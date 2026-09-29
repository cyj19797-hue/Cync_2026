//
//  BookmarkStore.swift
//  Cync
//
//  Local-only shared bookmark list — the API has no per-user bookmark
//  endpoint yet (see `Notice`/`CalendarEvent`'s header comments), so
//  bookmarking a notice on "공지사항" persists it here (`UserDefaults`,
//  keyed by `Notice.id`) instead. "캘린더" reads this list too and shows
//  each bookmarked notice as a same-day event on its `date` — see
//  `CalendarEvent.init(bookmarkedNotice:)`.
//

import Foundation

@MainActor
final class BookmarkStore: ObservableObject {
    static let shared = BookmarkStore()

    @Published private(set) var bookmarkedNotices: [Notice]

    private static let storageKey = "bookmarkedNotices"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode([Notice].self, from: data) {
            bookmarkedNotices = saved
        } else {
            bookmarkedNotices = []
        }
    }

    func isBookmarked(_ noticeId: Int) -> Bool {
        bookmarkedNotices.contains { $0.id == noticeId }
    }

    /// Adds `notice` if it isn't already saved, or removes it if it is.
    /// Returns the notice's bookmarked state after the toggle.
    @discardableResult
    func toggle(_ notice: Notice) -> Bool {
        if isBookmarked(notice.id) {
            remove(noticeId: notice.id)
            return false
        } else {
            var bookmarked = notice
            bookmarked.isBookmarked = true
            bookmarkedNotices.append(bookmarked)
            persist()
            return true
        }
    }

    func remove(noticeId: Int) {
        bookmarkedNotices.removeAll { $0.id == noticeId }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(bookmarkedNotices) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
