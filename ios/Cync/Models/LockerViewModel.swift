//
//  LockerViewModel.swift
//  Cync
//
//  Backs LockerView with the real `GET /api/lockers` call (`docs/API.md`
//  §4). "내 사물함" isn't returned separately by the server — it's whichever
//  locker in the full list has `currentUserId` equal to the signed-in
//  student's id, which needs `GET /api/me` (via `CurrentUserSession`).
//

import Combine
import Foundation

@MainActor
final class LockerViewModel: ObservableObject {
    @Published var lockers: [Locker] = []
    @Published var myLocker: Locker?
    @Published var errorMessage: String?
    /// `false` until the first successful load — the header's "신청" button
    /// waits for it so it doesn't flash for students who already have one.
    @Published private(set) var hasLoaded = false

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
            myLocker = allLockers.first { $0.isMine(studentId: profile.studentId) }
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// "사물함 비밀번호 찾기" gate: checks the account password (see
    /// `CyncAPI.verifyPassword`). `false` if the student id isn't known yet.
    func verifyAccountPassword(_ password: String) async throws -> Bool {
        guard let studentId else { return false }
        return try await CyncAPI.verifyPassword(studentId: studentId, password: password)
    }
}
