//
//  CurrentUserSession.swift
//  Cync
//
//  Shared cache of `GET /api/me`. Several unrelated screens each need a
//  piece of it — Settings shows nickname/color, Community gates writing on
//  `currentlyBanned`, Lockers needs `studentId` to tell "내 사물함" apart
//  from someone else's — so this is one place to `refresh()` it instead of
//  duplicating the fetch, matching `docs/API.md`'s own advice to call
//  `fetchMyProfile()` on app entry or tab switch.
//

import Foundation

@MainActor
final class CurrentUserSession: ObservableObject {
    static let shared = CurrentUserSession()

    @Published private(set) var profile: UserProfile?

    private init() {}

    @discardableResult
    func refresh() async throws -> UserProfile {
        let profile = try await CyncAPI.fetchMyProfile()
        self.profile = profile
        return profile
    }

    func update(_ profile: UserProfile) {
        self.profile = profile
    }
}
