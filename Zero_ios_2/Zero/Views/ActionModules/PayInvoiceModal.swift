import SwiftUI
import PassKit

/// Premium action modal for invoice payment
/// Refactored to use shared component library (Phase 5.2b)
struct PayInvoiceModal: View {
    let card: EmailCard
    let invoiceId: String
    let amount: String
    let merchant: String
    let context: [String: Any]
    @Binding var isPresented: Bool

    @State private var selectedPaymentMethod = "Apple Pay"
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var isProcessing = false
    @State private var showPDFPreview = false

    // Extract optional context
    var dueDate: String? {
        context["dueDate"] as? String
    }

    var paymentLink: String? {
        context["paymentLink"] as? String
    }

    var lateFee: String? {
        context["lateFee"] as? String
    }

    var invoiceUrl: String? {
        context["invoiceUrl"] as? String
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header section
                    headerSection

                    // Invoice details with shared components
                    invoiceDetailsSection

                    // Payment method selection
                    paymentMethodSection

                    // Success/error banners
                    if showSuccess {
                        ModalSuccessBanner(
                            title: "Payment Successful!",
                            message: "Your payment of \(amount) has been processed",
                            onDismiss: { showSuccess = false }
                        )
                    }

                    if let error = errorMessage {
                        ModalErrorBanner(
                            title: "Payment Failed",
                            message: error,
                            actionTitle: "Try Again",
                            action: { processPayment() },
                            onDismiss: { errorMessage = nil }
                        )
                    }
                }
                .padding(DesignTokens.Spacing.card)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Pay Invoice")
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
                paymentButtonsFooter
            }
            .loadingOverlay(isLoading: isProcessing, message: "Processing payment...")
        }
        .sheet(isPresented: $showPDFPreview) {
            if let invoiceUrl = invoiceUrl, let url = URL(string: invoiceUrl) {
                DocumentPreviewModal(
                    documentTitle: "Invoice #\(invoiceId)",
                    pdfData: nil,
                    pdfURL: url,
                    isPresented: $showPDFPreview
                )
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 16) {
            // Invoice icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: "doc.text.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            }

            // Title and merchant
            VStack(alignment: .leading, spacing: 4) {
                Text("Invoice Payment")
                    .font(.title2.bold())
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Text(merchant)
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.Colors.textSubtle)
            }

            Spacer()
        }
    }

    // MARK: - Invoice Details Section

    private var invoiceDetailsSection: some View {
        ModalSectionView(title: "Invoice Details", background: .glass) {
            // Invoice ID - using shared CopyableField
            CopyableField(
                label: "Invoice ID",
                value: invoiceId,
                icon: "number.circle.fill",
                iconColor: .blue,
                style: .inline
            )

            Divider()
                .padding(.vertical, 4)

            // Amount Due - prominent display using CopyableField
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount Due")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text(amount)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.green)

                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }

            Divider()
                .padding(.vertical, 4)

            // Additional details using shared InfoRow
            if let dueDate = dueDate {
                InfoRow(
                    label: "Due Date",
                    value: dueDate,
                    icon: "calendar.circle.fill",
                    iconColor: .orange
                )
            }

            if let lateFee = lateFee {
                InfoRow(
                    label: "Late Fee",
                    value: lateFee,
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .red
                )
            }
        }
    }

    // MARK: - Payment Method Section

    private var paymentMethodSection: some View {
        ModalSectionView(title: "Payment Method", background: .glass) {
            VStack(spacing: 8) {
                ForEach(["Apple Pay", "Credit Card", "Bank Account"], id: \.self) { method in
                    Button {
                        selectedPaymentMethod = method
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } label: {
                        HStack(spacing: 12) {
                            // Icon
                            Image(systemName: paymentIcon(for: method))
                                .font(.title3)
                                .foregroundColor(selectedPaymentMethod == method ? .blue : .secondary)
                                .frame(width: 30)

                            // Method name
                            Text(method)
                                .font(.subheadline)
                                .foregroundColor(.primary)

                            Spacer()

                            // Selection indicator
                            if selectedPaymentMethod == method {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary.opacity(0.3))
                                    .font(.title3)
                            }
                        }
                        .padding(DesignTokens.Spacing.component)
                        .background(
                            selectedPaymentMethod == method ?
                            Color.blue.opacity(0.1) :
                            Color(.systemGray6).opacity(0.5)
                        )
                        .cornerRadius(DesignTokens.Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                .strokeBorder(
                                    selectedPaymentMethod == method ?
                                    Color.blue.opacity(0.5) :
                                    Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Payment Buttons Footer

    private var paymentButtonsFooter: some View {
        VStack(spacing: 12) {
            // Primary: Pay button
            Button {
                processPayment()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Pay \(amount)")
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
            .disabled(isProcessing)
            .opacity(isProcessing ? 0.5 : 1.0)

            // Secondary: Preview PDF
            if invoiceUrl != nil {
                Button {
                    showPDFPreview = true
                } label: {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("Preview Invoice PDF")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
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

    func paymentIcon(for method: String) -> String {
        switch method {
        case "Apple Pay": return "apple.logo"
        case "Credit Card": return "creditcard.fill"
        case "Bank Account": return "building.columns.fill"
        default: return "creditcard"
        }
    }

    // MARK: - Actions

    func processPayment() {
        // Validation
        guard !isProcessing else { return }

        isProcessing = true

        // Simulated payment processing (replace with real Stripe/payment SDK)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false

            // Simulate random success/failure for testing
            // TODO: In production, check payment gateway response
            let isSuccess = Bool.random() // Randomly succeed or fail for testing

            if isSuccess {
                showSuccess = true

                // Success haptic
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)

                Logger.info("Invoice paid: \(invoiceId), Amount: \(amount)", category: .action)

                // Analytics
                AnalyticsService.shared.log("invoice_paid", properties: [
                    "invoice_id": invoiceId,
                    "amount": amount,
                    "merchant": merchant,
                    "payment_method": selectedPaymentMethod,
                    "source": "pay_invoice_modal"
                ])

                // Auto-dismiss after success
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isPresented = false
                }
            } else {
                errorMessage = "Payment failed. Please try again or use a different payment method."

                // Error haptic
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.error)

                Logger.error("Payment failed for invoice: \(invoiceId)", category: .action)

                // Analytics
                AnalyticsService.shared.log("invoice_payment_failed", properties: [
                    "invoice_id": invoiceId,
                    "amount": amount,
                    "merchant": merchant,
                    "payment_method": selectedPaymentMethod
                ])
            }
        }
    }

    func openInvoiceUrl(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)

        Logger.info("Opening invoice URL", category: .action)

        AnalyticsService.shared.log("invoice_pdf_opened", properties: [
            "invoice_id": invoiceId,
            "merchant": merchant
        ])
    }
}

// MARK: - Preview

// Preview disabled - requires full EmailCard initialization
// #if DEBUG
// struct PayInvoiceModal_Previews: PreviewProvider {
//     static var previews: some View {
//         // Preview code here
//     }
// }
// #endif
