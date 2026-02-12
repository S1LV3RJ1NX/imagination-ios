//
//  JournalView.swift
//  ImaginationGame
//
//  The Chronicle - Journal chapter list
//  Progressive unlocking tied to game progress
//

import SwiftUI

struct JournalView: View {
    @StateObject private var viewModel = JournalViewModel()
    @State private var selectedChapter: JournalChapter?
    let sessionId: String?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Cache indicator (if using offline data)
                if viewModel.isUsingCache && !viewModel.isLoading {
                    cacheIndicatorView
                }
                
                // Content
                if viewModel.isLoading && viewModel.chapters.isEmpty {
                    loadingView
                } else if let error = viewModel.error, viewModel.chapters.isEmpty {
                    errorView(error)
                } else {
                    journalListView
                }
            }
        }
        .onAppear {
            if let sessionId = sessionId {
                print("📖 JournalView appeared with sessionId: \(sessionId)")
                viewModel.loadChapters(sessionId: sessionId)
            } else {
                print("📖 JournalView appeared without session - loading all chapters as locked")
                // Load from cache first
                viewModel.loadFromCache()
                
                // If no cache, fetch all chapters as locked from backend
                if viewModel.chapters.isEmpty {
                    viewModel.loadChapters(sessionId: nil)
                }
            }
        }
        .sheet(item: $selectedChapter) { chapter in
            ChapterDetailView(chapter: chapter)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
            }
            
            Text("📖 THE CHRONICLE")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.terminalGreen)
                .shadow(color: .terminalGreen, radius: 10)
            
            // Progress bar
            VStack(spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(viewModel.unlockedCount) / \(viewModel.totalCount)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.terminalGreen)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.terminalDarkGray)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.terminalGreen, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (viewModel.progressPercentage / 100.0), height: 8)
                    }
                }
                .frame(height: 8)
            }
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
    
    // MARK: - Cache Indicator
    
    private var cacheIndicatorView: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.cyan)
            
            Text("Viewing saved progress (offline)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.cyan.opacity(0.8))
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.cyan.opacity(0.1))
    }
    
    // MARK: - Journal List
    
    private var journalListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Show ALL chapters in order (like Chambers list)
                // Sorted by order_index so they appear in story order
                ForEach(viewModel.sortedChapters) { chapter in
                    ChapterRow(chapter: chapter, isLocked: !chapter.isUnlocked)
                        .onTapGesture {
                            if chapter.isUnlocked {
                                selectedChapter = chapter
                            } else {
                                // Optional: Show toast or nothing for locked chapters
                                print("📕 Chapter \(chapter.chapterId) is locked")
                            }
                        }
                }
            }
            .padding()
        }
        .background(Color.terminalBlack)
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Loading & Error
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .terminalGreen))
                .scaleEffect(1.5)
            
            Text("Loading Journal...")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.terminalGreen.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.terminalBlack)
    }
    
    private func errorView(_ message: String) -> some View {
        let isSessionExpired = message.contains("expired") || message.contains("not found")
        
        return VStack(spacing: 16) {
            Image(systemName: isSessionExpired ? "clock.badge.exclamationmark" : "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(isSessionExpired ? .orange : .red)
            
            Text(isSessionExpired ? "Session Expired" : "Error")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(isSessionExpired ? .orange : .red)
            
            Text(message)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if isSessionExpired {
                Text("Your game session has expired. Start a new chamber to continue your journey and unlock more journal entries.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)
            } else {
                Button(action: {
                    viewModel.refresh(sessionId: sessionId)
                }) {
                    Text("Retry")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.terminalGreen)
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.terminalBlack)
    }
}

// MARK: - Chapter Row

struct ChapterRow: View {
    let chapter: JournalChapter
    let isLocked: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Chapter number/icon
            VStack {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                } else {
                    Image(systemName: "book.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.terminalGreen)
                }
            }
            .frame(width: 32)
            
            // Chapter info
            VStack(alignment: .leading, spacing: 6) {
                Text(chapter.formattedChapterNumber)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(isLocked ? .gray : .terminalGreen)
                
                Text(chapter.title)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(isLocked ? .gray.opacity(0.5) : .white)
                
                if !isLocked {
                    Text(chapter.contentPreview)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                } else {
                    Text("Complete Chamber \(chapter.orderIndex) to unlock")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.5))
                        .italic()
                }
            }
            
            Spacer()
            
            // Arrow indicator (unlocked only)
            if !isLocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            isLocked ?
                Color.terminalDarkGray.opacity(0.3) :
                Color.terminalGreen.opacity(0.05)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isLocked ? Color.gray.opacity(0.3) : Color.terminalGreen.opacity(0.5),
                    lineWidth: 1
                )
        )
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct JournalView_Previews: PreviewProvider {
    static var previews: some View {
        JournalView(sessionId: "test-session")
            .preferredColorScheme(.dark)
    }
}
