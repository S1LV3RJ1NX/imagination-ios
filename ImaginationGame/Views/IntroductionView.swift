//
//  IntroductionView.swift
//  ImaginationGame
//
//  4-screen onboarding experience with integrated purchase flow (Option C)
//

import StoreKit
import SwiftUI

// MARK: - Main Introduction View

struct IntroductionView: View {
    @State private var currentScreen = 0
    @State private var showSkipAlert = false
    @State private var showSkipPrompt = false
    @State private var hasCheckedSkip = false
    @StateObject private var storeManager = StoreManager.shared
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentScreen) {
                Screen1Welcome()
                    .tag(0)
                
                Screen2HowItWorks()
                    .tag(1)
                
                Screen3FinalPreparation(onNext: { currentScreen = 3 })
                    .tag(2)
                
                Screen4BeginJourney(
                    storeManager: storeManager,
                    onBeginJourney: {
                        UserDefaults.standard.set(true, forKey: "hasSeenIntro")
                        onComplete()
                    },
                    onNotYet: { showSkipAlert = true }
                )
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .alert("Not Ready Yet?", isPresented: $showSkipAlert) {
            Button("Continue Intro", role: .cancel) { }
            Button("Close App", role: .destructive) {
                exit(0)
            }
        } message: {
            Text("Take your time. The Chambers will be here when you're ready.")
        }
        .alert("Skip Introduction?", isPresented: $showSkipPrompt) {
            Button("Watch Again", role: .cancel) { }
            Button("Skip to Game") {
                if storeManager.isUnlocked {
                    UserDefaults.standard.set(true, forKey: "hasSeenIntro")
                    onComplete()
                } else {
                    // Jump to the final screen with purchase
                    currentScreen = 3
                }
            }
        } message: {
            Text("You've seen the introduction before. Would you like to skip directly to the first chamber?")
        }
        .onAppear {
            if !hasCheckedSkip {
                hasCheckedSkip = true
                let hasSeenIntro = UserDefaults.standard.bool(forKey: "hasSeenIntro")
                if hasSeenIntro {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showSkipPrompt = true
                    }
                }
            }
        }
    }
}

// MARK: - Screen 1: Welcome

struct Screen1Welcome: View {
    @State private var glowing = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Title
            Text("IMAGINATION")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.terminalGreen)
                .shadow(color: .terminalGreen.opacity(glowing ? 0.8 : 0.3), radius: 10)
            
            // Doors
            HStack(spacing: 20) {
                Text("🚪")
                Text("🚪")
                Text("🚪")
            }
            .font(.system(size: 48))
            
            Text("[The Chambers]")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.gray)
            
            // Body text - centered
            VStack(spacing: 16) {
                IntroText("You are about to enter a series of mysterious chambers.")
                IntroText("Each will test you in different ways.")
                IntroText("But this is not just puzzles.")
                IntroText("This is a journey of self-discovery.")
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 32)
            
            Text("← Swipe to continue →")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray.opacity(0.6))
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowing = true
            }
        }
    }
}

// MARK: - Screen 2: How This Works

struct Screen2HowItWorks: View {
    @State private var showSection1 = false
    @State private var showSection2 = false
    @State private var showSection3 = false
    @State private var showSection4 = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("HOW THIS WORKS")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.terminalGreen)
                    .padding(.top, 24)
                
                Divider()
                    .background(Color.terminalGreen.opacity(0.3))
                    .padding(.bottom, 4)
                
                // Section 1
                FeatureSection(
                    icon: "🧩",
                    title: "20 UNIQUE CHAMBERS",
                    description: "Each tests your mind in different ways: logic, creativity, empathy, and more.",
                    isVisible: showSection1
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Section 2
                FeatureSection(
                    icon: "🧠",
                    title: "YOUR CHOICES MATTER",
                    description: "Some chambers have no \"wrong\" answer. What matters is HOW you choose.",
                    isVisible: showSection2
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Section 3
                FeatureSection(
                    icon: "📖",
                    title: "A STORY UNFOLDS",
                    description: "Your journal updates after each chamber, revealing the mystery.",
                    isVisible: showSection3
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Section 4
                FeatureSection(
                    icon: "🧙",
                    title: "THE FINAL REVEAL",
                    description: "The Wizard shows who you truly are.",
                    isVisible: showSection4
                )
                
                Text("← Swipe to continue →")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.top, 24)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5).delay(0.0)) { showSection1 = true }
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) { showSection2 = true }
            withAnimation(.easeIn(duration: 0.5).delay(0.6)) { showSection3 = true }
            withAnimation(.easeIn(duration: 0.5).delay(0.9)) { showSection4 = true }
        }
    }
}

// MARK: - Screen 3: Final Preparation (Hints & Info)

struct Screen3FinalPreparation: View {
    let onNext: () -> Void
    @State private var buttonGlowing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("BEFORE YOU BEGIN")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.terminalGreen)
                    .padding(.top, 24)
                
                Divider()
                    .background(Color.terminalGreen.opacity(0.3))
                    .padding(.bottom, 4)
                
                // Info sections
                VStack(spacing: 20) {
                    InfoSection(
                        icon: "💡",
                        title: "HINTS ARE AVAILABLE",
                        description: "If you get stuck, hints unlock after a few attempts. They're free—but tracked in your profile."
                    )
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    InfoSection(
                        icon: "📖",
                        title: "JOURNAL UPDATES",
                        description: "After each chamber, your journal updates with story entries and personality insights."
                    )
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    InfoSection(
                        icon: "⏱️",
                        title: "TAKE YOUR TIME",
                        description: "There's no timer. No rush. Explore, think, and choose deliberately."
                    )
                }
                
                Text("← Swipe for final message →")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.top, 24)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Screen 4: Begin Journey (with integrated purchase)

struct Screen4BeginJourney: View {
    @ObservedObject var storeManager: StoreManager
    let onBeginJourney: () -> Void
    let onNotYet: () -> Void
    @State private var warningPulsing = false
    @State private var buttonGlowing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Warning header
                Text("⚠️ IMPORTANT ⚠️")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                    .scaleEffect(warningPulsing ? 1.1 : 1.0)
                    .padding(.top, 24)
                
                Divider()
                    .background(Color.orange.opacity(0.3))
                    .padding(.bottom, 4)
                
                // Main message
                VStack(spacing: 14) {
                    Text("ONE JOURNEY, ONE TRUTH")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    IntroText("Once you enter a chamber, you CANNOT go back.")
                    IntroText("Your decisions are permanent.")
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.vertical, 4)
                    
                    IntroText("This isn't about finding the \"right\" answer.")
                    IntroText("It's about discovering YOUR answer.")
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        BulletPoint("NO SAVE POINTS")
                        BulletPoint("NO DO-OVERS")
                        BulletPoint("JUST YOU AND YOUR CHOICES")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.vertical, 4)
                    
                    Text("Ready to discover who you are?")
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                // Buttons
                VStack(spacing: 16) {
                    // Primary: Begin Journey (with price if not yet purchased)
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        if storeManager.isUnlocked {
                            // Already purchased — go straight in
                            onBeginJourney()
                        } else {
                            // Trigger Apple payment sheet directly
                            Task {
                                await storeManager.purchase()
                                if storeManager.isUnlocked {
                                    onBeginJourney()
                                }
                            }
                        }
                    }) {
                        HStack {
                            if storeManager.isPurchasing {
                                ProgressView()
                                    .tint(.black)
                                    .padding(.trailing, 4)
                            }
                            
                            Text(purchaseButtonText)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.71, blue: 0.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: buttonGlowing ? .yellow.opacity(0.8) : .yellow.opacity(0.3), radius: 15)
                        .scaleEffect(buttonGlowing ? 1.02 : 1.0)
                    }
                    .disabled(storeManager.isPurchasing)
                    
                    // Error message
                    if let error = storeManager.errorMessage {
                        Text(error)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Not Yet button
                    Button(action: onNotYet) {
                        Text("Not Yet")
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
                    
                    // Restore Purchase link
                    Button(action: {
                        Task {
                            await storeManager.restorePurchases()
                            if storeManager.isUnlocked {
                                onBeginJourney()
                            }
                        }
                    }) {
                        Text("Restore Purchase")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.gray)
                            .underline()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                warningPulsing = true
                buttonGlowing = true
            }
        }
    }
    
    private var purchaseButtonText: String {
        if storeManager.isPurchasing {
            return "Purchasing..."
        }
        if storeManager.isUnlocked {
            return "Begin Journey"
        }
        if let product = storeManager.product {
            return "Begin Journey — \(product.displayPrice)"
        }
        return "Begin Journey — $2.99"
    }
}

// MARK: - Reusable Components

struct IntroText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 15, design: .monospaced))
            .foregroundColor(.white.opacity(0.9))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }
}

struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.orange)
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

struct FeatureSection: View {
    let icon: String
    let title: String
    let description: String
    let isVisible: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Text(icon)
                .font(.system(size: 32))
                .opacity(isVisible ? 1.0 : 0.0)
            
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.terminalGreen)
            
            Text(description)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
        .opacity(isVisible ? 1.0 : 0.0)
    }
}

struct InfoSection: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 10) {
            Text(icon)
                .font(.system(size: 32))
            
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.terminalGreen)
            
            Text(description)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Preview

struct IntroductionView_Previews: PreviewProvider {
    static var previews: some View {
        IntroductionView(onComplete: {})
            .preferredColorScheme(.dark)
    }
}
