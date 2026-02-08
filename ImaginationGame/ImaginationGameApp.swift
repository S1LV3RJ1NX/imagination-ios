import SwiftUI

@main
struct ImaginationGameApp: App {
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    
    var body: some Scene {
        WindowGroup {
            if hasSeenIntro {
                // User has seen intro - show main tabs
                MainTabView()
                    .preferredColorScheme(.dark)
            } else {
                // First time user - show intro
                IntroductionView {
                    hasSeenIntro = true
                }
                .preferredColorScheme(.dark)
            }
        }
    }
}
