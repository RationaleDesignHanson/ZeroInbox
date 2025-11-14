import SwiftUI
import PassKit

struct AddToWalletModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var passOpportunity: PassOpportunity?
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

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
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: iconName)
                                .font(.title)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(passOpportunity?.title ?? "Add to Wallet")
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

                    // Pass preview
                    VStack(alignment: .leading, spacing: 16) {
                        Text(passOpportunity?.description ?? "Add this pass to your Apple Wallet for quick access")
                            .font(.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineSpacing(4)

                        // Pass info card
                        VStack(spacing: 12) {
                            // Flight/Event details
                            if let details = extractDetails() {
                                ForEach(details, id: \.key) { detail in
                                    HStack {
                                        Text(detail.key)
                                            .font(.caption)
                                            .foregroundColor(DesignTokens.Colors.textSubtle)
                                        Spacer()
                                        Text(detail.value)
                                            .font(.subheadline.bold())
                                            .foregroundColor(DesignTokens.Colors.textPrimary)
                                    }
                                }
                            }
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

                        // Benefits list
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Benefits")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            ForEach(benefits, id: \.self) { benefit in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(benefit)
                                        .font(.caption)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                            }
                        }
                    }

                    // Add to Wallet button
                    Button {
                        addToWallet()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "wallet.pass.fill")
                                Text("Add to Apple Wallet")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.gray : Color.black)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .cornerRadius(DesignTokens.Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                        )
                    }
                    .disabled(isLoading || !WalletService.canAddPasses())

                    // Success message
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Added to Wallet!")
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

                    // Note about wallet capability
                    if !WalletService.canAddPasses() {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                            Text("Apple Wallet is not available on this device")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        }
                        .padding()
                        .background(Color.orange.opacity(DesignTokens.Opacity.overlayLight))
                        .cornerRadius(DesignTokens.Radius.chip)
                    }
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .onAppear {
            detectPassOpportunity()
        }
    }

    var iconName: String {
        switch passOpportunity?.type {
        case .boardingPass:
            return "airplane.departure"
        case .eventTicket:
            return "ticket.fill"
        case .coupon:
            return "tag.fill"
        case .storeCard:
            return "creditcard.fill"
        default:
            return "wallet.pass.fill"
        }
    }

    var benefits: [String] {
        switch passOpportunity?.type {
        case .boardingPass:
            return [
                "Quick access at security and boarding gate",
                "Automatic updates for gate changes",
                "Works offline - no internet needed",
                "Lock screen notifications for flight updates"
            ]
        case .eventTicket:
            return [
                "Easy access at venue entrance",
                "No need to print tickets",
                "Receive event updates and reminders",
                "Works offline"
            ]
        case .coupon:
            return [
                "Never forget to use your coupon",
                "Get reminders when near store",
                "Track expiration date",
                "Easy to show at checkout"
            ]
        default:
            return [
                "Quick access from lock screen",
                "Automatic updates",
                "Works offline"
            ]
        }
    }

    func detectPassOpportunity() {
        passOpportunity = WalletService.shared.detectPassOpportunity(in: card)
    }

    func extractDetails() -> [(key: String, value: String)]? {
        let text = "\(card.title) \(card.summary) \(card.body ?? "")"

        switch passOpportunity?.type {
        case .boardingPass:
            var details: [(key: String, value: String)] = []

            // Extract flight number
            if let flightMatch = text.range(of: #"([A-Z]{2})\s*(\d{1,4})"#, options: .regularExpression) {
                let flight = String(text[flightMatch]).replacingOccurrences(of: " ", with: "")
                details.append((key: "FLIGHT", value: flight))
            }

            // Extract date
            if let date = extractDate(from: text) {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                details.append((key: "DEPARTURE", value: formatter.string(from: date)))
            }

            // Extract confirmation/PNR
            if let pnr = extractConfirmation(from: text) {
                details.append((key: "CONFIRMATION", value: pnr))
            }

            return details.isEmpty ? nil : details

        case .eventTicket:
            var details: [(key: String, value: String)] = []

            // Event name
            details.append((key: "EVENT", value: card.title))

            // Date
            if let date = extractDate(from: text) {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                details.append((key: "DATE", value: formatter.string(from: date)))
            }

            return details

        default:
            return nil
        }
    }

    func extractDate(from text: String) -> Date? {
        // Try to extract date from text (simplified version)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        // This is a simplified extraction - in production you'd want more robust date parsing
        return nil
    }

    func extractConfirmation(from text: String) -> String? {
        // Pattern: 6-character alphanumeric confirmation code
        let pattern = #"\b([A-Z0-9]{6})\b"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            return String(text[range])
        }
        return nil
    }

    func addToWallet() {
        isLoading = true
        showError = false
        showSuccess = false

        // Check if we have extracted URLs
        if let urls = passOpportunity?.extractedURLs, let firstURL = urls.first {
            // We have a direct pass URL
            Logger.info("Adding pass from URL: \(firstURL)", category: .action)

            // Get the root view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                isLoading = false
                showError = true
                errorMessage = "Could not present Wallet interface"
                return
            }

            WalletService.shared.downloadAndAddPass(
                from: firstURL,
                presentingViewController: rootVC
            ) { result in
                DispatchQueue.main.async {
                    isLoading = false

                    switch result {
                    case .success:
                        showSuccess = true
                        Logger.info("Pass added to wallet successfully", category: .action)

                        // Haptic feedback
                        let impact = UINotificationFeedbackGenerator()
                        impact.notificationOccurred(.success)

                        // Auto-dismiss after success
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            isPresented = false
                        }

                    case .failure(let error):
                        showError = true
                        errorMessage = error.localizedDescription
                        Logger.error("Failed to add pass: \(error.localizedDescription)", category: .action)
                    }
                }
            }
        } else {
            // No direct URL found - show error
            isLoading = false
            showError = true
            errorMessage = "Could not find pass download link in this email. Please check the email for a 'Add to Wallet' button or link."
            Logger.warning("No pass URLs found in email", category: .action)
        }
    }
}
