import SwiftUI

struct CelebrationView: View {
    let archetype: CardType
    let allArchetypesCleared: Bool // New parameter for MAJOR celebration
    let onContinue: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var confettiPhase: CGFloat = 0
    @State private var showModelTuning = false
    
    var body: some View {
        ZStack {
            // Vibrant gradient (more intense for all cleared)
            LinearGradient(
                colors: allArchetypesCleared ? [
                    Color.vibrantYellow,  // Gold celebration
                    Color.vibrantPink,    // Pink
                    Color.vibrantBlue     // Blue
                ] : [
                    Color.celebrationPurpleBlue,
                    Color.celebrationDeepPurple,
                    Color.celebrationBrightPink
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Exploding confetti from center (MORE for all cleared)
            GeometryReader { geometry in
                ForEach(0..<(allArchetypesCleared ? 80 : 40), id: \.self) { i in
                    let angle = Double(i) * (360.0 / Double(allArchetypesCleared ? 80 : 40))
                    let velocity = CGFloat.random(in: allArchetypesCleared ? 250...500 : 200...400)
                    
                    Circle()
                        .fill([Color.vibrantYellow, Color.vibrantGreen, Color.vibrantBlue, Color.vibrantPink, Color.vibrantPurple, Color.vibrantOrange].randomElement()!)
                        .frame(width: CGFloat.random(in: 8...16))
                        .position(
                            x: geometry.size.width / 2 + cos(angle * .pi / 180) * velocity * confettiPhase,
                            y: geometry.size.height / 2 + sin(angle * .pi / 180) * velocity * confettiPhase
                        )
                        .opacity(1.0 - Double(confettiPhase * 0.8))
                        .scaleEffect(1.0 + confettiPhase * 0.5)
                        .rotationEffect(.degrees(Double(i) * 45 * Double(confettiPhase)))
                }
            }
            
            VStack(spacing: 30) {
                Image(systemName: allArchetypesCleared ? "trophy.fill" : "checkmark.circle.fill")
                    .font(.system(size: allArchetypesCleared ? 120 : 100))
                    .foregroundColor(allArchetypesCleared ? .yellow : .green)
                    .shadow(color: .black.opacity(0.3), radius: 10)
                
                Text(allArchetypesCleared ? "Total Inbox Zero!" : "Inbox Zero!")
                    .font(.system(size: allArchetypesCleared ? 54 : 48, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 5)
                
                if allArchetypesCleared {
                    Text("All Categories Cleared!")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 3)
                }
                
                Text("All done with \(archetype.displayName)")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))

                // Model Tuning Upsell (only for MAJOR celebration)
                if allArchetypesCleared {
                    VStack(spacing: 16) {
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                            Text("Level Up")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.7))
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 20)

                        // Unified Model Tuning Card
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "brain.head.profile")
                                    .font(.title2)
                                    .foregroundColor(.cyan)
                                Text("Train Zero's AI")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }

                            Text("Help Zero get smarter! Review how it categorizes emails and suggests actions. Your feedback trains the model to work better for you.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)

                            Button {
                                showModelTuning = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "slider.horizontal.3")
                                    Text("Open Model Tuning")
                                }
                            }
                            .buttonStyle(GradientButtonStyle(colors: [.vibrantCyan, .vibrantBlue, .vibrantPurple]))
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(Color.cyan.opacity(0.4), lineWidth: 2)
                                )
                        )
                        .padding(.horizontal, 32)
                    }
                }

                Button {
                    onContinue()
                } label: {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(.gradientPrimary)
                .padding(.top, 40)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Trigger confetti explosion with smooth ease-out
            withAnimation(.easeOut(duration: 2.5)) {
                confettiPhase = 1.0
            }

            // Scale in content with bouncy spring
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65, blendDuration: 0.2)) {
                scale = 1.0
                opacity = 1.0
            }

            // Success haptic with notification feedback
            let notification = UINotificationFeedbackGenerator()
            notification.prepare()
            notification.notificationOccurred(.success)
        }
        .sheet(isPresented: $showModelTuning) {
            ModelTuningView()
        }
    }

}

#Preview("Single Archetype") {
    CelebrationView(
        archetype: .mail,
        allArchetypesCleared: false,
        onContinue: {}
    )
}

#Preview("All Cleared") {
    CelebrationView(
        archetype: .ads,
        allArchetypesCleared: true,
        onContinue: {}
    )
}

