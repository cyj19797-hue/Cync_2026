//
//  SessionStore.swift
//  Cync
//
//  App-wide login state, driving whether `CyncApp` shows `LoginView` or
//  `RootTabView`. Always starts logged out so `LoginView` shows fresh on
//  every launch, even if a token survived in the Keychain from a previous
//  session (`CyncAPI.accessToken` may still be non-nil — `isLoggedIn`
//  intentionally ignores it here).
//

import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var isLoggedIn = false

    func logIn() {
        isLoggedIn = true
    }

    func logOut() {
        CyncAPI.logout()
        isLoggedIn = false
    }
}
