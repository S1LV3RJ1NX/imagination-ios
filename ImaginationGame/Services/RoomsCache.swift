//
//  RoomsCache.swift
//  ImaginationGame
//
//  Local cache for rooms list using UserDefaults
//

import Foundation

final class RoomsCache {
    
    // MARK: - Singleton
    
    static let shared = RoomsCache()
    
    // MARK: - Constants
    
    private let roomsKey = "cached_rooms_list"
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Save rooms to cache
    func saveRooms(_ rooms: [RoomInfo]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(rooms)
            UserDefaults.standard.set(data, forKey: roomsKey)
            print("💾 Cached \(rooms.count) rooms locally")
        } catch {
            print("❌ Failed to cache rooms: \(error)")
        }
    }
    
    /// Load rooms from cache
    func loadRooms() -> [RoomInfo]? {
        guard let data = UserDefaults.standard.data(forKey: roomsKey) else {
            print("📭 No cached rooms found")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let rooms = try decoder.decode([RoomInfo].self, from: data)
            print("📦 Loaded \(rooms.count) rooms from cache")
            return rooms
        } catch {
            print("❌ Failed to decode cached rooms: \(error)")
            return nil
        }
    }
    
    /// Clear cached rooms
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: roomsKey)
        print("🗑️ Cleared rooms cache")
    }
    
    /// Check if cache is empty
    var isEmpty: Bool {
        return loadRooms()?.isEmpty ?? true
    }
}
