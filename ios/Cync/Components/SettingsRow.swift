//
//  SettingsRow.swift
//  test
//
//  Figma node `47:1728`/`47:1741` etc. ("설정명") — one settings row: leading
//  icon + label, an optional trailing value ("한국어"), and a chevron. Used
//  for all 7 rows across "설정" and "계정" — only "언어 설정" fills the
//  trailing value slot.
//

import SwiftUI

struct SettingsRow: View {
    let systemImage: String
    let titleKey: LocalizedStringKey
    var value: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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

                NavigationChevron()
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    List {
        SettingsRow(systemImage: "globe", titleKey: "언어 설정", value: "한국어") {}
        SettingsRow(systemImage: "bell", titleKey: "알림 설정") {}
    }
}
