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

import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var studentId: String
    @Published var password: String = ""
    @Published var rememberStudentId: Bool
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    private static let rememberedStudentIdKey = "rememberedStudentId"

    init() {
        let remembered = UserDefaults.standard.string(forKey: Self.rememberedStudentIdKey)
        studentId = remembered ?? ""
        rememberStudentId = remembered != nil
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
            _ = try await CyncAPI.login(studentId: studentId, password: password)
        } catch {
            errorMessage = (error as? CyncAPIError)?.errorDescription
                ?? "로그인에 실패했습니다. 학번/비밀번호를 확인해주세요."
            return false
        }

        if rememberStudentId {
            UserDefaults.standard.set(studentId, forKey: Self.rememberedStudentIdKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.rememberedStudentIdKey)
        }

        return true
    }
}
