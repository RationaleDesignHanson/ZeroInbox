import UIKit

/// Centralized haptic feedback service
/// Provides consistent haptic feedback across the app
class HapticService {
    static let shared = HapticService()

    private init() {}

    // MARK: - Impact Feedback

    /// Light impact (e.g., selection changes, toggles)
    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        Logger.info("Haptic: light impact", category: .haptic)
    }

    /// Medium impact (e.g., button taps, swipe threshold)
    func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        Logger.info("Haptic: medium impact", category: .haptic)
    }

    /// Heavy impact (e.g., card dismissed, major action)
    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
        Logger.info("Haptic: heavy impact", category: .haptic)
    }

    /// Rigid impact (e.g., error boundaries, limits reached)
    func rigidImpact() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
        Logger.info("Haptic: rigid impact", category: .haptic)
    }

    /// Soft impact (e.g., gentle UI changes)
    func softImpact() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
        Logger.info("Haptic: soft impact", category: .haptic)
    }

    // MARK: - Notification Feedback

    /// Success notification (e.g., action completed, form submitted)
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        Logger.info("Haptic: success", category: .haptic)
    }

    /// Warning notification (e.g., validation warning, confirm action)
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
        Logger.info("Haptic: warning", category: .haptic)
    }

    /// Error notification (e.g., failed action, invalid input)
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
        Logger.info("Haptic: error", category: .haptic)
    }

    // MARK: - Selection Feedback

    /// Selection changed (e.g., picker scrolling, tab switching)
    func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        Logger.info("Haptic: selection changed", category: .haptic)
    }

    // MARK: - Complex Patterns

    /// Celebration pattern (triple tap for major wins)
    func celebration() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()

        generator.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.notificationOccurred(.success)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            generator.notificationOccurred(.success)
        }

        Logger.info("Haptic: celebration", category: .haptic)
    }

    /// Double tap pattern (for confirmations, acknowledgments)
    func doubleTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.impactOccurred()
        }

        Logger.info("Haptic: double tap", category: .haptic)
    }

    // MARK: - Prepared Generators (for low-latency haptics)

    private var preparedImpactGenerator: UIImpactFeedbackGenerator?

    /// Prepare an impact generator for immediate use
    /// Call this before an interaction to reduce haptic latency
    func prepareImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        preparedImpactGenerator = UIImpactFeedbackGenerator(style: style)
        preparedImpactGenerator?.prepare()
    }

    /// Trigger prepared impact (or create new one if not prepared)
    func triggerPreparedImpact() {
        if let generator = preparedImpactGenerator {
            generator.impactOccurred()
            generator.prepare() // Re-prepare for next use
        } else {
            mediumImpact()
        }
    }
}
