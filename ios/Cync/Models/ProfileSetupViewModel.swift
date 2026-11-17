//
//  ProfileSetupViewModel.swift
//  Cync
//
//  Backs `ProfileSetupView` ("프로필 설정", Figma node `257:6758`). Reuses the
//  same `PUT /api/me/profile` call as `SettingsViewModel.updateProfile(_:_:)`
//  (`docs/API.md` §1) — this screen just doesn't expose the color picker, so
//  it saves whatever `profileColor` the account already has (the server's
//  auto-assigned default, since this is the account's first save).
//

import Foundation

@MainActor
final class ProfileSetupViewModel: ObservableObject {
    @Published var nickname: String
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    private let currentColor: ProfileColor

    init(currentNickname: String, currentColor: ProfileColor) {
        nickname = currentNickname
        self.currentColor = currentColor
    }

    var canSubmit: Bool {
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @discardableResult
    func submit() async -> Bool {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let profile = try await CyncAPI.updateMyProfile(nickname: trimmed, color: currentColor)
            CurrentUserSession.shared.update(profile)
            NicknameSetupStore.markCompleted(for: profile.studentId)
            return true
        } catch {
            errorMessage = String(appLocalized: .profileSaveFailedMessage)
            return false
        }
    }
}
