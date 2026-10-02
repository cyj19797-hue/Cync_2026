//
//  NotificationPreferences.swift
//  test
//
//  What the "6-1 알림 설정" screen and its two sub-screens store: the
//  "전체 알림" master switch, each alert, which notice categories "새 공지
//  알림" covers, and which locker results "사물함 신청 결과 알림" covers.
//
//  There's no server endpoint for these yet (none in `docs/API.md`), so
//  `LocalNotificationPreferencesStore` keeps them on the device. A server
//  version only needs another `NotificationPreferencesStore`.
//

import Foundation

struct NotificationPreferences: Codable, Equatable {
    /// "전체 알림" — off silences everything below it.
    var allEnabled = true
    /// "마감 임박 알림".
    var deadlineDDay = true
    /// "새 공지 알림" — the categories it covers (see `noticeCategoryOptions`).
    var noticeCategories: Set<NoticeCategory> = Set(Self.noticeCategoryOptions)
    /// "사물함 신청 결과 알림" — 신청 승인.
    var lockerApproved = true
    /// "사물함 신청 결과 알림" — 신청 거절.
    var lockerRejected = true
    /// "Cync 공지 알림" — app operator notices (점검, 업데이트).
    var cyncNotices = true
    /// "사물함 반납 안내" — the admin's end-of-term return.
    var lockerReturn = true
    /// "댓글 알림" — comments on my posts.
    var comments = true
    /// "답글 알림" — replies to my comments.
    var replies = true
    /// "좋아요 알림" — off by default: it can fire often.
    var likes = false
    /// "신고 처리 결과" — what happened to a post/comment I reported.
    var reportResults = true
    /// "이용 제한 안내" — community restriction placed or lifted.
    var communityRestriction = true

    /// Every real notice category (not the "전체" filter).
    static let noticeCategoryOptions: [NoticeCategory] = NoticeCategory.allCases.filter { $0 != .all }

    init() {}

    /// Missing keys (e.g. saved before a newer alert existed) take their
    /// defaults instead of failing the whole load.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = NotificationPreferences()
        allEnabled = try c.decodeIfPresent(Bool.self, forKey: .allEnabled) ?? d.allEnabled
        deadlineDDay = try c.decodeIfPresent(Bool.self, forKey: .deadlineDDay) ?? d.deadlineDDay
        noticeCategories = try c.decodeIfPresent(Set<NoticeCategory>.self, forKey: .noticeCategories) ?? d.noticeCategories
        lockerApproved = try c.decodeIfPresent(Bool.self, forKey: .lockerApproved) ?? d.lockerApproved
        lockerRejected = try c.decodeIfPresent(Bool.self, forKey: .lockerRejected) ?? d.lockerRejected
        cyncNotices = try c.decodeIfPresent(Bool.self, forKey: .cyncNotices) ?? d.cyncNotices
        lockerReturn = try c.decodeIfPresent(Bool.self, forKey: .lockerReturn) ?? d.lockerReturn
        comments = try c.decodeIfPresent(Bool.self, forKey: .comments) ?? d.comments
        replies = try c.decodeIfPresent(Bool.self, forKey: .replies) ?? d.replies
        likes = try c.decodeIfPresent(Bool.self, forKey: .likes) ?? d.likes
        reportResults = try c.decodeIfPresent(Bool.self, forKey: .reportResults) ?? d.reportResults
        communityRestriction = try c.decodeIfPresent(Bool.self, forKey: .communityRestriction) ?? d.communityRestriction
    }
}

protocol NotificationPreferencesStore {
    func load() -> NotificationPreferences
    /// Throws when the change couldn't be saved; the screen then puts the
    /// switch back.
    func save(_ preferences: NotificationPreferences) async throws
}

/// Saves to `UserDefaults` as JSON.
struct LocalNotificationPreferencesStore: NotificationPreferencesStore {
    private static let key = "notificationPreferences"

    func load() -> NotificationPreferences {
        guard let data = UserDefaults.standard.data(forKey: Self.key),
              let preferences = try? JSONDecoder().decode(NotificationPreferences.self, from: data)
        else { return NotificationPreferences() }
        return preferences
    }

    func save(_ preferences: NotificationPreferences) async throws {
        let data = try JSONEncoder().encode(preferences)
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}
