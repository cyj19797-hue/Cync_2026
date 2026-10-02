//
//  NotificationSettingsView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `325:2146` ("6-1 알림 설정").
//  Pushed from SettingsView's "알림 설정" row — back chevron + title come
//  from `ScreenNavigationBar`, not the system nav bar (see that file's
//  header for why: iOS 26's Liquid Glass toolbar chrome).
//
//  Layout: the permission banner (only while iOS notifications aren't
//  allowed), then "전체 알림" (18pt Bold, like the section titles) and
//  three sections ("공지사항", "사물함", "커뮤니티") whose rows sit one step
//  in under their title, each a `NotificationSettingRow` (17pt) with a
//  one-line description (14pt). "새 공지 알림" and "사물함 신청 결과 알림" open sub-screens
//  (`NotificationNoticeCategoriesView`, `NotificationLockerResultsView`)
//  and show their current value (전체 / n개 / 끔).
//
//  Rhythm: rows ≥56pt with 14pt above/below the labels and 4pt between
//  label and description; 32pt above each section title, 8pt below it;
//  dividers between rows only, from the row's indent to 16pt short of
//  the right edge (`listRowDivider`).
//
//  No bottom tab bar here: only the five main tab screens show it — see
//  TabBarVisibility.swift.
//

import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var viewModel = NotificationSettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var isNoticeCategoriesPresented = false
    @State private var isLockerResultsPresented = false

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: .settingsNotifications, onBack: { dismiss() })

            NotificationPermissionBanner(
                permission: viewModel.permission,
                onAllow: { Task { await viewModel.requestPermission() } },
                onOpenSettings: viewModel.openSystemSettings
            )

            List {
                Section {
                    NotificationSettingRow(
                        titleKey: .notifAll,
                        subtitleKey: .notifAllHint,
                        isOn: viewModel.binding(\.allEnabled),
                        isProminent: true
                    )
                    .disabled(!viewModel.canEditAll)
                    .listRowDivider(isLast: true)
                }

                Section {
                    toggleRow(.notifDeadline, .notifDeadlineHint, \.deadlineDDay)
                    NotificationSettingRow(
                        titleKey: .notifNewNotice,
                        subtitleKey: .notifNewNoticeHint,
                        value: viewModel.noticeSummary,
                        indent: indent
                    ) {
                        isNoticeCategoriesPresented = true
                    }
                    .listRowDivider()
                    toggleRow(.notifCyncNotice, .notifCyncNoticeHint, \.cyncNotices, isLast: true)
                } header: {
                    sectionHeader(.tabNotices)
                }
                .disabled(!viewModel.canEditItems)

                Section {
                    NotificationSettingRow(
                        titleKey: .notifLockerResult,
                        subtitleKey: .notifLockerResultHint,
                        value: viewModel.lockerSummary,
                        indent: indent
                    ) {
                        isLockerResultsPresented = true
                    }
                    .listRowDivider()
                    toggleRow(.notifLockerReturn, .notifLockerReturnHint, \.lockerReturn, isLast: true)
                } header: {
                    sectionHeader(.tabLockers)
                }
                .disabled(!viewModel.canEditItems)

                Section {
                    toggleRow(.notifComment, .notifCommentHint, \.comments)
                    toggleRow(.notifReply, .notifReplyHint, \.replies)
                    toggleRow(.notifLike, .notifLikeHint, \.likes)
                    toggleRow(.notifReportResult, .notifReportResultHint, \.reportResults)
                    toggleRow(.notifRestriction, .notifRestrictionHint, \.communityRestriction, isLast: true)
                } header: {
                    sectionHeader(.tabCommunity)
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
        .navigationDestination(isPresented: $isNoticeCategoriesPresented) {
            NotificationNoticeCategoriesView(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $isLockerResultsPresented) {
            NotificationLockerResultsView(viewModel: viewModel)
        }
        .notificationPermissionTracking(viewModel)
        .toast(message: $viewModel.toastMessage)
    }

    /// Rows under a section title sit one step in.
    private var indent: CGFloat { NotificationSettingRow.sectionIndent }

    /// 18pt Bold, the same as "전체 알림"; 32pt above, 8pt below.
    private func sectionHeader(_ titleKey: LocalizedStringResource) -> some View {
        ListSectionHeader(
            titleKey: titleKey,
            topPadding: Spacing.xl,
            font: .settingSectionTitle,
            tracking: Tracking.settingSectionTitle,
            bottomPadding: Spacing.xs
        )
    }

    private func toggleRow(
        _ titleKey: LocalizedStringResource,
        _ subtitleKey: LocalizedStringResource,
        _ keyPath: WritableKeyPath<NotificationPreferences, Bool>,
        isLast: Bool = false
    ) -> some View {
        NotificationSettingRow(
            titleKey: titleKey,
            subtitleKey: subtitleKey,
            isOn: viewModel.binding(keyPath),
            indent: indent
        )
        .listRowDivider(isLast: isLast)
    }
}

extension View {
    /// Reads the iOS permission on appear and every time the app comes
    /// back to the foreground (e.g. from iOS 설정).
    func notificationPermissionTracking(_ viewModel: NotificationSettingsViewModel) -> some View {
        modifier(NotificationPermissionTracking(viewModel: viewModel))
    }
}

private struct NotificationPermissionTracking: ViewModifier {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .task { await viewModel.refreshPermission() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await viewModel.refreshPermission() }
                }
            }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
    .environmentObject(TabBarVisibility())
}
