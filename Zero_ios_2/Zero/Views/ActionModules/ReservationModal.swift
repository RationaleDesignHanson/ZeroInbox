import SwiftUI
import EventKit

struct ReservationModal: View {
    let card: EmailCard
    let context: [String: String]
    @Binding var isPresented: Bool

    @State private var showAddToCalendar = false
    @State private var showSuccess = false
    @State private var showBrowserView = false

    // Extract reservation details from context
    private var venueName: String {
        context["venue"] ?? context["location"] ?? context["restaurant"] ?? context["hotel"] ?? "Reservation"
    }

    private var reservationDate: String {
        context["date"] ?? context["checkIn"] ?? context["time"] ?? "Date TBD"
    }

    private var confirmationCode: String {
        context["confirmationCode"] ?? context["confirmation"] ?? context["bookingId"] ?? "N/A"
    }

    private var guestCount: String? {
        context["guests"] ?? context["partySize"]
    }

    private var reservationUrl: String? {
        context["url"] ?? context["reservationUrl"] ?? context["bookingUrl"]
    }

    private var reservationType: ReservationType {
        let title = card.title.lowercased()
        let summary = card.summary.lowercased()

        if title.contains("hotel") || summary.contains("hotel") || title.contains("accommodation") {
            return .hotel
        } else if title.contains("flight") || summary.contains("flight") || title.contains("airline") {
            return .flight
        } else if title.contains("restaurant") || summary.contains("restaurant") || title.contains("dinner") || title.contains("table") {
            return .restaurant
        } else {
            return .generic
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom header
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .font(.title2)
                }
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header with reservation type icon
                    HStack(spacing: DesignTokens.Spacing.component) {
                        ZStack {
                            Circle()
                                .fill(reservationType.color.opacity(0.2))
                                .frame(width: 60, height: 60)

                            Text(reservationType.icon)
                                .font(.system(size: 32))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(reservationType.title)
                                .font(.caption.bold())
                                .foregroundColor(DesignTokens.Colors.textSecondary)

                            Text(venueName)
                                .font(.title2.bold())
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .lineLimit(2)
                        }
                    }

                    Divider()
                        .background(DesignTokens.Colors.borderStrong)

                    // Reservation Details Card
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        // Date/Time
                        ReservationDetailRow(
                            icon: "calendar",
                            iconColor: .blue,
                            label: "Date & Time",
                            value: reservationDate
                        )

                        // Confirmation Code
                        ReservationDetailRow(
                            icon: "number",
                            iconColor: .green,
                            label: "Confirmation",
                            value: confirmationCode,
                            copyable: true
                        )

                        // Guest count (if available)
                        if let guests = guestCount {
                            ReservationDetailRow(
                                icon: "person.2",
                                iconColor: .purple,
                                label: reservationType == .hotel ? "Guests" : "Party Size",
                                value: guests
                            )
                        }

                        // Location/Venue (from card)
                        if let location = extractLocation(from: card.summary) {
                            ReservationDetailRow(
                                icon: "mappin.circle",
                                iconColor: .red,
                                label: "Location",
                                value: location
                            )
                        }
                    }
                    .padding(DesignTokens.Spacing.section)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                            .fill(DesignTokens.Colors.overlay10)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                    .strokeBorder(DesignTokens.Colors.border, lineWidth: 1)
                            )
                    )

                    // Additional Info
                    if !card.summary.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                            Text("Details")
                                .font(DesignTokens.Typography.headingSmall)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            StructuredSummaryView(card: card)
                        }
                        .padding(DesignTokens.Spacing.component)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                .fill(DesignTokens.Colors.overlay5)
                        )
                    }

                    // Action Buttons
                    VStack(spacing: DesignTokens.Spacing.element) {
                        // Add to Calendar - Primary Action
                        StandardButton(
                            "Add to Calendar",
                            icon: "calendar.badge.plus",
                            cardType: card.type
                        ) {
                            showAddToCalendar = true
                        }

                        // View/Modify Online
                        if reservationUrl != nil {
                            StandardButton.secondary(
                                "View/Modify Online",
                                icon: "safari"
                            ) {
                                showBrowserView = true
                            }
                        }

                        // Share Reservation
                        StandardButton.tertiary(
                            "Share Details",
                            icon: "square.and.arrow.up"
                        ) {
                            shareReservation()
                        }
                    }
                    .padding(.top, DesignTokens.Spacing.inline)

                    // Success message
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Added to Calendar!")
                                .foregroundColor(.green)
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .background(
            ArchetypeConfig.config(for: card.type).gradient
                .ignoresSafeArea()
        )
        .sheet(isPresented: $showAddToCalendar) {
            AddToCalendarModal(card: card, isPresented: $showAddToCalendar)
                .onDisappear {
                    // Show success briefly then dismiss parent
                    showSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isPresented = false
                    }
                }
        }
        .fullScreenCover(isPresented: $showBrowserView) {
            if let urlString = reservationUrl, let url = URL(string: urlString) {
                SafariViewWithContext(
                    url: url,
                    actionName: "View Reservation",
                    cardTitle: card.title,
                    cardType: card.type,
                    onDismiss: {
                        showBrowserView = false
                    }
                )
            }
        }
    }

    // MARK: - Helper Methods

    /// Extract location from summary text
    private func extractLocation(from text: String) -> String? {
        // Look for common location patterns
        let patterns = [
            "at ",
            "located at ",
            "address: ",
            "location: "
        ]

        for pattern in patterns {
            if let range = text.lowercased().range(of: pattern) {
                let afterPattern = String(text[range.upperBound...])
                let location = afterPattern.components(separatedBy: ".").first?
                    .components(separatedBy: ",").prefix(2).joined(separator: ",")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if let loc = location, !loc.isEmpty && loc.count > 5 {
                    return loc
                }
            }
        }

        return nil
    }

    /// Share reservation details
    private func shareReservation() {
        var shareText = "\(reservationType.title)\n"
        shareText += "\(venueName)\n"
        shareText += "Date: \(reservationDate)\n"
        shareText += "Confirmation: \(confirmationCode)\n"

        if let guests = guestCount {
            shareText += "Guests: \(guests)\n"
        }

        if let url = reservationUrl {
            shareText += "\n\(url)"
        }

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }

        Logger.info("Shared reservation details", category: .action)
    }
}

// MARK: - Supporting Views

struct ReservationDetailRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    var copyable: Bool = false

    @State private var showCopied = false

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.element) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(DesignTokens.Colors.textFaded)

                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }

            Spacer()

            if copyable {
                Button {
                    UIPasteboard.general.string = value
                    showCopied = true

                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showCopied = false
                    }
                } label: {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundColor(showCopied ? .green : .white.opacity(0.5))
                }
            }
        }
    }
}

// MARK: - Reservation Type

enum ReservationType {
    case hotel
    case restaurant
    case flight
    case generic

    var icon: String {
        switch self {
        case .hotel: return "🏨"
        case .restaurant: return "🍽️"
        case .flight: return "✈️"
        case .generic: return "📅"
        }
    }

    var title: String {
        switch self {
        case .hotel: return "Hotel Reservation"
        case .restaurant: return "Restaurant Reservation"
        case .flight: return "Flight Booking"
        case .generic: return "Reservation"
        }
    }

    var color: Color {
        switch self {
        case .hotel: return .purple
        case .restaurant: return .orange
        case .flight: return .blue
        case .generic: return .gray
        }
    }
}
