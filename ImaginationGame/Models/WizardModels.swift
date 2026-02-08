//
//  WizardModels.swift
//  ImaginationGame
//
//  Models for the Wizard archetype system
//  Matches backend: backend/app/services/archetype_calculator.py
//

import Foundation

/// Player's personality archetype (1 of 16 possible)
struct Archetype: Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let dialogue: String
    let primaryTraits: [String]
    let secondaryTraits: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case dialogue
        case primaryTraits = "primary_traits"
        case secondaryTraits = "secondary_traits"
    }
    
    /// Get all traits (primary + secondary)
    var allTraits: [String] {
        return primaryTraits + secondaryTraits
    }
}

/// Response from wizard archetype calculation
struct WizardRevealResponse: Codable {
    let archetype: Archetype
    let traits: PlayerTraits
    let journeyStats: JourneyStats
    let completionMessage: String
    
    enum CodingKeys: String, CodingKey {
        case archetype
        case traits
        case journeyStats = "journey_stats"
        case completionMessage = "completion_message"
    }
}

/// Request to share profile (generate shareable image)
struct ShareProfileRequest: Codable {
    let sessionId: String
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
    }
}

/// Response with shareable profile image data
struct ShareProfileResponse: Codable {
    let imageData: String // Base64 encoded PNG
    let archetypeName: String
    let topTraits: [TraitScore]
    
    enum CodingKeys: String, CodingKey {
        case imageData = "image_data"
        case archetypeName = "archetype_name"
        case topTraits = "top_traits"
    }
}

/// Individual trait score for display
struct TraitScore: Codable, Equatable {
    let name: String
    let value: Double
}
