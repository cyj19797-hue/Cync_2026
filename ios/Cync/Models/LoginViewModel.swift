//
//  LoginViewModel.swift
//  Cync
//
//  Backs LoginView ("1-5 로그인"). There is no `/api/auth/login` endpoint in
//  `docs/API.md` yet, so `submit()` mocks a successful login instead of
//  calling the real backend — see `LoginCredentials`'s header comment for
//  the same gap.
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

    /// Mock login — see the type header comment for why this doesn't call
    /// the real backend yet.
    func submit() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        try? await Task.sleep(for: .seconds(0.5))

        if rememberStudentId {
            UserDefaults.standard.set(studentId, forKey: Self.rememberedStudentIdKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.rememberedStudentIdKey)
        }
    }
}
