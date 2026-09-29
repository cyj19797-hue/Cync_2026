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

import SwiftUI

struct CommentListView: View {
    let threads: [CommentThread]
    let onLike: (Comment) -> Void
    let onReply: (Comment) -> Void

    var body: some View {
        if threads.isEmpty {
            Text("첫 댓글을 달아보세요.")
                .font(.communityPostBody).tracking(Tracking.communityPostBody)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, Spacing.xl)
        } else {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(threads) { thread in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        CommentRow(
                            comment: thread.comment,
                            onLike: { onLike(thread.comment) },
                            onReply: { onReply(thread.comment) }
                        )

                        ForEach(thread.replies) { reply in
                            CommentRow(
                                comment: reply,
                                isReply: true,
                                onLike: { onLike(reply) }
                            )
                        }
                    }
                }
            }
        }
    }
}

#Preview("댓글 없음") {
    CommentListView(threads: [], onLike: { _ in }, onReply: { _ in })
        .padding()
}

#Preview("댓글 + 대댓글") {
    CommentListView(
        threads: CommentThread.threads(from: Comment.mockList),
        onLike: { _ in },
        onReply: { _ in }
    )
    .padding()
}
