//
//  PhoneRootView.swift
//  Airplay Demo
//
//  Created on 5/5/26, all Glory goes to God.
//
//  Role in the dual-scene architecture:
//  Renders the phone scene's UI: a quiet reader-style transcript laid
//  out for hand-held reading. Locked to portrait by Info.plist so that
//  rotating the phone does NOT rotate this view (or affect the TV).
//
//  How sync to the TV works (1-to-1):
//  This view measures every line's frame inside its scroll content via
//  a preference key. On every scroll update it figures out which line
//  is currently at the TOP of the visible area, and how far the user
//  has scrolled INTO that line (0...1). Both numbers are written to
//  PrayerSession. The TV scene measures its own line frames the same
//  way and applies an `.offset(y:)` so the same line is at its top
//  with the same in-line fraction.
//
//  Font-size change handling:
//  When the user taps "Tt", line heights change. The ScrollView keeps
//  the same scroll offset (in points), which now lands on a different
//  line. To keep the visible content stable across the change, we
//  detect the scale transition inside onPreferenceChange and call
//  ScrollViewProxy.scrollTo(currentTopLineIndex, .top) — so whatever
//  line was at the top before the size change is at the top after.
//
//  Player UI:
//  Intentionally absent in this iteration. The bottom of the screen
//  reserves space where a future "now playing" mini-player will go.
//

import SwiftUI

struct PhoneRootView: View {

    @Environment(PrayerSession.self) private var session

    /// Per-line frames inside the scroll content's coordinate space.
    /// Used to translate a raw scroll offset into (topLineIndex,
    /// topLineProgress) for syncing with the TV.
    @State private var lineFrames: [Int: CGRect] = [:]

    /// The scale value we last took a complete measurement at. While
    /// `measuredScale == session.fontScale`, the layout is stable and
    /// we ignore further LineFramesKey emissions — that kills the
    /// "bound preference … tried to update multiple times per frame"
    /// runtime warning AND avoids needless re-publish work during scroll.
    @State private var measuredScale: PrayerTheme.FontScale? = nil

    /// Last seen scroll offset, stashed in a class so it does NOT
    /// trigger view re-renders. Re-rendering the 380-line transcript
    /// on every gesture frame would cost more than the sync is worth.
    private let scrollState = ScrollState()

    var body: some View {
        ZStack {
            PrayerTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                transcript
                playerSpace
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .center, spacing: 16) {
            Button {
                // Reset both indices; TV will jump back too.
                session.topLineIndex = 0
                session.topLineProgress = 0
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(PrayerTheme.primaryText)
                    .frame(width: 32, height: 32, alignment: .leading)
            }
            .accessibilityLabel("Restart prayer")

            Spacer(minLength: 0)

            Text(session.title)
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundStyle(PrayerTheme.primaryText)
                .lineLimit(1)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            // No AirPlay button: AVRoutePickerView surfaces audio
            // routes (it would only show Bluetooth/AirPods here, not
            // an Apple TV), and there's no public iOS API to
            // programmatically initiate Screen Mirroring. The path
            // for engaging our external display scene is Control
            // Center → Screen Mirroring → pick an Apple TV.
            Button {
                // Tt writes to the shared session — the TV picks up
                // the same scale value and uses its own (larger)
                // tier of it, so line-for-line sync is preserved.
                session.fontScale = session.fontScale.next()
            } label: {
                HStack(alignment: .lastTextBaseline, spacing: -1) {
                    Text("T")
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                    Text("t")
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                }
                .foregroundStyle(PrayerTheme.primaryText)
                .frame(minWidth: 32, minHeight: 32, alignment: .trailing)
            }
            .accessibilityLabel("Cycle text size")
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 16)
    }

    // MARK: - Transcript

    private var transcript: some View {
        let scale = session.fontScale
        return ScrollViewReader { proxy in
            ScrollView {
                // Eager VStack (not Lazy) so every line emits its frame
                // immediately — we need the full set of frames to find
                // the topmost visible line at any scroll position.
                VStack(alignment: .leading, spacing: scale.phoneVerticalGap) {
                    ForEach(session.lines.indices, id: \.self) { index in
                        line(at: index, scale: scale)
                            .background(linePositionReporter(for: index))
                            .id(index)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .coordinateSpace(name: Self.scrollContentSpace)
            }
            .scrollIndicators(.hidden)
            .onPreferenceChange(LineFramesKey.self) { newFrames in
                handlePreferenceUpdate(newFrames, proxy: proxy)
            }
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { _, offset in
                scrollState.offset = offset
                publishTopLine()
            }
        }
    }

    /// Emits the line's frame in the scroll-content coordinate space
    /// so the parent ScrollView can collect them via PreferenceKey.
    private func linePositionReporter(for index: Int) -> some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: LineFramesKey.self,
                value: [index: geo.frame(in: .named(Self.scrollContentSpace))]
            )
        }
    }

    /// Single funnel for LineFramesKey updates. Three jobs:
    ///   1. Skip the update if we already have a complete measurement
    ///      at the current font scale (suppresses the runtime warning
    ///      about preferences updating multiple times per frame).
    ///   2. If the scale just changed, snap the scroll to the previous
    ///      `topLineIndex` so the same content stays visible.
    ///   3. Otherwise, recompute (topLineIndex, topLineProgress) from
    ///      the new measurement.
    private func handlePreferenceUpdate(
        _ newFrames: [Int: CGRect],
        proxy: ScrollViewProxy
    ) {
        let currentScale = session.fontScale
        let alreadyMeasured = measuredScale == currentScale
            && lineFrames.count >= newFrames.count
            && !lineFrames.isEmpty
        if alreadyMeasured { return }

        let isScaleChange = measuredScale != nil && measuredScale != currentScale

        if newFrames != lineFrames {
            lineFrames = newFrames
        }
        if newFrames.count >= session.lines.count {
            measuredScale = currentScale
        }

        if isScaleChange, lineFrames[session.topLineIndex] != nil {
            // Pull the scroll back to put the previously-current line
            // at the top. Skip implicit animation so the catch-up is
            // a single-frame snap, not a visible scroll.
            let target = session.topLineIndex
            withAnimation(nil) {
                proxy.scrollTo(target, anchor: .top)
            }
        } else {
            publishTopLine()
        }
    }

    /// Walk the (sorted) line frames to find the topmost line whose
    /// bottom is below the current scroll offset, then express the
    /// remainder as a fraction within that line. Write to session
    /// only on real change to avoid feedback loops.
    private func publishTopLine() {
        guard !lineFrames.isEmpty else { return }
        let scrollOffset = scrollState.offset
        let sorted = lineFrames.sorted { $0.key < $1.key }

        var newIndex = sorted.last?.key ?? 0
        var newFraction: Double = 1

        for (index, frame) in sorted where frame.maxY > scrollOffset {
            let height = max(1, frame.height)
            let raw = (scrollOffset - frame.minY) / height
            newIndex = index
            newFraction = max(0, min(1, Double(raw)))
            break
        }

        if newIndex != session.topLineIndex {
            session.topLineIndex = newIndex
        }
        if abs(newFraction - session.topLineProgress) > 0.001 {
            session.topLineProgress = newFraction
        }
    }

    @ViewBuilder
    private func line(at index: Int, scale: PrayerTheme.FontScale) -> some View {
        let text = session.lines[index]
        let isHeader = SamplePrayer.isSectionHeader(text)

        Text(text)
            .font(.system(
                size: isHeader ? scale.phoneHeader : scale.phoneBody,
                weight: .regular,
                design: .serif
            ))
            .foregroundStyle(isHeader ? PrayerTheme.mutedText : PrayerTheme.primaryText)
            .lineSpacing(scale.phoneLineSpacing)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, isHeader ? scale.phoneVerticalGap * 0.6 : 0)
            .padding(.bottom, isHeader ? scale.phoneVerticalGap * 0.4 : 0)
    }

    // MARK: - Reserved player space

    private var playerSpace: some View {
        Color.clear.frame(height: 88)
    }

    // MARK: - Constants

    private static let scrollContentSpace = "phoneScrollContent"
}

/// Holds the latest scroll offset outside the SwiftUI value-graph so
/// updating it does NOT cause `PhoneRootView` to re-render. Without
/// this, every gesture frame would re-evaluate the 380-line VStack —
/// SwiftUI's UIScrollView keeps scrolling smooth either way, but the
/// extra work makes the matching offset on the TV scene stutter.
private final class ScrollState {
    var offset: CGFloat = 0
}

#Preview {
    PhoneRootView()
        .environment(PrayerSession.shared)
}
