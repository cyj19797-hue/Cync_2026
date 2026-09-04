//
//  Locker.swift
//  Cync
//
//  Data model backing the "4 사물함" (Locker) list screen's grid + summary
//  card, and reused by "4-1 사물함 신청" (Locker Application)'s own grid —
//  now the real `Locker` shape from `GET /api/lockers` (`docs/API.md` §4).
//
//  The server only tracks 3 raw states (`LockerStatus`) plus
//  `currentUserId`; "내 사물함" isn't a status of its own, it's derived by
//  comparing `currentUserId` to the signed-in student's id (`isMine(studentId:)`).
//

import Foundation

enum LockerStatus: String, Codable {
    case available = "AVAILABLE"
    case inUse = "IN_USE"
    case broken = "BROKEN"
}

struct Locker: Identifiable, Codable {
    let id: Int
    var lockerNumber: Int
    var location: String?
    var status: LockerStatus
    var currentUserId: String?
    var assignedAt: String?
    var dueDate: String?
    /// Only populated by the server when the caller owns this locker (or
    /// is an admin) — see `docs/API.md` §4.
    var password: String?

    func isMine(studentId: String?) -> Bool {
        guard let studentId, let currentUserId else { return false }
        return studentId == currentUserId
    }
}

extension Locker {
    /// Mock data for previews only — the real grid always comes from
    /// `GET /api/lockers` (see `LockerViewModel.load()`).
    static let mockList: [Locker] = {
        let cycle: [LockerStatus] = [.inUse, .available, .available, .broken, .broken, .available]
        return (1...48).map { number in
            let status: LockerStatus = number == 27 ? .inUse : cycle[number % cycle.count]
            return Locker(
                id: number,
                lockerNumber: number,
                location: "센B202 앞",
                status: status,
                currentUserId: number == 27 ? "20231234" : (status == .inUse ? "other-student" : nil),
                assignedAt: number == 27 ? "2026-03-01" : nil,
                dueDate: number == 27 ? "2026-12-31" : nil,
                password: number == 27 ? "3847" : nil
            )
        }
    }()

    /// Mock data for the "4-1 사물함 신청" screen, matching Figma's `361:4254`
    /// ("사물함1") — a 6×6 grid (36 lockers) of unassigned lockers only.
    static let applicationMockList: [Locker] = {
        let cycle: [LockerStatus] = [.inUse, .available, .available, .broken, .broken, .available]
        return (1...36).map { number in
            Locker(
                id: number,
                lockerNumber: number,
                location: "센 B03 뒷문 방향",
                status: cycle[number % cycle.count],
                currentUserId: cycle[number % cycle.count] == .inUse ? "other-student" : nil,
                assignedAt: nil,
                dueDate: nil,
                password: nil
            )
        }
    }()
}
