import SwiftUI

/// Progressive reveal swipe hint that animates a card moving in different directions
/// Shows icons activating as the card moves, teaching gestures naturally
struct SwipeHintOverlay: View {
    let actionLabel: String
    @State private var currentHint: HintDirection = .right
    @State private var offset: CGFloat = 0
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0.3
    @State private var showLabel: Bool = false

    enum HintDirection: CaseIterable {
        case right, left, down

        var icon: String {
            switch self {
            case .right: return "arrow.right.circle.fill"
            case .left: return "checkmark.circle.fill"
            case .down: return "clock.fill"
            }
        }

        var color: Color {
            switch self {
            case .right: return .green
            case .left: return .blue
            case .down: return .purple
            }
        }

        var label: String {
            switch self {
            case .right: return "Take Action"
            case .left: return "Mark as Read"
            case .down: return "Snooze"
            }
        }

        var offset: CGFloat {
            switch self {
            case .right: return 60
            case .left: return -60
            case .down: return 0
            }
        }

        var verticalOffset: CGFloat {
            switch self {
            case .right, .left: return 0
            case .down: return 30
            }
        }
    }

    var body: some View {
        // Container with explicit frame to account for all animation movement
        // Card: 200x120, moves ±60 horizontal/+30 vertical
        // Icons: appear at ±120 horizontal/+80 vertical
        // Total space needed: ~320 width x ~240 height
        ZStack {
            // Background card simulation
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    // Mini card content
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 140, height: 12)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 160, height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 140, height: 8)
                    }
                )
                .offset(x: offset, y: currentHint.verticalOffset)

            // Action icon and label - shown together immediately
            VStack(spacing: 12) {
                Image(systemName: currentHint.icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(currentHint.color)

                if showLabel {
                    Text(currentHint == .right ? "\(actionLabel)" : currentHint.label)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(currentHint.color.opacity(0.9))
                        .cornerRadius(8)
                }
            }
            .scaleEffect(iconScale)
            .opacity(iconOpacity)
            .offset(x: currentHint == .right ? 120 : currentHint == .left ? -120 : 0,
                    y: currentHint == .down ? 80 : 0)
        }
        .frame(width: 320, height: 240)
        .onAppear {
            startAnimation()
        }
    }

    func startAnimation() {
        // Faster cycle with label shown immediately
        withAnimation(.easeInOut(duration: 0.6)) {
            offset = currentHint.offset
            iconScale = 1.2
            iconOpacity = 1.0
        }

        // Show label immediately with icon
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.15)) {
                showLabel = true
            }
        }

        // Hold for viewing, then reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showLabel = false
            }

            withAnimation(.easeInOut(duration: 0.5)) {
                offset = 0
                iconScale = 0.5
                iconOpacity = 0.3
            }
        }

        // Move to next hint faster (1.5s per direction)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Move to next hint
            let allCases = HintDirection.allCases
            if let currentIndex = allCases.firstIndex(of: currentHint) {
                let nextIndex = (currentIndex + 1) % allCases.count
                currentHint = allCases[nextIndex]
            }

            // Repeat
            startAnimation()
        }
    }
}

/// First-time overlay that shows swipe hints on the actual card
struct FirstTimeSwipeHintOverlay: View {
    let actionLabel: String
    @Binding var showHint: Bool
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated hint card
                SwipeHintOverlay(actionLabel: actionLabel)
                    .scaleEffect(pulseScale)

                // Instructional text
                VStack(spacing: 12) {
                    Text("Swipe to Take Action")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("Watch the card move to learn the gestures")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                // Dismiss button
                Button {
                    withAnimation {
                        showHint = false
                    }
                    UserDefaults.standard.set(true, forKey: "hasSeenSwipeHint")
                } label: {
                    Text("Got it")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            // Subtle pulse animation
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

        SwipeHintOverlay(actionLabel: "Sign Form")
    }
}
