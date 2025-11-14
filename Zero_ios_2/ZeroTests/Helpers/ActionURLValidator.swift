import XCTest
@testable import Zero

/**
 * ActionURLValidator
 * Validates URL generation and format for GO_TO actions
 *
 * Ensures all external URL actions:
 * - Generate valid URLs
 * - Handle required/optional context correctly
 * - Use proper URL encoding
 * - Follow consistent URL patterns
 */

class ActionURLValidator {

    // MARK: - URL Validation

    /// Validates that a URL string is properly formed
    static func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        guard let scheme = url.scheme else { return false }

        // Check for valid HTTP/HTTPS schemes or custom app schemes
        let validSchemes = ["http", "https", "mailto", "tel", "sms"]
        let isStandardScheme = validSchemes.contains(scheme.lowercased())
        let isCustomAppScheme = scheme.contains(".")  // e.g., com.example.app://

        return isStandardScheme || isCustomAppScheme
    }

    /// Validates URL with context requirements
    static func validateURL(for actionId: String, context: [String: String]) -> URLValidationResult {
        guard let actionConfig = ActionRegistry.shared.getAction(actionId) else {
            return URLValidationResult(
                isValid: false,
                url: nil,
                errors: ["Action '\(actionId)' not found in registry"]
            )
        }

        // GO_TO actions must have a URL
        guard actionConfig.actionType == .goTo else {
            return URLValidationResult(
                isValid: false,
                url: nil,
                errors: ["Action '\(actionId)' is not a GO_TO action"]
            )
        }

        // Check for URL in context
        var url: String? = nil
        var errors: [String] = []

        // Look for URL in various context keys
        let urlKeys = ["url", "link", "\(actionId)Url", "actionUrl"]
        for key in urlKeys {
            if let foundURL = context[key] {
                url = foundURL
                break
            }
        }

        guard let urlString = url, !urlString.isEmpty else {
            errors.append("Missing URL in context for GO_TO action '\(actionId)'")
            return URLValidationResult(isValid: false, url: nil, errors: errors)
        }

        // Validate URL format
        if !isValidURL(urlString) {
            errors.append("Invalid URL format: '\(urlString)'")
            return URLValidationResult(isValid: false, url: urlString, errors: errors)
        }

        // Validate required context keys are present
        let missingKeys = actionConfig.requiredContextKeys.filter { context[$0] == nil }
        if !missingKeys.isEmpty {
            errors.append("Missing required context keys: \(missingKeys.joined(separator: ", "))")
        }

        let isValid = errors.isEmpty
        return URLValidationResult(isValid: isValid, url: urlString, errors: errors)
    }

    // MARK: - Bulk Validation

    /// Validates all GO_TO actions in registry
    static func validateAllGoToActions() -> ActionValidationReport {
        let registry = ActionRegistry.shared
        let goToActions = registry.registry.values.filter { $0.actionType == .goTo }

        var validActions: [String] = []
        var invalidActions: [String: [String]] = [:]
        var warnings: [String] = []

        for action in goToActions {
            // Generate sample context based on required keys
            var sampleContext: [String: String] = [:]

            // Always include a URL for GO_TO actions
            sampleContext["url"] = "https://example.com/\(action.actionId)"

            // Add sample values for required context keys
            for key in action.requiredContextKeys where key != "url" {
                sampleContext[key] = "sample_\(key)_value"
            }

            let validation = validateURL(for: action.actionId, context: sampleContext)

            if validation.isValid {
                validActions.append(action.actionId)
            } else {
                invalidActions[action.actionId] = validation.errors
            }

            // Check for URL encoding issues
            if let url = validation.url, url.contains(" ") {
                warnings.append("Action '\(action.actionId)' URL contains spaces (needs encoding)")
            }
        }

        return ActionValidationReport(
            totalActions: goToActions.count,
            validActions: validActions,
            invalidActions: invalidActions,
            warnings: warnings
        )
    }

    // MARK: - Common URL Patterns

    /// Validates common URL patterns for specific action types
    static func validateURLPattern(for actionId: String, url: String) -> URLPatternValidation {
        var expectedPatterns: [String] = []
        var matchesPattern = false

        // Define expected URL patterns for common actions
        switch actionId {
        case "track_package":
            expectedPatterns = ["ups.com", "fedex.com", "usps.com", "dhl.com", "track"]
            matchesPattern = expectedPatterns.contains { url.lowercased().contains($0) }

        case "view_order":
            expectedPatterns = ["order", "purchase", "receipt"]
            matchesPattern = expectedPatterns.contains { url.lowercased().contains($0) }

        case "pay_invoice":
            expectedPatterns = ["invoice", "payment", "pay", "bill"]
            matchesPattern = expectedPatterns.contains { url.lowercased().contains($0) }

        case "check_in_flight":
            expectedPatterns = ["checkin", "check-in", "boarding"]
            matchesPattern = expectedPatterns.contains { url.lowercased().contains($0) }

        case "get_directions":
            expectedPatterns = ["maps.apple.com", "maps.google.com", "waze.com", "directions"]
            matchesPattern = expectedPatterns.contains { url.lowercased().contains($0) }

        default:
            // For generic actions, just check URL is valid
            matchesPattern = isValidURL(url)
        }

        return URLPatternValidation(
            actionId: actionId,
            url: url,
            expectedPatterns: expectedPatterns,
            matchesPattern: matchesPattern
        )
    }

    // MARK: - URL Encoding

    /// Validates URL encoding for special characters
    static func validateURLEncoding(_ urlString: String) -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []

        // Check for unencoded spaces
        if urlString.contains(" ") {
            issues.append("URL contains unencoded spaces")
        }

        // Check for other special characters that should be encoded
        let specialChars = ["<", ">", "\"", "{", "}", "|", "\\", "^", "`", "[", "]"]
        for char in specialChars {
            if urlString.contains(char) {
                issues.append("URL contains unencoded special character: '\(char)'")
            }
        }

        let isValid = issues.isEmpty
        return (isValid, issues)
    }
}

// MARK: - Validation Result Types

struct URLValidationResult {
    let isValid: Bool
    let url: String?
    let errors: [String]

    var description: String {
        if isValid {
            return "✅ Valid URL: \(url ?? "nil")"
        } else {
            return "❌ Invalid:\n" + errors.map { "  - \($0)" }.joined(separator: "\n")
        }
    }
}

struct ActionValidationReport: CustomStringConvertible {
    let totalActions: Int
    let validActions: [String]
    let invalidActions: [String: [String]]
    let warnings: [String]

    var description: String {
        var report = """

        ===========================================
        GO_TO ACTION VALIDATION REPORT
        ===========================================
        Total GO_TO Actions:  \(totalActions)
        Valid Actions:        \(validActions.count)
        Invalid Actions:      \(invalidActions.count)
        Warnings:             \(warnings.count)
        Success Rate:         \(String(format: "%.1f", Double(validActions.count) / Double(totalActions) * 100))%

        """

        if !invalidActions.isEmpty {
            report += "\n❌ Invalid Actions:\n"
            for (actionId, errors) in invalidActions.sorted(by: { $0.key < $1.key }) {
                report += "  \(actionId):\n"
                errors.forEach { report += "    - \($0)\n" }
            }
        }

        if !warnings.isEmpty {
            report += "\n⚠️  Warnings:\n"
            warnings.forEach { report += "  - \($0)\n" }
        }

        report += "\n===========================================\n"
        return report
    }
}

struct URLPatternValidation {
    let actionId: String
    let url: String
    let expectedPatterns: [String]
    let matchesPattern: Bool

    var description: String {
        if matchesPattern {
            return "✅ \(actionId): URL matches expected pattern"
        } else if expectedPatterns.isEmpty {
            return "ℹ️  \(actionId): No specific pattern required"
        } else {
            return "⚠️  \(actionId): URL doesn't match expected patterns: \(expectedPatterns.joined(separator: ", "))"
        }
    }
}

// MARK: - XCTest Integration

extension XCTestCase {

    /// Assert that a GO_TO action generates a valid URL
    func assertValidURL(for actionId: String, context: [String: String], file: StaticString = #file, line: UInt = #line) {
        let validation = ActionURLValidator.validateURL(for: actionId, context: context)

        XCTAssertTrue(validation.isValid, "URL validation failed for '\(actionId)': \(validation.errors.joined(separator: ", "))", file: file, line: line)

        if let url = validation.url {
            XCTAssertTrue(ActionURLValidator.isValidURL(url), "Invalid URL format: '\(url)'", file: file, line: line)
        }
    }

    /// Assert that a URL matches expected pattern for action type
    func assertURLPattern(for actionId: String, url: String, file: StaticString = #file, line: UInt = #line) {
        let validation = ActionURLValidator.validateURLPattern(for: actionId, url: url)

        if !validation.expectedPatterns.isEmpty {
            XCTAssertTrue(validation.matchesPattern, "URL '\(url)' doesn't match expected pattern for '\(actionId)'. Expected patterns: \(validation.expectedPatterns.joined(separator: ", "))", file: file, line: line)
        }
    }
}
