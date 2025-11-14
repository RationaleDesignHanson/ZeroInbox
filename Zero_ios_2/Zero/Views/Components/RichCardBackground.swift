import SwiftUI

/// Rich card background with visually stunning effects
/// MAIL: Nebula/galaxy with animated particles and color shifting
/// ADS: Scenic nature backgrounds (forest, mountains, etc.)
struct RichCardBackground: View {
    let cardType: CardType
    let animationSpeed: Double

    @State private var animationPhase: CGFloat = 0
    @State private var particleOffsets: [CGSize] = []
    @State private var particleOpacities: [Double] = []

    init(for cardType: CardType, animationSpeed: Double = 30) {
        self.cardType = cardType
        self.animationSpeed = animationSpeed
    }

    var body: some View {
        ZStack {
            switch cardType {
            case .mail:
                // Nebula/Galaxy background with animated particles
                NebulaBackground(
                    animationPhase: animationPhase,
                    particleOffsets: $particleOffsets,
                    particleOpacities: $particleOpacities
                )

            case .ads:
                // Scenic nature background (forest/mountain aesthetic)
                ScenicBackground(animationPhase: animationPhase)
            }
        }
        .onAppear {
            // Initialize particles for nebula
            if cardType == .mail {
                particleOffsets = (0..<40).map { _ in
                    CGSize(
                        width: CGFloat.random(in: -150...150),
                        height: CGFloat.random(in: -200...200)
                    )
                }
                particleOpacities = (0..<40).map { _ in
                    Double.random(in: 0.1...0.5)
                }
            }

            // Start animation
            withAnimation(
                .easeInOut(duration: animationSpeed)
                .repeatForever(autoreverses: true)
            ) {
                animationPhase = 1.0
            }
        }
    }
}

// MARK: - Nebula Background (MAIL)

/// Deep space nebula effect with glowing particles and color shifts
struct NebulaBackground: View {
    let animationPhase: CGFloat
    @Binding var particleOffsets: [CGSize]
    @Binding var particleOpacities: [Double]

    var body: some View {
        ZStack {
            // Deep space base
            Color.black.opacity(DesignTokens.Opacity.textSecondary)

            // Nebula clouds - layered gradients with different colors
            RadialGradient(
                colors: [
                    Color(red: 0.2, green: 0.1, blue: 0.4, opacity: 0.6), // Deep purple
                    Color(red: 0.1, green: 0.15, blue: 0.3, opacity: 0.3), // Dark blue
                    Color.clear
                ],
                center: .init(x: 0.3, y: 0.4),
                startRadius: 0,
                endRadius: 300
            )
            .scaleEffect(1.0 + animationPhase * 0.1)
            .blur(radius: 60)

            RadialGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.6, opacity: 0.5), // Bright purple
                    Color(red: 0.2, green: 0.3, blue: 0.7, opacity: 0.3), // Blue-purple
                    Color.clear
                ],
                center: .init(x: 0.7, y: 0.6),
                startRadius: 0,
                endRadius: 250
            )
            .scaleEffect(1.0 + animationPhase * 0.15)
            .blur(radius: 50)
            .offset(x: animationPhase * 20, y: animationPhase * -15)

            RadialGradient(
                colors: [
                    Color(red: 0.1, green: 0.4, blue: 0.7, opacity: 0.4), // Cyan-blue
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.2),
                startRadius: 0,
                endRadius: 200
            )
            .scaleEffect(1.0 + animationPhase * 0.12)
            .blur(radius: 40)
            .offset(x: animationPhase * -15, y: animationPhase * 20)

            // Stars/particles
            GeometryReader { geometry in
                ForEach(0..<particleOffsets.count, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(particleOpacities.indices.contains(i) ? particleOpacities[i] : 0.3))
                        .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                        .offset(particleOffsets.indices.contains(i) ? particleOffsets[i] : .zero)
                        .blur(radius: 0.5)
                }
            }

            // Glowing nebula highlights
            RadialGradient(
                colors: [
                    Color(red: 0.6, green: 0.3, blue: 0.8, opacity: 0.3), // Bright magenta
                    Color.clear
                ],
                center: .init(x: 0.2, y: 0.7),
                startRadius: 0,
                endRadius: 150
            )
            .scaleEffect(1.0 + animationPhase * 0.2)
            .blur(radius: 30)
            .blendMode(.screen)
        }
    }
}

// MARK: - Scenic Background (ADS)

/// Lighter liquid glass galaxy aesthetic for shopping/promotional content
/// Differentiates from Mail's darker nebula with brighter, airier cosmic tones
struct ScenicBackground: View {
    let animationPhase: CGFloat

    var body: some View {
        ZStack {
            // Lighter base (soft cosmic gradient)
            LinearGradient(
                colors: [
                    Color(red: 0.25, green: 0.35, blue: 0.50), // Brighter cosmic blue
                    Color(red: 0.30, green: 0.40, blue: 0.55), // Lighter blue-purple
                    Color(red: 0.35, green: 0.45, blue: 0.60)  // Airy periwinkle
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Liquid glass clouds - lighter, more ethereal
            RadialGradient(
                colors: [
                    Color(red: 0.50, green: 0.60, blue: 0.80, opacity: 0.5), // Soft sky blue
                    Color(red: 0.40, green: 0.50, blue: 0.70, opacity: 0.3), // Light periwinkle
                    Color.clear
                ],
                center: .init(x: 0.3, y: 0.5),
                startRadius: 0,
                endRadius: 300
            )
            .scaleEffect(1.0 + animationPhase * 0.08)
            .blur(radius: 50)

            RadialGradient(
                colors: [
                    Color(red: 0.45, green: 0.55, blue: 0.75, opacity: 0.4), // Airy blue
                    Color(red: 0.50, green: 0.45, blue: 0.70, opacity: 0.25), // Light lavender
                    Color.clear
                ],
                center: .init(x: 0.7, y: 0.4),
                startRadius: 0,
                endRadius: 250
            )
            .scaleEffect(1.0 + animationPhase * 0.1)
            .blur(radius: 40)
            .offset(x: animationPhase * -10, y: animationPhase * 15)

            // Bright accent glow (liquid glass shimmer)
            RadialGradient(
                colors: [
                    Color(red: 0.60, green: 0.70, blue: 0.90, opacity: 0.35), // Bright sky blue
                    Color(red: 0.55, green: 0.65, blue: 0.85, opacity: 0.2), // Soft cyan
                    Color.clear
                ],
                center: .init(x: 0.8, y: 0.2),
                startRadius: 0,
                endRadius: 200
            )
            .scaleEffect(1.0 + animationPhase * 0.15)
            .blur(radius: 35)
            .blendMode(.screen)

            // Subtle depth layer (lighter cosmic mist)
            LinearGradient(
                colors: [
                    Color.clear,
                    Color(red: 0.35, green: 0.45, blue: 0.60, opacity: 0.3), // Light cosmic blue
                    Color(red: 0.30, green: 0.40, blue: 0.55, opacity: 0.4)  // Soft depth
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .offset(y: animationPhase * 5)
            .blur(radius: 20)
        }
    }
}

#Preview("MAIL - Nebula") {
    RichCardBackground(for: .mail)
        .ignoresSafeArea()
}

#Preview("ADS - Scenic") {
    RichCardBackground(for: .ads)
        .ignoresSafeArea()
}
