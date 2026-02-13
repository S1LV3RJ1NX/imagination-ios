import SwiftUI

@main
struct ImaginationGameApp: App {
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @StateObject private var storeManager = StoreManager.shared
    
    var body: some Scene {
        WindowGroup {
            if hasSeenIntro && storeManager.isUnlocked {
                // Paid user who has seen intro — show main game
                MainTabView()
                    .preferredColorScheme(.dark)
            } else {
                // New user or unpaid user — show intro (purchase integrated in Screen 4)
                IntroductionView {
                    hasSeenIntro = true
                }
                .preferredColorScheme(.dark)
            }
        }
    }
}
