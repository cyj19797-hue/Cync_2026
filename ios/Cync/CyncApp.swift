import SwiftUI

@main
struct CyncApp: App {
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionStore)
        }
    }
}

/// Overlays `LaunchScreenView` on top of `AppIntroView`/`TermsAgreementView`/
/// `LoginView`/`RootTabView` for a beat on cold launch, then fades it out —
/// so the splash is always the first thing shown. Underneath it: "1-3 앱
/// 소개" (`AppIntroView`) until "연결하기", then "1-4 이용약관 동의"
/// (`TermsAgreementView`) until "세종대학교 계정으로 시작하기", then
/// `LoginView` — matching Figma's own 1-3 → 1-4 → 1-5 screen numbering.
private struct RootView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var isShowingLaunchScreen = true
    @State private var hasSeenIntro = false
    @State private var hasAgreedToTerms = false

    /// How long the splash stays up before fading out. Not driven by any
    /// real loading work (there isn't any at cold launch yet) — just long
    /// enough for the logo to register before the intro screen appears.
    private static let launchScreenDuration: Duration = .seconds(1.2)

    var body: some View {
        ZStack {
            if sessionStore.isLoggedIn {
                RootTabView()
            } else if hasAgreedToTerms {
                LoginView()
            } else if hasSeenIntro {
                TermsAgreementView {
                    withAnimation {
                        hasAgreedToTerms = true
                    }
                }
            } else {
                AppIntroView {
                    withAnimation {
                        hasSeenIntro = true
                    }
                }
            }

            if isShowingLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: Self.launchScreenDuration)
            withAnimation {
                isShowingLaunchScreen = false
            }
        }
    }
}
