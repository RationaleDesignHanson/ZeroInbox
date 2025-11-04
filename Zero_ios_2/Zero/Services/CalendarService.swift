import Foundation
import EventKit

class CalendarService {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()

    private init() {}

    // MARK: - Calendar Permissions

    enum CalendarError: LocalizedError {
        case permissionDenied
        case eventCreationFailed
        case noCalendarsAvailable
        case invalidEventData

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Calendar access denied. Please enable in Settings > Privacy > Calendars."
            case .eventCreationFailed:
                return "Failed to create calendar event."
            case .noCalendarsAvailable:
                return "No calendars available. Please create a calendar first."
            case .invalidEventData:
                return "Invalid event data provided."
            }
        }
    }

    /// Request calendar access (iOS 17+ uses new API)
    func requestAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            // iOS 17+ new authorization API
            let status = try await eventStore.requestFullAccessToEvents()
            Logger.info("Calendar access status: \(status)", category: .app)
            return status
        } else {
            // iOS 16 and earlier
            return try await withCheckedThrowingContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }

    /// Check current authorization status
    var authorizationStatus: EKAuthorizationStatus {
        if #available(iOS 17.0, *) {
            return EKEventStore.authorizationStatus(for: .event)
        } else {
            return EKEventStore.authorizationStatus(for: .event)
        }
    }

    var isAuthorized: Bool {
        if #available(iOS 17.0, *) {
            return authorizationStatus == .fullAccess || authorizationStatus == .writeOnly
        } else {
            return authorizationStatus == .authorized
        }
    }

    // MARK: - Event Creation

    struct CalendarEventData {
        let title: String
        let startDate: Date
        let endDate: Date
        let location: String?
        let notes: String?
        let url: URL?
        let isAllDay: Bool

        init(
            title: String,
            startDate: Date,
            endDate: Date,
            location: String? = nil,
            notes: String? = nil,
            url: URL? = nil,
            isAllDay: Bool = false
        ) {
            self.title = title
            self.startDate = startDate
            self.endDate = endDate
            self.location = location
            self.notes = notes
            self.url = url
            self.isAllDay = isAllDay
        }
    }

    /// Create a calendar event from CalendarInvite model
    func createEvent(from invite: CalendarInvite, emailBody: String? = nil) async throws {
        // Check permissions first
        if !isAuthorized {
            Logger.warning("Calendar not authorized, requesting access", category: .app)
            let granted = try await requestAccess()
            guard granted else {
                throw CalendarError.permissionDenied
            }
        }

        // Parse event data from invite
        guard let title = invite.meetingTitle,
              let timeString = invite.meetingTime else {
            throw CalendarError.invalidEventData
        }

        // Parse date from time string (backend should provide ISO 8601)
        let startDate = parseDate(from: timeString) ?? Date()
        let endDate = startDate.addingTimeInterval(3600) // Default 1 hour duration

        // Build notes from email context
        var notes = ""
        if let organizer = invite.organizer {
            notes += "Organizer: \(organizer)\n\n"
        }
        if let meetingUrl = invite.meetingUrl {
            notes += "Join: \(meetingUrl)\n\n"
        }
        if let body = emailBody {
            notes += "Details:\n\(body)"
        }

        let eventData = CalendarEventData(
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: invite.meetingUrl, // Use meeting URL as location for quick access
            notes: notes,
            url: invite.meetingUrl.flatMap { URL(string: $0) },
            isAllDay: false
        )

        try await createEvent(eventData)
    }

    /// Create a calendar event with custom data
    func createEvent(_ eventData: CalendarEventData) async throws {
        // Check permissions
        guard isAuthorized else {
            throw CalendarError.permissionDenied
        }

        // Get default calendar
        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            throw CalendarError.noCalendarsAvailable
        }

        // Create event
        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = eventData.title
        event.startDate = eventData.startDate
        event.endDate = eventData.endDate
        event.location = eventData.location
        event.notes = eventData.notes
        event.url = eventData.url
        event.isAllDay = eventData.isAllDay

        // Set availability to busy
        event.availability = .busy

        // Add alarm (15 minutes before)
        let alarm = EKAlarm(relativeOffset: -15 * 60) // 15 minutes in seconds
        event.addAlarm(alarm)

        // Save event
        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            Logger.info("✅ Calendar event created: \(eventData.title)", category: .app)

            // Log analytics
            AnalyticsService.shared.log("calendar_event_created", properties: [
                "title": eventData.title,
                "has_location": eventData.location != nil,
                "has_url": eventData.url != nil,
                "is_all_day": eventData.isAllDay
            ])

            // Haptic feedback
            HapticService.shared.success()
        } catch {
            Logger.error("Failed to save calendar event: \(error.localizedDescription)", category: .app)
            throw CalendarError.eventCreationFailed
        }
    }

    /// Convenience method for adding events with completion handler (for backwards compatibility)
    func addEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        notes: String? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Task {
            do {
                let eventData = CalendarEventData(
                    title: title,
                    startDate: startDate,
                    endDate: endDate,
                    location: location,
                    notes: notes
                )
                try await createEvent(eventData)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Meeting URL Detection

    /// Extract meeting platform from URL
    func detectMeetingPlatform(from url: String) -> String? {
        let lowercased = url.lowercased()

        if lowercased.contains("zoom.us") {
            return "Zoom"
        } else if lowercased.contains("meet.google.com") {
            return "Google Meet"
        } else if lowercased.contains("teams.microsoft.com") {
            return "Microsoft Teams"
        } else if lowercased.contains("webex.com") {
            return "Webex"
        } else if lowercased.contains("gotomeeting.com") {
            return "GoToMeeting"
        } else if lowercased.contains("whereby.com") {
            return "Whereby"
        } else if lowercased.contains("around.co") {
            return "Around"
        }

        return nil
    }

    /// Get SF Symbol icon for meeting platform
    func iconForPlatform(_ platform: String?) -> String {
        guard let platform = platform?.lowercased() else {
            return "video.fill"
        }

        switch platform {
        case "zoom":
            return "video.fill"
        case "google meet":
            return "video.fill"
        case "microsoft teams":
            return "person.3.fill"
        case "webex":
            return "video.fill"
        default:
            return "video.fill"
        }
    }

    /// Get color for meeting platform
    func colorForPlatform(_ platform: String?) -> String {
        guard let platform = platform?.lowercased() else {
            return "#007AFF" // Blue
        }

        switch platform {
        case "zoom":
            return "#2D8CFF" // Zoom blue
        case "google meet":
            return "#00897B" // Google Meet teal
        case "microsoft teams":
            return "#6264A7" // Teams purple
        case "webex":
            return "#00BCEB" // Webex cyan
        default:
            return "#007AFF" // Default blue
        }
    }

    // MARK: - Date Parsing

    private func parseDate(from string: String) -> Date? {
        // Try ISO 8601 format first
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: string) {
            return date
        }

        // Try common formats
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
            "MM/dd/yyyy HH:mm",
            "MMM dd, yyyy 'at' h:mm a"
        ]

        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: string) {
                return date
            }
        }

        Logger.warning("Failed to parse date: \(string)", category: .app)
        return nil
    }

    // MARK: - Helper Methods

    /// Format date for display
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Check if event is in the future
    func isFutureEvent(_ date: Date) -> Bool {
        return date > Date()
    }

    /// Get time until event
    func timeUntilEvent(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())

        if interval < 0 {
            return "Past event"
        }

        let hours = Int(interval / 3600)
        let days = hours / 24

        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}
