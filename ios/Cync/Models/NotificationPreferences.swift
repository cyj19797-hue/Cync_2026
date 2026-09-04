//
//  NotificationPreferences.swift
//  test
//
//  Data model backing the "6-1 알림 설정" (Notification Settings) screen's
//  two toggle rows. The other two rows ("새 공지사항 등록", "사물함 결과") are
//  chevron navigation rows, not stored booleans, so they aren't modeled
//  here.
//

import Foundation

struct NotificationPreferences: Codable {
    /// "마감 D-day" — deadline reminder push notifications.
    var deadlineDDayAlerts: Bool
    /// "댓글" — new-comment push notifications.
    var commentAlerts: Bool
}

extension NotificationPreferences {
    static let mock = NotificationPreferences(deadlineDDayAlerts: true, commentAlerts: true)
}
