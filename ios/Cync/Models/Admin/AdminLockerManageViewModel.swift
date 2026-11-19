//
//  AdminLockerManageViewModel.swift
//  Cync
//
//  Backs "관리자 - 사물함 관리" (`AdminLockerManageView`). ADMIN only on the
//  server side (`docs/API.md` §4).
//
//  One source of truth: `lockers` (`GET /api/lockers`, merged with
//  `GET /api/lockers/pending`). The summary, the 승인 대기 list and the 사용
//  중 list are all computed from it, and every action swaps in the locker
//  the server sends back — so a locker approved on 승인 대기 shows up on
//  사용 중 (and in the counts) right away.
//
//  - 승인 대기: sorted by locker number — the server has no "applied at"
//    time (`assignedAt` is set on approval). 승인 is immediate; 거부 is
//    confirmed by the view first. 여러 개 선택 → 선택 승인 approves one by
//    one (no batch API); failures stay and are reported together.
//  - 사용 중: room order (`lockers.json`) then number; filter by 학번 or
//    number ("12" finds 012) and by room. 비밀번호 보기 is per row and
//    resets on tab change / leaving. 반납 is confirmed by the view first.
//  - 배치도: the shared locker map, fed `mapStatuses` (from `lockers`) so
//    it never fetches on its own. A tapped cell opens the action card for
//    `selectedMapLockerNumber`; 고장 처리 / 복구하기 are immediate.
//  - 학기 말 전체 반납: the button asks the server for a preview
//    (`confirm=false`, changes nothing) and opens `AdminReturnAllDialog`
//    with that count; "승인 대기 신청도 함께 취소" re-asks with
//    `includePending`. Only the dialog's red button executes
//    (`confirm=true`). Afterwards — success or not — the list reloads, so
//    the summary, tabs and map show what the server really did.
//

import Combine
import Foundation

enum AdminLockerTab: CaseIterable, Hashable {
    case pending
    /// Not built yet — shows a "준비 중" placeholder.
    case inUse
    /// Not built yet — shows a "준비 중" placeholder.
    case map

    var titleKey: LocalizedStringResource {
        switch self {
        case .pending: return .adminLockerStatusPending
        case .inUse: return .adminLockerStatusInUse
        case .map: return .adminLockerTabMap
        }
    }
}

struct AdminLockerSummary: Equatable {
    var pending = 0
    var inUse = 0
    var available = 0
    var broken = 0

    init(pending: Int = 0, inUse: Int = 0, available: Int = 0, broken: Int = 0) {
        self.pending = pending
        self.inUse = inUse
        self.available = available
        self.broken = broken
    }

    init(lockers: [Locker]) {
        for locker in lockers {
            switch locker.status {
            case .pending: pending += 1
            case .inUse: inUse += 1
            case .available: available += 1
            case .broken: broken += 1
            }
        }
    }
}

@MainActor
final class AdminLockerManageViewModel: ObservableObject {
    @Published var selectedTab: AdminLockerTab = .pending {
        didSet {
            if selectedTab != oldValue {
                hideAllPasswords()
                selectedMapLockerNumber = nil
            }
        }
    }
    @Published private(set) var lockers: [Locker] = []
    @Published private(set) var hasLoaded = false

    // 승인 대기
    @Published var searchText = ""
    @Published private(set) var isSelecting = false
    @Published private(set) var selectedIDs: Set<Int> = []
    @Published private(set) var isApprovingSelection = false

    // 사용 중
    @Published var inUseSearchText = ""
    /// Room filter — `nil` is 전체 구역.
    @Published var inUseZoneFilter: String?
    @Published private(set) var visiblePasswordIDs: Set<Int> = []
    /// 학기 말 전체 반납: fetching the first preview (the button spins).
    @Published private(set) var isPreparingReturnAll = false
    /// 학기 말 전체 반납's confirm dialog, while it's open.
    @Published private(set) var returnAllDialog: AdminReturnAllDialogState?

    // 배치도
    /// The cell whose action card is open (outlined on the map).
    @Published var selectedMapLockerNumber: Int?

    /// Lockers with a request in flight — their buttons are disabled.
    @Published private(set) var processingIDs: Set<Int> = []
    @Published var toastMessage: String?
    @Published var errorMessage: String?

    private let zoneIdByNumber = LockerDataLoader.zoneIdByLockerNumber()
    private let zoneOrder: [String: Int] = Dictionary(
        uniqueKeysWithValues: LockerDataLoader.zoneIdsInFileOrder().enumerated().map { ($1, $0) }
    )
    /// Previews pass data in and skip the network.
    private let isPreview: Bool

    init() {
        isPreview = false
    }

    /// Preview data — never calls the server.
    init(
        previewLockers: [Locker],
        selectedTab: AdminLockerTab = .pending,
        isSelecting: Bool = false,
        visiblePasswordIDs: Set<Int> = [],
        selectedMapLockerNumber: Int? = nil
    ) {
        isPreview = true
        lockers = previewLockers
        self.selectedTab = selectedTab
        self.isSelecting = isSelecting
        self.visiblePasswordIDs = visiblePasswordIDs
        self.selectedMapLockerNumber = selectedMapLockerNumber
        hasLoaded = true
    }

    var summary: AdminLockerSummary { AdminLockerSummary(lockers: lockers) }

    func load() async {
        guard !isPreview else { return }
        do {
            async let all = CyncAPI.fetchAllLockers()
            async let pending = CyncAPI.fetchPendingLockers()
            let (allLockers, pendingList) = try await (all, pending)
            // The pending endpoint is the authority on who's waiting.
            let pendingByID = Dictionary(pendingList.map { ($0.id, $0) }, uniquingKeysWith: { $1 })
            var merged = allLockers.map { pendingByID[$0.id] ?? $0 }
            let known = Set(merged.map(\.id))
            merged += pendingList.filter { !known.contains($0.id) }
            lockers = merged
            selectedIDs.formIntersection(pendingLockers.map(\.id))
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Leaving the screen hides every password again.
    func hideAllPasswords() {
        visiblePasswordIDs.removeAll()
    }

    // MARK: - Lists

    var pendingLockers: [Locker] {
        lockers.filter { $0.status == .pending }.sorted { $0.lockerNumber < $1.lockerNumber }
    }

    /// Pending requests matching the 학번 search.
    var filteredPending: [Locker] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return pendingLockers }
        return pendingLockers.filter { ($0.currentUserId ?? "").contains(query) }
    }

    var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Room order from `lockers.json`, then locker number.
    var inUseLockers: [Locker] {
        lockers.filter { $0.status == .inUse }.sorted { a, b in
            let za = zoneOrder[zoneId(for: a) ?? ""] ?? .max
            let zb = zoneOrder[zoneId(for: b) ?? ""] ?? .max
            return za != zb ? za < zb : a.lockerNumber < b.lockerNumber
        }
    }

    /// In-use lockers matching the room filter and the 학번/번호 search.
    var filteredInUse: [Locker] {
        let query = inUseSearchText.trimmingCharacters(in: .whitespaces)
        return inUseLockers.filter { locker in
            if let inUseZoneFilter, zoneId(for: locker) != inUseZoneFilter { return false }
            guard !query.isEmpty else { return true }
            return (locker.currentUserId ?? "").contains(query)
                || Self.paddedNumber(locker.lockerNumber).contains(query)
        }
    }

    var isFilteringInUse: Bool {
        inUseZoneFilter != nil || !inUseSearchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - 배치도

    /// What the map paints — straight from `lockers`, so every action
    /// recolors it at once. Numbers missing here show as 정보 없음.
    var mapStatuses: [Int: LockerCellStatus] {
        Dictionary(
            lockers.map { ($0.lockerNumber, LockerCellStatus(serverStatus: $0.status)) },
            uniquingKeysWith: { _, latest in latest }
        )
    }

    func locker(number: Int) -> Locker? {
        lockers.first { $0.lockerNumber == number }
    }

    // MARK: - Labels

    func zoneId(forLockerNumber number: Int) -> String? {
        zoneIdByNumber[number]
    }

    func zoneId(for locker: Locker) -> String? {
        zoneIdByNumber[locker.lockerNumber] ?? locker.location
    }

    /// "B201 · 012번".
    func title(for locker: Locker) -> String {
        String(appLocalized: .adminLockerRowTitle(zoneId(for: locker) ?? "-", Self.paddedNumber(locker.lockerNumber)))
    }

    /// "학번 22011234".
    func subtitle(for locker: Locker) -> String {
        String(appLocalized: .adminLockerStudentId(locker.currentUserId ?? "-"))
    }

    /// "9월 10일" ("Sep 10") from `assignedAt` (approval time); nil
    /// without it. Shared by the 사용 중 row and the map's action card.
    func startDateText(for locker: Locker) -> String? {
        guard let raw = locker.assignedAt, !raw.isEmpty else { return nil }
        let date = raw.contains("T") ? SpringDate.parse(raw) : (SpringDate.parseDay(raw) ?? SpringDate.parse(raw))
        return date.formatted(.dateTime.month(.abbreviated).day().locale(AppLanguage.currentLocale))
    }

    /// "9월 10일부터 사용"; nil without `assignedAt`.
    func sinceText(for locker: Locker) -> String? {
        startDateText(for: locker).map { String(appLocalized: .adminLockerInUseSince($0)) }
    }

    /// "012" — locker numbers are shown 3 digits wide.
    static func paddedNumber(_ number: Int) -> String {
        String(format: "%03d", number)
    }

    // MARK: - 승인 대기 actions

    @discardableResult
    func approve(_ locker: Locker) async -> Bool {
        await perform(on: locker) {
            let updated = try await CyncAPI.approveLocker(id: locker.id)
            self.replace(updated, fallbackStatus: .inUse)
            self.toastMessage = String(appLocalized: .adminLockerApprovedToast(self.title(for: locker)))
        }
    }

    @discardableResult
    func reject(_ locker: Locker) async -> Bool {
        await perform(on: locker) {
            let updated = try await CyncAPI.rejectLocker(id: locker.id)
            self.replace(updated, fallbackStatus: .available)
            self.toastMessage = String(appLocalized: .adminLockerRejectedToast(self.title(for: locker)))
        }
    }

    func toggleSelecting() {
        isSelecting.toggle()
        selectedIDs.removeAll()
    }

    func toggleSelection(_ locker: Locker) {
        if selectedIDs.contains(locker.id) {
            selectedIDs.remove(locker.id)
        } else {
            selectedIDs.insert(locker.id)
        }
    }

    /// One call per locker, in list order (no batch API). Failures stay
    /// selected and in the list.
    func approveSelected() async {
        let targets = pendingLockers.filter { selectedIDs.contains($0.id) }
        guard !targets.isEmpty, !isApprovingSelection else { return }
        isApprovingSelection = true
        defer { isApprovingSelection = false }

        var failed = 0
        for locker in targets {
            processingIDs.insert(locker.id)
            do {
                let updated = try await CyncAPI.approveLocker(id: locker.id)
                replace(updated, fallbackStatus: .inUse)
            } catch {
                failed += 1
            }
            processingIDs.remove(locker.id)
        }

        if failed == 0 {
            toastMessage = String(appLocalized: .adminLockerBatchApprovedToast(targets.count))
            isSelecting = false
            selectedIDs.removeAll()
        } else {
            errorMessage = String(appLocalized: .adminLockerBatchPartialFailure(targets.count, failed))
        }
    }

    // MARK: - 사용 중 actions

    func togglePassword(_ locker: Locker) {
        if visiblePasswordIDs.contains(locker.id) {
            visiblePasswordIDs.remove(locker.id)
        } else {
            visiblePasswordIDs.insert(locker.id)
        }
    }

    @discardableResult
    func returnLocker(_ locker: Locker) async -> Bool {
        await perform(on: locker) {
            let updated = try await CyncAPI.returnLocker(id: locker.id)
            self.replace(updated, fallbackStatus: .available)
            self.visiblePasswordIDs.remove(locker.id)
            self.toastMessage = String(appLocalized: .adminLockerReturnedToast(self.title(for: locker)))
        }
    }

    // MARK: - 배치도 actions (reversible — no confirm)

    @discardableResult
    func markBroken(_ locker: Locker) async -> Bool {
        await perform(on: locker) {
            let updated = try await CyncAPI.setLockerStatus(id: locker.id, status: .broken)
            self.replace(updated, fallbackStatus: .broken)
            self.toastMessage = String(appLocalized: .adminLockerMarkedBrokenToast(Self.paddedNumber(locker.lockerNumber)))
        }
    }

    @discardableResult
    func restore(_ locker: Locker) async -> Bool {
        await perform(on: locker) {
            let updated = try await CyncAPI.setLockerStatus(id: locker.id, status: .available)
            self.replace(updated, fallbackStatus: .available)
            self.toastMessage = String(appLocalized: .adminLockerRestoredToast(Self.paddedNumber(locker.lockerNumber)))
        }
    }

    // MARK: - 학기 말 전체 반납

    /// The button: preview first (nothing changes), then the dialog.
    func startReturnAll() async {
        guard !isPreparingReturnAll, returnAllDialog == nil else { return }
        isPreparingReturnAll = true
        defer { isPreparingReturnAll = false }
        do {
            let preview = try await CyncAPI.previewReturnAll(includePending: false)
            returnAllDialog = AdminReturnAllDialogState(preview: preview)
        } catch {
            errorMessage = String(appLocalized: .adminLockerActionFailed(error.localizedDescription))
        }
    }

    /// "승인 대기 신청도 함께 취소" — re-asks the preview for the new count.
    func setReturnAllIncludesPending(_ includePending: Bool) async {
        guard var dialog = returnAllDialog, !dialog.isExecuting else { return }
        dialog.includePending = includePending
        dialog.isLoadingPreview = true
        returnAllDialog = dialog
        do {
            let preview = try await CyncAPI.previewReturnAll(includePending: includePending)
            // A later toggle wins.
            guard returnAllDialog?.includePending == includePending else { return }
            returnAllDialog?.preview = preview
            returnAllDialog?.isLoadingPreview = false
        } catch {
            returnAllDialog = nil
            errorMessage = String(appLocalized: .adminLockerActionFailed(error.localizedDescription))
        }
    }

    /// 취소 / backdrop — not while it's running.
    func cancelReturnAll() {
        guard returnAllDialog?.isExecuting != true else { return }
        returnAllDialog = nil
    }

    /// The red "n개 반납": can't be undone.
    func executeReturnAll() async {
        guard var dialog = returnAllDialog, !dialog.isBusy, dialog.count > 0 else { return }
        dialog.isExecuting = true
        returnAllDialog = dialog
        do {
            let result = try await CyncAPI.executeReturnAll(includePending: dialog.includePending)
            returnAllDialog = nil
            if result.executed {
                toastMessage = String(appLocalized: .adminLockerReturnAllDone(result.count))
            } else {
                errorMessage = String(appLocalized: .adminLockerReturnAllNotExecuted)
            }
        } catch {
            returnAllDialog = nil
            errorMessage = String(appLocalized: .adminLockerActionFailed(error.localizedDescription))
        }
        // Whatever happened, show the server's actual state.
        hideAllPasswords()
        selectedIDs.removeAll()
        await load()
    }

    // MARK: - Helpers

    /// Returns whether it went through.
    private func perform(on locker: Locker, _ work: () async throws -> Void) async -> Bool {
        guard !processingIDs.contains(locker.id) else { return false }
        processingIDs.insert(locker.id)
        defer { processingIDs.remove(locker.id) }
        do {
            try await work()
            return true
        } catch {
            errorMessage = String(appLocalized: .adminLockerActionFailed(error.localizedDescription))
            return false
        }
    }

    /// Swaps in the server's copy. If its status didn't come back as
    /// expected (shouldn't happen), the expected one is applied so the
    /// lists stay consistent with what the admin just did.
    private func replace(_ updated: Locker, fallbackStatus: LockerStatus) {
        var updated = updated
        if updated.status != fallbackStatus { updated.status = fallbackStatus }
        if fallbackStatus == .available { updated.currentUserId = nil; updated.password = nil }
        if let index = lockers.firstIndex(where: { $0.id == updated.id }) {
            lockers[index] = updated
        } else {
            lockers.append(updated)
        }
        selectedIDs.remove(updated.id)
    }
}

extension AdminLockerManageViewModel {
    private static func previewLocker(_ number: Int, _ status: LockerStatus, _ studentId: String?,
                                      password: String? = nil, assignedAt: String? = nil) -> Locker {
        Locker(id: number, lockerNumber: number, location: nil, status: status, currentUserId: studentId,
               assignedAt: assignedAt, dueDate: nil, password: password)
    }

    /// Three pending requests, five in use across rooms, plus a few others.
    static let previewLockers: [Locker] = [
        previewLocker(6, .pending, "21017777", password: "4821"),
        previewLocker(12, .pending, "22011234"),
        previewLocker(61, .pending, "24010021"),
        previewLocker(260, .pending, "23015678"),
        previewLocker(7, .inUse, "22014567", password: "4821", assignedAt: "2026-09-08T10:00:00"),
        previewLocker(45, .inUse, "21019876", password: "1937", assignedAt: "2026-09-10T09:30:00"),
        previewLocker(150, .inUse, "20017788", password: "5512", assignedAt: "2026-09-10T14:00:00"),
        previewLocker(190, .inUse, "23011122", password: "0820", assignedAt: "2026-09-12T11:00:00"),
        previewLocker(300, .inUse, "24015555", password: "7731", assignedAt: nil),
        previewLocker(1, .available, nil),
        previewLocker(2, .available, nil),
        previewLocker(3, .inUse, "22013333", password: "1111", assignedAt: "2026-09-01T09:00:00"),
        previewLocker(4, .broken, nil),
        previewLocker(5, .available, nil),
        previewLocker(11, .broken, nil),
        previewLocker(75, .broken, nil)
    ]

    /// No pending, no in-use.
    static let previewEmptyLockers: [Locker] = [
        previewLocker(1, .available, nil),
        previewLocker(75, .broken, nil)
    ]
}
