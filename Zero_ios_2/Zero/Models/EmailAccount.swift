import Foundation

/// Represents an email account (Gmail, Outlook, Yahoo)
struct EmailAccount: Identifiable, Codable, Hashable {
    let id: String // accountId from backend
    let email: String
    let provider: EmailProvider
    var isPrimary: Bool
    var enabled: Bool
    var lastSynced: Date?
    var unreadCount: Int?
    var tokenExpiry: Date?

    enum EmailProvider: String, Codable, CaseIterable {
        case gmail = "gmail"
        case outlook = "outlook"
        case yahoo = "yahoo"

        var displayName: String {
            switch self {
            case .gmail: return "Gmail"
            case .outlook: return "Outlook"
            case .yahoo: return "Yahoo"
            }
        }

        var iconName: String {
            switch self {
            case .gmail: return "envelope.fill"
            case .outlook: return "envelope.badge.fill"
            case .yahoo: return "envelope.open.fill"
            }
        }

        var color: (red: Double, green: Double, blue: Double) {
            switch self {
            case .gmail: return (0.85, 0.27, 0.23) // Gmail red
            case .outlook: return (0.0, 0.47, 0.84) // Outlook blue
            case .yahoo: return (0.4, 0.0, 0.8) // Yahoo purple
            }
        }
    }

    /// Get initials from email (first letter)
    var initial: String {
        email.prefix(1).uppercased()
    }

    /// Get display name (email without domain)
    var displayName: String {
        email.components(separatedBy: "@").first ?? email
    }

    /// Check if token is expired or about to expire
    var needsTokenRefresh: Bool {
        guard let expiry = tokenExpiry else { return false }
        // Refresh if expires within 5 minutes
        return expiry.timeIntervalSinceNow < 300
    }

    /// Time since last sync (for display)
    var lastSyncedText: String {
        guard let synced = lastSynced else { return "Never synced" }

        let interval = Date().timeIntervalSince(synced)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Sample Data for Previews
extension EmailAccount {
    static let sampleAccounts: [EmailAccount] = [
        EmailAccount(
            id: "account-1",
            email: "candace@gmail.com",
            provider: .gmail,
            isPrimary: true,
            enabled: true,
            lastSynced: Date().addingTimeInterval(-300), // 5 min ago
            unreadCount: 24,
            tokenExpiry: Date().addingTimeInterval(3600) // 1 hour from now
        ),
        EmailAccount(
            id: "account-2",
            email: "work@company.com",
            provider: .gmail,
            isPrimary: false,
            enabled: true,
            lastSynced: Date().addingTimeInterval(-1800), // 30 min ago
            unreadCount: 12,
            tokenExpiry: Date().addingTimeInterval(3600)
        ),
        EmailAccount(
            id: "account-3",
            email: "side@freelance.com",
            provider: .outlook,
            isPrimary: false,
            enabled: false, // Disabled
            lastSynced: Date().addingTimeInterval(-86400), // 1 day ago
            unreadCount: 6,
            tokenExpiry: Date().addingTimeInterval(-3600) // Expired
        )
    ]
}
