import SwiftUI

/// Ambient floating particles for backgrounds
/// Creates subtle animated white dots that drift across the screen
struct FloatingParticles: View {
    let particleCount: Int
    let particleSize: CGFloat
    let speed: Double

    @State private var particleOffsets: [CGSize] = []
    @State private var particleOpacities: [Double] = []

    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<particleCount, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(particleOpacities.indices.contains(i) ? particleOpacities[i] : 0.2))
                    .frame(width: particleSize, height: particleSize)
                    .offset(particleOffsets.indices.contains(i) ? particleOffsets[i] : .zero)
            }
        }
        .onAppear {
            // Initialize random positions and opacities
            particleOffsets = (0..<particleCount).map { _ in
                CGSize(
                    width: CGFloat.random(in: -200...200),
                    height: CGFloat.random(in: -400...400)
                )
            }
            particleOpacities = (0..<particleCount).map { _ in
                Double.random(in: 0.1...0.3)
            }

            // Animate particles
            for i in 0..<particleCount {
                let randomDuration = Double.random(in: (speed - 1)...(speed + 1))
                let randomDelay = Double(i) * 0.1

                withAnimation(
                    .easeInOut(duration: randomDuration)
                    .repeatForever(autoreverses: true)
                    .delay(randomDelay)
                ) {
                    particleOffsets[i] = CGSize(
                        width: CGFloat.random(in: -200...200),
                        height: CGFloat.random(in: -400...400)
                    )
                }
            }
        }
    }
}
