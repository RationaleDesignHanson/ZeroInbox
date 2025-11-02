import SwiftUI

struct OpenAppModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var showSuccessMessage = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Open in App")
                        .font(.title2.bold())
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    Text("Launch the app to complete action")
                        .font(.subheadline)
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                }

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .font(.title2)
                }
            }
            .padding()

            Divider()
                .background(Color.white.opacity(0.2))

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Email details
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        Text(card.title)
                            .font(.title3.bold())
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        StructuredSummaryView(card: card)
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Instructions
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                        HStack(spacing: DesignTokens.Spacing.component) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)

                            Text("This action requires the app to be installed on your device")
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(DesignTokens.Radius.button)

                        // Detected app
                        if let appName = detectAppName() {
                            HStack(spacing: DesignTokens.Spacing.component) {
                                Image(systemName: "app.badge")
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                Text("Detected: \(appName)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                    }

                    // Success/Error message
                    if showSuccessMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("App launched successfully!")
                                .foregroundColor(.green)
                        }
                        .font(.subheadline.bold())
                    }

                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(DesignTokens.Radius.chip)
                    }
                }
                .padding(DesignTokens.Spacing.card)
            }

            // Action buttons
            VStack(spacing: DesignTokens.Spacing.component) {
                Button {
                    openApp()
                } label: {
                    HStack {
                        Image(systemName: "app.badge")
                        Text("Open App")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .cornerRadius(DesignTokens.Radius.button)
                }

                Button {
                    copyLink()
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Link")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .cornerRadius(DesignTokens.Radius.button)
                }
            }
            .padding()
        }
        .background(ArchetypeConfig.config(for: card.type).gradient)
    }

    // MARK: - Helper Functions

    /// Detect app name from email content
    func detectAppName() -> String? {
        let text = "\(card.title) \(card.summary)".lowercased()

        if text.contains("ourfamilywizard") || text.contains("family wizard") || text.contains("ofw") {
            return "Our Family Wizard"
        } else if text.contains("doordash") {
            return "DoorDash"
        } else if text.contains("ubereats") || text.contains("uber eats") {
            return "Uber Eats"
        } else if text.contains("grubhub") {
            return "Grubhub"
        } else if text.contains("instacart") {
            return "Instacart"
        }

        return nil
    }

    /// Extract deep link from email body
    func extractDeepLink() -> String? {
        guard let body = card.body else { return nil }

        // Look for URL schemes
        let schemes = [
            "ofw://", "wheaton://",        // Our Family Wizard
            "doordash://", "ubereats://",  // Food delivery
            "grubhub://", "instacart://"
        ]

        for scheme in schemes {
            if let range = body.range(of: scheme) {
                // Extract the full URL
                let startIndex = range.lowerBound
                let remaining = body[startIndex...]

                // Find the end of the URL (space, newline, or end of string)
                if let endRange = remaining.rangeOfCharacter(from: CharacterSet(charactersIn: " \n\r")) {
                    return String(remaining[..<endRange.lowerBound])
                } else {
                    return String(remaining)
                }
            }
        }

        // Fallback: look for https:// links that might be universal links
        if let range = body.range(of: "https://") {
            let startIndex = range.lowerBound
            let remaining = body[startIndex...]

            if let endRange = remaining.rangeOfCharacter(from: CharacterSet(charactersIn: " \n\r")) {
                let url = String(remaining[..<endRange.lowerBound])
                // Only return if it contains app-related domains
                if url.contains("ourfamilywizard") || url.contains("doordash") || url.contains("ubereats") {
                    return url
                }
            }
        }

        return nil
    }

    /// Open the app using deep link
    func openApp() {
        guard let deepLink = extractDeepLink() else {
            errorMessage = "Could not find app link in email"
            return
        }

        guard let url = URL(string: deepLink) else {
            errorMessage = "Invalid app link format"
            return
        }

        // Check if app can be opened
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                if success {
                    showSuccessMessage = true
                    errorMessage = nil

                    // Haptic feedback
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)

                    // Auto-dismiss after 1.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isPresented = false
                    }
                } else {
                    errorMessage = "Failed to open app. Please install it from the App Store."
                }
            }
        } else {
            errorMessage = "App not installed. Please download it from the App Store."
        }
    }

    /// Copy deep link to clipboard
    func copyLink() {
        if let deepLink = extractDeepLink() {
            UIPasteboard.general.string = deepLink

            // Show success feedback
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)

            // Show temporary message
            showSuccessMessage = true
            errorMessage = nil

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showSuccessMessage = false
            }
        } else {
            errorMessage = "No link found to copy"
        }
    }
}
