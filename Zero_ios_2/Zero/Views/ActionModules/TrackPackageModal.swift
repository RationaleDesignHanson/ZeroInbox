import SwiftUI

/// Premium action modal for package tracking
/// Refactored to use shared component library (Phase 5.2a)
struct TrackPackageModal: View {
    let card: EmailCard
    let trackingNumber: String
    let carrier: String
    let trackingUrl: String
    let context: [String: Any]
    @Binding var isPresented: Bool

    @State private var showSuccess = false
    @State private var errorMessage: String?

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
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header with carrier branding
                    headerSection

                    // Shipment details with shared components
                    shipmentDetailsSection

                    // Delivery timeline
                    deliveryProgressSection

                    // Success/error banners
                    if showSuccess {
                        ModalSuccessBanner(
                            title: "Success!",
                            message: "Action completed successfully",
                            onDismiss: { showSuccess = false }
                        )
                    }

                    if let error = errorMessage {
                        ModalErrorBanner(
                            title: "Error",
                            message: error,
                            onDismiss: { errorMessage = nil }
                        )
                    }
                }
                .padding(DesignTokens.Spacing.card)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Track Package")
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
                actionButtonsFooter
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 16) {
            // Carrier icon
            ZStack {
                Circle()
                    .fill(carrierColor.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: carrierIcon)
                    .font(.title)
                    .foregroundColor(carrierColor)
            }

            // Title and carrier
            VStack(alignment: .leading, spacing: 4) {
                Text("Track Your Package")
                    .font(.title2.bold())
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Text(carrier)
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.Colors.textSubtle)
            }

            Spacer()
        }
    }

    // MARK: - Shipment Details Section

    private var shipmentDetailsSection: some View {
        ModalSectionView(title: "Shipment Details", background: .glass) {
            // Tracking number - using shared CopyableField component
            CopyableField(
                label: "Tracking Number",
                value: trackingNumber,
                icon: "number.circle.fill",
                iconColor: .blue,
                style: .prominent
            )

            Divider()
                .padding(.vertical, 8)

            // Additional details using shared InfoRow component
            if let order = orderNumber {
                InfoRow(
                    label: "Order Number",
                    value: order,
                    icon: "bag.circle.fill",
                    iconColor: .cyan
                )
            }

            if let delivery = estimatedDelivery {
                InfoRow(
                    label: "Estimated Delivery",
                    value: delivery,
                    icon: "calendar.circle.fill",
                    iconColor: .green
                )
            }

            if let status = deliveryStatus {
                InfoRow(
                    label: "Current Status",
                    value: status,
                    icon: "box.truck.fill",
                    iconColor: .orange
                )
            }
        }
    }

    // MARK: - Delivery Progress Section

    private var deliveryProgressSection: some View {
        ModalSectionView(title: "Delivery Progress", background: .glass) {
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
    }

    // MARK: - Action Buttons Footer

    private var actionButtonsFooter: some View {
        VStack(spacing: 12) {
            // Live Activity button (iOS 16.1+)
            if #available(iOS 16.1, *) {
                Button {
                    startLiveActivity()
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Track on Dynamic Island")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(DesignTokens.Radius.button)
                }
            }

            // Primary action: View Full Details
            Button {
                openTrackingUrl()
            } label: {
                HStack {
                    Image(systemName: "safari")
                    Text("View Full Details")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(DesignTokens.Radius.button)
            }

            // Secondary action: Share
            Button {
                shareTracking()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Tracking Info")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(DesignTokens.Radius.button)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.section)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    func openTrackingUrl() {
        guard let url = URL(string: trackingUrl) else {
            errorMessage = "Invalid tracking URL"
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

            showSuccess = true

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

            showSuccess = true

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
                showSuccess = false
                isPresented = false
            }
        } else {
            // Show error - Live Activities disabled or unavailable
            errorMessage = "Live Activities are not available. Please enable them in Settings > Notifications."

            Logger.warning("Failed to start Live Activity - may be disabled", category: .action)

            // Analytics for failure
            AnalyticsService.shared.log("live_activity_failed", properties: [
                "tracking_number": trackingNumber,
                "carrier": carrier,
                "reason": "activities_disabled"
            ])

            // Auto-hide error after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                errorMessage = nil
            }
        }
    }
}

// MARK: - Tracking Step Component (Custom for this modal)

struct TrackingStep: View {
    let icon: String
    let title: String
    let isCompleted: Bool
    let color: Color

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.component) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isCompleted ? color : .secondary.opacity(0.4))
                .frame(width: 30)

            Text(title)
                .font(.subheadline)
                .foregroundColor(isCompleted ? .primary : .secondary)

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

// MARK: - Preview

// Preview disabled - requires full EmailCard initialization
// #if DEBUG
// struct TrackPackageModal_Previews: PreviewProvider {
//     static var previews: some View {
//         // Preview code here
//     }
// }
// #endif
