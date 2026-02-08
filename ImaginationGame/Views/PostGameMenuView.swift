//
//  PostGameMenuView.swift
//  ImaginationGame
//
//  Menu shown after completing all 20 chambers
//  Options: Stats, Journal, Share, New Journey
//

import SwiftUI

struct PostGameMenuView: View {
    let sessionId: String
    let onNewJourney: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var showWizardReveal = false
    @State private var showStats = false
    @State private var showJournal = false
    @State private var showNewJourneyAlert = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Celebration header
                    headerView
                    
                    // Menu options
                    menuOptions
                    
                    // New Journey button
                    newJourneySection
                }
                .padding(24)
            }
        }
        .sheet(isPresented: $showWizardReveal) {
            WizardRevealView(sessionId: sessionId)
        }
        .sheet(isPresented: $showStats) {
            NavigationView {
                StatsView(sessionId: sessionId)
            }
        }
        .sheet(isPresented: $showJournal) {
            JournalView(sessionId: sessionId)
        }
        .alert("Start New Journey?", isPresented: $showNewJourneyAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Begin Anew", role: .destructive, action: onNewJourney)
        } message: {
            Text("This will reset all progress and start fresh. Your current journey will be lost forever.")
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 20) {
            Text("🎉")
                .font(.system(size: 80))
            
            Text("JOURNEY COMPLETE")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.terminalGreen)
                .shadow(color: .terminalGreen, radius: 15)
            
            Text("You have conquered all 20 Chambers.\nThe Wizard awaits to reveal your true self.")
                .font(.system(size: 15, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Menu Options
    
    private var menuOptions: some View {
        VStack(spacing: 16) {
            // Wizard Reveal (Primary Action)
            MenuCard(
                icon: "🧙",
                title: "Wizard's Revelation",
                description: "Discover your personality archetype",
                color: .yellow,
                isPrimary: true
            ) {
                showWizardReveal = true
            }
            
            // Full Stats
            MenuCard(
                icon: "📊",
                title: "Your Profile",
                description: "View all traits and statistics",
                color: .cyan
            ) {
                showStats = true
            }
            
            // Journal
            MenuCard(
                icon: "📖",
                title: "The Chronicle",
                description: "Read the complete story",
                color: .green
            ) {
                showJournal = true
            }
        }
    }
    
    // MARK: - New Journey
    
    private var newJourneySection: some View {
        VStack(spacing: 16) {
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.vertical, 8)
            
            Text("Want to discover a different path?")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.gray)
            
            Button(action: { showNewJourneyAlert = true }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Start New Journey")
                }
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.5), lineWidth: 2)
                )
            }
            
            Text("⚠️ This will permanently delete your current progress")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.red.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Menu Card

struct MenuCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    var isPrimary: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: isPrimary ? .heavy : .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                // Icon
                Text(icon)
                    .font(.system(size: isPrimary ? 48 : 40))
                    .frame(width: 60)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: isPrimary ? 18 : 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: isPrimary ? 14 : 13, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
            }
            .padding(isPrimary ? 24 : 20)
            .background(
                isPrimary ?
                    LinearGradient(
                        colors: [color.opacity(0.2), color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [Color.terminalGreen.opacity(0.05), Color.terminalGreen.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isPrimary ? color.opacity(0.6) : Color.terminalGreen.opacity(0.3),
                        lineWidth: isPrimary ? 3 : 2
                    )
            )
            .cornerRadius(16)
            .shadow(
                color: isPrimary ? color.opacity(0.3) : Color.clear,
                radius: isPrimary ? 20 : 0
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview

struct PostGameMenuView_Previews: PreviewProvider {
    static var previews: some View {
        PostGameMenuView(sessionId: "test-session", onNewJourney: {})
            .preferredColorScheme(.dark)
    }
}
