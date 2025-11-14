import SwiftUI

/// Card stack view with swipe gesture handling
/// Extracted from ContentView for better organization and testability
/// Scales down when bottom nav expands to make room for actions
struct CardStackView: View {
    @ObservedObject var viewModel: EmailViewModel
    @Binding var dragOffset: CGSize
    @Binding var actionModalCard: EmailCard?
    @Binding var showActionModal: Bool
    @Binding var actionOptionsCard: EmailCard?
    @Binding var selectedActionId: String?
    @Binding var undoActionText: String
    @Binding var showUndoToast: Bool
    @Binding var snoozeCard: EmailCard?
    @Binding var showSnoozePicker: Bool
    @Binding var urgentConfirmCard: EmailCard?
    @Binding var showUrgentConfirmation: Bool
    @Binding var selectedThreadCard: EmailCard?
    @Binding var saveSnoozeMenuCard: EmailCard?
    @Binding var showSaveSnoozeMenu: Bool
    @Binding var folderPickerCard: EmailCard?
    @Binding var showFolderPicker: Bool
    var hasMultipleAccounts: Bool = false

    @EnvironmentObject var navState: NavigationState

    // Scaling state for nav expansion
    @State private var cardStackScale: CGFloat = 1.0
    @State private var cardStackOpacity: Double = 1.0
    @State private var cardStackYOffset: CGFloat = 0
    @State private var swipesDisabled: Bool = false
    
    var body: some View {
        ZStack {
            // Empty state when no cards
            if viewModel.filteredCards.isEmpty {
                EmptyInboxView()
            } else {
                // Card stack
                cardStackContent
            }

            // Loading overlay (shows on top of everything)
            if viewModel.isLoadingRealEmails {
                LoadingOverlayView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 600)  // Constrain card height for better nav clearance
        .scaleEffect(cardStackScale)
        .opacity(cardStackOpacity)
        .offset(y: cardStackYOffset)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: cardStackScale)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: cardStackOpacity)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: cardStackYOffset)
        .onChange(of: navState.actionsExpanded) { _, expanded in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if expanded {
                    // Quick actions open - scale down stack
                    cardStackScale = 0.73
                    cardStackYOffset = -20
                    cardStackOpacity = 0.9
                    swipesDisabled = true
                } else {
                    // Collapsed - full size
                    cardStackScale = 1.0
                    cardStackYOffset = 0
                    cardStackOpacity = 1.0
                    swipesDisabled = false
                }
            }
        }
        .onChange(of: navState.sheetPresented) { _, presented in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if presented {
                    // Sheet open - dim only, no scaling
                    cardStackOpacity = 0.7
                    swipesDisabled = true
                } else if !navState.actionsExpanded {
                    // Sheet closed and actions not expanded - restore
                    cardStackOpacity = 1.0
                    swipesDisabled = false
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// Returns only the cards that need to be rendered (current + next 4)
    /// This dramatically improves performance for large inboxes
    private var visibleCards: [EmailCard] {
        let currentIdx = viewModel.currentIndex
        let allCards = viewModel.filteredCards

        guard currentIdx < allCards.count else {
            return []
        }

        // Render current card + 4 ahead (5 total)
        let endIndex = min(currentIdx + 5, allCards.count)
        return Array(allCards[currentIdx..<endIndex])
    }

    // MARK: - Card Stack Content

    private var cardStackContent: some View {
        ZStack {
            // Performance optimization: Only render cards near the current index
            // Render current card + 4 cards ahead (total 5 visible cards)
            ForEach(visibleCards, id: \.id) { card in
                // Find the actual index in the full cards array
                if let actualIndex = viewModel.filteredCards.firstIndex(where: { $0.id == card.id }) {
                    let offset = actualIndex - viewModel.currentIndex
                    let isTopCard = actualIndex == viewModel.currentIndex

                    renderCard(card: card, actualIndex: actualIndex, offset: offset, isTopCard: isTopCard)
                }
            }
        }
    }

    @ViewBuilder
    private func renderCard(card: EmailCard, actualIndex: Int, offset: Int, isTopCard: Bool) -> some View {
        let horizontal = abs(dragOffset.width)
        let vertical = abs(dragOffset.height)
        let isHorizontal = horizontal > vertical
        let swipeDistance = isHorizontal ? horizontal : vertical
        let revealProgress = isTopCard ? min(swipeDistance / 200.0, 1.0) : 0.0

        ZStack {
            SimpleCardView(
                card: card,
                isTopCard: isTopCard,
                revealProgress: revealProgress,
                onSignatureTap: {
                    actionModalCard = card
                    showActionModal = true
                },
                onThreadTap: {
                    selectedThreadCard = card
                    Logger.info("Thread indicator tapped for card: \(card.id)", category: .ui)
                },
                viewModel: viewModel,
                isSaved: viewModel.isSaved(cardId: card.id),
                hasMultipleAccounts: hasMultipleAccounts,
                cardIndex: actualIndex
            )

            // Swipe action overlay (for all 3 directions)
            if isTopCard && swipeDistance > 50 {
                SwipeOverlay(
                    direction: getSwipeDirection(isHorizontal: isHorizontal, dragOffset: dragOffset),
                    distance: swipeDistance
                )
                .frame(width: Constants.UI.cardWidth, height: Constants.UI.cardHeight)
                .cornerRadius(DesignTokens.Radius.modal)
            }
        }
        .offset(y: CGFloat(offset) * Constants.UI.cardStackOffset)
        .scaleEffect(1 - (CGFloat(abs(offset)) * Constants.UI.cardStackScale))
        .zIndex(Double(viewModel.filteredCards.count - abs(offset)))
        .opacity(abs(offset) > 2 ? 0 : 1)
        .animation(
            .spring(
                response: Constants.UI.Animation.springResponse,
                dampingFraction: Constants.UI.Animation.springDamping,
                blendDuration: Constants.UI.Animation.springBlend
            ),
            value: offset
        )
        .offset(isTopCard ? dragOffset : .zero)
        .rotation3DEffect(
            .degrees(isTopCard ? Double(dragOffset.width / 30) : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.interactiveSpring(), value: dragOffset)
        .gesture(
            (isTopCard && !swipesDisabled) ? DragGesture()
                .onChanged { value in
                    handleDragChanged(value)
                }
                .onEnded { value in
                    handleDragEnded(value, card: card)
                }
            : nil
        )
    }

    // MARK: - Gesture Handlers
    
    /// Handle drag gesture change
    private func handleDragChanged(_ value: DragGesture.Value) {
        dragOffset = value.translation
        
        // Determine primary swipe direction
        let horizontal = abs(value.translation.width)
        let vertical = abs(value.translation.height)
        let isHorizontal = horizontal > vertical
        let distance = isHorizontal ? horizontal : vertical
        let previousDistance = isHorizontal ? abs(dragOffset.width) : abs(dragOffset.height)
        
        // Haptic feedback at threshold
        if distance > Constants.UI.swipeHapticThreshold && previousDistance <= Constants.UI.swipeHapticThreshold {
            HapticService.shared.mediumImpact()
        }
    }
    
    /// Handle drag gesture end
    private func handleDragEnded(_ value: DragGesture.Value, card: EmailCard) {
        let horizontal = abs(value.translation.width)
        let vertical = abs(value.translation.height)
        let isHorizontal = horizontal > vertical
        let distance = isHorizontal ? horizontal : vertical
        
        if distance > Constants.UI.swipeThreshold {
            // Determine swipe direction
            let direction: SwipeDirection
            if isHorizontal {
                direction = value.translation.width > 0 ? .right : .left
            } else {
                // Distinguish UP vs DOWN for vertical swipes
                if value.translation.height < 0 {
                    // Flick UP - show action selector
                    actionOptionsCard = card
                    dragOffset = .zero
                    HapticService.shared.mediumImpact()
                    return
                } else {
                    direction = .down // Swipe down = snooze
                }
            }

            // Animate card off screen
            withAnimation(
                .spring(
                    response: Constants.UI.Animation.springResponse,
                    dampingFraction: 0.75,
                    blendDuration: Constants.UI.Animation.springBlend
                )
            ) {
                if direction == .down {
                    dragOffset = CGSize(width: 0, height: 600)
                } else {
                    dragOffset = CGSize(
                        width: value.translation.width > 0 ? 600 : -600,
                        height: value.translation.height * 0.3
                    )
                }
            }

            // Handle swipe after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(
                    .spring(
                        response: Constants.UI.Animation.springResponse,
                        dampingFraction: Constants.UI.Animation.springDamping
                    )
                ) {
                    handleSwipeAction(direction: direction, card: card)
                    dragOffset = .zero
                }
            }

            // Strong haptic on successful swipe
            HapticService.shared.heavyImpact()
        } else {
            // Snap back with smooth, bouncy spring
            withAnimation(
                .spring(
                    response: Constants.UI.Animation.snapbackResponse,
                    dampingFraction: Constants.UI.Animation.snapbackDamping,
                    blendDuration: Constants.UI.Animation.snapbackBlend
                )
            ) {
                dragOffset = .zero
            }
        }
    }
    
    /// Handle the actual swipe action (left, right, down, up)
    private func handleSwipeAction(direction: SwipeDirection, card: EmailCard) {
        switch direction {
        case .left:
            handleLeftSwipe(card: card)
        case .right:
            handleRightSwipe(card: card)
        case .down:
            handleDownSwipe(card: card)
        case .up:
            // Swipe up is handled in handleDragEnded (shows action selector)
            // This case should never be reached, but required for exhaustive switch
            break
        }

        // Check if we've finished this group and need to advance
        checkAndAdvanceIfEmpty()
    }

    /// Check if current archetype/group is empty and auto-advance to next with cards
    private func checkAndAdvanceIfEmpty() {
        // Wait a brief moment for state to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.viewModel.filteredCards.isEmpty {
                Logger.info("Current group empty, auto-advancing to next", category: .ui)
                self.viewModel.switchToNextArchetype()
            }
        }
    }
    
    /// Handle left swipe (mark as read)
    private func handleLeftSwipe(card: EmailCard) {
        if card.urgent == true {
            urgentConfirmCard = card
            showUrgentConfirmation = true
            return
        }
        
        viewModel.handleSwipe(direction: .left, card: card)
        undoActionText = "Marked as Read"
        showUndoToast = true
        Logger.logUserAction("Card swiped left", details: ["card_id": card.id])
    }
    
    /// Handle right swipe (take action)
    private func handleRightSwipe(card: EmailCard) {
        viewModel.handleSwipe(direction: .right, card: card)
        undoActionText = "Action Taken"
        showUndoToast = true
        actionModalCard = card
        
        // Store effective action for routing
        selectedActionId = viewModel.getEffectiveAction(for: card)
        Logger.info("Swipe right - effective action: \(selectedActionId ?? "none")", category: .ui)
        showActionModal = true
    }
    
    /// Handle down swipe (show save/snooze menu)
    private func handleDownSwipe(card: EmailCard) {
        // Show save/snooze menu to let user choose
        saveSnoozeMenuCard = card
        showSaveSnoozeMenu = true
    }
    
    // MARK: - Helper Methods
    
    /// Get swipe direction from drag offset
    private func getSwipeDirection(isHorizontal: Bool, dragOffset: CGSize) -> SwipeDirection {
        if isHorizontal {
            return dragOffset.width > 0 ? .right : .left
        } else {
            // Distinguish UP vs DOWN for vertical swipes
            return dragOffset.height < 0 ? .up : .down
        }
    }
}

// MARK: - Preview
#if DEBUG
struct CardStackView_Previews: PreviewProvider {
    static var previews: some View {
        let mockServices = ServiceContainer.mock()
        
        ZStack {
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            CardStackView(
                viewModel: mockServices.emailViewModel,
                dragOffset: .constant(.zero),
                actionModalCard: .constant(nil),
                showActionModal: .constant(false),
                actionOptionsCard: .constant(nil),
                selectedActionId: .constant(nil),
                undoActionText: .constant(""),
                showUndoToast: .constant(false),
                snoozeCard: .constant(nil),
                showSnoozePicker: .constant(false),
                urgentConfirmCard: .constant(nil),
                showUrgentConfirmation: .constant(false),
                selectedThreadCard: .constant(nil),
                saveSnoozeMenuCard: .constant(nil),
                showSaveSnoozeMenu: .constant(false),
                folderPickerCard: .constant(nil),
                showFolderPicker: .constant(false)
            )
        }
    }
}
#endif

