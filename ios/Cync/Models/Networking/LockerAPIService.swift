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

enum LockerAPIService {
    static func fetchStatusByLockerNumber() async throws -> [Int: LockerCellStatus] {
        let lockers = try await CyncAPI.fetchAllLockers()
        return Dictionary(
            lockers.map { ($0.lockerNumber, LockerCellStatus(serverStatus: $0.status)) },
            uniquingKeysWith: { _, latest in latest }
        )
    }
}

private extension LockerCellStatus {
    init(serverStatus: LockerStatus) {
        switch serverStatus {
        case .available: self = .empty
        case .pending: self = .pending
        case .inUse: self = .occupied
        case .broken: self = .broken
        }
    }
}
