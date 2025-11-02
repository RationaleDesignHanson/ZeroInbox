import SwiftUI
import SafariServices

/**
 * PaymentPreviewModal
 * Shows payment details before opening payment link
 * Framework-compliant: Shows "evidence" (amount, merchant) before action
 */

struct PaymentPreviewModal: View {
    let card: EmailCard
    let amount: String
    let merchant: String
    let paymentUrl: String
    @Binding var isPresented: Bool
    
    @State private var showingSafari = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Details")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Review before paying")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.title2)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.green, Color.green.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Payment icon
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding()
                    
                    // Amount display (large)
                    VStack(spacing: 8) {
                        Text("Amount Due")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(amount.hasPrefix("$") ? amount : "$\(amount)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Payment details
                    VStack(spacing: 16) {
                        InfoRowPayment(label: "Pay To", value: merchant)
                        
                        if let invoiceId = card.suggestedActions?.first?.context?["invoiceId"] {
                            InfoRowPayment(label: "Invoice", value: invoiceId)
                        }
                        
                        if let dueDate = card.suggestedActions?.first?.context?["dueDate"] {
                            InfoRowPayment(label: "Due Date", value: dueDate)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Security notice
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Secure Payment")
                                .font(.subheadline.bold())
                            Text("You'll be redirected to a secure payment page")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            openPayment()
                        } label: {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                Text("Proceed to Payment")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button {
                            isPresented = false
                        } label: {
                            Text("Cancel")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .background(Color(white: 0.98))
        }
        .sheet(isPresented: $showingSafari) {
            if let url = URL(string: paymentUrl) {
                SafariView(url: url)
            }
        }
    }
    
    private func openPayment() {
        showingSafari = true
        HapticFeedback.light()
        
        // Auto-dismiss after opening Safari
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
}

struct InfoRowPayment: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body.bold())
                .foregroundColor(.primary)
        }
    }
}

