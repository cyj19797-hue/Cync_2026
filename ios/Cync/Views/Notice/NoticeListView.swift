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
//  the root's `.showsTabBar(selectedNotice == nil)` drops `RootTabView`'s
//  bottom tab bar while it's open (see TabBarVisibility.swift), so the
//  card gets the extra room instead of sharing the screen with it.
//

import SwiftUI

struct NoticeListView: View {
    @StateObject private var viewModel = NoticeListViewModel()
    @State private var isSearchPresented = false
    @State private var selectedNotice: Notice?

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
    }

    private var content: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Figma의 체크박스 아이콘 대신 공지 의미에 맞는 확성기(SF Symbol) 사용
                AppTopBar(title: .tabNotices) {
                    Image(systemName: "megaphone")
                } trailing: {
                    Button {
                        isSearchPresented = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.textPrimary)
                    }
                    .accessibilityLabel(Text(.commonSearch))
                }

                if isSearchPresented {
                    SearchBar(text: $viewModel.searchText, isActive: $isSearchPresented)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.top, Spacing.xs)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    CategoryFilterRow(selectedCategory: $viewModel.selectedCategory)
                        .padding(.top, Spacing.xs)
                        .transition(.opacity)
                }

                List {
                    ForEach(viewModel.filteredNotices) { notice in
                        NoticeRow(
                            notice: notice,
                            showsCategory: viewModel.selectedCategory == .all,
                            onToggleBookmark: { viewModel.toggleBookmark(for: notice) },
                            onSelect: { selectedNotice = notice }
                        )
                        .listRowSeparatorTint(Color.borderLight)
                        .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
                    }
                }
                .listStyle(.plain)
            }
            .background(Color.appBackground)
            .animation(.default, value: isSearchPresented)
            .toolbar(.hidden, for: .navigationBar)
            // Main tab screen — the bottom tab bar shows only while this
            // root is on screen and no notice detail covers it (see
            // TabBarVisibility.swift).
            .showsTabBar(selectedNotice == nil)
            .task {
                await viewModel.load()
            }
            .alert(
                Text(.commonError),
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { isPresented in if !isPresented { viewModel.errorMessage = nil } }
                )
            ) {
                Button(.commonOk, role: .cancel) {}
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
