//
//  PostComment.swift
//  test
//
//  Data model backing the "댓글" (comments) section of "5-1 게시글".
//  Figma only shows one level of nesting (a reply sits directly under its
//  parent comment, indented), so `replies` isn't rendered recursively —
//  see CommunityCommentRow — but the model itself doesn't artificially cap
//  the depth, since a future reply-to-reply feature would just add another
//  level here.
//

import Foundation

struct PostComment: Identifiable, Codable {
    let id: UUID
    var authorName: String
    var createdAt: Date
    var content: String
    var likeCount: Int
    var replies: [PostComment]
}

extension PostComment {
    /// Mock data matching "5-1 게시글"'s 4 top-level comments (2 of which
    /// have a reply).
    static let mockList: [PostComment] = {
        func date(_ minute: Int) -> Date {
            Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 21, hour: 17, minute: minute)) ?? Date()
        }

        return [
            PostComment(
                id: UUID(),
                authorName: "익명",
                createdAt: date(4),
                content: "이 강의 완전 꿀강의에요!!",
                likeCount: 0,
                replies: [
                    PostComment(
                        id: UUID(),
                        authorName: "익명",
                        createdAt: date(6),
                        content: "저도 들었는데 진짜 좋아요 ㅎㅎ",
                        likeCount: 0,
                        replies: []
                    )
                ]
            ),
            PostComment(
                id: UUID(),
                authorName: "익명",
                createdAt: date(9),
                content: "사물함 신청 언제까지 가능한가요?",
                likeCount: 0,
                replies: []
            ),
            PostComment(
                id: UUID(),
                authorName: "익명",
                createdAt: date(15),
                content: "다음 학기에도 계속 운영되나요?",
                likeCount: 0,
                replies: [
                    PostComment(
                        id: UUID(),
                        authorName: "익명",
                        createdAt: date(18),
                        content: "네! 매 학기 계속 운영될 예정이에요.",
                        likeCount: 0,
                        replies: []
                    )
                ]
            )
        ]
    }()
}
