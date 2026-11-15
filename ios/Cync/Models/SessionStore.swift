//
//  SessionStore.swift
//  Cync
//
//  App-wide login state, driving whether `CyncApp` shows `LoginView` or
//  `RootTabView`.
//
//  "자동 로그인" (`LoginView`): when it was checked at the last login, the
//  JWT is kept in the Keychain and `isLoggedIn` starts `true` on launch —
//  as long as that token hasn't expired yet (its `exp` claim). Otherwise
//  the app starts logged out and `LoginView` shows as before.
//
//  The on/off preference lives in `UserDefaults`, not the Keychain, on
//  purpose: Keychain items survive deleting the app, `UserDefaults` doesn't,
//  so a reinstall never silently logs back in with a stale token.
//

import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var isLoggedIn: Bool

    private static let autoLoginEnabledKey = "autoLoginEnabled"

    /// Last "자동 로그인" checkbox value — also prefills that checkbox.
    static var isAutoLoginEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: autoLoginEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: autoLoginEnabledKey) }
    }

    init() {
        if Self.isAutoLoginEnabled,
           let token = CyncAPI.accessToken,
           !JWT.isExpired(token) {
            isLoggedIn = true
        } else {
            // Drop any leftover token (auto login off, expired, or left
            // behind by a previous install) so requests don't send it.
            CyncAPI.logout()
            isLoggedIn = false
        }
    }

    func logIn() {
        isLoggedIn = true
    }

    func logOut() {
        CyncAPI.logout()
        isLoggedIn = false
    }
}

/// Reads a JWT's `exp` claim locally — no signature check, only used to
/// skip auto login with a token the server would reject anyway.
private enum JWT {
    static func isExpired(_ token: String) -> Bool {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return true }

        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)

        guard let data = Data(base64Encoded: base64),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else {
            // No readable `exp` — treat as non-expiring; the server still
            // answers 401 if it's actually invalid.
            return false
        }
        return Date(timeIntervalSince1970: exp) <= Date()
    }
}
