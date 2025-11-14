import SwiftUI
import MapKit

struct PickupDetailsModal: View {
    let card: EmailCard
    let rxNumber: String
    let pharmacy: String
    let context: [String: Any]
    @Binding var isPresented: Bool

    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false

    // Extract pharmacy details from context
    var pharmacyAddress: String {
        (context["pharmacyAddress"] as? String) ?? "Location details in email"
    }

    var pharmacyPhone: String? {
        context["pharmacyPhone"] as? String
    }

    var pharmacyHours: String {
        (context["pharmacyHours"] as? String) ?? "Mon-Fri 9AM-6PM"
    }

    var pickupDeadline: String? {
        context["pickupDeadline"] as? String
    }

    var medicationName: String? {
        context["medicationName"] as? String
    }

    var copay: String? {
        context["copay"] as? String
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
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .font(.title2)
                }
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                        HStack {
                            Image(systemName: "pills.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Prescription Ready")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                if let medication = medicationName {
                                    Text(medication)
                                        .font(.subheadline)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Prescription details
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                        Text("Prescription Details")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        DetailRow(
                            icon: "number.circle.fill",
                            label: "Rx Number",
                            value: rxNumber,
                            color: .blue
                        )

                        if let copay = copay {
                            DetailRow(
                                icon: "dollarsign.circle.fill",
                                label: "Copay",
                                value: copay,
                                color: .green
                            )
                        }

                        if let deadline = pickupDeadline {
                            DetailRow(
                                icon: "clock.fill",
                                label: "Pick up by",
                                value: deadline,
                                color: .orange
                            )
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Pharmacy details
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                        Text("Pharmacy Location")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        // Embedded map preview
                        MapPreviewView(
                            locationName: pharmacy,
                            address: pharmacyAddress,
                            height: 200
                        )

                        DetailRow(
                            icon: "clock.fill",
                            label: "Hours",
                            value: pharmacyHours,
                            color: .blue
                        )

                        if let phone = pharmacyPhone {
                            DetailRow(
                                icon: "phone.circle.fill",
                                label: "Phone",
                                value: phone,
                                color: .green
                            )
                        }
                    }

                    // Action buttons
                    VStack(spacing: DesignTokens.Spacing.component) {
                        Button {
                            openDirections()
                        } label: {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Get Directions")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .cornerRadius(DesignTokens.Radius.button)
                        }

                        if let phone = pharmacyPhone {
                            Button {
                                callPharmacy(phone: phone)
                            } label: {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text("Call Pharmacy")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                        }

                        Button {
                            addReminder()
                        } label: {
                            HStack {
                                Image(systemName: "bell.fill")
                                Text("Set Pickup Reminder")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .cornerRadius(DesignTokens.Radius.button)
                        }

                        if showSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Reminder set!")
                                    .foregroundColor(.green)
                                    .font(.headline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(DesignTokens.Opacity.overlayLight))
                            .cornerRadius(DesignTokens.Radius.button)
                        }

                        if showError, let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.red.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Radius.chip)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
    }

    func openDirections() {
        // Encode pharmacy name and address for Maps URL
        let query = "\(pharmacy) \(pharmacyAddress)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let mapsURL = URL(string: "maps://?q=\(query)") {
            if UIApplication.shared.canOpenURL(mapsURL) {
                UIApplication.shared.open(mapsURL)
                Logger.info("Opening directions to pharmacy", category: .action)

                // Analytics
                AnalyticsService.shared.log("pharmacy_directions_opened", properties: [
                    "pharmacy": pharmacy,
                    "rx_number": rxNumber
                ])
            } else {
                // Fallback to Google Maps web
                if let googleMapsURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(query)") {
                    UIApplication.shared.open(googleMapsURL)
                }
            }
        }
    }

    func callPharmacy(phone: String) {
        let cleanedPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        if let phoneURL = URL(string: "tel://\(cleanedPhone)") {
            if UIApplication.shared.canOpenURL(phoneURL) {
                UIApplication.shared.open(phoneURL)
                Logger.info("Calling pharmacy: \(phone)", category: .action)

                // Analytics
                AnalyticsService.shared.log("pharmacy_called", properties: [
                    "pharmacy": pharmacy,
                    "rx_number": rxNumber
                ])
            } else {
                errorMessage = "Unable to make phone calls on this device"
                showError = true
            }
        } else {
            errorMessage = "Invalid phone number"
            showError = true
        }
    }

    func addReminder() {
        // Create reminder title
        let title = if let medication = medicationName {
            "Pick up \(medication) at \(pharmacy)"
        } else {
            "Pick up prescription at \(pharmacy)"
        }

        // Create detailed notes
        var notes = "Rx Number: \(rxNumber)\n"
        notes += "Pharmacy: \(pharmacy)\n"
        notes += "Address: \(pharmacyAddress)\n"
        if let phone = pharmacyPhone {
            notes += "Phone: \(phone)\n"
        }
        notes += "Hours: \(pharmacyHours)"

        // Parse due date from pickupDeadline if available
        var dueDate: Date?
        if let deadline = pickupDeadline {
            dueDate = parseDateFromString(deadline)
        }

        // Default to tomorrow at 5 PM if no deadline
        if dueDate == nil {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            var components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 17  // 5 PM
            components.minute = 0
            dueDate = Calendar.current.date(from: components)
        }

        // Create reminder with HIGH priority (medical is urgent)
        RemindersService.shared.createReminder(
            title: title,
            notes: notes,
            dueDate: dueDate,
            priority: 1  // High priority (1-4)
        ) { result in
            switch result {
            case .success:
                withAnimation {
                    showSuccess = true
                }

                Logger.info("Pickup reminder created for Rx \(rxNumber)", category: .action)

                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.success)

                // Analytics
                AnalyticsService.shared.log("pickup_reminder_created", properties: [
                    "pharmacy": pharmacy,
                    "rx_number": rxNumber,
                    "has_deadline": pickupDeadline != nil,
                    "has_medication_name": medicationName != nil
                ])

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccess = false
                }

            case .failure(let error):
                Logger.error("Failed to create reminder: \(error.localizedDescription)", category: .action)

                errorMessage = "Could not create reminder. Please check Reminders permission in Settings."
                showError = true

                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.error)

                // Analytics
                AnalyticsService.shared.log("pickup_reminder_failed", properties: [
                    "pharmacy": pharmacy,
                    "rx_number": rxNumber,
                    "error": error.localizedDescription
                ])

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showError = false
                }
            }
        }
    }

    /// Parse date from string like "Friday at 6 PM" or "Oct 25, 2025"
    private func parseDateFromString(_ dateString: String) -> Date? {
        // Try common date formats
        let formatters = [
            // "October 25, 2025"
            createDateFormatter(format: "MMMM d, yyyy"),
            // "Oct 25, 2025"
            createDateFormatter(format: "MMM d, yyyy"),
            // "10/25/2025"
            createDateFormatter(format: "MM/dd/yyyy"),
            // "2025-10-25"
            createDateFormatter(format: "yyyy-MM-dd")
        ]

        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                // Set time to 5 PM
                var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                components.hour = 17
                components.minute = 0
                return Calendar.current.date(from: components)
            }
        }

        // Try to detect day of week (Friday, Monday, etc.)
        let lowercased = dateString.lowercased()
        let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

        for (index, weekday) in weekdays.enumerated() {
            if lowercased.contains(weekday) {
                // Find next occurrence of this weekday
                let targetWeekday = index + 2  // Calendar.current weekday is 1-based, Sunday = 1
                let today = Date()
                let currentWeekday = Calendar.current.component(.weekday, from: today)

                var daysToAdd = targetWeekday - currentWeekday
                if daysToAdd <= 0 {
                    daysToAdd += 7  // Next week
                }

                if let futureDate = Calendar.current.date(byAdding: .day, value: daysToAdd, to: today) {
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: futureDate)
                    components.hour = 17  // 5 PM
                    components.minute = 0
                    return Calendar.current.date(from: components)
                }
            }
        }

        return nil
    }

    private func createDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
}

// Detail row component
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.component) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(DesignTokens.Colors.textSubtle)

                Text(value)
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }
}
