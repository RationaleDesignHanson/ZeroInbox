import SwiftUI

struct LoadingView: View {
    @State private var animationProgress: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationDegrees: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        ZStack {
            // Gradient background matching SplashView and app theme
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.49, blue: 0.91),
                    Color(red: 0.46, green: 0.29, blue: 0.64),
                    Color(red: 0.94, green: 0.58, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all, edges: .all)

            // Floating particles matching SplashView
            FloatingParticles(particleCount: 20, particleSize: 4, speed: 3)

            VStack(spacing: 40) {
                Spacer()

                // Animated logo/icon
                ZStack {
                    // Outer rotating ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(rotationDegrees))
                        .opacity(0.6)

                    // Middle pulsing circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseScale)

                    // Center icon with shimmer effect
                    ZStack {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 50, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .blue.opacity(0.8), .white],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        // Shimmer overlay
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.3),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .offset(x: shimmerOffset)
                            .mask(
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 50, weight: .light))
                            )
                    }
                }

                // App name matching SplashView branding
                VStack(spacing: 12) {
                    Text("zero")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Clear your inbox fast")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }

                // Loading progress indicator
                VStack(spacing: 16) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)

                            // Animated progress
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * animationProgress, height: 6)
                                .overlay(
                                    // Shine effect
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    .clear,
                                                    .white.opacity(0.5),
                                                    .clear
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 50)
                                        .offset(x: geometry.size.width * animationProgress - 25)
                                )
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 50)

                    // Loading text
                    Text(loadingText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Bottom tagline
                Text("AI-Powered Email Management")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 40)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Computed Properties

    var loadingText: String {
        let progress = Int(animationProgress * 100)

        switch progress {
        case 0..<20:
            return "Initializing..."
        case 20..<40:
            return "Connecting to services..."
        case 40..<60:
            return "Loading your inbox..."
        case 60..<80:
            return "Analyzing emails..."
        case 80..<95:
            return "Almost ready..."
        default:
            return "Ready!"
        }
    }

    // MARK: - Animations

    func startAnimations() {
        // Progress bar animation (smooth and deterministic)
        withAnimation(.easeInOut(duration: 2.5)) {
            animationProgress = 1.0
        }

        // Pulse animation (continuous)
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }

        // Rotation animation (continuous)
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            rotationDegrees = 360
        }

        // Shimmer animation (continuous sweep)
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            shimmerOffset = 200
        }
    }
}

// MARK: - Preview

#if DEBUG
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
#endif
