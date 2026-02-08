//
//  JournalCache.swift
//  ImaginationGame
//
//  Local cache for journal chapters using UserDefaults
//  iOS is the source of truth for unlocked chapters and content
//

import Foundation

final class JournalCache {
    
    // MARK: - Singleton
    
    static let shared = JournalCache()
    
    // MARK: - Constants
    
    private let chaptersKey = "cached_journal_chapters"
    private let unlockedChaptersKey = "unlocked_chapter_ids"
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Save chapters to cache
    func saveChapters(_ chapters: [JournalChapter]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(chapters)
            UserDefaults.standard.set(data, forKey: chaptersKey)
            print("💾 Cached \(chapters.count) chapters locally")
        } catch {
            print("❌ Failed to cache chapters: \(error)")
        }
    }
    
    /// Load chapters from cache
    func loadChapters() -> [JournalChapter]? {
        guard let data = UserDefaults.standard.data(forKey: chaptersKey) else {
            print("📭 No cached chapters found")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let chapters = try decoder.decode([JournalChapter].self, from: data)
            print("📦 Loaded \(chapters.count) chapters from cache")
            return chapters
        } catch {
            print("❌ Failed to decode cached chapters: \(error)")
            return nil
        }
    }
    
    /// Save a single chapter (or update existing)
    func saveChapter(_ chapter: JournalChapter) {
        var chapters = loadChapters() ?? []
        
        // Remove old version if exists
        chapters.removeAll { $0.chapterId == chapter.chapterId }
        
        // Add new version
        chapters.append(chapter)
        
        // Sort by order_index
        chapters.sort { $0.orderIndex < $1.orderIndex }
        
        saveChapters(chapters)
    }
    
    /// Mark a chapter as unlocked (update unlock status in cache)
    func unlockChapter(chapterId: String) {
        guard var chapters = loadChapters() else {
            print("⚠️ Cannot unlock chapter: no cached chapters")
            return
        }
        
        // Update unlock status
        if let index = chapters.firstIndex(where: { $0.chapterId == chapterId }) {
            let updatedChapter = chapters[index]
            // Create a new chapter with updated unlock status
            let unlockedChapter = JournalChapter(
                id: updatedChapter.id,
                chapterId: updatedChapter.chapterId,
                title: updatedChapter.title,
                content: updatedChapter.content,
                unlockCondition: updatedChapter.unlockCondition,
                orderIndex: updatedChapter.orderIndex,
                isUnlocked: true
            )
            chapters[index] = unlockedChapter
            saveChapters(chapters)
            print("🔓 Unlocked chapter in cache: \(chapterId)")
        }
        
        // Also save to unlocked list
        var unlockedIds = getUnlockedChapterIds()
        if !unlockedIds.contains(chapterId) {
            unlockedIds.append(chapterId)
            UserDefaults.standard.set(unlockedIds, forKey: unlockedChaptersKey)
        }
    }
    
    /// Get list of unlocked chapter IDs
    func getUnlockedChapterIds() -> [String] {
        return UserDefaults.standard.stringArray(forKey: unlockedChaptersKey) ?? []
    }
    
    /// Get a specific chapter from cache
    func getChapter(chapterId: String) -> JournalChapter? {
        guard let chapters = loadChapters() else { return nil }
        return chapters.first { $0.chapterId == chapterId }
    }
    
    /// Merge fetched chapters with cache (update unlock status and content)
    func mergeChapters(fetched: [JournalChapter]) -> [JournalChapter] {
        var cached = loadChapters() ?? []
        
        // Update cached chapters with fetched data
        for fetchedChapter in fetched {
            if let index = cached.firstIndex(where: { $0.chapterId == fetchedChapter.chapterId }) {
                // Update existing chapter (preserve local unlock status if more recent)
                let cachedChapter = cached[index]
                
                // Use fetched data but preserve local unlock if it's true
                let mergedChapter = JournalChapter(
                    id: fetchedChapter.id,
                    chapterId: fetchedChapter.chapterId,
                    title: fetchedChapter.title,
                    content: fetchedChapter.content.isEmpty ? cachedChapter.content : fetchedChapter.content,
                    unlockCondition: fetchedChapter.unlockCondition,
                    orderIndex: fetchedChapter.orderIndex,
                    isUnlocked: cachedChapter.isUnlocked || fetchedChapter.isUnlocked
                )
                cached[index] = mergedChapter
            } else {
                // New chapter - add it
                cached.append(fetchedChapter)
            }
        }
        
        // Sort by order_index
        cached.sort { $0.orderIndex < $1.orderIndex }
        
        saveChapters(cached)
        return cached
    }
    
    /// Clear all cached chapters (for debugging/reset)
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: chaptersKey)
        UserDefaults.standard.removeObject(forKey: unlockedChaptersKey)
        print("🗑️ Cleared journal cache")
    }
    
    /// Check if cache is empty
    var isEmpty: Bool {
        return loadChapters()?.isEmpty ?? true
    }
}
