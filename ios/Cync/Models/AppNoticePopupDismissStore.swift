//
//  AppNoticePopupDismissStore.swift
//  Cync
//
//  Remembers which app-launch popup notices this device chose "다시 보지
//  않기" for. Stored in `UserDefaults` as `id → updatedAt` (the version the
//  user dismissed), not just the id: when an admin edits the notice its
//  `updatedAt` changes, the stored value no longer matches, and it pops up
//  again — an edit usually means there's something new to read.
//
//  Per device, not per account: it's a "don't show me this again" choice
//  about the phone, and the notices are the same for everyone.
//

import Foundation

struct AppNoticePopupDismissStore {
    private let defaults: UserDefaults
    private static let storageKey = "appNoticePopup.dismissed"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private var records: [String: String] {
        get { defaults.dictionary(forKey: Self.storageKey) as? [String: String] ?? [:] }
        nonmutating set { defaults.set(newValue, forKey: Self.storageKey) }
    }

    /// The version a dismissal is keyed on — `updatedAt`, or `createdAt`
    /// for a server row without one.
    private static func version(of notice: AppNotice) -> String {
        notice.updatedAt ?? notice.createdAt
    }

    func isDismissed(_ notice: AppNotice) -> Bool {
        records[String(notice.id)] == Self.version(of: notice)
    }

    func dismiss(_ notice: AppNotice) {
        records[String(notice.id)] = Self.version(of: notice)
    }

    /// Drops records for notices no longer in the server's popup list
    /// (deleted, or popup turned off) so the stored dictionary doesn't grow
    /// forever. A notice whose popup is turned back on later shows again.
    func prune(keeping notices: [AppNotice]) {
        let live = Set(notices.map { String($0.id) })
        let current = records
        let kept = current.filter { live.contains($0.key) }
        if kept.count != current.count { records = kept }
    }
}
