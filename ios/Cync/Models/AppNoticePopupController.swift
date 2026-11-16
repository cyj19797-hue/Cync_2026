//
//  AppNoticePopupController.swift
//  Cync
//
//  Drives the app-launch popup notices (`docs/API.md` §8,
//  `GET /api/app-notices/popup`), shown by `AppNoticePopupOverlay`.
//
//  - Loads once per app run, the first time the main tabs are on screen
//    after the splash while logged in (`RootView` calls `loadIfNeeded()`).
//    A failure is swallowed — a popup must never block using the app.
//  - Keeps only `isPopup` rows, newest `createdAt` first (the server's
//    order isn't), minus the ones this device dismissed with "다시 보지
//    않기" (`AppNoticePopupDismissStore`).
//  - 확인 / 닫기 close the current card (it shows again next launch);
//    "다시 보지 않기" also records it. 자세히 보기 closes it like 확인 and
//    opens the full notice (`detailNotice`, shown by `RootView`); the next
//    card waits until that screen is closed. The overlay goes away after
//    the last card.
//

import Foundation

@MainActor
final class AppNoticePopupController: ObservableObject {
    /// Notices still to show; the first one is on screen.
    @Published private(set) var queue: [AppNotice]
    /// How many there were when loaded — for the "1 / 2" pill.
    @Published private(set) var total: Int
    /// Notice opened with 자세히 보기 — `RootView` shows its detail screen.
    @Published private(set) var detailNotice: AppNotice?

    private var hasLoaded = false
    private let dismissStore: AppNoticePopupDismissStore

    init(dismissStore: AppNoticePopupDismissStore = AppNoticePopupDismissStore()) {
        self.dismissStore = dismissStore
        queue = []
        total = 0
    }

    /// Previews: shows `notices` as-is, never calls the server.
    init(previewNotices notices: [AppNotice]) {
        dismissStore = AppNoticePopupDismissStore()
        queue = notices
        total = notices.count
        hasLoaded = true
    }

    /// The card on screen — none while a detail screen is open.
    var current: AppNotice? { detailNotice == nil ? queue.first : nil }

    /// 1-based position of `current` among the notices loaded this launch.
    var currentPosition: Int { total - queue.count + 1 }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        guard let notices = try? await CyncAPI.fetchPopupNotices() else { return }

        let popups = notices.filter(\.isPopup)
        dismissStore.prune(keeping: popups)
        let toShow = popups
            .filter { !dismissStore.isDismissed($0) }
            .sorted { SpringDate.parse($0.createdAt) > SpringDate.parse($1.createdAt) }
        total = toShow.count
        queue = toShow
        #if DEBUG
        if MockServer.opensPopupDetail { openDetail() }
        #endif
    }

    /// 확인 — close for now; it pops up again next launch.
    func confirm() {
        guard !queue.isEmpty else { return }
        queue.removeFirst()
    }

    /// 자세히 보기 — close like 확인 and open the full notice.
    func openDetail() {
        guard let notice = queue.first else { return }
        queue.removeFirst()
        detailNotice = notice
    }

    /// The detail screen opened by 자세히 보기 was closed; the next card,
    /// if any, comes up.
    func closeDetail() {
        detailNotice = nil
    }

    /// 다시 보지 않기 — close and never show this version on this device.
    func dismissForever() {
        guard let notice = queue.first else { return }
        dismissStore.dismiss(notice)
        queue.removeFirst()
    }
}
