//
//  CommunityPostRow.swift
//  test
//
//  Figma node `139:1657` ("게시글") — one post row: title + 1-line body
//  preview, and independent like/comment reaction badges. Each badge is
//  shown only when its own count is at least 1 — a post with comments but
//  no likes (or vice versa) shows just that one badge, not a "0" alongside
//  it, and a post with neither shows no reaction row at all.
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
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(post.title)
                .font(.communityPostTitle)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            Text(post.content)
                .font(.communityPostBody)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            if post.likeCount > 0 || post.commentCount > 0 {
                HStack(spacing: Spacing.xs) {
                    if post.likeCount > 0 {
                        reaction(systemImage: "heart", count: post.likeCount)
                    }
                    if post.commentCount > 0 {
                        reaction(systemImage: "bubble.right", count: post.commentCount)
                    }
                }
                .padding(.top, 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect?() }
        .padding(.vertical, Spacing.xs)
    }

    private func reaction(systemImage: String, count: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: systemImage)
            Text("\(count)")
        }
        .font(.communityReactionCount)
        .foregroundStyle(Color.gray700)
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
