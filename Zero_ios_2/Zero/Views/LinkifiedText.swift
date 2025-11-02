import SwiftUI
import UIKit
import SafariServices

/// Text view that automatically detects URLs and makes them tappable
/// Uses UITextView with data detectors and custom delegate for SFSafariViewController
struct LinkifiedText: UIViewRepresentable {
    let text: String
    let font: Font
    let color: Color
    let lineSpacing: CGFloat

    init(
        _ text: String,
        font: Font = .body,
        color: Color = .white.opacity(0.9),
        lineSpacing: CGFloat = 4
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.lineSpacing = lineSpacing
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()

        // Make it non-editable (read-only)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false

        // Transparent background to blend with parent
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0

        // Proper text wrapping - let container determine width
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.widthTracksTextView = true

        // CRITICAL: Ensure text view doesn't expand horizontally
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        // Enable data detectors for URLs, phone numbers, etc.
        textView.dataDetectorTypes = [.link, .phoneNumber, .address]

        // Set delegate for custom link handling
        textView.delegate = context.coordinator

        // Elegant pill-style links (no underline, subtle background)
        textView.linkTextAttributes = [
            .foregroundColor: UIColor(red: 0.578, green: 0.769, blue: 0.992, alpha: 1.0), // #93c5fd
            .underlineStyle: 0, // No underline
            .backgroundColor: UIColor(red: 0.578, green: 0.769, blue: 0.992, alpha: 0.15)
        ]

        return textView
    }

    // MARK: - Coordinator for link handling

    class Coordinator: NSObject, UITextViewDelegate {
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            // Handle link tap with in-app Safari
            if interaction == .invokeDefaultAction {
                openLinkInSafari(URL)

                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()

                // Return false to prevent default action
                return false
            }
            return true
        }

        private func openLinkInSafari(_ url: URL) {
            // Get the current window scene
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let viewController = windowScene.windows.first?.rootViewController else {
                // Fallback to external Safari
                UIApplication.shared.open(url)
                Logger.warning("Could not find view controller, opening in external Safari", category: .ui)
                return
            }

            // Present SFSafariViewController
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = false
            config.barCollapsingEnabled = true

            let safari = SFSafariViewController(url: url, configuration: config)
            safari.dismissButtonStyle = .done
            safari.preferredControlTintColor = .systemBlue

            // Find the topmost presented view controller
            var topController = viewController
            while let presented = topController.presentedViewController {
                topController = presented
            }

            topController.present(safari, animated: true)
            Logger.info("Opening link in Safari: \(url.absoluteString)", category: .ui)
        }
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        // Convert SwiftUI Font/Color to UIKit equivalents
        let uiFont: UIFont
        switch font {
        case .body:
            uiFont = .systemFont(ofSize: 17)
        case .caption:
            uiFont = .systemFont(ofSize: 12)
        default:
            uiFont = .systemFont(ofSize: 17)
        }

        let uiColor = UIColor(color)

        // Create attributed string with styling
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineBreakMode = .byWordWrapping
        // Allow breaking at any character for long URLs (as fallback)
        paragraphStyle.lineBreakStrategy = .standard

        let attributes: [NSAttributedString.Key: Any] = [
            .font: uiFont,
            .foregroundColor: uiColor,
            .paragraphStyle: paragraphStyle
        ]

        textView.attributedText = NSAttributedString(string: text, attributes: attributes)

        // Size to content - width will be determined by parent container
        textView.sizeToFit()
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        LinkifiedText(
            "Check out our website at https://example.com for more details.",
            color: .white.opacity(0.9)
        )

        LinkifiedText(
            "Visit www.apple.com or https://google.com for info.",
            color: .white.opacity(0.9)
        )

        LinkifiedText(
            """
            Hi there!

            Please click this link to confirm your order:
            https://store.example.com/orders/12345

            You can also track your package here:
            www.fedex.com/tracking/ABC123

            Call us at 1-800-555-1234 if you have questions.

            Thanks!
            """,
            color: .white.opacity(0.9)
        )
    }
    .padding()
    .background(
        LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
