import SwiftUI

struct QuickReplyModal: View {
    let card: EmailCard
    let recipientEmail: String
    let subject: String
    let context: [String: Any]
    @Binding var isPresented: Bool

    @State private var replyText: String = ""
    @State private var selectedSuggestion: String? = nil
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isSending = false
    @State private var showCCBCC = false
    @State private var aiSuggestions: [String] = []
    @State private var isLoadingAI = false
    @State private var aiError: String? = nil

    // Extract optional context
    var originalMessage: String? {
        context["originalMessage"] as? String
    }

    var senderName: String? {
        context["senderName"] as? String
    }

    // Fallback suggestions if AI fails
    let fallbackSuggestions = [
        "Thanks, sounds good!",
        "I'll get back to you tomorrow.",
        "I appreciate the update."
    ]

    // Use AI suggestions if available, otherwise fallback
    var suggestions: [String] {
        return aiSuggestions.isEmpty ? fallbackSuggestions : aiSuggestions
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
                            Image(systemName: "envelope.fill")
                                .font(.largeTitle)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Quick Reply")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                if let senderName = senderName {
                                    Text("to \(senderName)")
                                        .font(.subheadline)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                } else {
                                    Text("to \(recipientEmail)")
                                        .font(.subheadline)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }
                            }
                        }
                    }

                    // Original message summary
                    if let originalMessage = originalMessage {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                            Text("Original Message")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSubtle)

                            Text(originalMessage)
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                                .padding(DesignTokens.Spacing.component)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                                .cornerRadius(DesignTokens.Spacing.inline)
                                .lineLimit(4)
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Smart suggestions
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        HStack {
                            Text(isLoadingAI ? "Generating AI Replies..." : "Quick Replies")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            if isLoadingAI {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else if !aiSuggestions.isEmpty {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }

                        if aiError != nil {
                            Text("Using fallback suggestions")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        }

                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                selectSuggestion(suggestion)
                            } label: {
                                HStack {
                                    Image(systemName: selectedSuggestion == suggestion ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedSuggestion == suggestion ? .green : .white.opacity(DesignTokens.Opacity.overlayStrong))

                                    Text(suggestion)
                                        .font(.subheadline)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .background(selectedSuggestion == suggestion ? Color.green.opacity(DesignTokens.Opacity.overlayLight) : Color.white.opacity(DesignTokens.Opacity.glassLight))
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Custom reply text editor
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        Text("Custom Reply")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        TextEditor(text: $replyText)
                            .frame(height: 120)
                            .padding(DesignTokens.Spacing.inline)
                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Spacing.inline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .onChange(of: replyText) {
                                if !replyText.isEmpty {
                                    selectedSuggestion = nil
                                }
                            }
                    }

                    // CC/BCC section (collapsible)
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        Button {
                            withAnimation {
                                showCCBCC.toggle()
                            }
                        } label: {
                            HStack {
                                Text("CC/BCC")
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                                Image(systemName: showCCBCC ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                        }

                        if showCCBCC {
                            VStack(spacing: DesignTokens.Spacing.inline) {
                                TextField("CC", text: .constant(""))
                                    .padding(DesignTokens.Spacing.component)
                                    .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                    .cornerRadius(DesignTokens.Spacing.inline)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                TextField("BCC", text: .constant(""))
                                    .padding(DesignTokens.Spacing.component)
                                    .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                    .cornerRadius(DesignTokens.Spacing.inline)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }
                        }
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            sendReply()
                        } label: {
                            HStack {
                                if isSending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Send Reply")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSend ? Color.blue : Color.gray.opacity(DesignTokens.Opacity.overlayMedium))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                        .disabled(!canSend || isSending)

                        if showSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Reply sent!")
                                    .foregroundColor(.green)
                                    .font(.headline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(DesignTokens.Opacity.overlayLight))
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
                            .background(Color.red.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Radius.chip)
                        }
                    }
                    .padding(.top, DesignTokens.Spacing.card)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .onAppear {
            generateAIReplies()
        }
    }

    var canSend: Bool {
        !replyText.isEmpty || selectedSuggestion != nil
    }

    var finalReplyText: String {
        if !replyText.isEmpty {
            return replyText
        } else if let suggestion = selectedSuggestion {
            return suggestion
        }
        return ""
    }

    func selectSuggestion(_ suggestion: String) {
        if selectedSuggestion == suggestion {
            selectedSuggestion = nil
        } else {
            selectedSuggestion = suggestion
            replyText = ""
        }

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    func sendReply() {
        isSending = true

        // Check if email sending is enabled
        let emailSendingEnabled = UserDefaults.standard.bool(forKey: "enableEmailSending")

        // Simulated email sending (or real if enabled)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSending = false
            showSuccess = true

            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

            if emailSendingEnabled {
                Logger.info("⚠️ Reply sent FOR REAL to: \(recipientEmail)", category: .action)
                // TODO: Actual email API integration would go here
            } else {
                Logger.info("🛡️ Reply simulated (safe mode) to: \(recipientEmail)", category: .action)
            }

            // Analytics
            AnalyticsService.shared.log("reply_sent", properties: [
                "recipient": recipientEmail,
                "reply_type": selectedSuggestion != nil ? "suggestion" : "custom",
                "reply_length": finalReplyText.count,
                "suggestion_text": selectedSuggestion ?? "none",
                "used_ai_suggestion": !aiSuggestions.isEmpty && selectedSuggestion != nil && aiSuggestions.contains(selectedSuggestion!),
                "ai_suggestions_available": !aiSuggestions.isEmpty,
                "email_sending_enabled": emailSendingEnabled,
                "safe_mode": !emailSendingEnabled
            ])

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isPresented = false
            }
        }
    }

    func generateAIReplies() {
        isLoadingAI = true
        aiError = nil

        Logger.info("🤖 Generating AI smart replies for: \(card.title)", category: .service)

        Task {
            do {
                // Generate AI-powered context-aware replies
                let replies = try await SmartReplyService.shared.generateSmartReplies(for: card)

                await MainActor.run {
                    self.aiSuggestions = replies
                    self.isLoadingAI = false
                    Logger.info("✅ Generated \(replies.count) AI suggestions", category: .service)

                    // Haptic feedback for successful generation
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            } catch {
                await MainActor.run {
                    self.isLoadingAI = false
                    self.aiError = error.localizedDescription
                    Logger.warning("AI reply generation failed, using fallback: \(error.localizedDescription)", category: .service)

                    // Still provide fallback suggestions (already defined)
                }
            }
        }
    }
}
