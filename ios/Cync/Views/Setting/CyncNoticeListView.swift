//
//  CyncNoticeListView.swift
//  Cync
//
//  Figma: "26 2 창학" file, frame `464:2503` ("6-2 Cync 공지").
//  Pushed from SettingsView's "Cync 공지" row — back chevron + title come
//  from `ScreenNavigationBar` (system nav bar hidden), matching Figma's own
//  center label ("공지사항"), not the row's own "Cync 공지" wording. Rows are
//  the app team's own announcements (`CyncNotice`), distinct from the
//  school/student-council board on `NoticeListView`. Tapping a row pushes
//  "6-2-1 공지사항 내용" (`CyncNoticeDetailView`) via `.navigationDestination(item:)`,
//  the same pattern `CommunityView` uses to push its post detail.
//
//  Hides RootTabView's bottom tab bar while pushed — see
//  `TabBarVisibility`'s header comment for why a plain
//  `.toolbar(_:for: .tabBar)` can't do this here.
//

import SwiftUI

struct CyncNoticeListView: View {
    @State private var notices = CyncNotice.mockList
    @State private var selectedNotice: CyncNotice?
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: "공지사항", onBack: { dismiss() })

            List {
                ForEach(notices) { notice in
                    CyncNoticeRow(notice: notice) {
                        selectedNotice = notice
                    }
                    .listRowSeparatorTint(Color.borderLight)
                    .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
                }
            }
            .listStyle(.plain)
        }
        .background(Color.appBackground)
        .navigationDestination(item: $selectedNotice) { notice in
            CyncNoticeDetailView(notice: notice)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { tabBarVisibility.isHidden = true }
        .onDisappear { tabBarVisibility.isHidden = false }
    }
}

#Preview {
    NavigationStack {
        CyncNoticeListView()
    }
    .environmentObject(TabBarVisibility())
}
