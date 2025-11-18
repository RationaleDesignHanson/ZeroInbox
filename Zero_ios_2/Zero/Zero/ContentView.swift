import SwiftUI

struct ContentView: View {
    @EnvironmentObject var services: ServiceContainer
    @StateObject var viewState = ContentViewState()
    @StateObject private var accountManager = AccountManager()
    @StateObject private var userPermissions = UserPermissions.shared
    @StateObject private var navState = NavigationState()

    var viewModel: EmailViewModel {
        services.emailViewModel
    }

    /// Computed user ID from authenticated email
    private var userId: String {
        getUserEmail() ?? "user-123" // Fallback to default
    }

    /// Get current user context for action validation
    private var userContext: UserContext {
        userPermissions.getUserContext(userId: userId)
    }

    /// Check if user has multiple email accounts connected
    private var hasMultipleAccounts: Bool {
        accountManager.accounts.count > 1
    }

    var body: some View {
        ZStack {
            // App state flow
            switch services.emailViewModel.currentAppState {
            case .splash:
                SplashView {
                    services.emailViewModel.currentAppState = .onboarding
                }

            case .onboarding:
                OnboardingView(
                    selectedArchetypes: $services.userPreferences.selectedArchetypes,
                    onComplete: {
                        // Ensure all categories are selected (v1.10+: binary mail/ads system)
                        let allArchetypes: [CardType] = [
                            .mail,
                            .ads
                        ]

                        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")

                        // CRITICAL: Ensure at least one category is selected, default to both
                        if viewModel.selectedArchetypes.isEmpty {
                            viewModel.selectedArchetypes = allArchetypes
                            Logger.warning("No categories selected after onboarding, defaulting to mail and ads", category: .app)
                        }

                        Logger.info("Onboarding complete, transitioning to feed (useMockData=\(useMockData), archetypes=\(viewModel.selectedArchetypes.map { $0.displayName }))", category: .app)
                        viewModel.currentAppState = .feed

                        // CRITICAL: Load cards immediately when entering feed
                        // .onAppear may not fire reliably on first appearance after state change
                        viewModel.loadCards()
                    },
                    userEmail: getUserEmail()
                )

            case .feed:
                MainFeedView(
                    viewModel: viewModel,
                    viewState: viewState,
                    navState: navState,
                    userContext: userContext,
                    hasMultipleAccounts: hasMultipleAccounts,
                    loadCartItemCount: loadCartItemCount,
                    getUserEmail: getUserEmail,
                    getActionModalView: { card in AnyView(self.getActionModalView(for: card)) }
                )
                .environmentObject(services)

            case .miniCelebration(let archetype):
                // Mini celebration toast overlay
                ZStack {
                    MainFeedView(
                        viewModel: viewModel,
                        viewState: viewState,
                        navState: navState,
                        userContext: userContext,
                        hasMultipleAccounts: hasMultipleAccounts,
                        loadCartItemCount: loadCartItemCount,
                        getUserEmail: getUserEmail,
                        getActionModalView: { card in AnyView(self.getActionModalView(for: card)) }
                    )
                    .environmentObject(services)

                    MiniCelebrationToast(archetype: archetype) {
                        // Dismiss and switch to next archetype
                        viewModel.switchToNextArchetype()
                        viewModel.currentAppState = .feed
                    }
                    .zIndex(1000)
                }

            case .celebration:
                CelebrationView(
                    archetype: viewModel.currentArchetype,
                    allArchetypesCleared: checkAllArchetypesCleared()
                ) {
                    viewModel.switchToNextArchetype()
                    viewModel.currentAppState = .feed
                }
            }
        }
        .onChange(of: services.emailViewModel.currentAppState) { oldState, newState in
            // CRITICAL: Load cards whenever we transition to feed state
            // This ensures cards load even when .onAppear doesn't fire reliably
            Logger.info("🔄 STATE CHANGE DETECTED: \(String(describing: oldState)) → \(String(describing: newState))", category: .app)
            if newState == .feed && oldState != .feed {
                let useMockData = UserDefaults.standard.bool(forKey: "useMockData")
                Logger.info("✅ Transitioning to feed state, triggering loadCards() (useMockData=\(useMockData))", category: .app)
                viewModel.loadCards()
            }
        }
        .onChange(of: viewModel.cards.count) { oldCount, newCount in
            // Capture initial card count when cards first load (for progress meter)
            // IMPORTANT: Reset viewState.totalInitialCards if newCount increases significantly (card refresh/reload)

            // Calculate remaining undismissed cards
            let remainingCards = viewModel.cards.filter { $0.state != .dismissed }.count

            // Reset progress when all cards are dismissed
            if remainingCards == 0 && viewState.totalInitialCards > 0 {
                Logger.info("📊 All cards dismissed, resetting progress tracker", category: .ui)
                viewState.totalInitialCards = 0
            } else if viewState.totalInitialCards == 0 && newCount > 0 {
                viewState.totalInitialCards = newCount
                Logger.info("📊 Initial card count captured: \(viewState.totalInitialCards)", category: .ui)
            } else if newCount > viewState.totalInitialCards {
                // Cards were refreshed/reloaded - update viewState.totalInitialCards
                Logger.info("📊 Cards refreshed: updating total from \(viewState.totalInitialCards) to \(newCount)", category: .ui)
                viewState.totalInitialCards = newCount
            }
        }
        .onAppear {
            // Handle UI testing flag to skip onboarding
            if ProcessInfo.processInfo.environment["SKIP_ONBOARDING"] == "true" {
                Logger.info("⏩ Skipping onboarding for UI tests", category: .app)

                // Set default categories (v1.10+: binary mail/ads)
                let allArchetypes: [CardType] = [.mail, .ads]
                if viewModel.selectedArchetypes.isEmpty {
                    viewModel.selectedArchetypes = allArchetypes
                }

                // Skip directly to feed
                viewModel.currentAppState = .feed
                viewModel.loadCards()
            }

            // Initialize viewState.totalInitialCards if cards are already loaded
            // This fixes cases where .onChange doesn't trigger properly
            if viewState.totalInitialCards == 0 && !viewModel.cards.isEmpty {
                viewState.totalInitialCards = viewModel.cards.count
                Logger.info("📊 Initialized viewState.totalInitialCards in onAppear: \(viewState.totalInitialCards)", category: .ui)
            }
        }
    }
    
    
    @ViewBuilder
    func getActionModalView(for card: EmailCard) -> some View {
        // ROUTING STRATEGY:
        // 1. Check if user manually selected an action (via swipe up menu)
        // 2. Use ActionRouter (v1.1) for cards with suggestedActions
        // 3. Fall back to ModalRouter (v1.0) for legacy cards

        if let suggestedActions = card.suggestedActions, !suggestedActions.isEmpty {
            // Determine which action to execute and log routing decision
            let (actionToExecute, wasUserSelected) = determineActionToExecute(
                suggestedActions: suggestedActions,
                card: card
            )

            // Modern card with v1.1 action-first architecture
            actionRouterModalView(for: actionToExecute, card: card)
                .onAppear {
                    Logger.info("🔍 Modal routing: executing=\(actionToExecute.actionId), type=\(actionToExecute.actionType == .goTo ? "GO_TO" : "IN_APP"), userSelected=\(wasUserSelected), count=\(suggestedActions.count)", category: .action)
                }
        } else {
            // Legacy card without suggestedActions - use EmailComposer fallback
            EmailComposerModal(card: card, isPresented: $viewState.showActionModal)
                .onAppear {
                    Logger.warning("⚠️ Legacy card without suggestedActions, using EmailComposer fallback: \(card.id), hpa: \(card.hpa)", category: .action)
                }
        }
    }

    /// Helper function to determine which action to execute from suggested actions
    /// Returns tuple of (action to execute, was user selected)
    private func determineActionToExecute(
        suggestedActions: [EmailAction],
        card: EmailCard
    ) -> (EmailAction, Bool) {
        // Priority 1: Check if user has swapped the action (stored in customActions)
        if let customActionId = viewModel.getCustomAction(for: card.id),
           let customAction = suggestedActions.first(where: { $0.actionId == customActionId }) {
            Logger.info("🔄 Using swapped custom action: \(customAction.actionId) (user swapped from primary)", category: .action)
            return (customAction, true)
        }

        // Priority 2: User's manual selection from action sheet (one-time, not persistent)
        if let selectedId = viewState.selectedActionId,
           let selectedAction = suggestedActions.first(where: { $0.actionId == selectedId }) {
            // Defer state modification to avoid "modifying state during view update" warning
            DispatchQueue.main.async {
                self.viewState.selectedActionId = nil  // Clear after use
            }
            Logger.info("🎯 Using user-selected action: \(selectedAction.actionId)", category: .action)
            return (selectedAction, true)
        }

        // Priority 3: Primary action from backend
        if let primaryAction = ActionRouter.shared.getPrimaryAction(from: card) {
            Logger.info("🎯 Using primary action: \(primaryAction.actionId)", category: .action)
            return (primaryAction, false)
        }

        // Priority 4: Fallback to first suggested action
        let fallbackAction = suggestedActions[0]
        Logger.info("🎯 Using fallback action: \(fallbackAction.actionId)", category: .action)
        return (fallbackAction, false)
    }

    // MARK: - ActionRouter Modal Views (v1.1 - JSON-First Architecture)

    /**
     * Modal Routing Strategy (JSON-First with Legacy Fallbacks)
     *
     * Architecture:
     * 1. **JSON-FIRST**: Loads modal configuration from JSON files via ModalConfigService
     *    - JSON configs define fields, validation, layout, and actions
     *    - Rendered by GenericActionModal (universal modal renderer)
     *    - Supports remote config updates and A/B testing
     *
     * 2. **LEGACY FALLBACKS**: For each action type, hardcoded modal implementations
     *    - Used when JSON config fails to load or doesn't exist
     *    - 25 specialized modal Swift files in Views/ActionModules/
     *    - Marked for gradual deprecation in Phase 6
     *
     * Routing Flow:
     * - actionRouterModalView() checks action.actionType
     * - IN_APP actions → load JSON config → GenericActionModal
     * - If JSON fails → fall back to hardcoded modal (case statements below)
     * - GO_TO actions → open URL in Safari with context header
     *
     * Note: This dual approach provides safety during JSON system rollout.
     * Future work (Phase 6): Remove fallback case statements once JSON is battle-tested.
     */

    @ViewBuilder
    private func actionRouterModalView(for action: EmailAction, card: EmailCard) -> some View {
        switch action.actionType {
        case .goTo:
            // GO_TO actions open URLs in Safari with context header
            if let context = action.context,
               let urlString = extractURL(from: context, actionId: action.actionId),
               let url = validateURL(urlString) {
                SafariViewWithContext(
                    url: url,
                    actionName: action.displayName,
                    cardTitle: card.title,
                    cardType: card.type,
                    onDismiss: {
                        viewState.showActionModal = false
                    }
                )
                .onAppear {
                    Logger.info("Opening GO_TO action in Safari with context: \(action.displayName) - \(url.absoluteString)", category: .action)
                }
            } else {
                // Missing or invalid URL - show helpful error and close modal
                VStack(spacing: 12) {
                    Image(systemName: "link.slash")
                        .font(.largeTitle)
                        .foregroundColor(.red)

                    Text("Unable to open link")
                        .font(.headline)
                        .foregroundColor(.white)

                    if let context = action.context, !context.isEmpty {
                        Text("Missing URL in action context")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("No context data provided")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .onAppear {
                    Logger.error("GO_TO action missing or invalid URL: \(action.actionId)", category: .action)
                    if let context = action.context {
                        let availableKeys = context.keys.sorted().joined(separator: ", ")
                        Logger.error("Available context keys: [\(availableKeys)]", category: .action)
                    } else {
                        Logger.error("No context provided for action", category: .action)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        viewState.showActionModal = false
                    }
                }
            }

        case .inApp:
            // IN_APP actions show modals
            inAppActionModalView(for: action, card: card)
        }
    }

    @ViewBuilder
    private func inAppActionModalView(for action: EmailAction, card: EmailCard) -> some View {
        // Check for compound flows first (multi-step actions like sign → pay → email)
        if let steps = action.compoundSteps, !steps.isEmpty {
            // Get compound definition for end behavior
            let compoundDef = CompoundActionRegistry.shared.getCompoundAction(action.actionId)

            CompoundActionFlow(
                card: card,
                steps: steps,
                context: action.context ?? [:],
                endBehavior: compoundDef?.endBehavior,
                isPresented: $viewState.showActionModal
            )
            .onAppear {
                Logger.info("🔄 Rendering compound flow with \(steps.count) steps: \(steps.joined(separator: " → "))", category: .action)
                if let behavior = compoundDef?.endBehavior {
                    switch behavior {
                    case .emailComposer:
                        Logger.info("End behavior: Email composer will be shown", category: .action)
                    case .dismissWithSuccess:
                        Logger.info("End behavior: Dismiss with success", category: .action)
                    case .returnToApp:
                        Logger.info("End behavior: Return to app", category: .action)
                    }
                }
            }
        } else {
            // Single-step actions
            switch action.actionId {
            case "sign_form":
                SignFormModal(
                    card: card,
                    isPresented: $viewState.showActionModal,
                    onSignComplete: { signatureName in
                        viewState.signedDocumentName = signatureName
                        viewState.emailComposerCard = card
                        Logger.info("Signature saved: \(signatureName)", category: .modal)

                        viewState.showActionModal = false
                        Logger.info("SignFormModal dismissed, scheduling EmailComposer", category: .modal)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            if !viewState.showActionModal {
                                Logger.info("Opening EmailComposer modal for card: \(card.id)", category: .modal)
                                viewState.showEmailComposer = true
                            } else {
                                Logger.warning("SignFormModal still visible, retrying EmailComposer", category: .modal)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    viewState.showEmailComposer = true
                                }
                            }
                        }
                    }
                )

            case "add_to_calendar":
                AddToCalendarModal(card: card, isPresented: $viewState.showActionModal)

            case "view_newsletter_summary":
                if let context = action.context {
                    NewsletterSummaryModal(
                        card: card,
                        context: context,
                        isPresented: $viewState.showActionModal
                    )
                } else {
                    NewsletterSummaryModal(
                        card: card,
                        context: [:],
                        isPresented: $viewState.showActionModal
                    )
                }

            case "schedule_purchase":
                if let scheduleAction = card.suggestedActions?.first(where: { $0.actionId == "schedule_purchase" }) {
                    ScheduledPurchaseModal(card: card, action: scheduleAction, isPresented: $viewState.showActionModal)
                } else {
                    EmailComposerModal(card: card, isPresented: $viewState.showActionModal)
                        .onAppear {
                            Logger.warning("schedule_purchase action not found in suggestedActions", category: .action)
                        }
                }

            case "view_details":
                // Generic view details action - show full email detail view
                EmailDetailView(card: card)

            case "browse_shopping", "claim_deal", "save_deal":
                ShoppingPurchaseModal(card: card, isPresented: $viewState.showActionModal, selectedAction: action.actionId)
                    .environmentObject(viewModel)

            case "schedule_meeting", "schedule_demo", "schedule_call":
                ScheduleMeetingModal(card: card, isPresented: $viewState.showActionModal, onComplete: {})

            case "review_document", "approve_document", "view_document":
                // PRIORITY: If email requires signature, use SignFormModal instead
                // Otherwise, show DocumentViewerModal for real documents or EmailDetailView as fallback
                if card.requiresSignature == true {
                    // Signature request takes priority - use sign & send flow
                    SignFormModal(
                        card: card,
                        isPresented: $viewState.showActionModal,
                        onSignComplete: { signatureName in
                            viewState.signedDocumentName = signatureName
                            viewState.emailComposerCard = card
                            Logger.info("Signature saved: \(signatureName)", category: .modal)

                            viewState.showActionModal = false
                            Logger.info("SignFormModal dismissed, scheduling EmailComposer", category: .modal)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                if !viewState.showActionModal {
                                    Logger.info("Opening EmailComposer modal for card: \(card.id)", category: .modal)
                                    viewState.showEmailComposer = true
                                } else {
                                    Logger.warning("SignFormModal still visible, retrying EmailComposer", category: .modal)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        viewState.showEmailComposer = true
                                    }
                                }
                            }
                        }
                    )
                    .onAppear {
                        Logger.info("📝 Document requires signature - routing to SignFormModal (priority)", category: .action)
                    }
                } else if let context = action.context, context["documentUrl"] != nil || context["attachmentUrl"] != nil {
                    // Real document exists - show DocumentViewerModal
                    DocumentViewerModal(card: card, isPresented: $viewState.showActionModal)
                        .onAppear {
                            Logger.info("📄 Opening real document from email", category: .action)
                        }
                } else {
                    // No real document - fallback to EmailDetailView
                    EmailDetailView(card: card)
                        .onAppear {
                            Logger.info("📧 No document attachment found - showing EmailDetailView", category: .action)
                        }
                }

            case "view_spreadsheet", "review_budget":
                SpreadsheetViewerModal(card: card, isPresented: $viewState.showActionModal)

            case "open_app":
                OpenAppModal(card: card, isPresented: $viewState.showActionModal)

            case "archive", "save_later", "save_for_later", "snooze":
                SnoozePickerModal(
                    isPresented: $viewState.showActionModal,
                    selectedDuration: $viewState.snoozeDuration
                ) {
                    if let card = viewState.actionModalCard {
                        viewModel.setRememberedSnoozeDuration(viewState.snoozeDuration)
                        viewModel.handleSwipe(direction: .down, card: card)
                        viewState.undoActionText = "Snoozed for \(viewState.snoozeDuration)h"
                        viewState.showUndoToast = true
                        viewState.showActionModal = false
                    }
                }

            case "reply", "quick_reply", "respond":
                EmailComposerModal(
                    card: card,
                    isPresented: $viewState.showActionModal,
                    recipientOverride: action.context?["recipientEmail"] ?? card.sender?.email,
                    subjectOverride: action.context?["subject"] ?? "Re: \(card.title)"
                )

            case "track_package":
                if let context = action.context {
                    TrackPackageModal(
                        card: card,
                        trackingNumber: context["trackingNumber"] ?? "Unknown",
                        carrier: context["carrier"] ?? "Carrier",
                        trackingUrl: context["url"] ?? context["trackingUrl"] ?? "",
                        context: context,
                        isPresented: $viewState.showActionModal
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $viewState.showActionModal)
                        .onAppear {
                            Logger.warning("track_package missing context", category: .action)
                        }
                }

            case "pay_invoice":
                if let context = action.context {
                    PayInvoiceModal(
                        card: card,
                        invoiceId: context["invoiceId"] ?? context["invoiceNumber"] ?? "Unknown",
                        amount: context["amount"] ?? context["amountDue"] ?? "$0.00",
                        merchant: context["merchant"] ?? card.company?.name ?? "Merchant",
                        context: context,
                        isPresented: $viewState.showActionModal
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $viewState.showActionModal)
                        .onAppear {
                            Logger.warning("pay_invoice missing context", category: .action)
                        }
                }

            case "check_in_flight":
                if let context = action.context {
                    CheckInFlightModal(
                        card: card,
                        flightNumber: context["flightNumber"] ?? "Unknown",
                        airline: context["airline"] ?? "Airline",
                        checkInUrl: context["checkInUrl"] ?? context["url"] ?? "",
                        context: context,
                        isPresented: $viewState.showActionModal
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $viewState.showActionModal)
                        .onAppear {
                            Logger.warning("check_in_flight missing context", category: .action)
                        }
                }

            case "cancel_subscription":
                CancelSubscriptionModal(card: card) {
                    viewState.showActionModal = false
                }
                .onAppear {
                    Logger.info("🚫 Opening cancel subscription modal for: \(card.company?.name ?? "service")", category: .action)
                }

            case "unsubscribe":
                if let context = action.context, let unsubscribeUrl = context["unsubscribeUrl"] {
                    UnsubscribeModal(
                        card: card,
                        unsubscribeUrl: unsubscribeUrl,
                        isPresented: $viewState.showActionModal,
                        onUnsubscribeComplete: {
                            Logger.info("✅ Unsubscribe completed for: \(card.company?.name ?? card.sender?.name ?? "sender")", category: .action)
                        }
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $viewState.showActionModal)
                        .onAppear {
                            Logger.warning("unsubscribe missing unsubscribeUrl in context", category: .action)
                        }
                }

            case "write_review":
                if let context = action.context {
                    WriteReviewModal(
                        card: card,
                        productName: context["productName"] ?? "Product",
                        reviewLink: context["reviewLink"] ?? context["url"] ?? "",
                        context: context,
                        isPresented: $viewState.showActionModal
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $viewState.showActionModal)
                        .onAppear {
                            Logger.warning("write_review missing context", category: .action)
                        }
                }

            case "contact_driver":
                if let context = action.context {
                    ContactDriverModal(
                        card: card,
                        driverInfo: context,
                        isPresented: $viewState.showActionModal
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $viewState.showActionModal)
                        .onAppear {
                            Logger.warning("contact_driver missing context", category: .action)
                        }
                }

            case "view_pickup_details":
                if let context = action.context {
                    PickupDetailsModal(
                        card: card,
                        rxNumber: context["rxNumber"] ?? "N/A",
                        pharmacy: context["pharmacy"] ?? "Pharmacy",
                        context: context,
                        isPresented: $viewState.showActionModal
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $viewState.showActionModal)
                        .onAppear {
                            Logger.warning("view_pickup_details missing context", category: .action)
                        }
                }

            case "copy_promo_code", "copy_code":
                // Instant clipboard copy with haptic feedback
                if let code = action.context?["promoCode"] ?? action.context?["code"] {
                    Text("Code Copied!")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.green.opacity(0.9))
                        .onAppear {
                            UIPasteboard.general.string = code

                            let notification = UINotificationFeedbackGenerator()
                            notification.notificationOccurred(.success)

                            Logger.info("Promo code copied to clipboard: \(code)", category: .action)

                            AnalyticsService.shared.log("promo_code_copied", properties: [
                                "code": code,
                                "merchant": card.company?.name ?? "unknown"
                            ])

                            // Auto-dismiss after 1 second
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                viewState.showActionModal = false
                            }
                        }
                } else {
                    EmailComposerModal(card: card, isPresented: $viewState.showActionModal)
                        .onAppear {
                            Logger.warning("copy_promo_code missing code in context", category: .action)
                        }
                }

            // Native iOS Integrations
            case "add_to_wallet":
                AddToWalletModal(card: card, isPresented: $viewState.showActionModal)

            case "add_reminder", "set_reminder", "remind":
                AddReminderModal(card: card, isPresented: $viewState.showActionModal)

            case "save_contact_native":
                SaveContactModal(card: card, isPresented: $viewState.showActionModal)

            case "send_message":
                SendMessageModal(card: card, isPresented: $viewState.showActionModal)

            case "share":
                if let context = action.context {
                    let shareContent = generateShareContentForModal(from: card, context: context)
                    ShareModal(card: card, content: shareContent, isPresented: $viewState.showActionModal)
                } else {
                    let shareContent = generateShareContentForModal(from: card, context: [:])
                    ShareModal(card: card, content: shareContent, isPresented: $viewState.showActionModal)
                }

            case "view_reservation", "modify_reservation":
                if let context = action.context {
                    // Pass context directly (already [String: String])
                    ReservationModal(
                        card: card,
                        context: context,
                        isPresented: $viewState.showActionModal
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $viewState.showActionModal)
                        .onAppear {
                            Logger.warning("view_reservation missing context", category: .action)
                        }
                }

            // TIER 1: High-priority missing actions
            case "add_to_notes":
                AddToNotesModal(card: card, isPresented: $viewState.showActionModal)

            case "track_delivery":
                // Same as track_package
                if let context = action.context {
                    TrackPackageModal(
                        card: card,
                        trackingNumber: context["trackingNumber"] ?? context["deliveryNumber"] ?? "Unknown",
                        carrier: context["carrier"] ?? context["courier"] ?? "Carrier",
                        trackingUrl: context["url"] ?? context["trackingUrl"] ?? context["deliveryUrl"] ?? "",
                        context: context,
                        isPresented: $viewState.showActionModal
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $viewState.showActionModal)
                        .onAppear {
                            Logger.warning("track_delivery missing context", category: .action)
                        }
                }

            case "schedule_payment", "set_payment_reminder":
                // Payment scheduling - use calendar or reminder
                AddReminderModal(card: card, isPresented: $viewState.showActionModal)

            case "join_meeting", "open_link", "open_original_link":
                // These should be GO_TO actions, but if marked as IN_APP, open in Safari
                if let context = action.context,
                   let urlString = extractURL(from: context, actionId: action.actionId),
                   let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    EmailDetailView(card: card)
                        .onAppear {
                            Logger.warning("\(action.actionId) missing valid URL", category: .action)
                        }
                }

            case "reschedule_appointment", "confirm_appointment", "book_appointment", "check_in_appointment":
                // Appointment actions - use calendar
                AddToCalendarModal(card: card, isPresented: $viewState.showActionModal)

            // TIER 2: Medium-priority missing actions
            case "verify_account":
                AccountVerificationModal(
                    card: card,
                    isPresented: $viewState.showActionModal,
                    verificationType: .account,
                    verifyUrl: action.context.flatMap { extractURL(from: $0, actionId: action.actionId) }
                )

            case "verify_device":
                AccountVerificationModal(
                    card: card,
                    isPresented: $viewState.showActionModal,
                    verificationType: .device,
                    verifyUrl: action.context.flatMap { extractURL(from: $0, actionId: action.actionId) }
                )

            case "verify_social_account":
                AccountVerificationModal(
                    card: card,
                    isPresented: $viewState.showActionModal,
                    verificationType: .social,
                    verifyUrl: action.context.flatMap { extractURL(from: $0, actionId: action.actionId) }
                )

            case "reset_password":
                // Password reset - open link or show detail
                if let context = action.context,
                   let urlString = extractURL(from: context, actionId: action.actionId),
                   let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    EmailDetailView(card: card)
                }

            case "update_payment_method", "update_payment":
                // Payment update - use dedicated payment modal
                UpdatePaymentModal(
                    card: card,
                    isPresented: $viewState.showActionModal,
                    updateUrl: action.context.flatMap { extractURL(from: $0, actionId: action.actionId) },
                    context: action.context ?? [:]
                )

            case "download_attachment", "download_receipt", "download_results":
                // Document download - show document viewer
                DocumentViewerModal(card: card, isPresented: $viewState.showActionModal)

            case "view_invoice", "view_order", "view_statement":
                // View financial documents
                if let context = action.context,
                   let urlString = extractURL(from: context, actionId: action.actionId),
                   let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    DocumentViewerModal(card: card, isPresented: $viewState.showActionModal)
                }

            case "manage_subscription", "upgrade_subscription", "extend_trial":
                // Subscription management
                if let context = action.context,
                   let urlString = extractURL(from: context, actionId: action.actionId),
                   let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    EmailDetailView(card: card)
                }

            case "complete_cart", "return_item", "reorder_item", "buy_again":
                // Shopping actions
                ShoppingPurchaseModal(card: card, isPresented: $viewState.showActionModal, selectedAction: action.actionId)
                    .environmentObject(viewModel)

            // School & Education actions
            case "accept_school_event", "rsvp_school_event", "reply_to_teacher", "submit_assignment",
                 "view_assignment", "check_grade", "view_lms_message", "view_announcement", "view_team_announcement":
                // School actions - open link or show detail
                if let context = action.context,
                   let urlString = extractURL(from: context, actionId: action.actionId),
                   let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    EmailDetailView(card: card)
                }

            // Social & RSVP actions
            case "rsvp_yes":
                RSVPModal(
                    card: card,
                    isPresented: $viewState.showActionModal,
                    response: .yes,
                    context: action.context ?? [:]
                )

            case "rsvp_no":
                RSVPModal(
                    card: card,
                    isPresented: $viewState.showActionModal,
                    response: .no,
                    context: action.context ?? [:]
                )

            case "accept_social_invitation", "rsvp_game":
                // Generic invitations - use dedicated RSVP modal with yes response
                RSVPModal(
                    card: card,
                    isPresented: $viewState.showActionModal,
                    response: .yes,
                    context: action.context ?? [:]
                )

            // Event & Activity actions
            case "add_activity_to_calendar", "book_activity_tickets", "register_event",
                 "register_for_sports", "view_game_schedule", "view_practice_details":
                // Activity registration - open link or add to calendar
                if let context = action.context,
                   let urlString = extractURL(from: context, actionId: action.actionId),
                   let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    AddToCalendarModal(card: card, isPresented: $viewState.showActionModal)
                }

            // Legal & Government actions
            case "apply_for_permit", "register_to_vote", "confirm_court_appearance", "renew_license",
                 "pay_property_tax", "view_ballot", "view_legal_document":
                // Government/legal actions - open link or show document
                if let context = action.context,
                   let urlString = extractURL(from: context, actionId: action.actionId),
                   let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    DocumentViewerModal(card: card, isPresented: $viewState.showActionModal)
                }

            // Financial & Insurance actions
            case "file_insurance_claim", "view_claim_status", "dispute_transaction", "view_credit_report",
                 "view_mortgage_details", "view_portfolio", "view_benefits":
                // Financial documents - open link or show document
                if let context = action.context,
                   let urlString = extractURL(from: context, actionId: action.actionId),
                   let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    DocumentViewerModal(card: card, isPresented: $viewState.showActionModal)
                }

            // Healthcare actions
            case "pickup_prescription", "schedule_inspection", "schedule_test":
                // Healthcare actions - add reminder or open link
                if let context = action.context,
                   let urlString = extractURL(from: context, actionId: action.actionId),
                   let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    AddReminderModal(card: card, isPresented: $viewState.showActionModal)
                }

            // Utilities & Services actions
            case "pay_utility_bill", "prepare_for_outage", "set_outage_reminder", "view_outage_details",
                 "change_delivery_preferences", "schedule_delivery_time", "notify_restock":
                // Utility actions - open link or set reminder
                if let context = action.context,
                   let urlString = extractURL(from: context, actionId: action.actionId),
                   let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    AddReminderModal(card: card, isPresented: $viewState.showActionModal)
                }

            // Shopping & Rewards actions
            case "redeem_rewards", "rate_product", "set_price_alert", "accept_offer", "view_product",
                 "view_refund_status", "view_warranty", "view_usage":
                // Shopping/rewards - open link or browse shopping
                if let context = action.context,
                   let urlString = extractURL(from: context, actionId: action.actionId),
                   let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    ShoppingPurchaseModal(card: card, isPresented: $viewState.showActionModal, selectedAction: action.actionId)
                        .environmentObject(viewModel)
                }

            // Real Estate & Property actions
            case "save_properties", "view_property_listings", "schedule_showing", "view_introduction":
                // Real estate - use dedicated modal or open link
                if action.actionId == "save_properties" {
                    SavePropertiesModal(card: card, isPresented: $viewState.showActionModal)
                } else if let context = action.context,
                          let urlString = extractURL(from: context, actionId: action.actionId),
                          let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    EmailDetailView(card: card)
                }

            // Job & Career actions
            case "view_job_details", "schedule_interview", "check_application_status":
                // Job actions - open link or show detail
                if let context = action.context,
                   let urlString = extractURL(from: context, actionId: action.actionId),
                   let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    EmailDetailView(card: card)
                }

            // Travel & Booking actions
            case "manage_booking", "view_itinerary", "get_directions":
                // Travel actions - use dedicated itinerary modal
                let itineraryType: ViewItineraryModal.ItineraryType = {
                    if let type = action.context?["type"] {
                        switch type.lowercased() {
                        case "flight": return .flight
                        case "hotel": return .hotel
                        case "rental", "car": return .rental
                        case "restaurant": return .restaurant
                        default: return .general
                        }
                    }
                    return .general
                }()

                ViewItineraryModal(
                    card: card,
                    isPresented: $viewState.showActionModal,
                    itineraryType: itineraryType,
                    bookingUrl: action.context.flatMap { extractURL(from: $0, actionId: action.actionId) },
                    context: action.context ?? [:]
                )

            case "print_return_label", "track_return":
                // Return/label actions - open link or show details
                if let context = action.context,
                   let urlString = extractURL(from: context, actionId: action.actionId),
                   let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    EmailDetailView(card: card)
                }

            // Support & Communication actions
            case "contact_support", "view_ticket", "reply_to_ticket", "reply_to_thread", "reply_to_post":
                // Support/communication - reply or view details
                if action.actionId.contains("reply") || action.actionId == "reply_thanks" {
                    EmailComposerModal(
                        card: card,
                        isPresented: $viewState.showActionModal,
                        recipientOverride: action.context?["recipientEmail"] ?? card.sender?.email,
                        subjectOverride: action.context?["subject"] ?? "Re: \(card.title)"
                    )
                } else if let context = action.context,
                          let urlString = extractURL(from: context, actionId: action.actionId),
                          let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    EmailDetailView(card: card)
                }

            // Community & Social actions
            case "read_community_post", "view_post_comments", "view_social_message", "share_achievement":
                // Community actions - use dedicated modals or open link
                if action.actionId == "read_community_post" {
                    ReadCommunityPostModal(card: card, isPresented: $viewState.showActionModal)
                } else if action.actionId == "view_post_comments" {
                    ViewPostCommentsModal(card: card, isPresented: $viewState.showActionModal)
                } else if let context = action.context,
                          let urlString = extractURL(from: context, actionId: action.actionId),
                          let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    EmailDetailView(card: card)
                }

            // Activity & Analytics actions
            case "view_activity", "view_activity_details", "view_results", "view_extracted_content",
                 "view_incident", "view_onboarding_info", "view_referral":
                // Activity/analytics actions - use dedicated modals or show details
                if action.actionId == "view_activity" {
                    ViewActivityModal(card: card, isPresented: $viewState.showActionModal)
                } else if action.actionId == "view_activity_details" {
                    ViewActivityDetailsModal(card: card, isPresented: $viewState.showActionModal)
                } else if let context = action.context,
                          let urlString = extractURL(from: context, actionId: action.actionId),
                          let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    EmailDetailView(card: card)
                }

            // Security actions
            case "review_security":
                ReviewSecurityModal(
                    card: card,
                    isPresented: $viewState.showActionModal,
                    securityType: .reviewActivity,
                    actionUrl: action.context.flatMap { extractURL(from: $0, actionId: action.actionId) },
                    context: action.context ?? [:]
                )

            case "revoke_secret":
                ReviewSecurityModal(
                    card: card,
                    isPresented: $viewState.showActionModal,
                    securityType: .revokeAccess,
                    actionUrl: action.context.flatMap { extractURL(from: $0, actionId: action.actionId) },
                    context: action.context ?? [:]
                )

            case "verify_transaction":
                ReviewSecurityModal(
                    card: card,
                    isPresented: $viewState.showActionModal,
                    securityType: .verifyTransaction,
                    actionUrl: action.context.flatMap { extractURL(from: $0, actionId: action.actionId) },
                    context: action.context ?? [:]
                )

            case "provide_access_code":
                ProvideAccessCodeModal(card: card, isPresented: $viewState.showActionModal)

            // Document & Tax actions
            case "download_tax_document", "pay_form_fee", "take_survey":
                // Document/tax actions - download or open link
                if let context = action.context,
                   let urlString = extractURL(from: context, actionId: action.actionId),
                   let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    DocumentViewerModal(card: card, isPresented: $viewState.showActionModal)
                }

            // Scheduling actions (general)
            case "schedule_extraction_retry":
                // Internal scheduling action - show detail
                EmailDetailView(card: card)

            // Catch-all for remaining backend actions
            case "cancel_subscription_service":
                // Miscellaneous actions - try to open link or show detail
                if let context = action.context,
                   let urlString = extractURL(from: context, actionId: action.actionId),
                   let url = validateURL(urlString) {
                    SafariViewWithContext(
                        url: url,
                        actionName: action.displayName,
                        cardTitle: card.title,
                        cardType: card.type,
                        onDismiss: {
                            viewState.showActionModal = false
                        }
                    )
                } else {
                    EmailDetailView(card: card)
                }

            default:
                // Generic fallback for unmapped IN_APP actions
                EmailComposerModal(card: card, isPresented: $viewState.showActionModal)
                    .onAppear {
                        Logger.warning("⚠️ Unmapped IN_APP action: \(action.actionId), falling back to EmailComposer", category: .action)
                    }
            }
        }
    }

    // MARK: - Loading View
    @ViewBuilder
    func loadingView(isClassifying: Bool) -> some View {
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")

        // Show loading spinner for both mock and real email modes
        VStack(spacing: 24) {
            // Animated spinner
            ProgressView()
                .scaleEffect(1.8)
                .tint(.white)

            // Loading text with progress
            VStack(spacing: 12) {
                Text(isClassifying ? "Analyzing emails" : "Loading your emails")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                // Progress bar (only for real emails)
                if !useMockData && services.appState.loadingProgress > 0 {
                    VStack(spacing: 6) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 6)

                                // Progress
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .green],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * services.appState.loadingProgress, height: 6)
                                    .animation(.easeInOut(duration: 0.3), value: services.appState.loadingProgress)
                            }
                        }
                        .frame(height: 6)
                        .frame(maxWidth: 200)

                        // Progress percentage and message
                        Text("\(Int(services.appState.loadingProgress * 100))% - \(services.appState.loadingMessage)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Text(isClassifying ?
                     "Detecting intents and suggesting actions..." :
                     useMockData ? "Hang tight while we prepare your demo..." : "Hang tight while we fetch and organize...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - FireflyBackground Component

/// Firefly background matching the website design
/// Creates floating particles with subtle glow effects on a multi-color gradient
struct FireflyBackground: View {
    @State private var fireflies: [Firefly] = []

    var body: some View {
        ZStack {
            // Base gradient matching website colors
            // linear-gradient(135deg, #1a1a2e 0%, #2d1b4e 30%, #4a1942 60%, #1f1f3a 100%)
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "2d1b4e"),
                    Color(hex: "4a1942"),
                    Color(hex: "1f1f3a")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Firefly particles
            ForEach(fireflies) { firefly in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                firefly.color.opacity(firefly.opacity),
                                firefly.color.opacity(firefly.opacity * 0.5),
                                firefly.color.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: firefly.size
                        )
                    )
                    .frame(width: firefly.size, height: firefly.size)
                    .blur(radius: firefly.blur)
                    .position(firefly.position)
                    .opacity(firefly.currentOpacity)
        }
        }
        .ignoresSafeArea()
        .onAppear {
            generateFireflies()
            startAnimation()
        }
    }

    private func generateFireflies() {
        // Generate 40 small/medium fireflies + 6 large orbs
        var newFireflies: [Firefly] = []

        // Small, medium, and warm fireflies (40 total)
        for i in 0..<40 {
            let rand = Double.random(in: 0...1)
            let type: FireflyType = rand < 0.33 ? .small : rand < 0.66 ? .medium : .warm
            newFireflies.append(Firefly(type: type, index: i))
        }

        // Large ambient orbs (6 total)
        for i in 0..<6 {
            newFireflies.append(Firefly(type: .orb, index: i + 40))
        }

        fireflies = newFireflies
    }

    private func startAnimation() {
        for i in 0..<fireflies.count {
            animateFirefly(index: i)
        }
    }

    private func animateFirefly(index: Int) {
        guard index < fireflies.count else { return }

        let duration = fireflies[index].duration
        let delay = Double.random(in: 0...duration)

        // Animate opacity
        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            fireflies[index].currentOpacity = Double.random(in: 0.3...0.9)
        }

        // Animate position
        Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { _ in
            guard index < fireflies.count else { return }

            withAnimation(.easeInOut(duration: duration)) {
                let moveRange = fireflies[index].type == .orb ? 80.0 : 70.0
                fireflies[index].position.x += CGFloat.random(in: -moveRange...moveRange)
                fireflies[index].position.y += CGFloat.random(in: -moveRange...moveRange)

                // Keep within screen bounds
                fireflies[index].position.x = max(0, min(UIScreen.main.bounds.width, fireflies[index].position.x))
                fireflies[index].position.y = max(0, min(UIScreen.main.bounds.height, fireflies[index].position.y))
            }
        }
    }
}

// MARK: - Firefly Model

enum FireflyType {
    case small, medium, warm, orb
}

struct Firefly: Identifiable {
    let id = UUID()
    let type: FireflyType
    let color: Color
    let size: CGFloat
    let blur: CGFloat
    let opacity: Double
    let duration: Double
    var position: CGPoint
    var currentOpacity: Double

    init(type: FireflyType, index: Int) {
        self.type = type

        // Set properties based on type (matching website CSS)
        switch type {
        case .small:
            // rgba(147, 197, 253, 1) - blue fireflies
            self.color = Color(red: 147/255, green: 197/255, blue: 253/255)
            self.size = 3
            self.blur = 5
            self.opacity = 0.8

        case .medium:
            // rgba(196, 181, 253, 1) - purple fireflies
            self.color = Color(red: 196/255, green: 181/255, blue: 253/255)
            self.size = 5
            self.blur = 7.5
            self.opacity = 0.9

        case .warm:
            // rgba(251, 191, 36, 1) - amber/orange fireflies
            self.color = Color(red: 251/255, green: 191/255, blue: 36/255)
            self.size = 4
            self.blur = 6
            self.opacity = 0.9

        case .orb:
            // rgba(139, 92, 246, 0.15) - large purple orbs
            self.color = Color(red: 139/255, green: 92/255, blue: 246/255)
            self.size = 200
            self.blur = 40
            self.opacity = 0.15
        }

        // Random initial position
        self.position = CGPoint(
            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
        )

        // Random animation duration (8-20s for organic feel, longer for orbs)
        self.duration = type == .orb
            ? Double.random(in: 20...35)
            : Double.random(in: 8...20)

        // Start with random opacity
        self.currentOpacity = Double.random(in: 0.3...0.9)
    }
}
