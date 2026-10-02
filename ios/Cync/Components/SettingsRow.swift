//
//  SettingsRow.swift
//  test
//
//  Figma node `47:1728`/`47:1741` etc. ("설정명") — one settings row: leading
//  icon + label, an optional trailing value ("한국어"), and a chevron. Used
//  for the tappable rows across "설정" and "계정" — only "언어 설정" fills
//  the trailing value slot. Rows that only show information (no tap, no
//  chevron) use `SettingsInfoRow`, which shares `SettingsRowContent` so the
//  two kinds of row line up exactly.
//

import SwiftUI

struct SettingsRow: View {
    let systemImage: String
    let titleKey: LocalizedStringResource
    var value: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsRowContent(systemImage: systemImage, titleKey: titleKey, value: value, showsChevron: true)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Icon + title + optional trailing value (+ optional chevron) — the
/// layout shared by `SettingsRow` and `SettingsInfoRow`.
struct SettingsRowContent: View {
    let systemImage: String
    let titleKey: LocalizedStringResource
    var value: String?
    var showsChevron: Bool

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.textPrimary)
                .frame(width: 20)

            Text(titleKey)
                .font(.categoryBadge).tracking(Tracking.categoryBadge)
                .foregroundStyle(Color.textPrimary)

            Spacer(minLength: 0)

            if let value {
                Text(value)
                    .font(.lockerLocationText).tracking(Tracking.lockerLocationText)
                    .foregroundStyle(Color.textPrimary)
            }

            if showsChevron {
                NavigationChevron()
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    List {
        SettingsRow(systemImage: "globe", titleKey: "언어 설정", value: "한국어") {}
        SettingsRow(systemImage: "bell", titleKey: "알림 설정") {}
        SettingsInfoRow(systemImage: "info.circle", titleKey: "프로그램 정보", value: "1.0.0v")
    }
}
