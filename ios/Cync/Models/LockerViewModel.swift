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
    @Published var selectedLocation: String = ""
    @Published private(set) var locations: [String] = []
    @Published var errorMessage: String?

    func load() async {
        do {
            async let lockersTask = CyncAPI.fetchAllLockers()
            async let profileTask = CurrentUserSession.shared.refresh()
            let (allLockers, profile) = try await (lockersTask, profileTask)

            lockers = allLockers
            myLocker = allLockers.first { $0.isMine(studentId: profile.studentId) }
            locations = Array(Set(allLockers.compactMap(\.location))).sorted()
            if selectedLocation.isEmpty || !locations.contains(selectedLocation) {
                selectedLocation = locations.first ?? ""
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var lockersAtSelectedLocation: [Locker] {
        lockers.filter { $0.location == selectedLocation }
    }
}
