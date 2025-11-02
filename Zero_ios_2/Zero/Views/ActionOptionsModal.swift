import SwiftUI

struct ActionOptionsModal: View {
    let card: EmailCard
    let currentAction: String
    let viewModel: EmailViewModel
    @Binding var isPresented: Bool
    let onActionSelected: (String) -> Void

    @State private var selectedAction: String?
    @State private var showCompoundWarning = false
    @State private var pendingAction: String?

    var actionOptions: [(id: String, label: String, description: String, icon: String)] {
        let _ = Logger.info("actionOptions computed property called for card type: \(card.type)", category: .action)
        let modern = card.type
        switch modern {
        case .mail:
            var options: [(id: String, label: String, description: String, icon: String)] = []

            // Only show "Open App" if email contains a deep link
            if shouldShowOpenAppAction(for: card) {
                options.append(("open_app", "Open in App", "Launch app to complete action", "app.badge"))
            }

            // Only show "Sign & Send" if email requires a signature
            if card.requiresSignature == true {
                options.append(("sign_send", "Sign & Send", "Auto-fill form and send reply", "signature"))
            }

            // Only show "Add to Calendar" if there's an event-related keyword
            if shouldShowCalendarAction(for: card) {
                options.append(("schedule", "Add to Calendar", "Create calendar event", "calendar.badge.plus"))
            }

            // Always show acknowledge (generic reply)
            options.append(("acknowledge", "Acknowledge", "Send confirmation reply", "checkmark.message"))

            // Always show save/archive
            options.append(("save_later", "Save for Later", "Snooze until specified time", "clock"))
            options.append(("archive", "Archive", "Mark as read and file", "archivebox"))

            let _ = Logger.info("personal options count: \(options.count) (filtered)", category: .action)
            return options
        case .ads:
            return [
                ("claim_deal", "Claim Deal", "Open store page with deal applied", "bag.fill"),
                ("save_deal", "Save Deal", "Bookmark for later purchase", "bookmark"),
                ("not_interested", "Not Interested", "Dismiss and unsubscribe", "xmark.circle"),
                ("compare", "Compare Prices", "Check other retailers", "chart.bar.xaxis")
            ]
        }
    }
    
    var body: some View {
        let _ = Logger.info("ActionOptionsModal.body called for card type: \(card.type), card id: \(card.id)", category: .action)
        let _ = Logger.info("actionOptions count in body: \(actionOptions.count)", category: .action)

        return VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Choose Action")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Select your preferred action")
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
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Action options
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(actionOptions, id: \.id) { option in
                            let _ = Logger.info("ForEach rendering option: \(option.id) - \(option.label)", category: .action)
                            Button {
                                Logger.info("Button tapped for option: \(option.id)", category: .action)
                                selectedAction = option.id
                                // Haptic feedback
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                            } label: {
                                HStack(spacing: 16) {
                                    // Icon
                                    Image(systemName: option.icon)
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 40)
                                    
                                    // Text
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option.label)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(option.description)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                    
                                    // Selection indicator
                                    if selectedAction == option.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.title3)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedAction == option.id ? 
                                              Color.white.opacity(0.25) : 
                                              Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .strokeBorder(
                                                    selectedAction == option.id ? 
                                                    Color.green : 
                                                    Color.white.opacity(0.2), 
                                                    lineWidth: selectedAction == option.id ? 2 : 1
                                                )
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
                
                // Confirm button
                Button {
                    if let selected = selectedAction {
                        // Check if changing from compound action to non-compound
                        if viewModel.getCompoundGroup(for: currentAction) != nil,
                           !viewModel.isInSameCompoundGroup(action1: currentAction, action2: selected) {
                            // Changing away from compound action group
                            pendingAction = selected
                            showCompoundWarning = true
                        } else {
                            // Same group or not compound - proceed
                            onActionSelected(selected)
                            isPresented = false
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Continue")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedAction != nil ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .disabled(selectedAction == nil)
                .padding()
        }
        .background(ArchetypeConfig.config(for: card.type).gradient)
        .alert("Change Action?", isPresented: $showCompoundWarning) {
            Button("Cancel", role: .cancel) {
                pendingAction = nil
            }
            Button("Change") {
                if let action = pendingAction {
                    onActionSelected(action)
                    isPresented = false
                }
            }
        } message: {
            if let pending = pendingAction,
               let currentGroup = viewModel.getCompoundGroup(for: currentAction) {
                let groupActions = currentGroup.map { viewModel.getActionLabel(for: $0) }.joined(separator: ", ")
                Text("This email currently supports multiple related actions: \(groupActions). Changing to '\(viewModel.getActionLabel(for: pending))' will use only that single action. Continue?")
            }
        }
    }

    // MARK: - Action Filtering Helpers

    /// Determines if calendar action should be shown based on email content
    private func shouldShowCalendarAction(for card: EmailCard) -> Bool {
        let text = "\(card.title) \(card.summary) \(card.body ?? "")".lowercased()

        // Keywords that suggest an event
        let eventKeywords = [
            "visit", "field trip", "meeting", "conference", "performance",
            "game", "practice", "rehearsal", "appointment", "event",
            "deadline", "due date", "tournament", "recital", "show",
            "party", "celebration", "ceremony"
        ]

        return eventKeywords.contains { text.contains($0) }
    }

    /// Determines if a transactional_leader email needs review/approval action
    private func shouldShowReviewAction(for card: EmailCard) -> Bool {
        let text = "\(card.title) \(card.summary)".lowercased()

        let reviewKeywords = ["approval", "review", "approve", "budget", "document", "contract", "agreement"]
        return reviewKeywords.contains { text.contains($0) }
    }

    /// Determines if a sales email is likely interested vs unqualified
    private func shouldShowScheduleDemo(for card: EmailCard) -> Bool {
        // If probability score is high, show schedule demo
        if let probability = card.probability, probability >= 60 {
            return true
        }

        let text = "\(card.title) \(card.summary)".lowercased()
        let interestedKeywords = ["interested", "demo", "learn more", "schedule", "call", "meeting"]
        return interestedKeywords.contains { text.contains($0) }
    }

    /// Determines if email contains deep links requiring app launch
    private func shouldShowOpenAppAction(for card: EmailCard) -> Bool {
        let text = "\(card.title) \(card.summary) \(card.body ?? "")".lowercased()

        // Known app URL schemes and identifiers
        let appIdentifiers = [
            "ourfamilywizard", "family wizard", "ofw",  // Our Family Wizard
            "doordash", "ubereats", "grubhub",          // Food delivery
            "instacart", "shipt",                        // Grocery delivery
            "app.link", "applink", "deeplink"           // Generic deep linking
        ]

        // Check if email mentions these apps
        if appIdentifiers.contains(where: { text.contains($0) }) {
            return true
        }

        // Check for "open in app" language
        let appKeywords = ["open in app", "view in app", "launch app", "download our app", "tap to open"]
        if appKeywords.contains(where: { text.contains($0) }) {
            return true
        }

        // Check for URL schemes in body
        if let body = card.body {
            let schemes = ["wheaton://", "doordash://", "ubereats://", "ofw://"]
            if schemes.contains(where: { body.contains($0) }) {
                return true
            }
        }

        return false
    }
}

