//
//  CyncNoticeReadStore.swift
//  Cync
//
//  Which "Cync 공지" entries the user has opened, for the list's unread
//  dot / title weight. Local-only (`UserDefaults`, keyed by
//  `CyncNotice.id`) — the board has no backend yet, let alone a per-user
//  read flag. Device-wide rather than per-account like
//  `NicknameSetupStore`: these are app-team announcements, the same for
//  every account, so "already read on this phone" is what the dot means.
//

import Foundation

@MainActor
final class CyncNoticeReadStore: ObservableObject {
    static let shared = CyncNoticeReadStore()

    @Published private(set) var readIDs: Set<Int>

    private static let storageKey = "readCyncNoticeIDs"

    private init() {
        let saved = UserDefaults.standard.array(forKey: Self.storageKey) as? [Int] ?? []
        readIDs = Set(saved)
    }

    func isRead(_ noticeId: Int) -> Bool {
        readIDs.contains(noticeId)
    }

    func markRead(_ noticeId: Int) {
        guard !readIDs.contains(noticeId) else { return }
        readIDs.insert(noticeId)
        UserDefaults.standard.set(Array(readIDs), forKey: Self.storageKey)
    }
}
