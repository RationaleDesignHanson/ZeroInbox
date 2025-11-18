import SwiftUI
import UIKit

struct ShareModal: View {
    let card: EmailCard
    let content: String
    @Binding var isPresented: Bool

    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            ModalHeader(isPresented: $isPresented)

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Share")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Text(card.title)
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Share preview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Share this information with others")
                            .font(.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineSpacing(4)

                        // Preview of what will be shared
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Content to share:")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textTertiary)

                            Text(content)
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .lineLimit(10)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                        )

                        // Share options info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Share via")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            ForEach(shareOptions, id: \.self) { option in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text(option)
                                        .font(.caption)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                            }
                        }
                    }

                    // Share button
                    Button {
                        presentShareSheet()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .cornerRadius(DesignTokens.Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                        )
                    }

                    // Success message
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Shared successfully!")
                                .foregroundColor(.green)
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(DesignTokens.Opacity.overlayLight))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Error message
                    if showError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(DesignTokens.Opacity.overlayLight))
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    var shareOptions: [String] {
        [
            "Messages - Send via iMessage or SMS",
            "Mail - Send via email",
            "Notes - Save to Apple Notes",
            "Copy - Copy to clipboard",
            "AirDrop - Share with nearby devices",
            "Any other app you have installed"
        ]
    }

    func presentShareSheet() {
        Logger.info("Presenting share sheet with content", category: .action)

        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            showError = true
            errorMessage = "Could not present share sheet"
            return
        }

        // Create activity items
        let activityItems: [Any] = [content]

        // Create activity view controller
        let activityVC = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        // Exclude certain activity types if desired
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .print,
            .saveToCameraRoll
        ]

        // iPad: Present as popover
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        // Completion handler
        activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            DispatchQueue.main.async {
                if let error = error {
                    showError = true
                    errorMessage = error.localizedDescription
                    Logger.error("Share failed: \(error.localizedDescription)", category: .action)
                } else if completed {
                    showSuccess = true
                    Logger.info("Content shared successfully via \(activityType?.rawValue ?? "unknown")", category: .action)

                    // Haptic feedback
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)

                    // Track analytics
                    AnalyticsService.shared.log("share_completed", properties: [
                        "card_id": card.id,
                        "activity_type": activityType?.rawValue ?? "unknown",
                        "content_length": content.count
                    ])

                    // Auto-dismiss after success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isPresented = false
                    }
                }
            }
        }

        // Present the share sheet
        rootVC.present(activityVC, animated: true)

        // Track analytics
        AnalyticsService.shared.log("share_sheet_opened", properties: [
            "card_id": card.id,
            "content_length": content.count
        ])
    }
}

#Preview {
    ShareModal(
        card: EmailCard(
            id: "123",
            type: .ads,
            state: .unseen,
            priority: .high,
            hpa: "amazon.com",
            timeAgo: "2m",
            title: "Your Package Has Shipped",
            summary: "Track your order with tracking number 1Z999AA10123456784",
            metaCTA: "Track Package"
        ),
        content: "Your Package Has Shipped\n\nTrack your order with tracking number 1Z999AA10123456784\n\nTracking: 1Z999AA10123456784\n\nhttps://ups.com/track",
        isPresented: .constant(true)
    )
}
