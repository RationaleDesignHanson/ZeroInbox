import SwiftUI

/**
 * ActionOptionsModal v1.1
 * Dynamic action menu based on card.suggestedActions (Action-First Model)
 * Falls back to static archetype-based actions if suggestedActions not available
 */

struct ActionOptionsModalV1_1: View {
    let card: EmailCard
    let currentAction: String
    let viewModel: EmailViewModel
    @Binding var isPresented: Bool
    let onActionSelected: (String) -> Void

    @State private var selectedAction: String?
    @StateObject private var actionRouter = ActionRouter.shared
    
    // Dynamic action options from v1.1 model
    var dynamicActionOptions: [(id: String, label: String, description: String, icon: String)] {
        guard let suggestedActions = card.suggestedActions, !suggestedActions.isEmpty else {
            // Fallback to legacy static actions
            return legacyActionOptions
        }
        
        Logger.info("Using dynamic actions from suggestedActions: \(suggestedActions.count) actions", category: .action)
        
        return suggestedActions.map { action in
            (
                id: action.actionId,
                label: action.displayName,
                description: actionDescription(for: action),
                icon: actionIcon(for: action)
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose Action")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text(card.intent != nil ? "Smart actions for this email" : "Select your preferred action")
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
            
            // Show intent badge if available (v1.1)
            if let intent = card.intent, let confidence = card.intentConfidence {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("Detected: \(intentDisplayName(intent))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    Text("\(Int(confidence * 100))% confidence")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Action options
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(dynamicActionOptions, id: \.id) { option in
                        ActionOptionRow(
                            option: option,
                            isSelected: selectedAction == option.id,
                            isPrimary: isPrimaryAction(option.id)
                        ) {
                            handleActionSelection(option.id)
                        }
                    }
                }
                .padding()
            }
        }
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
    }
    
    // MARK: - Action Handling
    
    private func handleActionSelection(_ actionId: String) {
        selectedAction = actionId

        // Find the action from suggestedActions
        if let suggestedActions = card.suggestedActions,
           let action = suggestedActions.first(where: { $0.actionId == actionId }) {

            Logger.info("Executing dynamic action: \(action.displayName)", category: .action)

            // IMPORTANT: Save as custom action so it shows on card and persists for future use
            viewModel.setCustomAction(for: card.id, action: actionId)
            Logger.info("✅ Saved custom action: \(actionId) for card: \(card.id)", category: .action)

            // Dismiss modal first for smoother transition
            isPresented = false

            // Execute after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // When user explicitly selects an action from the menu,
                // execute ONLY that action (bypass compound flow)
                // This allows users to pick individual actions like "Pay Fee"
                // without executing the full "Sign, Pay, Email" compound sequence
                actionRouter.executeAction(action, card: card)
            }
        } else {
            // Fallback to legacy action handling
            Logger.info("Falling back to legacy action handling for: \(actionId)", category: .action)
            onActionSelected(actionId)
            
            // Dismiss after short delay for visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPresented = false
            }
        }
    }
    
    private func isPrimaryAction(_ actionId: String) -> Bool {
        guard let suggestedActions = card.suggestedActions else {
            return false
        }
        return suggestedActions.first(where: { $0.actionId == actionId })?.isPrimary ?? false
    }
    
    // MARK: - UI Helpers
    
    private func actionDescription(for action: EmailAction) -> String {
        // Generate description based on action type and context
        switch action.actionId {
        case "track_package":
            if let carrier = action.context?["carrier"] {
                return "Track with \(carrier)"
            }
            return "Track package delivery"
        case "pay_invoice":
            if let amount = action.context?["amount"] {
                return "Pay \(amount)"
            }
            return "Complete payment"
        case "join_meeting":
            if let platform = action.context?["platform"] {
                return "Join \(platform) meeting"
            }
            return "Join video meeting"
        case "sign_form":
            return "Sign and send form"
        case "check_in_flight":
            if let flightNumber = action.context?["flightNumber"] {
                return "Check in for flight \(flightNumber)"
            }
            return "Complete flight check-in"
        case "add_to_calendar":
            return "Add event to calendar"
        case "view_assignment":
            return "View assignment details"
        case "write_review":
            if let productName = action.context?["productName"] {
                return "Review \(productName)"
            }
            return "Write product review"
        case "claim_deal":
            return "Claim promotional offer"
        case "verify_account":
            return "Verify your account"
        default:
            return actionTypeDescription(action.actionType)
        }
    }
    
    private func actionIcon(for action: EmailAction) -> String {
        // Map actionId to appropriate SF Symbol
        switch action.actionId {
        case "track_package": return "shippingbox.fill"
        case "view_order": return "doc.text"
        case "pay_invoice": return "creditcard.fill"
        case "download_receipt": return "arrow.down.doc"
        case "join_meeting": return "video.fill"
        case "add_to_calendar": return "calendar.badge.plus"
        case "rsvp_yes": return "checkmark.circle.fill"
        case "rsvp_no": return "xmark.circle.fill"
        case "sign_form": return "signature"
        case "check_in_flight": return "airplane.departure"
        case "view_itinerary": return "map"
        case "reset_password": return "lock.rotation"
        case "verify_account": return "checkmark.shield"
        case "write_review": return "star.fill"
        case "claim_deal": return "tag.fill"
        case "view_assignment": return "doc.text.magnifyingglass"
        case "quick_reply": return "arrowshape.turn.up.left.fill"
        case "save_for_later": return "clock"
        case "view_details": return "doc.plaintext"
        default: return action.actionType == .goTo ? "arrow.up.forward.app" : "app.badge"
        }
    }
    
    private func actionTypeDescription(_ type: ActionType) -> String {
        switch type {
        case .goTo: return "Opens in browser or app"
        case .inApp: return "Complete action in app"
        }
    }
    
    private func intentDisplayName(_ intent: String) -> String {
        let parts = intent.split(separator: ".")
        guard parts.count >= 2 else { return intent }
        
        // Format: "category.subcategory.action" → "Subcategory Action"
        let subcategory = parts[1].capitalized.replacingOccurrences(of: "_", with: " ")
        let action = parts.count > 2 ? parts[2].capitalized.replacingOccurrences(of: "_", with: " ") : ""
        
        return action.isEmpty ? subcategory : "\(subcategory) \(action)"
    }
    
    // MARK: - Legacy Fallback
    
    /// Legacy static action options (fallback when no suggestedActions)
    var legacyActionOptions: [(id: String, label: String, description: String, icon: String)] {
        Logger.info("Using fallback static actions for archetype: \(card.type)", category: .action)

        // Binary classification: mail or ads
        switch card.type {
        case .mail:
            // All non-promotional emails
            var options: [(id: String, label: String, description: String, icon: String)] = []
            if card.requiresSignature == true {
                options.append(("sign_send", "Sign & Send", "Auto-fill form and send reply", "signature"))
            }
            options.append(("acknowledge", "Acknowledge", "Send confirmation reply", "checkmark.message"))
            options.append(("save_later", "Save for Later", "Snooze until specified time", "clock"))
            return options

        case .ads:
            // Marketing, promotions, newsletters
            return [
                ("claim_deal", "Claim Deal", "Open store page with deal applied", "bag.fill"),
                ("save_deal", "Save Deal", "Bookmark for later purchase", "bookmark"),
                ("check_in", "Check In", "Complete check-in process", "checkmark.square")
            ]
        }
    }
}

// MARK: - Action Option Row

struct ActionOptionRow: View {
    let option: (id: String, label: String, description: String, icon: String)
    let isSelected: Bool
    let isPrimary: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: option.icon)
                    .font(.title2)
                    .foregroundColor(isPrimary ? .yellow : .white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isPrimary ? Color.yellow.opacity(0.2) : Color.white.opacity(0.1))
                    )
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(option.label)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if isPrimary {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(option.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Chevron or checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundColor(isSelected ? .green : .white.opacity(0.5))
                    .font(.system(size: 18))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPrimary ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    // Create standalone EmailViewModel for preview
    let viewModel = EmailViewModel(
        userPreferences: UserPreferencesService(),
        appState: AppStateManager(),
        cardManagement: CardManagementService()
    )

    ActionOptionsModalV1_1(
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
            suggestedActions: [
                EmailAction(
                    actionId: "sign_form",
                    displayName: "Sign & Send",
                    actionType: .inApp,
                    isPrimary: true,
                    priority: 1,
                    context: ["formName": "Field Trip Permission"],
                    isCompound: true,
                    compoundSteps: ["sign_form", "pay_form_fee"]
                ),
                EmailAction(
                    actionId: "add_to_calendar",
                    displayName: "Add to Calendar",
                    actionType: .inApp,
                    isPrimary: false,
                    priority: 2,
                    context: ["eventDate": "Oct 25"],
                    isCompound: nil,
                    compoundSteps: nil
                )
            ],
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
        currentAction: "",
        viewModel: viewModel,
        isPresented: .constant(true),
        onActionSelected: { _ in }
    )
}

