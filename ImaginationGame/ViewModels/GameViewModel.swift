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
    
    // NEW: Trait tracking and journey progress
    @Published var currentTraits: PlayerTraits = PlayerTraits()
    @Published var journeyStats: JourneyStats = JourneyStats()
    @Published var keyDecisions: [KeyDecision] = []
    @Published var journalUnlocked: [String] = []
    @Published var lastUnlockedChapter: String?
    
    // Current chamber tracking (for recovery)
    @Published var hintsUsedThisChamber: Int = 0
    @Published var attemptsThisChamber: Int = 0
    @Published var actionsThisChamber: Int = 0
    
    // Chamber visual
    @Published var currentAsciiArt: String?
    
    // Notification
    @Published var showJournalUnlockNotification: Bool = false
    
    // MARK: - Private Properties
    
    private let apiService = APIService.shared
    private let journalCache = JournalCache.shared
    private let attemptTracker = ChamberAttemptTracker.shared
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
        
        // DON'T reset journey tracking - iOS is source of truth!
        // Progress is preserved across chambers and backend restarts
        
        // Check if this is a retry attempt (has previous attempt data)
        if let previousAttempt = attemptTracker.getAttempt(chamberId: roomId) {
            #if DEBUG
            print("🔄 Retry attempt #\(previousAttempt.attemptCount + 1) for \(roomId)")
            print("   Previous: \(previousAttempt.hintsUsedTotal) hints, \(previousAttempt.wrongAttemptsTotal) wrong attempts")
            #endif
            
            // Keep cumulative tracking from previous attempts
            hintsUsedThisChamber = previousAttempt.hintsUsedTotal
            attemptsThisChamber = previousAttempt.wrongAttemptsTotal
            actionsThisChamber = previousAttempt.actionsTotal
        } else {
            // First attempt at this chamber
            hintsUsedThisChamber = 0
            attemptsThisChamber = 0
            actionsThisChamber = 0
        }
        
        // Build recovery data from stored state
        // Only send if there's actual progress (not first time)
        let hasProgress = !journalUnlocked.isEmpty || journeyStats.chambersCompleted > 0
        let recovery = hasProgress ? buildRecoveryData() : nil
        
        #if DEBUG
        if hasProgress {
            print("🔄 Starting chamber with recovery data:")
            print("  - Chambers completed: \(journeyStats.chambersCompleted)")
            print("  - Journal unlocked: \(journalUnlocked.count)")
            print("  - Traits: logical=\(currentTraits.logicalThinking), creative=\(currentTraits.creativeThinking)")
        } else {
            print("🆕 Starting first chamber (no recovery data)")
        }
        #endif
        
        apiService.startGame(roomId: roomId, recoveryData: recovery)
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
                    
                    // Load traits and stats from backend response
                    self?.currentTraits = response.state.traits
                    self?.journeyStats = response.state.journeyStats
                    self?.keyDecisions = response.state.keyDecisions
                    self?.journalUnlocked = response.state.journalUnlocked
                    
                    // Check for journal unlock
                    if let chapter = response.journalChapterUnlocked {
                        self?.lastUnlockedChapter = chapter
                        self?.showJournalUnlockNotification = true
                        
                        // Cache the unlock status immediately
                        self?.journalCache.unlockChapter(chapterId: chapter)
                    }
                    
                    // Load ASCII art
                    self?.currentAsciiArt = response.asciiArt
                    
                    // Add opening narration (no system message)
                    self?.addNarration(response.openingNarration)
                    
                    // Persist state
                    self?.saveGameState()
                    
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
            roomId: currentRoomId,
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
                    
                    // Track chamber actions
                    self.actionsThisChamber += 1
                    if response.outcome.lowercased().contains("incorrect") || response.outcome.lowercased().contains("wrong") {
                        self.attemptsThisChamber += 1
                    }
                    
                    // IMPORTANT: Update session_id in case backend auto-recovered from a lost session
                    // This handles backend restarts gracefully
                    if self.sessionId != response.sessionId {
                        #if DEBUG
                        print("⚠️ Session ID changed (backend auto-recovery): \(self.sessionId ?? "nil") -> \(response.sessionId)")
                        #endif
                        self.sessionId = response.sessionId
                    }
                    
                    // Update traits and stats on chamber completion
                    if let traits = response.traits {
                        self.currentTraits = traits
                        #if DEBUG
                        print("✨ Traits updated after chamber completion")
                        #endif
                    }
                    
                    if let stats = response.journeyStats {
                        self.journeyStats = stats
                        #if DEBUG
                        print("📊 Journey stats updated: \(stats.chambersCompleted) chambers completed")
                        #endif
                    }
                    
                    // Check for new journal chapter
                    if let chapter = response.journalChapterUnlocked {
                        if !self.journalUnlocked.contains(chapter) {
                            self.journalUnlocked.append(chapter)
                            self.lastUnlockedChapter = chapter
                            self.showJournalUnlockNotification = true
                            
                            // Cache the unlock status immediately
                            self.journalCache.unlockChapter(chapterId: chapter)
                        }
                    }
                    
                    // Save updated state
                    self.saveGameState()
                    
                    // Add status message
                    var statusText = ""
                    
                    if response.phase == "success" {
                        statusText = "🎉 CHAMBER COMPLETE! The door opens..."
                        
                        // Update final attempt stats
                        self.attemptTracker.updateAttempt(
                            chamberId: self.currentRoomId,
                            hintsUsed: self.hintsUsedThisChamber,
                            actions: self.actionsThisChamber,
                            wrongAttempts: self.attemptsThisChamber
                        )
                        
                        // Mark as completed (lock from replay)
                        self.attemptTracker.markComplete(chamberId: self.currentRoomId)
                        
                        // Reset chamber tracking on success
                        self.hintsUsedThisChamber = 0
                        self.attemptsThisChamber = 0
                        self.actionsThisChamber = 0
                    } else if response.phase == "failure" {
                        statusText = "💀 CHAMBER FAILED - Your choices revealed much about you."
                        
                        // Update attempt stats (will be used on retry)
                        self.attemptTracker.updateAttempt(
                            chamberId: self.currentRoomId,
                            hintsUsed: self.hintsUsedThisChamber,
                            actions: self.actionsThisChamber,
                            wrongAttempts: self.attemptsThisChamber
                        )
                    }
                    
                    if !statusText.isEmpty {
                        self.addCompleteMessage(statusText)
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
        loadingMessageTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
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
    
    // MARK: - Persistence
    
    private func saveGameState() {
        guard let sessionId = sessionId else { return }
        
        let encoder = JSONEncoder()
        
        // Save session ID
        UserDefaults.standard.set(sessionId, forKey: "lastSessionId")
        UserDefaults.standard.set(currentRoomId, forKey: "lastRoomId")
        
        // Save traits
        if let traitsData = try? encoder.encode(currentTraits) {
            UserDefaults.standard.set(traitsData, forKey: "playerTraits")
        }
        
        // Save journey stats
        if let statsData = try? encoder.encode(journeyStats) {
            UserDefaults.standard.set(statsData, forKey: "journeyStats")
        }
        
        // Save key decisions
        if let decisionsData = try? encoder.encode(keyDecisions) {
            UserDefaults.standard.set(decisionsData, forKey: "keyDecisions")
        }
        
        // Save journal unlocked
        if let journalData = try? encoder.encode(journalUnlocked) {
            UserDefaults.standard.set(journalData, forKey: "journalUnlocked")
        }
        
        // Save chamber tracking
        UserDefaults.standard.set(hintsUsedThisChamber, forKey: "hintsUsedThisChamber")
        UserDefaults.standard.set(attemptsThisChamber, forKey: "attemptsThisChamber")
        UserDefaults.standard.set(actionsThisChamber, forKey: "actionsThisChamber")
        
        #if DEBUG
        print("💾 Game state persisted")
        #endif
    }
    
    func loadGameState() {
        let decoder = JSONDecoder()
        
        // Load session ID
        sessionId = UserDefaults.standard.string(forKey: "lastSessionId")
        currentRoomId = UserDefaults.standard.string(forKey: "lastRoomId") ?? "room_01"
        
        // Load traits
        if let traitsData = UserDefaults.standard.data(forKey: "playerTraits"),
           let traits = try? decoder.decode(PlayerTraits.self, from: traitsData) {
            currentTraits = traits
        }
        
        // Load journey stats
        if let statsData = UserDefaults.standard.data(forKey: "journeyStats"),
           let stats = try? decoder.decode(JourneyStats.self, from: statsData) {
            journeyStats = stats
        }
        
        // Load key decisions
        if let decisionsData = UserDefaults.standard.data(forKey: "keyDecisions"),
           let decisions = try? decoder.decode([KeyDecision].self, from: decisionsData) {
            keyDecisions = decisions
        }
        
        // Load journal unlocked
        if let journalData = UserDefaults.standard.data(forKey: "journalUnlocked"),
           let journal = try? decoder.decode([String].self, from: journalData) {
            journalUnlocked = journal
        }
        
        // Load chamber tracking
        hintsUsedThisChamber = UserDefaults.standard.integer(forKey: "hintsUsedThisChamber")
        attemptsThisChamber = UserDefaults.standard.integer(forKey: "attemptsThisChamber")
        actionsThisChamber = UserDefaults.standard.integer(forKey: "actionsThisChamber")
        
        #if DEBUG
        print("📥 Game state loaded from persistence")
        #endif
    }
    
    func clearGameState() {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "lastSessionId")
        UserDefaults.standard.removeObject(forKey: "lastRoomId")
        UserDefaults.standard.removeObject(forKey: "playerTraits")
        UserDefaults.standard.removeObject(forKey: "journeyStats")
        UserDefaults.standard.removeObject(forKey: "keyDecisions")
        UserDefaults.standard.removeObject(forKey: "journalUnlocked")
        UserDefaults.standard.removeObject(forKey: "hintsUsedThisChamber")
        UserDefaults.standard.removeObject(forKey: "attemptsThisChamber")
        UserDefaults.standard.removeObject(forKey: "actionsThisChamber")
        
        // Clear caches
        journalCache.clearCache()
        attemptTracker.clearAll()
        RoomsCache.shared.clearCache()
        
        // Reset in-memory state to defaults
        sessionId = nil
        currentRoomId = "room_01"
        gamePhase = .playing
        turnCount = 0
        hintsUnlocked = 0
        messages.removeAll()
        currentTraits = PlayerTraits()
        journeyStats = JourneyStats()
        keyDecisions.removeAll()
        journalUnlocked.removeAll()
        lastUnlockedChapter = nil
        hintsUsedThisChamber = 0
        attemptsThisChamber = 0
        actionsThisChamber = 0
        currentAsciiArt = nil
        errorMessage = nil
        
        #if DEBUG
        print("🗑️ Game state cleared (storage + in-memory state)")
        #endif
    }
    
    // MARK: - Recovery Data
    
    /// Build recovery data for session restoration
    func buildRecoveryData() -> RecoveryData {
        // Convert PlayerTraits to dictionary
        let traitsDict: [String: Double] = [
            "logical_thinking": currentTraits.logicalThinking,
            "creative_thinking": currentTraits.creativeThinking,
            "observation": currentTraits.observation,
            "memory": currentTraits.memory,
            "empathy": currentTraits.empathy,
            "courage": currentTraits.courage,
            "patience": currentTraits.patience,
            "trust": currentTraits.trust,
            "impulsivity": currentTraits.impulsivity,
            "pragmatism": currentTraits.pragmatism,
            "curiosity": currentTraits.curiosity,
            "integrity": currentTraits.integrity
        ]
        
        // Convert JourneyStats to dictionary
        let statsDict: [String: Int] = [
            "chambers_completed": journeyStats.chambersCompleted,
            "hints_used": journeyStats.hintsUsed,
            "wrong_attempts": journeyStats.wrongAttempts,
            "total_actions": journeyStats.totalActions,
            "total_time_seconds": journeyStats.totalTimeSeconds
        ]
        
        // Convert KeyDecisions to array of dictionaries
        let decisionsArray: [[String: String]]? = keyDecisions.isEmpty ? nil : keyDecisions.map { decision in
            [
                "chamber_id": decision.chamberId,
                "decision_type": decision.decisionType,
                "decision_value": decision.decisionValue,
                "timestamp": ISO8601DateFormatter().string(from: decision.timestamp)
            ]
        }
        
        // Get completed chambers from ChamberAttemptTracker
        let completedChamberIds = attemptTracker.getCompletedChamberIds()
        
        return RecoveryData(
            traits: traitsDict,
            journeyStats: statsDict,
            keyDecisions: decisionsArray,
            journalUnlocked: journalUnlocked.isEmpty ? nil : journalUnlocked,
            chambersCompleted: completedChamberIds.isEmpty ? nil : completedChamberIds,
            hintsUsedThisChamber: hintsUsedThisChamber,
            attemptsThisChamber: attemptsThisChamber,
            actionsThisChamber: actionsThisChamber
        )
    }
    
    // MARK: - New Journey
    
    /// Reset all game progress and start fresh
    func startNewJourney(roomId: String = "room_01") {
        // Clear all persisted data
        clearGameState()
        
        // Reset in-memory state
        messages.removeAll()
        sessionId = nil
        currentRoomId = roomId
        gamePhase = .playing
        turnCount = 0
        hintsUnlocked = 0
        streamingNarration = ""
        currentTraits = PlayerTraits()
        journeyStats = JourneyStats()
        keyDecisions = []
        journalUnlocked = []
        lastUnlockedChapter = nil
        hintsUsedThisChamber = 0
        attemptsThisChamber = 0
        actionsThisChamber = 0
        currentAsciiArt = nil
        errorMessage = nil
        
        // Start new game
        startNewGame(roomId: roomId)
        
        #if DEBUG
        print("🔄 Started new journey")
        #endif
    }
}
