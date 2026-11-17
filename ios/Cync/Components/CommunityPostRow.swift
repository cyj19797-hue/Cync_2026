//
//  CommunityPostRow.swift
//  test
//
//  Figma node `139:1657` ("게시글") — one post row: title, up to a 2-line
//  body preview, then one meta line: "3분 전 • 💬 2 ♡ 5". The meta line
//  mirrors `NoticeRow`'s "카테고리 · 날짜" line (same separator dot, same
//  secondary tone) so the two feeds scan the same way. No author name —
//  the feed only needs "when", and the detail screen already shows who.
//
//  Each reaction is shown only when its own count is at least 1 — a post
//  with comments but no likes shows just the comment count, not a "0"
//  alongside it. The dot sits only between the time and the reactions;
//  the comment and like counts sit next to each other without one.
//
//  Spacing matches `NoticeRow` (4pt between lines, 4pt row padding) so
//  roughly as many posts fit on screen as notices do.
//
//  The trailing "더보기" (kebab) button and its 공유하기/저장하기/신고하기
//  action menu (formerly `.communityPostActionMenu(target:)`,
//  Components/CommunityPostActionMenu.swift) have been removed from this
//  screen entirely — this row has no trailing button anymore.
//

import SwiftUI

struct CommunityPostRow: View {
    let post: CommunityPost
    /// Opens "5-1 게시글". `nil` keeps the row static (used by the
    /// standalone preview below).
    var onSelect: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(post.title)
                .font(.communityRowTitle).tracking(Tracking.communityRowTitle)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            Text(post.content)
                .font(.communityRowPreview).tracking(Tracking.communityRowPreview)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            metaLine
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { onSelect?() }
        .padding(.vertical, Spacing.xxs)
    }

    private var metaLine: some View {
        HStack(spacing: Spacing.xs) {
            Text(post.listTimeText)

            if post.commentCount > 0 || post.likeCount > 0 {
                separatorDot

                HStack(spacing: Spacing.xs) {
                    if post.commentCount > 0 {
                        reaction(systemImage: "bubble.right", count: post.commentCount)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(Text(.communityCommentCount(post.commentCount)))
                    }
                    if post.likeCount > 0 {
                        reaction(systemImage: "heart", count: post.likeCount)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(Text(.communityLikeCount(post.likeCount)))
                    }
                }
            }
        }
        .font(.communityRowMeta).tracking(Tracking.communityRowMeta)
        .foregroundStyle(Color.textSecondary)
    }

    private func reaction(systemImage: String, count: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: systemImage)
            Text(count, format: .number)
        }
    }

    private var separatorDot: some View {
        Circle()
            .fill(Color.gray400)
            .frame(width: 4, height: 4)
    }
}

/// `CommunityPost`'s memberwise init is `private` (two of its stored
/// properties are), so these previews build dummy posts by mutating a copy
/// of an existing mock instead of constructing one directly.
private func mockPost(title: String, likeCount: Int, commentCount: Int) -> CommunityPost {
    var post = CommunityPost.mockList[0]
    post.title = title
    post.likeCount = likeCount
    post.commentCount = commentCount
    return post
}

#Preview("좋아요만 있음") {
    List {
        CommunityPostRow(
            post: mockPost(title: "좋아요만 있는 게시글", likeCount: 3, commentCount: 0)
        )
    }
    .listStyle(.plain)
}

#Preview("댓글만 있음") {
    List {
        CommunityPostRow(
            post: mockPost(title: "댓글만 있는 게시글", likeCount: 0, commentCount: 5)
        )
    }
    .listStyle(.plain)
}

#Preview("좋아요 + 댓글 모두 있음") {
    List {
        CommunityPostRow(
            post: mockPost(title: "둘 다 있는 게시글", likeCount: 2, commentCount: 4)
        )
    }
    .listStyle(.plain)
}

#Preview("좋아요 + 댓글 모두 없음") {
    List {
        CommunityPostRow(
            post: mockPost(title: "둘 다 없는 게시글 (반응 영역 없음)", likeCount: 0, commentCount: 0)
        )
    }
    .listStyle(.plain)
}
