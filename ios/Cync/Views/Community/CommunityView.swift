//
//  CommunityView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `47:928` ("5 커뮤니티").
//  Top bar (`47:930`) + a feed of `CommunityPostRow` (`139:1657` etc.).
//  Tapping a row pushes "5-1 게시글" (`CommunityPostDetailView`) via
//  `.navigationDestination(item:)`; the compose ("Mode") button pushes
//  "5-2 게시글 등록" (`CommunityPostComposeView`) the same way, prepending
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
//  `CommunityViewModel.filteredPosts`). The compose button still sits in
//  the top bar, just left of search, until its final spot is decided —
//  search takes the rightmost slot so it's in the same place as on the
//  other tabs. Pull-to-refresh reloads the feed; an empty feed (or an
//  empty search result) shows a centered message instead of a blank list.
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
                    HStack(spacing: Spacing.md) {
                        Button {
                            isComposePresented = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .foregroundStyle(viewModel.isBanned ? Color.gray400 : Color.textPrimary)
                        }
                        .disabled(viewModel.isBanned)
                        .accessibilityLabel(Text(.communityWrite))

                        Button {
                            isSearchPresented = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.textPrimary)
                        }
                        .accessibilityLabel(Text(.commonSearch))
                    }
                }

                if isSearchPresented {
                    SearchBar(text: $viewModel.searchText, isActive: $isSearchPresented)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.top, Spacing.xs)
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
                .padding(.top, Spacing.xxs)
                .refreshable { await viewModel.load() }
                .overlay {
                    if viewModel.hasLoaded && viewModel.filteredPosts.isEmpty {
                        emptyState
                    }
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
