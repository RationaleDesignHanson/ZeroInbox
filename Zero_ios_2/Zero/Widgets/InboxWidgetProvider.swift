import WidgetKit
import SwiftUI

/// Timeline provider for inbox widgets
/// Fetches email data from shared UserDefaults and provides timeline entries
struct InboxWidgetProvider: TimelineProvider {

    // MARK: - TimelineProvider Protocol

    func placeholder(in context: Context) -> InboxWidgetEntry {
        InboxWidgetEntry(
            date: Date(),
            unreadCount: 5,
            urgentCount: 2,
            topPriorityEmail: WidgetEmail(
                id: "placeholder",
                title: "Important Meeting Tomorrow",
                sender: "boss@company.com",
                archetype: "work",
                hpa: "Add to Calendar",
                timeAgo: "2h ago"
            ),
            recentEmails: []
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (InboxWidgetEntry) -> Void) {
        let entry = fetchCurrentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<InboxWidgetEntry>) -> Void) {
        let entry = fetchCurrentEntry()

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    // MARK: - Data Fetching

    /// Fetch current inbox data from shared UserDefaults
    private func fetchCurrentEntry() -> InboxWidgetEntry {
        // Use App Group to share data between app and widget
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.zero.email") else {
            return placeholderEntry()
        }

        // Fetch cached email data
        let unreadCount = sharedDefaults.integer(forKey: "widget_unread_count")
        let urgentCount = sharedDefaults.integer(forKey: "widget_urgent_count")

        var topPriorityEmail: WidgetEmail? = nil
        if let topEmailData = sharedDefaults.data(forKey: "widget_top_email"),
           let decoded = try? JSONDecoder().decode(WidgetEmail.self, from: topEmailData) {
            topPriorityEmail = decoded
        }

        var recentEmails: [WidgetEmail] = []
        if let recentData = sharedDefaults.data(forKey: "widget_recent_emails"),
           let decoded = try? JSONDecoder().decode([WidgetEmail].self, from: recentData) {
            recentEmails = decoded
        }

        return InboxWidgetEntry(
            date: Date(),
            unreadCount: unreadCount,
            urgentCount: urgentCount,
            topPriorityEmail: topPriorityEmail,
            recentEmails: recentEmails
        )
    }

    private func placeholderEntry() -> InboxWidgetEntry {
        InboxWidgetEntry(
            date: Date(),
            unreadCount: 0,
            urgentCount: 0,
            topPriorityEmail: nil,
            recentEmails: []
        )
    }
}

// MARK: - Widget Entry

/// Timeline entry containing inbox data for widget display
struct InboxWidgetEntry: TimelineEntry {
    let date: Date
    let unreadCount: Int
    let urgentCount: Int
    let topPriorityEmail: WidgetEmail?
    let recentEmails: [WidgetEmail]
}

// Note: WidgetEmail and WidgetDataService are now defined in Services/WidgetDataService.swift
// The main app and widget extension both share these models via the shared target membership
