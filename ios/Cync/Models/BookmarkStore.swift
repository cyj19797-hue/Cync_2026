//
//  BookmarkStore.swift
//  Cync
//
//  Local-only shared bookmark list — the API has no per-user bookmark
//  endpoint yet (see `Notice`/`CalendarEvent`'s header comments), so
//  bookmarking a notice on "공지사항" persists it here (`UserDefaults`,
//  one list per signed-in 학번) instead. "캘린더" reads this list too and shows
//  each bookmarked notice on the dates extracted from its text — see
//  `CalendarEvent.events(fromBookmarkedNotice:)`.
//

import Foundation

@MainActor
final class BookmarkStore: ObservableObject {
    static let shared = BookmarkStore()

    @Published private(set) var bookmarkedNotices: [Notice] = []

    /// Signed-in student id (JWT `sub`) — each account has its own list
    /// under `bookmarkedNotices.<학번>`, so logging out and into another
    /// account on the same phone never shows the previous one's bookmarks.
    /// `nil` while logged out: nothing is shown or saved.
    private var accountId: String?

    private static let storageKeyPrefix = "bookmarkedNotices."
    /// Pre-per-account key, shared by everyone who used this phone — it
    /// can't be attributed to an account, so it's deleted.
    private static let legacyStorageKey = "bookmarkedNotices"

    private init() {
        UserDefaults.standard.removeObject(forKey: Self.legacyStorageKey)
        switchAccount(to: CyncAPI.accessToken.flatMap(JWT.subject))
    }

    /// Loads `accountId`'s saved bookmarks (none for `nil`). Called by
    /// `SessionStore` on login/logout.
    func switchAccount(to accountId: String?) {
        self.accountId = accountId
        if let accountId,
           let data = UserDefaults.standard.data(forKey: Self.storageKeyPrefix + accountId),
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

    /// Reconciles the saved copies with the server's current notice list
    /// (`serverNotices` = council + school, as `NoticeListViewModel` builds
    /// it). Each bookmark stores a full `Notice` snapshot, so without this a
    /// notice deleted on the server — or test data saved by an older build —
    /// kept showing on "캘린더". Bookmarks whose notice is gone are dropped;
    /// the rest are refreshed with the server's latest title/body.
    func sync(with serverNotices: [Notice]) {
        let current = Dictionary(serverNotices.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let synced: [Notice] = bookmarkedNotices.compactMap { saved in
            guard var fresh = current[saved.id] else { return nil }
            fresh.isBookmarked = true
            return fresh
        }
        guard synced.map(\.id) != bookmarkedNotices.map(\.id)
            || zip(synced, bookmarkedNotices).contains(where: { $0.title != $1.title || $0.originalText != $1.originalText || $0.date != $1.date })
        else { return }
        bookmarkedNotices = synced
        persist()
    }

    /// Fetches both notice boards and runs `sync(with:)` — for screens that
    /// show bookmarks without loading the notice list themselves (캘린더).
    /// A failed fetch leaves the bookmarks untouched.
    func refreshFromServer() async {
        do {
            async let council = CyncAPI.fetchCouncilNotices()
            async let school = CyncAPI.fetchSchoolNotices()
            let notices = try await council.map(Notice.init(councilNotice:))
                + school.map(Notice.init(schoolNotice:))
            sync(with: notices)
        } catch {
            // Keep what's saved — better a stale bookmark than losing them all offline.
        }
    }

    private func persist() {
        guard let accountId,
              let data = try? JSONEncoder().encode(bookmarkedNotices) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKeyPrefix + accountId)
    }
}
