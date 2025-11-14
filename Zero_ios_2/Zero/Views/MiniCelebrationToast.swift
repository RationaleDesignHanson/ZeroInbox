import SwiftUI

struct MiniCelebrationToast: View {
    let archetype: CardType
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var yOffset: CGFloat = 100
    @State private var confettiPhase: CGFloat = 0

    var body: some View {
        ZStack {
            // Mini confetti burst (fewer particles)
            ForEach(0..<20, id: \.self) { i in
                let angle = Double(i) * (360.0 / 20.0)
                let velocity = CGFloat.random(in: 50...100)

                Circle()
                    .fill([Color.yellow, Color.green, Color.blue, Color.pink, Color.purple].randomElement()!)
                    .frame(width: CGFloat.random(in: 4...8))
                    .offset(
                        x: cos(angle * .pi / 180) * velocity * confettiPhase,
                        y: sin(angle * .pi / 180) * velocity * confettiPhase
                    )
                    .opacity(1.0 - Double(confettiPhase))
                    .scaleEffect(1.0 + confettiPhase * 0.3)
            }

            // Toast card
            HStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Nice work!")
                        .font(.headline.bold())
                        .foregroundColor(.white)

                    Text("\(archetype.displayName) cleared!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                }

                Spacer()
            }
            .padding(DesignTokens.Spacing.section)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
            )
            .frame(maxWidth: UIScreen.main.bounds.width - 48)
        }
        .offset(y: yOffset)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            // Confetti explosion
            withAnimation(.easeOut(duration: 1.5)) {
                confettiPhase = 1.0
            }

            // Toast slide up and scale in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
                yOffset = 0
            }

            // Light haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            // Auto-dismiss after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                    yOffset = -50
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.15),
                Color(red: 0.15, green: 0.15, blue: 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        MiniCelebrationToast(
            archetype: .mail,
            onDismiss: {}
        )
    }
}
