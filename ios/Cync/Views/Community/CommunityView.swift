//
//  CommunityView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `47:928` ("5 커뮤니티").
//  Top bar (`47:930`) + a feed of `CommunityPostRow` (`139:1657` etc.).
//  Tapping a row pushes "5-1 게시글" (`CommunityPostDetailView`) via
//  `.navigationDestination(item:)`; the round floating compose button at
//  the bottom right pushes "5-2 게시글 등록" (`CommunityPostComposeView`)
//  the same way, prepending
//  the finished draft to `posts`. The bottom tab bar (`47:931`) is not
//  built here — it's RootTabView's `TabView`, this is just its "커뮤니티" tab
//  content.
//
//  No UIKit anywhere on this screen — `List` supplies the row separators
//  Figma drew as image lines. Rows have no trailing "더보기" button —
//  the 공유/저장/신고 action menu that used to live behind it
//  (`.communityPostActionMenu(target:)`) has been removed.
//
//  Header layout mirrors NoticeListView: the magnifying glass opens the
//  shared `SearchBar` under the top bar (client-side title/body filter,
//  `CommunityViewModel.filteredPosts`) — the top bar holds only search,
//  like the other tabs. Composing is the floating button
//  (`FloatingComposeButton`), disabled (gray) while the user is banned; the list
//  keeps extra room at the bottom so the last row can scroll out from
//  under it. Pull-to-refresh reloads the feed; an empty feed (or an empty
//  search result) shows a centered message instead of a blank list.
//
//  Row insets and the list's top padding match NoticeListView, so the gap
//  under the header and the row density are the same on both tabs.
//
//  Figma node `257:6758` ("프로필 설정") gates first-time entry: while
//  `viewModel.needsNicknameSetup` is true, `ProfileSetupView` replaces this
//  screen's whole content (bottom tab bar included — the feed root, which
//  carries `.showsTabBar()`, is off screen) instead of the normal feed.
//

import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @State private var selectedPost: CommunityPost?
    @State private var isComposePresented = false
    @State private var isSearchPresented = false
    @State private var isReportManagePresented = false
    /// Admin check reads the shared `GET /api/me` cache.
    @ObservedObject private var session = CurrentUserSession.shared

    var body: some View {
        Group {
            if viewModel.needsNicknameSetup, let profile = viewModel.profile {
                ProfileSetupView(profile: profile) {
                    viewModel.completeNicknameSetup()
                }
            } else {
                feed
            }
        }
        .task { await viewModel.load() }
    }

    private var feed: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTopBar(title: .tabCommunity) {
                    Image(systemName: "face.smiling")
                } trailing: {
                    TopBarIconButton(systemImage: "magnifyingglass", labelKey: .commonSearch) {
                        isSearchPresented = true
                    }
                    // Admins only — 신고 관리, with a red dot while any
                    // report is unresolved.
                    if session.profile?.isAdmin == true {
                        reportManageButton
                    }
                }

                if isSearchPresented {
                    SearchBar(text: $viewModel.searchText, isActive: $isSearchPresented)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.screenContentTop)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                List {
                    ForEach(viewModel.filteredPosts) { post in
                        CommunityPostRow(
                            post: post,
                            onSelect: { selectedPost = post }
                        )
                        .listRowSeparatorTint(Color.borderLight)
                        .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
                    }
                }
                .listStyle(.plain)
                // Rows add `Spacing.xs` (inset) + `Spacing.xxs` (their own
                // padding) above the first post's text.
                .padding(.top, Spacing.screenContentTop - Spacing.xs - Spacing.xxs)
                .refreshable { await viewModel.load() }
                // Room under the last row so it isn't stuck behind the
                // floating compose button.
                .contentMargins(.bottom, FloatingComposeButton.reservedHeight, for: .scrollContent)
                .overlay {
                    if viewModel.hasLoaded && viewModel.filteredPosts.isEmpty {
                        emptyState
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    FloatingComposeButton(labelKey: .communityWrite, isDisabled: viewModel.isBanned) {
                        isComposePresented = true
                    }
                    .padding(Spacing.md)
                }
            }
            .animation(.default, value: isSearchPresented)
            .navigationDestination(item: $selectedPost) { post in
                CommunityPostDetailView(
                    post: post,
                    onPostDeleted: { deletedId in
                        viewModel.posts.removeAll { $0.id == deletedId }
                    },
                    onPostChanged: { updated in
                        if let index = viewModel.posts.firstIndex(where: { $0.id == updated.id }) {
                            viewModel.posts[index] = updated
                        }
                    }
                )
            }
            .navigationDestination(isPresented: $isReportManagePresented) {
                AdminReportManageView()
                    .onDisappear {
                        Task { await viewModel.refreshPendingReports() }
                    }
            }
            .navigationDestination(isPresented: $isComposePresented) {
                CommunityPostComposeView { newPost in
                    viewModel.posts.insert(newPost, at: 0)
                }
            }
            .background(Color.appBackground)
            .toolbar(.hidden, for: .navigationBar)
            // Main tab screen — the bottom tab bar shows only while this
            // root is on screen (see TabBarVisibility.swift).
            .showsTabBar()
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

    private var reportManageButton: some View {
        TopBarIconButton(systemImage: "exclamationmark.bubble", labelKey: .adminReportTitle, isAdminOnly: true) {
            isReportManagePresented = true
        }
        .overlay(alignment: .topTrailing) {
            if viewModel.pendingReportCount > 0 {
                Circle()
                    .fill(Color.adminDanger)
                    .frame(width: 8, height: 8)
                    // On the icon's top-right corner, not the 44pt box's.
                    .offset(x: -10, y: 10)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityValue(viewModel.pendingReportCount > 0 ? Text(.adminReportHasPending) : Text(verbatim: ""))
    }

    private var emptyState: some View {
        Text(viewModel.isSearching ? .communitySearchEmpty : .communityEmpty)
            .font(.emptyStateMessage).tracking(Tracking.emptyStateMessage)
            .foregroundStyle(Color.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.md)
            // Taps and pull-to-refresh drags go through to the list.
            .allowsHitTesting(false)
    }
}

#Preview {
    CommunityView()
        .environmentObject(TabBarVisibility())
}
