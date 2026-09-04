//
//  NotificationSettingRow.swift
//  test
//
//  Figma node `361:2308` etc. ("설정명") — a settings row with no leading
//  icon (unlike `SettingsRow` on "6 - 설정"), ending in either a `Switch`
//  ("마감 D-day", "댓글") or a chevron ("새 공지사항 등록", "사물함 결과"). Pass
//  `isOn` for the former, `onNavigate` for the latter.
//

import SwiftUI

struct NotificationSettingRow: View {
    let titleKey: LocalizedStringKey
    var isOn: Binding<Bool>?
    var onNavigate: (() -> Void)?

    var body: some View {
        if let onNavigate {
            Button(action: onNavigate) { rowContent }
                .buttonStyle(.plain)
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        HStack(spacing: Spacing.xs) {
            Text(titleKey)
                .font(.categoryBadge)
                .foregroundStyle(Color.textPrimary)

            Spacer(minLength: 0)

            if let isOn {
                // Figma's Material `Switch` maps directly to SwiftUI's
                // native `Toggle` — the system default tint is kept since
                // Figma doesn't specify a custom "on" color for it here.
                Toggle("", isOn: isOn)
                    .labelsHidden()
            } else {
                NavigationChevron()
            }
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var isOn = true
        var body: some View {
            List {
                NotificationSettingRow(titleKey: "마감 D-day", isOn: $isOn)
                NotificationSettingRow(titleKey: "새 공지사항 등록", onNavigate: {})
            }
        }
    }
    return PreviewHost()
}
