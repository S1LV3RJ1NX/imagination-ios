import SwiftUI
import Combine

class RoomSelectionViewModel: ObservableObject {
    @Published var rooms: [RoomInfo] = []
    @Published var completedRooms: Set<String> = []
    @Published var unlockedRooms: Set<String> = ["room_01"]
    @Published var showGame = false
    @Published var selectedRoomId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Pagination
    @Published var currentPage = 0
    let roomsPerPage = 5
    
    // SECRET CODE: Unlock all rooms with secret code (works in production)
    @AppStorage("allRoomsUnlocked") var allRoomsUnlocked: Bool = false
    private let secretCode = "PDLINQ3KR7V7"  // Secret code to unlock all rooms (must be UPPERCASE)
    
    private let apiService = APIService.shared
    private let roomsCache = RoomsCache.shared
    private var cancellables = Set<AnyCancellable>()
    
    var totalRooms: Int { rooms.count }
    var completedCount: Int { completedRooms.count }
    var progressPercentage: Int {
        guard totalRooms > 0 else { return 0 }
        return (completedCount * 100) / totalRooms
    }
    
    // Pagination computed properties
    var totalPages: Int {
        guard !rooms.isEmpty else { return 0 }
        return (rooms.count + roomsPerPage - 1) / roomsPerPage
    }
    
    var currentPageRooms: [RoomInfo] {
        let startIndex = currentPage * roomsPerPage
        let endIndex = min(startIndex + roomsPerPage, rooms.count)
        guard startIndex < rooms.count else { return [] }
        return Array(rooms[startIndex..<endIndex])
    }
    
    var canGoToPreviousPage: Bool {
        currentPage > 0
    }
    
    var canGoToNextPage: Bool {
        currentPage < totalPages - 1
    }
    
    var currentPageStart: Int {
        currentPage * roomsPerPage + 1
    }
    
    var currentPageEnd: Int {
        min((currentPage + 1) * roomsPerPage, rooms.count)
    }
    
    init() {
        loadProgress()
        loadRoomsFromCache()
    }
    
    /// Load rooms from cache (instant, offline)
    func loadRoomsFromCache() {
        if let cached = roomsCache.loadRooms(), !cached.isEmpty {
            rooms = cached
            print("📦 Loaded \(cached.count) rooms from cache")
        }
    }
    
    func loadRooms() {
        // Always load from cache first (instant)
        loadRoomsFromCache()
        
        // Then try to fetch from backend to sync latest data
        isLoading = true
        errorMessage = nil
        
        apiService.fetchRooms()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        // If we have cache, don't show error
                        if self.rooms.isEmpty {
                            self.errorMessage = "Failed to load rooms: \(error.localizedDescription)"
                            print("❌ Failed to load rooms: \(error)")
                        } else {
                            // Silently fail - we have cached data
                            print("⚠️ Backend sync failed, using cache: \(error.localizedDescription)")
                        }
                    }
                },
                receiveValue: { [weak self] (response: RoomsResponse) in
                    guard let self = self else { return }
                    
                    // Save to cache
                    self.roomsCache.saveRooms(response.rooms)
                    
                    self.rooms = response.rooms
                    self.loadProgress()
                    print("✅ Loaded \(response.rooms.count) rooms from backend")
                }
            )
            .store(in: &cancellables)
    }
    
    func loadProgress() {
        // Load from UserDefaults
        if let savedCompleted = UserDefaults.standard.stringArray(forKey: "completedRooms") {
            completedRooms = Set(savedCompleted)
        }
        
        if let savedUnlocked = UserDefaults.standard.stringArray(forKey: "unlockedRooms") {
            unlockedRooms = Set(savedUnlocked)
        } else {
            unlockedRooms = ["room_01"]  // First room always unlocked
        }
    }
    
    func saveProgress() {
        UserDefaults.standard.set(Array(completedRooms), forKey: "completedRooms")
        UserDefaults.standard.set(Array(unlockedRooms), forKey: "unlockedRooms")
    }
    
    func isUnlocked(_ roomId: String) -> Bool {
        // SECRET CODE: All rooms unlocked (works in production)
        if allRoomsUnlocked {
            return true
        }
        return unlockedRooms.contains(roomId)
    }
    
    func verifySecretCode(_ code: String) -> Bool {
        let enteredCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if enteredCode == secretCode {
            allRoomsUnlocked = true
            print("🔓 Secret code verified! All rooms unlocked.")
            return true
        }
        return false
    }
    
    func disableSecretCodeMode() {
        allRoomsUnlocked = false
        print("🔒 Secret code mode disabled.")
    }
    
    func isCompleted(_ roomId: String) -> Bool {
        // Check both old tracking and new attempt tracker
        return completedRooms.contains(roomId) || ChamberAttemptTracker.shared.isCompleted(chamberId: roomId)
    }
    
    func selectRoom(_ roomId: String) {
        selectedRoomId = roomId
        showGame = true
    }
    
    func markRoomComplete(_ roomId: String) {
        completedRooms.insert(roomId)
        
        // Unlock next room
        if let currentIndex = rooms.firstIndex(where: { $0.roomId == roomId }),
           currentIndex + 1 < rooms.count {
            let nextRoomId = rooms[currentIndex + 1].roomId
            unlockedRooms.insert(nextRoomId)
            print("🔓 Unlocked next room: \(nextRoomId)")
        }
        
        saveProgress()
    }
    
    func resetProgress() {
        print("🗑️ RESET PROGRESS: Starting comprehensive cleanup...")
        
        // Clear room selection state
        completedRooms.removeAll()
        unlockedRooms = ["room_01"]
        currentPage = 0
        saveProgress()
        
        // Clear ALL local storage caches
        ChamberAttemptTracker.shared.clearAll()
        JournalCache.shared.clearCache()
        RoomsCache.shared.clearCache()
        
        // Clear ALL UserDefaults keys related to game state
        let keysToRemove = [
            "lastSessionId",
            "lastRoomId",
            "playerTraits",
            "journeyStats",
            "keyDecisions",
            "journalUnlocked",
            "hintsUsedThisChamber",
            "attemptsThisChamber",
            "actionsThisChamber",
            "completedRooms",
            "unlockedRooms",
            "allRoomsUnlocked",
            "currentPage"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("✅ Reset complete - all local data cleared")
        print("ℹ️  Backend sessions will auto-expire (TTL)")
    }
    
    // Pagination methods
    func goToPreviousPage() {
        guard canGoToPreviousPage else { return }
        withAnimation {
            currentPage -= 1
        }
    }
    
    func goToNextPage() {
        guard canGoToNextPage else { return }
        withAnimation {
            currentPage += 1
        }
    }
}
