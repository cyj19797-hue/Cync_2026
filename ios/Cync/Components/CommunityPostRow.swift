//
//  CommunityPostRow.swift
//  test
//
//  Figma node `139:1657` ("게시글") — one post row: title + 1-line body
//  preview, an optional like/comment reaction row, and a trailing "더보기"
//  (kebab) button. Figma only fully populated the reaction row on one of its
//  6 mock instances — `CommunityPostRow` shows it whenever a post actually
//  has likes/comments and hides it otherwise, rather than hard-coding which
//  rows have it.
//
//  The kebab used to open its own edit/delete/report `Menu` here, invented
//  before "커뮤니티 - 액션메뉴" specified the real behavior (공유하기/저장하기/
//  신고하기 via a `.confirmationDialog` owned by the parent screen — see
//  Components/CommunityPostActionMenu.swift) — it now just reports the tap
//  up via `onTapMore`.
//

import SwiftUI

struct CommunityPostRow: View {
    let post: CommunityPost
    let onTapMore: () -> Void
    /// Opens "5-1 게시글". `nil` keeps the row static (used by the
    /// standalone preview below).
    var onSelect: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
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
                        reaction(systemImage: "heart", count: post.likeCount)
                        reaction(systemImage: "bubble.right", count: post.commentCount)
                    }
                    .padding(.top, 2)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onSelect?() }

            Spacer(minLength: 0)

            // Figma: "더보기(케밥) 버튼" — opens "커뮤니티 - 액션메뉴".
            Button(action: onTapMore) {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
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

#Preview {
    List {
        ForEach(CommunityPost.mockList) { post in
            CommunityPostRow(post: post, onTapMore: {})
        }
    }
    .listStyle(.plain)
}
