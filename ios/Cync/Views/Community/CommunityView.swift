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
//  Figma node `257:6758` ("프로필 설정") gates first-time entry: while
//  `viewModel.needsNicknameSetup` is true, `ProfileSetupView` replaces this
//  screen's whole content (bottom tab bar included, same as
//  `NoticeDetailView`'s full-screen takeover) instead of the normal feed.
//

import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @State private var selectedPost: CommunityPost?
    @State private var isComposePresented = false
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility

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
        .onChange(of: viewModel.needsNicknameSetup) { _, needsSetup in
            tabBarVisibility.isHidden = needsSetup
        }
        .onDisappear {
            tabBarVisibility.isHidden = false
        }
    }

    private var feed: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTopBar(title: .tabCommunity) {
                    Image(systemName: "face.smiling")
                } trailing: {
                    Button {
                        isComposePresented = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(viewModel.isBanned ? Color.gray400 : Color.textPrimary)
                    }
                    .disabled(viewModel.isBanned)
                    .accessibilityLabel(Text(.communityWrite))
                }

                List {
                    ForEach(viewModel.posts) { post in
                        CommunityPostRow(
                            post: post,
                            onSelect: { selectedPost = post }
                        )
                        .listRowSeparatorTint(Color.borderLight)
                        .listRowInsets(EdgeInsets(top: Spacing.md, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
                    }
                }
                .listStyle(.plain)
            }
            .navigationDestination(item: $selectedPost) { post in
                CommunityPostDetailView(post: post)
            }
            .navigationDestination(isPresented: $isComposePresented) {
                CommunityPostComposeView { newPost in
                    viewModel.posts.insert(newPost, at: 0)
                }
            }
            .background(Color.appBackground)
            .toolbar(.hidden, for: .navigationBar)
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
    CommunityView()
        .environmentObject(TabBarVisibility())
}
