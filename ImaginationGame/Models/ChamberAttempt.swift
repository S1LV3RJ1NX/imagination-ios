//
//  ChamberAttempt.swift
//  ImaginationGame
//
//  Tracks attempts at a chamber across sessions
//  Used for personality profiling - accumulates data from all retry attempts
//

import Foundation

struct ChamberAttempt: Codable {
    let chamberId: String
    var attemptCount: Int = 0  // Number of times tried
    var hintsUsedTotal: Int = 0  // Total hints across all attempts
    var actionsTotal: Int = 0  // Total actions across all attempts
    var wrongAttemptsTotal: Int = 0  // Total wrong attempts
    var isCompleted: Bool = false  // Successfully completed (locked from replay)
    var completedAt: Date?  // When completed
    var sessions: [String] = []  // Session IDs used for this chamber
    
    init(chamberId: String) {
        self.chamberId = chamberId
    }
}

/// Manager for chamber attempt tracking
final class ChamberAttemptTracker {
    
    static let shared = ChamberAttemptTracker()
    
    private let attemptsKey = "chamber_attempts"
    
    private init() {}
    
    // MARK: - Storage
    
    func saveAttempts(_ attempts: [String: ChamberAttempt]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(attempts)
            UserDefaults.standard.set(data, forKey: attemptsKey)
            print("💾 Saved chamber attempts: \(attempts.count) chambers")
        } catch {
            print("❌ Failed to save chamber attempts: \(error)")
        }
    }
    
    func loadAttempts() -> [String: ChamberAttempt] {
        guard let data = UserDefaults.standard.data(forKey: attemptsKey) else {
            return [:]
        }
        
        do {
            let decoder = JSONDecoder()
            let attempts = try decoder.decode([String: ChamberAttempt].self, from: data)
            return attempts
        } catch {
            print("❌ Failed to load chamber attempts: \(error)")
            return [:]
        }
    }
    
    // MARK: - Public Methods
    
    /// Start a new attempt at a chamber
    func startAttempt(chamberId: String, sessionId: String) -> ChamberAttempt {
        var attempts = loadAttempts()
        var attempt = attempts[chamberId] ?? ChamberAttempt(chamberId: chamberId)
        
        // Increment attempt count
        attempt.attemptCount += 1
        attempt.sessions.append(sessionId)
        
        attempts[chamberId] = attempt
        saveAttempts(attempts)
        
        print("🎮 Starting attempt #\(attempt.attemptCount) for \(chamberId)")
        return attempt
    }
    
    /// Update attempt with current session data
    func updateAttempt(chamberId: String, hintsUsed: Int, actions: Int, wrongAttempts: Int) {
        var attempts = loadAttempts()
        guard var attempt = attempts[chamberId] else { return }
        
        attempt.hintsUsedTotal += hintsUsed
        attempt.actionsTotal += actions
        attempt.wrongAttemptsTotal += wrongAttempts
        
        attempts[chamberId] = attempt
        saveAttempts(attempts)
    }
    
    /// Mark chamber as completed (lock from replay)
    func markComplete(chamberId: String) {
        var attempts = loadAttempts()
        guard var attempt = attempts[chamberId] else { return }
        
        attempt.isCompleted = true
        attempt.completedAt = Date()
        
        attempts[chamberId] = attempt
        saveAttempts(attempts)
        
        print("✅ Chamber \(chamberId) completed and locked from replay")
    }
    
    /// Check if chamber is completed (can't replay)
    func isCompleted(chamberId: String) -> Bool {
        let attempts = loadAttempts()
        return attempts[chamberId]?.isCompleted ?? false
    }
    
    /// Get attempt for a chamber
    func getAttempt(chamberId: String) -> ChamberAttempt? {
        let attempts = loadAttempts()
        return attempts[chamberId]
    }
    
    /// Get list of completed chamber IDs
    func getCompletedChamberIds() -> [String] {
        let attempts = loadAttempts()
        return attempts.values.filter { $0.isCompleted }.map { $0.chamberId }
    }
    
    /// Clear all attempts (for New Journey)
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: attemptsKey)
        print("🗑️ Cleared all chamber attempts")
    }
}
