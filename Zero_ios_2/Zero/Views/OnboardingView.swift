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
            // Animated gradient background
            LinearGradient(
                colors: [Color.blue, Color.purple, Color.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
                
                // Navigation
                HStack {
                    Button {
                        if currentStep > 0 {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                    } label: {
                        Text("Previous")
                            .foregroundColor(currentStep == 0 ? .white.opacity(0.3) : .white.opacity(0.6))
                    }
                    .disabled(currentStep == 0)
                    
                    Spacer()
                    
                    Text("\(currentStep + 1) of \(steps.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    Button {
                        if isLastStep {
                            // Always use all 4 archetypes
                            selectedArchetypes = [.mail, .mail, .mail, .ads]
                            Logger.info("Onboarding completed with all 4 archetypes", category: .app)

                            // Mark onboarding as completed when user finishes
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                            onComplete()
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    } label: {
                        HStack {
                            Text(isLastStep ? "Get Started" : "Next")
                                .font(.headline)
                            Image(systemName: isLastStep ? "bolt.fill" : "arrow.right")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
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
        // PHASE 1: Card moves in direction + icon/label scale up (0.5s)
        withAnimation(.easeOut(duration: 0.5)) {
            offset = currentHint.offset
            iconScale = 1.3
            iconOpacity = 1.0
            showLabel = true
        }

        // PHASE 2: Hold at peak (0.7s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // PHASE 3: Card returns to center (0.4s)
            withAnimation(.easeIn(duration: 0.4)) {
                offset = 0
                iconScale = 0.5
                iconOpacity = 0.3
                showLabel = false
            }
        }

        // Total cycle time: 1.6s per direction
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
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

