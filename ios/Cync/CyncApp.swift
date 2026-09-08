import SwiftUI

@main
struct CyncApp: App {
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if true {
                    RootTabView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(sessionStore)
        }
    }
}
