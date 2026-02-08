//
//  ChapterDetailView.swift
//  ImaginationGame
//
//  Full chapter reading experience
//  Beautiful typography and smooth scrolling
//

import SwiftUI

struct ChapterDetailView: View {
    let chapter: JournalChapter
    @Environment(\.dismiss) private var dismiss
    @State private var contentOpacity = 0.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Chapter content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Chapter number
                        Text(chapter.formattedChapterNumber)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.terminalGreen)
                        
                        // Title
                        Text(chapter.title)
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .lineSpacing(4)
                        
                        Divider()
                            .background(Color.terminalGreen.opacity(0.3))
                            .padding(.vertical, 8)
                        
                        // Content
                        Text(chapter.content)
                            .font(.system(size: 17, design: .serif))
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(8)
                            .multilineTextAlignment(.leading)
                            .opacity(contentOpacity)
                    }
                    .padding(24)
                }
                .background(Color.terminalBlack)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                contentOpacity = 1.0
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("JOURNAL")
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.terminalGreen.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "book.fill")
                .font(.system(size: 16))
                .foregroundColor(.terminalGreen)
        }
        .padding()
        .background(Color.terminalDarkGray.opacity(0.5))
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(.terminalGreen),
            alignment: .bottom
        )
    }
}

// MARK: - Preview

struct ChapterDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ChapterDetailView(
            chapter: JournalChapter(
                id: "prologue",
                chapterId: "prologue",
                title: "The First Door",
                content: "The stone chamber is cold and silent. Before you stands a door—ancient, weathered, bearing symbols you cannot read. Yet somehow, you know: this is the beginning of something profound...",
                unlockCondition: "game_start",
                orderIndex: 0,
                isUnlocked: true
            )
        )
        .preferredColorScheme(.dark)
    }
}
