//
//  NoticeListView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `30:354` ("2 공지사항").
//  Top bar (`41:816`) + category filter row (`42:108`) + notice list (`42:122`).
//  The bottom tab bar (`30:577`) is not built here — it's the app-wide
//  `TabView` in RootTabView.swift, this view is just its "공지사항" tab content.
//
//  Figma's "2-1 공지글" is a full-screen dialog with no tab bar behind it —
//  `tabBarVisibility` hides `RootTabView`'s bottom tab bar while it's open
//  (see `TabBarVisibility`'s header comment for why a plain
//  `.toolbar(_:for: .tabBar)` can't do this against a hand-rolled tab bar),
//  so the card gets the extra room instead of sharing the screen with it.
//

import SwiftUI

struct NoticeListView: View {
    @StateObject private var viewModel = NoticeListViewModel()
    @State private var isSearchPresented = false
    @State private var selectedNotice: Notice?
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility

    var body: some View {
        ZStack {
            content

            if let notice = selectedNotice {
                NoticeDetailView(
                    notice: notice,
                    onToggleBookmark: {
                        viewModel.toggleBookmark(for: notice)
                        selectedNotice = viewModel.notices.first { $0.id == notice.id }
                    },
                    onDismiss: { selectedNotice = nil },
                    onPrevious: viewModel.notice(before: notice).map { previous in
                        { selectedNotice = previous }
                    },
                    onNext: viewModel.notice(after: notice).map { next in
                        { selectedNotice = next }
                    }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.default, value: selectedNotice?.id)
        .onChange(of: selectedNotice?.id) { _, newValue in
            tabBarVisibility.isHidden = newValue != nil
        }
        .onDisappear {
            tabBarVisibility.isHidden = false
        }
    }

    private var content: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // TODO: Assets에 커스텀 "CheckSquare" 아이콘 추가 필요 — 우선 SF Symbol로 대체
                AppTopBar(title: "공지사항") {
                    Image(systemName: "checkmark.square")
                } trailing: {
                    Button {
                        isSearchPresented = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.textPrimary)
                    }
                    .accessibilityLabel("검색")
                }

                if isSearchPresented {
                    SearchBar(text: $viewModel.searchText, isActive: $isSearchPresented)
                        .padding(.horizontal, Spacing.xs)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    CategoryFilterRow(selectedCategory: $viewModel.selectedCategory)
                        .transition(.opacity)
                }

                List {
                    ForEach(viewModel.filteredNotices) { notice in
                        NoticeRow(
                            notice: notice,
                            onToggleBookmark: { viewModel.toggleBookmark(for: notice) },
                            onSelect: { selectedNotice = notice }
                        )
                        .listRowSeparatorTint(Color.borderLight)
                        .listRowInsets(EdgeInsets(top: Spacing.xxs, leading: Spacing.md, bottom: Spacing.xxs, trailing: Spacing.md))
                    }
                }
                .listStyle(.plain)
            }
            .background(Color.appBackground)
            .animation(.default, value: isSearchPresented)
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.load()
            }
            .alert(
                "오류",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { isPresented in if !isPresented { viewModel.errorMessage = nil } }
                )
            ) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

#Preview {
    NoticeListView()
        .environmentObject(TabBarVisibility())
}
