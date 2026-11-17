//
//  AdminReportManageViewModel.swift
//  Cync
//
//  Backs "관리자 - 신고 관리" (`AdminReportManageView`). ADMIN only on the
//  server side (`docs/API.md` §9, §5).
//
//  One source of truth: `reports` (`GET /api/reports` — pending and
//  resolved together). Both tabs are computed from it as `ReportGroup`s
//  (one card per target + status), so resolving a group moves it from 미처리
//  to 처리 완료 everywhere at once.
//
//  - 미처리: most reports first, then newest. 전체: newest first.
//  - Previews: each distinct target is fetched once (in parallel) —
//    `fetchPostDetail` for posts, `fetchComment` for comments. The server
//    answers a missing post with 500, not 404 (`PostController` throws a
//    bare RuntimeException), so both read as "already deleted".
//    `fetchComment` isn't on the server yet; any failure there shows
//    "댓글 내용을 불러올 수 없어요" and disables 작성자 정지 (no 학번).
//  - Actions resolve EVERY report in the group, and only after the action
//    itself went through. 작성자 정지 runs ban → (delete) → resolve and
//    stops at the first failure, saying which steps already happened.
//  - What was done is remembered on this device (`AdminActionHistoryStore`)
//    — the server keeps no record of it.
//

import Combine
import Foundation

enum AdminReportTab: CaseIterable, Hashable {
    case pending
    case all

    var titleKey: LocalizedStringResource {
        switch self {
        case .pending: return .adminReportTabPending
        case .all: return .adminReportTabAll
        }
    }
}

/// What the card's preview box shows for a target.
enum ReportTargetPreview: Equatable {
    case loading
    case post(CommunityPost)
    case comment(Comment)
    /// The comment couldn't be fetched (no single-comment API yet).
    case commentUnavailable
    /// The post couldn't be fetched for some other reason (offline…).
    case failed
    /// Already deleted — only 문제없음 is left to do.
    case deleted

    /// The author's 학번, when it's known.
    var authorId: String? {
        switch self {
        case .post(let post): return post.authorId
        case .comment(let comment): return comment.authorId
        default: return nil
        }
    }

    /// The author as the list shows them ("익명" when anonymous).
    var authorDisplayName: String? {
        switch self {
        case .post(let post): return post.displayAuthorName
        case .comment(let comment): return comment.displayAuthorName
        default: return nil
        }
    }

    /// The author's profile color — hidden for anonymous authors.
    var authorColor: ProfileColor? {
        switch self {
        case .post(let post): return post.isShownAsAnonymous ? nil : post.authorColor.flatMap(ProfileColor.init(rawValue:))
        case .comment(let comment): return comment.isShownAsAnonymous ? nil : comment.authorColor.flatMap(ProfileColor.init(rawValue:))
        default: return nil
        }
    }
}

@MainActor
final class AdminReportManageViewModel: ObservableObject {
    @Published var selectedTab: AdminReportTab = .pending
    @Published private(set) var reports: [Report] = []
    @Published private(set) var previews: [ReportTarget: ReportTargetPreview] = [:]
    @Published private(set) var hasLoaded = false
    /// Groups with a request in flight — their buttons are disabled.
    @Published private(set) var processingGroupIDs: Set<String> = []
    /// Report id → what this device did about it.
    @Published private(set) var actionHistory: [Int: [AdminModerationAction]] = [:]
    @Published var toastMessage: String?
    @Published var errorMessage: String?

    private let history: AdminActionHistoryStore
    private let isPreview: Bool
    /// Previews: the signed-in admin's 학번 (otherwise `CurrentUserSession`).
    private let previewAdminId: String?

    /// `nil` → `.shared`. (A `= .shared` default argument would be evaluated
    /// outside the main actor, which Swift 6 rejects.)
    init(history: AdminActionHistoryStore? = nil) {
        let history = history ?? .shared
        self.history = history
        isPreview = false
        previewAdminId = nil
        actionHistory = history.reportActions()
    }

    /// Preview data — never calls the server.
    init(
        previewReports: [Report],
        previews: [ReportTarget: ReportTargetPreview],
        selectedTab: AdminReportTab = .pending,
        actionHistory: [Int: [AdminModerationAction]] = [:],
        adminId: String = "admin"
    ) {
        history = .shared
        isPreview = true
        previewAdminId = adminId
        reports = previewReports
        self.previews = previews
        self.selectedTab = selectedTab
        self.actionHistory = actionHistory
        hasLoaded = true
    }

    // MARK: - Lists

    /// 미처리 — most reports first, then newest.
    var pendingGroups: [ReportGroup] {
        ReportGroup.make(from: reports.filter { $0.status == .pending }).sorted {
            $0.count != $1.count ? $0.count > $1.count : $0.latestDate > $1.latestDate
        }
    }

    /// 전체 — newest first.
    var allGroups: [ReportGroup] {
        ReportGroup.make(from: reports).sorted { $0.latestDate > $1.latestDate }
    }

    var visibleGroups: [ReportGroup] {
        selectedTab == .pending ? pendingGroups : allGroups
    }

    /// The red number on the 미처리 tab — cards to act on, not raw reports.
    var pendingCount: Int { pendingGroups.count }

    func preview(for group: ReportGroup) -> ReportTargetPreview {
        previews[group.target] ?? .loading
    }

    /// "게시글 삭제, 작성자 7일 정지" — nil when this device has no record.
    func resolvedSummary(for group: ReportGroup) -> String? {
        AdminActionHistoryStore.summary(for: group.reportIDs, in: actionHistory)
    }

    /// The signed-in admin's own 학번 — they can't ban themselves.
    var adminStudentId: String? {
        previewAdminId ?? CurrentUserSession.shared.profile?.studentId
    }

    func isSelf(_ studentId: String?) -> Bool {
        guard let studentId, let adminStudentId else { return false }
        return studentId == adminStudentId
    }

    /// 작성자 정지 needs a 학번, and it can't be the admin's own.
    func canBan(_ group: ReportGroup) -> Bool {
        guard let authorId = preview(for: group).authorId else { return false }
        return !isSelf(authorId)
    }

    /// Prefill of the ban reason: "욕설 또는 혐오 표현 (신고 3건)".
    func defaultBanReason(for group: ReportGroup) -> String {
        String(appLocalized: .adminBanDefaultReason(String(appLocalized: group.reason.label), group.count))
    }

    // MARK: - Loading

    func load() async {
        guard !isPreview else { return }
        do {
            if CurrentUserSession.shared.profile == nil {
                _ = try? await CurrentUserSession.shared.refresh()
            }
            reports = try await CyncAPI.fetchAllReports()
            hasLoaded = true
        } catch {
            errorMessage = String(appLocalized: .adminReportLoadFailed(error.localizedDescription))
            return
        }
        await loadPreviews()
    }

    /// One request per distinct target, all at once. Targets already shown
    /// keep their preview while it refreshes (no flash back to gray).
    private func loadPreviews() async {
        let targets = Set(reports.map(\.target))
        previews = previews.filter { targets.contains($0.key) }
        for target in targets where previews[target] == nil {
            previews[target] = .loading
        }

        await withTaskGroup(of: (ReportTarget, ReportTargetPreview).self) { group in
            for target in targets {
                group.addTask { (target, await Self.fetchPreview(for: target)) }
            }
            for await (target, preview) in group {
                previews[target] = preview
            }
        }
    }

    private nonisolated static func fetchPreview(for target: ReportTarget) async -> ReportTargetPreview {
        switch target.kind {
        case .post:
            do {
                return .post(try await CyncAPI.fetchPostDetail(id: target.id))
            } catch CyncAPIError.badStatus(let code) where code == 404 || code == 500 {
                return .deleted
            } catch {
                return .failed
            }
        case .comment:
            do {
                let comment = try await CyncAPI.fetchComment(id: target.id)
                return comment.deleted ? .deleted : .comment(comment)
            } catch {
                return .commentUnavailable
            }
        }
    }

    // MARK: - Actions

    /// 삭제 (confirmed by the view first) → resolve all.
    func delete(_ group: ReportGroup) async {
        await perform(on: group) {
            do {
                try await Self.deleteTarget(group.target)
            } catch {
                self.errorMessage = String(appLocalized: .adminReportDeleteFailed(error.localizedDescription))
                return
            }
            self.previews[group.target] = .deleted
            guard await self.resolveAll(group, actions: [.deleted(group.target.kind)], partialKey: .adminReportDeletedButResolveFailed) else { return }
            self.toastMessage = String(appLocalized: group.target.kind == .post ? .adminReportDeletedPostToast : .adminReportDeletedCommentToast)
        }
    }

    /// 문제없음 — no confirm; just resolves all.
    func dismiss(_ group: ReportGroup) async {
        await perform(on: group) {
            guard await self.resolveAll(group, actions: [.dismissed], partialKey: nil) else { return }
            self.toastMessage = String(appLocalized: .adminReportDismissedToast)
        }
    }

    /// 작성자 정지: ban → (delete) → resolve all, stopping at the first
    /// failure. Returns whether the ban itself went through — the card
    /// closes then (banning again wouldn't help); on a ban failure it stays
    /// open so the admin can retry.
    @discardableResult
    func ban(_ group: ReportGroup, period: AdminBanPeriod, reason: String, alsoDelete: Bool) async -> Bool {
        let reason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let studentId = preview(for: group).authorId, !reason.isEmpty else { return false }
        guard !isSelf(studentId) else {
            errorMessage = String(appLocalized: .adminBanSelfNotAllowed)
            return false
        }

        var banned = false
        await perform(on: group) {
            // 1. ban
            do {
                try await CyncAPI.banUser(studentId: studentId, days: period.days, reason: reason)
            } catch {
                self.errorMessage = String(appLocalized: .adminBanFailed(error.localizedDescription))
                return
            }
            banned = true
            self.history.logBan(studentId: studentId, days: period.days)

            // 2. delete (optional)
            var actions: [AdminModerationAction] = [.banned(days: period.days)]
            if alsoDelete {
                do {
                    try await Self.deleteTarget(group.target)
                } catch {
                    self.errorMessage = String(appLocalized: group.target.kind == .post
                        ? .adminBanDeletePostFailed : .adminBanDeleteCommentFailed)
                    return
                }
                self.previews[group.target] = .deleted
                actions.append(.deleted(group.target.kind))
            }

            // 3. resolve — only once everything above succeeded.
            let partialKey: LocalizedStringResource = alsoDelete
                ? .adminBanDeletedButResolveFailed : .adminBanBannedButResolveFailed
            guard await self.resolveAll(group, actions: actions, partialKey: partialKey) else { return }
            let doneKey: LocalizedStringResource = period.days.map { LocalizedStringResource.adminBanDoneToastDays($0) } ?? .adminBanDoneToastPermanent
            self.toastMessage = String(appLocalized: doneKey)
        }
        return banned
    }

    // MARK: - Helpers

    private static func deleteTarget(_ target: ReportTarget) async throws {
        switch target.kind {
        case .post: try await CyncAPI.deletePost(id: target.id)
        case .comment: try await CyncAPI.deleteComment(id: target.id)
        }
    }

    /// Resolves every still-pending report in the group, one by one (no
    /// batch API), swapping in the server's copy as each succeeds. Records
    /// `actions` for the resolved ones. On a failure: `partialKey`
    /// ("…됐지만 처리 완료 표시에 실패했어요") when an earlier step already
    /// changed something, else a plain failure; then reloads so the list
    /// matches the server.
    private func resolveAll(_ group: ReportGroup, actions: [AdminModerationAction],
                            partialKey: LocalizedStringResource?) async -> Bool {
        var resolvedIDs: [Int] = []
        defer {
            if !resolvedIDs.isEmpty {
                history.record(actions, forReports: resolvedIDs)
                actionHistory = history.reportActions()
            }
        }
        for report in group.reports where report.status == .pending {
            do {
                let updated = try await CyncAPI.resolveReport(id: report.id)
                replace(updated, fallback: report)
                resolvedIDs.append(report.id)
            } catch {
                errorMessage = partialKey.map { String(appLocalized: $0) }
                    ?? String(appLocalized: .adminReportResolveFailed(error.localizedDescription))
                return false
            }
        }
        return true
    }

    /// Swaps in the server's copy; marks it resolved even if the response
    /// somehow didn't say so, since the call succeeded.
    private func replace(_ updated: Report, fallback: Report) {
        var updated = updated.id == fallback.id ? updated : fallback
        updated.status = .resolved
        if let index = reports.firstIndex(where: { $0.id == fallback.id }) {
            reports[index] = updated
        }
    }

    private func perform(on group: ReportGroup, _ work: () async -> Void) async {
        guard !processingGroupIDs.contains(group.id) else { return }
        processingGroupIDs.insert(group.id)
        defer { processingGroupIDs.remove(group.id) }
        await work()
    }
}

// MARK: - Preview data

extension AdminReportManageViewModel {
    /// `CommunityPost`/`Comment` keep `createdAt` private, so preview
    /// copies are decoded the way the server's would be.
    private static func decoded<T: Decodable>(_ json: [String: Any]) -> T {
        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(T.self, from: data)
    }

    static var previewTargets: [ReportTarget: ReportTargetPreview] {
        let post6: CommunityPost = decoded([
            "id": 6, "title": "오늘 자료구조 과제 같이 할 사람",
            "content": "과제 같이 하실 분 구해요. 지난번에 같이 한 사람들은 진짜 … (욕설이 포함된 문장이 이어짐)",
            "authorId": "22011234", "authorName": "이민호", "authorNickname": "익명482913",
            "anonymous": false, "viewCount": 31, "likeCount": 0, "commentCount": 0,
            "createdAt": "2026-11-14T21:03:00", "updatedAt": "2026-11-14T21:03:00"
        ])
        let post2: CommunityPost = decoded([
            "id": 2, "title": "중고 전공서적 나눔합니다",
            "content": "자료구조, 운영체제 교재 나눔해요. 필요하신 분 댓글 남겨주세요.",
            "authorId": "20231005", "authorName": "최지훈",
            "anonymous": true, "viewCount": 20, "likeCount": 5, "commentCount": 1,
            "createdAt": "2026-11-13T10:00:00", "updatedAt": "2026-11-13T10:00:00"
        ])
        return [
            ReportTarget(kind: .post, id: 6): .post(post6),
            ReportTarget(kind: .comment, id: 5): .comment(previewComment),
            ReportTarget(kind: .post, id: 999): .deleted,
            ReportTarget(kind: .post, id: 2): .post(post2),
            ReportTarget(kind: .comment, id: 1): .commentUnavailable
        ]
    }

    static var previewComment: Comment {
        decoded([
            "id": 5, "postId": 3,
            "content": "부업 문의는 오픈채팅으로 주세요. 하루 30분 투자로 월 100 가능",
            "authorId": "23015678", "authorName": "정우성", "authorNickname": "광고왕", "authorColor": "ORANGE",
            "anonymous": false, "deleted": false, "createdAt": "2026-11-15T09:00:00"
        ])
    }
}
