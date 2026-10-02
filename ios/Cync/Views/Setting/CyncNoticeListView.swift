//
//  CyncNoticeListView.swift
//  Cync
//
//  Figma: "26 2 창학" file, frame `464:2503` ("6-2 Cync 공지").
//  Pushed from SettingsView's "Cync 공지" row — back chevron + title come
//  from `ScreenNavigationBar` (system nav bar hidden). The title is the
//  same "Cync 공지" / "Cync Notice" as that row (not the 공지사항 tab's
//  name), so it isn't mistaken for the 공지사항 tab. Rows are the app
//  team's own announcements (`CyncNotice`), distinct from the
//  school/student-council board on `NoticeListView`. Tapping a row pushes
//  "6-2-1 공지사항 내용" (`CyncNoticeDetailView`) via `.navigationDestination(item:)`,
//  the same pattern `CommunityView` uses to push its post detail.
//
//  Beyond Figma: a skeleton while loading, an empty state, an inline
//  error with 다시 시도 (not a system `.alert`), and pull-to-refresh.
//
//  No bottom tab bar here: only the five main tab screens show it — see
//  TabBarVisibility.swift.
//

import SwiftUI

struct CyncNoticeListView: View {
    @StateObject private var viewModel = CyncNoticeListViewModel()
    @ObservedObject private var readStore = CyncNoticeReadStore.shared
    @State private var selectedNotice: CyncNotice?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: .settingsCyncNotice, onBack: { dismiss() })

            switch viewModel.phase {
            case .loading:
                skeleton
            case .failed:
                errorState
            case .loaded:
                list
            }
        }
        .background(Color.appBackground)
        .navigationDestination(item: $selectedNotice) { notice in
            CyncNoticeDetailView(notice: notice)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.notices) { notice in
                CyncNoticeRow(notice: notice, isRead: readStore.isRead(notice.id)) {
                    selectedNotice = notice
                }
                .listRowSeparatorTint(Color.borderLight)
                .listRowInsets(Self.rowInsets)
            }
        }
        .listStyle(.plain)
        .refreshable { await viewModel.load() }
        .overlay {
            if viewModel.notices.isEmpty {
                emptyState
            }
        }
    }

    /// Placeholder rows in the real row's shape, grayed out by `.redacted`.
    private var skeleton: some View {
        List {
            ForEach(1...5, id: \.self) { _ in
                CyncNoticeRow(notice: .placeholder, isRead: true) {}
                    .listRowSeparatorTint(Color.borderLight)
                    .listRowInsets(Self.rowInsets)
            }
        }
        .listStyle(.plain)
        .redacted(reason: .placeholder)
        .disabled(true)
        .accessibilityHidden(true)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: "megaphone")
                .font(.noticeDetailTitle)
                .foregroundStyle(Color.textSecondary)
                .accessibilityHidden(true)

            Text(.cyncNoticeEmptyTitle)
                .font(.noticeTitle).tracking(Tracking.noticeTitle)
                .foregroundStyle(Color.textPrimary)

            Text(.cyncNoticeEmptyMessage)
                .font(.emptyStateMessage).tracking(Tracking.emptyStateMessage)
                .foregroundStyle(Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Spacing.screenHorizontal)
        // Taps and pull-to-refresh drags go through to the list.
        .allowsHitTesting(false)
    }

    private var errorState: some View {
        VStack(spacing: Spacing.md) {
            VStack(spacing: Spacing.xs) {
                Text(.cyncNoticeLoadFailed)
                    .font(.noticeTitle).tracking(Tracking.noticeTitle)
                    .foregroundStyle(Color.textPrimary)

                Text(.cyncNoticeLoadFailedMessage)
                    .font(.emptyStateMessage).tracking(Tracking.emptyStateMessage)
                    .foregroundStyle(Color.textSecondary)
            }
            .multilineTextAlignment(.center)

            // Dark accent, not `eventAccent`: white on #36AFFF is only ~2.3:1.
            PrimaryActionButton(titleKey: .commonRetry, tint: .eventAccentDark) {
                Task { await viewModel.load() }
            }
            .frame(maxWidth: 200)
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private static let rowInsets = EdgeInsets(
        top: Spacing.xs,
        leading: Spacing.screenHorizontal,
        bottom: Spacing.xs,
        trailing: Spacing.screenHorizontal
    )
}

#Preview {
    NavigationStack {
        CyncNoticeListView()
    }
}
