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
//  Three display states, driven by `session.language`:
//    • nil      — the user hasn't picked a language yet on the phone.
//                 Show a centered splash that prompts them to choose.
//    • .english — single-column English transcript (the original look).
//    • .latin   — bilingual side-by-side: Latin on the left, English
//                 translation on the right, line-for-line. Uses a
//                 smaller font tier (PrayerTheme.tvBilingual*) so two
//                 columns fit comfortably on the canvas.
//
//  Sync (1-to-1) works the same in all rendering modes:
//  Each row corresponds to one PrayerLine indexed identically to the
//  phone, so writing `session.topLineIndex` and `session.topLineProgress`
//  on the phone always means the same logical line on the TV. This
//  view measures every row's frame in its own VStack via the shared
//  LineFramesKey preference (exactly as the phone does), looks up the
//  frame of the line at `session.topLineIndex`, and translates the
//  VStack up by `frame.minY + topLineProgress * frame.height`.
//
//  Smoothness vs. snap:
//  Routine scroll-driven offset changes animate over `offsetCatchUp-
//  Duration` (a critically-damped spring) so the TV tracks the
//  phone's gesture stream smoothly. Three transitions deliberately
//  don't animate:
//    • The very first measurement after the scene attaches — if the
//      user starts AirPlay mid-prayer, we want the TV to land at the
//      right place instantly, not scroll-from-zero over 0.33 s.
//    • A font-scale change — the phone snaps its scroll to keep the
//      same line at the top; the TV snaps its offset to match.
//    • A language change — single-column ↔ bilingual produces a
//      wholly different line layout, so we snap without animation.
//  All three are gated by `hasInitialOffset`, plus `measuredScale`
//  and `measuredLanguage` to detect the transitions.
//
//  Why the split into TVRootView + TVLineStack:
//  TVRootView observes `topLineIndex` and `topLineProgress`, so its
//  body re-runs on every gesture frame from the phone. If the line
//  VStack lived inside TVRootView's body, SwiftUI would re-evaluate
//  every line view per re-render and the offset update would stutter.
//  Instead, the line stack is an Equatable child: SwiftUI compares
//  its inputs (lines, language, scale, size) against the previous
//  call and — since none of those change during scroll — skips re-
//  evaluating it entirely. Only the .offset(y:) modifier re-applies,
//  which is essentially free.
//

import SwiftUI

struct TVRootView: View {

    @Environment(PrayerSession.self) private var session

    @State private var lineFrames: [Int: CGRect] = [:]

    /// The (scale, language) pair we last took a complete measurement
    /// at. Same purpose as on the phone: ignore further preference
    /// emissions once we have a complete measurement for the current
    /// layout, which kills the runtime warning AND removes per-frame
    /// churn. Splitting scale and language tracking lets us snap
    /// without animation on either transition.
    @State private var measuredScale: PrayerTheme.FontScale? = nil
    @State private var measuredLanguage: PrayerLanguage? = nil

    /// Becomes `true` after the first non-empty measurement settles.
    /// While `false`, the offset is applied without animation, so a
    /// fresh attach (AirPlay engaged mid-prayer) snaps to the current
    /// position instead of scrolling-from-zero. Reset to `false` on
    /// font-scale OR language change so the snap behaviour repeats.
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

            if let language = session.language {
                GeometryReader { proxy in
                    content(in: proxy.size, language: language)
                }
                .ignoresSafeArea()
            } else {
                splash
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Splash (no language picked yet)

    private var splash: some View {
        VStack(spacing: 18) {
            Text(session.title(for: nil))
                .font(.system(size: 56, weight: .semibold, design: .serif))
                .foregroundStyle(PrayerTheme.primaryText)
                .multilineTextAlignment(.center)

            Text("Choose a language on iPhone to begin.")
                .font(.system(size: 30, weight: .regular, design: .serif))
                .foregroundStyle(PrayerTheme.mutedText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Content

    @ViewBuilder
    private func content(in size: CGSize, language: PrayerLanguage) -> some View {
        let yOffset = computeOffset()

        ZStack(alignment: .topLeading) {
            TVLineStack(
                lines: session.lines,
                language: language,
                scale: session.fontScale,
                size: size
            )
            .equatable()
            .offset(y: -yOffset)
            // Animate steady-state scroll updates with a critically-
            // damped spring; bypass animation while `hasInitialOffset`
            // is false (first attach, font change, language change)
            // so those land as single-frame snaps.
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
            handlePreferenceUpdate(newFrames, language: language)
        }
    }

    /// Where in the (un-offset) content the phone's viewport top
    /// currently lives. We translate the VStack up by this much.
    private func computeOffset() -> CGFloat {
        guard let frame = lineFrames[session.topLineIndex] else { return 0 }
        return frame.minY + CGFloat(session.topLineProgress) * frame.height
    }

    /// Single funnel for LineFramesKey updates. Four jobs:
    ///   1. Skip the update if we already have a complete measurement
    ///      at the current (scale, language) (suppresses the runtime
    ///      warning about preferences updating multiple times per frame).
    ///   2. On the first complete measurement, render the offset once
    ///      with no animation so a mid-prayer attach lands precisely.
    ///   3. On a font-scale change, do the same snap so the TV
    ///      catches up to the phone's new layout instantly.
    ///   4. On a language change (single-col ↔ bilingual), snap too —
    ///      the layout differs too much to animate cleanly.
    private func handlePreferenceUpdate(
        _ newFrames: [Int: CGRect],
        language: PrayerLanguage
    ) {
        let currentScale = session.fontScale
        let alreadyMeasured = measuredScale == currentScale
            && measuredLanguage == language
            && lineFrames.count >= newFrames.count
            && !lineFrames.isEmpty
        if alreadyMeasured { return }

        let isLayoutChange =
            (measuredScale != nil && measuredScale != currentScale)
            || (measuredLanguage != nil && measuredLanguage != language)

        if newFrames != lineFrames {
            lineFrames = newFrames
        }
        if newFrames.count >= session.lines.count {
            measuredScale = currentScale
            measuredLanguage = language
        }

        if isLayoutChange {
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

/// The line VStack lives in its own Equatable view so that scroll
/// updates from the phone don't force SwiftUI to walk every line view
/// again. Inputs are `lines`, `language`, `scale`, and `size`; none of
/// these change when only `topLineProgress` changes, so the equality
/// check on every re-render of TVRootView returns true and SwiftUI
/// re-uses the cached rendering. Only the parent's `.offset(y:)` is
/// re-applied.
private struct TVLineStack: View, Equatable {

    let lines: [PrayerLine]
    let language: PrayerLanguage
    let scale: PrayerTheme.FontScale
    let size: CGSize

    static let coordinateSpaceName = "tvContent"

    var body: some View {
        VStack(alignment: .leading, spacing: verticalGap) {
            ForEach(lines.indices, id: \.self) { index in
                row(at: index)
            }
        }
        .padding(.horizontal, size.width * PrayerTheme.tvOverscanFraction)
        .frame(width: size.width, alignment: .leading)
        .coordinateSpace(name: Self.coordinateSpaceName)
    }

    private var verticalGap: CGFloat {
        switch language {
        case .english: return scale.tvVerticalGap
        case .latin:   return scale.tvBilingualVerticalGap
        }
    }

    private func positionReporter(for index: Int) -> some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: LineFramesKey.self,
                value: [index: geo.frame(in: .named(Self.coordinateSpaceName))]
            )
        }
    }

    /// One row per PrayerLine. English mode draws a single text view
    /// across the full reading column; Latin mode draws an HStack of
    /// (Latin, English) so the translation sits beside its source.
    ///
    /// Where the position reporter sits matters for sync. On the phone
    /// (which always shows just one language), each row measures the
    /// language the user is reading — so phone progress fractions
    /// reflect that text. On the TV in bilingual mode the row height
    /// is the MAX of the two columns, but the user is still reading
    /// the LEFT (Latin) column; that's the language whose progress the
    /// phone publishes. So in bilingual mode we attach the position
    /// reporter to the LATIN column only — its frame is what drives
    /// `(topLineIndex, topLineProgress)` translation. The English
    /// column rides alongside as visual translation; if it wraps
    /// taller than the Latin, the extra height extends beyond the
    /// measured row but is irrelevant to sync. Without this, in-line
    /// progress drifts whenever the two columns wrap to different
    /// numbers of visual lines.
    @ViewBuilder
    private func row(at index: Int) -> some View {
        let line = lines[index]
        let contentWidth = size.width * (1 - PrayerTheme.tvOverscanFraction * 2)

        switch language {
        case .english:
            singleColumn(line: line, isHeader: line.isHeader, columnWidth: contentWidth)
                .background(positionReporter(for: index))

        case .latin:
            // 50/50 split with a small gutter so the two columns don't
            // visually run together.
            let gutter: CGFloat = 36
            let columnWidth = (contentWidth - gutter) / 2
            HStack(alignment: .top, spacing: gutter) {
                bilingualColumn(
                    text: line.latin,
                    isHeader: line.isHeader,
                    columnWidth: columnWidth
                )
                .background(positionReporter(for: index))

                bilingualColumn(
                    text: line.english,
                    isHeader: line.isHeader,
                    columnWidth: columnWidth
                )
            }
            .frame(width: contentWidth, alignment: .leading)
            .padding(.top, line.isHeader ? scale.tvBilingualVerticalGap * 0.5 : 0)
            .padding(.bottom, line.isHeader ? scale.tvBilingualVerticalGap * 0.3 : 0)
        }
    }

    @ViewBuilder
    private func singleColumn(
        line: PrayerLine,
        isHeader: Bool,
        columnWidth: CGFloat
    ) -> some View {
        Text(line.text(for: language))
            .font(.system(
                size: isHeader ? scale.tvHeader : scale.tvBody,
                weight: .regular,
                design: .serif
            ))
            .foregroundStyle(isHeader ? PrayerTheme.mutedText : PrayerTheme.primaryText)
            .lineSpacing(scale.tvLineSpacing)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: columnWidth, alignment: .leading)
            .padding(.top, isHeader ? scale.tvVerticalGap * 0.5 : 0)
            .padding(.bottom, isHeader ? scale.tvVerticalGap * 0.3 : 0)
    }

    @ViewBuilder
    private func bilingualColumn(
        text: String,
        isHeader: Bool,
        columnWidth: CGFloat
    ) -> some View {
        Text(text)
            .font(.system(
                size: isHeader ? scale.tvBilingualHeader : scale.tvBilingualBody,
                weight: .regular,
                design: .serif
            ))
            .foregroundStyle(isHeader ? PrayerTheme.mutedText : PrayerTheme.primaryText)
            .lineSpacing(scale.tvBilingualLineSpacing)
            .multilineTextAlignment(.leading)
            // fixedSize on the vertical axis keeps the Text from being
            // truncated by the HStack — without it, SwiftUI is free to
            // shrink the taller column to the height of the shorter one.
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: columnWidth, alignment: .topLeading)
    }

    static func == (lhs: TVLineStack, rhs: TVLineStack) -> Bool {
        lhs.scale == rhs.scale
            && lhs.language == rhs.language
            && lhs.size == rhs.size
            && lhs.lines == rhs.lines
    }
}

#Preview("TV — landscape", traits: .landscapeLeft) {
    TVRootView()
        .environment(PrayerSession.shared)
}
