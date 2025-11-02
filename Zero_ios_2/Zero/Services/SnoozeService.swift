import Foundation
import UserNotifications

class SnoozeService {
    static let shared = SnoozeService()

    private let userDefaults = UserDefaults.standard
    private let snoozedEmailsKey = "snoozedEmails"

    // Notification for snooze list changes
    static let snoozeListDidChangeNotification = Notification.Name("snoozeListDidChange")

    private init() {
        // Request notification permission on init
        requestNotificationPermission()
    }

    // MARK: - Notification Permission

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                Logger.info("Notification permission granted", category: .app)
            } else if let error = error {
                Logger.error("Notification permission error: \(error.localizedDescription)", category: .app)
            }
        }
    }

    // MARK: - Snooze Management

    /// Snooze an email until a specific time
    func snoozeEmail(_ email: EmailCard, until: Date, reason: String? = nil) {
        var snoozedEmails = getSnoozedEmails()

        let snooze = SnoozedEmail(
            emailId: email.id,
            emailTitle: email.title,
            emailSender: email.sender?.name ?? email.sender?.email ?? "Unknown",
            snoozeUntil: until,
            reason: reason ?? "Snoozed"
        )

        snoozedEmails.append(snooze)
        saveSnoozedEmails(snoozedEmails)

        // Schedule notification
        scheduleNotification(for: snooze)

        Logger.info("Snoozed email '\(email.title)' until \(until)", category: .app)

        // Analytics
        AnalyticsService.shared.log("email_snoozed", properties: [
            "email_id": email.id,
            "snooze_duration": until.timeIntervalSinceNow,
            "reason": reason ?? "manual"
        ])
    }

    /// Unsnooze an email
    func unsnoozeEmail(_ emailId: String) {
        var snoozedEmails = getSnoozedEmails()
        snoozedEmails.removeAll { $0.emailId == emailId }
        saveSnoozedEmails(snoozedEmails)

        // Cancel notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [emailId])

        Logger.info("Unsnoozed email: \(emailId)", category: .app)

        // Analytics
        AnalyticsService.shared.log("email_unsnoozed", properties: ["email_id": emailId])
    }

    /// Check if an email is snoozed
    func isSnoozed(_ emailId: String) -> Bool {
        return getSnoozedEmails().contains { $0.emailId == emailId }
    }

    /// Get snooze info for an email
    func getSnooze(for emailId: String) -> SnoozedEmail? {
        return getSnoozedEmails().first { $0.emailId == emailId }
    }

    /// Get all snoozed emails
    func getSnoozedEmails() -> [SnoozedEmail] {
        guard let data = userDefaults.data(forKey: snoozedEmailsKey),
              let emails = try? JSONDecoder().decode([SnoozedEmail].self, from: data) else {
            return []
        }
        return emails
    }

    /// Save snoozed emails to UserDefaults
    private func saveSnoozedEmails(_ emails: [SnoozedEmail]) {
        if let data = try? JSONEncoder().encode(emails) {
            userDefaults.set(data, forKey: snoozedEmailsKey)
            NotificationCenter.default.post(name: Self.snoozeListDidChangeNotification, object: nil)
        }
    }

    /// Get emails that should reappear now
    func getReappearedEmails() -> [SnoozedEmail] {
        let snoozedEmails = getSnoozedEmails()
        let now = Date()

        return snoozedEmails.filter { $0.snoozeUntil <= now }
    }

    /// Clean up expired snoozes
    func cleanupExpiredSnoozes() {
        let snoozedEmails = getSnoozedEmails()
        let now = Date()

        let activeSnoozes = snoozedEmails.filter { $0.snoozeUntil > now }
        saveSnoozedEmails(activeSnoozes)
    }

    // MARK: - Smart Snooze Suggestions

    /// Get intelligent snooze time suggestions based on email content
    func suggestSnoozeTimes(for email: EmailCard) -> [SnoozeOption] {
        var options: [SnoozeOption] = []
        let now = Date()
        let calendar = Calendar.current

        // Default options
        options.append(SnoozeOption(
            label: "Later Today",
            time: calendar.date(byAdding: .hour, value: 3, to: now) ?? now,
            icon: "clock",
            reason: "In 3 hours"
        ))

        options.append(SnoozeOption(
            label: "This Evening",
            time: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now,
            icon: "sunset",
            reason: "At 6:00 PM today"
        ))

        options.append(SnoozeOption(
            label: "Tomorrow Morning",
            time: {
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                components.day = (components.day ?? 0) + 1
                components.hour = 9
                components.minute = 0
                return calendar.date(from: components) ?? now
            }(),
            icon: "sunrise",
            reason: "Tomorrow at 9:00 AM"
        ))

        // Smart suggestions based on email content
        let text = "\(email.title) \(email.summary)".lowercased()

        // Deadline-based snoozes
        if let deadline = detectDeadline(from: text) {
            let reminderTime = calendar.date(byAdding: .hour, value: -24, to: deadline) ?? deadline
            options.insert(SnoozeOption(
                label: "Before Deadline",
                time: reminderTime,
                icon: "exclamationmark.triangle",
                reason: "1 day before deadline"
            ), at: 0)
        }

        // Event-based snoozes
        if text.contains("meeting") || text.contains("event") || text.contains("appointment") {
            let reminderTime = calendar.date(byAdding: .hour, value: -1, to: now) ?? now
            options.insert(SnoozeOption(
                label: "Before Meeting",
                time: reminderTime,
                icon: "calendar",
                reason: "1 hour before"
            ), at: 0)
        }

        // Next week for low priority
        if email.priority == .low {
            options.append(SnoozeOption(
                label: "Next Week",
                time: calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now,
                icon: "calendar.badge.clock",
                reason: "In 1 week"
            ))
        }

        return options
    }

    /// Detect deadline from email text
    private func detectDeadline(from text: String) -> Date? {
        let calendar = Calendar.current
        let now = Date()

        // Pattern 1: "due tomorrow"
        if text.contains("due tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: now)
        }

        // Pattern 2: "deadline friday", "due friday"
        let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        for (index, weekday) in weekdays.enumerated() {
            if text.contains("deadline \(weekday)") || text.contains("due \(weekday)") {
                let today = calendar.component(.weekday, from: now)
                let targetWeekday = index + 2 // Calendar weekdays are 1-indexed, Sunday = 1
                var daysToAdd = targetWeekday - today
                if daysToAdd <= 0 {
                    daysToAdd += 7
                }
                return calendar.date(byAdding: .day, value: daysToAdd, to: now)
            }
        }

        // Pattern 3: "due in X days"
        if let range = text.range(of: "due in (\\d+) days?", options: .regularExpression) {
            let daysString = text[range].replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            if let days = Int(daysString) {
                return calendar.date(byAdding: .day, value: days, to: now)
            }
        }

        return nil
    }

    // MARK: - Notifications

    /// Schedule local notification for snoozed email
    private func scheduleNotification(for snooze: SnoozedEmail) {
        let content = UNMutableNotificationContent()
        content.title = "Email Reminder"
        content.body = "\(snooze.emailTitle) from \(snooze.emailSender)"
        content.sound = .default
        content.badge = 1

        let timeInterval = snooze.snoozeUntil.timeIntervalSinceNow
        guard timeInterval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: snooze.emailId, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("Failed to schedule notification: \(error.localizedDescription)", category: .app)
            } else {
                Logger.info("Scheduled notification for \(snooze.emailTitle)", category: .app)
            }
        }
    }
}

// MARK: - Models

struct SnoozedEmail: Codable, Identifiable {
    let id = UUID()
    let emailId: String
    let emailTitle: String
    let emailSender: String
    let snoozeUntil: Date
    let reason: String

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: snoozeUntil)
    }

    enum CodingKeys: String, CodingKey {
        case emailId, emailTitle, emailSender, snoozeUntil, reason
    }
}

struct SnoozeOption: Identifiable {
    let id = UUID()
    let label: String
    let time: Date
    let icon: String
    let reason: String
}
