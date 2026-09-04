//
//  CommentRow.swift
//  Cync
//
//  Figma node `295:1985` ("댓글") — one comment or reply: author line,
//  content, a heart button, and (top-level comments only) "답글 달기". A
//  reply (`295:2003`, `pl-[32px]`) is the same row indented, with no reply
//  button — modeled with `isReply` rather than two near-duplicate views.
//

import SwiftUI

struct CommentRow: View {
    let comment: Comment
    var isReply: Bool = false
    let onLike: () -> Void
    var onReply: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                AuthorLine(authorName: comment.displayAuthorName, createdAt: comment.createdAt)
                Text(comment.deleted ? "삭제된 댓글입니다" : comment.content)
                    .font(.communityPostBody)
                    .foregroundStyle(comment.deleted ? Color.gray400 : Color.textPrimary)
            }

            // Soft-deleted comments (`comment.deleted`) hide both actions —
            // liking or replying to "삭제된 댓글입니다" doesn't make sense.
            if !comment.deleted {
                HStack(spacing: Spacing.xs) {
                    Button(action: onLike) {
                        Image(systemName: comment.likeCount > 0 ? "heart.fill" : "heart")
                            .foregroundStyle(comment.likeCount > 0 ? Color.brandPrimary : Color.textPrimary)
                    }
                    .buttonStyle(.plain)

                    if let onReply {
                        Button(action: onReply) {
                            Text("답글 달기")
                                .font(.commentReplyButton)
                                .foregroundStyle(Color.gray400)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()
                .overlay(Color.borderLight)
        }
        .padding(.leading, isReply ? Spacing.xl : 0)
    }
}

#Preview {
    VStack(spacing: Spacing.xxs) {
        CommentRow(comment: Comment.mockList[0], onLike: {}, onReply: {})
        CommentRow(comment: Comment.mockList[3], isReply: true, onLike: {})
    }
    .padding()
}
