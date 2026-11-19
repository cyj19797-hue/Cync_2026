//
//  LockerAPIService.swift
//  Cync
//
//  Bridges the physical locker map (`LockerMapViewController`) to the real
//  `GET /api/lockers` data (`docs/API.md` §4, already wrapped by
//  `CyncAPI.fetchAllLockers()`) instead of the local layout JSON's status.
//  Reuses `CyncAPI`'s networking and error handling rather than opening a
//  second URLSession path — this file is just the mapping from a server
//  `Locker` list to `[lockerNumber: LockerCellStatus]`, keyed the same way
//  `LockerCell.lockerNumber` is, so the map screen can look each cell up.
//

import Foundation

//
//  Students' maps only (the admin map is fed its own statuses): someone
//  else's pending request reads as 사용 불가 — "승인 대기" is only shown
//  for the student's own request (`mine`).
//

enum LockerAPIService {
    static func fetchStatusByLockerNumber() async throws -> [Int: LockerCellStatus] {
        let lockers = try await CyncAPI.fetchAllLockers()
        return Dictionary(
            lockers.map { ($0.lockerNumber, studentStatus(for: $0)) },
            uniquingKeysWith: { _, latest in latest }
        )
    }

    /// Others' `PENDING` → `.occupied`; everything else as the server says.
    static func studentStatus(for locker: Locker) -> LockerCellStatus {
        if locker.status == .pending && !locker.mine { return .occupied }
        return LockerCellStatus(serverStatus: locker.status)
    }
}

extension LockerCellStatus {
    /// Server status → map cell status (also used by the admin screen,
    /// which feeds the map its own data).
    init(serverStatus: LockerStatus) {
        switch serverStatus {
        case .available: self = .empty
        case .pending: self = .pending
        case .inUse: self = .occupied
        case .broken: self = .broken
        }
    }
}
