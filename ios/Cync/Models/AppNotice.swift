//
//  AppNotice.swift
//  Cync
//
//  `AppNotice` from `/api/app-notices` (`docs/API.md` §8) — the Cync team's
//  own announcements (updates, maintenance), shown as `CyncNotice` on
//  설정 > Cync 공지.
//
//  The popup flag comes back as `"popup"`, not the documented `"isPopup"`:
//  the server's Lombok getter for `boolean isPopup` is `isPopup()`, which
//  Jackson names `popup`. Both spellings are read. (Requests still send
//  `isPopup` — that's the `@RequestParam` name.)
//

import Foundation

struct AppNotice: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String
    let content: String
    let isPopup: Bool
    let authorId: String?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, content, popup, isPopup, authorId, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        isPopup = try container.decodeIfPresent(Bool.self, forKey: .popup)
            ?? container.decodeIfPresent(Bool.self, forKey: .isPopup)
            ?? false
        authorId = try container.decodeIfPresent(String.self, forKey: .authorId)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    init(id: Int, title: String, content: String, isPopup: Bool, createdAt: String, updatedAt: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.isPopup = isPopup
        self.authorId = nil
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }
}

extension CyncNotice {
    /// Server fields only — `isPinned` and `imageURLs` don't exist on
    /// `AppNotice` and keep their defaults.
    init(_ notice: AppNotice) {
        self.init(
            id: notice.id,
            title: notice.title,
            date: SpringDate.parse(notice.createdAt),
            content: notice.content,
            isPopup: notice.isPopup
        )
    }
}

extension AppNotice {
    /// `#Preview` data — two popups and four regular notices, newest first.
    static let previewList: [AppNotice] = [
        AppNotice(id: 6, title: "[v1.2] 업데이트 안내",
                  content: "v1.2에서 사물함 배치도와 신고 기능이 추가됐어요.\n\n• 사물함 배치도에서 빈 칸을 바로 확인할 수 있어요.\n• 게시글·댓글을 신고할 수 있어요.",
                  isPopup: true, createdAt: "2026-11-17T10:00:00"),
        AppNotice(id: 5, title: "11/20(목) 서버 점검 안내",
                  content: "더 안정적인 서비스를 위해 서버 점검을 진행해요.\n\n• 일시: 11월 20일(목) 02:00 ~ 04:00\n• 영향: 점검 중에는 앱 로그인과 사물함 신청이 잠시 멈춰요.\n\n이용에 불편을 드려 죄송해요.",
                  isPopup: true, createdAt: "2026-11-16T18:00:00"),
        AppNotice(id: 4, title: "사물함 신청 방식이 바뀌었어요",
                  content: "이제 신청 후 학생회 승인을 거쳐 사용할 수 있어요.",
                  isPopup: false, createdAt: "2026-11-10T09:00:00"),
        AppNotice(id: 3, title: "[v1.1] 업데이트 안내",
                  content: "커뮤니티 대댓글과 프로필 색상이 추가됐어요.",
                  isPopup: false, createdAt: "2026-10-20T09:00:00"),
        AppNotice(id: 2, title: "개인정보 처리방침 개정 안내",
                  content: "개인정보 처리방침이 일부 개정됐어요. 설정 > 약관에서 확인할 수 있어요.",
                  isPopup: false, createdAt: "2026-09-30T09:00:00"),
        AppNotice(id: 1, title: "[v1.0] Cync 출시 안내",
                  content: "학과 생활을 하나로 연결하는 Cync가 출시됐어요.",
                  isPopup: false, createdAt: "2026-09-01T09:00:00")
    ]
}
