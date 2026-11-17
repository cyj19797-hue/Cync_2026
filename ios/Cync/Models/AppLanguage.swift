//
//  AppLanguage.swift
//  Cync
//
//  In-app language setting (설정 > 언어 설정). The default, `.system`,
//  follows the device / iOS per-app language — that's what a first launch
//  gets. Picking 한국어 or English overrides it and takes effect right away,
//  without restarting the app.
//
//  How the switch reaches every string (checked on device — overriding
//  `Bundle.main`, the usual trick, does NOT work with String Catalogs):
//    - `Text(.someKey)` resolves against the SwiftUI environment's locale,
//      so `RootView` injects `.environment(\.locale, …)` at the top.
//    - Strings built in code must go through `String(appLocalized:)`
//      below instead of `String(localized:)` — it stamps the chosen locale
//      onto the resource before resolving it.
//    - Date/number formatting in code uses `AppLanguage.currentLocale`
//      instead of `Locale.current`.
//  `RootTabView` also re-creates its tab content when the language changes
//  (`.id`), so text computed once and kept in view state is rebuilt too.
//
//  The choice is also written to `AppleLanguages` (the same per-app
//  language key iOS Settings uses), so after a relaunch even system-drawn
//  pieces — keyboard, share sheets, built-in button titles — match it.
//  Those pieces can't change mid-session; only the app's own text does.
//

import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case korean = "ko"
    case english = "en"

    var id: String { rawValue }

    private static let storageKey = "appLanguage"

    /// The saved choice; `.system` until the user picks one.
    static var saved: AppLanguage {
        UserDefaults.standard.string(forKey: storageKey).flatMap(AppLanguage.init) ?? .system
    }

    /// The locale all app text and formatting should use right now.
    static var currentLocale: Locale {
        saved.locale
    }

    var locale: Locale {
        switch self {
        case .system:
            return .current
        case .korean:
            return Locale(languageCode: .korean, languageRegion: Locale.current.region)
        case .english:
            return Locale(languageCode: .english, languageRegion: Locale.current.region)
        }
    }

    fileprivate func persist() {
        let defaults = UserDefaults.standard
        if self == .system {
            defaults.removeObject(forKey: Self.storageKey)
            defaults.removeObject(forKey: "AppleLanguages")
        } else {
            defaults.set(rawValue, forKey: Self.storageKey)
            defaults.set([rawValue], forKey: "AppleLanguages")
        }
    }
}

/// Observable wrapper so the view tree re-renders when the language
/// changes. Read the value through `AppLanguage.saved`/`.currentLocale`
/// from non-view code.
@MainActor
final class LanguageSettings: ObservableObject {
    static let shared = LanguageSettings()

    @Published private(set) var language: AppLanguage = AppLanguage.saved

    private init() {}

    var locale: Locale { language.locale }

    func select(_ language: AppLanguage) {
        guard language != self.language else { return }
        language.persist()
        self.language = language
    }
}

extension String {
    /// `String(localized:)` in the app's chosen language — use this for any
    /// user-facing string built in code (placeholders, error messages,
    /// accessibility text). See this file's header for why.
    init(appLocalized resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = AppLanguage.currentLocale
        self.init(localized: resource)
    }
}
