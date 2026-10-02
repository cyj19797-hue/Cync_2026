//
//  CommentRow.swift
//  Cync
//
//  Figma node `295:1985` ("댓글") — one comment or reply, in two lines:
//    1. "작성자 · 시간" on the left; heart (+ count), "답글", ⋮ on the right
//    2. the comment text
//  The actions used to take a third line of their own; moving them onto
//  the author line keeps a short comment to two lines.
//
//  A reply (`295:2003`, `pl-[32px]`) is the same row indented, with no
//  reply button (the server allows only one level) — modeled with
//  `isReply` rather than two near-duplicate views.
//
//  The heart, "답글" and ⋮ are small on screen but each gets a 44×44pt
//  touch area via `.minimumHitTarget()`.
//
//  ⋮ opens the same `PopupMenu` as the post's own ⋮ (the screen owns the
//  menu; this row only marks where it opens, via `popupMenuAnchor(id:)`
//  with `menuAnchorID`). A deleted comment ("삭제된 댓글입니다", only kept
//  when it still has replies) shows just that text: no author, actions or
//  menu.
//

import SwiftUI

struct CommentRow: View {
    let comment: Comment
    let authorLabel: CommentAuthorLabel
    var isReply: Bool = false
    /// Which ⋮ items this viewer gets; empty hides the ⋮ button.
    var actions: [CommentAction] = []
    let onLike: () -> Void
    var onReply: (() -> Void)?
    /// ⋮ tapped — the screen opens its `PopupMenu` under this row's anchor.
    var onMore: () -> Void = {}

    /// `PopupMenu` anchor id for this comment's ⋮.
    static func menuAnchorID(for comment: Comment) -> String {
        "comment-\(comment.id)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            if comment.deleted {
                Text(.commentDeleted)
                    .font(.communityPostBody).tracking(Tracking.communityPostBody)
                    .foregroundStyle(Color.gray400)
            } else {
                HStack(spacing: Spacing.md) {
                    AuthorLine(
                        authorName: authorLabel.text,
                        createdAt: comment.createdAt,
                        nameColor: authorLabel == .postAuthor ? .eventAccent : .textPrimary
                    )

                    Spacer(minLength: 0)

                    likeButton

                    if let onReply {
                        Button(action: onReply) {
                            Text(.commentReplyShort)
                                .font(.commentReplyButton).tracking(Tracking.commentReplyButton)
                                .foregroundStyle(Color.gray400)
                                .frame(minHeight: 20)
                                .minimumHitTarget()
                        }
                        .buttonStyle(.plain)
                    }

                    if !actions.isEmpty {
                        menu
                    }
                }

                Text(comment.content)
                    .font(.communityPostBody).tracking(Tracking.communityPostBody)
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, Spacing.xs)
        .overlay(alignment: .bottom) {
            Divider().overlay(Color.borderLight)
        }
        .padding(.leading, isReply ? Spacing.xl : 0)
    }

    private var likeButton: some View {
        Button(action: onLike) {
            HStack(spacing: 2) {
                Image(systemName: comment.isLikedByMe ? "heart.fill" : "heart")
                if comment.likeCount > 0 {
                    Text(comment.likeCount, format: .number)
                }
            }
            .font(.commentReplyButton).tracking(Tracking.commentReplyButton)
            .foregroundStyle(comment.isLikedByMe ? Color.eventAccent : Color.gray400)
            .frame(minWidth: 20, minHeight: 20)
            .minimumHitTarget()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(.commentLike))
        .accessibilityValue(comment.likeCount > 0 ? Text(comment.likeCount, format: .number) : Text(verbatim: ""))
        .accessibilityAddTraits(comment.isLikedByMe ? .isSelected : [])
    }

    private var menu: some View {
        Button(action: onMore) {
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .font(.commentReplyButton)
                .foregroundStyle(Color.gray400)
                .frame(width: 20, height: 20)
                .minimumHitTarget()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(.commentMore))
        .popupMenuAnchor(id: Self.menuAnchorID(for: comment))
    }
}

#Preview {
    VStack(spacing: 0) {
        CommentRow(comment: Comment.mockList[0], authorLabel: .anonymous(number: 1), actions: [.report], onLike: {}, onReply: {})
        CommentRow(comment: Comment.mockList[3], authorLabel: .postAuthor, isReply: true, actions: [.delete], onLike: {})
    }
    .padding()
}
