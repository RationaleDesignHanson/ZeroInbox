import Foundation
import WidgetKit

// MARK: - Widget Data Service (Main App)

/// Service to update widget data from the main app
/// Call this whenever email data changes to keep widgets up-to-date
/// Widgets read from shared UserDefaults (App Group) and display inbox status
struct WidgetDataService {

    static func updateWidgetData(unreadCount: Int, urgentCount: Int, topEmail: EmailCard?, recentEmails: [EmailCard]) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.zero.email") else {
            Logger.warning("⚠️ Failed to access shared UserDefaults for widget - App Group may not be configured", category: .widget)
            return
        }

        // Save unread and urgent counts
        sharedDefaults.set(unreadCount, forKey: "widget_unread_count")
        sharedDefaults.set(urgentCount, forKey: "widget_urgent_count")

        // Save top priority email
        if let topEmail = topEmail {
            let widgetEmail = WidgetEmail(
                id: topEmail.id,
                title: topEmail.title,
                sender: topEmail.sender?.name ?? "Unknown",
                archetype: topEmail.type.rawValue,
                hpa: topEmail.hpa,
                timeAgo: topEmail.timeAgo
            )
            if let encoded = try? JSONEncoder().encode(widgetEmail) {
                sharedDefaults.set(encoded, forKey: "widget_top_email")
            }
        } else {
            sharedDefaults.removeObject(forKey: "widget_top_email")
        }

        // Save recent emails (up to 5)
        let widgetEmails = recentEmails.prefix(5).map { email in
            WidgetEmail(
                id: email.id,
                title: email.title,
                sender: email.sender?.name ?? "Unknown",
                archetype: email.type.rawValue,
                hpa: email.hpa,
                timeAgo: email.timeAgo
            )
        }
        if let encoded = try? JSONEncoder().encode(widgetEmails) {
            sharedDefaults.set(encoded, forKey: "widget_recent_emails")
        }

        // Trigger widget refresh
        WidgetCenter.shared.reloadAllTimelines()

        Logger.debug("✓ Widget data updated: \(unreadCount) unread, \(urgentCount) urgent", category: .widget)
    }
}

// MARK: - Widget Email Model

/// Lightweight email model for widget display
/// Must be Codable to store in UserDefaults, Identifiable for SwiftUI
struct WidgetEmail: Codable, Identifiable {
    let id: String
    let title: String
    let sender: String
    let archetype: String
    let hpa: String
    let timeAgo: String
}
