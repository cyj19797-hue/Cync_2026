//
//  Locker.swift
//  Cync
//
//  Data model backing the "4 사물함" (Locker) list screen's grid + summary
//  card, and reused by "4-1 사물함 신청" (Locker Application)'s own grid —
//  now the real `Locker` shape from `GET /api/lockers` (`docs/API.md` §4).
//
//  The server tracks 4 raw states (`LockerStatus`); "내 사물함" isn't a
//  status of its own — the server marks the signed-in student's own locker
//  with `mine: true`. `currentUserId` only comes for an admin or for your
//  own locker (null otherwise), so it can't be compared any more.
//
//  `.pending` was added by the 2026-09-03 API change (`docs/API.md` §4):
//  applying no longer grants a locker immediately, it moves it to
//  `PENDING` until an admin approves it.
//

import Foundation

enum LockerStatus: String, Codable {
    case available = "AVAILABLE"
    case pending = "PENDING"
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
    /// The signed-in student's own locker (pending or in use). Missing in
    /// older responses → false.
    var mine: Bool = false

    init(
        id: Int,
        lockerNumber: Int,
        location: String?,
        status: LockerStatus,
        currentUserId: String?,
        assignedAt: String?,
        dueDate: String?,
        password: String?,
        mine: Bool = false
    ) {
        self.id = id
        self.lockerNumber = lockerNumber
        self.location = location
        self.status = status
        self.currentUserId = currentUserId
        self.assignedAt = assignedAt
        self.dueDate = dueDate
        self.password = password
        self.mine = mine
    }

    private enum CodingKeys: String, CodingKey {
        case id, lockerNumber, location, status, currentUserId, assignedAt, dueDate, password, mine
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        lockerNumber = try c.decode(Int.self, forKey: .lockerNumber)
        location = try c.decodeIfPresent(String.self, forKey: .location)
        status = try c.decode(LockerStatus.self, forKey: .status)
        currentUserId = try c.decodeIfPresent(String.self, forKey: .currentUserId)
        assignedAt = try c.decodeIfPresent(String.self, forKey: .assignedAt)
        dueDate = try c.decodeIfPresent(String.self, forKey: .dueDate)
        password = try c.decodeIfPresent(String.self, forKey: .password)
        mine = try c.decodeIfPresent(Bool.self, forKey: .mine) ?? false
    }
}

/// `POST /api/lockers/return-all` — `executed` is false for a preview
/// (`confirm=false`), true once the lockers were actually returned.
struct ReturnAllResult: Decodable, Equatable {
    let executed: Bool
    let count: Int
    let lockerNumbers: [Int]
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
                currentUserId: number == 27 ? "20231234" : nil,
                assignedAt: number == 27 ? "2026-03-01" : nil,
                dueDate: number == 27 ? "2026-12-31" : nil,
                password: number == 27 ? "3847" : nil,
                mine: number == 27
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
                currentUserId: nil,
                assignedAt: nil,
                dueDate: nil,
                password: nil
            )
        }
    }()
}
