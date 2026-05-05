//
//  TVRootView.swift
//  Airplay Demo
//
//  Created on 5/5/26, all Glory goes to God.
//
//  Role in the dual-scene architecture:
//  Rendered by ExternalSceneDelegate into a UIWindow on the AirPlay
//  receiver — typically a 1920×1080 landscape canvas, separate from
//  the phone's window. iOS makes this scene non-interactive by virtue
//  of the UIWindowSceneSessionRoleExternalDisplayNonInteractive role,
//  so user touches never reach this view.
//
//  Visual relationship to the phone:
//  Same dark teal background, same warm cream serif, same section-
//  header treatment. Only the point sizes change — and they track
//  PrayerSession.fontScale alongside the phone, so when the user
//  taps "Tt" on the phone the TV resizes too. The TV always uses
//  a proportionally larger tier of the same scale (see PrayerTheme
//  FontScale: phoneBody vs tvBody).
//
//  How sync works (1-to-1):
//  This view measures every line's frame in its own VStack via the
//  shared LineFramesKey preference, exactly as the phone does. To
//  position itself, it looks up the frame of the line at
//  `session.topLineIndex` and translates the VStack up by
//  `frame.minY + topLineProgress * frame.height`. Whichever line is
//  at the top of the phone's viewport ends up at the top of the
//  TV's viewport, with the same in-line fraction.
//
//  Smoothness vs. snap:
//  Routine scroll-driven offset changes animate over `offsetCatchUp-
//  Duration` (a critically-damped spring) so the TV tracks the
//  phone's gesture stream smoothly. But two transitions deliberately
//  don't animate:
//    • The very first measurement after the scene attaches — if the
//      user starts AirPlay mid-prayer, we want the TV to land at the
//      right place instantly, not scroll-from-zero over 0.33 s.
//    • A font-scale change — the phone snaps its scroll to keep the
//      same line at the top; the TV snaps its offset to match.
//  Both are gated by `hasInitialOffset` and `measuredScale`.
//
//  Why the split into TVRootView + TVLineStack:
//  TVRootView observes `topLineIndex` and `topLineProgress`, so its
//  body re-runs on every gesture frame from the phone. If the 380-
//  line VStack lived inside TVRootView's body, SwiftUI would re-
//  evaluate all 380 line views per re-render and the offset update
//  would stutter. Instead, the line stack is an Equatable child:
//  SwiftUI compares its inputs (lines, scale, size) against the
//  previous call and — since none of those change during scroll —
//  skips re-evaluating it entirely. Only the .offset(y:) modifier
//  re-applies, which is essentially free.
//

import SwiftUI

struct TVRootView: View {

    @Environment(PrayerSession.self) private var session

    @State private var lineFrames: [Int: CGRect] = [:]

    /// The scale value we last took a complete measurement at. Same
    /// purpose as on the phone: ignore further preference emissions
    /// once we have a complete measurement for the current scale,
    /// which kills the runtime warning AND removes per-frame churn.
    @State private var measuredScale: PrayerTheme.FontScale? = nil

    /// Becomes `true` after the first non-empty measurement settles.
    /// While `false`, the offset is applied without animation, so a
    /// fresh attach (AirPlay engaged mid-prayer) snaps to the current
    /// position instead of scrolling-from-zero. Reset to `false` on
    /// font-scale change so the snap behaviour repeats there.
    @State private var hasInitialOffset = false

    /// 0.33 — settled here after A/B against shorter and bouncier
    /// variants. Critically-damped: no bounce, no overshoot.
    private static let offsetCatchUpDuration: TimeInterval = 0.33

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background OUTSIDE the GeometryReader and OUTSIDE any
            // safe-area-respecting container so it fills the whole TV
            // canvas, edge to edge.
            PrayerTheme.background
                .ignoresSafeArea()

            GeometryReader { proxy in
                content(in: proxy.size)
            }
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func content(in size: CGSize) -> some View {
        let yOffset = computeOffset()

        ZStack(alignment: .topLeading) {
            TVLineStack(
                lines: session.lines,
                scale: session.fontScale,
                size: size
            )
            .equatable()
            .offset(y: -yOffset)
            // Animate steady-state scroll updates with a critically-
            // damped spring; bypass animation while `hasInitialOffset`
            // is false (first attach, font change) so those land as
            // single-frame snaps.
            .animation(
                hasInitialOffset
                    ? .smooth(duration: Self.offsetCatchUpDuration)
                    : nil,
                value: yOffset
            )
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .clipped()
        .onPreferenceChange(LineFramesKey.self) { newFrames in
            handlePreferenceUpdate(newFrames)
        }
    }

    /// Where in the (un-offset) content the phone's viewport top
    /// currently lives. We translate the VStack up by this much.
    private func computeOffset() -> CGFloat {
        guard let frame = lineFrames[session.topLineIndex] else { return 0 }
        return frame.minY + CGFloat(session.topLineProgress) * frame.height
    }

    /// Single funnel for LineFramesKey updates. Three jobs:
    ///   1. Skip the update if we already have a complete measurement
    ///      at the current font scale (suppresses the runtime warning
    ///      about preferences updating multiple times per frame).
    ///   2. On the first complete measurement, render the offset once
    ///      with no animation so a mid-prayer attach lands precisely.
    ///   3. On a font-scale change, do the same snap so the TV
    ///      catches up to the phone's new layout instantly.
    private func handlePreferenceUpdate(_ newFrames: [Int: CGRect]) {
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

        if isScaleChange {
            // Disable animation for one render cycle, then re-enable.
            hasInitialOffset = false
            DispatchQueue.main.async {
                hasInitialOffset = true
            }
        } else if !hasInitialOffset && !newFrames.isEmpty {
            // First complete-ish measurement — let this render snap
            // (no animation) and turn animation back on next runloop.
            DispatchQueue.main.async {
                hasInitialOffset = true
            }
        }
    }
}

// MARK: - TVLineStack

/// The 380-line VStack lives in its own Equatable view so that scroll
/// updates from the phone don't force SwiftUI to walk every line view
/// again. Inputs are `lines`, `scale`, and `size`; none of these change
/// when only `topLineProgress` changes, so the equality check on every
/// re-render of TVRootView returns true and SwiftUI re-uses the cached
/// rendering. Only the parent's `.offset(y:)` is re-applied.
private struct TVLineStack: View, Equatable {

    let lines: [String]
    let scale: PrayerTheme.FontScale
    let size: CGSize

    static let coordinateSpaceName = "tvContent"

    var body: some View {
        VStack(alignment: .leading, spacing: scale.tvVerticalGap) {
            ForEach(lines.indices, id: \.self) { index in
                line(at: index)
                    .background(positionReporter(for: index))
            }
        }
        .padding(.horizontal, size.width * PrayerTheme.tvOverscanFraction)
        .frame(width: size.width, alignment: .leading)
        .coordinateSpace(name: Self.coordinateSpaceName)
    }

    private func positionReporter(for index: Int) -> some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: LineFramesKey.self,
                value: [index: geo.frame(in: .named(Self.coordinateSpaceName))]
            )
        }
    }

    @ViewBuilder
    private func line(at index: Int) -> some View {
        let text = lines[index]
        let isHeader = SamplePrayer.isSectionHeader(text)
        let maxWidth = size.width * (1 - PrayerTheme.tvOverscanFraction * 2)

        Text(text)
            .font(.system(
                size: isHeader ? scale.tvHeader : scale.tvBody,
                weight: .regular,
                design: .serif
            ))
            .foregroundStyle(isHeader ? PrayerTheme.mutedText : PrayerTheme.primaryText)
            .lineSpacing(scale.tvLineSpacing)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: maxWidth, alignment: .leading)
            .padding(.top, isHeader ? scale.tvVerticalGap * 0.5 : 0)
            .padding(.bottom, isHeader ? scale.tvVerticalGap * 0.3 : 0)
    }

    static func == (lhs: TVLineStack, rhs: TVLineStack) -> Bool {
        lhs.scale == rhs.scale
            && lhs.size == rhs.size
            && lhs.lines == rhs.lines
    }
}

#Preview("TV — landscape", traits: .landscapeLeft) {
    TVRootView()
        .environment(PrayerSession.shared)
}
