//
//  JournalUnlockNotification.swift
//  ImaginationGame
//
//  Toast notification for journal chapter unlocks
//  Appears at top of screen with animation
//

import SwiftUI

struct JournalUnlockNotification: View {
    let chapterName: String
    @Binding var isShowing: Bool
    let onTap: () -> Void
    
    @State private var offset: CGFloat = -200
    @State private var opacity: Double = 0
    
    var body: some View {
        if isShowing {
            VStack {
                HStack(spacing: 12) {
                    // Icon
                    Text("📖")
                        .font(.system(size: 24))
                    
                    // Text
                    VStack(alignment: .leading, spacing: 4) {
                        Text("JOURNAL UNLOCKED")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.terminalGreen)
                        
                        Text(chapterName)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("Tap to read")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.terminalGreen.opacity(0.6))
                            .italic()
                    }
                    
                    Spacer()
                    
                    // Arrow indicating it's tappable
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.terminalGreen.opacity(0.7))
                }
                .padding(16)
                .background(
                    Color.black.opacity(0.95)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.terminalGreen.opacity(0.7), lineWidth: 2)
                )
                .cornerRadius(8)
                .shadow(color: .terminalGreen.opacity(0.5), radius: 20)
                .padding(.horizontal)
                
                Spacer()
            }
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                showNotification()
            }
            .onTapGesture {
                print("📖 Notification tapped!")
                hideNotification()
                // Wait for hide animation to complete before calling onTap
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onTap()
                }
            }
        }
    }
    
    private func showNotification() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Animate in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            offset = 60 // Safe area + padding
            opacity = 1.0
        }
        
        // Auto-dismiss after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            if isShowing {
                hideNotification()
            }
        }
    }
    
    private func hideNotification() {
        withAnimation(.easeOut(duration: 0.3)) {
            offset = -200
            opacity = 0
        }
        
        // Reset state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}

// MARK: - Preview

struct JournalUnlockNotification_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            JournalUnlockNotification(
                chapterName: "The First Door",
                isShowing: .constant(true),
                onTap: { print("Tapped") }
            )
        }
    }
}
