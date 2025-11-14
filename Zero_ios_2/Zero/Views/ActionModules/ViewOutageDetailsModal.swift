import SwiftUI
import MapKit

struct OutageDetails {
    let outageType: OutageType
    let status: OutageStatus
    let affectedCustomers: Int
    let estimatedRestoration: Date?
    let cause: String
    let affectedServices: [String]
    let affectedAreas: [String]
    let updates: [OutageUpdate]
}

enum OutageType {
    case power
    case internet
    case water
    case gas

    var icon: String {
        switch self {
        case .power: return "bolt.fill"
        case .internet: return "wifi.slash"
        case .water: return "drop.fill"
        case .gas: return "flame.fill"
        }
    }

    var color: Color {
        switch self {
        case .power: return .yellow
        case .internet: return .blue
        case .water: return .cyan
        case .gas: return .orange
        }
    }
}

enum OutageStatus {
    case active
    case investigating
    case repairing
    case resolved

    var display: String {
        switch self {
        case .active: return "Active Outage"
        case .investigating: return "Investigating"
        case .repairing: return "Repair in Progress"
        case .resolved: return "Resolved"
        }
    }

    var color: Color {
        switch self {
        case .active: return .red
        case .investigating: return .orange
        case .repairing: return .yellow
        case .resolved: return .green
        }
    }
}

struct OutageUpdate: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
}

struct ViewOutageDetailsModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var outageDetails: OutageDetails?
    @State private var showCalendarSuccess = false

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
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Outage Details")
                                .font(.title2.bold())
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            if let details = outageDetails {
                                Text(details.status.display)
                                    .font(.subheadline)
                                    .foregroundColor(details.status.color)
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    if let details = outageDetails {
                        // Status Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: details.outageType.icon)
                                    .font(.title)
                                    .foregroundColor(details.outageType.color)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(details.status.display)
                                        .font(.headline)
                                        .foregroundColor(details.status.color)

                                    Text(details.cause)
                                        .font(.subheadline)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                            }

                            Divider()
                                .background(Color.white.opacity(DesignTokens.Opacity.overlayLight))

                            // Affected Services
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Affected Services")
                                    .font(.caption.bold())
                                    .foregroundColor(DesignTokens.Colors.textSubtle)

                                HStack(spacing: 8) {
                                    ForEach(details.affectedServices, id: \.self) { service in
                                        HStack(spacing: 4) {
                                            Image(systemName: iconForService(service))
                                                .font(.caption)
                                            Text(service)
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.red.opacity(DesignTokens.Opacity.overlayLight))
                                        .foregroundColor(.red)
                                        .cornerRadius(DesignTokens.Radius.button)
                                    }
                                }
                            }

                            // Impact Stats
                            HStack(spacing: 24) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.3.fill")
                                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                                            .font(.caption)
                                        Text("Affected")
                                            .font(.caption)
                                            .foregroundColor(DesignTokens.Colors.textSubtle)
                                    }
                                    Text("\(details.affectedCustomers.formatted())")
                                        .font(.title3.bold())
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    Text("customers")
                                        .font(.caption2)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }

                                if let restoration = details.estimatedRestoration {
                                    Divider()
                                        .frame(height: 50)

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "clock.fill")
                                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                                                .font(.caption)
                                            Text("Est. Restoration")
                                                .font(.caption)
                                                .foregroundColor(DesignTokens.Colors.textSubtle)
                                        }
                                        Text(restoration, style: .time)
                                            .font(.title3.bold())
                                            .foregroundColor(.yellow)
                                        Text(restoration, style: .date)
                                            .font(.caption2)
                                            .foregroundColor(DesignTokens.Colors.textSubtle)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            Color.red.opacity(DesignTokens.Opacity.glassLight)
                        )
                        .cornerRadius(DesignTokens.Radius.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                                .strokeBorder(Color.red.opacity(0.4), lineWidth: 1)
                        )

                        // Affected Areas
                        if !details.affectedAreas.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Affected Areas")
                                    .font(.headline)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(details.affectedAreas, id: \.self) { area in
                                        HStack(spacing: 12) {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundColor(.red)
                                            Text(area)
                                                .font(.subheadline)
                                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                                        .cornerRadius(DesignTokens.Radius.button)
                                    }
                                }
                            }
                        }

                        // Status Updates Timeline
                        if !details.updates.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Status Updates")
                                    .font(.headline)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                VStack(spacing: 0) {
                                    ForEach(Array(details.updates.enumerated()), id: \.element.id) { index, update in
                                        OutageUpdateRow(
                                            update: update,
                                            isFirst: index == 0,
                                            isLast: index == details.updates.count - 1
                                        )
                                    }
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Radius.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                                    .strokeBorder(Color.blue.opacity(0.4), lineWidth: 1)
                            )
                        }

                        // Action Buttons
                        VStack(spacing: 12) {
                            if details.estimatedRestoration != nil {
                                Button {
                                    addReminderToCalendar()
                                } label: {
                                    HStack {
                                        Image(systemName: "bell.badge.fill")
                                        Text("Remind Me at Restoration Time")
                                            .font(.headline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.yellow)
                                    .foregroundColor(.black)
                                    .cornerRadius(DesignTokens.Radius.button)
                                }
                            }

                            Button {
                                shareOutageInfo()
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Outage Info")
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

                        // Calendar Success
                        if showCalendarSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Reminder added!")
                                    .foregroundColor(.green)
                                    .font(.subheadline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(DesignTokens.Opacity.overlayLight))
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                    }

                    // Info message
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Check back for real-time updates. You'll receive notifications when the outage is resolved.")
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
            parseOutageDetails()
        }
    }

    func parseOutageDetails() {
        // Extract outage details from email
        let text = (card.title + " " + card.summary + " " + (card.body ?? "")).lowercased()

        // Determine outage type
        var outageType: OutageType = .power
        if text.contains("power") || text.contains("electric") {
            outageType = .power
        } else if text.contains("internet") || text.contains("network") {
            outageType = .internet
        } else if text.contains("water") {
            outageType = .water
        } else if text.contains("gas") {
            outageType = .gas
        }

        // Determine status
        var status: OutageStatus = .active
        if text.contains("investigating") {
            status = .investigating
        } else if text.contains("repair") || text.contains("fixing") {
            status = .repairing
        } else if text.contains("resolved") || text.contains("restored") {
            status = .resolved
        }

        // Extract affected customer count
        var affectedCustomers = 1247
        if let match = text.range(of: #"(\d{1,3}(?:,\d{3})*)\s*(?:customer|people|home)"#, options: .regularExpression) {
            let countStr = String(text[match]).filter { $0.isNumber || $0 == "," }
            if let count = Int(countStr.replacingOccurrences(of: ",", with: "")) {
                affectedCustomers = count
            }
        }

        // Estimated restoration (default to 6 hours from now)
        var estimatedRestoration: Date?
        if let restoration = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) {
            estimatedRestoration = restoration
        }

        // Affected services
        var affectedServices: [String] = []
        if text.contains("power") || text.contains("electric") {
            affectedServices.append("Power")
        }
        if text.contains("internet") || text.contains("network") {
            affectedServices.append("Internet")
        }
        if text.contains("water") {
            affectedServices.append("Water")
        }
        if affectedServices.isEmpty {
            affectedServices.append("Power")
        }

        // Affected areas
        let affectedAreas = [
            "Downtown District",
            "Main Street Corridor",
            "Residential Zone A"
        ]

        // Status updates
        let updates = [
            OutageUpdate(
                timestamp: Date().addingTimeInterval(-3600),
                message: "Outage reported. Crews dispatched to investigate."
            ),
            OutageUpdate(
                timestamp: Date().addingTimeInterval(-1800),
                message: "Issue identified: Equipment failure at substation."
            ),
            OutageUpdate(
                timestamp: Date().addingTimeInterval(-900),
                message: "Repair crews on site. Working to restore service."
            )
        ]

        outageDetails = OutageDetails(
            outageType: outageType,
            status: status,
            affectedCustomers: affectedCustomers,
            estimatedRestoration: estimatedRestoration,
            cause: "Equipment failure",
            affectedServices: affectedServices,
            affectedAreas: affectedAreas,
            updates: updates
        )
    }

    func iconForService(_ service: String) -> String {
        switch service.lowercased() {
        case "power": return "bolt.fill"
        case "internet": return "wifi"
        case "water": return "drop.fill"
        case "gas": return "flame.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }

    func addReminderToCalendar() {
        guard let details = outageDetails,
              let restoration = details.estimatedRestoration else { return }

        Logger.info("Adding outage restoration reminder", category: .action)

        CalendarService.shared.addEvent(
            title: "⚡ Power Restoration Expected",
            startDate: restoration,
            endDate: Calendar.current.date(byAdding: .minute, value: 30, to: restoration) ?? restoration,
            location: details.affectedAreas.first ?? "Your area",
            notes: """
            Estimated restoration time for \(details.outageType) outage.

            Affected: \(details.affectedCustomers) customers
            Status: \(details.status.display)
            Cause: \(details.cause)
            """
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    withAnimation(.spring()) {
                        showCalendarSuccess = true
                    }
                    Logger.info("Restoration reminder added", category: .action)

                    // Haptic feedback
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.spring()) {
                            showCalendarSuccess = false
                        }
                    }

                case .failure(let error):
                    Logger.error("Failed to add reminder: \(error.localizedDescription)", category: .action)
                }
            }
        }
    }

    func shareOutageInfo() {
        guard let details = outageDetails else { return }

        let updatesText = details.updates.map { update in
            "\(update.timestamp.formatted(date: .omitted, time: .shortened)): \(update.message)"
        }.joined(separator: "\n")

        let shareText = """
        ⚠️ OUTAGE ALERT

        Status: \(details.status.display)
        Type: \(details.affectedServices.joined(separator: ", "))
        Affected: \(details.affectedCustomers) customers

        \(details.estimatedRestoration != nil ? "Est. Restoration: \(details.estimatedRestoration!.formatted())" : "")

        Areas:
        \(details.affectedAreas.map { "• \($0)" }.joined(separator: "\n"))

        Updates:
        \(updatesText)
        """

        UIPasteboard.general.string = shareText
        Logger.info("Outage info copied to clipboard", category: .action)

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
    }
}

// MARK: - Outage Update Row

struct OutageUpdateRow: View {
    let update: OutageUpdate
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(Color.blue.opacity(DesignTokens.Opacity.overlayMedium))
                        .frame(width: 2, height: 20)
                }

                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)

                if !isLast {
                    Rectangle()
                        .fill(Color.blue.opacity(DesignTokens.Opacity.overlayMedium))
                        .frame(width: 2, height: 50)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(update.timestamp, style: .time)
                    .font(.caption.bold())
                    .foregroundColor(.blue)

                Text(update.message)
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("View Outage Details Modal") {
    ViewOutageDetailsModal(
        card: EmailCard(
            id: "preview",
            type: .mail,
            state: .seen,
            priority: .medium,
            hpa: "view_outage_details",
            timeAgo: "2h",
            title: "Power Outage in Your Area",
            summary: "We are currently experiencing a power outage affecting approximately 1,247 customers in the downtown district. Our crews are working to restore service. Estimated restoration time: 6:00 PM today.",
            body: "Outage Alert\n\nA power outage is currently affecting your area due to equipment failure at the main substation.\n\nAffected Areas:\n- Downtown District\n- Main Street Corridor\n- Residential Zone A\n\nAffected Services: Power, Internet\n\nEstimated Customers Affected: 1,247\n\nOur repair crews are on site and working to restore service as quickly as possible.\n\nEstimated Restoration: 6:00 PM today\n\nWe apologize for the inconvenience and thank you for your patience.",
            metaCTA: "View",
            suggestedActions: [
                EmailAction(
                    actionId: "view_outage_details",
                    displayName: "View Details",
                    actionType: .inApp,
                    isPrimary: true,
                    context: [:]
                )
            ],
            sender: SenderInfo(
                name: "PG&E Alerts",
                initial: "P",
                email: "alerts@pge.com"
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
