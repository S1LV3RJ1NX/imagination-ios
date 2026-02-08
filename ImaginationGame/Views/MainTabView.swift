//
//  MainTabView.swift
//  ImaginationGame
//
//  Main tab navigation: Chambers, Journal, Profile
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var gameViewModel: GameViewModel
    @StateObject private var roomSelectionViewModel = RoomSelectionViewModel()
    
    init() {
        let vm = GameViewModel()
        _gameViewModel = StateObject(wrappedValue: vm)
        
        // Load any saved progress on app launch
        vm.loadGameState()
    }
    @State private var selectedTab = 0
    @State private var currentRoomIndex: Int? = nil
    @State private var showPostGameMenu = false
    @State private var shouldOpenJournal = false
    
    // All chamber IDs in order (20 chambers)
    private let chamberIds = [
        "room_01", "room_02", "room_03", "room_05", "room_06",
        "room_07", "room_09", "room_10", "room_11", "room_13",
        "room_14", "room_15", "room_17", "room_18", "room_19",
        "room_20", "room_21", "room_22", "room_24", "room_25"
    ]
    
    var body: some View {
        ZStack {
            // Main content based on whether playing a chamber
            if showPostGameMenu {
                // All chambers complete
                if let sessionId = gameViewModel.sessionId {
                    PostGameMenuView(sessionId: sessionId) {
                        gameViewModel.startNewJourney()
                        currentRoomIndex = nil
                        showPostGameMenu = false
                        selectedTab = 0
                    }
                }
            } else if let roomIndex = currentRoomIndex {
                // Playing a chamber - full screen
                GameView(
                    roomId: chamberIds[roomIndex],
                    onRoomComplete: {
                        // Mark current room as complete and unlock next
                        let completedRoomId = chamberIds[roomIndex]
                        roomSelectionViewModel.markRoomComplete(completedRoomId)
                        print("✅ Marked \(completedRoomId) as complete")
                        
                        // Move to next room
                        currentRoomIndex = roomIndex + 1
                        if currentRoomIndex! >= chamberIds.count {
                            showPostGameMenu = true
                        }
                    },
                    onBack: {
                        print("🔙 Back button pressed")
                        currentRoomIndex = nil
                        selectedTab = 0
                    },
                    onJournalNotificationTapped: {
                        print("📖 Journal notification tapped!")
                        print("📖 Current sessionId: \(gameViewModel.sessionId ?? "nil")")
                        print("📖 Unlocked chapters: \(gameViewModel.journalUnlocked)")
                        
                        // Exit chamber view
                        withAnimation {
                            currentRoomIndex = nil
                        }
                        
                        // Switch to journal tab after a brief delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation {
                                selectedTab = 1
                            }
                        }
                    }
                )
                .environmentObject(gameViewModel)
                .transition(.move(edge: .trailing))
            } else {
                // Tab navigation
                TabView(selection: $selectedTab) {
                    #if DEBUG
                    let _ = print("📍 Current tab: \(selectedTab)")
                    #endif
                    // Chambers Tab
                    NavigationView {
                        RoomSelectionView(
                            viewModel: roomSelectionViewModel,
                            onRoomSelected: { roomId in
                                print("🗺️ Chamber selected: \(roomId)")
                                if let index = chamberIds.firstIndex(of: roomId) {
                                    currentRoomIndex = index
                                }
                            },
                            onBackToMenu: {
                                currentRoomIndex = nil
                            }
                        )
                    }
                    .tabItem {
                        Label("Chambers", systemImage: "map")
                    }
                    .tag(0)
                    .environmentObject(gameViewModel)
                    
                    // Journal Tab
                    JournalTabContent(sessionId: gameViewModel.sessionId)
                        .tabItem {
                            Label("Journal", systemImage: "book")
                        }
                        .tag(1)
                        .environmentObject(gameViewModel)
                    
                    // Profile Tab (Future: Show current traits and progress)
                    NavigationView {
                        ProfileTabContent(
                            sessionId: gameViewModel.sessionId,
                            chambersCompleted: gameViewModel.journeyStats.chambersCompleted
                        )
                    }
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                    .tag(2)
                    .environmentObject(gameViewModel)
                }
                .accentColor(.terminalGreen)
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .preferredColorScheme(.dark)
    }
}
