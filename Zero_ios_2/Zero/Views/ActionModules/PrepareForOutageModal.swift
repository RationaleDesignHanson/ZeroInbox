import SwiftUI

struct PrepareForOutageModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var outageStart: Date?
    @State private var outageEnd: Date?
    @State private var outageReason = ""
    @State private var affectedAreas = ""
    @State private var showCalendarSuccess = false
    @State private var preparationTips: [PreparationTip] = []

    struct PreparationTip: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
        var isChecked: Bool = false
    }

    var outageDuration: String {
        guard let start = outageStart, let end = outageEnd else { return "Unknown" }
        let hours = Calendar.current.dateComponents([.hour], from: start, to: end).hour ?? 0
        return "\(hours) hours"
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
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Prepare for Outage")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                if !outageReason.isEmpty {
                                    Text(outageReason)
                                        .font(.subheadline)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Outage Schedule Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Scheduled Outage")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        if let start = outageStart, let end = outageEnd {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(start, style: .date)
                                        .font(.subheadline.bold())
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    Text("\(start.formatted(date: .omitted, time: .shortened)) - \(end.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }
                            }

                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .font(.title3)
                                    .foregroundColor(.orange)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Duration: \(outageDuration)")
                                        .font(.subheadline.bold())
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                }
                            }
                        }

                        if !affectedAreas.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "map.fill")
                                    .font(.title3)
                                    .foregroundColor(.red)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Affected Areas")
                                        .font(.caption)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                    Text(affectedAreas)
                                        .font(.subheadline.bold())
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(DesignTokens.Radius.card)

                    // Preparation Checklist
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Preparation Checklist")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Spacer()

                            let checkedCount = preparationTips.filter { $0.isChecked }.count
                            Text("\(checkedCount)/\(preparationTips.count)")
                                .font(.subheadline.bold())
                                .foregroundColor(.orange)
                        }

                        VStack(spacing: 12) {
                            ForEach($preparationTips) { $tip in
                                PreparationTipRow(tip: $tip)
                            }
                        }
                    }
                    .padding()
                    .background(
                        Color.orange.opacity(0.1)
                    )
                    .cornerRadius(DesignTokens.Radius.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                            .strokeBorder(Color.orange.opacity(0.4), lineWidth: 1)
                    )

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            addToCalendar()
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Add Reminder to Calendar")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(DesignTokens.Radius.button)
                        }

                        Button {
                            shareChecklist()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Checklist")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .cornerRadius(DesignTokens.Radius.button)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }

                    // Calendar Success
                    if showCalendarSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Reminder added to calendar!")
                                .foregroundColor(.green)
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Info message
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Prepare ahead of time to minimize disruption. Check your utility provider's website for updates.")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .onAppear {
            detectOutageDetails()
            loadPreparationTips()
        }
    }

    func detectOutageDetails() {
        // Extract outage details from card
        if let action = card.suggestedActions?.first(where: { $0.actionId.contains("outage") }),
           let context = action.context {
            if let startString = context["outage_start"],
               let start = ISO8601DateFormatter().date(from: startString) {
                outageStart = start
            }
            if let endString = context["outage_end"],
               let end = ISO8601DateFormatter().date(from: endString) {
                outageEnd = end
            }
            if let reason = context["reason"] {
                outageReason = reason
            }
            if let areas = context["affected_areas"] {
                affectedAreas = areas
            }
        } else {
            // Default to tomorrow 9 AM - 3 PM
            if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
                components.hour = 9
                components.minute = 0
                outageStart = Calendar.current.date(from: components)

                components.hour = 15
                outageEnd = Calendar.current.date(from: components)
            }

            outageReason = "Planned Maintenance"
            affectedAreas = "Your neighborhood"
        }
    }

    func loadPreparationTips() {
        preparationTips = [
            PreparationTip(
                icon: "battery.100",
                title: "Charge All Devices",
                description: "Fully charge phones, tablets, and laptops"
            ),
            PreparationTip(
                icon: "lightbulb.fill",
                title: "Prepare Flashlights",
                description: "Check batteries and have them ready"
            ),
            PreparationTip(
                icon: "refrigerator.fill",
                title: "Minimize Fridge Opening",
                description: "Keep fridge/freezer closed during outage"
            ),
            PreparationTip(
                icon: "drop.fill",
                title: "Fill Water Containers",
                description: "Store drinking water in bottles"
            ),
            PreparationTip(
                icon: "power",
                title: "Turn Off Appliances",
                description: "Unplug sensitive electronics"
            ),
            PreparationTip(
                icon: "doc.text.fill",
                title: "Save Your Work",
                description: "Save all computer files and close apps"
            )
        ]
    }

    func addToCalendar() {
        guard let start = outageStart, let end = outageEnd else { return }

        Logger.info("Adding outage to calendar", category: .action)

        CalendarService.shared.addEvent(
            title: "⚠️ Power Outage - \(outageReason)",
            startDate: start,
            endDate: end,
            location: affectedAreas,
            notes: """
            Planned power outage

            Preparation checklist:
            \(preparationTips.map { "• \($0.title)" }.joined(separator: "\n"))

            Duration: \(outageDuration)
            """
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    withAnimation(.spring()) {
                        showCalendarSuccess = true
                    }
                    Logger.info("Outage reminder added to calendar", category: .action)

                    // Haptic feedback
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)

                    // Hide success after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.spring()) {
                            showCalendarSuccess = false
                        }
                    }

                case .failure(let error):
                    Logger.error("Failed to add calendar event: \(error.localizedDescription)", category: .action)
                }
            }
        }
    }

    func shareChecklist() {
        let checklistText = """
        Power Outage Preparation Checklist

        Outage: \(outageStart?.formatted() ?? "TBD")
        Duration: \(outageDuration)

        Checklist:
        \(preparationTips.map { "☐ \($0.title): \($0.description)" }.joined(separator: "\n"))
        """

        UIPasteboard.general.string = checklistText
        Logger.info("Checklist copied to clipboard", category: .action)

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
    }
}

// MARK: - Preparation Tip Row

struct PreparationTipRow: View {
    @Binding var tip: PrepareForOutageModal.PreparationTip

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                tip.isChecked.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: tip.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(tip.isChecked ? .green : .white.opacity(0.5))
                    .font(.title3)

                Image(systemName: tip.icon)
                    .foregroundColor(.orange)
                    .font(.title3)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tip.title)
                        .font(.subheadline.bold())
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .strikethrough(tip.isChecked)

                    Text(tip.description)
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .strikethrough(tip.isChecked)
                }

                Spacer()
            }
            .padding()
            .background(Color.white.opacity(tip.isChecked ? 0.05 : 0.08))
            .cornerRadius(DesignTokens.Radius.button)
        }
    }
}

// MARK: - Preview

#Preview("Prepare For Outage Modal") {
    PrepareForOutageModal(
        card: EmailCard(
            id: "preview",
            type: .mail,
            state: .seen,
            priority: .medium,
            hpa: "prepare_for_outage",
            timeAgo: "2h",
            title: "Planned Power Outage Notice",
            summary: "We will be performing scheduled maintenance on electrical equipment in your area. Power will be off tomorrow from 9:00 AM to 3:00 PM. Please prepare ahead of time.",
            body: "Dear Customer,\n\nWe are writing to inform you of a planned power outage in your neighborhood.\n\nDate: Tomorrow\nTime: 9:00 AM - 3:00 PM\nDuration: 6 hours\nReason: Equipment maintenance\n\nAffected Areas: Downtown district, Main Street corridor\n\nPlease prepare by:\n• Charging all electronic devices\n• Storing perishable food items\n• Having flashlights ready\n• Turning off sensitive equipment\n\nWe apologize for any inconvenience.\n\nThank you for your understanding.",
            metaCTA: "View",
            suggestedActions: [
                EmailAction(
                    actionId: "prepare_for_outage",
                    displayName: "Prepare for Outage",
                    actionType: .inApp,
                    isPrimary: true,
                    context: [:]
                )
            ],
            sender: SenderInfo(
                name: "PG&E",
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
