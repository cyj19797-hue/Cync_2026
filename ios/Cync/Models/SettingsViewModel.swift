//
//  SettingsViewModel.swift
//  Cync
//
//  Backs SettingsView with the real `GET /api/me` / `PUT /api/me/profile`
//  calls (see `docs/API.md` §1). `profile` is `nil` until `loadProfile()`
//  finishes — every request needs a Keychain access token this app has no
//  login flow to populate yet, so today `loadProfile()` will fail with
//  `.unauthorized` until that exists.
//

import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var language: AppLanguage = .korean
    @Published var searchText: String = ""
    @Published var errorMessage: String?

    func loadProfile() async {
        do {
            let profile = try await CyncAPI.fetchMyProfile()
            self.profile = profile
            CurrentUserSession.shared.update(profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateProfile(nickname: String, color: ProfileColor) async {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let profile = try await CyncAPI.updateMyProfile(nickname: trimmed, color: color)
            self.profile = profile
            CurrentUserSession.shared.update(profile)
        } catch {
            errorMessage = "닉네임이 중복되었거나 저장에 실패했습니다."
        }
    }
}
