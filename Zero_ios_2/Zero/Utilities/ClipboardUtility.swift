import UIKit

/// Shared clipboard utility with haptic feedback
/// Consolidates duplicate copyToClipboard() implementations across ActionModules
struct ClipboardUtility {

    /// Copy text to clipboard with haptic feedback
    /// - Parameter text: The text to copy
    static func copy(_ text: String) {
        UIPasteboard.general.string = text

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        Logger.info("Copied to clipboard: \(text.prefix(50))...", category: .action)
    }

    /// Copy text to clipboard with optional haptic style
    /// - Parameters:
    ///   - text: The text to copy
    ///   - hapticStyle: The haptic feedback style (default: .medium)
    static func copy(_ text: String, hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIPasteboard.general.string = text

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: hapticStyle)
        impact.impactOccurred()

        Logger.info("Copied to clipboard: \(text.prefix(50))...", category: .action)
    }
}
