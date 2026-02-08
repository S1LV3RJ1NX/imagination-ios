//
//  LoadingView.swift
//  ImaginationGame
//
//  Beautiful loading states with terminal aesthetic
//

import SwiftUI

struct LoadingView: View {
    let message: String
    @State private var dotCount = 0
    @State private var glowing = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated dots
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.terminalGreen)
                        .frame(width: 12, height: 12)
                        .scaleEffect(dotCount == index ? 1.3 : 1.0)
                        .opacity(dotCount == index ? 1.0 : 0.5)
                }
            }
            
            // Message
            Text(message)
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.terminalGreen)
                .shadow(color: glowing ? .terminalGreen.opacity(0.8) : .terminalGreen.opacity(0.3), radius: 10)
        }
        .onAppear {
            // Animate dots
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    dotCount = (dotCount + 1) % 3
                }
            }
            
            // Pulsing glow
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowing = true
            }
        }
    }
}

struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            LoadingView(message: message)
        }
    }
}

// MARK: - Preview

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LoadingView(message: "Loading...")
        }
    }
}
