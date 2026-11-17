//
//  LoginViewModel.swift
//  Cync
//
//  Backs LoginView ("1-5 로그인"). `submit()` calls `CyncAPI.login`, which
//  hits the real `POST /api/auth/login` (see that method's header comment —
//  it's not in `docs/API.md` yet, but it's live on the backend).
//
//  "학번 기억하기" persists only the student id (never the password) to
//  `UserDefaults` so the field can be prefilled on next launch — this is
//  local, on-device storage, not a server-side "remember me" session.
//
//  "자동 로그인" is the one that keeps a session: when checked, the issued
//  JWT is saved to the Keychain so `SessionStore` can skip `LoginView` on
//  next launch (see that file).
//

import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var studentId: String
    @Published var password: String = ""
    @Published var rememberStudentId: Bool
    @Published var autoLogin: Bool
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    private static let rememberedStudentIdKey = "rememberedStudentId"

    init() {
        let remembered = UserDefaults.standard.string(forKey: Self.rememberedStudentIdKey)
        studentId = remembered ?? ""
        rememberStudentId = remembered != nil
        autoLogin = SessionStore.isAutoLoginEnabled
    }

    var canSubmit: Bool {
        !studentId.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    /// Returns whether login succeeded, so callers know when to flip
    /// `SessionStore.isLoggedIn`.
    @discardableResult
    func submit() async -> Bool {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            _ = try await CyncAPI.login(studentId: studentId, password: password, persistToken: autoLogin)
        } catch is URLError {
            // No connection / timeout — the request never got an answer, so
            // "check your id/password" would send the user the wrong way.
            errorMessage = String(appLocalized: .loginNetworkError)
            return false
        } catch {
            // Any answer from the server — a login screen shouldn't surface
            // raw HTTP/decoding detail, and the server reports a wrong
            // password as a plain error status, so it all reads as wrong
            // id/password to the user.
            errorMessage = String(appLocalized: .loginFailedMessage)
            return false
        }

        if rememberStudentId {
            UserDefaults.standard.set(studentId, forKey: Self.rememberedStudentIdKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.rememberedStudentIdKey)
        }

        SessionStore.isAutoLoginEnabled = autoLogin

        return true
    }
}
