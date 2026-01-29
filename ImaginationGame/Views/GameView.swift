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
    
    @StateObject private var viewModel = GameViewModel()
    @State private var actionText: String = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showHints: Bool = false
    
    init(roomId: String, onRoomComplete: @escaping () -> Void) {
        self.roomId = roomId
        self.onRoomComplete = onRoomComplete
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
        }
        .onAppear {
            // Start game with specified room
            viewModel.startNewGame(roomId: roomId)
        }
        .onChange(of: viewModel.gamePhase) { oldValue, newValue in
            if newValue == .won {
                // Mark room as complete
                onRoomComplete()
                
                // Auto-dismiss after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dismiss()
                }
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
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("ROOMS")
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
                    label: "TURN",
                    value: "\(viewModel.turnCount)",
                    color: .terminalGreen
                )
                
                StatusBadge(
                    label: "STATUS",
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
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageView(message: message)
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
            // New game button (only show if game is over)
            if viewModel.isGameOver {
                Button(action: {
                    actionText = ""
                    viewModel.startNewGame()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("NEW GAME")
                    }
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.terminalBlack)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.terminalGreen, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                }
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
                        .foregroundColor(.terminalGreen)
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
}

// MARK: - Message View

struct MessageView: View {
    let message: NarrationMessage
    
    var body: some View {
        Text(message.text)
            .font(.system(size: message.fontSize, design: .monospaced))
            .foregroundColor(message.color)
            .multilineTextAlignment(.leading)
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
            return 16
        case .playerAction:
            return 15
        case .systemMessage:
            return 13
        case .complete:
            return 14
        }
    }
    
    var padding: CGFloat {
        switch type {
        case .complete, .systemMessage:
            return 8
        default:
            return 0
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
