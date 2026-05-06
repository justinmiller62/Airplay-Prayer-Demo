//
//  PrayerLine.swift
//  Airplay Demo
//
//  Created on 5/5/26, all Glory goes to God.
//
//  Role in the dual-scene architecture:
//  Each line of the prayer is stored once with its English text, its
//  Latin text, and whether it should render with section-header styling.
//  Both phone and TV scenes index into the same `[PrayerLine]` array on
//  PrayerSession, so a given line index means the same content in either
//  language and the (topLineIndex, topLineProgress) sync between phone
//  and TV is language-independent.
//
//  When the TV is showing the bilingual side-by-side layout (Latin chosen),
//  it draws BOTH `latin` and `english` for the same row, line-for-line.
//  The phone always shows just one language at a time.
//

import Foundation

struct PrayerLine: Equatable, Hashable {
    let english: String
    let latin: String
    let isHeader: Bool

    func text(for language: PrayerLanguage) -> String {
        switch language {
        case .english: return english
        case .latin:   return latin
        }
    }
}

enum PrayerLanguage: String, CaseIterable, Hashable {
    case english
    case latin

    var displayName: String {
        switch self {
        case .english: return "English"
        case .latin:   return "Latin"
        }
    }

    /// Native-language label used on the picker buttons so each option
    /// reads in its own tongue ("English" / "Latine").
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .latin:   return "Latine"
        }
    }
}
