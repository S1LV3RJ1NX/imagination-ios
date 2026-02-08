//
//  JournalModels.swift
//  ImaginationGame
//
//  Models for The Chronicle journal system
//  Matches backend: backend/app/services/journal_manager.py
//

import Foundation

/// A chapter in The Chronicle
struct JournalChapter: Codable, Identifiable, Equatable {
    let id: String
    let chapterId: String
    let title: String
    let content: String
    let unlockCondition: String
    let orderIndex: Int
    let isUnlocked: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case chapterId = "chapter_id"
        case title
        case content
        case unlockCondition = "unlock_condition"
        case orderIndex = "order_index"
        case isUnlocked = "is_unlocked"
    }
    
    /// Formatted chapter number for display (e.g., "Chapter 1")
    var formattedChapterNumber: String {
        if chapterId == "prologue" {
            return "Prologue"
        } else if chapterId == "epilogue" {
            return "Epilogue"
        } else {
            // Extract number from "chapter_01", "chapter_02", etc.
            let numberString = chapterId.replacingOccurrences(of: "chapter_", with: "")
            if let number = Int(numberString) {
                return "Chapter \(number)"
            }
            return chapterId.capitalized
        }
    }
    
    /// Preview of content (first 100 characters)
    var contentPreview: String {
        let maxLength = 100
        if content.count > maxLength {
            let index = content.index(content.startIndex, offsetBy: maxLength)
            return String(content[..<index]) + "..."
        }
        return content
    }
}

/// Response for journal list endpoint
struct JournalListResponse: Codable {
    let chapters: [JournalChapter]
    let unlockedCount: Int
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case chapters
        case unlockedCount = "unlocked_count"
        case totalCount = "total_count"
    }
}

/// Response for individual chapter endpoint
struct ChapterResponse: Codable {
    let chapter: JournalChapter
}
