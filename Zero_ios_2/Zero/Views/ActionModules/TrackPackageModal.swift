import SwiftUI

struct TrackPackageModal: View {
    let card: EmailCard
    let trackingNumber: String
    let carrier: String
    let trackingUrl: String
    let context: [String: Any]
    @Binding var isPresented: Bool

    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var copiedToClipboard = false

    // Extract optional context
    var orderNumber: String? {
        context["orderNumber"] as? String
    }

    var estimatedDelivery: String? {
        context["estimatedDelivery"] as? String ?? context["deliveryDate"] as? String
    }

    var deliveryStatus: String? {
        context["deliveryStatus"] as? String
    }

    // Carrier branding
    var carrierIcon: String {
        let lowerCarrier = carrier.lowercased()
        if lowerCarrier.contains("ups") {
            return "shippingbox.fill"
        } else if lowerCarrier.contains("fedex") {
            return "cube.box.fill"
        } else if lowerCarrier.contains("usps") {
            return "envelope.fill"
        } else if lowerCarrier.contains("dhl") {
            return "airplane"
        } else if lowerCarrier.contains("amazon") {
            return "bag.fill"
        } else {
            return "shippingbox"
        }
    }

    var carrierColor: Color {
        let lowerCarrier = carrier.lowercased()
        if lowerCarrier.contains("ups") {
            return .brown
        } else if lowerCarrier.contains("fedex") {
            return .purple
        } else if lowerCarrier.contains("usps") {
            return .blue
        } else if lowerCarrier.contains("dhl") {
            return .yellow
        } else if lowerCarrier.contains("amazon") {
            return .orange
        } else {
            return .gray
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
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .font(.title2)
                }
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: carrierIcon)
                                .font(.largeTitle)
                                .foregroundColor(carrierColor)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Track Your Package")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Text(carrier)
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Tracking details
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                        Text("Shipment Details")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        // Tracking number (large, prominent)
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                            Text("Tracking Number")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSubtle)

                            HStack {
                                Text(trackingNumber)
                                    .font(.title3.bold().monospaced())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Spacer()

                                Button {
                                    copyTrackingNumber()
                                } label: {
                                    Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc")
                                        .foregroundColor(copiedToClipboard ? .green : .blue)
                                        .font(.title3)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Radius.button)
                        }

                        if let order = orderNumber {
                            DetailRow(
                                icon: "number.circle.fill",
                                label: "Order Number",
                                value: order,
                                color: .cyan
                            )
                        }

                        if let delivery = estimatedDelivery {
                            DetailRow(
                                icon: "calendar.circle.fill",
                                label: "Estimated Delivery",
                                value: delivery,
                                color: .green
                            )
                        }

                        if let status = deliveryStatus {
                            DetailRow(
                                icon: "box.truck.fill",
                                label: "Status",
                                value: status,
                                color: .orange
                            )
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Tracking timeline (simplified - Phase 1)
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                        Text("Delivery Progress")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                            TrackingStep(
                                icon: "checkmark.circle.fill",
                                title: "Order Placed",
                                isCompleted: true,
                                color: .green
                            )

                            TrackingStep(
                                icon: "shippingbox.fill",
                                title: "Shipped",
                                isCompleted: true,
                                color: .green
                            )

                            TrackingStep(
                                icon: "box.truck.fill",
                                title: "In Transit",
                                isCompleted: deliveryStatus?.lowercased().contains("transit") ?? false,
                                color: .orange
                            )

                            TrackingStep(
                                icon: "location.fill",
                                title: "Out for Delivery",
                                isCompleted: deliveryStatus?.lowercased().contains("out for delivery") ?? false,
                                color: .blue
                            )

                            TrackingStep(
                                icon: "house.fill",
                                title: "Delivered",
                                isCompleted: deliveryStatus?.lowercased().contains("delivered") ?? false,
                                color: .purple
                            )
                        }
                    }

                    // Action buttons
                    VStack(spacing: DesignTokens.Spacing.component) {
                        // Live Activity button (iOS 16.1+)
                        if #available(iOS 16.1, *) {
                            Button {
                                startLiveActivity()
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Track on Dynamic Island")
                                }
                            }
                            .buttonStyle(GradientButtonStyle(colors: [.vibrantPurple, .vibrantBlue]))
                        }

                        Button {
                            openTrackingUrl()
                        } label: {
                            HStack {
                                Image(systemName: "safari")
                                Text("View Full Details")
                            }
                        }
                        .buttonStyle(.gradientPrimary)

                        Button {
                            shareTracking()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Tracking Info")
                            }
                        }
                        .buttonStyle(.gradientLifestyle)

                        if showSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Tracking info shared!")
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
                            .cornerRadius(DesignTokens.Spacing.inline)
                        }
                    }
                    .padding(.top, DesignTokens.Spacing.card)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
    }

    func openTrackingUrl() {
        guard let url = URL(string: trackingUrl) else {
            errorMessage = "Invalid tracking URL"
            showError = true
            return
        }

        UIApplication.shared.open(url)
        Logger.info("Opening tracking URL for \(carrier)", category: .action)

        // Analytics
        AnalyticsService.shared.log("tracking_url_opened", properties: [
            "carrier": carrier,
            "tracking_number": trackingNumber,
            "has_order_number": orderNumber != nil,
            "source": "track_package_modal"
        ])

        // Auto-dismiss after opening URL
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }

    func copyTrackingNumber() {
        UIPasteboard.general.string = trackingNumber

        withAnimation {
            copiedToClipboard = true
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Logger.info("Tracking number copied: \(trackingNumber)", category: .action)

        // Analytics
        AnalyticsService.shared.log("tracking_number_copied", properties: [
            "carrier": carrier,
            "tracking_number_length": trackingNumber.count
        ])

        // Reset copied state after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copiedToClipboard = false
            }
        }
    }

    func shareTracking() {
        let shareText = """
        📦 Package Tracking

        Tracking #: \(trackingNumber)
        Carrier: \(carrier)
        \(estimatedDelivery != nil ? "Est. Delivery: \(estimatedDelivery!)" : "")

        Track: \(trackingUrl)
        """

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        // Get the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)

            withAnimation {
                showSuccess = true
            }

            Logger.info("Sharing tracking info for \(carrier)", category: .action)

            // Analytics
            AnalyticsService.shared.log("tracking_shared", properties: [
                "carrier": carrier,
                "tracking_number": trackingNumber
            ])

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSuccess = false
            }
        }
    }

    @available(iOS 16.1, *)
    func startLiveActivity() {
        // Extract package description from context if available
        let packageDescription = context["packageDescription"] as? String ?? card.title

        // Determine initial status based on delivery status
        let initialStatus: TrackingStatus
        if let status = deliveryStatus?.lowercased() {
            if status.contains("delivered") {
                initialStatus = .delivered
            } else if status.contains("out for delivery") {
                initialStatus = .outForDelivery
            } else if status.contains("transit") {
                initialStatus = .inTransit
            } else if status.contains("shipped") {
                initialStatus = .shipped
            } else {
                initialStatus = .shipped // Default to shipped
            }
        } else {
            initialStatus = .shipped
        }

        // Extract current location from context
        let currentLocation = context["currentLocation"] as? String

        // Start the Live Activity
        let activityId = LiveActivityManager.shared.startPackageTracking(
            trackingNumber: trackingNumber,
            carrier: carrier,
            description: packageDescription,
            initialStatus: initialStatus,
            currentLocation: currentLocation,
            estimatedDelivery: estimatedDelivery ?? "Pending"
        )

        if activityId != nil {
            // Show success feedback
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)

            withAnimation {
                showSuccess = true
            }

            Logger.info("Live Activity started for tracking: \(trackingNumber)", category: .action)

            // Analytics
            AnalyticsService.shared.log("live_activity_started", properties: [
                "tracking_number": trackingNumber,
                "carrier": carrier,
                "initial_status": initialStatus.rawValue
            ])

            // Optional: Start simulated updates for testing (DEBUG only)
            #if DEBUG
            if UserDefaults.standard.bool(forKey: "simulateLiveActivityUpdates") {
                LiveActivityManager.shared.simulateTrackingUpdates(trackingNumber: trackingNumber)
                Logger.info("Started simulated tracking updates", category: .action)
            }
            #endif

            // Hide success message and dismiss modal
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showSuccess = false
                }
                isPresented = false
            }
        } else {
            // Show error - Live Activities disabled or unavailable
            errorMessage = "Live Activities are not available. Please enable them in Settings > Notifications."
            showError = true

            Logger.warning("Failed to start Live Activity - may be disabled", category: .action)

            // Analytics for failure
            AnalyticsService.shared.log("live_activity_failed", properties: [
                "tracking_number": trackingNumber,
                "carrier": carrier,
                "reason": "activities_disabled"
            ])

            // Auto-hide error after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showError = false
                }
            }
        }
    }
}

// Tracking step component
struct TrackingStep: View {
    let icon: String
    let title: String
    let isCompleted: Bool
    let color: Color

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.component) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isCompleted ? color : .white.opacity(DesignTokens.Opacity.overlayMedium))
                .frame(width: 30)

            Text(title)
                .font(.subheadline)
                .foregroundColor(isCompleted ? DesignTokens.Colors.textPrimary : .white.opacity(DesignTokens.Opacity.overlayStrong))

            Spacer()

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundColor(color)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.inline)
    }
}
