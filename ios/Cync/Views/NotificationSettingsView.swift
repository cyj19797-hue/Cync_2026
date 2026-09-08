//
//  NotificationSettingsView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `325:2146` ("6-1 알림 설정").
//  Pushed from SettingsView's "알림 설정" row — back chevron + title come
//  from `ScreenNavigationBar`, not the system nav bar (see that file's
//  header for why: iOS 26's Liquid Glass toolbar chrome). Three sections
//  ("공지사항", "사물함", "커뮤니티"), each built from `NotificationSettingRow`.
//
//  No UIKit anywhere on this screen — the toggle rows are native `Toggle`.
//
//  Hides `RootTabView`'s bottom tab bar while pushed — see
//  `TabBarVisibility`'s header comment for why a plain
//  `.toolbar(_:for: .tabBar)` can't do this here.
//

import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var viewModel = NotificationSettingsViewModel()
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: "알림 설정", onBack: { dismiss() })

            List {
                Section {
                    NotificationSettingRow(titleKey: "마감 D-day", isOn: $viewModel.preferences.deadlineDDayAlerts)
                    NotificationSettingRow(titleKey: "새 공지사항 등록") {
                        // TODO: 공지사항 알림 세부 설정 화면 연동 필요
                    }
                } header: {
                    Text("공지사항")
                        .font(.noticeTitle)
                        .foregroundStyle(Color.textPrimary)
                }

                Section {
                    NotificationSettingRow(titleKey: "사물함 결과") {
                        // TODO: 사물함 결과 알림 세부 설정 화면 연동 필요
                    }
                } header: {
                    Text("사물함")
                        .font(.noticeTitle)
                        .foregroundStyle(Color.textPrimary)
                }

                Section {
                    NotificationSettingRow(titleKey: "댓글", isOn: $viewModel.preferences.commentAlerts)
                } header: {
                    Text("커뮤니티")
                        .font(.noticeTitle)
                        .foregroundStyle(Color.textPrimary)
                }
            }
            .listStyle(.plain)
            .background(Color.appBackground)
        }
        .background(Color.appBackground)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { tabBarVisibility.isHidden = true }
        .onDisappear { tabBarVisibility.isHidden = false }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
    .environmentObject(TabBarVisibility())
}
