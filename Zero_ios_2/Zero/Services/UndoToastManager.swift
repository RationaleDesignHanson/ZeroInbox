import SwiftUI
import Combine

/**
 * UndoToastManager - Orchestrates undo toast presentation and lifecycle
 *
 * Responsibilities:
 * - Present undo toasts for reversible actions
 * - Manage active toast state
 * - Handle undo/timeout callbacks
 * - Queue multiple toasts (show one at a time)
 *
 * Usage:
 * ```
 * toastManager.showUndoToast(
 *     message: "Invitation declined. Tap to undo.",
 *     config: undoConfig,
 *     onUndo: { /* reverse action */ }
 * )
 * ```
 */
@MainActor
class UndoToastManager: ObservableObject {
    // MARK: - Published State
    @Published var activeToast: ToastState?

    // MARK: - Private State
    private var toastQueue: [ToastState] = []
    private var activeActionId: String?

    // MARK: - Toast State
    struct ToastState: Identifiable {
        let id = UUID()
        let message: String
        let countdownStyle: UndoCountdownStyle
        let undoWindowSeconds: TimeInterval
        let actionId: String
        let onUndo: () -> Void
        let onTimeout: () -> Void
    }

    // MARK: - Public Methods

    /// Show undo toast for an action with undo configuration
    func showUndoToast(
        message: String,
        config: UndoConfig,
        actionId: String,
        onUndo: @escaping () -> Void,
        onFinalize: @escaping () -> Void = {}
    ) {
        let toastState = ToastState(
            message: message,
            countdownStyle: config.countdownStyle,
            undoWindowSeconds: config.undoWindowSeconds,
            actionId: actionId,
            onUndo: { [weak self] in
                self?.handleUndo(actionId: actionId)
                onUndo()
            },
            onTimeout: { [weak self] in
                self?.handleTimeout(actionId: actionId)
                onFinalize()
            }
        )

        if activeToast == nil {
            // No active toast, show immediately
            presentToast(toastState)
        } else {
            // Queue toast to show after current one finishes
            toastQueue.append(toastState)
        }
    }

    /// Dismiss current toast without executing undo or timeout callbacks
    func dismissCurrentToast() {
        activeToast = nil
        activeActionId = nil
        showNextQueuedToast()
    }

    /// Cancel undo window for specific action (if still active)
    func cancelUndoWindow(for actionId: String) {
        if activeActionId == actionId {
            dismissCurrentToast()
        } else {
            // Remove from queue if present
            toastQueue.removeAll { $0.actionId == actionId }
        }
    }

    // MARK: - Private Methods

    private func presentToast(_ toast: ToastState) {
        activeToast = toast
        activeActionId = toast.actionId
    }

    private func handleUndo(actionId: String) {
        activeToast = nil
        activeActionId = nil

        // Don't show next toast immediately - give user a moment
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            showNextQueuedToast()
        }
    }

    private func handleTimeout(actionId: String) {
        activeToast = nil
        activeActionId = nil
        showNextQueuedToast()
    }

    private func showNextQueuedToast() {
        guard !toastQueue.isEmpty else { return }
        let nextToast = toastQueue.removeFirst()
        presentToast(nextToast)
    }
}

// MARK: - Environment Key
private struct UndoToastManagerKey: EnvironmentKey {
    static let defaultValue = UndoToastManager()
}

extension EnvironmentValues {
    var undoToastManager: UndoToastManager {
        get { self[UndoToastManagerKey.self] }
        set { self[UndoToastManagerKey.self] = newValue }
    }
}

// MARK: - Toast Container View Modifier
struct UndoToastContainer: ViewModifier {
    @StateObject private var toastManager = UndoToastManager()

    func body(content: Content) -> some View {
        ZStack {
            content
                .environment(\.undoToastManager, toastManager)

            // Toast overlay
            if let toast = toastManager.activeToast {
                VStack {
                    Spacer()

                    UndoToastView(
                        message: toast.message,
                        countdownStyle: toast.countdownStyle,
                        undoWindowSeconds: toast.undoWindowSeconds,
                        onUndo: toast.onUndo,
                        onTimeout: toast.onTimeout
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(999)
                }
                .animation(.spring(duration: 0.6, bounce: 0.3), value: toastManager.activeToast != nil)
            }
        }
    }
}

extension View {
    /// Add undo toast support to this view hierarchy
    func withUndoToasts() -> some View {
        modifier(UndoToastContainer())
    }
}

// MARK: - Preview Provider
#Preview("Toast Manager Demo") {
    struct DemoView: View {
        @Environment(\.undoToastManager) var toastManager

        var body: some View {
            VStack(spacing: 20) {
                Text("Undo Toast Manager Demo")
                    .font(.title)

                Button("Decline Invitation") {
                    toastManager.showUndoToast(
                        message: "Invitation declined. Tap to undo.",
                        config: UndoConfig(
                            toastMessage: "Invitation declined. Tap to undo.",
                            countdownStyle: .progressBar
                        ),
                        actionId: "rsvp_no",
                        onUndo: {
                            print("✅ Undo: Re-accepted invitation")
                        },
                        onFinalize: {
                            print("⏰ Finalized: Invitation declined")
                        }
                    )
                }
                .buttonStyle(.borderedProminent)

                Button("Send Payment") {
                    toastManager.showUndoToast(
                        message: "Payment sent. Tap to undo.",
                        config: UndoConfig(
                            toastMessage: "Payment sent. Tap to undo.",
                            countdownStyle: .circularRing
                        ),
                        actionId: "pay_invoice",
                        onUndo: {
                            print("✅ Undo: Payment cancelled")
                        },
                        onFinalize: {
                            print("⏰ Finalized: Payment processed")
                        }
                    )
                }
                .buttonStyle(.borderedProminent)

                Button("Cancel Subscription") {
                    toastManager.showUndoToast(
                        message: "Subscription cancelled. Tap to undo.",
                        config: UndoConfig(
                            toastMessage: "Subscription cancelled. Tap to undo.",
                            countdownStyle: .numeric
                        ),
                        actionId: "cancel_subscription",
                        onUndo: {
                            print("✅ Undo: Subscription restored")
                        },
                        onFinalize: {
                            print("⏰ Finalized: Subscription cancelled")
                        }
                    )
                }
                .buttonStyle(.borderedProminent)

                Button("Dismiss Current Toast") {
                    toastManager.dismissCurrentToast()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    return DemoView()
        .withUndoToasts()
}
