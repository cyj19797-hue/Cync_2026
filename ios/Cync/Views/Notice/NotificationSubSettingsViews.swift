//
//  NotificationSubSettingsViews.swift
//  Cync
//
//  The two sub-screens of "알림 설정", sharing its view model:
//  - "새 공지 알림": one switch per notice category (학사 / 장학 / 학생회 /
//    국제교류).
//  - "사물함 신청 결과 알림": 신청 승인 / 신청 거절.
//  Same rows, dividers, banner and save-or-revert behavior as the main
//  screen; everything is disabled while iOS notifications aren't allowed
//  or "전체 알림" is off.
//

import SwiftUI

struct NotificationNoticeCategoriesView: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NotificationSubSettingsScreen(titleKey: .notifNewNotice, viewModel: viewModel, onBack: { dismiss() }) {
            let options = NotificationPreferences.noticeCategoryOptions
            ForEach(options) { category in
                NotificationSettingRow(titleKey: category.label, isOn: viewModel.binding(for: category))
                    .listRowDivider(isLast: category == options.last)
            }
        }
    }
}

struct NotificationLockerResultsView: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NotificationSubSettingsScreen(titleKey: .notifLockerResult, viewModel: viewModel, onBack: { dismiss() }) {
            NotificationSettingRow(
                titleKey: .notifLockerApproved,
                subtitleKey: .notifLockerApprovedHint,
                isOn: viewModel.binding(\.lockerApproved)
            )
            .listRowDivider()
            NotificationSettingRow(
                titleKey: .notifLockerRejected,
                subtitleKey: .notifLockerRejectedHint,
                isOn: viewModel.binding(\.lockerRejected)
            )
            .listRowDivider(isLast: true)
        }
    }
}

/// Bar + permission banner + one section of rows.
private struct NotificationSubSettingsScreen<Rows: View>: View {
    let titleKey: LocalizedStringResource
    @ObservedObject var viewModel: NotificationSettingsViewModel
    let onBack: () -> Void
    @ViewBuilder let rows: () -> Rows

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: titleKey, onBack: onBack)

            NotificationPermissionBanner(
                permission: viewModel.permission,
                onAllow: { Task { await viewModel.requestPermission() } },
                onOpenSettings: viewModel.openSystemSettings
            )

            List {
                Section {
                    rows()
                }
                .disabled(!viewModel.canEditItems)
            }
            .listStyle(.plain)
            .compactListSections()
            .environment(\.defaultMinListRowHeight, NotificationSettingRow.minHeight)
            .background(Color.appBackground)
        }
        .background(Color.appBackground)
        .toolbar(.hidden, for: .navigationBar)
        .notificationPermissionTracking(viewModel)
        .toast(message: $viewModel.toastMessage)
    }
}

#Preview {
    NavigationStack {
        NotificationNoticeCategoriesView(viewModel: NotificationSettingsViewModel())
    }
}
