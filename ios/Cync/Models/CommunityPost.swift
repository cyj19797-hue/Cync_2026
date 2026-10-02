//
//  CommunityPost.swift
//  Cync
//
//  Data model backing the "5 커뮤니티" (Community) feed and the
//  "5-1 게시글" (Post Detail) screen — now the real `Post` shape from
//  `GET/POST /api/posts` (`docs/API.md` §2). Comments are fetched
//  separately (`GET /api/posts/{id}/comments`), not embedded here — see
//  `CommunityPostDetailViewModel`.
//

import Foundation

struct CommunityPost: Identifiable, Codable, Hashable {
    let id: Int
    var title: String
    var content: String
    var authorId: String
    var authorName: String
    var authorNickname: String?
    var authorColor: String?
    var anonymous: Bool
    var viewCount: Int
    var likeCount: Int
    var commentCount: Int
    private var createdAtRaw: String
    private var updatedAtRaw: String
    /// Whether the signed-in user has liked this post — fills the heart.
    /// Only right when the request carried the login token (the server
    /// answers `false` for anonymous requests).
    var likedByMe: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, title, content, authorId, authorName, authorNickname, authorColor
        case anonymous, viewCount, likeCount, commentCount, likedByMe
        case createdAtRaw = "createdAt"
        case updatedAtRaw = "updatedAt"
    }

    var createdAt: Date { SpringDate.parse(createdAtRaw) }
    var updatedAt: Date { SpringDate.parse(updatedAtRaw) }

    /// Same rule as `Comment.isShownAsAnonymous`: posted with "익명"
    /// checked, or the author still has the server's generated default
    /// nickname ("익명123456", see `DefaultNickname`), or has no nickname
    /// at all (the only fallback would be the real `authorName`, which must
    /// never be rendered — `docs/API.md` §2).
    var isShownAsAnonymous: Bool {
        guard !anonymous, let nickname = authorNickname else { return true }
        return DefaultNickname.matches(nickname)
    }

    var displayAuthorName: String {
        isShownAsAnonymous ? String(appLocalized: .commonAnonymous) : (authorNickname ?? "")
    }

    /// Feed-row / detail timestamp — see `RelativeTime`.
    var listTimeText: String {
        RelativeTime.text(for: createdAt)
    }

    /// Case-insensitive match against title and body, for the feed's search.
    func matches(_ query: String) -> Bool {
        title.localizedCaseInsensitiveContains(query) || content.localizedCaseInsensitiveContains(query)
    }
}

extension CommunityPost {
    /// Decoded by hand (in an extension, so the memberwise init stays) for
    /// two fields the server may leave out: `commentCount` comes back
    /// `null` on a post with no comments, and `likedByMe` is newer than
    /// some responses. Both fall back instead of failing the whole feed.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        authorId = try container.decode(String.self, forKey: .authorId)
        authorName = try container.decode(String.self, forKey: .authorName)
        authorNickname = try container.decodeIfPresent(String.self, forKey: .authorNickname)
        authorColor = try container.decodeIfPresent(String.self, forKey: .authorColor)
        anonymous = try container.decode(Bool.self, forKey: .anonymous)
        viewCount = try container.decode(Int.self, forKey: .viewCount)
        likeCount = try container.decode(Int.self, forKey: .likeCount)
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        createdAtRaw = try container.decode(String.self, forKey: .createdAtRaw)
        updatedAtRaw = try container.decode(String.self, forKey: .updatedAtRaw)
        likedByMe = try container.decodeIfPresent(Bool.self, forKey: .likedByMe) ?? false
    }
}

extension CommunityPost {
    /// Mock data for previews only — the real feed always comes from
    /// `GET /api/posts` (see `CommunityViewModel.load()`).
    static let mockList: [CommunityPost] = [
        CommunityPost(
            id: 1, title: "이번 학기 팀플 같이 하실 분",
            content: "알고리즘 수업 팀플 인원 구합니다. 관심 있으신 분 댓글 부탁드려요!",
            authorId: "20231001", authorName: "김철수", authorNickname: nil, authorColor: nil,
            anonymous: true, viewCount: 12, likeCount: 0, commentCount: 0,
            createdAtRaw: "2026-08-20T09:12:00", updatedAtRaw: "2026-08-20T09:12:00"
        ),
        CommunityPost(
            id: 2, title: "강의실 자리 맡아주실 분?",
            content: "10분 뒤 도착 예정인데 앞자리 하나만 맡아주실 수 있을까요 ㅠㅠ",
            authorId: "20231002", authorName: "이영희", authorNickname: nil, authorColor: nil,
            anonymous: true, viewCount: 8, likeCount: 0, commentCount: 0,
            createdAtRaw: "2026-08-20T13:45:00", updatedAtRaw: "2026-08-20T13:45:00"
        ),
        CommunityPost(
            id: 3, title: "동아리방 에어컨 고장난 것 같아요",
            content: "확인해보니 리모컨은 되는데 실외기가 안 도는 것 같습니다.",
            authorId: "20231003", authorName: "박민수", authorNickname: nil, authorColor: nil,
            anonymous: true, viewCount: 30, likeCount: 2, commentCount: 2,
            createdAtRaw: "2026-08-21T10:30:00", updatedAtRaw: "2026-08-21T10:30:00"
        ),
        CommunityPost(
            id: 4, title: "졸업작품 전시회 도와주실 분",
            content: "이번 주 토요일 전시 부스 세팅 도와주실 분 구합니다.",
            authorId: "20231004", authorName: "정다은", authorNickname: nil, authorColor: nil,
            anonymous: true, viewCount: 5, likeCount: 0, commentCount: 0,
            createdAtRaw: "2026-08-21T15:02:00", updatedAtRaw: "2026-08-21T15:02:00"
        ),
        CommunityPost(
            id: 5, title: "중고 전공서적 나눔합니다",
            content: "자료구조, 운영체제 교재 나눔해요. 필요하신 분 댓글 남겨주세요.",
            authorId: "20231005", authorName: "최지훈", authorNickname: nil, authorColor: nil,
            anonymous: true, viewCount: 20, likeCount: 0, commentCount: 0,
            createdAtRaw: "2026-08-21T16:40:00", updatedAtRaw: "2026-08-21T16:40:00"
        ),
        CommunityPost(
            id: 6, title: "뿌릿 이햣 듀듀",
            content: "내용을 자유롭게 입력하세요.",
            authorId: "20231006", authorName: "한소영", authorNickname: nil, authorColor: nil,
            anonymous: true, viewCount: 40, likeCount: 2, commentCount: 2,
            createdAtRaw: "2026-08-21T17:04:00", updatedAtRaw: "2026-08-21T17:04:00"
        )
    ]
}
