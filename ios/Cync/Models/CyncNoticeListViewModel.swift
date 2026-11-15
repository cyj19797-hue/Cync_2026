//
//  CyncNoticeListViewModel.swift
//  Cync
//
//  Backs "6-2 Cync 공지": load state (loading skeleton / list / empty /
//  error) from `GET /api/app-notices`, kept in the server's order (newest
//  first). Admins can also write, edit, delete and turn a notice's
//  launch popup on/off (`docs/API.md` §8) — every change is applied to
//  `notices` so the list and an open detail stay in step.
//
//  Showing the popup at app launch (`GET /api/app-notices/popup`) isn't
//  built here.
//

import Foundation

@MainActor
final class CyncNoticeListViewModel: ObservableObject {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed
    }

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var notices: [CyncNotice] = []
    @Published var toastMessage: String?
    @Published var errorMessage: String?

    private let isPreview: Bool
    private let previewIsAdmin: Bool

    init() {
        isPreview = false
        previewIsAdmin = false
    }

    /// Preview data — never calls the server.
    init(previewNotices: [CyncNotice], isAdmin: Bool) {
        isPreview = true
        previewIsAdmin = isAdmin
        notices = previewNotices
        phase = .loaded
    }

    /// 작성 button and the detail's 관리 menu — `role == "ADMIN"`.
    var isAdmin: Bool {
        isPreview ? previewIsAdmin : (CurrentUserSession.shared.profile?.isAdmin ?? false)
    }

    func load() async {
        guard !isPreview else { return }
        // Pull-to-refresh keeps the current list on screen instead of
        // swapping back to the skeleton.
        if notices.isEmpty {
            phase = .loading
        }
        if CurrentUserSession.shared.profile == nil {
            // Only to know whether to show the admin controls.
            _ = try? await CurrentUserSession.shared.refresh()
        }
        do {
            notices = try await CyncAPI.fetchAppNotices().map(CyncNotice.init)
            phase = .loaded
        } catch is CancellationError {
            // Pull-to-refresh released early — not an error.
        } catch {
            if notices.isEmpty { phase = .failed }
        }
    }

    func notice(id: Int) -> CyncNotice? {
        notices.first { $0.id == id }
    }

    // MARK: - Admin

    /// After 작성 — newest, so it goes on top.
    func insert(_ notice: CyncNotice) {
        notices.insert(notice, at: 0)
        toastMessage = String(appLocalized: .appNoticeCreatedToast)
    }

    /// After 수정 (or a popup switch).
    func replace(_ notice: CyncNotice) {
        if let index = notices.firstIndex(where: { $0.id == notice.id }) {
            notices[index] = notice
        }
    }

    /// 팝업 끄기 / 팝업 켜기 — no popup-only API, so the title and content
    /// go back unchanged with the flipped flag. Returns the updated notice.
    func togglePopup(_ notice: CyncNotice) async -> CyncNotice? {
        do {
            let updated = CyncNotice(try await CyncAPI.updateAppNotice(
                id: notice.id,
                title: notice.title,
                content: notice.content,
                isPopup: !notice.isPopup
            ))
            replace(updated)
            toastMessage = String(appLocalized: updated.isPopup ? .appNoticePopupOnToast : .appNoticePopupOffToast)
            return updated
        } catch {
            errorMessage = String(appLocalized: .appNoticeUpdateFailed(error.localizedDescription))
            return nil
        }
    }

    /// 삭제하기 (after the detail's confirm). Throws so the detail can show
    /// the error itself and stay open.
    func delete(_ notice: CyncNotice) async throws {
        try await CyncAPI.deleteAppNotice(id: notice.id)
        notices.removeAll { $0.id == notice.id }
        toastMessage = String(appLocalized: .appNoticeDeletedToast)
    }
}
