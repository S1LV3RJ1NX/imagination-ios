import SwiftUI

@main
struct ImaginationGameApp: App {
    var body: some Scene {
        WindowGroup {
            RoomSelectionView()
                .preferredColorScheme(.dark)
        }
    }
}
