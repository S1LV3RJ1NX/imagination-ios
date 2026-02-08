import SwiftUI

struct RoomSelectionView: View {
    @ObservedObject var viewModel: RoomSelectionViewModel
    let onRoomSelected: (String) -> Void
    let onBackToMenu: () -> Void
    
    @State private var showDebugMenu = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Hacker terminal theme
                Color.black.ignoresSafeArea(edges: .all)
                
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
                    VStack(spacing: 12) {
                        // Header
                        VStack(spacing: 4) {
                            Text("SELECT CHAMBER")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.green)
                            
                            Text("Complete chambers to unlock new challenges")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color.green.opacity(0.6))
                        }
                        .padding(.top, 4)
                        
                        // Progress Bar
                        VStack(spacing: 6) {
                            HStack {
                                Text("PROGRESS:")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(Color.green.opacity(0.8))
                                
                                Spacer()
                                
                                Text("\(viewModel.completedCount)/\(viewModel.totalRooms)")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.green)
                                
                                Text("(\(viewModel.progressPercentage)%)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Color.green.opacity(0.6))
                            }
                            
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.green.opacity(0.2))
                                        .frame(height: 6)
                                    
                                    Rectangle()
                                        .fill(Color.green)
                                        .frame(width: geometry.size.width * CGFloat(viewModel.progressPercentage) / 100, height: 6)
                                }
                                .cornerRadius(3)
                            }
                            .frame(height: 6)
                        }
                        .padding(.horizontal, 12)
                        
                        // Secret Code Badge (works in production)
                        if viewModel.allRoomsUnlocked {
                            HStack {
                                Image(systemName: "key.fill")
                                Text("ALL CHAMBERS UNLOCKED")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(Color.cyan)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.cyan.opacity(0.2))
                            .cornerRadius(8)
                            .padding(.top, 8)
                        }
                        
                        // Room List (current page only)
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(viewModel.currentPageRooms) { room in
                                    RoomCard(
                                        room: room,
                                        isUnlocked: viewModel.isUnlocked(room.roomId),
                                        isCompleted: viewModel.isCompleted(room.roomId),
                                        onTap: {
                                            // Don't allow replaying completed chambers
                                            if viewModel.isCompleted(room.roomId) {
                                                print("⚠️ Chamber \(room.roomId) already completed, cannot replay")
                                                return
                                            }
                                            
                                            if viewModel.isUnlocked(room.roomId) {
                                                onRoomSelected(room.roomId)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 6)
                            .padding(.bottom, 12)
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
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                    .padding(.top, 0)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showDebugMenu = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color.green)
                            .font(.system(size: 18))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showDebugMenu) {
                SettingsSheet(viewModel: viewModel, isPresented: $showDebugMenu)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
                        .foregroundColor(textColor)
                }
                
                Spacer()
                
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(Color.gray)
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 16)
            .frame(minHeight: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .disabled(!isUnlocked || isCompleted)  // Disable if locked OR completed
    }
    
    var statusIcon: String {
        if isCompleted { return "checkmark.circle.fill" }
        if isUnlocked { return "play.circle.fill" }
        return "lock.circle.fill"
    }
    
    var statusColor: Color {
        if isCompleted { return Color.gray.opacity(0.6) }  // Muted for completed
        if isUnlocked { return Color.cyan }  // Bright cyan for playable
        return Color.gray.opacity(0.4)  // Very muted for locked
    }
    
    var textColor: Color {
        if isCompleted { return Color.gray }  // Gray text for completed
        if isUnlocked { return Color.green }  // Green for current/playable
        return Color.gray.opacity(0.5)  // Muted for locked
    }
    
    var backgroundColor: Color {
        if isCompleted { return Color.gray.opacity(0.05) }  // Subtle gray for completed
        if isUnlocked { return Color.green.opacity(0.08) }  // Bright green tint for playable
        return Color.black  // Black for locked
    }
    
    var borderColor: Color {
        if isCompleted { return Color.gray.opacity(0.3) }  // Gray border for completed
        if isUnlocked { return Color.green }  // GREEN BORDER only for current/playable
        return Color.gray.opacity(0.2)  // Subtle gray for locked
    }
    
    var borderWidth: CGFloat {
        if isCompleted { return 1 }  // Thin border for completed
        if isUnlocked { return 2.5 }  // Thick GREEN border for playable (stands out!)
        return 1  // Thin for locked
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
    @EnvironmentObject var gameViewModel: GameViewModel
    @Binding var isPresented: Bool
    @State private var secretCodeInput: String = ""
    @State private var showSecretCodeError: Bool = false
    @State private var showSecretCodeSuccess: Bool = false
    
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
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Secret Code Section (Works in production)
                        VStack(spacing: 12) {
                            Text("🔑 UNLOCK ALL ROOMS")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.cyan)
                            
                            if viewModel.allRoomsUnlocked {
                                // Already unlocked - show disable button
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("ALL ROOMS UNLOCKED")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    }
                                    .foregroundColor(Color.green)
                                    .padding(.vertical, 8)
                                    
                                    Button(action: {
                                        viewModel.disableSecretCodeMode()
                                        isPresented = false
                                    }) {
                                        Text("DISABLE & RESET")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(Color.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color.red.opacity(0.7))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            } else {
                                // Show input field
                                VStack(spacing: 12) {
                                    
                                    HStack {
                                        TextField("Enter secret code", text: $secretCodeInput)
                                            .font(.system(size: 14, design: .monospaced))
                                            .foregroundColor(Color.green)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .padding(12)
                                            .background(Color.green.opacity(0.1))
                                            .cornerRadius(8)
                                            .autocapitalization(.allCharacters)
                                            .disableAutocorrection(true)
                                            .onChange(of: secretCodeInput) {
                                                showSecretCodeError = false
                                                showSecretCodeSuccess = false
                                            }
                                    }
                                    
                                    Button(action: {
                                        if viewModel.verifySecretCode(secretCodeInput) {
                                            showSecretCodeSuccess = true
                                            showSecretCodeError = false
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                isPresented = false
                                            }
                                        } else {
                                            showSecretCodeError = true
                                            showSecretCodeSuccess = false
                                        }
                                    }) {
                                        Text("UNLOCK")
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(Color.black)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.cyan)
                                            .cornerRadius(8)
                                    }
                                    
                                    if showSecretCodeError {
                                        Text("❌ Invalid code")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(Color.red)
                                    }
                                    
                                    if showSecretCodeSuccess {
                                        Text("✅ All rooms unlocked!")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(Color.green)
                                    }
                                }
                                .padding()
                                .background(Color.cyan.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Divider()
                            .background(Color.green.opacity(0.3))
                            .padding(.vertical, 8)
                        
                        VStack(spacing: 16) {
                            // Reset Progress
                            Button(action: {
                                viewModel.resetProgress()
                                gameViewModel.clearGameState()
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
                        } // End of inner VStack
                    } // End of outer VStack
                } // End of ScrollView
                
                Spacer()
                
                // Cancel Button
                Button(action: {
                    isPresented = false
                }) {
                    Text("CLOSE")
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
        RoomSelectionView(
            viewModel: RoomSelectionViewModel(),
            onRoomSelected: { roomId in
                print("Selected room: \(roomId)")
            },
            onBackToMenu: {
                print("Back to menu")
            }
        )
        .environmentObject(GameViewModel())
        .preferredColorScheme(.dark)
    }
}
