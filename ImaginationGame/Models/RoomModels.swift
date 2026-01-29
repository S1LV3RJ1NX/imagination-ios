import Foundation

// MARK: - Room Info
struct RoomInfo: Codable, Identifiable {
    let roomId: String
    let roomName: String
    let description: String
    let difficulty: String
    
    var id: String { roomId }
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case roomName = "room_name"
        case description
        case difficulty
    }
}

// MARK: - Rooms Response
struct RoomsResponse: Codable {
    let rooms: [RoomInfo]
    let total: Int
}

// MARK: - Progress Response
struct ProgressResponse: Codable {
    let playerId: String
    let completedRooms: [String]
    let unlockedRooms: [String]
    let currentRoom: String
    let totalRooms: Int
    let progressPercentage: Int
    let rooms: [RoomInfo]
    
    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case completedRooms = "completed_rooms"
        case unlockedRooms = "unlocked_rooms"
        case currentRoom = "current_room"
        case totalRooms = "total_rooms"
        case progressPercentage = "progress_percentage"
        case rooms
    }
}

// MARK: - Difficulty Helpers
extension RoomInfo {
    var difficultyStars: String {
        switch difficulty {
        case "very_easy": return "★☆☆☆☆"
        case "easy": return "★★☆☆☆"
        case "medium": return "★★★☆☆"
        case "medium_hard": return "★★★★☆"
        case "hard": return "★★★★☆"
        case "very_hard": return "★★★★★"
        default: return "★★★☆☆"
        }
    }
    
    var difficultyLabel: String {
        switch difficulty {
        case "very_easy": return "TUTORIAL"
        case "easy": return "EASY"
        case "medium": return "MEDIUM"
        case "medium_hard": return "CHALLENGING"
        case "hard": return "HARD"
        case "very_hard": return "EXPERT"
        default: return "MEDIUM"
        }
    }
}
