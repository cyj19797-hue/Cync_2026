//
//  LockerViewModel.swift
//  Cync
//
//  Backs LockerView with the real `GET /api/lockers` call (`docs/API.md`
//  §4). "내 사물함" is the locker the server marks `mine: true`.
//
//  After each load, `LockerApplicationTracker` checks whether a request
//  the student was waiting on vanished (rejected, or cancelled by the
//  admin's 학기 말 전체 반납) and, if the "신청 거절" alert is on, sets
//  `rejectedLocker` for LockerView's popup.
//

import Combine
import Foundation

@MainActor
final class LockerViewModel: ObservableObject {
    @Published var lockers: [Locker] = []
    @Published var myLocker: Locker?
    @Published var errorMessage: String?
    /// A request that didn't go through — LockerView shows
    /// `LockerRejectedDialog` while it's set.
    @Published var rejectedLocker: RejectedLocker?

    struct RejectedLocker: Equatable {
        let zoneId: String?
        let lockerNumber: Int
    }
    /// `false` until the first successful load — the header's "신청" button
    /// waits for it so it doesn't flash for students who already have one.
    @Published private(set) var hasLoaded = false
    /// Shows the header's "관리" button (→ AdminLockerManageView). Hidden
    /// for everyone else; the server enforces the rest.
    @Published private(set) var isAdmin = CurrentUserSession.shared.profile?.isAdmin ?? false

    private var studentId: String?
    /// Locker number → room ("B201"), from `lockers.json`, for the
    /// room label in front of MyLockerCard's locker number.
    private let zoneIdByNumber: [Int: String] = {
        guard let grouped = try? LockerDataLoader.loadGroupedByZone() else { return [:] }
        var map: [Int: String] = [:]
        for (zoneId, cells) in grouped {
            for cell in cells {
                if let number = cell.lockerNumber { map[number] = zoneId }
            }
        }
        return map
    }()

    func zoneId(forLockerNumber number: Int) -> String? {
        zoneIdByNumber[number]
    }

    func load() async {
        do {
            async let lockersTask = CyncAPI.fetchAllLockers()
            async let profileTask = CurrentUserSession.shared.refresh()
            let (allLockers, profile) = try await (lockersTask, profileTask)

            lockers = allLockers
            studentId = profile.studentId
            isAdmin = profile.isAdmin
            #if DEBUG
            if let role = MockServer.lockerRole { isAdmin = role == "admin" }
            #endif
            myLocker = allLockers.first { $0.mine }
            hasLoaded = true
            checkForRejectedApplication(studentId: profile.studentId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 신청 완료 — the applied locker becomes "나의 사물함" right away, and
    /// is remembered as waiting for approval.
    func didApply(_ locker: Locker) {
        var locker = locker
        locker.mine = true
        myLocker = locker
        if let studentId, locker.status == .pending {
            LockerApplicationTracker.remember(lockerNumber: locker.lockerNumber, studentId: studentId)
        }
    }

    /// Admins never apply, so they never get the popup.
    private func checkForRejectedApplication(studentId: String) {
        guard !isAdmin,
              let number = LockerApplicationTracker.resolve(myLocker: myLocker, studentId: studentId)
        else { return }
        let preferences = LocalNotificationPreferencesStore().load()
        // "전체 알림" off silences every alert under it, 신청 거절 included.
        guard preferences.allEnabled && preferences.lockerRejected else { return }
        rejectedLocker = RejectedLocker(zoneId: zoneId(forLockerNumber: number), lockerNumber: number)
    }

    /// "사물함 비밀번호 찾기" gate: checks the account password (see
    /// `CyncAPI.verifyPassword`). `false` if the student id isn't known yet.
    func verifyAccountPassword(_ password: String) async throws -> Bool {
        guard let studentId else { return false }
        return try await CyncAPI.verifyPassword(studentId: studentId, password: password)
    }
}
