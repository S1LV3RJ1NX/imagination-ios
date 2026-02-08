//
//  WizardRevealView.swift
//  ImaginationGame
//
//  Dramatic archetype reveal screen
//  The Wizard shows the player who they truly are
//

import SwiftUI

struct WizardRevealView: View {
    @StateObject private var viewModel = WizardViewModel()
    let sessionId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var showArchetypeName = false
    @State private var showDialogue = false
    @State private var showTraits = false
    @State private var showStats = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(error)
            } else if viewModel.isRevealed {
                revealView
            }
        }
        .onAppear {
            viewModel.loadWizardReveal(sessionId: sessionId)
        }
    }
    
    // MARK: - Loading
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            Text("🧙")
                .font(.system(size: 80))
            
            Text("The Wizard is reading your journey...")
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.terminalGreen)
                .multilineTextAlignment(.center)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .terminalGreen))
                .scaleEffect(1.5)
        }
        .padding()
    }
    
    // MARK: - Error
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text("⚠️")
                .font(.system(size: 64))
            
            Text(message)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.red.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { viewModel.loadWizardReveal(sessionId: sessionId) }) {
                Text("Retry")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.terminalGreen)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    // MARK: - Reveal
    
    private var revealView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerView
                
                // Archetype reveal
                if let archetype = viewModel.archetype {
                    archetypeSection(archetype)
                }
                
                // Wizard's dialogue
                if let archetype = viewModel.archetype, showDialogue {
                    wizardDialogue(archetype.dialogue)
                }
                
                // Trait breakdown
                if showTraits {
                    traitSection
                }
                
                // Journey stats
                if showStats {
                    statsSection
                }
                
                // Actions
                actionButtons
            }
            .padding(24)
        }
        .onAppear {
            // Staggered reveal animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.8)) {
                    showArchetypeName = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.8)) {
                    showDialogue = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeIn(duration: 0.8)) {
                    showTraits = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeIn(duration: 0.8)) {
                    showStats = true
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Text("🧙")
                .font(.system(size: 72))
            
            Text("THE WIZARD SPEAKS")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.terminalGreen)
                .shadow(color: .terminalGreen, radius: 10)
        }
        .padding(.top, 16)
    }
    
    private func archetypeSection(_ archetype: Archetype) -> some View {
        VStack(spacing: 16) {
            if showArchetypeName {
                Text("You are...")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.gray)
                
                Text(archetype.name)
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 20)
                    .multilineTextAlignment(.center)
                
                Text(archetype.description)
                    .font(.system(size: 16, design: .serif))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
    }
    
    private func wizardDialogue(_ dialogue: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: 20))
                    .foregroundColor(.terminalGreen)
                Spacer()
            }
            
            Text(dialogue)
                .font(.system(size: 16, design: .serif))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(8)
                .italic()
            
            HStack {
                Spacer()
                Image(systemName: "quote.closing")
                    .font(.system(size: 20))
                    .foregroundColor(.terminalGreen)
            }
        }
        .padding()
        .background(Color.terminalGreen.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.terminalGreen.opacity(0.3), lineWidth: 2)
        )
        .cornerRadius(12)
    }
    
    private var traitSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("YOUR PERSONALITY PROFILE")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.terminalGreen)
            
            VStack(spacing: 12) {
                ForEach(viewModel.topTraits, id: \.name) { trait in
                    TraitBar(name: trait.name, value: trait.value)
                }
            }
            
            NavigationLink(destination: StatsView(sessionId: sessionId)) {
                HStack {
                    Text("View Full Profile")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                }
                .foregroundColor(.cyan)
            }
            .padding(.top, 8)
        }
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("YOUR JOURNEY")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.terminalGreen)
            
            if let stats = viewModel.journeyStats {
                VStack(spacing: 12) {
                    StatRow(label: "Chambers Completed", value: "\(stats.chambersCompleted)")
                    StatRow(label: "Total Time", value: stats.formattedTotalTime)
                    StatRow(label: "Hints Used", value: "\(stats.hintsUsed)")
                    StatRow(label: "Success Rate", value: String(format: "%.1f%%", stats.successRate))
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Share profile
            Button(action: { viewModel.generateShareImage(sessionId: sessionId) }) {
                HStack {
                    if viewModel.isGeneratingShareImage {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Your Profile")
                    }
                }
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(viewModel.isGeneratingShareImage)
            
            // Done button
            Button(action: { dismiss() }) {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - Trait Bar

struct TraitBar: View {
    let name: String
    let value: Double
    @State private var animatedValue: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(String(format: "%.0f", value))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
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
                                colors: colorForValue(animatedValue),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (animatedValue / 100.0), height: 8)
                }
            }
            .frame(height: 8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedValue = value
            }
        }
    }
    
    private func colorForValue(_ value: Double) -> [Color] {
        if value >= 75 {
            return [.green, .cyan]
        } else if value >= 50 {
            return [.yellow, .orange]
        } else {
            return [.orange, .red]
        }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct WizardRevealView_Previews: PreviewProvider {
    static var previews: some View {
        WizardRevealView(sessionId: "test-session")
            .preferredColorScheme(.dark)
    }
}
