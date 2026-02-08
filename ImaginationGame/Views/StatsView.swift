//
//  StatsView.swift
//  ImaginationGame
//
//  Full personality profile with all 12 traits
//  Detailed journey statistics
//

import SwiftUI

struct StatsView: View {
    @StateObject private var viewModel = WizardViewModel()
    let sessionId: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else {
                    statsContent
                }
            }
        }
        .onAppear {
            if !viewModel.isRevealed {
                viewModel.loadWizardReveal(sessionId: sessionId)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("BACK")
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.terminalGreen.opacity(0.7))
                }
                
                Spacer()
            }
            
            Text("📊 YOUR PROFILE")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.terminalGreen)
                .shadow(color: .terminalGreen, radius: 10)
            
            if let archetype = viewModel.archetype {
                Text(archetype.name)
                    .font(.system(size: 16, design: .serif))
                    .foregroundColor(.yellow)
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
    
    // MARK: - Loading & Error
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .terminalGreen))
                .scaleEffect(1.5)
            
            Text("Loading Profile...")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.terminalGreen.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.terminalBlack)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.terminalBlack)
    }
    
    // MARK: - Stats Content
    
    private var statsContent: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Archetype description
                if let archetype = viewModel.archetype {
                    archetypeCard(archetype)
                }
                
                // All traits (12 total)
                traitSection
                
                // Journey statistics
                journeySection
                
                // Share button
                shareButton
            }
            .padding(24)
        }
        .background(Color.terminalBlack)
    }
    
    private func archetypeCard(_ archetype: Archetype) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🧙")
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Archetype")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    Text(archetype.name)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundColor(.yellow)
                }
                
                Spacer()
            }
            
            Text(archetype.description)
                .font(.system(size: 14, design: .serif))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
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
            Text("PERSONALITY TRAITS")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.terminalGreen)
            
            VStack(spacing: 12) {
                ForEach(viewModel.traitBreakdown, id: \.name) { trait in
                    TraitBar(name: trait.name, value: trait.value)
                }
            }
        }
    }
    
    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("JOURNEY STATISTICS")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.terminalGreen)
            
            if let stats = viewModel.journeyStats {
                VStack(spacing: 0) {
                    StatDetailRow(
                        icon: "checkmark.circle.fill",
                        label: "Chambers Completed",
                        value: "\(stats.chambersCompleted) / 20",
                        color: .green
                    )
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    StatDetailRow(
                        icon: "clock.fill",
                        label: "Total Time",
                        value: stats.formattedTotalTime,
                        color: .cyan
                    )
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    StatDetailRow(
                        icon: "lightbulb.fill",
                        label: "Hints Used",
                        value: "\(stats.hintsUsed)",
                        color: .yellow
                    )
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    StatDetailRow(
                        icon: "target",
                        label: "Wrong Attempts",
                        value: "\(stats.wrongAttempts)",
                        color: .red
                    )
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    StatDetailRow(
                        icon: "chart.line.uptrend.xyaxis",
                        label: "Success Rate",
                        value: String(format: "%.1f%%", stats.successRate),
                        color: .green
                    )
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    StatDetailRow(
                        icon: "gamecontroller.fill",
                        label: "Total Actions",
                        value: "\(stats.totalActions)",
                        color: .purple
                    )
                }
                .background(Color.terminalGreen.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.terminalGreen.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(12)
                
                // Averages
                VStack(spacing: 8) {
                    HStack {
                        Text("Avg. Time per Chamber:")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(formatTime(stats.averageTimePerChamber))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Avg. Hints per Chamber:")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "%.1f", stats.averageHintsPerChamber))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.terminalDarkGray.opacity(0.3))
                .cornerRadius(8)
            }
        }
    }
    
    private var shareButton: some View {
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
            .shadow(color: .yellow.opacity(0.3), radius: 10)
        }
        .disabled(viewModel.isGeneratingShareImage)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%dm %ds", mins, secs)
    }
}

// MARK: - Stat Detail Row

struct StatDetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(label)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.terminalGreen)
        }
        .padding()
    }
}

// MARK: - Preview

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StatsView(sessionId: "test-session")
        }
        .preferredColorScheme(.dark)
    }
}
