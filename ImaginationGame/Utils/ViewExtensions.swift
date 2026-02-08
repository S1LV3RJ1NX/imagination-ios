//
//  ViewExtensions.swift
//  ImaginationGame
//
//  Custom view modifiers and extensions for consistent UI
//

import SwiftUI

// MARK: - Custom Transitions

extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var scaleAndFade: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }
    
    static var bottomSlide: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
}

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    var backgroundColor: Color = Color.terminalGreen.opacity(0.05)
    var borderColor: Color = Color.terminalGreen.opacity(0.3)
    var cornerRadius: CGFloat = 12
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .cornerRadius(cornerRadius)
    }
}

extension View {
    func cardStyle(
        backgroundColor: Color = Color.terminalGreen.opacity(0.05),
        borderColor: Color = Color.terminalGreen.opacity(0.3),
        cornerRadius: CGFloat = 12
    ) -> some View {
        modifier(CardStyle(
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            cornerRadius: cornerRadius
        ))
    }
}

// MARK: - Glow Effect

struct GlowEffect: ViewModifier {
    var color: Color
    var radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius)
    }
}

extension View {
    func glow(color: Color = .terminalGreen, radius: CGFloat = 10) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.3)
                    .offset(x: geometry.size.width * phase)
                }
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 2.0)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1.0
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Press Animation

struct PressAnimation: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

extension View {
    func withPressAnimation() -> some View {
        modifier(PressAnimation())
    }
}

// MARK: - Fade In On Appear

struct FadeInOnAppear: ViewModifier {
    @State private var opacity: Double = 0
    var duration: Double
    var delay: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: duration).delay(delay)) {
                    opacity = 1.0
                }
            }
    }
}

extension View {
    func fadeInOnAppear(duration: Double = 0.5, delay: Double = 0) -> some View {
        modifier(FadeInOnAppear(duration: duration, delay: delay))
    }
}

// MARK: - Slide In On Appear

struct SlideInOnAppear: ViewModifier {
    @State private var offset: CGFloat = 50
    @State private var opacity: Double = 0
    var duration: Double
    var delay: Double
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: duration, dampingFraction: 0.7).delay(delay)) {
                    offset = 0
                    opacity = 1.0
                }
            }
    }
}

extension View {
    func slideInOnAppear(duration: Double = 0.6, delay: Double = 0) -> some View {
        modifier(SlideInOnAppear(duration: duration, delay: delay))
    }
}

// MARK: - Pulse Animation

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    var minScale: CGFloat
    var maxScale: CGFloat
    var duration: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? maxScale : minScale)
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulse(minScale: CGFloat = 1.0, maxScale: CGFloat = 1.05, duration: Double = 1.0) -> some View {
        modifier(PulseAnimation(minScale: minScale, maxScale: maxScale, duration: duration))
    }
}

// MARK: - Conditional Modifiers

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
