//
//  CyncNoticeDetailView.swift
//  Cync
//
//  Figma: "26 2 창학" file, frame `466:2742` ("6-2-1 공지사항 내용").
//  Pushed from CyncNoticeListView — a plain full-screen push, not the
//  centered dim-scrim dialog card `NoticeDetailView` uses for "2-1 공지글".
//  Just `ScreenNavigationBar` + title/date/content: this Figma frame has no
//  bookmark, translation toggle, or prev/next controls to reproduce.
//
//  Hides RootTabView's bottom tab bar while pushed — see
//  `TabBarVisibility`'s header comment for why a plain
//  `.toolbar(_:for: .tabBar)` can't do this here.
//

import SwiftUI

struct CyncNoticeDetailView: View {
    let notice: CyncNotice
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: "공지사항", onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(notice.title)
                            .font(.postDetailTitle).tracking(Tracking.postDetailTitle)
                            .foregroundStyle(Color.textPrimary)

                        Text(notice.dateText)
                            .font(.cyncNoticeDetailDate).tracking(Tracking.cyncNoticeDetailDate)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.xs)

                    Text(notice.content)
                        .font(.noticeDetailBody).tracking(Tracking.noticeDetailBody)
                        .foregroundStyle(Color.textPrimary)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.cardInset)
                }
            }
        }
        .background(Color.appBackground)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { tabBarVisibility.isHidden = true }
        .onDisappear { tabBarVisibility.isHidden = false }
    }
}

#Preview {
    NavigationStack {
        CyncNoticeDetailView(notice: CyncNotice.mockList[0])
    }
    .environmentObject(TabBarVisibility())
}
