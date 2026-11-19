//
//  SessionStore.swift
//  Cync
//
//  App-wide entry state, driving what `CyncApp`'s `RootView` shows:
//  `entryState` is the one place that decides between the intro/login,
//  the terms screen and the main tabs.
//
//  - `.checking`: launched with a saved "자동 로그인" token — waiting for
//    `GET /api/me` to say whether the terms were agreed. The splash stays
//    up meanwhile, so the main tabs never flash before the terms screen.
//  - `.loggedOut`: 앱 소개 → 로그인.
//  - `.needsTermsAgreement`: logged in but not agreed — only
//    `TermsAgreementView`; no tabs, no popups.
//  - `.ready`: the main tabs (and app-launch popup notices).
//
//  "자동 로그인" (`LoginView`): when it was checked at the last login, the
//  JWT is kept in the Keychain and the app starts in `.checking` — as long
//  as that token hasn't expired yet (its `exp` claim). Otherwise it starts
//  `.loggedOut`.
//
//  The on/off preference lives in `UserDefaults`, not the Keychain, on
//  purpose: Keychain items survive deleting the app, `UserDefaults` doesn't,
//  so a reinstall never silently logs back in with a stale token.
//

import Foundation

enum AppEntryState: Equatable {
    case checking
    case loggedOut
    case needsTermsAgreement
    case ready
}

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var entryState: AppEntryState

    /// Any logged-in state (terms agreed or not).
    var isLoggedIn: Bool {
        entryState == .ready || entryState == .needsTermsAgreement
    }

    private static let autoLoginEnabledKey = "autoLoginEnabled"
    /// How long auto login waits for `/api/me` before falling back to
    /// `TermsAgreementCache`.
    private static let profileCheckTimeout: Duration = .seconds(5)

    /// Last "자동 로그인" checkbox value — also prefills that checkbox.
    static var isAutoLoginEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: autoLoginEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: autoLoginEnabledKey) }
    }

    init() {
        #if DEBUG
        MockServer.resetAuthIfNeeded()
        if MockServer.startsLoggedOut { CyncAPI.logout() }
        #endif
        if Self.isAutoLoginEnabled,
           let token = CyncAPI.accessToken,
           !JWT.isExpired(token) {
            entryState = .checking
        } else {
            // Drop any leftover token (auto login off, expired, or left
            // behind by a previous install) so requests don't send it.
            CyncAPI.logout()
            entryState = .loggedOut
        }
    }

    /// Previews: start in a given state without touching the token.
    init(previewState: AppEntryState) {
        entryState = previewState
    }

    /// `.checking` only: asks `/api/me` whether the terms were agreed.
    /// 401/403 → logged out; offline or too slow → the cached answer, or
    /// the terms screen if there's none.
    func restoreSession() async {
        guard entryState == .checking else { return }
        let studentId = CyncAPI.accessToken.flatMap(JWT.subject)
        do {
            let profile = try await fetchProfileWithTimeout()
            TermsAgreementCache.save(profile.termsAgreed, studentId: profile.studentId)
            entryState = profile.termsAgreed ? .ready : .needsTermsAgreement
        } catch CyncAPIError.unauthorized {
            logOut()
        } catch {
            let cached = studentId.flatMap { TermsAgreementCache.value(studentId: $0) } ?? false
            entryState = cached ? .ready : .needsTermsAgreement
        }
    }

    private struct ProfileCheckTimedOut: Error {}

    private func fetchProfileWithTimeout() async throws -> UserProfile {
        try await withThrowingTaskGroup(of: UserProfile.self) { group in
            group.addTask { try await CurrentUserSession.shared.refresh() }
            group.addTask {
                try await Task.sleep(for: Self.profileCheckTimeout)
                throw ProfileCheckTimedOut()
            }
            defer { group.cancelAll() }
            guard let profile = try await group.next() else { throw ProfileCheckTimedOut() }
            return profile
        }
    }

    /// After a successful login — the response says whether the terms
    /// screen comes first.
    func logIn(termsAgreed: Bool) {
        let studentId = CyncAPI.accessToken.flatMap(JWT.subject)
        // Bookmarks are kept per account — load this one's.
        BookmarkStore.shared.switchAccount(to: studentId)
        if let studentId { TermsAgreementCache.save(termsAgreed, studentId: studentId) }
        entryState = termsAgreed ? .ready : .needsTermsAgreement
    }

    /// "모두 동의하고 시작하기": records it on the server, then the main
    /// tabs. Throws (and stays put) if the server didn't take it.
    func agreeToTerms() async throws {
        let profile = try await CyncAPI.agreeToTerms()
        CurrentUserSession.shared.update(profile)
        TermsAgreementCache.save(true, studentId: profile.studentId)
        entryState = .ready
    }

    func logOut() {
        CyncAPI.logout()
        BookmarkStore.shared.switchAccount(to: nil)
        entryState = .loggedOut
    }
}

/// Reads a JWT's claims locally — no signature check. Used to skip auto
/// login with a token the server would reject anyway, and to know which
/// account is signed in before `/api/me` answers.
enum JWT {
    static func isExpired(_ token: String) -> Bool {
        guard token.split(separator: ".").count == 3 else { return true }
        guard let exp = payload(of: token)?["exp"] as? TimeInterval else {
            // No readable `exp` — treat as non-expiring; the server still
            // answers 401 if it's actually invalid.
            return false
        }
        return Date(timeIntervalSince1970: exp) <= Date()
    }

    /// The `sub` claim — the backend puts the student id (학번) there
    /// (`JwtTokenProvider`).
    static func subject(_ token: String) -> String? {
        payload(of: token)?["sub"] as? String
    }

    private static func payload(of token: String) -> [String: Any]? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }

        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)

        guard let data = Data(base64Encoded: base64) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}
