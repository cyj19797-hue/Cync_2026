//
//  NotificationPermissionBanner.swift
//  Cync
//
//  Top of "알림 설정" (and its sub-screens) while iOS notifications aren't
//  allowed for the app. Never asked yet: "알림을 받으려면 알림을 허용해
//  주세요." + "알림 켜기" (shows the iOS prompt). Turned down: "알림이 꺼져
//  있어요. 설정에서 알림을 켜 주세요." + "설정 열기" (the app's page in iOS
//  설정). `surface` card; the button is the same 32pt filled button as
//  글쓰기's "등록" (white on `accentStrong`, ~4.5:1; 44pt to tap).
//

import SwiftUI

struct NotificationPermissionBanner: View {
    let permission: NotificationSettingsViewModel.PermissionState
    let onAllow: () -> Void
    let onOpenSettings: () -> Void

    private static let buttonHeight: CGFloat = 32
    private static let touchExtension = (44 - buttonHeight) / 2

    var body: some View {
        if permission == .notDetermined || permission == .denied {
            let isDenied = permission == .denied
            HStack(spacing: Spacing.cardInset) {
                Image(systemName: "bell.slash")
                    .foregroundStyle(Color.textSecondary)
                    .accessibilityHidden(true)

                Text(isDenied ? .notifPermissionDenied : .notifPermissionNotDetermined)
                    .font(.categoryBadge).tracking(Tracking.categoryBadge)
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: isDenied ? onOpenSettings : onAllow) {
                    Text(isDenied ? .notifOpenSettings : .notifAllow)
                        .font(.headerActionButton).tracking(Tracking.headerActionButton)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, Spacing.md)
                        .frame(minWidth: 44, minHeight: Self.buttonHeight)
                        .background {
                            RoundedRectangle(cornerRadius: Radius.chipSelected)
                                .fill(Color.accentStrong)
                        }
                        .padding(.vertical, Self.touchExtension)
                        .contentShape(Rectangle())
                        .padding(.vertical, -Self.touchExtension)
                }
                .buttonStyle(.plain)
                .fixedSize()
            }
            .padding(Spacing.cardInset)
            .background {
                RoundedRectangle(cornerRadius: Radius.scheduleCard)
                    .fill(Color.surface)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.screenContentTop)
        }
    }
}

#Preview {
    VStack {
        NotificationPermissionBanner(permission: .notDetermined, onAllow: {}, onOpenSettings: {})
        NotificationPermissionBanner(permission: .denied, onAllow: {}, onOpenSettings: {})
    }
}
