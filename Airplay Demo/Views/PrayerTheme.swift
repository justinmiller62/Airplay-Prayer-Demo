//
//  PrayerTheme.swift
//  Airplay Demo
//
//  Created on 5/5/26, all Glory goes to God.
//
//  Role in the dual-scene architecture:
//  Visual constants shared by PhoneRootView and TVRootView so the two
//  scenes look like one app. Same colours, same serif, same notion of
//  "section header vs body line", and — importantly — a single
//  FontScale enum that exposes both phone-scale and TV-scale metrics.
//
//  When the user taps "Tt" on the phone, the FontScale value on
//  PrayerSession changes; both scenes re-render at the new scale.
//  Phone goes 18→30pt body; TV goes 68→112pt body. The two scales
//  are tuned so the same number of lines fits on each surface at
//  each size — that's what keeps the 1-to-1 sync feeling natural.
//

import SwiftUI

enum PrayerTheme {

    // MARK: - Palette

    /// Deep teal app background. Reads calm on a phone; sits well
    /// behind large serif type on a TV without producing the
    /// white-on-black flicker pure black gives over AirPlay.
    static let background = Color(red: 0.105, green: 0.265, blue: 0.250)

    /// Warm off-white for body text. Slightly cream so the typography
    /// feels typeset rather than backlit.
    static let primaryText = Color(red: 0.965, green: 0.945, blue: 0.890)

    /// Same hue as primaryText, dimmed to ~42% — used for section
    /// headers ("Apostles' Creed", "Our Father", mystery announcements).
    static let mutedText = Color(red: 0.965, green: 0.945, blue: 0.890).opacity(0.42)

    // MARK: - TV layout constants

    /// Fraction of TV screen width to inset on each side for overscan.
    /// Kept tight so the reading column uses most of the canvas.
    static let tvOverscanFraction: CGFloat = 0.04

    // MARK: - Font scale (cycled by the Tt button on the phone)

    /// One scale value drives BOTH surfaces — see the file-level
    /// comment. Phone uses `phone*` properties, TV uses `tv*`.
    enum FontScale: Int, CaseIterable {
        case small, medium, large, xlarge

        // ── Phone ──────────────────────────────────────────────

        var phoneBody: CGFloat {
            switch self {
            case .small:  return 18
            case .medium: return 22
            case .large:  return 26
            case .xlarge: return 30
            }
        }
        var phoneHeader: CGFloat { phoneBody * 1.18 }
        var phoneLineSpacing: CGFloat { phoneBody * 0.32 }
        var phoneVerticalGap: CGFloat { phoneBody * 0.70 }

        // ── TV (proportionally larger so the same line count fits) ─

        var tvBody: CGFloat {
            switch self {
            case .small:  return 34
            case .medium: return 42
            case .large:  return 50
            case .xlarge: return 58
            }
        }
        var tvHeader: CGFloat { tvBody * 1.18 }
        var tvLineSpacing: CGFloat { tvBody * 0.30 }
        var tvVerticalGap: CGFloat { tvBody * 0.66 }

        // ── TV bilingual (Latin chosen — two columns share the canvas) ─

        /// Smaller TV body size used when both Latin and English share
        /// the screen side-by-side. Tuned so each column reads at a
        /// comparable density to the single-column English layout.
        var tvBilingualBody: CGFloat { tvBody * 0.78 }
        var tvBilingualHeader: CGFloat { tvBilingualBody * 1.18 }
        var tvBilingualLineSpacing: CGFloat { tvBilingualBody * 0.30 }
        var tvBilingualVerticalGap: CGFloat { tvBilingualBody * 0.66 }

        // ── Cycling ────────────────────────────────────────────

        func next() -> FontScale {
            FontScale(rawValue: (rawValue + 1) % FontScale.allCases.count) ?? .medium
        }
    }
}
