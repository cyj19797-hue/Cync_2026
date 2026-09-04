//
//  LoginCredentials.swift
//  Cync
//
//  Payload shape for a future `POST /api/auth/login` call — no such endpoint
//  exists in `docs/API.md` yet (see `CyncAPI.swift`'s header comment on
//  `accessToken` always starting `nil`), so `LoginViewModel.submit()` only
//  mocks a successful login for now instead of calling a real endpoint.
//

import Foundation

struct LoginCredentials {
    var studentId: String
    var password: String
}
