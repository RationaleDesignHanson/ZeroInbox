import SwiftUI
import PassKit

/// Update Payment Modal
/// Handles update_payment_method, update_payment, add_payment_method actions
struct UpdatePaymentModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    let updateUrl: String?
    let context: [String: String]

    @State private var showSuccess = false
    @State private var selectedPaymentType: PaymentType = .card

    enum PaymentType: String, CaseIterable {
        case card = "Credit/Debit Card"
        case bank = "Bank Account"
        case wallet = "Digital Wallet"

        var icon: String {
            switch self {
            case .card: return "creditcard.fill"
            case .bank: return "building.columns.fill"
            case .wallet: return "wallet.pass.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)

            ScrollView {
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.green.opacity(0.3), .blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 100, height: 100)

                        Image(systemName: "creditcard.and.123")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }

                    // Title
                    Text("Update Payment Method")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    // Service Info
                    if let merchant = context["merchant"] ?? context["service"] ?? card.company?.name,
                       !merchant.isEmpty {
                        VStack(spacing: 8) {
                            Text("For")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            Text(merchant)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Current Payment Info (if available)
                    if let currentMethod = context["currentPaymentMethod"] ?? context["lastFourDigits"],
                       !currentMethod.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Current Payment Method")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))

                            HStack(spacing: 12) {
                                Image(systemName: "creditcard")
                                    .foregroundColor(.white.opacity(0.7))
                                Text(currentMethod.starts(with: "****") ? currentMethod : "•••• \(currentMethod)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }

                    // Reason for Update (if provided)
                    if let reason = context["reason"] ?? context["updateReason"],
                       !reason.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text(reason)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                    }

                    // Payment Type Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Payment Type")
                            .font(.headline)
                            .foregroundColor(.white)

                        ForEach(PaymentType.allCases, id: \.self) { type in
                            Button {
                                selectedPaymentType = type
                                HapticService.shared.lightImpact()
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: type.icon)
                                        .font(.title2)
                                        .foregroundColor(selectedPaymentType == type ? .green : .white.opacity(0.7))
                                        .frame(width: 40)

                                    Text(type.rawValue)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.white)

                                    Spacer()

                                    if selectedPaymentType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(selectedPaymentType == type ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }

                    // Important Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Important")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.8))

                        VStack(alignment: .leading, spacing: 8) {
                            NoteRow(icon: "lock.shield.fill", text: "Your payment information is securely encrypted")
                            NoteRow(icon: "arrow.triangle.2.circlepath", text: "Changes will apply to future charges")
                            NoteRow(icon: "bell.fill", text: "You'll receive a confirmation email")
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)

                    // Actions
                    VStack(spacing: 12) {
                        // Update Payment Button
                        if let url = updateUrl {
                            Button {
                                if let urlObj = URL(string: url) {
                                    UIApplication.shared.open(urlObj)
                                    HapticService.shared.success()
                                    Logger.info("Opening payment update URL: \(url)", category: .action)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text("Update Payment Method")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .cornerRadius(12)
                            }
                        } else {
                            // If no URL, show Apple Pay/Wallet option
                            Button {
                                openAppleWallet()
                            } label: {
                                HStack {
                                    Image(systemName: "wallet.pass.fill")
                                    Text("Manage in Wallet")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .cornerRadius(12)
                            }
                        }

                        // Contact Support
                        Button {
                            contactSupport()
                        } label: {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("Contact Support")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
        }
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.3), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    private func openAppleWallet() {
        // Open Apple Wallet app
        if let url = URL(string: "shoebox://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                HapticService.shared.success()
                Logger.info("Opened Apple Wallet", category: .action)
            }
        }
    }

    private func contactSupport() {
        // Open email composer to contact support
        if let email = context["supportEmail"] ?? card.sender?.email {
            if let url = URL(string: "mailto:\(email)?subject=Payment%20Method%20Update") {
                UIApplication.shared.open(url)
                HapticService.shared.mediumImpact()
                Logger.info("Opening email to contact support: \(email)", category: .action)
            }
        }
    }
}

// MARK: - NoteRow Component

struct NoteRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 16)

            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))

            Spacer()
        }
    }
}
