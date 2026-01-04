import SwiftUI

/// Premium action modal for flight check-in
/// Refactored to use shared component library (Phase 5.2c)
struct CheckInFlightModal: View {
    let card: EmailCard
    let flightNumber: String
    let airline: String
    let checkInUrl: String
    let context: [String: Any]
    @Binding var isPresented: Bool

    @State private var showSuccess = false
    @State private var errorMessage: String?

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
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header section
                    headerSection

                    // Flight details with shared components
                    flightDetailsSection

                    // Boarding information (if available)
                    if gate != nil || terminal != nil || seatNumber != nil {
                        boardingInfoSection
                    }

                    // Success/error banners
                    if showSuccess {
                        ModalSuccessBanner(
                            title: "Check-In Initiated!",
                            message: "You'll be redirected to complete check-in",
                            onDismiss: { showSuccess = false }
                        )
                    }

                    if let error = errorMessage {
                        ModalErrorBanner(
                            title: "Check-In Failed",
                            message: error,
                            actionTitle: "Try Again",
                            action: { checkInNow() },
                            onDismiss: { errorMessage = nil }
                        )
                    }
                }
                .padding(DesignTokens.Spacing.card)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Flight Check-In")
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Unified button footer
                checkInButtonsFooter
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 16) {
            // Flight icon
            ZStack {
                Circle()
                    .fill(airlineColor(for: airline).opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: "airplane.departure")
                    .font(.title)
                    .foregroundColor(airlineColor(for: airline))
            }

            // Title and airline
            VStack(alignment: .leading, spacing: 4) {
                Text("Flight Check-In")
                    .font(.title2.bold())
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Text(airline)
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.Colors.textSubtle)
            }

            Spacer()
        }
    }

    // MARK: - Flight Details Section

    private var flightDetailsSection: some View {
        ModalSectionView(title: "Flight Details", background: .glass) {
            // Flight number
            InfoRow(
                label: "Flight Number",
                value: flightNumber,
                icon: "airplane.circle.fill",
                iconColor: .blue
            )

            if let departureTime = departureTime {
                InfoRow(
                    label: "Departure Time",
                    value: departureTime,
                    icon: "clock.fill",
                    iconColor: .orange
                )
            }

            if let origin = origin, let destination = destination {
                InfoRow(
                    label: "Route",
                    value: "\(origin) → \(destination)",
                    icon: "arrow.right.circle.fill",
                    iconColor: .green
                )
            } else if let destination = destination {
                InfoRow(
                    label: "Destination",
                    value: destination,
                    icon: "mappin.circle.fill",
                    iconColor: .green
                )
            }

            // Confirmation code - using shared CopyableField
            if let confirmationCode = confirmationCode {
                Divider()
                    .padding(.vertical, 8)

                CopyableField(
                    label: "Confirmation Code",
                    value: confirmationCode,
                    icon: "number.circle.fill",
                    iconColor: .purple,
                    style: .inline
                )
            }
        }
    }

    // MARK: - Boarding Information Section

    private var boardingInfoSection: some View {
        ModalSectionView(title: "Boarding Information", background: .glass) {
            if let terminal = terminal {
                InfoRow(
                    label: "Terminal",
                    value: terminal,
                    icon: "building.2.fill",
                    iconColor: .blue
                )
            }

            if let gate = gate {
                InfoRow(
                    label: "Gate",
                    value: gate,
                    icon: "rectangle.portrait.fill",
                    iconColor: .orange
                )
            }

            if let seatNumber = seatNumber {
                InfoRow(
                    label: "Seat",
                    value: seatNumber,
                    icon: "chair.fill",
                    iconColor: .green
                )
            }
        }
    }

    // MARK: - Check-In Buttons Footer

    private var checkInButtonsFooter: some View {
        VStack(spacing: 12) {
            // Primary: Check In Now
            Button {
                checkInNow()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Check In Now")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color(red: 0.0, green: 0.6, blue: 0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(DesignTokens.Radius.button)
            }

            // Secondary actions
            HStack(spacing: 12) {
                // Add to Wallet
                Button {
                    addToWallet()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "wallet.pass.fill")
                        Text("Add to Wallet")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(DesignTokens.Radius.button)
                }

                // Share Flight Info
                Button {
                    shareFlightInfo()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(DesignTokens.Radius.button)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.section)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }

    // MARK: - Helper Functions

    func airlineColor(for airline: String) -> Color {
        let lowercased = airline.lowercased()
        if lowercased.contains("united") { return .blue }
        if lowercased.contains("american") { return .red }
        if lowercased.contains("delta") { return .blue }
        if lowercased.contains("southwest") { return .orange }
        if lowercased.contains("jetblue") { return .blue }
        if lowercased.contains("alaska") { return .blue }
        return .blue // Default
    }

    // MARK: - Actions

    func checkInNow() {
        guard let url = URL(string: checkInUrl) else {
            errorMessage = "Invalid check-in URL"
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
            "destination": destination ?? "Unknown",
            "source": "check_in_flight_modal"
        ])

        // Auto-dismiss after showing success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPresented = false
        }
    }

    func addToWallet() {
        // TODO: Implement PassKit integration
        // This would create a boarding pass and add to Apple Wallet
        // For now, show success feedback

        showSuccess = true

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Logger.info("Boarding pass added to wallet: \(flightNumber)", category: .action)

        AnalyticsService.shared.log("boarding_pass_added", properties: [
            "flight_number": flightNumber,
            "airline": airline,
            "source": "check_in_flight_modal"
        ])

        // Reset success after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccess = false
        }
    }

    func shareFlightInfo() {
        var flightText = "✈️ Flight \(flightNumber) - \(airline)"

        if let departureTime = departureTime {
            flightText += "\n🕐 Departure: \(departureTime)"
        }
        if let origin = origin, let destination = destination {
            flightText += "\n📍 Route: \(origin) → \(destination)"
        }
        if let gate = gate {
            flightText += "\n🚪 Gate: \(gate)"
        }
        if let seatNumber = seatNumber {
            flightText += "\n💺 Seat: \(seatNumber)"
        }
        if let confirmationCode = confirmationCode {
            flightText += "\n🔖 Confirmation: \(confirmationCode)"
        }

        let activityVC = UIActivityViewController(
            activityItems: [flightText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }

        Logger.info("Flight info shared: \(flightNumber)", category: .action)

        AnalyticsService.shared.log("flight_info_shared", properties: [
            "flight_number": flightNumber,
            "airline": airline
        ])
    }
}

// MARK: - Preview

// Preview disabled - requires full EmailCard initialization
// #if DEBUG
// struct CheckInFlightModal_Previews: PreviewProvider {
//     static var previews: some View {
//         // Preview code here
//     }
// }
// #endif
