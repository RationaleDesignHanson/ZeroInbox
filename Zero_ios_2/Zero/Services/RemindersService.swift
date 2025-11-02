import Foundation
import EventKit

/// Service for creating reminders from emails
class RemindersService {
    static let shared = RemindersService()

    private let eventStore = EKEventStore()

    private init() {}

    // MARK: - Create Reminder

    /// Create a reminder from email card
    /// - Parameters:
    ///   - title: Reminder title
    ///   - notes: Reminder notes/description
    ///   - dueDate: Due date for reminder
    ///   - priority: Priority level (0-9, where 0 is none, 1-4 is high, 5 is medium, 6-9 is low)
    ///   - completion: Callback with success or error
    func createReminder(
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        priority: Int = 0,
        url: URL? = nil,
        completion: @escaping (Result<EKReminder, Error>) -> Void
    ) {
        Task {
            do {
                // Request reminders access
                let granted = try await eventStore.requestFullAccessToReminders()

                guard granted else {
                    await MainActor.run {
                        completion(.failure(RemindersError.accessDenied))
                    }
                    return
                }

                // Create reminder
                let reminder = EKReminder(eventStore: eventStore)
                reminder.title = title
                reminder.notes = notes
                reminder.calendar = eventStore.defaultCalendarForNewReminders()
                reminder.priority = priority

                // Set due date if provided
                if let dueDate = dueDate {
                    let components = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute],
                        from: dueDate
                    )
                    reminder.dueDateComponents = components
                }

                // Set URL if provided
                if let url = url {
                    reminder.url = url
                }

                // Save reminder
                try eventStore.save(reminder, commit: true)

                await MainActor.run {
                    Logger.info("Reminder created: \(title)", category: .action)
                    completion(.success(reminder))
                }

            } catch {
                await MainActor.run {
                    Logger.error("Failed to create reminder: \(error.localizedDescription)", category: .action)
                    completion(.failure(error))
                }
            }
        }
    }

    /// Create reminder from email card with smart date detection
    func createReminderFromEmail(
        card: EmailCard,
        customTitle: String? = nil,
        customDate: Date? = nil,
        completion: @escaping (Result<EKReminder, Error>) -> Void
    ) {
        let title = customTitle ?? generateReminderTitle(from: card)
        let notes = generateReminderNotes(from: card)
        let dueDate = customDate ?? detectDueDate(from: card)
        let priority = detectPriority(from: card)

        // TODO: Extract URL from card.suggestedActions if available
        let url: URL? = nil

        createReminder(
            title: title,
            notes: notes,
            dueDate: dueDate,
            priority: priority,
            url: url,
            completion: completion
        )
    }

    // MARK: - Smart Detection

    private func generateReminderTitle(from card: EmailCard) -> String {
        let text = card.title.lowercased()

        // If it's a form that needs signing
        if text.contains("permission form") || text.contains("sign") {
            return "Sign \(card.title)"
        }

        // If it's a payment
        if text.contains("invoice") || text.contains("payment") || text.contains("bill") {
            return "Pay \(card.title)"
        }

        // If it's RSVP
        if text.contains("rsvp") || text.contains("respond") {
            return "RSVP to \(card.title)"
        }

        // If it's a deadline
        if text.contains("deadline") || text.contains("due") {
            return "Complete: \(card.title)"
        }

        // Default
        return "Follow up: \(card.title)"
    }

    private func generateReminderNotes(from card: EmailCard) -> String {
        var notes = card.summary

        // Add sender info if available
        if let sender = card.sender {
            notes += "\n\nFrom: \(sender.name)"
            if let email = sender.email {
                notes += " <\(email)>"
            }
        }

        // Add kid info if relevant
        if let kid = card.kid {
            notes += "\nFor: \(kid.name) - \(kid.grade)"
        }

        // Add payment info if available
        if let amount = card.paymentAmount {
            notes += "\nAmount: $\(String(format: "%.2f", amount))"
        }

        return notes
    }

    private func detectDueDate(from card: EmailCard) -> Date? {
        let text = "\(card.title) \(card.summary)".lowercased()

        // Pattern 1: "by [date]" or "due [date]"
        if let date = extractDateFromText(text, keywords: ["by", "due", "before"]) {
            return date
        }

        // Pattern 2: Specific urgency keywords
        if text.contains("urgent") || text.contains("asap") || text.contains("today") {
            // Due today at end of day
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 17 // 5 PM
            components.minute = 0
            return Calendar.current.date(from: components)
        }

        if text.contains("tomorrow") {
            // Due tomorrow at 9 AM
            guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else {
                return nil
            }
            var components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 9
            components.minute = 0
            return Calendar.current.date(from: components)
        }

        if text.contains("this week") {
            // Due end of this week (Friday at 5 PM)
            let today = Date()
            let weekday = Calendar.current.component(.weekday, from: today)
            let daysUntilFriday = (6 - weekday + 7) % 7 // 6 = Friday
            guard let friday = Calendar.current.date(byAdding: .day, value: daysUntilFriday, to: today) else {
                return nil
            }
            var components = Calendar.current.dateComponents([.year, .month, .day], from: friday)
            components.hour = 17
            components.minute = 0
            return Calendar.current.date(from: components)
        }

        if text.contains("next week") {
            // Due next week (7 days from now at 9 AM)
            guard let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) else {
                return nil
            }
            var components = Calendar.current.dateComponents([.year, .month, .day], from: nextWeek)
            components.hour = 9
            components.minute = 0
            return Calendar.current.date(from: components)
        }

        // Default: 3 days from now at 9 AM (reasonable default for follow-up)
        guard let defaultDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) else {
            return nil
        }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: defaultDate)
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components)
    }

    private func detectPriority(from card: EmailCard) -> Int {
        let text = "\(card.title) \(card.summary)".lowercased()

        // High priority (1-4, using 1 for highest)
        if text.contains("urgent") || text.contains("asap") || text.contains("critical") || text.contains("important") {
            return 1
        }

        // Medium priority (5)
        if text.contains("please") || text.contains("reminder") || card.paymentAmount != nil {
            return 5
        }

        // Low priority (6-9, using 9 for lowest)
        return 9
    }

    private func extractDateFromText(_ text: String, keywords: [String]) -> Date? {
        // This is a simplified date extraction
        // In production, you'd want more sophisticated NLP date parsing

        let monthNames = ["january", "february", "march", "april", "may", "june",
                          "july", "august", "september", "october", "november", "december"]

        for (index, month) in monthNames.enumerated() {
            // Check for full month name with day
            if let range = text.range(of: "\\b\(month)\\s+(\\d{1,2})(st|nd|rd|th)?\\b",
                                      options: .regularExpression) {
                let dayString = text[range].replacingOccurrences(of: "[a-z]", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                    .components(separatedBy: .whitespaces)
                    .last ?? ""

                if let day = Int(dayString) {
                    var components = Calendar.current.dateComponents([.year], from: Date())
                    components.month = index + 1
                    components.day = day
                    components.hour = 9 // Default to 9 AM
                    components.minute = 0

                    if let detectedDate = Calendar.current.date(from: components) {
                        // If date is in the past, assume next year
                        if detectedDate < Date() {
                            components.year = (components.year ?? 0) + 1
                            return Calendar.current.date(from: components)
                        }
                        return detectedDate
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Detect Reminder Opportunities

    /// Detect if email needs a reminder
    func detectReminderOpportunity(in card: EmailCard) -> ReminderOpportunity? {
        let text = "\(card.title) \(card.summary)".lowercased()

        // Check for action items
        if text.contains("please") && (text.contains("respond") || text.contains("reply") || text.contains("rsvp")) {
            return ReminderOpportunity(
                title: "Respond to: \(card.title)",
                suggestedDate: detectDueDate(from: card),
                priority: detectPriority(from: card),
                reason: "This email requires a response"
            )
        }

        // Check for deadlines
        if text.contains("deadline") || text.contains("due") || text.contains("by") {
            return ReminderOpportunity(
                title: generateReminderTitle(from: card),
                suggestedDate: detectDueDate(from: card),
                priority: 1, // High priority
                reason: "This email has a deadline"
            )
        }

        // Check for forms
        if text.contains("form") && (text.contains("sign") || text.contains("complete") || text.contains("fill")) {
            return ReminderOpportunity(
                title: "Complete form: \(card.title)",
                suggestedDate: detectDueDate(from: card),
                priority: 5,
                reason: "This form needs to be completed"
            )
        }

        // Check for payments
        if text.contains("invoice") || text.contains("payment") || text.contains("bill") {
            return ReminderOpportunity(
                title: "Pay: \(card.title)",
                suggestedDate: detectDueDate(from: card),
                priority: 1,
                reason: "This payment is due"
            )
        }

        return nil
    }
}

// MARK: - Models

struct ReminderOpportunity {
    let title: String
    let suggestedDate: Date?
    let priority: Int
    let reason: String
}

// MARK: - Errors

enum RemindersError: LocalizedError {
    case accessDenied
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Reminders access was denied. Please enable it in Settings."
        case .saveFailed(let error):
            return "Failed to save reminder: \(error.localizedDescription)"
        }
    }
}
