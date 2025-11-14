import SwiftUI
import PassKit

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
    @State private var showError = false
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
            .padding(.top, DesignTokens.Spacing.card)  // Ensure header clears sheet top rounded corner
            .padding(.horizontal)
            .padding(.bottom, DesignTokens.Spacing.inline)

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.largeTitle)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Invoice")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Text(merchant)
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Invoice details
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                        Text("Invoice Details")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        DetailRow(
                            icon: "number.circle.fill",
                            label: "Invoice ID",
                            value: invoiceId,
                            color: .blue
                        )

                        DetailRow(
                            icon: "dollarsign.circle.fill",
                            label: "Amount Due",
                            value: amount,
                            color: .green
                        )

                        if let dueDate = dueDate {
                            DetailRow(
                                icon: "calendar.circle.fill",
                                label: "Due Date",
                                value: dueDate,
                                color: .orange
                            )
                        }

                        if let lateFee = lateFee {
                            DetailRow(
                                icon: "exclamationmark.triangle.fill",
                                label: "Late Fee",
                                value: lateFee,
                                color: .red
                            )
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Payment method selection
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                        Text("Payment Method")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        ForEach(["Apple Pay", "Credit Card", "Bank Account"], id: \.self) { method in
                            Button {
                                selectedPaymentMethod = method
                            } label: {
                                HStack {
                                    Image(systemName: paymentIcon(for: method))
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    Text(method)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    Spacer()
                                    if selectedPaymentMethod == method {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(selectedPaymentMethod == method ? 0.2 : 0.1))
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                        }
                    }

                    // Action buttons
                    VStack(spacing: DesignTokens.Spacing.component) {
                        Button {
                            processPayment()
                        } label: {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Pay \(amount)")
                                }
                            }
                        }
                        .buttonStyle(GradientButtonStyle(colors: [.vibrantGreen, .vibrantEmerald]))
                        .disabled(isProcessing)
                        .opacity(isProcessing ? 0.5 : 1.0)

                        if invoiceUrl != nil {
                            Button {
                                showPDFPreview = true
                            } label: {
                                HStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                    Text("Preview Invoice PDF")
                                }
                            }
                            .buttonStyle(.gradientPrimary)
                        }

                        if showSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Payment successful!")
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

    func paymentIcon(for method: String) -> String {
        switch method {
        case "Apple Pay": return "apple.logo"
        case "Credit Card": return "creditcard.fill"
        case "Bank Account": return "building.columns.fill"
        default: return "creditcard"
        }
    }

    func processPayment() {
        isProcessing = true

        // Simulated payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
            showSuccess = true

            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

            Logger.info("Invoice paid: \(invoiceId), Amount: \(amount)", category: .action)

            // Analytics
            AnalyticsService.shared.log("invoice_paid", properties: [
                "invoice_id": invoiceId,
                "amount": amount,
                "merchant": merchant,
                "payment_method": selectedPaymentMethod
            ])

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isPresented = false
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
