import SwiftUI
import MessageUI

struct SendMessageModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var messageOpportunity: MessageOpportunity?
    @State private var selectedNumber: String = ""
    @State private var messageBody: String = ""
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
                            Image(systemName: "message.fill")
                                .font(.title)
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(messageOpportunity?.reason ?? "Send Message")
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

                    // Phone number selection
                    if let opportunity = messageOpportunity {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Recipient")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            ForEach(opportunity.phoneNumbers, id: \.self) { number in
                                Button {
                                    selectedNumber = number
                                } label: {
                                    HStack {
                                        Image(systemName: "phone.fill")
                                            .foregroundColor(.green)

                                        VStack(alignment: .leading, spacing: 2) {
                                            if let name = opportunity.recipientName {
                                                Text(name)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                            }
                                            Text(formatPhoneNumber(number))
                                                .font(.caption)
                                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                        }

                                        Spacer()

                                        if selectedNumber == number {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding()
                                    .background(selectedNumber == number ? Color.green.opacity(DesignTokens.Opacity.overlayLight) : Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                                    .cornerRadius(DesignTokens.Radius.button)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                            .strokeBorder(selectedNumber == number ? Color.green : Color.white.opacity(DesignTokens.Opacity.glassLight), lineWidth: selectedNumber == number ? 2 : 1)
                                    )
                                }
                            }
                        }
                    }

                    // Message body
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Message")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        TextEditor(text: $messageBody)
                            .frame(height: 120)
                            .padding()
                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Radius.button)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .colorScheme(.dark)
                            .scrollContentBackground(.hidden)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                            )

                        // Character count
                        Text("\(messageBody.count) characters")
                            .font(.caption2)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    // Quick message suggestions
                    if let suggestions = getMessageSuggestions() {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick Messages")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            ForEach(suggestions, id: \.self) { suggestion in
                                Button {
                                    messageBody = suggestion
                                } label: {
                                    HStack {
                                        Image(systemName: "text.bubble")
                                            .foregroundColor(.blue)
                                            .font(.caption)

                                        Text(suggestion)
                                            .font(.caption)
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                            .lineLimit(2)
                                    }
                                    .padding(.horizontal, DesignTokens.Spacing.component)
                                    .padding(.vertical, DesignTokens.Spacing.inline)
                                    .background(Color.blue.opacity(DesignTokens.Opacity.overlayLight))
                                    .cornerRadius(DesignTokens.Radius.chip)
                                }
                            }
                        }
                    }

                    // Send Message button
                    Button {
                        sendMessage()
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Message")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((selectedNumber.isEmpty || messageBody.isEmpty) ? Color.gray : Color.green)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                    .disabled(selectedNumber.isEmpty || messageBody.isEmpty || !MessagesService.canSendMessages())

                    // Device capability warning
                    if !MessagesService.canSendMessages() {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("This device cannot send text messages. Make sure you have an active cellular plan or iMessage configured.")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(DesignTokens.Opacity.overlayLight))
                        .cornerRadius(DesignTokens.Radius.chip)
                    }

                    // Success message
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Message sent!")
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
        .onAppear {
            detectMessageOpportunity()
        }
    }

    func detectMessageOpportunity() {
        messageOpportunity = MessagesService.shared.detectMessageOpportunity(in: card)

        // Set default message body
        if let suggestedMessage = messageOpportunity?.suggestedMessage {
            messageBody = suggestedMessage
        }

        // Auto-select number if only one
        if let numbers = messageOpportunity?.phoneNumbers, numbers.count == 1 {
            selectedNumber = numbers[0]
        }
    }

    func getMessageSuggestions() -> [String]? {
        let text = "\(card.title) \(card.summary)".lowercased()

        var suggestions: [String] = []

        if text.contains("driver") || text.contains("delivery") {
            suggestions = [
                "Hi! I'm here for pickup. Thanks!",
                "Hi! Running 5 minutes late. Be there soon!",
                "Hi! I'm checking on my delivery status. Thanks!"
            ]
        } else if text.contains("rsvp") {
            suggestions = [
                "Yes, we'll be there!",
                "Unfortunately we can't make it.",
                "Can you send me more details?"
            ]
        } else if text.contains("confirm") {
            suggestions = [
                "Yes, confirmed!",
                "Confirmed for tomorrow. Thanks!",
                "I need to reschedule. Can we find another time?"
            ]
        }

        return suggestions.isEmpty ? nil : suggestions
    }

    func formatPhoneNumber(_ number: String) -> String {
        // Remove all non-digit characters
        let digits = number.filter { $0.isNumber }

        // Format as (XXX) XXX-XXXX for US numbers
        if digits.count == 10 {
            let areaCode = digits.prefix(3)
            let prefix = digits.dropFirst(3).prefix(3)
            let lineNumber = digits.dropFirst(6)
            return "(\(areaCode)) \(prefix)-\(lineNumber)"
        } else if digits.count == 11 && digits.first == "1" {
            let areaCode = digits.dropFirst().prefix(3)
            let prefix = digits.dropFirst(4).prefix(3)
            let lineNumber = digits.dropFirst(7)
            return "+1 (\(areaCode)) \(prefix)-\(lineNumber)"
        }

        return number
    }

    func sendMessage() {
        showError = false
        showSuccess = false

        // Get root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            showError = true
            errorMessage = "Could not present message composer"
            return
        }

        MessagesService.shared.sendMessage(
            to: [selectedNumber],
            body: messageBody,
            presentingViewController: rootVC
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    showSuccess = true
                    Logger.info("Message sent successfully", category: .action)

                    // Haptic feedback
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)

                    // Auto-dismiss after success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isPresented = false
                    }

                case .failure(let error):
                    // Only show error if it's not cancellation
                    if case MessagesError.cancelled = error {
                        // User cancelled, just log it
                        Logger.info("Message cancelled by user", category: .action)
                    } else {
                        showError = true
                        errorMessage = error.localizedDescription
                        Logger.error("Failed to send message: \(error.localizedDescription)", category: .action)

                        // Haptic feedback
                        let impact = UINotificationFeedbackGenerator()
                        impact.notificationOccurred(.error)
                    }
                }
            }
        }
    }
}
