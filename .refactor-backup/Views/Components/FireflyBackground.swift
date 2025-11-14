import SwiftUI

/// Firefly background matching the website design
/// Creates floating particles with subtle glow effects on a multi-color gradient
struct FireflyBackground: View {
    @State private var fireflies: [Firefly] = []

    var body: some View {
        ZStack {
            // Base gradient matching website colors
            // linear-gradient(135deg, #1a1a2e 0%, #2d1b4e 30%, #4a1942 60%, #1f1f3a 100%)
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "2d1b4e"),
                    Color(hex: "4a1942"),
                    Color(hex: "1f1f3a")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Firefly particles
            ForEach(fireflies) { firefly in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                firefly.color.opacity(firefly.opacity),
                                firefly.color.opacity(firefly.opacity * 0.5),
                                firefly.color.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: firefly.size
                        )
                    )
                    .frame(width: firefly.size, height: firefly.size)
                    .blur(radius: firefly.blur)
                    .position(firefly.position)
                    .opacity(firefly.currentOpacity)
        }
        }
        .ignoresSafeArea()
        .onAppear {
            generateFireflies()
            startAnimation()
        }
    }

    private func generateFireflies() {
        // Generate 40 small/medium fireflies + 6 large orbs
        var newFireflies: [Firefly] = []

        // Small, medium, and warm fireflies (40 total)
        for i in 0..<40 {
            let rand = Double.random(in: 0...1)
            let type: FireflyType = rand < 0.33 ? .small : rand < 0.66 ? .medium : .warm
            newFireflies.append(Firefly(type: type, index: i))
        }

        // Large ambient orbs (6 total)
        for i in 0..<6 {
            newFireflies.append(Firefly(type: .orb, index: i + 40))
        }

        fireflies = newFireflies
    }

    private func startAnimation() {
        for i in 0..<fireflies.count {
            animateFirefly(index: i)
        }
    }

    private func animateFirefly(index: Int) {
        guard index < fireflies.count else { return }

        let duration = fireflies[index].duration
        let delay = Double.random(in: 0...duration)

        // Animate opacity
        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            fireflies[index].currentOpacity = Double.random(in: 0.3...0.9)
        }

        // Animate position
        Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { _ in
            guard index < fireflies.count else { return }

            withAnimation(.easeInOut(duration: duration)) {
                let moveRange = fireflies[index].type == .orb ? 80.0 : 70.0
                fireflies[index].position.x += CGFloat.random(in: -moveRange...moveRange)
                fireflies[index].position.y += CGFloat.random(in: -moveRange...moveRange)

                // Keep within screen bounds
                fireflies[index].position.x = max(0, min(UIScreen.main.bounds.width, fireflies[index].position.x))
                fireflies[index].position.y = max(0, min(UIScreen.main.bounds.height, fireflies[index].position.y))
            }
        }
    }
}

// MARK: - Firefly Model

enum FireflyType {
    case small, medium, warm, orb
}

struct Firefly: Identifiable {
    let id = UUID()
    let type: FireflyType
    let color: Color
    let size: CGFloat
    let blur: CGFloat
    let opacity: Double
    let duration: Double
    var position: CGPoint
    var currentOpacity: Double

    init(type: FireflyType, index: Int) {
        self.type = type

        // Set properties based on type (matching website CSS)
        switch type {
        case .small:
            // rgba(147, 197, 253, 1) - blue fireflies
            self.color = Color(red: 147/255, green: 197/255, blue: 253/255)
            self.size = 3
            self.blur = 5
            self.opacity = 0.8

        case .medium:
            // rgba(196, 181, 253, 1) - purple fireflies
            self.color = Color(red: 196/255, green: 181/255, blue: 253/255)
            self.size = 5
            self.blur = 7.5
            self.opacity = 0.9

        case .warm:
            // rgba(251, 191, 36, 1) - amber/orange fireflies
            self.color = Color(red: 251/255, green: 191/255, blue: 36/255)
            self.size = 4
            self.blur = 6
            self.opacity = 0.9

        case .orb:
            // rgba(139, 92, 246, 0.15) - large purple orbs
            self.color = Color(red: 139/255, green: 92/255, blue: 246/255)
            self.size = 200
            self.blur = 40
            self.opacity = 0.15
        }

        // Random initial position
        self.position = CGPoint(
            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
        )

        // Random animation duration (8-20s for organic feel, longer for orbs)
        self.duration = type == .orb
            ? Double.random(in: 20...35)
            : Double.random(in: 8...20)

        // Start with random opacity
        self.currentOpacity = Double.random(in: 0.3...0.9)
    }
}

