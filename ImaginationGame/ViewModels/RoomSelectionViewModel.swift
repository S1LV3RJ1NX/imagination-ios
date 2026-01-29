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
    let roomsPerPage = 6
    
    // DEBUG MODE: Toggle to show all rooms unlocked for testing
    @AppStorage("debugMode") var debugMode: Bool = false
    
    private let apiService = APIService.shared
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
    }
    
    func loadRooms() {
        isLoading = true
        errorMessage = nil
        
        apiService.fetchRooms()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Failed to load rooms: \(error.localizedDescription)"
                        print("❌ Failed to load rooms: \(error)")
                    }
                },
                receiveValue: { [weak self] (response: RoomsResponse) in
                    self?.rooms = response.rooms
                    self?.loadProgress()
                    print("✅ Loaded \(response.rooms.count) rooms")
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
        // DEBUG MODE: All rooms unlocked
        if debugMode {
            return true
        }
        return unlockedRooms.contains(roomId)
    }
    
    func isCompleted(_ roomId: String) -> Bool {
        completedRooms.contains(roomId)
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
        completedRooms.removeAll()
        unlockedRooms = ["room_01"]
        currentPage = 0  // Reset to first page
        saveProgress()
    }
    
    func toggleDebugMode() {
        debugMode.toggle()
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
