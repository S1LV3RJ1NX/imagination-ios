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
        JournalView(sessionId: sessionId)
            .onAppear {
                #if DEBUG
                if let sid = sessionId {
                    print("📖 JournalTabContent: Session \(sid.prefix(12))...")
                } else {
                    print("📖 JournalTabContent: No session, using cache-only mode")
                }
                #endif
            }
    }
}
