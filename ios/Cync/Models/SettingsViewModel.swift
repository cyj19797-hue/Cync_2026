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
    @Published var errorMessage: String?

    func loadProfile() async {
        do {
            let profile = try await CyncAPI.fetchMyProfile()
            self.profile = profile
            CurrentUserSession.shared.update(profile)
        } catch is CancellationError {
            // Leaving the screen mid-load cancels it — not an error.
        } catch let error as URLError where error.code == .cancelled {
            // Same, surfaced by URLSession.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Saves via `PUT /api/me/profile`. Returns `nil` on success (and
    /// `profile` — so the settings card — updates right away), or the
    /// message the editor shows inside itself on failure. The server
    /// doesn't say *why* a nickname was refused (taken vs. not allowed), so
    /// those share one message; a network failure gets its own.
    func updateProfile(nickname: String, color: ProfileColor) async -> String? {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let profile = try await CyncAPI.updateMyProfile(nickname: trimmed, color: color)
            self.profile = profile
            CurrentUserSession.shared.update(profile)
            NicknameSetupStore.markCompleted(for: profile.studentId)
            return nil
        } catch is URLError {
            return String(appLocalized: .profileEditNetworkError)
        } catch {
            return String(appLocalized: .profileEditServerError)
        }
    }
}
