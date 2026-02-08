//
//  GameModels.swift
//  ImaginationGame
//
//  Data models matching backend API
//  Reference: backend/app/models/game.py
//

import Foundation

// MARK: - Game State

struct GameState: Codable, Identifiable {
    var id: String { sessionId } // Use sessionId as the identifier
    let sessionId: String
    let roomId: String
    let phase: GamePhase
    let turn: Int
    let flags: GameFlags
    let constraints: Constraints
    let history: [HistoryEntry]
    let hintsUnlocked: [Int]
    let hintsViewed: [Int]
    let createdAt: Date
    let lastActionAt: Date
    
    // NEW: Trait tracking and journey stats
    var traits: PlayerTraits
    var journeyStats: JourneyStats
    var keyDecisions: [KeyDecision]
    var journalUnlocked: [String]
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case roomId = "room_id"
        case phase, turn, flags, constraints, history
        case hintsUnlocked = "hints_unlocked"
        case hintsViewed = "hints_viewed"
        case createdAt = "created_at"
        case lastActionAt = "last_action_at"
        case traits
        case journeyStats = "journey_stats"
        case keyDecisions = "key_decisions"
        case journalUnlocked = "journal_unlocked"
    }
}

enum GamePhase: String, Codable {
    case playing = "active"
    case won = "success"
    case lost = "failure"
}

struct GameFlags: Codable {
    // Dynamic flags - each room has different flags defined in YAML
    // We store them as a generic dictionary since iOS doesn't use them for logic
    // (all game logic is server-side)
    private var storage: [String: AnyCodable] = [:]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dict = try container.decode([String: AnyCodable].self)
        self.storage = dict
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storage)
    }
    
    // Helper to get any flag value as string for debugging
    func getValue(_ key: String) -> String {
        if let value = storage[key] {
            return "\(value.value)"
        }
        return "N/A"
    }
}

struct Constraints: Codable {
    let violenceAllowed: Bool
    let maxTurns: Int
    
    enum CodingKeys: String, CodingKey {
        case violenceAllowed = "violence_allowed"
        case maxTurns = "max_turns"
    }
}

struct HistoryEntry: Codable {
    let turn: Int
    let action: String
    let intent: String
    let outcome: String
}

// MARK: - API Requests

struct StartGameRequest: Codable {
    let roomId: String?
    let recoveryData: RecoveryData?
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case recoveryData = "recovery_data"
    }
    
    init(roomId: String? = nil, recoveryData: RecoveryData? = nil) {
        self.roomId = roomId
        self.recoveryData = recoveryData
    }
}

struct ActionRequest: Codable {
    let sessionId: String
    let action: String
    let roomId: String?
    let recoveryData: RecoveryData?
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case action
        case roomId = "room_id"
        case recoveryData = "recovery_data"
    }
    
    init(sessionId: String, action: String, roomId: String? = nil, recoveryData: RecoveryData? = nil) {
        self.sessionId = sessionId
        self.action = action
        self.roomId = roomId
        self.recoveryData = recoveryData
    }
}

// MARK: - API Responses

struct StartGameResponse: Codable {
    let sessionId: String
    let openingNarration: String
    let state: GameState
    let journalChapterUnlocked: String?
    let asciiArt: String?
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case openingNarration = "opening_narration"
        case state
        case journalChapterUnlocked = "journal_chapter_unlocked"
        case asciiArt = "ascii_art"
    }
}

struct ActionResponse: Codable {
    let type: String
    let sessionId: String
    let turnCount: Int
    let phase: String
    let intent: String
    let confidence: Double
    let outcome: String
    let stateChanges: [String: AnyCodable]
    let narration: String
    let hintsUnlocked: Int
    let hintsAvailable: [Int]
    // Note: Removed guardTrust/guardAlert - flags are room-specific and server-side only
    
    // NEW: Trait tracking and journey stats (included on chamber completion)
    let traits: PlayerTraits?
    let journeyStats: JourneyStats?
    let journalChapterUnlocked: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case sessionId = "session_id"
        case turnCount = "turn_count"
        case phase, intent, confidence, outcome
        case stateChanges = "state_changes"
        case narration
        case hintsUnlocked = "hints_unlocked"
        case hintsAvailable = "hints_available"
        case traits
        case journeyStats = "journey_stats"
        case journalChapterUnlocked = "journal_chapter_unlocked"
    }
}

// MARK: - SSE Events (for streaming endpoint)

enum SSEEvent {
    case intent(intent: String, confidence: Double)
    case judgment(outcome: String, stateChanges: [String: Any])
    case narrationChunk(text: String)
    case complete(turnCount: Int, phase: String, hintsUnlocked: Int)
}

// MARK: - Helper for dynamic JSON

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        }
    }
}

// MARK: - UI Models

struct NarrationMessage: Identifiable {
    let id = UUID()
    let text: String
    let type: MessageType
    let timestamp: Date = Date()
    
    enum MessageType {
        case narration
        case playerAction
        case systemMessage
        case complete
    }
}
