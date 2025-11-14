import SwiftUI

/**
 * CompoundActionFlow
 * Wizard-style modal for multi-step actions (e.g., Sign → Pay)
 * State machine tracks progress through compound action steps
 */

struct CompoundActionFlow: View {
    let card: EmailCard
    let steps: [String]  // Array of actionIds to execute in sequence
    let context: [String: String]
    let endBehavior: CompoundActionDefinition.CompoundEndBehavior?
    @Binding var isPresented: Bool

    @State private var currentStepIndex = 0
    @State private var completedSteps: Set<String> = []
    @State private var stepData: [String: Any] = [:]
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingEmailComposer = false
    
    private var currentStep: String {
        guard currentStepIndex < steps.count else {
            return ""
        }
        return steps[currentStepIndex]
    }
    
    private var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }
    
    private var progress: Double {
        Double(currentStepIndex + 1) / Double(steps.count)
    }

    /// Extract "Why" section from card summary
    private var whySection: String? {
        let sections = SummaryParser.parse(card.summary)
        return sections.first(where: { $0.title == "Why" })?.content
    }

    /// Extract sender name from card for signature pre-fill
    private var senderName: String {
        // Try to get full name from sender
        if let sender = card.sender, !sender.name.isEmpty {
            return sender.name
        }
        // Fallback to kid name if available
        if let kid = card.kid, !kid.name.isEmpty {
            return kid.name
        }
        // Last resort: extract from email or use generic
        return "Parent/Guardian"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Complete Action")
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        // Show Why section above pagination if available
                        if let why = whySection {
                            Text(why)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                                .padding(.top, 2)  // Reduced from 4 to 2 for tighter spacing
                        }

                        Text("Step \(currentStepIndex + 1) of \(steps.count)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 4)  // Reduced from 8 to 4 for tighter spacing
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
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green)
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.easeInOut, value: progress)
                    }
                }
                .frame(height: 8)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.15, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Step content
            ScrollView {
                VStack(spacing: 24) {
                    stepView(for: currentStep)
                }
                .padding()
            }
            .background(Color(white: 0.95))
            
            // Bottom action bar
            HStack(spacing: 16) {
                if currentStepIndex > 0 {
                    Button {
                        Logger.info("📱 Back button tapped", category: .app)
                        previousStep()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Button {
                    Logger.info("📱 \(isLastStep ? "Complete" : "Continue") button tapped - Current step: \(currentStep)", category: .app)
                    if isLastStep {
                        completeFlow()
                    } else {
                        nextStep()
                    }
                } label: {
                    HStack {
                        Text(isLastStep ? "Complete" : "Continue")
                        Image(systemName: isLastStep ? "checkmark" : "chevron.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color.white)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Step Views
    
    @ViewBuilder
    private func stepView(for stepId: String) -> some View {
        switch stepId {
        case "sign_form":
            SignFormStepView(
                card: card,
                context: context,
                senderName: senderName,
                onComplete: {
                    // Sign form step just confirms, no data needed
                }
            )

        case "pay_form_fee":
            PaymentStepView(
                card: card,
                context: context,
                senderName: senderName,
                onComplete: { paymentData in
                    stepData["payment"] = paymentData
                    // Signature is now captured in payment step
                    if let signature = paymentData["signature"] {
                        stepData["signature"] = signature
                    }
                }
            )
            
        case "add_to_calendar":
            CalendarStepView(
                card: card,
                context: context,
                onComplete: { event in
                    stepData["calendar"] = event
                }
            )
            
        default:
            GenericStepView(
                stepId: stepId,
                card: card,
                context: context
            )
        }
    }
    
    // MARK: - Navigation

    private func nextStep() {
        Logger.info("🔄 nextStep() called - validating step '\(currentStep)'", category: .app)
        guard validateCurrentStep() else {
            Logger.warning("⚠️ Validation failed for step '\(currentStep)'", category: .app)
            return
        }

        Logger.info("✅ Step '\(currentStep)' validated, moving to next", category: .app)
        completedSteps.insert(currentStep)

        withAnimation {
            currentStepIndex += 1
        }
        Logger.info("📍 Now at step \(currentStepIndex): '\(currentStep)'", category: .app)
    }

    private func previousStep() {
        guard currentStepIndex > 0 else { return }

        Logger.info("⬅️ Going back from step \(currentStepIndex)", category: .app)
        withAnimation {
            currentStepIndex -= 1
        }
        Logger.info("📍 Now at step \(currentStepIndex): '\(currentStep)'", category: .app)
    }
    
    private func completeFlow() {
        guard validateCurrentStep() else {
            return
        }

        completedSteps.insert(currentStep)

        // All steps completed - execute final action
        Logger.info("CompoundActionFlow completed all steps: \(steps)", category: .app)
        Logger.info("📦 Collected data: \(stepData.keys)", category: .app)

        // Handle end behavior based on CompoundActionRegistry definition
        if let endBehavior = endBehavior {
            switch endBehavior {
            case .emailComposer(let template):
                // Show email composer with pre-filled template
                Logger.info("Opening email composer with template", category: .app)
                showEmailComposer(template: template)

            case .dismissWithSuccess:
                // Show success message and dismiss
                Logger.info("Compound action completed - dismissing with success", category: .app)
                dismissWithSuccess()

            case .returnToApp:
                // Return to app without email composer
                Logger.info("Compound action completed - returning to app", category: .app)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isPresented = false
                }
            }
        } else {
            // No end behavior defined - default to dismiss
            Logger.warning("No end behavior defined for compound action, defaulting to dismiss", category: .app)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPresented = false
            }
        }
    }

    private func showEmailComposer(template: CompoundActionDefinition.EmailComposerTemplate) {
        // Prepare email composer with template
        // This will be handled by showing EmailComposerModal
        showingEmailComposer = true

        // Dismiss compound flow after email composer shown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }

    private func dismissWithSuccess() {
        // Show success animation/feedback
        HapticService.shared.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
    
    private func validateCurrentStep() -> Bool {
        // Validate step has required data
        switch currentStep {
        case "sign_form":
            // Sign form step just shows info, no validation needed
            return true
        case "pay_form_fee":
            // Payment step now includes signature confirmation
            if stepData["payment"] == nil {
                showError("Please complete payment information")
                return false
            }
            if stepData["signature"] == nil {
                showError("Please confirm your signature")
                return false
            }
            return true
        case "add_to_calendar":
            // Calendar step requires event data
            if stepData["calendar"] == nil {
                showError("Please select a date")
                return false
            }
            return true
        default:
            // Generic steps (dead-end features) always validate
            return true
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Step View Components

struct SignFormStepView: View {
    let card: EmailCard
    let context: [String: String]
    let senderName: String
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Step header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text("Review Form")
                        .font(.title2.bold())
                }

                Text(context["formName"] ?? "Permission form ready to sign")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            // Form preview/confirmation
            VStack(alignment: .leading, spacing: 16) {
                Text("Form Details")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 12) {
                    if let formName = context["formName"] {
                        FormDetailRow(label: "Form", value: formName)
                    }

                    if let eventDate = context["eventDate"] {
                        FormDetailRow(label: "Event Date", value: eventDate)
                    }

                    if let amount = context["amount"] {
                        FormDetailRow(label: "Fee", value: amount)
                    }

                    FormDetailRow(label: "Signature", value: "Will be signed as: \(senderName)")
                }

                Text("✓ Your signature will be added automatically on the next step")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.top, 8)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
        .onAppear {
            // Auto-complete this step since no input needed
            onComplete()
        }
    }
}

struct FormDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}

struct PaymentStepView: View {
    let card: EmailCard
    let context: [String: String]
    let senderName: String
    let onComplete: ([String: String]) -> Void

    @State private var selectedMethod = "venmo"
    @State private var paymentHandle = ""
    @State private var confirmedSignature = ""

    private var amount: String {
        context["amount"] ?? "$15.00"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Step header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("Payment & Signature")
                        .font(.title2.bold())
                }

                Text("Complete payment of \(amount) and confirm signature")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            // Signature confirmation section (moved from sign step)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "signature")
                        .foregroundColor(.blue)
                    Text("Confirm Signature")
                        .font(.headline)
                }

                Text("We detected your name from the email. Please confirm:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Full Name", text: $confirmedSignature)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .onAppear {
                        // Pre-fill with detected sender name
                        confirmedSignature = senderName
                    }
                    .onChange(of: confirmedSignature) { oldValue, newValue in
                        updateCompletion()
                    }

                if !confirmedSignature.isEmpty && confirmedSignature != senderName {
                    Text("✓ Signature confirmed as: \(confirmedSignature)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )

            // Payment method selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Payment Method")
                    .font(.headline)

                HStack(spacing: 12) {
                    PaymentMethodButton(
                        icon: "dollarsign.circle.fill",
                        name: "Venmo",
                        isSelected: selectedMethod == "venmo"
                    ) {
                        selectedMethod = "venmo"
                    }

                    PaymentMethodButton(
                        icon: "app.fill",
                        name: "Zelle",
                        isSelected: selectedMethod == "zelle"
                    ) {
                        selectedMethod = "zelle"
                    }

                    PaymentMethodButton(
                        icon: "applelogo",
                        name: "Apple Pay",
                        isSelected: selectedMethod == "apple_pay"
                    ) {
                        selectedMethod = "apple_pay"
                    }
                }

                TextField("\(selectedMethod.capitalized) username", text: $paymentHandle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .onChange(of: paymentHandle) { oldValue, newValue in
                        updateCompletion()
                    }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    private func updateCompletion() {
        // Only call onComplete when both signature and payment are filled
        guard !confirmedSignature.isEmpty, !paymentHandle.isEmpty else { return }

        onComplete([
            "method": selectedMethod,
            "handle": paymentHandle,
            "amount": amount,
            "signature": confirmedSignature  // Include confirmed signature
        ])
    }
}

struct PaymentMethodButton: View {
    let icon: String
    let name: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(name)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct CalendarStepView: View {
    let card: EmailCard
    let context: [String: String]
    let onComplete: ([String: String]) -> Void
    
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text("Add to Calendar")
                        .font(.title2.bold())
                }
                
                Text(context["eventTitle"] ?? "Add this event to your calendar")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            DatePicker("Event Date", selection: $selectedDate)
                .datePickerStyle(GraphicalDatePickerStyle())
                .onChange(of: selectedDate) { oldValue, newValue in
                    onComplete(["date": newValue.description])
                }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct GenericStepView: View {
    let stepId: String
    let card: EmailCard
    let context: [String: String]

    @AppStorage("deadEndUIMode") private var uiMode: DeadEndUIMode = .professional

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Mode toggle in top-right corner
            HStack {
                Spacer()
                Button {
                    withAnimation {
                        uiMode = uiMode == .professional ? .humorous : .professional
                    }
                    HapticService.shared.lightImpact()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: uiMode == .professional ? "face.smiling" : "briefcase")
                            .font(.caption)
                        Text(uiMode == .professional ? "Humor" : "Pro")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            if uiMode == .professional {
                professionalUI
            } else {
                humorousUI
            }

            // Request This Feature Button (shared)
            Button {
                requestFeature()
            } label: {
                HStack {
                    Image(systemName: "megaphone.fill")
                    Text("Request This Feature")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Professional UI

    private var professionalUI: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.title)
                    .foregroundColor(.orange)
                Text(stepId.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.title2.bold())
            }

            Text("This feature is under development")
                .font(.body)
                .foregroundColor(.secondary)

            // Progress indicator
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(.blue)
                    Text("Development in Progress")
                        .font(.subheadline.bold())
                }

                ProgressView(value: 0.45)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)

                Text("Estimated completion: Q2 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )

            Text("We're working hard to bring you this feature. Your feedback helps us prioritize development.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Humorous UI

    private var humorousUI: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "theatermasks.fill")
                    .font(.title)
                    .foregroundColor(.purple)
                Text(stepId.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.title2.bold())
            }

            Text(generateHumorousMessage())
                .font(.body)
                .foregroundColor(.secondary)
                .italic()

            // Humorous visual
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.1), .pink.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)

                VStack(spacing: 12) {
                    Image(systemName: "hammer.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.purple)

                    Text(generateEmoji())
                        .font(.system(size: 40))

                    Text(generateHumorousStatus())
                        .font(.caption.bold())
                        .foregroundColor(.purple)
                }
            }

            Text(generateContextualJoke())
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
        }
    }

    // MARK: - Humorous Content Generators

    private func generateHumorousMessage() -> String {
        let messages = [
            "Our engineers are currently teaching this feature how to tie its shoes. It's a work in progress.",
            "This feature is still in the oven. Good things take time (and a lot of coffee).",
            "We're building this faster than you can say 'when will it be ready?' Almost there!",
            "This action is currently on vacation. It'll be back soon with a tan and better functionality.",
            "Feature under construction: Please wear your hard hat while we finish hammering out the details."
        ]
        return messages.randomElement() ?? messages[0]
    }

    private func generateEmoji() -> String {
        let emojis = ["🔨", "🚧", "⚡️", "🛠", "⏳", "🎯"]
        return emojis.randomElement() ?? "🔨"
    }

    private func generateHumorousStatus() -> String {
        let statuses = [
            "Building with love ❤️",
            "Coding intensifies 💻",
            "Almost there! 🚀",
            "Brewing excellence ☕️",
            "Coming soon™"
        ]
        return statuses.randomElement() ?? "Under Construction"
    }

    private func generateContextualJoke() -> String {
        // Context-aware humor based on stepId
        switch stepId {
        case _ where stepId.contains("calendar"):
            return "⏰ We're trying to fit this feature into our calendar... ironically."
        case _ where stepId.contains("payment"), _ where stepId.contains("pay"):
            return "💰 This feature costs us sleep, not you money. Coming soon!"
        case _ where stepId.contains("email"), _ where stepId.contains("reply"):
            return "📧 We'd email you when it's done, but that would require this feature to work first."
        case _ where stepId.contains("reminder"):
            return "🔔 We'll remind you when we remember to finish building this."
        default:
            return "🎭 In the meantime, enjoy this witty placeholder message we spent 10 minutes crafting."
        }
    }

    // MARK: - Analytics

    private func requestFeature() {
        Logger.logUserAction("Dead-end feature requested", details: [
            "step_id": stepId,
            "card_intent": card.intent ?? "unknown",
            "ui_mode": uiMode.rawValue
        ])

        AnalyticsService.shared.log("dead_end_feature_requested", properties: [
            "step_id": stepId,
            "action_name": stepId.replacingOccurrences(of: "_", with: " ").capitalized,
            "card_intent": card.intent ?? "unknown",
            "card_archetype": card.type.rawValue,
            "ui_mode": uiMode.rawValue,
            "context_keys": context.keys.joined(separator: ",")
        ])

        HapticService.shared.success()

        // Show success toast (would integrate with toast system)
        Logger.info("✅ Feature request recorded: \(stepId)", category: .app)
    }
}

// MARK: - Dead-End UI Mode

enum DeadEndUIMode: String {
    case professional = "professional"
    case humorous = "humorous"
}

// MARK: - Preview

struct CompoundActionFlow_Previews: PreviewProvider {
    static var previews: some View {
        CompoundActionFlow(
            card: EmailCard(
                id: "1",
                type: .mail,
                state: .unseen,
                priority: .high,
                hpa: "Sign & Send",
                timeAgo: "2h ago",
                title: "Field Trip Permission",
                summary: "Please sign the permission form",
                body: nil,
                htmlBody: nil,
                metaCTA: "Swipe Right: Sign & Send",
                intent: "education.permission.form",
                intentConfidence: 0.95,
                suggestedActions: nil,
                sender: nil,
                kid: nil,
                company: nil,
                store: nil,
                airline: nil,
                productImageUrl: nil,
                brandName: nil,
                originalPrice: nil,
                salePrice: nil,
                discount: nil,
                urgent: nil,
                expiresIn: nil,
                requiresSignature: true,
                paymentAmount: nil,
                paymentDescription: nil,
                value: nil,
                probability: nil,
                score: nil
            ),
            steps: ["sign_form", "pay_form_fee"],
            context: [
                "formName": "Field Trip Permission Form",
                "amount": "$15.00"
            ],
            endBehavior: .emailComposer(template: CompoundActionDefinition.EmailComposerTemplate(
                subjectPrefix: "Re: Permission Form - Signed & Paid",
                bodyTemplate: "I've signed and completed payment.",
                includeOriginalSender: true
            )),
            isPresented: .constant(true)
        )
    }
}

