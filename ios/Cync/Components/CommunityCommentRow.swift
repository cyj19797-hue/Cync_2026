//
//  CommunityCommentRow.swift
//  test
//
//  Figma node `295:1985` ("댓글") — one comment or reply: author line,
//  content, a heart button, and (top-level comments only) "답글 달기". A
//  reply (`295:2003`, `pl-[32px]`) is the same row indented, with no reply
//  button — modeled with `isReply` rather than two near-duplicate views.
//

import SwiftUI

struct CommunityCommentRow: View {
    let comment: PostComment
    var isReply: Bool = false
    let onLike: () -> Void
    var onReply: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                AuthorLine(authorName: comment.authorName, createdAt: comment.createdAt)
                Text(comment.content)
                    .font(.communityPostBody)
                    .foregroundStyle(Color.textPrimary)
            }

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

            Divider()
                .overlay(Color.borderLight)
        }
        .padding(.leading, isReply ? Spacing.xl : 0)
    }
}

#Preview {
    VStack(spacing: Spacing.xxs) {
        CommunityCommentRow(comment: PostComment.mockList[0], onLike: {}, onReply: {})
        CommunityCommentRow(comment: PostComment.mockList[0].replies[0], isReply: true, onLike: {})
    }
    .padding()
}
