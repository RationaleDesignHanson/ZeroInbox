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

            // Animated gradient background
            AnimatedGradientBackground(
                gradient: LinearGradient(
                    colors: [
                        Color.celebrationPurpleBlue,
                        Color.celebrationDeepPurple,
                        Color.celebrationBrightPink
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                animationSpeed: 30
            )
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
                            .opacity(0.15)
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
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.3), radius: 10)
                        
                        Text("00")
                            .font(.system(size: 70, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(0.15)
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
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // Authentication Options
                VStack(spacing: 16) {
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
                        HStack {
                            Image(systemName: "text.book.closed.fill")
                                .font(.title3)
                            Text("Use Mock Data")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.7), Color.pink.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }

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
                        HStack {
                            if isAuthenticating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Authenticating...")
                            } else {
                                Image(systemName: "g.circle.fill")
                                    .font(.title3)
                                Text("Login with Google")
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .disabled(isAuthenticating)
                    .opacity(isAuthenticating ? 0.5 : 1.0)

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
                        HStack {
                            if isAuthenticating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Authenticating...")
                            } else {
                                Image(systemName: "m.square.fill")
                                    .font(.title3)
                                Text("Login with Microsoft")
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.indigo.opacity(0.8), Color.purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .disabled(isAuthenticating)
                    .opacity(isAuthenticating ? 0.5 : 1.0)
                }
                .padding(.horizontal)

                // Error message
                if showError {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red.opacity(0.9))
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

/// Ambient floating particles for splash screen
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

