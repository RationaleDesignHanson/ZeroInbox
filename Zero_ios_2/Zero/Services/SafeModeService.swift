import Foundation

/// Safe Mode Service - Prevents accidental email sending during testing
/// Provides three modes: production, demo (redirects emails), and readonly
class SafeModeService {
    static let shared = SafeModeService()

    private init() {}

    // MARK: - Safe Mode Configuration

    enum SafeMode: String {
        case production   // Normal operation - emails sent to real recipients
        case demo         // All emails redirected to test address
        case readOnly     // No emails sent at all (simulate success)

        var description: String {
            switch self {
            case .production:
                return "Production Mode - Real emails will be sent"
            case .demo:
                return "Demo Mode - Emails redirected to test address"
            case .readOnly:
                return "Read-Only Mode - No emails sent (simulation only)"
            }
        }

        var icon: String {
            switch self {
            case .production:
                return "checkmark.shield.fill"
            case .demo:
                return "testtube.2"
            case .readOnly:
                return "eye.slash.fill"
            }
        }

        var color: String {
            switch self {
            case .production:
                return "green"
            case .demo:
                return "orange"
            case .readOnly:
                return "blue"
            }
        }
    }

    // Current mode - defaults to readOnly for safety
    var currentMode: SafeMode {
        get {
            if let modeString = UserDefaults.standard.string(forKey: "safeMode"),
               let mode = SafeMode(rawValue: modeString) {
                return mode
            }
            return .readOnly // Default to safest mode
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "safeMode")
            Logger.info("Safe Mode changed to: \(newValue.description)", category: .app)

            // Log mode change for auditing
            AnalyticsService.shared.log("safe_mode_changed", properties: [
                "mode": newValue.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ])
        }
    }

    // Test email address for demo mode
    var testEmail: String {
        get {
            UserDefaults.standard.string(forKey: "testEmail") ?? Constants.UserDefaults.demoEmail
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "testEmail")
        }
    }

    // MARK: - Email Interception

    /// Process an outgoing email based on safe mode settings
    /// Returns modified recipient or nil if email should be blocked
    func processOutgoingEmail(
        to recipient: String,
        subject: String,
        body: String,
        hasAttachment: Bool
    ) -> (shouldSend: Bool, modifiedRecipient: String?, warningMessage: String?) {

        switch currentMode {
        case .production:
            // Production mode - allow email to be sent normally
            Logger.info("📧 [PRODUCTION] Sending email to: \(recipient)", category: .network)
            return (true, recipient, nil)

        case .demo:
            // Demo mode - redirect to test email
            let originalRecipient = recipient
            let testRecipient = testEmail

            Logger.info("📧 [DEMO MODE] Redirecting email", category: .network)
            Logger.info("  Original recipient: \(originalRecipient)", category: .network)
            Logger.info("  Redirected to: \(testRecipient)", category: .network)
            Logger.info("  Subject: \(subject)", category: .network)

            // Modify subject to show original recipient (for future use in email headers)
            let _ = "[DEMO - Originally to: \(originalRecipient)] \(subject)"

            let warning = "Demo Mode: Email redirected to \(testRecipient)"

            return (true, testRecipient, warning)

        case .readOnly:
            // Read-only mode - block email entirely
            Logger.warning("📧 [READ-ONLY] Email blocked (simulation mode)", category: .network)
            Logger.warning("  Would have sent to: \(recipient)", category: .network)
            Logger.warning("  Subject: \(subject)", category: .network)
            Logger.warning("  Has attachment: \(hasAttachment)", category: .network)

            // Log blocked email for audit trail
            AnalyticsService.shared.log("email_blocked_readonly", properties: [
                "recipient": recipient,
                "subject": subject,
                "has_attachment": hasAttachment,
                "timestamp": Date().timeIntervalSince1970
            ])

            let warning = "Read-Only Mode: Email not sent (simulation only)"

            return (false, nil, warning)
        }
    }

    // MARK: - User Warnings

    /// Get warning banner text for current mode
    func getModeWarningBanner() -> (text: String, color: String)? {
        switch currentMode {
        case .production:
            return nil // No warning in production

        case .demo:
            return (
                text: "⚠️ Demo Mode Active - Emails redirected to \(testEmail)",
                color: "orange"
            )

        case .readOnly:
            return (
                text: "🔒 Read-Only Mode - No emails will be sent",
                color: "blue"
            )
        }
    }

    // MARK: - Mode Validation

    /// Check if it's safe to perform write operations
    var canWriteData: Bool {
        currentMode != .readOnly
    }

    /// Require confirmation before switching to production mode
    func requiresConfirmation(for mode: SafeMode) -> Bool {
        return mode == .production && currentMode != .production
    }

    // MARK: - Statistics

    /// Get blocked email count (read-only mode)
    var blockedEmailCount: Int {
        get {
            UserDefaults.standard.integer(forKey: "blockedEmailCount")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "blockedEmailCount")
        }
    }

    /// Get redirected email count (demo mode)
    var redirectedEmailCount: Int {
        get {
            UserDefaults.standard.integer(forKey: "redirectedEmailCount")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "redirectedEmailCount")
        }
    }

    /// Reset statistics
    func resetStatistics() {
        blockedEmailCount = 0
        redirectedEmailCount = 0
    }
}
