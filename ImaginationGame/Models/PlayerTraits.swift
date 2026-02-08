//
//  PlayerTraits.swift
//  ImaginationGame
//
//  Player personality traits tracked throughout the journey
//  Matches backend: backend/app/services/trait_tracker.py
//

import Foundation

/// Player personality traits scored 0.0 to 10.0
/// These are tracked secretly during gameplay and revealed at the end
/// Matches backend: backend/app/models/game.py PlayerTraits
struct PlayerTraits: Codable, Equatable {
    // Cognitive Traits
    var logicalThinking: Double
    var creativeThinking: Double
    var observation: Double
    var memory: Double
    
    // Emotional Traits
    var empathy: Double
    var courage: Double
    var patience: Double
    var trust: Double
    
    // Behavioral Traits
    var impulsivity: Double
    var pragmatism: Double
    var curiosity: Double
    var integrity: Double
    
    enum CodingKeys: String, CodingKey {
        case logicalThinking = "logical_thinking"
        case creativeThinking = "creative_thinking"
        case observation
        case memory
        case empathy
        case courage
        case patience
        case trust
        case impulsivity
        case pragmatism
        case curiosity
        case integrity
    }
    
    /// Initialize with default neutral values (0.0)
    init() {
        self.logicalThinking = 0.0
        self.creativeThinking = 0.0
        self.observation = 0.0
        self.memory = 0.0
        self.empathy = 0.0
        self.courage = 0.0
        self.patience = 0.0
        self.trust = 0.0
        self.impulsivity = 0.0
        self.pragmatism = 0.0
        self.curiosity = 0.0
        self.integrity = 0.0
    }
    
    /// Get all traits as array of (name, value) pairs for UI display
    var allTraits: [(name: String, value: Double)] {
        return [
            ("Logical Thinking", logicalThinking),
            ("Creative Thinking", creativeThinking),
            ("Observation", observation),
            ("Memory", memory),
            ("Empathy", empathy),
            ("Courage", courage),
            ("Patience", patience),
            ("Trust", trust),
            ("Impulsivity", impulsivity),
            ("Pragmatism", pragmatism),
            ("Curiosity", curiosity),
            ("Integrity", integrity)
        ]
    }
    
    /// Get top 5 strongest traits
    var topTraits: [(name: String, value: Double)] {
        return allTraits.sorted { $0.value > $1.value }.prefix(5).map { $0 }
    }
    
    /// Get trait value by key name (for dynamic lookup)
    func value(for key: String) -> Double? {
        switch key {
        case "logical_thinking": return logicalThinking
        case "creative_thinking": return creativeThinking
        case "observation": return observation
        case "memory": return memory
        case "empathy": return empathy
        case "courage": return courage
        case "patience": return patience
        case "trust": return trust
        case "impulsivity": return impulsivity
        case "pragmatism": return pragmatism
        case "curiosity": return curiosity
        case "integrity": return integrity
        default: return nil
        }
    }
}

/// Key decision made during gameplay (ethical dilemmas, persuasion choices)
/// Matches backend: backend/app/models/game.py KeyDecision
struct KeyDecision: Codable, Equatable, Identifiable {
    var id: String { chamberId + "_" + decisionType } // Generate ID from fields
    let chamberId: String
    let decisionType: String
    let decisionValue: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case chamberId = "chamber_id"
        case decisionType = "decision_type"
        case decisionValue = "decision_value"
        case timestamp
    }
}
