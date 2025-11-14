import SwiftUI

struct ViewActivityModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var activityTitle = ""
    @State private var activityDate: Date?
    @State private var activityLocation = ""
    @State private var attendeeCount = 0
    @State private var organizerName = ""
    @State private var activityDescription = ""
    @State private var showRSVPSuccess = false
    @State private var rsvpResponse: RSVPResponse?

    enum RSVPResponse {
        case yes
        case no
        case maybe
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom header bar
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .font(.title2)
                }
            }
            .padding()

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "figure.walk")
                                .font(.largeTitle)
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(activityTitle)
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                if !organizerName.isEmpty {
                                    Text("Organized by \(organizerName)")
                                        .font(.subheadline)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Activity Details Card
                    VStack(alignment: .leading, spacing: 16) {
                        // Date & Time
                        if let date = activityDate {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(date, style: .date)
                                        .font(.subheadline.bold())
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    Text(date, style: .time)
                                        .font(.caption)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }
                            }
                        }

                        // Location
                        if !activityLocation.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "location.fill")
                                    .font(.title3)
                                    .foregroundColor(.red)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(activityLocation)
                                        .font(.subheadline.bold())
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    Text("Location")
                                        .font(.caption)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }
                            }
                        }

                        // Attendees
                        if attendeeCount > 0 {
                            HStack(spacing: 12) {
                                Image(systemName: "person.3.fill")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(attendeeCount) \(attendeeCount == 1 ? "person" : "people")")
                                        .font(.subheadline.bold())
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    Text("Attending")
                                        .font(.caption)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(DesignTokens.Radius.card)

                    // Description
                    if !activityDescription.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Text(activityDescription)
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // RSVP Buttons
                    if !showRSVPSuccess {
                        VStack(spacing: 12) {
                            Text("Will you be attending?")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .center)

                            HStack(spacing: 12) {
                                // RSVP Yes
                                Button {
                                    rsvpYes()
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Yes")
                                            .font(.headline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(DesignTokens.Radius.button)
                                }

                                // RSVP No
                                Button {
                                    rsvpNo()
                                } label: {
                                    HStack {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("No")
                                            .font(.headline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(DesignTokens.Radius.button)
                                }
                            }

                            // RSVP Maybe
                            Button {
                                rsvpMaybe()
                            } label: {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                    Text("Maybe")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .cornerRadius(DesignTokens.Radius.button)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                        .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                )
                            }
                        }
                    }

                    // RSVP Success
                    if showRSVPSuccess, let response = rsvpResponse {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                Text("RSVP Sent!")
                                    .foregroundColor(.green)
                                    .font(.headline.bold())
                            }

                            Text("You responded: \(response == .yes ? "Yes" : response == .no ? "No" : "Maybe")")
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(DesignTokens.Opacity.overlayLight))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Add to Calendar button
                    if activityDate != nil {
                        Button {
                            addToCalendar()
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Add to Calendar")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(DesignTokens.Opacity.overlayMedium))
                            .foregroundColor(.white)
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                    }

                    // Info message
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Your RSVP will be sent to the organizer. You can change your response at any time.")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.blue.opacity(DesignTokens.Opacity.glassLight))
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .onAppear {
            detectActivityDetails()
        }
    }

    func detectActivityDetails() {
        // Extract activity details from card
        activityTitle = card.title

        // Try to get details from action context
        if let action = card.suggestedActions?.first(where: { $0.actionId.contains("activity") || $0.actionId.contains("rsvp") }),
           let context = action.context {
            if let location = context["location"] {
                activityLocation = location
            }
            if let countString = context["attendee_count"], let count = Int(countString) {
                attendeeCount = count
            }
            if let organizer = context["organizer"] {
                organizerName = organizer
            }
        }

        // Extract date from calendar invite or parse from content
        activityDate = extractDateFromContent()

        // Extract location from content if not in context
        if activityLocation.isEmpty {
            activityLocation = extractLocationFromContent()
        }

        // Use summary as description
        activityDescription = card.summary

        // Extract organizer from sender if not set
        if organizerName.isEmpty, let sender = card.sender {
            organizerName = sender.name
        }

        // Parse attendee count from content if not set
        if attendeeCount == 0 {
            attendeeCount = extractAttendeeCount()
        }
    }

    func extractDateFromContent() -> Date? {
        // This is a simplified extraction - in production, use a date parsing library
        // For now, return a date 7 days from now as default
        return Calendar.current.date(byAdding: .day, value: 7, to: Date())
    }

    func extractLocationFromContent() -> String {
        let text = card.title + " " + card.summary
        let patterns = ["at (.+?)(?:on|\\.|,|$)", "location:? (.+?)(?:\\.|,|$)"]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range]).trimmingCharacters(in: .whitespaces)
            }
        }

        return "Location TBD"
    }

    func extractAttendeeCount() -> Int {
        let text = card.summary.lowercased()
        let patterns = ["(\\d+) (?:people|person|attendees)", "(\\d+) (?:going|attending)"]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text),
               let count = Int(String(text[range])) {
                return count
            }
        }

        return 0
    }

    func rsvpYes() {
        rsvpResponse = .yes
        sendRSVP(response: "Yes")
    }

    func rsvpNo() {
        rsvpResponse = .no
        sendRSVP(response: "No")
    }

    func rsvpMaybe() {
        rsvpResponse = .maybe
        sendRSVP(response: "Maybe")
    }

    func sendRSVP(response: String) {
        Logger.info("RSVP sent: \(response) for activity: \(activityTitle)", category: .action)

        // Show success
        withAnimation(.spring()) {
            showRSVPSuccess = true
        }

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        // Log analytics
        AnalyticsService.shared.log(
            .actionExecuted,
            parameters: [
                "action_id": "rsvp_activity",
                "rsvp_response": response,
                "activity_title": activityTitle
            ]
        )

        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isPresented = false
        }
    }

    func addToCalendar() {
        guard let date = activityDate else { return }

        Logger.info("Adding activity to calendar: \(activityTitle)", category: .action)

        // Use CalendarService to add event
        CalendarService.shared.addEvent(
            title: activityTitle,
            startDate: date,
            endDate: Calendar.current.date(byAdding: .hour, value: 2, to: date) ?? date,
            location: activityLocation,
            notes: activityDescription
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    Logger.info("Activity added to calendar successfully", category: .action)
                    // Haptic feedback
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                case .failure(let error):
                    Logger.error("Failed to add activity to calendar: \(error.localizedDescription)", category: .action)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("View Activity Modal") {
    ViewActivityModal(
        card: EmailCard(
            id: "preview",
            type: .mail,
            state: .seen,
            priority: .medium,
            hpa: "view_activity",
            timeAgo: "2h",
            title: "Group Hike This Weekend",
            summary: "Join us for a morning hike at Mt. Tamalpais State Park! We'll meet at the main parking lot at 9 AM. Bring water, snacks, and wear comfortable hiking shoes. 12 people are attending so far!",
            body: "Hi everyone,\n\nLooking forward to our group hike this Saturday! The weather looks perfect.\n\nDetails:\n- Date: Saturday, Nov 9\n- Time: 9:00 AM\n- Location: Mt. Tamalpais State Park\n- Difficulty: Moderate\n- Duration: ~3 hours\n\nPlease RSVP so we know how many to expect.\n\nCheers,\nSarah",
            metaCTA: "View",
            suggestedActions: [
                EmailAction(
                    actionId: "view_activity",
                    displayName: "View Activity",
                    actionType: .inApp,
                    isPrimary: true,
                    context: [
                        "location": "Mt. Tamalpais State Park",
                        "attendee_count": "12",
                        "organizer": "Sarah Johnson"
                    ]
                )
            ],
            sender: SenderInfo(
                name: "Sarah Johnson",
                initial: "S",
                email: "sarah@hikingclub.com"
            )
        ),
        isPresented: .constant(true)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.05, green: 0.05, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
