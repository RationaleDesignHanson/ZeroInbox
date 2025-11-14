import SwiftUI

struct CalendarInviteView: View {
    let invite: CalendarInvite
    let onAddToCalendar: () -> Void
    let onJoinMeeting: (() -> Void)?

    @State private var platform: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
            // Header with calendar icon
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .font(.title3)
                    .foregroundColor(.blue)

                Text("Calendar Invite")
                    .font(.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Spacer()

                if let platform = platform {
                    // Platform badge
                    HStack(spacing: 4) {
                        Image(systemName: CalendarService.shared.iconForPlatform(platform))
                            .font(.caption)
                        Text(platform)
                            .font(.caption.bold())
                    }
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .padding(.horizontal, DesignTokens.Spacing.inline)
                    .padding(.vertical, 4)
                    .background(platformColor)
                    .cornerRadius(DesignTokens.Radius.minimal)
                }
            }

            Divider()
                .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

            // Meeting details
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                // Title
                if let title = invite.meetingTitle {
                    HStack(spacing: DesignTokens.Spacing.inline) {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                            .frame(width: 20)

                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                }

                // Time
                if let time = invite.meetingTime {
                    HStack(spacing: DesignTokens.Spacing.inline) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatMeetingTime(time))
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            if let date = parseDate(time) {
                                Text(timeUntil(date))
                                    .font(.caption)
                                    .foregroundColor(timeColor(date))
                            }
                        }
                    }
                }

                // Organizer
                if let organizer = invite.organizer {
                    HStack(spacing: DesignTokens.Spacing.inline) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                            .frame(width: 20)

                        Text(organizer)
                            .font(.subheadline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                }

                // Meeting URL (if available)
                if let _ = invite.meetingUrl, platform != nil {
                    HStack(spacing: DesignTokens.Spacing.inline) {
                        Image(systemName: "link")
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                            .frame(width: 20)

                        Text("Virtual meeting link available")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }
                }
            }

            // Action buttons
            HStack(spacing: DesignTokens.Spacing.component) {
                // Add to Calendar button
                Button(action: onAddToCalendar) {
                    HStack(spacing: DesignTokens.Spacing.inline) {
                        Image(systemName: "calendar.badge.plus")
                        Text("Add to Calendar")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(DesignTokens.Spacing.section)
                    .background(Color.blue)
                    .cornerRadius(DesignTokens.Radius.button)
                }

                // Join Meeting button (if URL available)
                if onJoinMeeting != nil, invite.meetingUrl != nil {
                    Button(action: { onJoinMeeting?() }) {
                        HStack(spacing: DesignTokens.Spacing.inline) {
                            Image(systemName: "video.fill")
                            Text("Join")
                                .font(.subheadline.bold())
                        }
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(DesignTokens.Spacing.section)
                        .background(platformColor)
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                }
            }

            // Accept/Decline buttons (if RSVP is supported)
            if invite.hasAcceptDecline == true {
                HStack(spacing: DesignTokens.Spacing.component) {
                    Button(action: {
                        // Accept invite
                        Logger.info("Calendar invite accepted", category: .action)
                        HapticService.shared.success()
                    }) {
                        HStack(spacing: DesignTokens.Spacing.inline) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Accept")
                                .font(.subheadline.bold())
                        }
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(DesignTokens.Spacing.section)
                        .background(Color.green.opacity(DesignTokens.Opacity.textTertiary))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    Button(action: {
                        // Decline invite
                        Logger.info("Calendar invite declined", category: .action)
                        HapticService.shared.warning()
                    }) {
                        HStack(spacing: DesignTokens.Spacing.inline) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Decline")
                                .font(.subheadline.bold())
                        }
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(DesignTokens.Spacing.section)
                        .background(Color.red.opacity(DesignTokens.Opacity.textTertiary))
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.section)
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.15),
                    Color.purple.opacity(DesignTokens.Opacity.glassLight)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(DesignTokens.Radius.container)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                .strokeBorder(Color.blue.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
        )
        .onAppear {
            // Detect platform from URL
            if let url = invite.meetingUrl {
                platform = CalendarService.shared.detectMeetingPlatform(from: url)
            } else if let platformValue = invite.platform {
                platform = platformValue
            }
        }
    }

    // MARK: - Helper Methods

    var platformColor: Color {
        guard let platform = platform else { return .blue }

        let colorHex = CalendarService.shared.colorForPlatform(platform)
        return Color(hex: colorHex)
    }

    func formatMeetingTime(_ timeString: String) -> String {
        guard let date = parseDate(timeString) else {
            return timeString
        }

        return CalendarService.shared.formatDate(date)
    }

    func parseDate(_ string: String) -> Date? {
        // Try ISO 8601 format
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: string) {
            return date
        }

        // Try DateFormatter
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        return dateFormatter.date(from: string)
    }

    func timeUntil(_ date: Date) -> String {
        let timeString = CalendarService.shared.timeUntilEvent(date)

        if timeString == "Past event" {
            return "This event has passed"
        } else {
            return "In \(timeString)"
        }
    }

    func timeColor(_ date: Date) -> Color {
        let interval = date.timeIntervalSince(Date())

        if interval < 0 {
            return .gray // Past event
        } else if interval < 3600 {
            return .red // Less than 1 hour
        } else if interval < 86400 {
            return .orange // Less than 1 day
        } else {
            return .green // More than 1 day
        }
    }
}

// MARK: - Preview

#Preview("Calendar Invite - Zoom") {
    CalendarInviteView(
        invite: CalendarInvite(
            platform: "Zoom",
            meetingUrl: "https://zoom.us/j/1234567890",
            meetingTime: "2024-10-30T14:00:00Z",
            meetingTitle: "Product Planning Session",
            organizer: "Sarah Chen",
            hasAcceptDecline: true
        ),
        onAddToCalendar: {
            print("Add to calendar tapped")
        },
        onJoinMeeting: {
            print("Join meeting tapped")
        }
    )
    .padding()
    .background(
        LinearGradient(
            colors: [Color.purple, Color.blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Calendar Invite - Google Meet") {
    CalendarInviteView(
        invite: CalendarInvite(
            platform: nil,
            meetingUrl: "https://meet.google.com/abc-defg-hij",
            meetingTime: "2024-10-28T10:30:00Z",
            meetingTitle: "Weekly Standup",
            organizer: "team@company.com",
            hasAcceptDecline: false
        ),
        onAddToCalendar: {
            print("Add to calendar tapped")
        },
        onJoinMeeting: {
            print("Join meeting tapped")
        }
    )
    .padding()
    .background(
        LinearGradient(
            colors: [Color.green, Color.teal],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
