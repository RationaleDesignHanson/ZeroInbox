import Foundation

/**
 * ContentView+URLHelpers
 * URL extraction and validation helpers
 *
 * Phase 2 (Option 2): CLI-safe helper extraction
 */
extension ContentView {

    // MARK: - URL Extraction

    /// Extract URL from action context using multiple fallback strategies
    func extractURL(from context: [String: String], actionId: String) -> String? {
        // Strategy 1: Look for direct URL keys
        let urlKeys = ["url", "actionUrl", "link", "href", "checkInUrl", "trackingUrl", "bookingUrl"]
        for key in urlKeys {
            if let url = context[key], !url.isEmpty {
                Logger.info("Found URL in context[\(key)]: \(url)", category: .action)
                return url
            }
        }

        // Strategy 2: Action-specific keys
        switch actionId {
        case "check_in":
            if let url = context["checkInUrl"] ?? context["url"] {
                return url
            }
        case "track_package":
            if let url = context["trackingUrl"] ?? context["url"] {
                return url
            }
        case "view_receipt":
            if let url = context["receiptUrl"] ?? context["url"] {
                return url
            }
        case "manage_subscription":
            if let url = context["manageUrl"] ?? context["accountUrl"] ?? context["url"] {
                return url
            }
        default:
            break
        }

        // Strategy 3: Look for any value that looks like a URL
        for (key, value) in context {
            if value.hasPrefix("http://") || value.hasPrefix("https://") {
                Logger.info("Found URL-like value in context[\(key)]: \(value)", category: .action)
                return value
            }
        }

        Logger.warning("No URL found in context for action: \(actionId)", category: .action)
        return nil
    }

    // MARK: - URL Validation

    /// Validate and sanitize URL string
    func validateURL(_ urlString: String) -> URL? {
        // Remove whitespace and newlines
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try direct URL parsing
        if let url = URL(string: trimmed) {
            // Validate scheme
            guard let scheme = url.scheme?.lowercased() else {
                Logger.error("URL missing scheme: \(trimmed)", category: .action)
                return nil
            }

            // Only allow http/https
            guard scheme == "http" || scheme == "https" else {
                Logger.error("Invalid URL scheme '\(scheme)': \(trimmed)", category: .action)
                return nil
            }

            // Validate host exists
            guard url.host != nil else {
                Logger.error("URL missing host: \(trimmed)", category: .action)
                return nil
            }

            return url
        }

        // Try adding https:// prefix if missing
        if !trimmed.hasPrefix("http://") && !trimmed.hasPrefix("https://") {
            let withScheme = "https://\(trimmed)"
            if let url = URL(string: withScheme), url.host != nil {
                Logger.info("Added https:// scheme to URL: \(withScheme)", category: .action)
                return url
            }
        }

        Logger.error("Failed to parse URL: \(trimmed)", category: .action)
        return nil
    }

    // MARK: - Share Content Generation

    /// Generate shareable content from card context for social sharing
    func generateShareContentForModal(from card: EmailCard, context: [String: Any]) -> String {
        var content = ""

        // Add card title
        content += card.title + "\n\n"

        // Add relevant context fields
        if let details = context["details"] as? String {
            content += details + "\n\n"
        }

        // Add sender info
        if let sender = card.sender {
            content += "From: \(sender.name)\n"
        }

        // Add URL if available
        if let urlString = context["url"] as? String {
            content += "\nLink: \(urlString)"
        }

        return content
    }
}
