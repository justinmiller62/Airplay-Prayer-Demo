//
//  LanguagePickerView.swift
//  Airplay Demo
//
//  Created on 5/5/26, all Glory goes to God.
//
//  Role in the dual-scene architecture:
//  The first screen the user sees on the phone. While `session.language`
//  is nil, PhoneRootView renders this picker instead of the transcript;
//  picking a language writes to the shared session and the transcript
//  takes over. The TV scene reads the same flag and shows a quiet
//  splash until a language has been chosen, so the two scenes are
//  always coherent.
//
//  When Latin is chosen, the TV later switches to a bilingual side-by-
//  side layout (Latin left, English right, line-for-line). The phone
//  shows just the chosen language regardless. The picker itself doesn't
//  know about that — it only writes the language; the views downstream
//  decide what to draw.
//

import SwiftUI

struct LanguagePickerView: View {

    @Environment(PrayerSession.self) private var session

    var body: some View {
        ZStack {
            PrayerTheme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 0)

                VStack(spacing: 12) {
                    Text("Choose a language")
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundStyle(PrayerTheme.primaryText)

                    Text("Latin shows the prayer in Latin on iPhone, with the English translation appearing line-for-line on the TV.")
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(PrayerTheme.mutedText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 14) {
                    languageButton(.english)
                    languageButton(.latin)
                }
                .padding(.horizontal, 28)

                Spacer(minLength: 0)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func languageButton(_ language: PrayerLanguage) -> some View {
        Button {
            session.language = language
            // Reset sync state so the transcript opens at the top of
            // the (possibly newly-laid-out) line list.
            session.topLineIndex = 0
            session.topLineProgress = 0
        } label: {
            HStack {
                Text(language.nativeName)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                Spacer()
                Text(language.displayName)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(PrayerTheme.mutedText)
            }
            .foregroundStyle(PrayerTheme.primaryText)
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(PrayerTheme.primaryText.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Choose \(language.displayName)")
    }
}

#Preview {
    LanguagePickerView()
        .environment(PrayerSession.shared)
}
