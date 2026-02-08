//
//  JournalViewModel.swift
//  ImaginationGame
//
//  Manages journal chapter list and reading
//

import Foundation
import Combine

@MainActor
class JournalViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var chapters: [JournalChapter] = []
    @Published var selectedChapter: JournalChapter?
    @Published var isLoading = false
    @Published var error: String?
    @Published var unlockedCount = 0
    @Published var totalCount = 0
    @Published var isUsingCache = false  // Indicates if we're using cached data
    
    // MARK: - Dependencies
    
    private let apiService: APIService
    private let cache: JournalCache
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(apiService: APIService? = nil, cache: JournalCache? = nil) {
        self.apiService = apiService ?? .shared
        self.cache = cache ?? .shared
        
        // Load cached chapters immediately
        loadFromCache()
    }
    
    // MARK: - Public Methods
    
    /// Load chapters from cache (instant, offline)
    func loadFromCache() {
        if let cached = cache.loadChapters(), !cached.isEmpty {
            chapters = cached
            unlockedCount = cached.filter { $0.isUnlocked }.count
            totalCount = cached.count
            isUsingCache = true
            print("📦 Loaded \(unlockedCount)/\(totalCount) chapters from cache")
        }
    }
    
    /// Load all journal chapters (tries cache first, then backend)
    /// If sessionId is nil, loads all chapters as locked
    func loadChapters(sessionId: String?) {
        // Always load from cache first (instant)
        loadFromCache()
        
        // Then try to fetch from backend to sync latest data
        isLoading = true
        error = nil
        
        apiService.getJournalChapters(sessionId: sessionId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        // If we have cache, don't show error
                        if self.chapters.isEmpty {
                            self.error = "Failed to load journal: \(error.localizedDescription)"
                            print("❌ Journal load error: \(error)")
                        } else {
                            // Silently fail - we have cached data
                            print("⚠️ Backend sync failed, using cache: \(error.localizedDescription)")
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    // Merge with cache (preserves local unlock status)
                    let merged = self.cache.mergeChapters(fetched: response.chapters)
                    
                    self.chapters = merged
                    self.unlockedCount = merged.filter { $0.isUnlocked }.count
                    self.totalCount = merged.count
                    self.isUsingCache = false
                    
                    print("📖 Synced \(self.unlockedCount)/\(self.totalCount) chapters with backend")
                }
            )
            .store(in: &cancellables)
    }
    
    /// Load a specific chapter by ID (tries cache first, then backend)
    func loadChapter(sessionId: String, chapterId: String) {
        // Try cache first
        if let cached = cache.getChapter(chapterId: chapterId) {
            selectedChapter = cached
            print("📦 Loaded chapter from cache: \(cached.title)")
            
            // If content is empty, try to fetch from backend
            if cached.content.isEmpty {
                fetchChapterFromBackend(sessionId: sessionId, chapterId: chapterId)
            }
            return
        }
        
        // Not in cache - fetch from backend
        fetchChapterFromBackend(sessionId: sessionId, chapterId: chapterId)
    }
    
    /// Fetch chapter from backend
    private func fetchChapterFromBackend(sessionId: String, chapterId: String) {
        isLoading = true
        error = nil
        
        apiService.getChapter(sessionId: sessionId, chapterId: chapterId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        // If we have cached chapter, don't show error
                        if self.selectedChapter == nil {
                            self.error = "Failed to load chapter: \(error.localizedDescription)"
                            print("❌ Chapter load error: \(error)")
                        } else {
                            print("⚠️ Backend fetch failed, using cache: \(error.localizedDescription)")
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    // Save to cache
                    self.cache.saveChapter(response.chapter)
                    
                    self.selectedChapter = response.chapter
                    print("📄 Loaded chapter from backend: \(response.chapter.title)")
                }
            )
            .store(in: &cancellables)
    }
    
    /// Get unlocked chapters only
    var unlockedChapters: [JournalChapter] {
        return chapters.filter { $0.isUnlocked }
    }
    
    /// Get locked chapters only
    var lockedChapters: [JournalChapter] {
        return chapters.filter { !$0.isUnlocked }
    }
    
    /// Check if a chapter is unlocked
    func isChapterUnlocked(chapterId: String) -> Bool {
        return chapters.first(where: { $0.chapterId == chapterId })?.isUnlocked ?? false
    }
    
    /// Get progress percentage (0-100)
    var progressPercentage: Double {
        guard totalCount > 0 else { return 0.0 }
        return (Double(unlockedCount) / Double(totalCount)) * 100.0
    }
    
    /// Clear selected chapter
    func clearSelection() {
        selectedChapter = nil
    }
    
    /// Refresh journal state
    func refresh(sessionId: String?) {
        loadChapters(sessionId: sessionId)
    }
    
    /// Manually unlock a chapter (for when backend sends unlock notification)
    func unlockChapter(chapterId: String) {
        cache.unlockChapter(chapterId: chapterId)
        loadFromCache()  // Reload from cache to reflect changes
        print("🔓 Manually unlocked chapter: \(chapterId)")
    }
    
    /// Clear all cached data (for debugging/reset)
    func clearCache() {
        cache.clearCache()
        chapters = []
        unlockedCount = 0
        totalCount = 0
        print("🗑️ Cleared journal cache")
    }
}
