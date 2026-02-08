//
//  GameView.swift
//  ImaginationGame
//
//  Main game screen with hacker terminal aesthetic
//  Dark theme, green monospace text, retro feel
//

import SwiftUI

struct GameView: View {
    let roomId: String
    let onRoomComplete: () -> Void
    let onBack: (() -> Void)?
    let onJournalNotificationTapped: (() -> Void)?
    
    @EnvironmentObject private var viewModel: GameViewModel
    @State private var actionText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var showHints: Bool = false
    
    init(roomId: String, onRoomComplete: @escaping () -> Void, onBack: (() -> Void)? = nil, onJournalNotificationTapped: (() -> Void)? = nil) {
        self.roomId = roomId
        self.onRoomComplete = onRoomComplete
        self.onBack = onBack
        self.onJournalNotificationTapped = onJournalNotificationTapped
    }
    
    var body: some View {
        ZStack {
            // Background - Pure black for terminal aesthetic
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Game area (narration + messages)
                gameAreaView
                
                // Input area
                if viewModel.sessionId != nil {
                    inputAreaView
                }
            }
            
            // Journal unlock notification
            if let chapter = viewModel.lastUnlockedChapter {
                JournalUnlockNotification(
                    chapterName: formatChapterName(chapter),
                    isShowing: $viewModel.showJournalUnlockNotification,
                    onTap: {
                        onJournalNotificationTapped?()
                    }
                )
                .zIndex(100)
            }
        }
        .onAppear {
            // Start game with specified room
            print("🎮 GameView appeared for roomId: \(roomId)")
            print("🎮 Current sessionId: \(viewModel.sessionId ?? "nil")")
            viewModel.startNewGame(roomId: roomId)
        }
        .onChange(of: viewModel.gamePhase) { oldValue, newValue in
            #if DEBUG
            print("🎮 GamePhase changed: \(oldValue.displayText) -> \(newValue.displayText)")
            #endif
            
            if newValue == .won {
                #if DEBUG
                print("🏆 Chamber WON! Marking complete and unlocking next for \(roomId)")
                #endif
                
                // Mark chamber as completed (lock from replay) and unlock next
                ChamberAttemptTracker.shared.markComplete(chamberId: roomId)
                onRoomComplete()
                
                #if DEBUG
                print("⏱️ Returning to chambers list in 3 seconds...")
                #endif
                
                // Auto-return to chambers list after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    #if DEBUG
                    print("⬅️ Returning to chambers list (chamber complete)")
                    #endif
                    onBack?()
                }
            } else if newValue == .lost {
                #if DEBUG
                print("💀 Chamber FAILED for \(roomId) - can retry")
                #endif
                
                // DON'T mark as complete - allow retry
                // DON'T call onRoomComplete() - don't unlock next
                // Traits and attempts are already tracked in iOS state
                
                // No auto-return for failed - let user retry or go back manually
            }
        }
        .sheet(isPresented: $showHints) {
            HintsView(sessionId: viewModel.sessionId ?? "")
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 8) {
            // Back button
            HStack {
                Button(action: { 
                    onBack?()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("CHAMBERS")
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.terminalGreen.opacity(0.7))
                }
                
                Spacer()
            }
            
            Text("🎮 IMAGINATION")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.terminalGreen)
                .shadow(color: .terminalGreen, radius: 10)
            
            HStack(spacing: 20) {
                StatusBadge(
                    label: "",
                    value: "Turn \(viewModel.turnCount)",
                    color: .terminalGreen
                )
                
                StatusBadge(
                    label: "",
                    value: viewModel.gamePhase.displayText,
                    color: viewModel.gamePhase.color
                )
                
                if viewModel.hintsUnlocked > 0 {
                    Button(action: { showHints = true }) {
                        StatusBadge(
                            label: "💡 HINTS",
                            value: "\(viewModel.hintsUnlocked)",
                            color: .yellow
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(Color.yellow.opacity(0.6), lineWidth: 2)
                                .scaleEffect(1.1)
                                .opacity(0.0)
                                .animation(
                                    Animation.easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: true),
                                    value: viewModel.hintsUnlocked
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .font(.system(size: 12, weight: .medium, design: .monospaced))
        }
        .padding()
        .background(Color.terminalDarkGray.opacity(0.5))
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(.terminalGreen),
            alignment: .bottom
        )
    }
    
    // MARK: - Game Area
    
    private var gameAreaView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .center, spacing: 16) {
                    // ASCII Art Display (if available) - shown as first message
                    if let asciiArt = viewModel.currentAsciiArt {
                        AsciiArtView(asciiArt: asciiArt)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                    }
                    
                    ForEach(viewModel.messages) { message in
                        MessageView(message: message)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(message.id)
                    }
                    
                    // Streaming narration (as it arrives)
                    if viewModel.isProcessingAction {
                        if viewModel.streamingNarration.isEmpty {
                            // Show loading message before first chunk
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .terminalGreen))
                                    .scaleEffect(0.8)
                                
                                Text(viewModel.currentLoadingMessage)
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(.terminalGreen.opacity(0.7))
                                    .transition(.opacity)
                                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentLoadingMessage)
                            }
                            .padding(12)
                            .background(Color.terminalGreen.opacity(0.05))
                            .cornerRadius(8)
                            .id("streaming")
                        } else {
                            // Show streaming narration with blinking cursor
                            // Using AttributedString for progressive character reveals
                            HStack(alignment: .top, spacing: 0) {
                                Text(viewModel.streamingNarration)
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundColor(.terminalGreen)
                                    .lineSpacing(4)
                                
                                // Blinking cursor
                                Text("▊")
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundColor(.cyan)
                                    .opacity(0.8)
                            }
                            .padding(12)
                            .background(Color.terminalGreen.opacity(0.05))
                            .cornerRadius(8)
                            .id("streaming")
                        }
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { oldValue, newValue in
                // Auto-scroll to bottom when new message arrives
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.streamingNarration) {
                // Auto-scroll while streaming
                if viewModel.isProcessingAction && !viewModel.streamingNarration.isEmpty {
                    // Scroll to bottom (use a stable ID)
                    withAnimation {
                        proxy.scrollTo("streaming", anchor: .bottom)
                    }
                }
            }
        }
        .background(Color.terminalBlack)
    }
    
    // MARK: - Input Area
    
    private var inputAreaView: some View {
        VStack(spacing: 12) {
            // Success message (auto-advancing)
            if viewModel.gamePhase == .won {
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("CHAMBER COMPLETE!")
                    }
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        .scaleEffect(0.8)
                }
                .padding()
                .background(Color.cyan.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // Failure message with retry button
            if viewModel.gamePhase == .lost {
                VStack(spacing: 12) {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("CHAMBER FAILED")
                        }
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                        
                        Text("Your choices revealed much about you.")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Retry button
                    Button(action: {
                        actionText = ""
                        viewModel.startNewGame(roomId: roomId)
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("RETRY CHAMBER")
                        }
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // Input field with scrolling text
            HStack(alignment: .center, spacing: 12) {
                ZStack(alignment: .leading) {
                    // Placeholder text
                    if actionText.isEmpty {
                        Text("Enter your action...")
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(.terminalGreen.opacity(0.5))
                            .padding(.horizontal, 16)
                    }
                    
                    TextEditor(text: $actionText)
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.cyan)  // Blue text for user input!
                        .scrollContentBackground(.hidden)
                        .background(Color.terminalBlack)
                        .frame(height: 44)
                        .padding(.horizontal, 8)
                        .focused($isInputFocused)
                        .disabled(!viewModel.canSendAction)
                }
                .background(Color.terminalBlack)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isInputFocused ? Color.cyan : Color.terminalGreen.opacity(0.6), lineWidth: 1)
                )
                
                Button(action: sendAction) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(viewModel.canSendAction && !actionText.isEmpty ? .terminalGreen : .gray)
                }
                .disabled(!viewModel.canSendAction || actionText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.terminalBlack)
    }
    
    // MARK: - Actions
    
    private func sendAction() {
        let action = actionText.trimmingCharacters(in: .whitespaces)
        guard !action.isEmpty else { return }
        
        viewModel.sendAction(action)
        actionText = ""
    }
    
    // MARK: - Helpers
    
    private func formatChapterName(_ chapterId: String) -> String {
        if chapterId == "prologue" {
            return "Prologue"
        } else if chapterId == "epilogue" {
            return "Epilogue"
        } else {
            // Extract number from "chapter_01", "chapter_02", etc.
            let numberString = chapterId.replacingOccurrences(of: "chapter_", with: "")
            if let number = Int(numberString) {
                return "Chapter \(number)"
            }
            return chapterId.capitalized
        }
    }
}

// MARK: - ASCII Art View

struct AsciiArtView: View {
    let asciiArt: String
    @State private var opacity = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            Text(asciiArt)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.cyan.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(1)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
        .overlay(
            VStack {
                Rectangle()
                    .fill(Color.cyan.opacity(0.5))
                    .frame(height: 1)
                Spacer()
                Rectangle()
                    .fill(Color.cyan.opacity(0.5))
                    .frame(height: 1)
            }
        )
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - Message View

struct MessageView: View {
    let message: NarrationMessage
    
    var body: some View {
        Text(message.text)
            .font(.system(size: message.fontSize, design: .monospaced))
            .foregroundColor(message.color)
            .multilineTextAlignment(.leading)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
            .padding(message.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(message.backgroundColor)
            .cornerRadius(4)
            .overlay(
                message.hasBorder ?
                RoundedRectangle(cornerRadius: 4)
                    .stroke(message.borderColor, lineWidth: message.borderWidth)
                : nil
            )
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundColor(color.opacity(0.7))
            Text(value)
                .foregroundColor(color)
                .fontWeight(.bold)
        }
    }
}

// MARK: - Extensions

extension NarrationMessage {
    var color: Color {
        switch type {
        case .narration:
            return .terminalGreen
        case .playerAction:
            return .cyan
        case .systemMessage:
            return .gray
        case .complete:
            return .yellow
        }
    }
    
    var fontSize: CGFloat {
        switch type {
        case .narration:
            return 15
        case .playerAction:
            return 14
        case .systemMessage:
            return 13
        case .complete:
            return 14
        }
    }
    
    var padding: CGFloat {
        switch type {
        case .narration:
            return 12
        case .playerAction:
            return 10
        case .complete, .systemMessage:
            return 8
        }
    }
    
    var backgroundColor: Color {
        switch type {
        case .complete:
            return Color.yellow.opacity(0.1)
        case .systemMessage:
            return Color.clear
        default:
            return Color.clear
        }
    }
    
    var hasBorder: Bool {
        switch type {
        case .complete:
            return true
        default:
            return false
        }
    }
    
    var borderColor: Color {
        return .yellow.opacity(0.5)
    }
    
    var borderWidth: CGFloat {
        return 1
    }
}

extension GamePhase {
    var displayText: String {
        switch self {
        case .playing:
            return "PLAYING"
        case .won:
            return "WON"
        case .lost:
            return "LOST"
        }
    }
    
    var color: Color {
        switch self {
        case .playing:
            return .terminalGreen
        case .won:
            return .yellow
        case .lost:
            return .red
        }
    }
}

// MARK: - Color Theme

extension Color {
    static let terminalGreen = Color(red: 0, green: 1, blue: 0)
    static let terminalBlack = Color(red: 0.04, green: 0.04, blue: 0.04)
    static let terminalDarkGray = Color(red: 0.1, green: 0.1, blue: 0.1)
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dotCount = 0
    
    var body: some View {
        HStack(spacing: 4) {
            Text("▋")
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.terminalGreen)
            
            Text("Thinking" + String(repeating: ".", count: dotCount))
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.terminalGreen.opacity(0.7))
        }
        .padding(.vertical, 8)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}

// MARK: - Preview

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(roomId: "room_01", onRoomComplete: {})
            .preferredColorScheme(.dark)
    }
}
