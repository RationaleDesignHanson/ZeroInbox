import SwiftUI

struct ContentView: View {
    @EnvironmentObject var services: ServiceContainer
    @StateObject private var accountManager = AccountManager()
    @StateObject private var userPermissions = UserPermissions.shared
    @StateObject private var navState = NavigationState()
    @State private var dragOffset: CGSize = .zero
    @State private var showArchetypeSheet = false

    private var viewModel: EmailViewModel {
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

    @State private var showUndoToast = false
    @State private var undoActionText = ""
    @State private var showActionModal = false
    @State private var actionModalCard: EmailCard?
    @State private var showSplayView = false
    @State private var showEmailComposer = false
    @State private var emailComposerCard: EmailCard?
    @State private var signedDocumentName: String?
    @State private var showSnoozePicker = false
    @State private var snoozeCard: EmailCard?
    @State private var snoozeDuration: Int = 2 // default 2 hours
    @State private var showUrgentConfirmation = false
    @State private var urgentConfirmCard: EmailCard?
    @State private var actionOptionsCard: EmailCard? // Using .sheet(item:) pattern - no separate bool needed
    @State private var selectedActionId: String?
    @State private var showSettings = false
    @State private var showShoppingCart = false
    @State private var showSearch = false
    @State private var cartItemCount = 0
    @State private var selectedThreadCard: EmailCard? = nil
    @State private var saveSnoozeMenuCard: EmailCard? = nil
    @State private var showSaveSnoozeMenu = false
    @State private var folderPickerCard: EmailCard? = nil
    @State private var showFolderPicker = false
    @State private var showSavedMail = false

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
                mainFeedView

            case .miniCelebration(let archetype):
                // Mini celebration toast overlay
                ZStack {
                    mainFeedView

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
        }
    }
    
    var mainFeedView: some View {
        ZStack {
            // Gradient background
            ArchetypeConfig.config(for: viewModel.currentArchetype).gradient
                .ignoresSafeArea()

            // Show loading screen while fetching emails OR if we have 0 cards and no error
            // This prevents premature showing of empty state
            let useMockData = UserDefaults.standard.bool(forKey: "useMockData")
            if viewModel.isLoadingRealEmails || viewModel.isClassifying || (!useMockData && viewModel.cards.isEmpty && viewModel.realEmailError == nil) {
                loadingView(isClassifying: viewModel.isClassifying)
            } else if viewModel.filteredCards.isEmpty {
                // Empty state - maintain same vertical layout as cards
                VStack {
                    Spacer()

                    EmptyStateView(archetype: viewModel.currentArchetype) {
                        if viewModel.realEmailError != nil {
                            // Retry loading real emails
                            Task {
                                await viewModel.loadRealEmails()
                            }
                        } else {
                            viewModel.refreshCards()
                        }
                    }

                    Spacer()
                }
                .padding(.bottom, 100) // Clearance for new nav design
            } else {
                // Card stack with swipe gestures - positioned 8px below Dynamic Island
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 8)  // Just 8px from Dynamic Island - clean and tight!

                    ZStack(alignment: .bottom) {
                        CardStackView(
                            viewModel: viewModel,
                            dragOffset: $dragOffset,
                            actionModalCard: $actionModalCard,
                            showActionModal: $showActionModal,
                            actionOptionsCard: $actionOptionsCard,
                            selectedActionId: $selectedActionId,
                            undoActionText: $undoActionText,
                            showUndoToast: $showUndoToast,
                            snoozeCard: $snoozeCard,
                            showSnoozePicker: $showSnoozePicker,
                            urgentConfirmCard: $urgentConfirmCard,
                            showUrgentConfirmation: $showUrgentConfirmation,
                            selectedThreadCard: $selectedThreadCard,
                            saveSnoozeMenuCard: $saveSnoozeMenuCard,
                            showSaveSnoozeMenu: $showSaveSnoozeMenu,
                            folderPickerCard: $folderPickerCard,
                            showFolderPicker: $showFolderPicker,
                            hasMultipleAccounts: hasMultipleAccounts
                        )
                        .environmentObject(navState)

                        // Undo toast at bottom of card (not screen)
                        if showUndoToast {
                            UndoToast(
                                action: undoActionText,
                                onUndo: {
                                    viewModel.undoLastAction()
                                    showUndoToast = false
                                },
                                onDismiss: {
                                    showUndoToast = false
                                }
                            )
                            .padding(.bottom, 15)
                            .zIndex(999)
                        }
                    }

                    Spacer()
                }
                .padding(.bottom, 100) // Clearance for reduced nav height
            }

            // Bottom Navigation Bar
            BottomNavigationBar(
                viewModel: viewModel,
                showSplayView: $showSplayView,
                showArchetypeSheet: $showArchetypeSheet,
                showShoppingCart: $showShoppingCart,
                showSettings: $showSettings,
                showSearch: $showSearch,
                showSavedMail: $showSavedMail,
                cartItemCount: cartItemCount,
                onRefresh: {
                    await viewModel.refreshEmails()
                }
            )
            .environmentObject(navState)

            // Debug overlay (toggleable from settings or feature flags)
            if services.featureGating.isEnabled(.debugOverlays) {
                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DEBUG INFO").font(.caption2.bold()).foregroundColor(.yellow)
                        Text("State: \(String(describing: viewModel.currentAppState))").font(.caption2)
                        Text("Mock: \(UserDefaults.standard.bool(forKey: "useMockData") ? "YES" : "NO")").font(.caption2)
                        Text("Total Cards: \(viewModel.cards.count)").font(.caption2)
                        Text("Current: \(viewModel.currentArchetype.rawValue)").font(.caption2)
                        Text("Filtered: \(viewModel.filteredCards.count)").font(.caption2)
                        Text("Loading: \(viewModel.isLoadingRealEmails ? "YES" : "NO")").font(.caption2)
                        Text("Classifying: \(viewModel.isClassifying ? "YES" : "NO")").font(.caption2)

                        // Show error if any
                        if let error = viewModel.realEmailError {
                            Text("❌ Error:").font(.caption2.bold()).foregroundColor(.red)
                            Text(error).font(.caption2).foregroundColor(.red)
                        } else {
                            Text("✅ No Error").font(.caption2).foregroundColor(.green)
                        }

                        Text("Selected: \(viewModel.selectedArchetypes.count)").font(.caption2)

                        // Show card type distribution
                        let cardTypes = Dictionary(grouping: viewModel.cards) { $0.type }
                        Text("Types:").font(.caption2).foregroundColor(.yellow)
                        ForEach(Array(cardTypes.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { type in
                            Text("  \(type.rawValue): \(cardTypes[type]?.count ?? 0)").font(.caption2)
                        }

                        // Show auth status
                        if let email = getUserEmail() {
                            Text("Auth: ✅ \(email)").font(.caption2).foregroundColor(.green)
                        } else {
                            Text("Auth: ❌ Not logged in").font(.caption2).foregroundColor(.red)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                    .padding(.leading, 8)
                    .padding(.bottom, 120)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Error banner from ActionRouter
            if ActionRouter.shared.showingError, let errorMessage = ActionRouter.shared.errorMessage {
                VStack {
                    ErrorBanner(
                        message: errorMessage,
                        type: .error,
                        dismissAction: {
                            ActionRouter.shared.showingError = false
                        }
                    )
                    .padding(.top, 36)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: ActionRouter.shared.showingError)
            }

        }
        .monitorNetworkStatus() // Show offline banner when disconnected
        // Archetype bottom sheet removed - now using inline toggle in bottom nav
        .sheet(item: $actionOptionsCard) { card in
            ActionSelectorBottomSheet(
                card: card,
                currentActionId: viewModel.getEffectiveAction(for: card),
                onActionSelected: { selectedAction in
                    Logger.info("User selected new action: \(selectedAction) for card: \(card.id)", category: .action)
                    viewModel.setCustomAction(for: card.id, action: selectedAction)
                    actionOptionsCard = nil
                },
                isPresented: Binding(
                    get: { actionOptionsCard != nil },
                    set: { if !$0 { actionOptionsCard = nil } }
                ),
                userContext: userContext
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showActionModal) {
            if let card = actionModalCard {
                getActionModalView(for: card)
                    .presentationBackground(ArchetypeConfig.config(for: card.type).gradient)
                    .presentationDragIndicator(.visible)
            } else {
                EmptyView()
                    .onAppear {
                        Logger.error("showActionModal triggered but actionModalCard is nil", category: .modal)
                    }
            }
        }
        .sheet(isPresented: $showEmailComposer) {
            if let card = emailComposerCard {
                EmailComposerModal(
                    card: card,
                    isPresented: $showEmailComposer,
                    attachmentName: signedDocumentName.map { "\($0)_signed.pdf" }
                )
                .presentationDragIndicator(.visible)
                .onAppear {
                    Logger.info("✅ EmailComposerModal appeared for card: \(card.id)", category: .modal)
                    if let attachment = signedDocumentName {
                        Logger.info("Attachment included: \(attachment)_signed.pdf", category: .modal)
                    }
                }
                .onDisappear {
                    Logger.info("EmailComposerModal dismissed", category: .modal)
                    // Clean up state
                    emailComposerCard = nil
                    signedDocumentName = nil
                }
            } else {
                // This should never happen, but log it if it does
                EmptyView()
                    .onAppear {
                        Logger.error("❌ BUG: EmailComposerModal sheet triggered but emailComposerCard is nil!", category: .modal)
                        showEmailComposer = false
                    }
            }
        }
        .onChange(of: showEmailComposer) { _, newValue in
            Logger.info("showEmailComposer changed to: \(newValue), emailComposerCard: \(emailComposerCard?.id ?? "nil")", category: .modal)
        }
        .sheet(isPresented: $showSnoozePicker) {
            SnoozePickerModal(
                isPresented: $showSnoozePicker,
                selectedDuration: $snoozeDuration
            ) {
                // Confirm snooze with selected duration and remember it
                if let card = snoozeCard {
                    viewModel.setRememberedSnoozeDuration(snoozeDuration)
                    viewModel.handleSwipe(direction: .down, card: card)
                    undoActionText = "Snoozed for \(snoozeDuration)h (will remember)"
                    showUndoToast = true
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert("Mark as Read?", isPresented: $showUrgentConfirmation) {
            Button("Cancel", role: .cancel) {
                // Card stays in place
            }
            Button("Mark as Read") {
                if let card = urgentConfirmCard {
                    viewModel.handleSwipe(direction: .left, card: card)
                    undoActionText = "Marked as Read"
                    showUndoToast = true
                }
            }
        } message: {
            if let card = urgentConfirmCard {
                Text("This urgent email from \(card.kid?.name ?? card.company?.name ?? card.sender?.name ?? "sender") will be marked as read. Are you sure?")
            }
        }
        .fullScreenCover(isPresented: $showSplayView) {
            SplayView(
                isPresented: $showSplayView,
                cards: viewModel.cards,
                archetype: viewModel.currentArchetype
            ) { selectedCard in
                // Jump to selected card
                if let index = viewModel.filteredCards.firstIndex(where: { $0.id == selectedCard.id }) {
                    viewModel.currentIndex = index
                }
            }
            .environmentObject(viewModel)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel, isPresented: $showSettings)
                .environmentObject(services)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShoppingCart) {
            ShoppingCartView()
                .presentationDragIndicator(.visible)
                .onDisappear {
                    // Refresh cart count when cart view closes
                    Task {
                        await loadCartItemCount()
                    }
                }
        }
        .sheet(isPresented: $showSearch) {
            SearchModal(viewModel: viewModel)
        }
        .sheet(item: $selectedThreadCard) { card in
            // Convert EmailCard to SearchResult for EmailThreadView
            if let threadData = card.threadData, !threadData.messages.isEmpty {
                // Convert ThreadData to SearchResult
                let searchResult = SearchResult(
                    threadId: card.id,
                    messageCount: threadData.messageCount,
                    latestEmail: SearchEmailPreview(
                        id: card.id,
                        type: card.type,
                        state: card.state,
                        priority: card.priority,
                        hpa: card.hpa,
                        timeAgo: card.timeAgo,
                        title: card.title,
                        summary: card.summary,
                        sender: card.sender,
                        threadLength: card.threadLength ?? threadData.messageCount
                    ),
                    allMessages: threadData.messages.map { msg in
                        SearchMessagePreview(
                            id: msg.id,
                            type: card.type,
                            state: card.state,
                            priority: card.priority,
                            hpa: card.hpa,
                            timeAgo: msg.date,
                            title: card.title,
                            summary: String(msg.body.prefix(200)),
                            sender: card.sender,
                            threadLength: threadData.messageCount
                        )
                    }
                )
                EmailThreadView(thread: searchResult)
            } else {
                // If no thread data, show the single email in EmailDetailView
                EmailDetailView(card: card)
            }
        }
        .sheet(isPresented: $showSaveSnoozeMenu) {
            if let card = saveSnoozeMenuCard {
                SaveSnoozeMenuView(
                    card: card,
                    isPresented: $showSaveSnoozeMenu,
                    onSaveToFolder: {
                        // Open folder picker
                        folderPickerCard = card
                        showFolderPicker = true
                    },
                    onSnooze: {
                        // Handle snooze based on user preference
                        snoozeCard = card
                        if viewModel.hasSetSnoozeDuration, let duration = viewModel.rememberedSnoozeDuration {
                            viewModel.handleSwipe(direction: .down, card: card)
                            undoActionText = "Snoozed for \(duration)h"
                            showUndoToast = true
                        } else {
                            showSnoozePicker = true
                        }
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showFolderPicker) {
            if let card = folderPickerCard {
                FolderPickerView(
                    card: card,
                    isPresented: $showFolderPicker
                )
            }
        }
        .sheet(isPresented: $showSavedMail) {
            SavedMailListView(isPresented: $showSavedMail)
                .environmentObject(viewModel)
        }
        .task {
            // Load initial cart count
            await loadCartItemCount()
        }
        .onAppear {
            // Load cards when mainFeedView appears (after onboarding completes)
            Logger.info("mainFeedView appeared, loading cards...", category: .app)
            viewModel.loadCards()
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
            // Legacy card with v1.0 hpa-based routing
            let destination = ModalRouter.route(card: card, selectedActionId: selectedActionId)
            modalRouterView(for: destination)
                .onAppear {
                    Logger.info("🔀 Using ModalRouter (legacy) for card: \(card.id), hpa: \(card.hpa)", category: .action)
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
        if let selectedId = selectedActionId,
           let selectedAction = suggestedActions.first(where: { $0.actionId == selectedId }) {
            // Defer state modification to avoid "modifying state during view update" warning
            DispatchQueue.main.async {
                self.selectedActionId = nil  // Clear after use
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

    // MARK: - ActionRouter Modal Views (v1.1)

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
                        showActionModal = false
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
                        showActionModal = false
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
                isPresented: $showActionModal
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
                    isPresented: $showActionModal,
                    onSignComplete: { signatureName in
                        signedDocumentName = signatureName
                        emailComposerCard = card
                        Logger.info("Signature saved: \(signatureName)", category: .modal)

                        showActionModal = false
                        Logger.info("SignFormModal dismissed, scheduling EmailComposer", category: .modal)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            if !showActionModal {
                                Logger.info("Opening EmailComposer modal for card: \(card.id)", category: .modal)
                                showEmailComposer = true
                            } else {
                                Logger.warning("SignFormModal still visible, retrying EmailComposer", category: .modal)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showEmailComposer = true
                                }
                            }
                        }
                    }
                )

            case "add_to_calendar":
                AddToCalendarModal(card: card, isPresented: $showActionModal)

            case "view_newsletter_summary":
                if let context = action.context {
                    NewsletterSummaryModal(
                        card: card,
                        context: context,
                        isPresented: $showActionModal
                    )
                } else {
                    NewsletterSummaryModal(
                        card: card,
                        context: [:],
                        isPresented: $showActionModal
                    )
                }

            case "schedule_purchase":
                if let scheduleAction = card.suggestedActions?.first(where: { $0.actionId == "schedule_purchase" }) {
                    ScheduledPurchaseModal(card: card, action: scheduleAction, isPresented: $showActionModal)
                } else {
                    EmailComposerModal(card: card, isPresented: $showActionModal)
                        .onAppear {
                            Logger.warning("schedule_purchase action not found in suggestedActions", category: .action)
                        }
                }

            case "view_details":
                // Generic view details action - show full email detail view
                EmailDetailView(card: card)

            case "browse_shopping", "claim_deal", "save_deal":
                ShoppingPurchaseModal(card: card, isPresented: $showActionModal, selectedAction: action.actionId)
                    .environmentObject(viewModel)

            case "schedule_meeting", "schedule_demo", "schedule_call":
                ScheduleMeetingModal(card: card, isPresented: $showActionModal, onComplete: {})

            case "review_document", "approve_document", "view_document":
                // PRIORITY: If email requires signature, use SignFormModal instead
                // Otherwise, show DocumentViewerModal for real documents or EmailDetailView as fallback
                if card.requiresSignature == true {
                    // Signature request takes priority - use sign & send flow
                    SignFormModal(
                        card: card,
                        isPresented: $showActionModal,
                        onSignComplete: { signatureName in
                            signedDocumentName = signatureName
                            emailComposerCard = card
                            Logger.info("Signature saved: \(signatureName)", category: .modal)

                            showActionModal = false
                            Logger.info("SignFormModal dismissed, scheduling EmailComposer", category: .modal)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                if !showActionModal {
                                    Logger.info("Opening EmailComposer modal for card: \(card.id)", category: .modal)
                                    showEmailComposer = true
                                } else {
                                    Logger.warning("SignFormModal still visible, retrying EmailComposer", category: .modal)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        showEmailComposer = true
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
                    DocumentViewerModal(card: card, isPresented: $showActionModal)
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
                SpreadsheetViewerModal(card: card, isPresented: $showActionModal)

            case "open_app":
                OpenAppModal(card: card, isPresented: $showActionModal)

            case "archive", "save_later", "snooze":
                SnoozePickerModal(
                    isPresented: $showActionModal,
                    selectedDuration: $snoozeDuration
                ) {
                    if let card = actionModalCard {
                        viewModel.setRememberedSnoozeDuration(snoozeDuration)
                        viewModel.handleSwipe(direction: .down, card: card)
                        undoActionText = "Snoozed for \(snoozeDuration)h"
                        showUndoToast = true
                        showActionModal = false
                    }
                }

            case "reply", "quick_reply", "respond":
                EmailComposerModal(
                    card: card,
                    isPresented: $showActionModal,
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
                        isPresented: $showActionModal
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $showActionModal)
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
                        isPresented: $showActionModal
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $showActionModal)
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
                        isPresented: $showActionModal
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $showActionModal)
                        .onAppear {
                            Logger.warning("check_in_flight missing context", category: .action)
                        }
                }

            case "cancel_subscription":
                CancelSubscriptionModal(card: card) {
                    showActionModal = false
                }
                .onAppear {
                    Logger.info("🚫 Opening cancel subscription modal for: \(card.company?.name ?? "service")", category: .action)
                }

            case "unsubscribe":
                if let context = action.context, let unsubscribeUrl = context["unsubscribeUrl"] {
                    UnsubscribeModal(
                        card: card,
                        unsubscribeUrl: unsubscribeUrl,
                        isPresented: $showActionModal,
                        onUnsubscribeComplete: {
                            Logger.info("✅ Unsubscribe completed for: \(card.company?.name ?? card.sender?.name ?? "sender")", category: .action)
                        }
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $showActionModal)
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
                        isPresented: $showActionModal
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $showActionModal)
                        .onAppear {
                            Logger.warning("write_review missing context", category: .action)
                        }
                }

            case "contact_driver":
                if let context = action.context {
                    ContactDriverModal(
                        card: card,
                        driverInfo: context,
                        isPresented: $showActionModal
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $showActionModal)
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
                        isPresented: $showActionModal
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $showActionModal)
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
                                showActionModal = false
                            }
                        }
                } else {
                    EmailComposerModal(card: card, isPresented: $showActionModal)
                        .onAppear {
                            Logger.warning("copy_promo_code missing code in context", category: .action)
                        }
                }

            // Native iOS Integrations
            case "add_to_wallet":
                AddToWalletModal(card: card, isPresented: $showActionModal)

            case "add_reminder", "set_reminder", "remind":
                AddReminderModal(card: card, isPresented: $showActionModal)

            case "save_contact_native":
                SaveContactModal(card: card, isPresented: $showActionModal)

            case "send_message":
                SendMessageModal(card: card, isPresented: $showActionModal)

            case "share":
                if let context = action.context {
                    let shareContent = generateShareContentForModal(from: card, context: context)
                    ShareModal(card: card, content: shareContent, isPresented: $showActionModal)
                } else {
                    let shareContent = generateShareContentForModal(from: card, context: [:])
                    ShareModal(card: card, content: shareContent, isPresented: $showActionModal)
                }

            case "view_reservation", "modify_reservation":
                if let context = action.context {
                    // Pass context directly (already [String: String])
                    ReservationModal(
                        card: card,
                        context: context,
                        isPresented: $showActionModal
                    )
                } else {
                    EmailComposerModal(card: card, isPresented: $showActionModal)
                        .onAppear {
                            Logger.warning("view_reservation missing context", category: .action)
                        }
                }

            default:
                // Generic fallback for unmapped IN_APP actions
                EmailComposerModal(card: card, isPresented: $showActionModal)
                    .onAppear {
                        Logger.warning("⚠️ Unmapped IN_APP action: \(action.actionId), falling back to EmailComposer", category: .action)
                    }
            }
        }
    }

    // MARK: - ModalRouter Views (Legacy v1.0)

    @ViewBuilder
    private func modalRouterView(for destination: ModalRouter.ModalDestination) -> some View {
        switch destination {
        case .documentViewer(let card):
            DocumentViewerModal(card: card, isPresented: $showActionModal)
            
        case .spreadsheetViewer(let card):
            SpreadsheetViewerModal(card: card, isPresented: $showActionModal)
            
        case .scheduleMeeting(let card):
            ScheduleMeetingModal(card: card, isPresented: $showActionModal, onComplete: {})
            
        case .emailComposer(let card, let recipient, let subject):
            EmailComposerModal(
                card: card,
                isPresented: $showActionModal,
                recipientOverride: recipient,
                subjectOverride: subject
            )
            
        case .signForm(let card, _):
            SignFormModal(
                card: card,
                isPresented: $showActionModal,
                onSignComplete: { signatureName in
                    signedDocumentName = signatureName
                    emailComposerCard = card
                    Logger.info("Signature saved: \(signatureName)", category: .modal)
                    
                    // IMPORTANT: First ensure the sign modal is fully dismissed
                    // Then wait for animation to complete before showing email composer
                    showActionModal = false
                    
                    Logger.info("SignFormModal dismissed, scheduling EmailComposer", category: .modal)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        // Double-check modal is dismissed
                        if !showActionModal {
                            Logger.info("Opening EmailComposer modal for card: \(card.id)", category: .modal)
                            showEmailComposer = true
                        } else {
                            Logger.warning("SignFormModal still visible, delaying EmailComposer", category: .modal)
                            // Retry after another delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showEmailComposer = true
                            }
                        }
                    }
                }
            )
            
        case .openApp(let card):
            OpenAppModal(card: card, isPresented: $showActionModal)

        case .openURL(let url):
            // Open URL in Safari (legacy - no context available)
            if let validUrl = URL(string: url) {
                SafariViewWrapper(url: validUrl, onDismiss: {
                    showActionModal = false
                })
            } else {
                // Invalid URL - show error and close modal
                Text("Invalid URL")
                    .onAppear {
                        Logger.error("Invalid URL provided to openURL: \(url)", category: .modal)
                        showActionModal = false
                    }
            }

        case .addToCalendar(let card):
            AddToCalendarModal(card: card, isPresented: $showActionModal)
            
        case .scheduledPurchase(let card, let action):
            ScheduledPurchaseModal(card: card, action: action, isPresented: $showActionModal)

        case .shoppingPurchase(let card, let selectedAction):
            ShoppingPurchaseModal(card: card, isPresented: $showActionModal, selectedAction: selectedAction)
                .environmentObject(viewModel)

        case .snoozePicker(_):
            SnoozePickerModal(
                isPresented: $showActionModal,
                selectedDuration: $snoozeDuration
            ) {
                if let card = actionModalCard {
                    viewModel.setRememberedSnoozeDuration(snoozeDuration)
                    viewModel.handleSwipe(direction: .down, card: card)
                    undoActionText = "Filed for \(snoozeDuration)h"
                    showUndoToast = true
                    showActionModal = false
                }
            }
            
        case .saveForLater(let card):
            SaveForLaterModal(card: card, isPresented: $showActionModal)
                .environmentObject(viewModel)

        case .viewAttachments(let card):
            AttachmentViewerModal(card: card, isPresented: $showActionModal)

        case .fallback(let card):
            EmailComposerModal(card: card, isPresented: $showActionModal)
        }
    }
    
    func getSwipeDirection(isHorizontal: Bool, dragOffset: CGSize) -> SwipeDirection {
        if isHorizontal {
            return dragOffset.width > 0 ? .right : .left
        } else {
            return .down
        }
    }
    
    func checkAllArchetypesCleared() -> Bool {
        // Check if ALL selected archetypes have zero unseen cards
        return viewModel.selectedArchetypes.allSatisfy { archetype in
            let archetypeCards = viewModel.cards.filter { $0.type == archetype && $0.state == .unseen }
            return archetypeCards.isEmpty
        }
    }

    func getUserEmail() -> String? {
        // Check if using mock data
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")
        if useMockData {
            return nil // Mock mode, don't show email
        }

        // Try to get email from Keychain (from authenticated session)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "EmailShortForm",
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let attributes = result as? [String: Any],
           let emailData = attributes[kSecAttrAccount as String] as? String {
            return emailData
        }

        return nil
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

    // MARK: - URL Extraction Helpers

    /// Extract URL from context with multiple fallback keys
    /// Handles inconsistent key names across different action types
    private func extractURL(from context: [String: String], actionId: String) -> String? {
        // Priority order: try all common URL key variations
        let urlKeys = [
            "url",            // Generic (preferred standard)
            "trackingUrl",    // track_package, track_delivery
            "invoiceUrl",     // pay_invoice, view_invoice
            "checkInUrl",     // check_in_flight, check_in_appointment
            "productUrl",     // Shopping actions (view_product, browse_shopping)
            "dealUrl",        // Shopping deals
            "itemUrl",        // Shopping items
            "productLink",    // Alt shopping key
            "dealLink",       // Alt deal key
            "shopUrl",        // Generic shopping
            "proposalUrl",    // view_proposal
            "meetingUrl",     // join_meeting
            "reservationUrl", // view_reservation, modify_reservation
            "itineraryUrl",   // view_itinerary
            "taskUrl",        // view_task
            "incidentUrl",    // view_incident
            "registrationUrl", // register_event
            "surveyUrl",      // take_survey
            "resetUrl",       // reset_password
            "verifyUrl",      // verify_account, verify_device
            "securityUrl",    // review_security
            "revokeUrl",      // revoke_secret
            "resultsUrl",     // view_results
            "supportUrl",     // contact_support
            "ticketUrl",      // view_ticket
            "bookingUrl",     // manage_booking
            "cartUrl",        // complete_cart, view_cart
            "link",           // Generic link
            "href"            // HTML-style link
        ]

        // Try each key in priority order
        for key in urlKeys {
            if let url = context[key], !url.isEmpty {
                Logger.info("✅ Found URL for \(actionId) using key: \(key) = \(url)", category: .action)
                return url
            }
        }

        // URL not found - log available keys and values for debugging
        let availableKeys = context.keys.sorted().joined(separator: ", ")
        let contextDetails = context.map { "\($0.key)=\($0.value.prefix(50))..." }.joined(separator: " | ")
        Logger.warning("❌ URL not found for \(actionId). Available context keys: [\(availableKeys)]", category: .action)
        Logger.warning("Context values: \(contextDetails)", category: .action)
        return nil
    }

    /// Validate URL format and scheme to prevent crashes
    private func validateURL(_ urlString: String) -> URL? {
        // Trim whitespace and newlines
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if URL string is empty
        guard !trimmed.isEmpty else {
            Logger.error("URL validation failed: empty string", category: .action)
            return nil
        }

        // Try to create URL object
        guard let url = URL(string: trimmed) else {
            Logger.error("URL validation failed: invalid format '\(trimmed)'", category: .action)
            return nil
        }

        // Validate scheme exists and is http/https
        guard let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else {
            Logger.error("URL validation failed: invalid or missing scheme in '\(trimmed)'", category: .action)
            return nil
        }

        // Validate host exists
        guard url.host != nil else {
            Logger.error("URL validation failed: missing host in '\(trimmed)'", category: .action)
            return nil
        }

        Logger.info("✅ URL validated successfully: \(url.absoluteString)", category: .action)
        return url
    }

    /// Generate shareable content from email card and context
    private func generateShareContentForModal(from card: EmailCard, context: [String: Any]) -> String {
        var content = card.title

        // Add summary if available
        if !card.summary.isEmpty {
            content += "\n\n\(card.summary)"
        }

        // Add tracking number if in context
        if let trackingNumber = context["trackingNumber"] as? String {
            content += "\n\nTracking: \(trackingNumber)"
        }

        // Add confirmation code if in context
        if let confirmationCode = context["confirmationCode"] as? String {
            content += "\n\nConfirmation: \(confirmationCode)"
        }

        // Add URL if in context
        if let url = context["url"] as? String {
            content += "\n\n\(url)"
        }

        return content
    }

    // MARK: - Shopping Cart Helpers
    func loadCartItemCount() async {
        do {
            let summary = try await ShoppingCartService.shared.getCartSummary(userId: userId)
            await MainActor.run {
                cartItemCount = summary.itemCount
                Logger.info("Updated cart badge: \(cartItemCount) items", category: .shopping)
            }
        } catch {
            // Silently fail - cart badge just won't update
            Logger.warning("Failed to load cart count: \(error.localizedDescription)", category: .shopping)
        }
    }
}
