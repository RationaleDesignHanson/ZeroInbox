import SwiftUI

/**
 * MainFeedView
 * Main email feed interface with card stack, navigation, and modals
 *
 * Extracted from ContentView Phase 2.2 to reduce complexity
 * Before: 2234 lines ContentView with embedded 378-line computed property
 * After: Standalone view with clear dependencies
 */
struct MainFeedView: View {

    // MARK: - Dependencies

    @ObservedObject var viewModel: EmailViewModel
    @ObservedObject var viewState: ContentViewState
    @EnvironmentObject var services: ServiceContainer

    let navState: NavigationState
    let userContext: UserContext
    let hasMultipleAccounts: Bool

    // Closures for parent-provided functionality
    let loadCartItemCount: () async -> Void
    let getUserEmail: () -> String?
    let getActionModalView: (EmailCard) -> AnyView

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dynamic background based on current section
            if viewModel.currentArchetype == .mail {
                // Purple firefly background for Mail
                FireflyBackground()
            } else {
                // Green springy background for Ads
                ScenicBackground(animationPhase: 0.5)
                    .ignoresSafeArea()
            }

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
                .padding(.bottom, 100) // Clearance for floating island nav
            } else {
                // Card stack with swipe gestures - centered vertically like web demo
                VStack(spacing: 0) {
                    Spacer()  // Equal weight spacer for vertical centering

                    ZStack(alignment: .bottom) {
                        CardStackView(
                            viewModel: viewModel,
                            dragOffset: $viewState.dragOffset,
                            actionModalCard: $viewState.actionModalCard,
                            showActionModal: $viewState.showActionModal,
                            actionOptionsCard: $viewState.actionOptionsCard,
                            selectedActionId: $viewState.selectedActionId,
                            undoActionText: $viewState.undoActionText,
                            showUndoToast: $viewState.showUndoToast,
                            snoozeCard: $viewState.snoozeCard,
                            showSnoozePicker: $viewState.showSnoozePicker,
                            urgentConfirmCard: $viewState.urgentConfirmCard,
                            showUrgentConfirmation: $viewState.showUrgentConfirmation,
                            selectedThreadCard: $viewState.selectedThreadCard,
                            saveSnoozeMenuCard: $viewState.saveSnoozeMenuCard,
                            showSaveSnoozeMenu: $viewState.showSaveSnoozeMenu,
                            folderPickerCard: $viewState.folderPickerCard,
                            showFolderPicker: $viewState.showFolderPicker,
                            hasMultipleAccounts: hasMultipleAccounts
                        )
                        .environmentObject(navState)

                        // Undo toast at bottom of card (not screen)
                        if viewState.showUndoToast {
                            UndoToast(
                                action: viewState.undoActionText,
                                onUndo: {
                                    viewModel.undoLastAction()
                                    viewState.showUndoToast = false
                                },
                                onDismiss: {
                                    viewState.showUndoToast = false
                                }
                            )
                            .padding(.bottom, 15)
                            .zIndex(999)
                        }
                    }

                    Spacer()
                }
                .padding(.bottom, 80) // Match web demo nav clearance
            }

            // Bottom Navigation Bar - Liquid Glass Design (pinned to bottom, matching web demo)
            VStack {
                Spacer()
                let mailCount = viewModel.cards.filter { $0.type == .mail && $0.state == .unseen }.count
                let adsCount = viewModel.cards.filter { $0.type == .ads && $0.state == .unseen }.count
                let _ = Logger.info("📊 Counter Update: Total cards=\(viewModel.cards.count), Mail (unseen)=\(mailCount), Ads (unseen)=\(adsCount)", category: .ui)
                LiquidGlassBottomNav(
                    viewModel: viewModel,
                    showShoppingCart: $viewState.showShoppingCart,
                    showSettings: $viewState.showSettings,
                    showSearch: $viewState.showSearch,
                    cartItemCount: viewState.cartItemCount,
                    mailCount: mailCount,
                    adsCount: adsCount,
                    totalInitialCards: viewState.totalInitialCards,
                    onRefresh: {
                        await viewModel.refreshEmails()
                    }
                )
                .edgesIgnoringSafeArea(.bottom)  // Match web demo positioning at absolute bottom
            }

            // Debug overlay (toggleable from settings or feature flags)
            if services.featureGating.isEnabled(.debugOverlays) {
                debugOverlay
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
        .sheet(item: $viewState.actionOptionsCard) { card in
            ActionSelectorBottomSheet(
                card: card,
                currentActionId: viewModel.getEffectiveAction(for: card),
                onActionSelected: { selectedAction in
                    Logger.info("User selected new action: \(selectedAction) for card: \(card.id)", category: .action)
                    viewModel.setCustomAction(for: card.id, action: selectedAction)
                    viewState.actionOptionsCard = nil
                },
                userContext: userContext
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewState.showActionModal) {
            if let card = viewState.actionModalCard {
                getActionModalView(card)
                    .presentationBackground(ArchetypeConfig.config(for: card.type).gradient)
                    .presentationDragIndicator(.visible)
            } else {
                EmptyView()
                    .onAppear {
                        Logger.error("viewState.showActionModal triggered but viewState.actionModalCard is nil", category: .modal)
                    }
            }
        }
        .sheet(isPresented: $viewState.showEmailComposer) {
            if let card = viewState.emailComposerCard {
                EmailComposerModal(
                    card: card,
                    isPresented: $viewState.showEmailComposer,
                    attachmentName: viewState.signedDocumentName.map { "\($0)_signed.pdf" }
                )
                .presentationDragIndicator(.visible)
                .onAppear {
                    Logger.info("✅ EmailComposerModal appeared for card: \(card.id)", category: .modal)
                    if let attachment = viewState.signedDocumentName {
                        Logger.info("Attachment included: \(attachment)_signed.pdf", category: .modal)
                    }
                }
                .onDisappear {
                    Logger.info("EmailComposerModal dismissed", category: .modal)
                    // Clean up state
                    viewState.emailComposerCard = nil
                    viewState.signedDocumentName = nil
                }
            } else {
                // This should never happen, but log it if it does
                EmptyView()
                    .onAppear {
                        Logger.error("❌ BUG: EmailComposerModal sheet triggered but viewState.emailComposerCard is nil!", category: .modal)
                        viewState.showEmailComposer = false
                    }
            }
        }
        .onChange(of: viewState.showEmailComposer) { _, newValue in
            Logger.info("viewState.showEmailComposer changed to: \(newValue), viewState.emailComposerCard: \(viewState.emailComposerCard?.id ?? "nil")", category: .modal)
        }
        .sheet(isPresented: $viewState.showSnoozePicker) {
            SnoozePickerModal(
                isPresented: $viewState.showSnoozePicker,
                selectedDuration: $viewState.snoozeDuration
            ) {
                // Confirm snooze with selected duration and remember it
                if let card = viewState.snoozeCard {
                    viewModel.setRememberedSnoozeDuration(viewState.snoozeDuration)
                    viewModel.handleSwipe(direction: .down, card: card)
                    viewState.undoActionText = "Snoozed for \(viewState.snoozeDuration)h (will remember)"
                    viewState.showUndoToast = true
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert("Mark as Read?", isPresented: $viewState.showUrgentConfirmation) {
            Button("Cancel", role: .cancel) {
                // Card stays in place
            }
            Button("Mark as Read") {
                if let card = viewState.urgentConfirmCard {
                    viewModel.handleSwipe(direction: .left, card: card)
                    viewState.undoActionText = "Marked as Read"
                    viewState.showUndoToast = true
                }
            }
        } message: {
            if let card = viewState.urgentConfirmCard {
                Text("This urgent email from \(card.kid?.name ?? card.company?.name ?? card.sender?.name ?? "sender") will be marked as read. Are you sure?")
            }
        }
        .fullScreenCover(isPresented: $viewState.showSplayView) {
            SplayView(
                isPresented: $viewState.showSplayView,
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
        .sheet(isPresented: $viewState.showSettings) {
            SettingsView(viewModel: viewModel, isPresented: $viewState.showSettings)
                .environmentObject(services)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewState.showShoppingCart) {
            ShoppingCartView()
                .presentationDragIndicator(.visible)
                .onDisappear {
                    // Refresh cart count when cart view closes
                    Task {
                        await loadCartItemCount()
                    }
                }
        }
        .sheet(isPresented: $viewState.showSearch) {
            SearchModal(viewModel: viewModel)
        }
        .sheet(item: $viewState.selectedThreadCard) { card in
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
        .sheet(isPresented: $viewState.showSaveSnoozeMenu) {
            if let card = viewState.saveSnoozeMenuCard {
                SaveSnoozeMenuView(
                    card: card,
                    isPresented: $viewState.showSaveSnoozeMenu,
                    onSaveToFolder: {
                        // Open folder picker
                        viewState.folderPickerCard = card
                        viewState.showFolderPicker = true
                    },
                    onSnooze: {
                        // Handle snooze based on user preference
                        viewState.snoozeCard = card
                        if viewModel.hasSetSnoozeDuration, let duration = viewModel.rememberedSnoozeDuration {
                            viewModel.handleSwipe(direction: .down, card: card)
                            viewState.undoActionText = "Snoozed for \(duration)h"
                            viewState.showUndoToast = true
                        } else {
                            viewState.showSnoozePicker = true
                        }
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $viewState.showFolderPicker) {
            if let card = viewState.folderPickerCard {
                FolderPickerView(
                    card: card,
                    isPresented: $viewState.showFolderPicker
                )
            }
        }
        .sheet(isPresented: $viewState.showSavedMail) {
            SavedMailListView(isPresented: $viewState.showSavedMail)
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

    // MARK: - Subviews

    private var debugOverlay: some View {
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
            .padding(DesignTokens.Spacing.inline)
            .background(Color.black.opacity(DesignTokens.Opacity.textTertiary))
            .cornerRadius(DesignTokens.Radius.chip)
            .padding(.leading, DesignTokens.Spacing.inline)
            .padding(.bottom, 120)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func loadingView(isClassifying: Bool) -> some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.5)

            Text(isClassifying ? "Classifying emails..." : "Loading emails...")
                .font(.headline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
        }
    }
}

