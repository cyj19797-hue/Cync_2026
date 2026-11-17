//
//  AdminActionHistoryStore.swift
//  Cync
//
//  What an admin did on THIS device — the server keeps neither.
//
//  1. Per report id: which action closed it ("게시글 삭제", "작성자 7일
//     정지", "문제없음"). `RESOLVED` on the server says only that someone
//     looked at it, so a resolved card shows "처리 완료 · 게시글 삭제" when
//     this device remembers, and just "처리 완료" when it doesn't (another
//     admin, another phone, a reinstall).
//  2. The last 20 bans/unbans (학번 · 조치 · 날짜) for "활동 정지 관리"'s
//     "이 기기에서 처리한 내역" — bans made from a report card count too.
//
//  Actions are stored as codes, not text, so the summary follows the app
//  language. UserDefaults, not the Keychain: nothing here is secret.
//

import Foundation

/// One thing done about a report.
enum AdminModerationAction: Hashable {
    case deleted(ReportTargetKind)
    /// `nil` days = permanent.
    case banned(days: Int?)
    case dismissed

    /// Stored form.
    var code: String {
        switch self {
        case .deleted(.post): return "deletedPost"
        case .deleted(.comment): return "deletedComment"
        case .banned(let days): return days.map { "ban:\($0)" } ?? "ban:permanent"
        case .dismissed: return "dismissed"
        }
    }

    init?(code: String) {
        switch code {
        case "deletedPost": self = .deleted(.post)
        case "deletedComment": self = .deleted(.comment)
        case "dismissed": self = .dismissed
        case "ban:permanent": self = .banned(days: nil)
        default:
            guard code.hasPrefix("ban:"), let days = Int(code.dropFirst(4)) else { return nil }
            self = .banned(days: days)
        }
    }

    /// "게시글 삭제", "작성자 7일 정지", "문제없음으로 처리".
    var summaryText: String {
        switch self {
        case .deleted(.post): return String(appLocalized: .adminReportHistoryDeletedPost)
        case .deleted(.comment): return String(appLocalized: .adminReportHistoryDeletedComment)
        case .banned(let days?): return String(appLocalized: .adminReportHistoryBanDays(days))
        case .banned(nil): return String(appLocalized: .adminReportHistoryBanPermanent)
        case .dismissed: return String(appLocalized: .adminReportHistoryDismissed)
        }
    }

    /// Delete before ban, as Figma writes it ("게시글 삭제, 작성자 7일 정지").
    fileprivate var sortOrder: Int {
        switch self {
        case .deleted: return 0
        case .banned: return 1
        case .dismissed: return 2
        }
    }
}

/// A ban or unban made on this device.
struct AdminBanLogEntry: Codable, Hashable, Identifiable {
    enum Action: Codable, Hashable {
        /// `nil` days = permanent.
        case ban(days: Int?)
        case unban
    }

    var id: UUID = UUID()
    let studentId: String
    let action: Action
    let date: Date

    /// "7일 정지" / "영구 정지" / "정지 해제".
    var actionText: String {
        switch action {
        case .ban(let days?): return String(appLocalized: .adminBanManageLogBanDays(days))
        case .ban(nil): return String(appLocalized: .adminBanManageLogBanPermanent)
        case .unban: return String(appLocalized: .adminBanManageLogUnban)
        }
    }

    /// "7일 정지 · 11/14".
    var detailText: String {
        String(appLocalized: .adminBanManageLogDetail(actionText, RelativeTime.shortDateText(for: date)))
    }
}

@MainActor
final class AdminActionHistoryStore {
    static let shared = AdminActionHistoryStore()

    private let defaults: UserDefaults
    private static let reportActionsKey = "admin.reportActions"
    private static let banLogKey = "admin.banLog"
    static let banLogLimit = 20

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Report actions

    /// Every remembered action, keyed by report id.
    func reportActions() -> [Int: [AdminModerationAction]] {
        let raw = defaults.dictionary(forKey: Self.reportActionsKey) as? [String: [String]] ?? [:]
        var result: [Int: [AdminModerationAction]] = [:]
        for (key, codes) in raw {
            guard let id = Int(key) else { continue }
            result[id] = codes.compactMap(AdminModerationAction.init(code:))
        }
        return result
    }

    /// Records `actions` for each report. Replaces anything stored before
    /// for those ids — they've just been resolved again.
    func record(_ actions: [AdminModerationAction], forReports reportIDs: [Int]) {
        var raw = defaults.dictionary(forKey: Self.reportActionsKey) as? [String: [String]] ?? [:]
        let codes = actions.sorted { $0.sortOrder < $1.sortOrder }.map(\.code)
        for id in reportIDs {
            raw[String(id)] = codes
        }
        defaults.set(raw, forKey: Self.reportActionsKey)
    }

    /// "게시글 삭제, 작성자 7일 정지" for a resolved card; nil when this
    /// device has no record of any of its reports.
    static func summary(for reportIDs: [Int], in actions: [Int: [AdminModerationAction]]) -> String? {
        // Every report in a group was resolved together, so any one with a
        // record speaks for the group (the newest first).
        guard let found = reportIDs.lazy.compactMap({ actions[$0] }).first(where: { !$0.isEmpty }) else {
            return nil
        }
        return found
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(\.summaryText)
            .joined(separator: ", ")
    }

    // MARK: - Ban log

    /// Newest first, at most `banLogLimit`.
    func banLog() -> [AdminBanLogEntry] {
        guard let data = defaults.data(forKey: Self.banLogKey),
              let entries = try? JSONDecoder().decode([AdminBanLogEntry].self, from: data) else { return [] }
        return entries
    }

    func logBan(studentId: String, days: Int?, date: Date = Date()) {
        append(AdminBanLogEntry(studentId: studentId, action: .ban(days: days), date: date))
    }

    func logUnban(studentId: String, date: Date = Date()) {
        append(AdminBanLogEntry(studentId: studentId, action: .unban, date: date))
    }

    private func append(_ entry: AdminBanLogEntry) {
        let entries = Array(([entry] + banLog()).prefix(Self.banLogLimit))
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Self.banLogKey)
        }
    }
}
