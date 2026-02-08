//
//  JourneyStats.swift
//  ImaginationGame
//
//  Journey statistics tracked throughout gameplay
//  Matches backend: backend/app/models/game.py
//

import Foundation

/// Statistics about the player's journey
/// Matches backend: backend/app/models/game.py JourneyStats
struct JourneyStats: Codable, Equatable {
    var chambersCompleted: Int
    var hintsUsed: Int
    var wrongAttempts: Int
    var totalActions: Int
    var totalTimeSeconds: Int
    var hintsPerChamber: [Int]
    var attemptsPerChamber: [Int]
    var actionsPerChamber: [Int]
    var timePerChamber: [Int]
    
    enum CodingKeys: String, CodingKey {
        case chambersCompleted = "chambers_completed"
        case hintsUsed = "hints_used"
        case wrongAttempts = "wrong_attempts"
        case totalActions = "total_actions"
        case totalTimeSeconds = "total_time_seconds"
        case hintsPerChamber = "hints_per_chamber"
        case attemptsPerChamber = "attempts_per_chamber"
        case actionsPerChamber = "actions_per_chamber"
        case timePerChamber = "time_per_chamber"
    }
    
    /// Initialize with default empty stats
    init() {
        self.chambersCompleted = 0
        self.hintsUsed = 0
        self.wrongAttempts = 0
        self.totalActions = 0
        self.totalTimeSeconds = 0
        self.hintsPerChamber = []
        self.attemptsPerChamber = []
        self.actionsPerChamber = []
        self.timePerChamber = []
    }
    
    /// Human-readable total time
    var formattedTotalTime: String {
        let hours = totalTimeSeconds / 3600
        let minutes = (totalTimeSeconds % 3600) / 60
        let seconds = totalTimeSeconds % 60
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    /// Average time per chamber
    var averageTimePerChamber: Double {
        guard chambersCompleted > 0 else { return 0.0 }
        return Double(totalTimeSeconds) / Double(chambersCompleted)
    }
    
    /// Average hints per chamber
    var averageHintsPerChamber: Double {
        guard chambersCompleted > 0 else { return 0.0 }
        return Double(hintsUsed) / Double(chambersCompleted)
    }
    
    /// Success rate (based on attempts)
    var successRate: Double {
        guard totalActions > 0 else { return 0.0 }
        let successfulActions = totalActions - wrongAttempts
        return (Double(successfulActions) / Double(totalActions)) * 100.0
    }
}

/// Recovery data sent to backend for session restoration
/// Matches backend: backend/app/models/game.py RecoveryData
struct RecoveryData: Codable {
    let traits: [String: Double]?
    let journeyStats: [String: Int]?
    let keyDecisions: [[String: String]]?
    let journalUnlocked: [String]?
    let chambersCompleted: [String]?
    let hintsUsedThisChamber: Int
    let attemptsThisChamber: Int
    let actionsThisChamber: Int
    
    enum CodingKeys: String, CodingKey {
        case traits
        case journeyStats = "journey_stats"
        case keyDecisions = "key_decisions"
        case journalUnlocked = "journal_unlocked"
        case chambersCompleted = "chambers_completed"
        case hintsUsedThisChamber = "hints_used_this_chamber"
        case attemptsThisChamber = "attempts_this_chamber"
        case actionsThisChamber = "actions_this_chamber"
    }
}
