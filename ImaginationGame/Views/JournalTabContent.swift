//
//  JournalTabContent.swift
//  ImaginationGame
//
//  Wrapper for Journal tab to handle session state
//

import SwiftUI

struct JournalTabContent: View {
    let sessionId: String?
    
    var body: some View {
        Group {
            #if DEBUG
            let _ = sessionId.map { print("📖 JournalTabContent: Session \($0.prefix(12))...") } ?? print("📖 JournalTabContent: No session, using cache-only mode")
            #endif
            
            // Always show JournalView - it will use cache if no session
            JournalView(sessionId: sessionId)
        }
    }
}
