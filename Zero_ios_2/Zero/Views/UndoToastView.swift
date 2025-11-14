import SwiftUI

/**
 * UndoToastView - Elegant toast notification with 10-second undo countdown
 *
 * Design Philosophy: Integrated, subtle, deterministic
 * Inspired by: iOS Mail "undo send", Raya/Hinge undo patterns
 *
 * Features:
 * - 4 countdown styles: progress bar (default), circular ring, numeric, none
 * - 10-second undo window (configurable)
 * - Accessibility: VoiceOver, reduced motion, dynamic type
 * - Haptic feedback
 * - Background/foreground timer persistence
 */
struct UndoToastView: View {
    // MARK: - Configuration
    let message: String
    let countdownStyle: UndoCountdownStyle
    let undoWindowSeconds: TimeInterval
    let onUndo: () -> Void
    let onTimeout: () -> Void

    // MARK: - State
    @State private var progress: CGFloat = 1.0
    @State private var remainingTime: TimeInterval
    @State private var timer: Timer?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initialization
    init(
        message: String,
        countdownStyle: UndoCountdownStyle = .progressBar,
        undoWindowSeconds: TimeInterval = 10.0,
        onUndo: @escaping () -> Void,
        onTimeout: @escaping () -> Void
    ) {
        self.message = message
        self.countdownStyle = countdownStyle
        self.undoWindowSeconds = undoWindowSeconds
        self.onUndo = onUndo
        self.onTimeout = onTimeout
        self._remainingTime = State(initialValue: undoWindowSeconds)
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Message + Undo Button
            HStack(spacing: 12) {
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                // Numeric countdown (if enabled)
                if case .numeric = countdownStyle {
                    Text("\(Int(ceil(remainingTime)))s")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                        .monospacedDigit()
                        .accessibilityLabel("\(Int(ceil(remainingTime))) seconds remaining")
                }

                // Undo button
                Button(action: handleUndo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Undo")
                .accessibilityHint("Double tap to reverse the action")
                .overlay {
                    // Circular ring countdown (if enabled)
                    if case .circularRing = countdownStyle {
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))
                            .animation(
                                reduceMotion ? .none : .linear(duration: undoWindowSeconds),
                                value: progress
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Progress bar countdown (if enabled)
            if case .progressBar = countdownStyle {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track (subtle)
                        Rectangle()
                            .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                            .frame(height: 2)

                        // Progress indicator
                        Rectangle()
                            .fill(Color.white.opacity(DesignTokens.Opacity.overlayMedium))
                            .frame(width: geometry.size.width * progress, height: 2)
                            .animation(
                                reduceMotion ? .none : .linear(duration: undoWindowSeconds),
                                value: progress
                            )
                    }
                    .cornerRadius(1)
                }
                .frame(height: 2)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
                .accessibilityLabel("Time remaining: \(Int(ceil(remainingTime))) seconds")
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.92))
                .background(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
        .padding(.bottom: 24)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(message). Time remaining: \(Int(ceil(remainingTime))) seconds")
        .onAppear {
            startCountdown()
            announceToVoiceOver()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }

    // MARK: - Timer Logic
    private func startCountdown() {
        // Start visual countdown animation
        if !reduceMotion {
            withAnimation(.linear(duration: undoWindowSeconds)) {
                progress = 0
            }
        }

        // Start timer for discrete updates
        let updateInterval: TimeInterval = reduceMotion ? 2.0 : 0.1
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            remainingTime -= updateInterval

            if reduceMotion {
                // Discrete progress updates for reduced motion
                progress = CGFloat(remainingTime / undoWindowSeconds)
            }

            if remainingTime <= 0 {
                handleTimeout()
            } else if remainingTime <= 3 && Int(remainingTime) != Int(remainingTime + updateInterval) {
                // Announce final countdown to VoiceOver
                announceRemainingTime()
            }
        }
    }

    private func stopCountdown() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Actions
    private func handleUndo() {
        stopCountdown()

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        onUndo()
    }

    private func handleTimeout() {
        stopCountdown()
        onTimeout()
    }

    // MARK: - Scene Phase Handling
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            // Timer continues in background (iOS allows short-lived timers)
            break

        case .active:
            if oldPhase == .background {
                // Resumed from background - timer should still be running
                // If time expired while backgrounded, handle timeout
                if remainingTime <= 0 {
                    handleTimeout()
                }
            }

        default:
            break
        }
    }

    // MARK: - Accessibility
    private func announceToVoiceOver() {
        let announcement = "\(message). \(Int(ceil(remainingTime))) seconds remaining to undo."
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    private func announceRemainingTime() {
        let seconds = Int(ceil(remainingTime))
        if seconds == 5 || seconds == 3 || seconds == 1 {
            UIAccessibility.post(
                notification: .announcement,
                argument: "\(seconds) second\(seconds == 1 ? "" : "s") remaining"
            )
        }
    }
}

// MARK: - Preview Provider
#Preview("Progress Bar (Default)") {
    ZStack {
        Color.gray.ignoresSafeArea()

        VStack {
            Spacer()
            UndoToastView(
                message: "Invitation declined. Tap to undo.",
                countdownStyle: .progressBar,
                undoWindowSeconds: 10.0,
                onUndo: {
                    print("Undo tapped")
                },
                onTimeout: {
                    print("Timeout reached")
                }
            )
        }
    }
}

#Preview("Circular Ring") {
    ZStack {
        Color.gray.ignoresSafeArea()

        VStack {
            Spacer()
            UndoToastView(
                message: "Payment sent. Tap to undo.",
                countdownStyle: .circularRing,
                undoWindowSeconds: 10.0,
                onUndo: {
                    print("Undo tapped")
                },
                onTimeout: {
                    print("Timeout reached")
                }
            )
        }
    }
}

#Preview("Numeric Countdown") {
    ZStack {
        Color.gray.ignoresSafeArea()

        VStack {
            Spacer()
            UndoToastView(
                message: "Subscription cancelled. Tap to undo.",
                countdownStyle: .numeric,
                undoWindowSeconds: 10.0,
                onUndo: {
                    print("Undo tapped")
                },
                onTimeout: {
                    print("Timeout reached")
                }
            )
        }
    }
}

#Preview("No Countdown") {
    ZStack {
        Color.gray.ignoresSafeArea()

        VStack {
            Spacer()
            UndoToastView(
                message: "Action completed. Tap to undo if needed.",
                countdownStyle: .none,
                undoWindowSeconds: 10.0,
                onUndo: {
                    print("Undo tapped")
                },
                onTimeout: {
                    print("Timeout reached")
                }
            )
        }
    }
}

#Preview("Long Message") {
    ZStack {
        Color.gray.ignoresSafeArea()

        VStack {
            Spacer()
            UndoToastView(
                message: "Tax payment of $1,234.56 initiated to County Tax Assessor. Tap to undo.",
                countdownStyle: .progressBar,
                undoWindowSeconds: 10.0,
                onUndo: {
                    print("Undo tapped")
                },
                onTimeout: {
                    print("Timeout reached")
                }
            )
        }
    }
}
