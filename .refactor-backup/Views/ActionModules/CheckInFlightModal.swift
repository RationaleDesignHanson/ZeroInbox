import SwiftUI

struct CheckInFlightModal: View {
    let card: EmailCard
    let flightNumber: String
    let airline: String
    let checkInUrl: String
    let context: [String: Any]
    @Binding var isPresented: Bool

    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false

    // Extract optional context
    var departureTime: String? {
        context["departureTime"] as? String
    }

    var destination: String? {
        context["destination"] as? String
    }

    var origin: String? {
        context["origin"] as? String
    }

    var confirmationCode: String? {
        context["confirmationCode"] as? String
    }

    var gate: String? {
        context["gate"] as? String
    }

    var terminal: String? {
        context["terminal"] as? String
    }

    var seatNumber: String? {
        context["seatNumber"] as? String
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
                    // Header with flight icon
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "airplane.departure")
                                .font(.largeTitle)
                                .foregroundColor(airlineColor(for: airline))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Flight Check-In")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Text(airline)
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Flight details
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                        Text("Flight Details")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        DetailRow(
                            icon: "airplane.circle.fill",
                            label: "Flight Number",
                            value: flightNumber,
                            color: .blue
                        )

                        if let departureTime = departureTime {
                            DetailRow(
                                icon: "clock.fill",
                                label: "Departure Time",
                                value: departureTime,
                                color: .orange
                            )
                        }

                        if let origin = origin, let destination = destination {
                            DetailRow(
                                icon: "arrow.right.circle.fill",
                                label: "Route",
                                value: "\(origin) → \(destination)",
                                color: .green
                            )
                        } else if let destination = destination {
                            DetailRow(
                                icon: "mappin.circle.fill",
                                label: "Destination",
                                value: destination,
                                color: .green
                            )
                        }

                        if let confirmationCode = confirmationCode {
                            DetailRow(
                                icon: "number.circle.fill",
                                label: "Confirmation Code",
                                value: confirmationCode,
                                color: .purple
                            )
                        }
                    }

                    // Gate & Seat info (if available)
                    if gate != nil || terminal != nil || seatNumber != nil {
                        Divider()
                            .background(Color.white.opacity(0.3))

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                            Text("Boarding Information")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            if let terminal = terminal {
                                DetailRow(
                                    icon: "building.2.fill",
                                    label: "Terminal",
                                    value: terminal,
                                    color: .blue
                                )
                            }

                            if let gate = gate {
                                DetailRow(
                                    icon: "rectangle.portrait.fill",
                                    label: "Gate",
                                    value: gate,
                                    color: .orange
                                )
                            }

                            if let seatNumber = seatNumber {
                                DetailRow(
                                    icon: "chair.fill",
                                    label: "Seat",
                                    value: seatNumber,
                                    color: .green
                                )
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Action buttons
                    VStack(spacing: DesignTokens.Spacing.component) {
                        // Primary action: Check In Now
                        Button {
                            checkInNow()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Check In Now")
                            }
                        }
                        .buttonStyle(GradientButtonStyle(colors: [.vibrantGreen, .vibrantEmerald]))

                        // Secondary actions
                        HStack(spacing: DesignTokens.Spacing.component) {
                            // Add to Wallet
                            Button {
                                addToWallet()
                            } label: {
                                HStack {
                                    Image(systemName: "wallet.pass.fill")
                                    Text("Add to Wallet")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(GradientButtonStyle(colors: [.vibrantBlue, .vibrantCyan]))

                            // Share Flight Info
                            Button {
                                shareFlightInfo()
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.gradientLifestyle)
                        }

                        if showSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Check-in initiated!")
                                    .foregroundColor(.green)
                                    .font(.headline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.2))
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
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(DesignTokens.Spacing.inline)
                        }
                    }
                    .padding(.top, DesignTokens.Spacing.card)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
    }

    func airlineColor(for airline: String) -> Color {
        let lowercased = airline.lowercased()
        if lowercased.contains("united") { return .blue }
        if lowercased.contains("american") { return .red }
        if lowercased.contains("delta") { return .blue }
        if lowercased.contains("southwest") { return .orange }
        if lowercased.contains("jetblue") { return .blue }
        return .blue // Default
    }

    func checkInNow() {
        guard let url = URL(string: checkInUrl) else {
            errorMessage = "Invalid check-in URL"
            showError = true
            return
        }

        // Open airline check-in website
        UIApplication.shared.open(url)

        // Show success feedback
        showSuccess = true

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        Logger.info("Flight check-in initiated: \(flightNumber)", category: .action)

        // Analytics
        AnalyticsService.shared.log("check_in_initiated", properties: [
            "flight_number": flightNumber,
            "airline": airline,
            "destination": destination ?? "Unknown"
        ])

        // Auto-dismiss after showing success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPresented = false
        }
    }

    func addToWallet() {
        // Simulated wallet addition
        showSuccess = true

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Logger.info("Boarding pass added to wallet: \(flightNumber)", category: .action)

        AnalyticsService.shared.log("boarding_pass_added", properties: [
            "flight_number": flightNumber,
            "airline": airline
        ])

        // Reset success after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccess = false
        }
    }

    func shareFlightInfo() {
        var flightText = "Flight \(flightNumber) - \(airline)"
        if let departureTime = departureTime {
            flightText += "\nDeparture: \(departureTime)"
        }
        if let origin = origin, let destination = destination {
            flightText += "\nRoute: \(origin) → \(destination)"
        }
        if let gate = gate {
            flightText += "\nGate: \(gate)"
        }
        if let seatNumber = seatNumber {
            flightText += "\nSeat: \(seatNumber)"
        }

        let activityVC = UIActivityViewController(
            activityItems: [flightText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }

        Logger.info("Flight info shared: \(flightNumber)", category: .action)

        AnalyticsService.shared.log("flight_info_shared", properties: [
            "flight_number": flightNumber,
            "airline": airline
        ])
    }
}
