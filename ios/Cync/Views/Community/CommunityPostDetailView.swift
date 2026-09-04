//
//  CommunityPostDetailView.swift
//  test
//
//  Figma: "26 2 창학" file, frame `228:1790` ("5-1 게시글").
//  Post header (`228:1994`: author, title, body, reactions, kebab menu) +
//  "댓글 섹션" (`299:2001`): a `calendarSurface` panel listing
//  `CommentRow`s via `CommentListView`. Pushed from CommunityView via
//  NavigationLink, so the back chevron comes from NavigationStack for free
//  — Figma's nav bar here has no title text, so no `.navigationTitle` is
//  set either. The kebab opens "커뮤니티 - 액션메뉴" the same way
//  CommunityView's row does — see Components/CommunityPostActionMenu.swift.
//
//  Comment/reply composing has no Figma frame yet, so
//  Components/CommentComposeView.swift reuses this screen's existing
//  bottom-sheet and button styles (see that file's header comment) rather
//  than inventing new ones.
//
//  No UIKit anywhere on this screen.
//

import SwiftUI

struct CommunityPostDetailView: View {
    @StateObject private var viewModel: CommunityPostDetailViewModel
    @State private var actionMenuTarget: CommunityPost?
    @State private var composeTarget: ComposeTarget?

    init(post: CommunityPost, previewComments: [Comment] = []) {
        let viewModel = CommunityPostDetailViewModel(post: post)
        viewModel.comments = previewComments
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                postHeader
                commentsSection
            }
        }
        .background(Color.appBackground)
        .communityPostActionMenu(target: $actionMenuTarget)
        .sheet(item: $composeTarget) { target in
            CommentComposeView(replyingToAuthor: target.replyingToAuthor) { text in
                Task { await viewModel.addComment(content: text, parentCommentId: target.parentCommentId) }
            }
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
        .navigationBarTitleDisplayMode(.inline)
    }

    private var postHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .top, spacing: Spacing.xs) {
                AuthorLine(authorName: viewModel.post.displayAuthorName, createdAt: viewModel.post.createdAt)

                Spacer(minLength: 0)

                // Figma: "더보기(케밥) 버튼" — opens "커뮤니티 - 액션메뉴".
                Button {
                    actionMenuTarget = viewModel.post
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
