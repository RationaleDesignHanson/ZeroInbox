import SwiftUI

/// Review Security Modal
/// Handles review_security, revoke_secret, verify_transaction actions
struct ReviewSecurityModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    let securityType: SecurityType
    let actionUrl: String?
    let context: [String: String]

    @State private var showConfirmation = false
    @State private var showSuccess = false

    enum SecurityType {
        case reviewActivity, revokeAccess, verifyTransaction, suspiciousActivity

        var title: String {
            switch self {
            case .reviewActivity: return "Review Security Activity"
            case .revokeAccess: return "Revoke Access"
            case .verifyTransaction: return "Verify Transaction"
            case .suspiciousActivity: return "Suspicious Activity"
            }
        }

        var icon: String {
            switch self {
            case .reviewActivity: return "shield.checkered"
            case .revokeAccess: return "key.slash.fill"
            case .verifyTransaction: return "checkmark.shield.fill"
            case .suspiciousActivity: return "exclamationmark.shield.fill"
            }
        }

        var color: Color {
            switch self {
            case .reviewActivity: return .blue
            case .revokeAccess: return .red
            case .verifyTransaction: return .green
            case .suspiciousActivity: return .orange
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header (Week 6: Using shared ModalHeader component)
            ModalHeader(isPresented: $isPresented)

            if showSuccess {
                successView
            } else {
                securityReviewView
            }
        }
        .background(
            LinearGradient(
                colors: [securityType.color.opacity(DesignTokens.Opacity.overlayMedium), Color.purple.opacity(DesignTokens.Opacity.overlayMedium)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    private var securityReviewView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [securityType.color.opacity(DesignTokens.Opacity.overlayMedium), Color.purple.opacity(DesignTokens.Opacity.overlayMedium)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)

                    Image(systemName: securityType.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }

                // Title
                Text(securityType.title)
                    .font(.title.bold())
                    .foregroundColor(.white)

                // Alert Banner (for suspicious activity)
                if securityType == .suspiciousActivity {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Action Required")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("We detected unusual activity on your account")
                                .font(.caption)
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color.orange.opacity(DesignTokens.Opacity.overlayMedium))
                    .cornerRadius(DesignTokens.Radius.button)
                }

                // Security Details Card
                VStack(alignment: .leading, spacing: 16) {
                    // Service/Account
                    if let service = context["service"] ?? context["accountName"] ?? card.company?.name,
                       !service.isEmpty {
                        SecurityDetailRow(
                            icon: "building.2.fill",
                            label: "Service",
                            value: service
                        )
                    }

                    // Device/Location
                    if let device = context["device"] ?? context["deviceName"],
                       !device.isEmpty {
                        SecurityDetailRow(
                            icon: "iphone",
                            label: "Device",
                            value: device
                        )
                    }

                    if let location = context["location"] ?? context["ipLocation"],
                       !location.isEmpty {
                        SecurityDetailRow(
                            icon: "mappin.circle",
                            label: "Location",
                            value: location
                        )
                    }

                    // IP Address
                    if let ipAddress = context["ipAddress"],
                       !ipAddress.isEmpty {
                        SecurityDetailRow(
                            icon: "network",
                            label: "IP Address",
                            value: ipAddress
                        )
                    }

                    // Timestamp
                    if let timestamp = context["timestamp"] ?? context["date"],
                       !timestamp.isEmpty {
                        SecurityDetailRow(
                            icon: "clock.fill",
                            label: "Time",
                            value: timestamp
                        )
                    }

                    // Transaction Amount (if applicable)
                    if securityType == .verifyTransaction,
                       let amount = context["amount"] ?? context["transactionAmount"],
                       !amount.isEmpty {
                        SecurityDetailRow(
                            icon: "dollarsign.circle.fill",
                            label: "Amount",
                            value: amount
                        )
                    }

                    // Access Type (for revoke)
                    if securityType == .revokeAccess,
                       let accessType = context["accessType"] ?? context["permission"],
                       !accessType.isEmpty {
                        SecurityDetailRow(
                            icon: "key.fill",
                            label: "Access Type",
                            value: accessType
                        )
                    }
                }
                .padding()
                .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                .cornerRadius(DesignTokens.Radius.button)

                // Security Recommendations
                VStack(alignment: .leading, spacing: 12) {
                    Text("Security Tips")
                        .font(.headline)
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 10) {
                        SecurityTipRow(
                            icon: "lock.shield.fill",
                            text: "Always use strong, unique passwords"
                        )
                        SecurityTipRow(
                            icon: "checkmark.shield.fill",
                            text: "Enable two-factor authentication"
                        )
                        SecurityTipRow(
                            icon: "eye.slash.fill",
                            text: "Never share verification codes"
                        )
                        if securityType == .revokeAccess {
                            SecurityTipRow(
                                icon: "arrow.clockwise",
                                text: "Review connected apps regularly"
                            )
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                .cornerRadius(DesignTokens.Radius.button)

                // Actions
                VStack(spacing: 12) {
                    // Primary Action Button
                    if let url = actionUrl {
                        Button {
                            if let urlObj = URL(string: url) {
                                UIApplication.shared.open(urlObj)
                                HapticService.shared.success()
                                Logger.info("Opening security action URL: \(url)", category: .action)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text(getPrimaryActionText())
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(
                                colors: [securityType.color, securityType.color.opacity(DesignTokens.Opacity.textSubtle)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                    }

                    // Revoke/Deny Button (for security actions)
                    if securityType == .revokeAccess || securityType == .verifyTransaction {
                        Button {
                            showConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: securityType == .revokeAccess ? "key.slash.fill" : "xmark.circle.fill")
                                Text(securityType == .revokeAccess ? "Revoke Access" : "Deny Transaction")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(DesignTokens.Opacity.textSubtle))
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                    }

                    // Contact Support
                    Button {
                        contactSecuritySupport()
                    } label: {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Contact Security Team")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayLight))
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                }
            }
            .padding()
        }
        .alert("Confirm Action", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button(securityType == .revokeAccess ? "Revoke" : "Deny", role: .destructive) {
                performSecurityAction()
            }
        } message: {
            Text(securityType == .revokeAccess ?
                 "Are you sure you want to revoke this access? This action cannot be undone." :
                 "Are you sure you want to deny this transaction? The sender will be notified.")
        }
    }

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(DesignTokens.Opacity.overlayLight))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.white)
            }

            // Success Message
            VStack(spacing: 12) {
                Text("Action Completed!")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("Your account is now more secure")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
            }

            Spacer()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isPresented = false
            }
        }
    }

    private func getPrimaryActionText() -> String {
        switch securityType {
        case .reviewActivity:
            return "Review Full Activity Log"
        case .revokeAccess:
            return "Manage Permissions"
        case .verifyTransaction:
            return "Verify This Transaction"
        case .suspiciousActivity:
            return "Secure My Account"
        }
    }

    private func performSecurityAction() {
        HapticService.shared.success()
        Logger.info("Security action performed: \(securityType.title)", category: .action)

        withAnimation {
            showSuccess = true
        }
    }

    private func contactSecuritySupport() {
        // Open email composer to contact security team
        if let supportEmail = context["supportEmail"] ?? context["securityEmail"] {
            if let url = URL(string: "mailto:\(supportEmail)?subject=Security%20Concern") {
                UIApplication.shared.open(url)
                HapticService.shared.mediumImpact()
                Logger.info("Opening email to security team: \(supportEmail)", category: .action)
            }
        } else {
            // Fallback: open sender's email
            if let senderEmail = card.sender?.email {
                if let url = URL(string: "mailto:\(senderEmail)?subject=Security%20Concern") {
                    UIApplication.shared.open(url)
                    HapticService.shared.mediumImpact()
                }
            }
        }
    }
}

// MARK: - SecurityDetailRow Component

struct SecurityDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
            }

            Spacer()
        }
    }
}

// MARK: - SecurityTipRow Component

struct SecurityTipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green.opacity(DesignTokens.Opacity.textTertiary))
                .font(.caption)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))

            Spacer()
        }
    }
}
