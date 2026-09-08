//
//  CommunityPostDetailView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `228:1790` ("5-1 게시글").
//  Post header (`228:1994`: author, title, body, reactions, kebab) +
//  "댓글 섹션" (`299:2001`): a `calendarSurface` panel listing `CommentRow`s
//  via `CommentListView`. Pushed from CommunityView via NavigationLink; the
//  back chevron comes from `ScreenNavigationBar` (system nav bar hidden),
//  passed an empty title since Figma's nav bar here has no title text.
//
//  Only this screen has the kebab — CommunityView's row list doesn't. Its
//  popup (`isActionMenuPresented`) is placeholder/demo content only (see
//  the TODO on it below); the real 공유/저장/신고 flow this used to open
//  (`.communityPostActionMenu(target:)`) was removed, and isn't what's
//  wired up here — replace the demo actions with whatever this menu should
//  actually do.
//
//  Comment/reply composing (`composeTarget`) presents
//  Components/CommentComposeView.swift — a centered, dimmed-backdrop popup
//  (`composeOverlay`), not a system `.sheet` — this project's UI rule
//  (CLAUDE.md) reserves `.sheet` for cases explicitly asked to use the
//  native look, and this is a custom-cornered card, not a bottom sheet.
//
//  No UIKit anywhere on this screen.
//

import SwiftUI

struct CommunityPostDetailView: View {
    @StateObject private var viewModel: CommunityPostDetailViewModel
    @StateObject private var keyboard = KeyboardObserver()
    @State private var composeTarget: ComposeTarget?
    @State private var isActionMenuPresented = false
    @Environment(\.dismiss) private var dismiss

    init(post: CommunityPost, previewComments: [Comment] = []) {
        let viewModel = CommunityPostDetailViewModel(post: post)
        viewModel.comments = previewComments
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenNavigationBar(titleKey: "", onBack: { dismiss() })

            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        postHeader
                        commentsSection
                    }
                }
                .background(Color.appBackground)
                // TODO: demo placeholder — swap these actions/labels for
                // whatever this menu should actually do.
                .confirmationDialog(
                    "더보기",
                    isPresented: $isActionMenuPresented,
                    titleVisibility: .hidden
                ) {
                    Button("데모 메뉴 1") {}
                    Button("데모 메뉴 2") {}
                    Button("데모 메뉴 3", role: .destructive) {}
                }
                .task {
                    await viewModel.loadComments()
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

                if let composeTarget {
                    composeOverlay(for: composeTarget)
                }
            }
            .animation(.easeOut(duration: 0.25), value: composeTarget?.id)
        }
        .background(Color.appBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Centered `CommentComposeView` over a tap-to-dismiss dim backdrop —
    /// this project's custom-modal pattern (see this file's header
    /// comment), not `.sheet`. `keyboard.height > 0` switches the card's
    /// frame alignment from `.center` to `.bottom` once the comment field
    /// is focused — this container is already inset by the system's own
    /// keyboard-avoidance (confirmed empirically: adding a second,
    /// manual keyboard-height inset on top of it overshoots and shoves the
    /// card off the top of the screen), so only a small fixed
    /// `Spacing.sm` gap is added, not `keyboard.height` itself.
    private func composeOverlay(for target: ComposeTarget) -> some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { composeTarget = nil }
                .transition(.opacity)

            CommentComposeView(replyingToAuthor: target.replyingToAuthor) { text, isAnonymous in
                composeTarget = nil
                Task {
                    await viewModel.addComment(
                        content: text,
                        parentCommentId: target.parentCommentId,
                        isAnonymous: isAnonymous
                    )
                }
            }
            .padding(.horizontal, Spacing.md)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: keyboard.height > 0 ? .bottom : .center
            )
            .padding(.bottom, keyboard.height > 0 ? Spacing.sm : 0)
            .animation(.easeOut(duration: 0.25), value: keyboard.height)
            .transition(.scale(scale: 0.92).combined(with: .opacity))
        }
    }

    private var postHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .top, spacing: Spacing.xs) {
                AuthorLine(authorName: viewModel.post.displayAuthorName, createdAt: viewModel.post.createdAt)

                Spacer(minLength: 0)

                // Figma: "더보기(케밥) 버튼" — opens a demo placeholder popup
                // (see `isActionMenuPresented`'s `.confirmationDialog` above).
                Button {
                    isActionMenuPresented = true
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .foregroundStyle(Color.textPrimary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            Text(viewModel.post.title)
                .font(.postDetailTitle)
                .foregroundStyle(Color.textPrimary)
                .padding(.top, Spacing.xxs)

            Text(viewModel.post.content)
                .font(.communityPostBody)
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: Spacing.xs) {
                Button {
                    viewModel.togglePostLike()
                } label: {
                    reactionLabel(
                        systemImage: viewModel.post.likeCount > 0 ? "heart.fill" : "heart",
                        count: viewModel.post.likeCount
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(viewModel.post.likeCount > 0 ? Color.brandPrimary : Color.textSecondary)

                // Total comment count, replies included — the flat
                // `comments` array makes this just its `count`, matching
                // the feed row's "♡2 💬2" badge convention.
                reactionLabel(systemImage: "bubble.right", count: viewModel.comments.count)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.md)
    }

    private func reactionLabel(systemImage: String, count: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: systemImage)
            Text("\(count)")
        }
        .font(.communityReactionCount)
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            commentsSectionHeader

            CommentListView(
                threads: viewModel.commentThreads,
                onLike: { viewModel.toggleCommentLike($0) },
                onReply: { comment in composeTarget = .reply(comment) }
            )
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.calendarSurface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray300)
                .frame(height: 1)
        }
    }

    private var commentsSectionHeader: some View {
        HStack {
            Text("댓글")
                .font(.commentsSectionTitle)
                .foregroundStyle(Color.textPrimary)

            Spacer(minLength: 0)

            Button {
                composeTarget = .newComment
            } label: {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "square.and.pencil")
                    Text("댓글 달기")
                }
                .font(.commentReplyButton)
                .foregroundStyle(Color.brandPrimary)
            }
            .buttonStyle(.plain)
        }
    }

    /// What `CommentComposeView` is being presented for — a brand new
    /// top-level comment, or a reply to a specific existing one.
    private enum ComposeTarget: Identifiable {
        case newComment
        case reply(Comment)

        var id: String {
            switch self {
            case .newComment: return "new"
            case .reply(let comment): return "reply-\(comment.id)"
            }
        }

        var replyingToAuthor: String? {
            if case .reply(let comment) = self { return comment.displayAuthorName }
            return nil
        }

        var parentCommentId: Int? {
            if case .reply(let comment) = self { return comment.id }
            return nil
        }
    }
}

#Preview("댓글 없음") {
    NavigationStack {
        CommunityPostDetailView(post: CommunityPost.mockList[0])
    }
}

#Preview("댓글 1개 이상") {
    NavigationStack {
        CommunityPostDetailView(
            post: CommunityPost.mockList[0],
            previewComments: [Comment.mockList[0]]
        )
    }
}

#Preview("댓글 + 대댓글") {
    NavigationStack {
        CommunityPostDetailView(post: CommunityPost.mockList[0], previewComments: Comment.mockList)
    }
}
