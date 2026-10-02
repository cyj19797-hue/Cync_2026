//
//  CommentListView.swift
//  Cync
//
//  The "댓글" section's list body on "5-1 게시글": empty-state message when
//  there are no comments yet, otherwise each top-level `CommentThread`
//  (built by `CommunityPostDetailViewModel`) rendered as a `CommentRow`
//  followed by its replies. Each row is told where it sits in its thread
//  (`connector` — the reply stem — and `showsDivider`, only on a thread's
//  last row), so a comment and its replies read as one group.
//
//  Each row carries `.id(comment.id)` so the detail screen can scroll to a
//  comment the user just posted.
//

import SwiftUI

struct CommentListView: View {
    let threads: [CommentThread]
    let authorLabel: (Comment) -> CommentAuthorLabel
    /// The post's author name, shown before "글쓴이" on their comments.
    var postAuthorName: String = ""
    /// Your own comments — no heart on those.
    var isMine: (Comment) -> Bool = { _ in false }
    /// The comment being replied to right now — its reply icon is tinted.
    var replyTargetID: Int?
    let actions: (Comment) -> [CommentAction]
    let onLike: (Comment) -> Void
    let onReply: (Comment) -> Void
    /// A comment's ⋮ was tapped — the screen opens its menu for it.
    let onMore: (Comment) -> Void
    /// A comment's direct delete/report icon was tapped.
    var onAction: (Comment, CommentAction) -> Void = { _, _ in }

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
                    row(for: thread.comment, connector: .none, showsDivider: thread.replies.isEmpty)

                    ForEach(thread.replies) { reply in
                        let isLast = reply.id == thread.replies.last?.id
                        row(for: reply, connector: isLast ? .last : .continuing, showsDivider: isLast)
                    }
                }
            }
        }
    }

    private func row(for comment: Comment, connector: CommentRow.Connector, showsDivider: Bool) -> some View {
        CommentRow(
            comment: comment,
            authorLabel: authorLabel(comment),
            postAuthorName: postAuthorName,
            connector: connector,
            showsDivider: showsDivider,
            canLike: !isMine(comment),
            isReplyTarget: comment.id == replyTargetID,
            actions: actions(comment),
            onLike: { onLike(comment) },
            // Replies can't be replied to — the server allows one level.
            onReply: connector == .none ? { onReply(comment) } : nil,
            onMore: { onMore(comment) },
            onAction: { onAction(comment, $0) }
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
