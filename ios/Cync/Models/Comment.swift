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
    /// Local-only, same as `likeCount` — whether this user tapped the heart.
    var isLikedByMe: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, postId, parentCommentId, content, authorId, authorName, authorNickname, authorColor
        case anonymous, deleted
        case createdAtRaw = "createdAt"
    }

    var createdAt: Date { SpringDate.parse(createdAtRaw) }

    /// Shown as anonymous: either posted with "익명" checked, or the author
    /// never picked a nickname — the server's generated default
    /// ("익명123456") reads like an anonymous label with a random number,
    /// and with no nickname at all the only fallback would be the real
    /// `authorName`, which must never be shown.
    var isShownAsAnonymous: Bool {
        guard !anonymous, let nickname = authorNickname else { return true }
        return DefaultNickname.matches(nickname)
    }

    /// `isShownAsAnonymous` hides identity entirely, so such a comment
    /// always shows "익명", never the nickname. The detail screen shows
    /// `CommentAuthorLabel` instead ("익명1", "글쓴이"); this plain form is
    /// for contexts without the whole thread.
    var displayAuthorName: String {
        isShownAsAnonymous ? String(appLocalized: .commonAnonymous) : (authorNickname ?? "")
    }
}

/// The nickname the server assigns at first login before the user picks
/// one: "익명" + a 6-digit number (`AuthController` on the backend).
enum DefaultNickname {
    static func matches(_ nickname: String) -> Bool {
        nickname.wholeMatch(of: /익명\d{6}/) != nil
    }
}

/// How a comment's author is shown on "5-1 게시글". Anonymous commenters are
/// numbered "익명1, 익명2…" in order of their first comment on the post, so
/// readers can tell one person's repeated comments apart without learning
/// who they are; the post's own author reads "글쓴이" instead of a number.
/// Built by `CommentAuthorLabel.labels(for:postAuthorId:)`.
enum CommentAuthorLabel: Equatable {
    case postAuthor
    case anonymous(number: Int)
    case named(String)

    var text: String {
        switch self {
        case .postAuthor: return String(appLocalized: .commentPostAuthor)
        case .anonymous(let number): return String(appLocalized: .commentAnonymousNumber(number))
        case .named(let name): return name
        }
    }

    /// Labels for every comment, keyed by comment id. Numbers are assigned
    /// by each author's earliest comment (deleted ones included, so a
    /// deletion never renumbers anyone else). Grouping uses `authorId`,
    /// which the server returns for every comment — never displayed.
    static func labels(for comments: [Comment], postAuthorId: String) -> [Int: CommentAuthorLabel] {
        var numberByAuthor: [String: Int] = [:]
        var labels: [Int: CommentAuthorLabel] = [:]

        let chronological = comments.sorted {
            ($0.createdAt, $0.id) < ($1.createdAt, $1.id)
        }
        for comment in chronological {
            if comment.authorId == postAuthorId {
                labels[comment.id] = .postAuthor
            } else if comment.isShownAsAnonymous {
                let number = numberByAuthor[comment.authorId] ?? (numberByAuthor.count + 1)
                numberByAuthor[comment.authorId] = number
                labels[comment.id] = .anonymous(number: number)
            } else {
                labels[comment.id] = .named(comment.displayAuthorName)
            }
        }
        return labels
    }
}

/// What the ⋮ menu on a comment can offer — which ones appear depends on
/// who's looking (`CommunityPostDetailViewModel.actions(for:)`).
enum CommentAction: Hashable {
    case edit, delete, report
}

/// Items in a post's own ⋮ menu on "5-1 게시글".
enum PostAction: Hashable {
    case delete, report
}

/// What a `POST /api/reports` was filed against (`targetType`).
enum ReportTargetKind: Hashable {
    case post, comment
}

/// `POST /api/reports`' `reason` values (`Report.Reason` on the server).
enum ReportReason: String, CaseIterable, Identifiable {
    case spam = "SPAM"
    case abuse = "ABUSE"
    case privacy = "PRIVACY"
    case falseInfo = "FALSE_INFO"
    case other = "OTHER"

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .spam: return .reportReasonSpam
        case .abuse: return .reportReasonAbuse
        case .privacy: return .reportReasonPrivacy
        case .falseInfo: return .reportReasonFalseInfo
        case .other: return .reportReasonOther
        }
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
