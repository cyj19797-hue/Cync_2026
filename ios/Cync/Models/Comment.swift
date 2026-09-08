//
//  Comment.swift
//  Cync
//
//  Data model backing the "댓글" (comments) section of "5-1 게시글" — now the
//  real `Comment` shape from `GET/POST /api/posts/{id}/comments`
//  (`docs/API.md` §2): flat array + `parentCommentId` (server only allows
//  one level of nesting), with a soft-delete `deleted` flag instead of the
//  row disappearing.
//

import Foundation

struct Comment: Identifiable, Codable, Hashable {
    let id: Int
    var postId: Int
    /// `nil` for a top-level comment; the parent comment's `id` for a reply.
    var parentCommentId: Int?
    var content: String
    var authorId: String
    var authorName: String
    var authorNickname: String?
    var authorColor: String?
    var anonymous: Bool
    /// Soft-deleted — render as "삭제된 댓글입니다" and hide its actions
    /// rather than dropping the row (see `CommentRow`).
    var deleted: Bool
    private var createdAtRaw: String
    /// Local-only — the API has no like/unlike endpoint for comments (see
    /// the gap table), so this never round-trips to the server and resets
    /// whenever comments are reloaded.
    var likeCount: Int = 0

    enum CodingKeys: String, CodingKey {
        case id, postId, parentCommentId, content, authorId, authorName, authorNickname, authorColor
        case anonymous, deleted
        case createdAtRaw = "createdAt"
    }

    var createdAt: Date { SpringDate.parse(createdAtRaw) }

    /// `anonymous` hides identity entirely — even a set `authorNickname` —
    /// so an anonymous comment always shows "익명", never the nickname.
    var displayAuthorName: String {
        anonymous ? "익명" : (authorNickname ?? authorName)
    }
}

extension Comment {
    /// Mock data for previews only — the real thread always comes from
    /// `GET /api/posts/{id}/comments` (see
    /// `CommunityPostDetailViewModel.loadComments()`).
    static let mockList: [Comment] = {
        func raw(_ minute: Int) -> String {
            "2026-08-21T17:\(String(format: "%02d", minute)):00"
        }

        return [
            Comment(id: 1, postId: 6, parentCommentId: nil, content: "이 강의 완전 꿀강의에요!!", authorId: "20231010", authorName: "김민준", authorNickname: nil, authorColor: nil, anonymous: true, deleted: false, createdAtRaw: raw(4)),
            Comment(id: 2, postId: 6, parentCommentId: nil, content: "사물함 신청 언제까지 가능한가요?", authorId: "20231011", authorName: "이서준", authorNickname: nil, authorColor: nil, anonymous: true, deleted: false, createdAtRaw: raw(9)),
            Comment(id: 3, postId: 6, parentCommentId: nil, content: "다음 학기에도 계속 운영되나요?", authorId: "20231012", authorName: "박도윤", authorNickname: nil, authorColor: nil, anonymous: true, deleted: false, createdAtRaw: raw(15)),
            Comment(id: 4, postId: 6, parentCommentId: 1, content: "저도 들었는데 진짜 좋아요 ㅎㅎ", authorId: "20231013", authorName: "최지우", authorNickname: nil, authorColor: nil, anonymous: true, deleted: false, createdAtRaw: raw(6)),
            Comment(id: 5, postId: 6, parentCommentId: 3, content: "네! 매 학기 계속 운영될 예정이에요.", authorId: "20231014", authorName: "정하은", authorNickname: nil, authorColor: nil, anonymous: true, deleted: false, createdAtRaw: raw(18))
        ]
    }()
}
