//
//  MainGameContainer.swift
//  ImaginationGame
//
//  Main container that manages game progression through all chambers
//

import SwiftUI

struct MainGameContainer: View {
    @StateObject private var gameViewModel = GameViewModel()
    @StateObject private var roomSelectionViewModel = RoomSelectionViewModel()
    @State private var currentRoomIndex: Int? = nil // nil = show room selection
    @State private var showPostGameMenu = false
    
    // All room IDs in order (20 chambers)
    private let roomIds = [
        "room_01", "room_02", "room_03", "room_05", "room_06",
        "room_07", "room_09", "room_10", "room_11", "room_13",
        "room_14", "room_15", "room_17", "room_18", "room_19",
        "room_20", "room_21", "room_22", "room_24", "room_25"
    ]
    
    var body: some View {
        Group {
            if showPostGameMenu {
                // All chambers complete - show post-game menu
                if let sessionId = gameViewModel.sessionId {
                    PostGameMenuView(sessionId: sessionId) {
                        // Start new journey
                        gameViewModel.startNewJourney()
                        currentRoomIndex = nil
                        showPostGameMenu = false
                    }
                }
            } else if let roomIndex = currentRoomIndex {
                // Show current chamber
                GameView(
                    roomId: roomIds[roomIndex],
                    onRoomComplete: {
                        // Mark room as complete and unlock next
                        let completedRoomId = roomIds[roomIndex]
                        roomSelectionViewModel.markRoomComplete(completedRoomId)
                        
                        // Room completed - advance to next
                        currentRoomIndex = roomIndex + 1
                        
                        // Check if all chambers complete
                        if currentRoomIndex! >= roomIds.count {
                            showPostGameMenu = true
                        }
                    },
                    onBack: {
                        // Back button pressed - return to room selection
                        currentRoomIndex = nil
                    }
                )
                .environmentObject(gameViewModel)
            } else {
                // Show room selection
                RoomSelectionView(
                    viewModel: roomSelectionViewModel,
                    onRoomSelected: { roomId in
                        // Find index of selected room
                        if let index = roomIds.firstIndex(of: roomId) {
                            currentRoomIndex = index
                        }
                    }, 
                    onBackToMenu: {
                        // Return to intro/menu
                        currentRoomIndex = nil
                    }
                )
            }
        }
    }
}

struct MainGameContainer_Previews: PreviewProvider {
    static var previews: some View {
        MainGameContainer()
            .preferredColorScheme(.dark)
    }
}
