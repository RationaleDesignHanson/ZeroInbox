import SwiftUI

struct EmailComposerModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    var attachmentName: String? = nil
    var recipientOverride: String? = nil
    var subjectOverride: String? = nil
    
    @State private var message = ""
    @State private var showSent = false
    @State private var showDraftComposer = false

    // AI Draft generation state
    @State private var isGeneratingDraft = false
    @State private var selectedTone: DraftTone = .professional
    @State private var generatedDraft: EmailDraft? = nil
    @State private var showRegenerateButton = false

    var body: some View {
        VStack(spacing: 0) {
                // Custom header
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                            .font(.title2)
                    }
                }
                .padding()
                
                VStack(spacing: 0) {
                // Header with recipient
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
                    HStack {
                        Text("To:")
                            .font(.subheadline)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                        Text(recipientOverride ?? recipientName)
                            .font(.subheadline.bold())
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    
                    HStack {
                        Text("Re:")
                            .font(.subheadline)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                        Text(subjectOverride ?? card.title)
                            .font(.subheadline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .lineLimit(1)
                    }

                    // Attachment (if signed document)
                    if let attachment = attachmentName {
                        HStack(spacing: DesignTokens.Spacing.element) {
                            Image(systemName: "paperclip")
                                .font(.title3)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(attachment)
                                    .font(.subheadline.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                Text("Signed Document")
                                    .font(DesignTokens.Typography.labelMedium)
                                    .foregroundColor(DesignTokens.Colors.textFaded)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(DesignTokens.Colors.overlay10)
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                        .fill(DesignTokens.Materials.glassmorphic)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                .strokeBorder(DesignTokens.Colors.border, lineWidth: 1)
                        )
                )
                .padding(.horizontal)
                .padding(.top)
                
                // AI Draft controls - tone selector and generate button
                VStack(spacing: DesignTokens.Spacing.inline) {
                    HStack(spacing: DesignTokens.Spacing.element) {
                        // Tone chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignTokens.Spacing.inline) {
                                ForEach(DraftTone.allCases, id: \.self) { tone in
                                    Button {
                                        selectedTone = tone
                                        if showRegenerateButton {
                                            generateAIDraft()
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: tone.icon)
                                                .font(.system(size: 10))
                                            Text(tone.rawValue)
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            selectedTone == tone ?
                                                LinearGradient(
                                                    colors: [Color.purple.opacity(DesignTokens.Opacity.textDisabled), Color.blue.opacity(DesignTokens.Opacity.textDisabled)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ) :
                                                LinearGradient(
                                                    colors: [Color.white.opacity(DesignTokens.Opacity.glassLight), Color.white.opacity(DesignTokens.Opacity.glassLight)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                        )
                                        .cornerRadius(DesignTokens.Radius.card)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .strokeBorder(
                                                    selectedTone == tone ? Color.white.opacity(DesignTokens.Opacity.overlayMedium) : Color.white.opacity(DesignTokens.Opacity.glassLight),
                                                    lineWidth: 1
                                                )
                                        )
                                    }
                                }
                            }
                        }

                        Spacer()

                        // Generate/Regenerate button
                        Button {
                            generateAIDraft()
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.tight) {
                                if isGeneratingDraft {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: showRegenerateButton ? "arrow.clockwise" : "sparkles")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(showRegenerateButton ? "Regenerate" : "Draft with AI")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                            }
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .padding(.horizontal, DesignTokens.Spacing.element)
                            .padding(.vertical, DesignTokens.Spacing.tight)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.purple.opacity(DesignTokens.Opacity.textDisabled),
                                        Color.blue.opacity(DesignTokens.Opacity.textDisabled)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(DesignTokens.Radius.container)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                DesignTokens.Colors.borderStrong,
                                                DesignTokens.Colors.overlay10
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .disabled(isGeneratingDraft)
                    }
                }
                .padding(.horizontal)
                .padding(.top, DesignTokens.Spacing.component)
                .padding(.bottom, DesignTokens.Spacing.inline)
                
                // Message composer with glassmorphic style
                ZStack(alignment: .topLeading) {
                    if message.isEmpty {
                        if isGeneratingDraft {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(DesignTokens.Opacity.overlayStrong)))
                                    .scaleEffect(0.8)
                                Text("Generating \(selectedTone.rawValue.lowercased()) draft...")
                                    .foregroundColor(DesignTokens.Colors.textPlaceholder)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, DesignTokens.Spacing.section)
                            .padding(.top, DesignTokens.Spacing.card)
                        } else {
                            Text("Type your message or tap 'Draft with AI'...")
                                .foregroundColor(DesignTokens.Colors.textPlaceholder)
                                .padding(.horizontal, DesignTokens.Spacing.section)
                                .padding(.top, DesignTokens.Spacing.card)
                        }
                    }

                    TextEditor(text: $message)
                        .padding(DesignTokens.Spacing.component)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .disabled(isGeneratingDraft)
                }
                .frame(minHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                        .fill(DesignTokens.Materials.glassmorphic)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            DesignTokens.Colors.borderStrong,
                                            DesignTokens.Colors.overlay10
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .padding(.horizontal)
                
                Spacer()
                
                // Quick reply alternatives
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.element) {
                    Text("Quick Replies")
                        .font(DesignTokens.Typography.labelLarge)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .padding(.horizontal, DesignTokens.Spacing.card)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Spacing.element) {
                            ForEach(quickReplies, id: \.self) { reply in
                                Button {
                                    message = reply
                                } label: {
                                    Text(reply)
                                        .font(DesignTokens.Typography.labelMedium)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                        .padding(.horizontal, DesignTokens.Spacing.element)
                                        .padding(.vertical, DesignTokens.Spacing.inline)
                                        .background(
                                            RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                                .fill(DesignTokens.Materials.glassmorphic)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                                        .strokeBorder(DesignTokens.Colors.border, lineWidth: 1)
                                                )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.card)
                    }
                }
                .padding(.bottom)
                
                // Send button
                Button {
                    sendEmail()
                } label: {
                    HStack(spacing: DesignTokens.Spacing.inline) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: DesignTokens.Button.iconSize, weight: .semibold))
                        Text("Send")
                            .font(DesignTokens.Typography.headingSmall)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.Button.heightStandard)
                    .background(message.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .disabled(message.isEmpty)
                .padding()
                
                if showSent {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Email Sent!")
                            .foregroundColor(.green)
                    }
                    .font(.subheadline.bold())
                    .padding(.bottom)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.05, green: 0.05, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            // Pre-populate with AI response or template
            message = generateContextualResponse()
        }
    }
    
    var recipientName: String {
        card.sender?.name ?? card.company?.name ?? card.store ?? "Recipient"
    }
    
    var quickReplies: [String] {
        switch card.type {
        case .mail:
            return ["Thanks for letting me know!", "I'll take care of it.", "Confirmed - see you then!"]
        case .ads:
            return ["Thank you!", "I'll check this out!", "Saved for later!"]
        }
    }
    
    /// Generate contextual response based on action type and email content
    func generateContextualResponse() -> String {
        // Check if this is an RSVP action
        if let actionId = card.suggestedActions?.first?.actionId {
            // RSVP Yes
            if actionId == "rsvp_yes" || subjectOverride?.contains("RSVP") == true {
                let eventName = extractEventName(from: card.title)
                let eventDate = extractEventDate(from: card.summary)

                var rsvpMessage = "Hi,\n\nThank you for the invitation! "

                if !eventName.isEmpty {
                    rsvpMessage += "I'd love to attend \(eventName)"
                    if !eventDate.isEmpty {
                        rsvpMessage += " on \(eventDate)"
                    }
                    rsvpMessage += ".\n\n"
                } else {
                    rsvpMessage += "I will be attending.\n\n"
                }

                rsvpMessage += "Looking forward to it!\n\nBest regards"
                return rsvpMessage
            }

            // RSVP No
            if actionId == "rsvp_no" {
                let eventName = extractEventName(from: card.title)
                let eventDate = extractEventDate(from: card.summary)

                var rsvpMessage = "Hi,\n\nThank you for the invitation. "

                if !eventName.isEmpty {
                    rsvpMessage += "Unfortunately, I won't be able to attend \(eventName)"
                    if !eventDate.isEmpty {
                        rsvpMessage += " on \(eventDate)"
                    }
                    rsvpMessage += ".\n\n"
                } else {
                    rsvpMessage += "Unfortunately, I won't be able to attend.\n\n"
                }

                rsvpMessage += "I hope it goes well!\n\nBest regards"
                return rsvpMessage
            }
        }

        // Check subject line for RSVP indicators
        let title = card.title.lowercased()
        if title.contains("rsvp") || title.contains("invitation") || title.contains("invite") {
            let eventName = extractEventName(from: card.title)
            return "Hi,\n\nThank you for the invitation to \(eventName). I'll be there!\n\nLooking forward to it.\n\nBest regards"
        }

        // Fall back to existing AI response logic
        return generateAIResponse()
    }

    func generateAIResponse() -> String {
        // If this is a CRM forward to Steve
        if recipientOverride?.contains("Steve") == true {
            let companyName = card.company?.name ?? "this company"
            let value = card.value ?? "$50K"
            let probability = card.probability ?? 75
            return "Hi Steve,\n\nI wanted to forward this lead to you for follow-up in the CRM.\n\nLead Details:\n• Company: \(companyName)\n• Estimated Value: \(value)\n• Probability: \(probability)%\n• Source: \(card.title)\n\nThis looks like a strong opportunity. Can you reach out and get them scheduled for a demo?\n\nThanks!"
        }
        
        // If there's an attachment, prioritize that message with comprehensive details
        if attachmentName != nil {
            var emailBody = "Hi,\n\n"

            // Identify what type of form this is
            let formType = extractFormType(from: card.title)

            // Build comprehensive message with kid details
            if let kid = card.kid {
                emailBody += "I've signed and attached the \(formType) for \(kid.name) (\(kid.grade)).\n\n"

                // Add payment information if present
                if let amount = card.paymentAmount, let paymentDesc = card.paymentDescription {
                    emailBody += "Payment Details:\n• \(paymentDesc): $\(String(format: "%.2f", amount))\n• Payment will be processed via \(getPaymentMethod())\n\n"
                }

                // Add any deadline information
                if let deadline = extractDeadline(from: card.summary) {
                    emailBody += "I understand this is needed by \(deadline).\n\n"
                }

                // Add context from summary
                if !card.summary.isEmpty && !card.summary.contains("requires signed form") {
                    // Include relevant context from summary that isn't redundant
                    let contextualInfo = extractContextualInfo(from: card.summary)
                    if !contextualInfo.isEmpty {
                        emailBody += "\(contextualInfo)\n\n"
                    }
                }
            } else {
                // Fallback if no kid info
                emailBody += "I've signed and attached the \(formType).\n\n"

                if let amount = card.paymentAmount {
                    emailBody += "Payment of $\(String(format: "%.2f", amount)) will be processed as indicated.\n\n"
                }
            }

            emailBody += "Please let me know if you need anything else or have any questions.\n\nBest regards"

            return emailBody
        }
        
        // Generate contextual AI response based on card type and content
        switch card.type {
        case .mail:
            // All mail types: Family, kids, education, household, billing, sales, projects, professional, healthcare, learning, account security
            if card.title.contains("Permission") || card.requiresSignature == true {
                return "Hi \(card.kid?.name ?? "there"),\n\nThanks for sending this over. I've reviewed the permission form and everything looks good. I'll get the signature completed and returned by the deadline.\n\nBest regards"
            } else if card.title.contains("Assignment") {
                return "Thank you for the notification. I'll work with \(card.kid?.name ?? "my child") to ensure the assignment is completed and submitted on time.\n\nAppreciate the heads up!"
            } else if card.title.contains("Calendar") || card.title.contains("Fair") || card.title.contains("Event") {
                return "Thanks for the reminder! I've added this to my calendar and we'll plan to attend. Looking forward to it!"
            } else if card.hpa.contains("Schedule") || card.hpa.contains("Demo") {
                return "Hi \(recipientName),\n\nThanks for your interest! I'd love to schedule a meeting to discuss this further.\n\nI have availability this week:\n• Tuesday 2-4 PM\n• Wednesday 10 AM - 12 PM\n• Thursday 1-3 PM\n\nDoes any of these times work for you?\n\nBest regards"
            } else if card.hpa.contains("Approve") || card.hpa.contains("Review") {
                return "Reviewed and approved. Please proceed with implementation.\n\nLet me know if you need anything else."
            } else if card.priority == .critical {
                return "Thanks for the alert. I'm jumping on this now and will coordinate with the team to resolve ASAP.\n\nI'll keep you updated on progress."
            } else {
                return "Thank you for keeping me informed. I'll make sure to follow up on this.\n\nBest regards"
            }

        case .ads:
            // E-commerce, deals, packages, travel
            if card.hpa.contains("Check In") {
                return "Thanks for the reminder! Just completed check-in. See you soon!"
            } else if card.hpa.contains("Track") {
                return "Thanks for the update! I'll track the delivery and watch for its arrival."
            } else {
                return "Thank you! I'll check this out.\n\nBest regards"
            }
        }
    }
    
    func sendEmail() {
        showSent = true

        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPresented = false
        }
    }

    // MARK: - Helper Functions for Email Synthesis

    /// Extract form type from title (e.g., "Field Trip Permission Form" → "permission form")
    func extractFormType(from title: String) -> String {
        let lowerTitle = title.lowercased()

        // Check for specific form types
        if lowerTitle.contains("permission") && lowerTitle.contains("form") {
            return "permission form"
        } else if lowerTitle.contains("field trip") {
            return "field trip permission form"
        } else if lowerTitle.contains("yearbook") {
            return "yearbook order form"
        } else if lowerTitle.contains("registration") {
            return "registration form"
        } else if lowerTitle.contains("medical") || lowerTitle.contains("health") {
            return "medical/health form"
        } else if lowerTitle.contains("emergency") && lowerTitle.contains("contact") {
            return "emergency contact form"
        } else if lowerTitle.contains("consent") {
            return "consent form"
        } else if lowerTitle.contains("volunteer") {
            return "volunteer form"
        } else if lowerTitle.contains("form") {
            return "form"
        } else {
            return "document"
        }
    }

    /// Extract deadline from summary (e.g., "due Wednesday" → "Wednesday")
    func extractDeadline(from summary: String) -> String? {
        let lowerSummary = summary.lowercased()

        // Common deadline patterns
        let deadlinePatterns = [
            "due by ",
            "deadline: ",
            "by ",
            "before ",
            "needed by "
        ]

        for pattern in deadlinePatterns {
            if let range = lowerSummary.range(of: pattern) {
                let afterPattern = String(lowerSummary[range.upperBound...])

                // Extract next few words (likely the date)
                let words = afterPattern.split(separator: " ").prefix(3).joined(separator: " ")

                // Clean up common suffixes
                let cleaned = words.replacingOccurrences(of: "\\.", with: "")
                    .replacingOccurrences(of: ",", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if !cleaned.isEmpty {
                    return cleaned
                }
            }
        }

        // Look for day of week
        let daysOfWeek = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        for day in daysOfWeek {
            if lowerSummary.contains(day) {
                return day.capitalized
            }
        }

        return nil
    }

    /// Extract contextual information from summary (exclude redundant parts)
    func extractContextualInfo(from summary: String) -> String {
        var info = summary

        // Remove phrases that are redundant with what we've already said
        let redundantPhrases = [
            "requires signed form",
            "sign and return",
            "please sign",
            "signature required",
            "and $",
            "payment by"
        ]

        for phrase in redundantPhrases {
            info = info.replacingOccurrences(of: phrase, with: "", options: .caseInsensitive)
        }

        // Clean up extra spaces and punctuation
        info = info.replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // If what's left is meaningful (more than just a few words), include it
        if info.count > 20 && !info.isEmpty {
            // Make sure it starts with capital letter
            if let firstChar = info.first, firstChar.isLowercase {
                info = info.prefix(1).uppercased() + info.dropFirst()
            }
            return "Additional details: \(info)"
        }

        return ""
    }

    /// Get payment method string
    func getPaymentMethod() -> String {
        return "Apple Pay" // Could be made dynamic if payment method is tracked
    }

    /// Extract event name from title (e.g., "Team Happy Hour RSVP" → "Team Happy Hour")
    func extractEventName(from title: String) -> String {
        let eventName = title
            .replacingOccurrences(of: "RSVP", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Invitation", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Invite", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " - Please", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ":-"))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return eventName.isEmpty ? "the event" : eventName
    }

    /// Extract event date from summary
    func extractEventDate(from summary: String) -> String {
        // Look for common date patterns
        let datePatterns = [
            "on ",
            "date: ",
            "when: ",
            "time: "
        ]

        let lowerSummary = summary.lowercased()
        for pattern in datePatterns {
            if let range = lowerSummary.range(of: pattern) {
                let afterPattern = String(lowerSummary[range.upperBound...])
                let words = afterPattern.split(separator: " ").prefix(5).joined(separator: " ")

                if !words.isEmpty {
                    return words
                }
            }
        }

        // Look for days of week
        let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        for day in daysOfWeek {
            if summary.contains(day) {
                return day
            }
        }

        return ""
    }

    // MARK: - AI Draft Generation

    /// Generate AI draft inline using DraftComposerService
    func generateAIDraft() {
        isGeneratingDraft = true

        // Log feedback if regenerating
        if let draft = generatedDraft {
            DraftComposerService.shared.logFeedback(draft: draft, action: .regenerated)
        }

        // Haptic feedback
        HapticService.shared.lightImpact()

        Task {
            do {
                let context = EmailDraftContext(
                    emailId: card.id,
                    subject: subjectOverride ?? card.title,
                    senderName: recipientOverride ?? recipientName,
                    emailBody: card.body ?? card.summary,
                    threadHistory: nil,
                    userIntent: nil
                )

                let draft = try await DraftComposerService.shared.generateDraft(
                    emailContext: context,
                    tone: selectedTone
                )

                await MainActor.run {
                    generatedDraft = draft
                    message = draft.content
                    isGeneratingDraft = false
                    showRegenerateButton = true

                    // Success haptic
                    HapticService.shared.mediumImpact()

                    Logger.info("AI draft generated inline: \(selectedTone.rawValue), \(String(format: "%.2f", draft.latency))s", category: .email)
                }
            } catch {
                await MainActor.run {
                    isGeneratingDraft = false

                    // Error haptic
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)

                    Logger.error("Failed to generate AI draft: \(error.localizedDescription)", category: .email)

                    // Show error in message field temporarily
                    message = "Failed to generate draft. Please try again or type manually."
                }
            }
        }
    }
}

