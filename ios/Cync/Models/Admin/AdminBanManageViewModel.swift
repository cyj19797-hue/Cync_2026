//
//  AdminBanManageViewModel.swift
//  Cync
//
//  Backs "관리자 - 활동 정지 관리" (`AdminBanManageView`) — ban or unban by
//  typing a 학번 (`docs/API.md` §5). There's no user-list API, so the 학번
//  can't be looked up or checked ahead of time; the server answers an
//  unknown one with 500 "사용자를 찾을 수 없습니다", shown here as "앱에
//  가입한 적이 없는 학번이에요". Banning from a report card is more exact
//  (the screen says so).
//
//  The view confirms before `submit()` — a mistyped 학번 bans someone else.
//  Every success is logged to "이 기기에서 처리한 내역" (last 20, shared
//  with bans made from 신고 관리).
//

import Combine
import Foundation

enum AdminBanTab: CaseIterable, Hashable {
    case ban
    case unban

    var titleKey: LocalizedStringResource {
        switch self {
        case .ban: return .adminBanManageTabBan
        case .unban: return .adminBanManageTabUnban
        }
    }
}

@MainActor
final class AdminBanManageViewModel: ObservableObject {
    @Published var selectedTab: AdminBanTab = .ban
    @Published var studentId = ""
    @Published var period = AdminBanPeriod.default
    @Published var reason = ""
    @Published private(set) var log: [AdminBanLogEntry] = []
    @Published private(set) var isSubmitting = false
    @Published var toastMessage: String?
    @Published var errorMessage: String?

    private let history: AdminActionHistoryStore
    private let isPreview: Bool
    private let previewAdminId: String?

    /// `nil` → `.shared`. (A `= .shared` default argument would be evaluated
    /// outside the main actor, which Swift 6 rejects.)
    init(history: AdminActionHistoryStore? = nil) {
        let history = history ?? .shared
        self.history = history
        isPreview = false
        previewAdminId = nil
        log = history.banLog()
    }

    /// Preview data — never calls the server.
    init(previewTab: AdminBanTab, studentId: String, reason: String = "", log: [AdminBanLogEntry]) {
        history = .shared
        isPreview = true
        previewAdminId = "admin"
        selectedTab = previewTab
        self.studentId = studentId
        self.reason = reason
        self.log = log
    }

    /// Spaces are already stripped as it's typed; trimmed again for safety.
    var trimmedStudentId: String { studentId.filter { !$0.isWhitespace } }
    var trimmedReason: String { reason.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var adminStudentId: String? {
        previewAdminId ?? CurrentUserSession.shared.profile?.studentId
    }

    var isSelf: Bool { !trimmedStudentId.isEmpty && trimmedStudentId == adminStudentId }

    /// The bottom button: a 학번, plus a reason on the 정지 tab.
    var canSubmit: Bool {
        guard !trimmedStudentId.isEmpty, !isSubmitting else { return false }
        return selectedTab == .unban || !trimmedReason.isEmpty
    }

    /// "22011234 7일 정지하기" / "22011234 영구 정지하기" / "22011234 정지 해제하기".
    /// Without a 학번 it falls back to "정지하기" / "정지 해제하기".
    var submitKey: LocalizedStringResource {
        let id = trimmedStudentId
        switch selectedTab {
        case .unban:
            return id.isEmpty ? .adminBanManageUnbanButtonEmpty : .adminBanManageUnbanButton(id)
        case .ban:
            if id.isEmpty { return .adminBanManageBanButtonEmpty }
            guard period.days != nil else { return .adminBanManageBanButtonPermanent(id) }
            return .adminBanManageBanButtonDays(id, String(appLocalized: period.labelKey))
        }
    }

    /// Title of the confirm dialog.
    var confirmTitleKey: LocalizedStringResource {
        let id = trimmedStudentId
        switch selectedTab {
        case .unban: return .adminBanManageConfirmUnbanTitle(id)
        case .ban:
            guard period.days != nil else { return .adminBanManageConfirmBanPermanentTitle(id) }
            return .adminBanManageConfirmBanTitle(id, String(appLocalized: period.labelKey))
        }
    }

    /// Called by the bottom button before the dialog: catches the admin's
    /// own 학번 right away. Returns whether to show the confirm dialog.
    func validateBeforeConfirm() -> Bool {
        guard canSubmit else { return false }
        if selectedTab == .ban && isSelf {
            errorMessage = String(appLocalized: .adminBanSelfNotAllowed)
            return false
        }
        return true
    }

    /// After the dialog's 확인.
    func submit() async {
        guard canSubmit, !isPreview else { return }
        let id = trimmedStudentId
        if selectedTab == .ban && isSelf {
            errorMessage = String(appLocalized: .adminBanSelfNotAllowed)
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            switch selectedTab {
            case .ban:
                try await CyncAPI.banUser(studentId: id, days: period.days, reason: trimmedReason)
                history.logBan(studentId: id, days: period.days)
                let doneKey: LocalizedStringResource = period.days == nil
                    ? .adminBanManageBanDonePermanent(id)
                    : .adminBanManageBanDoneDays(id, String(appLocalized: period.labelKey))
                toastMessage = String(appLocalized: doneKey)
            case .unban:
                try await CyncAPI.unbanUser(studentId: id)
                history.logUnban(studentId: id)
                toastMessage = String(appLocalized: .adminBanManageUnbanDone(id))
            }
            log = history.banLog()
            // Ready for the next one; the tab and period stay.
            studentId = ""
            reason = ""
        } catch CyncAPIError.badStatus(500) {
            // The only 500 these two endpoints throw on purpose.
            errorMessage = String(appLocalized: .adminBanManageUnknownStudent)
        } catch {
            errorMessage = String(appLocalized: selectedTab == .ban
                ? .adminBanFailed(error.localizedDescription)
                : .adminBanManageUnbanFailed(error.localizedDescription))
        }
    }
}

extension AdminBanManageViewModel {
    static var previewLog: [AdminBanLogEntry] {
        [
            AdminBanLogEntry(studentId: "22011234", action: .ban(days: 7), date: Date().addingTimeInterval(-86_400)),
            AdminBanLogEntry(studentId: "21019876", action: .unban, date: Date().addingTimeInterval(-3 * 86_400))
        ]
    }
}
