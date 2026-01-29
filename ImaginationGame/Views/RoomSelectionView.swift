import SwiftUI

struct RoomSelectionView: View {
    @StateObject private var viewModel = RoomSelectionViewModel()
    @State private var showDebugMenu = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Hacker terminal theme
                Color.black.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("LOADING MISSIONS...")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(Color.green)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Text("⚠️ ERROR")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.red)
                        
                        Text(error)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("RETRY") {
                            viewModel.loadRooms()
                        }
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        // Header
                        VStack(spacing: 8) {
                            Text("SELECT MISSION")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.green)
                            
                            Text("Complete rooms to unlock new challenges")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color.green.opacity(0.6))
                        }
                        .padding(.top, 16)
                        
                        // Progress Bar
                        VStack(spacing: 8) {
                            HStack {
                                Text("PROGRESS:")
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(Color.green.opacity(0.8))
                                
                                Spacer()
                                
                                Text("\(viewModel.completedCount)/\(viewModel.totalRooms)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.green)
                                
                                Text("(\(viewModel.progressPercentage)%)")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(Color.green.opacity(0.6))
                            }
                            
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.green.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    Rectangle()
                                        .fill(Color.green)
                                        .frame(width: geometry.size.width * CGFloat(viewModel.progressPercentage) / 100, height: 8)
                                }
                                .cornerRadius(4)
                            }
                            .frame(height: 8)
                        }
                        .padding(.horizontal)
                        
                        // Debug Mode Badge
                        #if DEBUG
                        if viewModel.debugMode {
                            HStack {
                                Image(systemName: "ladybug.fill")
                                Text("DEBUG MODE: ALL ROOMS UNLOCKED")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(Color.yellow)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(8)
                            .padding(.top, 8)
                        }
                        #endif
                        
                        // Room List (current page only)
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(viewModel.currentPageRooms) { room in
                                    RoomCard(
                                        room: room,
                                        isUnlocked: viewModel.isUnlocked(room.roomId),
                                        isCompleted: viewModel.isCompleted(room.roomId),
                                        onTap: {
                                            if viewModel.isUnlocked(room.roomId) {
                                                viewModel.selectRoom(room.roomId)
                                            }
                                        }
                                    )
                                }
                                
                                // Show "Coming Soon" text only on last page
                                if viewModel.currentPage == viewModel.totalPages - 1 {
                                    VStack(spacing: 8) {
                                        Text("✨ NEW ROOMS COMING SOON ✨")
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(Color.cyan)
                                        
                                        Text("More challenging puzzles are being crafted. Stay tuned!")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(Color.cyan.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.vertical, 20)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                        }
                        
                        // Pagination Controls
                        HStack(spacing: 24) {
                            // Previous Button
                            Button(action: { viewModel.goToPreviousPage() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                    Text("PREV")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(viewModel.canGoToPreviousPage ? .green : .gray)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(viewModel.canGoToPreviousPage ? Color.green : Color.gray, lineWidth: 2)
                                )
                            }
                            .disabled(!viewModel.canGoToPreviousPage)
                            
                            // Page Indicator
                            VStack(spacing: 4) {
                                Text("PAGE \(viewModel.currentPage + 1) / \(viewModel.totalPages)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.green)
                                
                                Text("Rooms \(viewModel.currentPageStart)-\(viewModel.currentPageEnd) of \(viewModel.totalRooms)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.green.opacity(0.6))
                            }
                            
                            // Next Button
                            Button(action: { viewModel.goToNextPage() }) {
                                HStack(spacing: 8) {
                                    Text("NEXT")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(viewModel.canGoToNextPage ? .green : .gray)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(viewModel.canGoToNextPage ? Color.green : Color.gray, lineWidth: 2)
                                )
                            }
                            .disabled(!viewModel.canGoToNextPage)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showDebugMenu = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color.green)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showGame) {
                if let roomId = viewModel.selectedRoomId {
                    GameView(roomId: roomId, onRoomComplete: {
                        viewModel.markRoomComplete(roomId)
                    })
                }
            }
            .sheet(isPresented: $showDebugMenu) {
                SettingsSheet(viewModel: viewModel, isPresented: $showDebugMenu)
            }
        }
        .onAppear {
            viewModel.loadRooms()
        }
    }
}

// MARK: - Room Card
struct RoomCard: View {
    let room: RoomInfo
    let isUnlocked: Bool
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status Icon
                Image(systemName: statusIcon)
                    .font(.system(size: 24))
                    .foregroundColor(statusColor)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(room.roomName)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(isUnlocked ? Color.green : Color.gray)
                }
                
                Spacer()
                
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(Color.gray)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isUnlocked ? Color.green.opacity(0.05) : Color.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isUnlocked ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .disabled(!isUnlocked)
    }
    
    var statusIcon: String {
        if isCompleted { return "checkmark.circle.fill" }
        if isUnlocked { return "play.circle.fill" }
        return "lock.circle.fill"
    }
    
    var statusColor: Color {
        if isCompleted { return Color.green }
        if isUnlocked { return Color.yellow }
        return Color.gray
    }
    
    var difficultyColor: Color {
        switch room.difficulty {
        case "very_easy": return Color.green
        case "easy": return Color.green.opacity(0.8)
        case "medium": return Color.yellow
        case "hard": return Color.orange
        case "very_hard": return Color.red
        default: return Color.yellow
        }
    }
}

// MARK: - Settings Sheet
struct SettingsSheet: View {
    @ObservedObject var viewModel: RoomSelectionViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Terminal background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text("SETTINGS")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.green)
                    
                    Text("─────────────────")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color.green.opacity(0.5))
                }
                .padding(.top, 32)
                .padding(.bottom, 24)
                
                VStack(spacing: 16) {
                    // Debug Mode (only in DEBUG builds)
                    #if DEBUG
                    Button(action: {
                        viewModel.toggleDebugMode()
                        isPresented = false
                    }) {
                        HStack {
                            Text(viewModel.debugMode ? "🐛 DISABLE DEBUG MODE" : "🐛 ENABLE DEBUG MODE")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.black)
                            
                            Spacer()
                            
                            Text("(Test All Rooms)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color.black.opacity(0.6))
                        }
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    Text("⚠️  Debug mode unlocks all rooms for testing")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color.yellow.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Divider()
                        .background(Color.green.opacity(0.3))
                        .padding(.vertical, 8)
                    #endif
                    
                    // Reset Progress
                    Button(action: {
                        viewModel.resetProgress()
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16))
                            
                            Text("RESET PROGRESS")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    Text("⚠️  This will delete all your progress")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color.red.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Cancel Button
                Button(action: {
                    isPresented = false
                }) {
                    Text("CANCEL")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.green)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green, lineWidth: 2)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Preview
struct RoomSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        RoomSelectionView()
            .preferredColorScheme(.dark)
    }
}
