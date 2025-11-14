import SwiftUI

/// Animated gradient background with subtle "breathing" motion
/// Creates liquid, living gradient effect inspired by swipe-app
struct AnimatedGradientBackground: View {
    let gradient: LinearGradient
    let animationSpeed: Double // seconds for full cycle

    @State private var animationPhase: CGFloat = 0

    /// Create animated gradient background
    /// - Parameters:
    ///   - gradient: The base gradient to animate
    ///   - animationSpeed: Duration of animation cycle in seconds (default: 25s for subtle motion)
    init(gradient: LinearGradient, animationSpeed: Double = 25) {
        self.gradient = gradient
        self.animationSpeed = animationSpeed
    }

    var body: some View {
        ZStack {
            // Base gradient (static)
            gradient

            // Animated overlay (subtle breathing motion)
            gradient
                .opacity(DesignTokens.Opacity.overlayStrong)
                .scaleEffect(1.2)
                .offset(
                    x: animationPhase * 50,
                    y: animationPhase * 30
                )
                .blur(radius: 30)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: animationSpeed)
                .repeatForever(autoreverses: true)
            ) {
                animationPhase = 1.0
            }
        }
    }
}

/// Convenience extension for card types
extension AnimatedGradientBackground {
    /// Create animated gradient for specific card type
    /// - Parameters:
    ///   - cardType: The card type to get gradient from ArchetypeConfig
    ///   - animationSpeed: Duration of animation cycle (default: 25s)
    init(for cardType: CardType, animationSpeed: Double = 25) {
        let config = ArchetypeConfig.config(for: cardType)
        self.init(gradient: config.gradient, animationSpeed: animationSpeed)
    }
}

#Preview {
    AnimatedGradientBackground(for: .mail)
        .ignoresSafeArea()
}
