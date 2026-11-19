import SwiftUI

@main
struct CyncApp: App {
    @StateObject private var sessionStore = SessionStore()

    init() {
        #if DEBUG
        // `[MockServer]` lines reach a `simctl launch --stdout=` file
        // right away instead of when the buffer fills.
        setvbuf(stdout, nil, _IOLBF, 0)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionStore)
        }
    }
}

/// Overlays `LaunchScreenView` on top of everything on cold launch, then
/// fades it out — so the splash is always the first thing shown. It stays
/// at least `launchScreenDuration`, and with a saved "자동 로그인" token
/// until `SessionStore.restoreSession()` knows whether the terms were
/// agreed, so the main tabs never flash before the terms screen.
///
/// Underneath, `SessionStore.entryState` picks the screen:
/// - `.loggedOut`: "1-3 앱 소개" (`AppIntroView`) until "연결하기", then
///   `LoginView`.
/// - `.needsTermsAgreement`: `TermsAgreementView` only (it's a root
///   screen, so there's no back or swipe out of it).
/// - `.ready`: `RootTabView`, plus the app-launch popup notices.
private struct RootView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    /// 설정 > 언어 설정 — its locale is injected below so every `Text(.key)`
    /// in the app switches language immediately (see AppLanguage.swift).
    @ObservedObject private var languageSettings = LanguageSettings.shared
    @State private var isShowingLaunchScreen = true
    @State private var hasSeenIntro = false
    /// App-launch popup notices (설정 > Cync 공지 with "팝업" on).
    @StateObject private var popupController = AppNoticePopupController()

    /// How long the splash stays up before fading out. Not driven by any
    /// real loading work (there isn't any at cold launch yet) — just long
    /// enough for the logo to register before the intro screen appears.
    private static let launchScreenDuration: Duration = .seconds(1.2)

    /// Splash: the minimum time, and any auto-login check.
    private var isSplashVisible: Bool {
        isShowingLaunchScreen || sessionStore.entryState == .checking
    }

    private var isShowingMainTabs: Bool {
        sessionStore.entryState == .ready && !isSplashVisible
    }

    var body: some View {
        ZStack {
            switch sessionStore.entryState {
            case .ready:
                RootTabView()
            case .needsTermsAgreement:
                TermsAgreementView()
            case .loggedOut:
                if hasSeenIntro {
                    LoginView()
                } else {
                    AppIntroView {
                        withAnimation {
                            hasSeenIntro = true
                        }
                    }
                }
            case .checking:
                // Hidden under the splash until the check is done.
                Color.appBackground.ignoresSafeArea()
            }

            // Above the whole logged-in app (tabs, pushed screens, tab bar),
            // under the splash. Never before the terms are agreed.
            if sessionStore.entryState == .ready {
                if let notice = popupController.detailNotice {
                    AppNoticePopupDetailHost(notice: notice) {
                        popupController.closeDetail()
                    }
                    .id(notice.id)
                }
                AppNoticePopupOverlay(controller: popupController)
            }

            if isSplashVisible {
                LaunchScreenView()
                    .transition(.opacity)
            }
        }
        .environment(\.locale, languageSettings.locale)
        // Popup notices load once per launch, the first time the main tabs
        // are actually visible: splash gone and logged in (right away with
        // 자동 로그인, otherwise just after logging in).
        .task(id: isShowingMainTabs) {
            if isShowingMainTabs {
                await popupController.loadIfNeeded()
            }
        }
        // The splash fades out also when it ends with the auto-login check.
        .animation(.default, value: isSplashVisible)
        .task {
            try? await Task.sleep(for: Self.launchScreenDuration)
            withAnimation {
                isShowingLaunchScreen = false
            }
        }
        .task {
            #if DEBUG
            if MockServer.skipsIntro { hasSeenIntro = true }
            #endif
            await sessionStore.restoreSession()
        }
    }
}
