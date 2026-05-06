//
//  PrayerSession.swift
//  Airplay Demo
//
//  Created on 5/5/26, all Glory goes to God.
//
//  Role in the dual-scene architecture:
//  THE single source of truth shared by the phone and TV scenes. Both
//  scene delegates inject `PrayerSession.shared` into their SwiftUI
//  hierarchies via `.environment(...)` so any property mutation flows
//  to the views that read it.
//
//  Four pieces of state cross scenes:
//    • language         — nil until the user picks English or Latin on
//                         the phone's first screen. While nil, the phone
//                         shows the language picker and the TV shows a
//                         "Choose a language on iPhone" splash.
//    • topLineIndex     — which line is at the top of the phone's
//                         visible transcript. The TV scrolls so that
//                         same line is at the top of its viewport.
//    • topLineProgress  — 0...1 fraction of how far the user has
//                         scrolled INTO that top line. Combined with
//                         topLineIndex this is enough to re-position
//                         the TV at exactly the same point in the
//                         prayer regardless of differing line heights.
//    • fontScale        — the phone's "Tt" button writes here; the TV
//                         reads it and uses its own (larger) tier of
//                         the same scale, so 1-to-1 line correspondence
//                         is preserved across text-size changes.
//
//  Why @Observable (not ObservableObject):
//  This is a teaching repo and ObservableObject would be more familiar.
//  We pay the cost of using the newer @Observable macro here for a
//  concrete reason: per-property change tracking. With ObservableObject,
//  ANY @Published change re-renders every view that holds the model —
//  meaning the phone's 380-line transcript would rebuild on every
//  scroll-progress update (60+ times per second), making the TV's
//  matching offset stutter. With @Observable a view only re-renders on
//  changes to properties IT reads in its body, so writing
//  topLineProgress (read only by the TV) doesn't disturb the phone.
//

import Foundation
import SwiftUI

@Observable
final class PrayerSession {

    /// Shared singleton. Both scene delegates pass this same instance
    /// into their SwiftUI hierarchies via `.environment(...)`.
    static let shared = PrayerSession()

    /// Bilingual title — views pick the side that matches `language`.
    var titleEnglish: String
    var titleLatin: String

    /// Each entry carries both languages plus its header flag, so a
    /// given line index points at the same logical line of the prayer
    /// regardless of which language is being displayed.
    var lines: [PrayerLine]

    /// nil until the user picks on the language screen.
    var language: PrayerLanguage? = nil

    var topLineIndex: Int = 0
    var topLineProgress: Double = 0

    var fontScale: PrayerTheme.FontScale = .large

    private init() {
        self.titleEnglish = SamplePrayer.title.english
        self.titleLatin = SamplePrayer.title.latin
        self.lines = SamplePrayer.lines
    }

    /// Convenience for views: title in the chosen language, falling
    /// back to English when no language has been picked yet (e.g. the
    /// TV splash, which only renders before selection).
    func title(for language: PrayerLanguage?) -> String {
        switch language {
        case .latin: return titleLatin
        default:     return titleEnglish
        }
    }
}

// MARK: - Shared preference key

/// Each line emits its frame in its scroll-content coordinate space
/// via this PreferenceKey. The parent view collects them all into a
/// `[Int: CGRect]` keyed by line index, then translates the current
/// scroll offset into `(topLineIndex, topLineProgress)`. The same
/// key is reused on both phone and TV — the per-side coordinate
/// space is what makes the measurements local to each surface.
struct LineFramesKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
