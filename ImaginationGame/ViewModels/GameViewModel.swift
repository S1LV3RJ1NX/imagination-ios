//
//  GameViewModel.swift
//  ImaginationGame
//
//  MVVM ViewModel - Manages game state and business logic
//  Uses Combine for reactive updates
//

import Foundation
import Combine

class GameViewModel: ObservableObject {
    
    // MARK: - Published Properties (Observable by Views)
    
    @Published var messages: [NarrationMessage] = []
    @Published var sessionId: String?
    @Published var currentRoomId: String = "room_01"
    @Published var gamePhase: GamePhase = .playing
    @Published var turnCount: Int = 0
    @Published var hintsUnlocked: Int = 0
    @Published var isLoading: Bool = false
    @Published var isProcessingAction: Bool = false
    @Published var errorMessage: String?
    // Note: guardTrust/guardAlert removed - flags are now room-specific and server-side only
    
    // Streaming properties
    @Published var streamingNarration: String = ""
    @Published var currentLoadingMessage: String = "Thinking..."
    
    // MARK: - Private Properties
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var sseClient: SSEClient?
    private var loadingMessageTimer: Timer?
    private var loadingMessageIndex: Int = 0
    
    // Streaming state - simple chunk queue
    private var chunkQueue: [String] = []
    private var displayTask: Task<Void, Never>?
    
    // Varied loading messages that rotate every 1 second
    private let loadingMessages = [
        "Thinking...",
        "Analyzing...",
        "Processing...",
        "Understanding...",
        "Considering...",
        "Examining...",
        "Evaluating...",
        "Pondering...",
        "Investigating..."
    ]
    
    // MARK: - Game Actions
    
    func startNewGame(roomId: String = "room_01") {
        isLoading = true
        errorMessage = nil
        messages.removeAll()
        currentRoomId = roomId
        
        apiService.startGame(roomId: roomId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        self?.addSystemMessage("❌ Failed to start game: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.sessionId = response.sessionId
                    self?.gamePhase = response.state.phase
                    self?.turnCount = Int(response.state.turn)  // Explicit Int conversion
                    self?.hintsUnlocked = response.state.hintsUnlocked.count
                    // Flags are room-specific and not displayed in UI
                    
                    // Add opening narration (no system message)
                    self?.addNarration(response.openingNarration)
                    
                    self?.isLoading = false
                }
            )
            .store(in: &cancellables)
    }
    
    func sendAction(_ action: String) {
        guard let sessionId = sessionId else {
            errorMessage = "No active session"
            return
        }
        
        guard !action.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        // Add player action to chat
        addPlayerAction(action)
        
        isProcessingAction = true
        errorMessage = nil
        
        // Reset streaming state
        streamingNarration = ""
        chunkQueue = []
        displayTask?.cancel()
        
        // Start loading message rotation
        currentLoadingMessage = loadingMessages.randomElement() ?? "Thinking..."
        startLoadingMessageRotation()
        
        // Use streaming endpoint
        sseClient = apiService.processActionStream(
            sessionId: sessionId,
            action: action,
            onChunk: { [weak self] chunk in
                guard let self = self else { return }
                
                #if DEBUG
                print("🎨 Received chunk: '\(chunk)'")
                #endif
                
                // Stop loading rotation on first chunk
                if self.streamingNarration.isEmpty {
                    Task { @MainActor in
                        #if DEBUG
                        print("🛑 Stopping loading messages")
                        #endif
                        self.stopLoadingMessageRotation()
                    }
                }
                
                // Queue chunk for progressive display
                self.chunkQueue.append(chunk)
                #if DEBUG
                print("📦 Queued chunk, queue has \(self.chunkQueue.count) chunks")
                #endif
                
                // Start display task if not running
                if self.displayTask == nil || self.displayTask?.isCancelled == true {
                    self.startChunkDisplay()
                }
            },
            onComplete: { [weak self] response in
                guard let self = self else { return }
                
                #if DEBUG
                print("🏁 Stream complete - finalizing display")
                #endif
                
                // Stop loading rotation
                self.stopLoadingMessageRotation()
                
                // Wait for display to finish, then flush remaining chunks
                Task { @MainActor in
                    // Wait a moment for display task to process remaining chunks
                    try? await Task.sleep(for: .milliseconds(200))
                    
                    // Flush any remaining chunks
                    while !self.chunkQueue.isEmpty {
                        let chunk = self.chunkQueue.removeFirst()
                        self.streamingNarration += chunk
                    }
                    
                    #if DEBUG
                    print("✅ Finalizing with \(self.streamingNarration.count) total chars")
                    #endif
                    
                    // Add final narration to messages
                    let finalText = self.streamingNarration.isEmpty ? response.narration : self.streamingNarration
                    self.addNarration(finalText)
                    
                    // Clear streaming state
                    self.streamingNarration = ""
                    self.chunkQueue = []
                    self.displayTask?.cancel()
                    
                    // Update game state
                    self.turnCount = Int(response.turnCount)
                    self.hintsUnlocked = Int(response.hintsUnlocked)
                    self.gamePhase = GamePhase(rawValue: response.phase) ?? .playing
                    
                    // IMPORTANT: Update session_id in case backend auto-recovered from a lost session
                    // This handles backend restarts gracefully
                    if self.sessionId != response.sessionId {
                        #if DEBUG
                        print("⚠️ Session ID changed (backend auto-recovery): \(self.sessionId ?? "nil") -> \(response.sessionId)")
                        #endif
                        self.sessionId = response.sessionId
                    }
                    
                    // Add status message
                    var statusText = ""
                    
                    if response.phase == "success" {
                        statusText = "🎉 YOU WON! The door opens..."
                    } else if response.phase == "failure" {
                        statusText = "💀 GAME OVER"
                    }
                    
                    if !statusText.isEmpty {
                        self.addCompleteMessage(statusText)
                    }
                    
                    if response.phase == "success" || response.phase == "failure" {
                        self.addSystemMessage("\n🎮 Game Over! Tap 'New Game' to play again.")
                    }
                    
                    self.isProcessingAction = false
                }
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                
                #if DEBUG
                print("❌ Stream error: \(error.localizedDescription)")
                #endif
                
                self.stopLoadingMessageRotation()
                self.displayTask?.cancel()
                
                Task { @MainActor in
                    self.streamingNarration = ""
                    self.chunkQueue = []
                    self.isProcessingAction = false
                    self.errorMessage = error.localizedDescription
                    self.addSystemMessage("❌ Error: \(error.localizedDescription)")
                }
            }
        )
    }
    
    // MARK: - Chunk Display (Simple Progressive)
    
    private func startChunkDisplay() {
        // Cancel existing task if running
        displayTask?.cancel()
        
        // Start display task
        displayTask = Task { @MainActor in
            #if DEBUG
            print("🎬 Starting chunk display")
            #endif
            await displayChunksProgressively()
        }
    }
    
    private func displayChunksProgressively() async {
        var displayedCount = 0
        
        while !Task.isCancelled {
            // Check if there are chunks to display
            if chunkQueue.isEmpty {
                // Wait a bit for more chunks
                try? await Task.sleep(for: .milliseconds(50))
                
                // If still empty after waiting, we're done (or waiting for more)
                if chunkQueue.isEmpty {
                    // Check if we should continue waiting or finish
                    // (Stream might still be active)
                    continue
                }
            }
            
            // Display next chunk
            let chunk = chunkQueue.removeFirst()
            streamingNarration += chunk
            displayedCount += 1
            
            #if DEBUG
            if displayedCount % 5 == 0 {
                print("💬 Displayed \(displayedCount) chunks, total: \(streamingNarration.count) chars")
            }
            #endif
            
            // Small delay between chunks for progressive feel (50ms)
            // This creates smooth progressive display without being too slow
            try? await Task.sleep(for: .milliseconds(50))
        }
        
        #if DEBUG
        print("✅ Chunk display complete")
        #endif
    }
    
    // MARK: - Loading Message Rotation
    
    private func startLoadingMessageRotation() {
        loadingMessageIndex = 0
        loadingMessageTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.loadingMessageIndex = (self.loadingMessageIndex + 1) % self.loadingMessages.count
            self.currentLoadingMessage = self.loadingMessages[self.loadingMessageIndex]
        }
    }
    
    private func stopLoadingMessageRotation() {
        loadingMessageTimer?.invalidate()
        loadingMessageTimer = nil
    }
    
    // MARK: - Message Helpers
    
    private func addNarration(_ text: String) {
        let message = NarrationMessage(text: text, type: .narration)
        messages.append(message)
    }
    
    private func addPlayerAction(_ text: String) {
        let message = NarrationMessage(text: "> \(text)", type: .playerAction)
        messages.append(message)
    }
    
    private func addSystemMessage(_ text: String) {
        let message = NarrationMessage(text: text, type: .systemMessage)
        messages.append(message)
    }
    
    private func addCompleteMessage(_ text: String) {
        let message = NarrationMessage(text: text, type: .complete)
        messages.append(message)
    }
    
    // MARK: - Game State Queries
    
    var isGameOver: Bool {
        gamePhase != .playing
    }
    
    var canSendAction: Bool {
        sessionId != nil && !isProcessingAction && !isGameOver
    }
}
