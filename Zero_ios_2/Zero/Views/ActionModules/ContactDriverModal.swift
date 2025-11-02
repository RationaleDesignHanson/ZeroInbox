import SwiftUI
import MessageUI

struct ContactDriverModal: View {
    let card: EmailCard
    let driverInfo: [String: Any]
    @Binding var isPresented: Bool

    @State private var message = ""
    @State private var showSuccess = false
    @State private var showMessageComposer = false
    @State private var errorMessage: String?
    @State private var showError = false

    // Extract driver details from context
    var driverName: String {
        (driverInfo["driverName"] as? String) ?? "Your driver"
    }

    var driverPhone: String? {
        driverInfo["driverPhone"] as? String
    }

    var estimatedArrival: String {
        (driverInfo["estimatedArrival"] as? String) ?? "Soon"
    }

    var trackingNumber: String? {
        driverInfo["trackingNumber"] as? String
    }

    var quickMessages: [String] {
        [
            "Running late, please wait 5 minutes",
            "Please leave at front door",
            "Please ring doorbell",
            "Where should I meet you?"
        ]
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
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(driverName)
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Text("Arriving \(estimatedArrival)")
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                        }

                        if let trackingNumber = trackingNumber {
                            Text("Order: \(trackingNumber)")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Quick messages
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        Text("Quick Messages")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        ForEach(quickMessages, id: \.self) { quickMsg in
                            Button {
                                message = quickMsg
                                sendMessage()
                            } label: {
                                HStack {
                                    Image(systemName: "message.fill")
                                        .foregroundColor(.blue)
                                    Text(quickMsg)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                        .font(.subheadline)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                        }
                    }

                    // Custom message
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                        Text("Custom Message")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        TextEditor(text: $message)
                            .frame(height: 100)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(DesignTokens.Radius.button)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .colorScheme(.dark)
                            .scrollContentBackground(.hidden)
                    }

                    // Action buttons
                    VStack(spacing: DesignTokens.Spacing.component) {
                        Button {
                            sendMessage()
                        } label: {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("Send Message")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(message.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                        .disabled(message.isEmpty)

                        if let phone = driverPhone {
                            Button {
                                callDriver(phone: phone)
                            } label: {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text("Call Driver")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                        }

                        if showSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Message sent!")
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
                            .cornerRadius(DesignTokens.Radius.chip)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
    }

    func sendMessage() {
        // In production, this would integrate with delivery service API
        // For now, show success message
        withAnimation {
            showSuccess = true
        }

        Logger.info("Message sent to driver: \(message)", category: .action)

        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        // Analytics
        AnalyticsService.shared.log("driver_contacted", properties: [
            "driver_name": driverName,
            "message_length": message.count,
            "is_quick_message": quickMessages.contains(message)
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isPresented = false
        }
    }

    func callDriver(phone: String) {
        let cleanedPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        if let phoneURL = URL(string: "tel://\(cleanedPhone)") {
            if UIApplication.shared.canOpenURL(phoneURL) {
                UIApplication.shared.open(phoneURL)
                Logger.info("Calling driver: \(phone)", category: .action)

                // Analytics
                AnalyticsService.shared.log("driver_called", properties: [
                    "driver_name": driverName
                ])

                isPresented = false
            } else {
                errorMessage = "Unable to make phone calls on this device"
                showError = true
            }
        } else {
            errorMessage = "Invalid phone number"
            showError = true
        }
    }
}
