import Foundation

/// Service for sanitizing email content by removing PII (Personally Identifiable Information)
/// Used to prepare email data for training while protecting user privacy
class EmailSanitizer {

    // MARK: - Version

    static let version = "1.0.0"

    // MARK: - Sanitized Email Model

    struct SanitizedEmail {
        let subject: String
        let from: String
        let fromDomain: String?
        let snippet: String
        let body: String?
        let sanitizationApplied: Bool
        let sanitizationVersion: String
    }

    // MARK: - Public API

    /// Sanitizes email content by removing PII
    /// - Parameters:
    ///   - subject: Email subject line
    ///   - from: Sender email address
    ///   - snippet: Email preview/snippet
    ///   - body: Full email body (optional)
    /// - Returns: Sanitized email with PII redacted
    static func sanitize(subject: String, from: String, snippet: String?, body: String?) -> SanitizedEmail {
        return SanitizedEmail(
            subject: redactPII(subject),
            from: redactEmailAddress(from),
            fromDomain: extractDomain(from),
            snippet: redactPII(snippet ?? ""),
            body: body != nil ? redactPII(body!) : nil,
            sanitizationApplied: true,
            sanitizationVersion: version
        )
    }

    // MARK: - Domain Extraction

    /// Extracts domain from email address while removing username
    /// Example: "john.doe@gmail.com" → "gmail.com"
    private static func extractDomain(_ email: String) -> String? {
        let components = email.components(separatedBy: "@")
        guard components.count == 2 else { return nil }
        return components[1].lowercased()
    }

    /// Redacts email address but preserves domain if requested
    /// Example: "john.doe@gmail.com" → "<EMAIL>@gmail.com"
    private static func redactEmailAddress(_ email: String, preserveDomain: Bool = false) -> String {
        guard preserveDomain else {
            return "<EMAIL>"
        }

        let components = email.components(separatedBy: "@")
        guard components.count == 2 else { return "<EMAIL>" }
        return "<EMAIL>@\(components[1])"
    }

    // MARK: - PII Redaction

    /// Redacts all PII from text using regex patterns
    /// Redacts: emails, phones, credit cards, SSNs, URLs, IP addresses
    private static func redactPII(_ text: String) -> String {
        var sanitized = text

        // 1. Email addresses
        // Pattern: anything@domain.tld
        sanitized = sanitized.replacingOccurrences(
            of: "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}",
            with: "<EMAIL>",
            options: .regularExpression
        )

        // 2. Phone numbers (multiple formats)
        // Matches: (555) 123-4567, 555-123-4567, 555.123.4567, +1-555-123-4567, etc.
        let phonePatterns = [
            // US format with country code
            "\\+?1?[-.]?\\s?\\(?([0-9]{3})\\)?[-.]?\\s?([0-9]{3})[-.]?\\s?([0-9]{4})",
            // International format
            "\\+[0-9]{1,3}[-.]?\\s?\\(?([0-9]{1,4})\\)?[-.]?\\s?([0-9]{1,4})[-.]?\\s?([0-9]{1,9})",
            // Simple 10-digit
            "\\b[0-9]{3}[-.]?[0-9]{3}[-.]?[0-9]{4}\\b"
        ]

        for pattern in phonePatterns {
            sanitized = sanitized.replacingOccurrences(
                of: pattern,
                with: "<PHONE>",
                options: .regularExpression
            )
        }

        // 3. Credit card numbers (13-19 digits with optional spaces/dashes)
        // Matches: 4532-1234-5678-9010, 4532 1234 5678 9010, 4532123456789010
        sanitized = sanitized.replacingOccurrences(
            of: "\\b(?:[0-9]{4}[-\\s]?){3}[0-9]{1,4}\\b",
            with: "<CARD>",
            options: .regularExpression
        )

        // Also catch continuous 13-19 digit sequences (catches cards without separators)
        sanitized = sanitized.replacingOccurrences(
            of: "\\b[0-9]{13,19}\\b",
            with: "<CARD>",
            options: .regularExpression
        )

        // 4. Social Security Numbers
        // Matches: 123-45-6789
        sanitized = sanitized.replacingOccurrences(
            of: "\\b[0-9]{3}-[0-9]{2}-[0-9]{4}\\b",
            with: "<SSN>",
            options: .regularExpression
        )

        // 5. URLs (partial redaction - keep domain for context)
        // Replace protocol and path, keep domain
        sanitized = sanitized.replacingOccurrences(
            of: "https?://([a-zA-Z0-9.-]+)(/[^\\s]*)?",
            with: "<URL:$1>",
            options: .regularExpression
        )

        // 6. IP Addresses
        // Matches: 192.168.1.1
        sanitized = sanitized.replacingOccurrences(
            of: "\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b",
            with: "<IP>",
            options: .regularExpression
        )

        // 7. Tracking numbers (common formats)
        // UPS: 1Z + 16 chars, FedEx: 12-14 digits, USPS: 20-22 digits
        sanitized = sanitized.replacingOccurrences(
            of: "\\b1Z[A-Z0-9]{16}\\b",
            with: "<TRACKING>",
            options: .regularExpression
        )

        sanitized = sanitized.replacingOccurrences(
            of: "\\b[0-9]{12,14}\\b",
            with: "<TRACKING>",
            options: .regularExpression
        )

        // 8. Order/Invoice numbers (common patterns)
        // Matches: Order #12345, Invoice #INV-12345, Order ID: 12345
        sanitized = sanitized.replacingOccurrences(
            of: "(?:Order|Invoice|ID)\\s*[#:]?\\s*[A-Z0-9-]{4,}",
            with: "Order <ORDER_ID>",
            options: [.regularExpression, .caseInsensitive]
        )

        return sanitized
    }

    // MARK: - Statistics

    /// Analyzes text and returns count of PII elements detected
    /// Useful for logging and validation
    static func analyzePII(_ text: String) -> PIIAnalysis {
        var analysis = PIIAnalysis()

        // Count email addresses
        let emailPattern = "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"
        if let regex = try? NSRegularExpression(pattern: emailPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            analysis.emailCount = matches.count
        }

        // Count phone numbers
        let phonePattern = "\\+?1?[-.]?\\s?\\(?([0-9]{3})\\)?[-.]?\\s?([0-9]{3})[-.]?\\s?([0-9]{4})"
        if let regex = try? NSRegularExpression(pattern: phonePattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            analysis.phoneCount = matches.count
        }

        // Count credit cards
        let cardPattern = "\\b(?:[0-9]{4}[-\\s]?){3}[0-9]{1,4}\\b"
        if let regex = try? NSRegularExpression(pattern: cardPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            analysis.creditCardCount = matches.count
        }

        // Count SSNs
        let ssnPattern = "\\b[0-9]{3}-[0-9]{2}-[0-9]{4}\\b"
        if let regex = try? NSRegularExpression(pattern: ssnPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            analysis.ssnCount = matches.count
        }

        return analysis
    }

    /// PII analysis result
    struct PIIAnalysis {
        var emailCount: Int = 0
        var phoneCount: Int = 0
        var creditCardCount: Int = 0
        var ssnCount: Int = 0

        var totalPIICount: Int {
            return emailCount + phoneCount + creditCardCount + ssnCount
        }

        var hasPII: Bool {
            return totalPIICount > 0
        }
    }
}
