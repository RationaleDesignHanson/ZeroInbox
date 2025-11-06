import SwiftUI

struct OnboardingView: View {
    @Binding var selectedArchetypes: [CardType]
    let onComplete: () -> Void
    let userEmail: String?  // nil = mock mode, else authenticated
    @State private var currentStep = 0

    private var isFirstTime: Bool {
        !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    private var steps: [String] {
        // Simplified to 2 cards - users learn gestures from actual cards
        return [
            "Welcome to Zero",
            "Ready to Go"
        ]
    }
    
    private var isLastStep: Bool {
        currentStep == steps.count - 1
    }
    
    var body: some View {
        ZStack {
            // Firefly background matching mail section
            FireflyBackgroundOnboarding()
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Skip button (only show if user has completed onboarding before)
                if !isFirstTime {
                    HStack {
                        Spacer()
                        Button {
                            // Ensure both binary archetypes are selected when skipping (v1.10+)
                            if selectedArchetypes.isEmpty {
                                selectedArchetypes = [.mail, .ads]
                                Logger.info("Skip: No archetypes selected, defaulting to mail and ads", category: .app)
                            }
                            Logger.info("Skip: Onboarding skipped with archetypes: \(selectedArchetypes.map { $0.displayName })", category: .app)
                            onComplete()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.title3)
                                .padding()
                        }
                    }
                } else {
                    // Spacer to maintain layout consistency
                    HStack {
                        Spacer()
                    }
                    .frame(height: 44)
                }
                
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentStep ? Color.white : 
                                  index < currentStep ? Color.green : Color.white.opacity(0.3))
                            .frame(width: index == currentStep ? 24 : 8, height: 8)
                            .animation(.spring(), value: currentStep)
                    }
                }
                
                Spacer()
                
                // Step content
                stepContent
                
                Spacer()

                // Why You'll Love Zero Section
                whyYouLoveZeroSection

                Spacer()

                // Navigation - Horizontal button row
                VStack(spacing: 12) {
                    Text("\(currentStep + 1) of \(steps.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))

                    HStack(spacing: 12) {
                        // Previous button
                        Button {
                            if currentStep > 0 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep -= 1
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Previous")
                            }
                            .font(.headline)
                            .foregroundColor(currentStep == 0 ? .white.opacity(0.3) : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background {
                                if currentStep == 0 {
                                    Color.white.opacity(0.1)
                                } else {
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                            .cornerRadius(12)
                        }
                        .disabled(currentStep == 0)

                        // Next/Get Started button
                        Button {
                            if isLastStep {
                                // Always use all 4 archetypes
                                selectedArchetypes = [.mail, .mail, .mail, .ads]
                                Logger.info("Onboarding completed with all 4 archetypes", category: .app)

                                // Mark onboarding as completed when user finishes
                                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                                onComplete()
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep += 1
                                }
                            }
                        } label: {
                            HStack {
                                Text(isLastStep ? "Get Started" : "Next")
                                Image(systemName: isLastStep ? "bolt.fill" : "arrow.right")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, y: 4)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    @ViewBuilder
    var stepContent: some View {
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")

        switch currentStep {
        case 0:
            // Welcome screen with value proposition
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)

                Text("Welcome to Zero")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("Clear your inbox in minutes, not hours")
                    .font(.title3.bold())
                    .foregroundColor(.white.opacity(0.9))

                if useMockData {
                    Text("Zero organizes emails with smart actions so you can swipe through what matters.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                } else {
                    VStack(spacing: 12) {
                        Text("Zero organizes emails with smart actions so you can swipe through what matters.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        if let email = userEmail {
                            Text("Connected: \(email)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 8)
                        }
                    }
                }

                // Hint about gesture learning
                Text("Watch the cards to learn the gestures")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 12)

                // Card animation demo
                OnboardingCardAnimation()
                    .padding(.top, 20)
            }

        case 1:
            // Ready screen
            readyContent

        default:
            EmptyView()
        }
    }

    // MARK: - Reusable Content Views

    @ViewBuilder
    var readyContent: some View {
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")

        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("You're All Set!")
                .font(.title.bold())
                .foregroundColor(.white)

            if useMockData {
                Text("Start swiping and watch your inbox clear in record time.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                Text("Start swiping through your emails and watch your inbox clear in record time.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    @ViewBuilder
    var whyYouLoveZeroSection: some View {
        VStack(spacing: 20) {
            Text("Why You'll Love Zero")
                .font(.title2.bold())
                .foregroundColor(.white)

            HStack(spacing: 16) {
                // Save Time
                VStack(spacing: 8) {
                    Text("⏰")
                        .font(.system(size: 36))
                    Text("Save Time")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                    Text("2 hrs")
                        .font(.title3.bold())
                        .foregroundColor(.blue)
                    Text("saved daily")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

                // Reduce Stress
                VStack(spacing: 8) {
                    Text("🧘")
                        .font(.system(size: 36))
                    Text("Reduce Stress")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                    Text("Zero")
                        .font(.title3.bold())
                        .foregroundColor(.green)
                    Text("anxiety")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

                // Stay Secure
                VStack(spacing: 8) {
                    Text("🔒")
                        .font(.system(size: 36))
                    Text("Stay Secure")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                    Text("100%")
                        .font(.title3.bold())
                        .foregroundColor(.purple)
                    Text("private")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Onboarding Card Animation
/// Animated demonstration of card swiping through all 4 gestures
struct OnboardingCardAnimation: View {
    @State private var currentHint: HintDirection = .right
    @State private var offset: CGFloat = 0
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0.3
    @State private var showLabel: Bool = false
    @State private var animationCount: Int = 0
    private let maxAnimations = 4 // 1 cycle × 4 directions

    enum HintDirection: CaseIterable {
        case right, left, down, up

        var icon: String {
            switch self {
            case .right: return "arrow.right.circle.fill"
            case .left: return "checkmark.circle.fill"
            case .down: return "clock.fill"
            case .up: return "arrow.triangle.2.circlepath"
            }
        }

        var color: Color {
            switch self {
            case .right: return .green
            case .left: return .blue
            case .down: return .purple
            case .up: return .orange
            }
        }

        var label: String {
            switch self {
            case .right: return "Take Action"
            case .left: return "Mark as Read"
            case .down: return "Snooze"
            case .up: return "Choose Action"
            }
        }

        var offset: CGFloat {
            switch self {
            case .right: return 45
            case .left: return -45
            case .down, .up: return 0
            }
        }

        var verticalOffset: CGFloat {
            switch self {
            case .right, .left: return 0
            case .down: return 20
            case .up: return -20
            }
        }
    }

    var body: some View {
        ZStack {
            // Background card simulation
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .frame(width: 150, height: 90)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    // Mini card content
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 105, height: 10)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 105, height: 6)
                    }
                )
                .offset(x: offset, y: currentHint.verticalOffset)

            // Action icon and label
            VStack(spacing: 6) {
                Image(systemName: currentHint.icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.white)

                Text(currentHint.label)
                    .font(.caption.bold())
                    .foregroundColor(currentHint.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(8)
                    .opacity(showLabel ? 1.0 : 0.0)
            }
            .scaleEffect(iconScale)
            .opacity(iconOpacity)
            .offset(
                x: currentHint == .right ? 90 : currentHint == .left ? -90 : 0,
                y: currentHint == .down ? 55 : currentHint == .up ? -55 : 0
            )
        }
        .frame(width: 240, height: 130)
        .onAppear {
            startAnimation()
        }
    }

    func startAnimation() {
        // PHASE 1: Card moves in direction + icon/label scale up (smoother easing)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
            offset = currentHint.offset
            iconScale = 1.3
            iconOpacity = 1.0
            showLabel = true
        }

        // PHASE 2: Hold at peak (0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            // PHASE 3: Card returns to center (smoother easing)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75, blendDuration: 0)) {
                offset = 0
                iconScale = 0.5
                iconOpacity = 0.3
                showLabel = false
            }
        }

        // Total cycle time: 1.9s per direction for smoother feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            animationCount += 1

            // Loop forever through all 4 directions
            let allCases = HintDirection.allCases
            if let currentIndex = allCases.firstIndex(of: currentHint) {
                let nextIndex = (currentIndex + 1) % allCases.count
                currentHint = allCases[nextIndex]
            }

            // Repeat indefinitely
            startAnimation()
        }
    }
}

// MARK: - Firefly Background for Onboarding (matching mail section)

/// Firefly background matching the main app's mail section design
struct FireflyBackgroundOnboarding: View {
    @State private var fireflies: [FireflyOnboarding] = []

    var body: some View {
        ZStack {
            // Base gradient matching ContentView FireflyBackground (mail section)
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
        var newFireflies: [FireflyOnboarding] = []

        // Small, medium, and warm fireflies (30 total for less cluttered onboarding)
        for i in 0..<30 {
            let rand = Double.random(in: 0...1)
            let type: FireflyTypeOnboarding = rand < 0.33 ? .small : rand < 0.66 ? .medium : .warm
            newFireflies.append(FireflyOnboarding(type: type, index: i))
        }

        // Large ambient orbs (4 total)
        for i in 0..<4 {
            newFireflies.append(FireflyOnboarding(type: .orb, index: i + 30))
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

// MARK: - Firefly Models for Onboarding

enum FireflyTypeOnboarding {
    case small, medium, warm, orb
}

struct FireflyOnboarding: Identifiable {
    let id = UUID()
    let type: FireflyTypeOnboarding
    let color: Color
    let size: CGFloat
    let blur: CGFloat
    let opacity: Double
    let duration: Double
    var position: CGPoint
    var currentOpacity: Double

    init(type: FireflyTypeOnboarding, index: Int) {
        self.type = type

        // Set properties based on type (matching website/ContentView)
        switch type {
        case .small:
            self.color = Color(red: 147/255, green: 197/255, blue: 253/255)
            self.size = 3
            self.blur = 5
            self.opacity = 0.8

        case .medium:
            self.color = Color(red: 196/255, green: 181/255, blue: 253/255)
            self.size = 5
            self.blur = 7.5
            self.opacity = 0.9

        case .warm:
            self.color = Color(red: 251/255, green: 191/255, blue: 36/255)
            self.size = 4
            self.blur = 6
            self.opacity = 0.9

        case .orb:
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

