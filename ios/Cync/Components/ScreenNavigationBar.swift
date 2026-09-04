//
//  ScreenNavigationBar.swift
//  Cync
//
//  Custom back button + title bar (e.g. "6-1 알림 설정" frame) for screens
//  that need Figma's exact 44x44 tap target instead of the system
//  `NavigationStack` bar. The leading icon reuses `NavigationChevron`
//  rather than the empty icon-instance placeholder Figma's export left
//  behind.
//

import SwiftUI

struct ScreenNavigationBar: View {
    let titleKey: LocalizedStringKey
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                NavigationChevron(direction: .left, color: .textPrimary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .padding(Spacing.xs)
            .frame(width: 44, height: 44)
            .accessibilityLabel("뒤로")

            Text(titleKey)
                .font(.screenNavTitle)
                .foregroundStyle(Color.textPrimary)
                .padding(Spacing.xs)
                .frame(height: 44)
        }
        .padding(.vertical, Spacing.xxs)
        .padding(.horizontal, Spacing.md)
    }
}

#Preview {
    ScreenNavigationBar(titleKey: "알림 설정", onBack: {})
}
