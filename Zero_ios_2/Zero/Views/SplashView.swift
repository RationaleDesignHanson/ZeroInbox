import SwiftUI

struct SplashView: View {
    let onComplete: () -> Void
    @State private var password = ""
    @State private var showPassword = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var useMockData = false // Toggle for mock vs real data (default to real)
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAuthenticating = false
    @EnvironmentObject var services: ServiceContainer
    @State private var hasSeenSplash = UserDefaults.standard.bool(forKey: "hasSeenSplash")
    @State private var showLoadingScreen = false
    
    var body: some View {
        ZStack {
            // Show loading screen on first launch
            if showLoadingScreen {
                LoadingView()
                    .transition(.opacity)
                    .zIndex(1000)
            }

            // Firefly background (same as mail section)
            FireflyBackground()
                .ignoresSafeArea()

            // Floating particles
            FloatingParticles(particleCount: 20, particleSize: 4, speed: 3)
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo: 10000 (matching web exactly)
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Text("10")
                            .font(.system(size: 70, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(DesignTokens.Opacity.overlayLight)
                            .blur(radius: 2)
                        
                        Text("0")
                            .font(.system(size: 70, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.376, green: 0.647, blue: 0.980),
                                        Color(red: 0.655, green: 0.333, blue: 0.965)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(DesignTokens.Radius.card)
                            .shadow(color: .black.opacity(DesignTokens.Opacity.overlayMedium), radius: 10)
                        
                        Text("00")
                            .font(.system(size: 70, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(DesignTokens.Opacity.overlayLight)
                            .blur(radius: 2)
                    }
                    
                    Text("zero")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: -7)
                }
                
                VStack(spacing: 8) {
                    Text("Clear your inbox fast.")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("Swipe to keep, act, or archive for later.")
                        .font(.body)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))

                    // Build version info
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "100"))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayMedium))
                        .padding(.top, 4)
                }

                Spacer()

                // Authentication Options - Horizontal Bottom Nav Style
                HStack(spacing: 12) {
                    // Mock Data Button
                    Button {
                        // Set mock mode
                        UserDefaults.standard.set(true, forKey: "useMockData")
                        if let analytics = services.analyticsService as? AnalyticsService {
                            analytics.dataMode = "mock"
                        }
                        services.settings.useMockData = true

                        // Mark splash as seen and proceed
                        UserDefaults.standard.set(true, forKey: "hasSeenSplash")
                        Logger.info("Mock data mode selected, analytics environment: mock", category: .app)
                        onComplete()
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                // Glow effect
                                Circle()
                                    .fill(Color.orange.opacity(DesignTokens.Opacity.overlayLight))
                                    .frame(width: 44, height: 44)
                                    .blur(radius: 8)

                                // Icon background
                                Circle()
                                    .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.orange.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                    )

                                // Icon
                                Image(systemName: "text.book.closed.fill")
                                    .font(.title3)
                                    .foregroundColor(.orange)
                            }

                            Text("Mock")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Google OAuth Button
                    Button {
                        isAuthenticating = true
                        Task {
                            do {
                                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                      let window = windowScene.windows.first else {
                                    throw NSError(domain: "SplashView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot find window"])
                                }

                                let email = try await EmailAPIService.shared.authenticateGmail(presentationAnchor: window)
                                await MainActor.run {
                                    // Set real data mode
                                    UserDefaults.standard.set(false, forKey: "useMockData")
                                    if let analytics = services.analyticsService as? AnalyticsService {
                                        analytics.dataMode = "real"
                                    }
                                    services.settings.useMockData = false

                                    // Mark splash as seen
                                    UserDefaults.standard.set(true, forKey: "hasSeenSplash")

                                    isAuthenticating = false
                                    Logger.info("Google OAuth completed, analytics environment: real", category: .app)
                                    Logger.info("Authenticated as: \(email)", category: .app)
                                    onComplete()
                                }
                            } catch {
                                await MainActor.run {
                                    isAuthenticating = false
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        }
                    } label: {
                        VStack(spacing: 6) {
                            if isAuthenticating {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                        .frame(width: 44, height: 44)

                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            } else {
                                ZStack {
                                    // Glow effect
                                    Circle()
                                        .fill(Color.blue.opacity(DesignTokens.Opacity.overlayLight))
                                        .frame(width: 44, height: 44)
                                        .blur(radius: 8)

                                    // Icon background
                                    Circle()
                                        .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color.blue.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                        )

                                    // Icon
                                    Image(systemName: "g.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                            }

                            Text(isAuthenticating ? "Wait..." : "Google")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(isAuthenticating)
                    .opacity(isAuthenticating ? DesignTokens.Opacity.overlayStrong : DesignTokens.Opacity.textPrimary)

                    // Microsoft OAuth Button
                    Button {
                        isAuthenticating = true
                        Task {
                            do {
                                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                      let window = windowScene.windows.first else {
                                    throw NSError(domain: "SplashView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot find window"])
                                }

                                let email = try await EmailAPIService.shared.authenticateMicrosoft(presentationAnchor: window)
                                await MainActor.run {
                                    // Set real data mode
                                    UserDefaults.standard.set(false, forKey: "useMockData")
                                    if let analytics = services.analyticsService as? AnalyticsService {
                                        analytics.dataMode = "real"
                                    }
                                    services.settings.useMockData = false

                                    // Mark splash as seen
                                    UserDefaults.standard.set(true, forKey: "hasSeenSplash")

                                    isAuthenticating = false
                                    Logger.info("Microsoft OAuth completed, analytics environment: real", category: .app)
                                    Logger.info("Authenticated as: \(email)", category: .app)
                                    onComplete()
                                }
                            } catch {
                                await MainActor.run {
                                    isAuthenticating = false
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        }
                    } label: {
                        VStack(spacing: 6) {
                            if isAuthenticating {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                        .frame(width: 44, height: 44)

                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            } else {
                                ZStack {
                                    // Glow effect
                                    Circle()
                                        .fill(Color.purple.opacity(DesignTokens.Opacity.overlayLight))
                                        .frame(width: 44, height: 44)
                                        .blur(radius: 8)

                                    // Icon background
                                    Circle()
                                        .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color.purple.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                        )

                                    // Icon
                                    Image(systemName: "m.square.fill")
                                        .font(.title3)
                                        .foregroundColor(.purple)
                                }
                            }

                            Text(isAuthenticating ? "Wait..." : "Microsoft")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(isAuthenticating)
                    .opacity(isAuthenticating ? DesignTokens.Opacity.overlayStrong : DesignTokens.Opacity.textPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        // Base glass layer
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(DesignTokens.Opacity.glassLight),
                                        Color.white.opacity(DesignTokens.Opacity.glassUltraLight)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .background(
                                .ultraThinMaterial.opacity(DesignTokens.Opacity.textDisabled),
                                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                            )

                        // Holographic rim lighting
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.cyan.opacity(DesignTokens.Opacity.overlayMedium),
                                        Color.purple.opacity(DesignTokens.Opacity.overlayMedium),
                                        Color.pink.opacity(DesignTokens.Opacity.overlayMedium)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1.5
                            )

                        // Inner glow for depth
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                            .strokeBorder(
                                Color.white.opacity(DesignTokens.Opacity.overlayLight),
                                lineWidth: 0.5
                            )
                            .blur(radius: 2)
                    }
                )
                .padding(.horizontal, 20)
                .shadow(color: Color.black.opacity(DesignTokens.Opacity.overlayLight), radius: 20, x: 0, y: -5)

                // Error message
                if showError {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red.opacity(DesignTokens.Opacity.textSecondary))
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    showError = false
                                }
                            }
                        }
                }
            }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            // Check if this is the VERY first launch
            let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasCompletedFirstLaunch")

            if isFirstLaunch {
                // Show loading screen for 2.5 seconds (matches LoadingView animation duration)
                showLoadingScreen = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showLoadingScreen = false
                    }
                    // Mark first launch as complete
                    UserDefaults.standard.set(true, forKey: "hasCompletedFirstLaunch")

                    // Then animate in the splash view
                    withAnimation(.spring(response: 0.6)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                }
            } else {
                // Not first launch - animate in immediately
                withAnimation(.spring(response: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}

// MARK: - Floating Particles Component

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
