//
//  LockerApplicationViewModel.swift
//  Cync
//
//  Backs LockerApplicationView with `GET /api/lockers/available` and
//  `POST /api/lockers/{id}/apply` (`docs/API.md` §4).
//

import Combine
import Foundation

@MainActor
final class LockerApplicationViewModel: ObservableObject {
    @Published var lockers: [Locker] = []
    @Published var selectedLockerID: Int?
    @Published var errorMessage: String?
    /// The location this grid belongs to — shown in
    /// `LockerApplicationConfirmDialog` (Figma: "센 B03 뒷문 방향").
    let location: String

    init(location: String = "센 B03 뒷문 방향") {
        self.location = location
    }

    var selectedLocker: Locker? {
        lockers.first { $0.id == selectedLockerID }
    }

    func load() async {
        do {
            lockers = try await CyncAPI.fetchAvailableLockers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectLocker(_ locker: Locker) {
        guard locker.status == .available else { return }
        selectedLockerID = (selectedLockerID == locker.id) ? nil : locker.id
    }

    /// Applies for `locker` and returns the server's response — which
    /// includes the assigned `password`/`dueDate` the confirmation dialogs
    /// display next.
    func apply(_ locker: Locker) async throws -> Locker {
        try await CyncAPI.applyLocker(id: locker.id)
    }
}
