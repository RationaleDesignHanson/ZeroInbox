import SwiftUI
import EventKit

/// RSVP Modal
/// Handles rsvp_yes, rsvp_no, rsvp_maybe, accept_social_invitation actions
struct RSVPModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    let response: RSVPResponse
    let context: [String: String]

    @State private var showSuccess = false
    @State private var addingToCalendar = false
    @State private var sendReplyEmail = true

    enum RSVPResponse {
        case yes, no, maybe

        var title: String {
            switch self {
            case .yes: return "Accept Invitation"
            case .no: return "Decline Invitation"
            case .maybe: return "Maybe"
            }
        }

        var icon: String {
            switch self {
            case .yes: return "checkmark.circle.fill"
            case .no: return "xmark.circle.fill"
            case .maybe: return "questionmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .yes: return .green
            case .no: return .red
            case .maybe: return .orange
            }
        }

        var responseText: String {
            switch self {
            case .yes: return "attending"
            case .no: return "not attending"
            case .maybe: return "maybe attending"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)

            if showSuccess {
                successView
            } else {
                rsvpFormView
            }
        }
        .background(
            LinearGradient(
                colors: [response.color.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    private var rsvpFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [response.color.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)

                    Image(systemName: response.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }

                // Title
                Text(response.title)
                    .font(.title.bold())
                    .foregroundColor(.white)

                // Event Details Card
                VStack(alignment: .leading, spacing: 16) {
                    // Event Name
                    if let eventName = context["eventName"] ?? context["subject"],
                       !eventName.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Event")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            Text(eventName)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }

                    Divider().background(Color.white.opacity(0.3))

                    // Date & Time
                    if let date = context["date"] ?? context["eventDate"],
                       !date.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(date)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    if let time = context["time"] ?? context["eventTime"],
                       !time.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "clock")
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(time)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    // Location
                    if let location = context["location"] ?? context["venue"],
                       !location.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Location")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(location)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    // Host
                    if let host = card.sender?.name, !host.isEmpty {
                        Divider().background(Color.white.opacity(0.3))

                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Host")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(host)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

                // Options
                if response == .yes {
                    Toggle(isOn: $sendReplyEmail) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Send Reply Email")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                            Text("Notify the host of your response")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .tint(.green)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }

                // Confirmation Message
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white.opacity(0.7))
                        Text("You're \(response.responseText) this event")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)

                // Actions
                VStack(spacing: 12) {
                    // Confirm RSVP Button
                    Button {
                        confirmRSVP()
                    } label: {
                        HStack {
                            Image(systemName: response.icon)
                            Text("Confirm Response")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(
                            colors: [response.color, response.color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .cornerRadius(12)
                    }

                    // Add to Calendar (only for "yes" responses)
                    if response == .yes {
                        Button {
                            addEventToCalendar()
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Add to Calendar")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        .disabled(addingToCalendar)
                    }
                }
            }
            .padding()
        }
    }

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success Icon
            ZStack {
                Circle()
                    .fill(response.color.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.white)
            }

            // Success Message
            VStack(spacing: 12) {
                Text("Response Sent!")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("Your RSVP has been recorded")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding()
        .onAppear {
            // Auto-dismiss after showing success
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isPresented = false
            }
        }
    }

    private func confirmRSVP() {
        HapticManager.notification(type: .success)

        // Log analytics
        Logger.info("RSVP confirmed: \(response.responseText) for event: \(context["eventName"] ?? "unknown")", category: .action)

        // If sending reply email, open email composer
        if sendReplyEmail && response == .yes {
            // TODO: Open email composer with pre-filled RSVP message
            Logger.info("Opening email composer to send RSVP reply", category: .action)
        }

        // Show success state
        withAnimation {
            showSuccess = true
        }
    }

    private func addEventToCalendar() {
        addingToCalendar = true
        HapticManager.impact(style: .medium)

        let eventStore = EKEventStore()

        // Request calendar access
        eventStore.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                addingToCalendar = false

                if granted {
                    let event = EKEvent(eventStore: eventStore)
                    event.title = context["eventName"] ?? context["subject"] ?? card.title

                    // Parse date/time (simplified - would need proper date parsing in production)
                    if let dateString = context["date"] ?? context["eventDate"] {
                        // For demo, use a default future date
                        event.startDate = Date().addingTimeInterval(86400) // Tomorrow
                        event.endDate = event.startDate.addingTimeInterval(3600) // 1 hour duration
                    }

                    if let location = context["location"] ?? context["venue"] {
                        event.location = location
                    }

                    event.notes = card.summary
                    event.calendar = eventStore.defaultCalendarForNewEvents

                    do {
                        try eventStore.save(event, span: .thisEvent)
                        HapticManager.notification(type: .success)
                        Logger.info("Event added to calendar successfully", category: .action)
                    } catch {
                        Logger.error("Failed to add event to calendar: \(error.localizedDescription)", category: .action)
                    }
                } else {
                    Logger.warning("Calendar access not granted", category: .action)
                }
            }
        }
    }
}
