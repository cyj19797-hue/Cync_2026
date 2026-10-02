//
//  CommentListView.swift
//  Cync
//
//  The "댓글" section's list body on "5-1 게시글": empty-state message when
//  there are no comments yet, otherwise each top-level `CommentThread`
//  (built by `CommunityPostDetailViewModel`) rendered as a `CommentRow`
//  followed by its replies, each reply indented via `CommentRow`'s own
//  `isReply` flag.
//
//  Each row carries `.id(comment.id)` so the detail screen can scroll to a
//  comment the user just posted.
//

import SwiftUI

struct CommentListView: View {
    let threads: [CommentThread]
    let authorLabel: (Comment) -> CommentAuthorLabel
    let actions: (Comment) -> [CommentAction]
    let onLike: (Comment) -> Void
    let onReply: (Comment) -> Void
    /// A comment's ⋮ was tapped — the screen opens its menu for it.
    let onMore: (Comment) -> Void

    var body: some View {
        if threads.isEmpty {
            Text(.commentEmpty)
                .font(.communityPostBody).tracking(Tracking.communityPostBody)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, Spacing.xl)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(threads) { thread in
                    row(for: thread.comment, isReply: false)

                    ForEach(thread.replies) { reply in
                        row(for: reply, isReply: true)
                    }
                }
            }
        }
    }

    private func row(for comment: Comment, isReply: Bool) -> some View {
        CommentRow(
            comment: comment,
            authorLabel: authorLabel(comment),
            isReply: isReply,
            actions: actions(comment),
            onLike: { onLike(comment) },
            // Replies can't be replied to — the server allows one level.
            onReply: isReply ? nil : { onReply(comment) },
            onMore: { onMore(comment) }
        )
        .id(comment.id)
    }
}

#Preview("댓글 없음") {
    CommentListView(
        threads: [],
        authorLabel: { _ in .anonymous(number: 1) },
        actions: { _ in [] },
        onLike: { _ in },
        onReply: { _ in },
        onMore: { _ in }
    )
    .padding()
}

#Preview("댓글 + 대댓글") {
    let labels = CommentAuthorLabel.labels(for: Comment.mockList, postAuthorId: "20231012")
    return CommentListView(
        threads: CommentThread.threads(from: Comment.mockList),
        authorLabel: { labels[$0.id] ?? .anonymous(number: 0) },
        actions: { _ in [.report] },
        onLike: { _ in },
        onReply: { _ in },
        onMore: { _ in }
    )
    .padding()
}
