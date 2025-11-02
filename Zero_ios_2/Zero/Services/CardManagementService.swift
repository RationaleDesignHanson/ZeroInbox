import Foundation
import SwiftUI

/// Card Management Service
/// Handles all card-related operations: filtering, state management, swipes, and celebrations
class CardManagementService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// All email cards
    @Published var cards: [EmailCard] = []
    
    /// Current card index in filtered cards
    @Published var currentIndex: Int = 0
    
    // MARK: - Initialization
    
    init() {
        Logger.info("Card management service initialized", category: .card)
    }
    
    // MARK: - Card Filtering
    
    /// Get filtered cards for specific archetype
    func filteredCards(
        for archetype: CardType,
        selectedArchetypes: [CardType]
    ) -> [EmailCard] {
        // CRITICAL: If no archetypes selected yet, default to showing current archetype
        // This prevents race condition where cards load before selectedArchetypes is set
        let effectiveArchetypes = selectedArchetypes.isEmpty ? [archetype] : selectedArchetypes

        return cards.filter { card in
            let category = card.type
            return effectiveArchetypes.contains(category) &&
                   category == archetype &&
                   card.state == .unseen
        }
    }
    
    /// Get current card for archetype
    func currentCard(
        for archetype: CardType,
        selectedArchetypes: [CardType]
    ) -> EmailCard? {
        let filtered = filteredCards(for: archetype, selectedArchetypes: selectedArchetypes)
        guard currentIndex < filtered.count else { return nil }
        return filtered[currentIndex]
    }
    
    // MARK: - Card Loading
    
    func loadCards(forceReload: Bool = false) {
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")
        Logger.info("loadCards called, useMockData: \(useMockData), forceReload: \(forceReload)", category: .card)

        if useMockData {
            // Load mock data if cards are empty OR if explicitly forcing reload (e.g., pull-to-refresh)
            if cards.isEmpty || forceReload {
                Logger.info("Loading mock data (cards empty: \(cards.isEmpty), forceReload: \(forceReload))", category: .card)
                let mockCards = DataGenerator.generateSarahChenEmails()
                // For mock data, DON'T apply persisted states (always load fresh)
                setCards(mockCards, applyPersistedStates: false)
                Logger.info("Loaded \(cards.count) mock emails (fresh, no persisted states)", category: .card)
            } else {
                Logger.info("Skipping mock data load - \(cards.count) cards already present", category: .card)
            }
        }
        // Real email loading happens via loadRealEmails() in EmailViewModel
    }

    func setCards(_ newCards: [EmailCard], applyPersistedStates: Bool = true) {
        var finalCards = newCards

        // Only apply persisted states and priorities for real emails (not mock data)
        if applyPersistedStates {
            for index in finalCards.indices {
                // Apply persisted state
                if let persistedState = loadCardState(for: finalCards[index].id) {
                    finalCards[index].state = persistedState
                }

                // Apply persisted priority (user-controlled)
                if let persistedPriority = loadCardPriority(for: finalCards[index].id) {
                    finalCards[index].priority = persistedPriority
                }
            }
        }

        self.cards = finalCards

        // Log card type distribution for debugging
        let cardTypes = Dictionary(grouping: finalCards) { $0.type }
        let typeDistribution = cardTypes.map { "\($0.key.rawValue): \($0.value.count)" }.joined(separator: ", ")
        let unseenCount = finalCards.filter { $0.state == .unseen }.count

        Logger.info("📧 Cards updated: \(finalCards.count) total (\(unseenCount) unseen) | Types: \(typeDistribution)", category: .card)
    }
    
    func refreshCards() {
        Logger.info("Cards refreshed", category: .card)
    }
    
    // MARK: - Swipe Handling
    
    func handleSwipe(
        direction: SwipeDirection,
        card: EmailCard,
        customActions: [String: String],
        onActionRecorded: @escaping (EmailCard, CardState) -> Void
    ) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else {
            Logger.error("Card not found for swipe: \(card.id)", category: .card)
            return
        }

        // Store previous state for undo
        let previousState = cards[index].state

        // Update card state
        switch direction {
        case .left:
            cards[index].state = .seen
        case .right:
            cards[index].state = .actioned
        case .down:
            cards[index].state = .snoozed
        case .up:
            // Swipe up shows action selector - no state change
            break
        }

        // Only persist state for real emails, not mock data
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")
        if direction != .up && !useMockData {
            saveCardState(cards[index].state, for: card.id)
        }

        // Record action for undo
        onActionRecorded(card, previousState)

        // Analytics: Track card swipe
        AnalyticsService.shared.log("card_swiped", properties: [
            "direction": direction == .left ? "left" : (direction == .right ? "right" : (direction == .down ? "down" : "up")),
            "archetype": card.type.rawValue,
            "priority": card.priority.rawValue,
            "has_intent": card.intent != nil,
            "intent": card.intent ?? "unknown",
            "intent_confidence": card.intentConfidence ?? 0,
            "has_custom_action": customActions[card.id] != nil,
            "has_suggested_actions": card.suggestedActions != nil,
            "action_count": card.suggestedActions?.count ?? 0
        ])

        Logger.info("Card swiped: \(card.id), direction: \(direction), new state: \(cards[index].state)", category: .card)
    }
    
    // MARK: - Undo
    
    func undoAction(card: EmailCard, previousState: CardState) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else {
            Logger.error("Card not found for undo: \(card.id)", category: .card)
            return
        }

        cards[index].state = previousState

        // Only persist state for real emails, not mock data
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")
        if !useMockData {
            saveCardState(previousState, for: card.id)
        }

        Logger.info("Action undone: card \(card.id) restored to \(previousState)", category: .card)
    }
    
    // MARK: - Celebration Logic
    
    enum CelebrationLevel {
        case none
        case mini(CardType)  // Single archetype cleared
        case major           // All archetypes cleared
    }
    
    func checkForCelebration(
        currentArchetype: CardType,
        selectedArchetypes: [CardType]
    ) -> CelebrationLevel {
        // Check if current archetype is cleared
        let currentArchetypeCards = cards.filter {
            $0.type == currentArchetype && $0.state == .unseen
        }
        
        // Check if ALL selected archetypes are at zero
        let allArchetypesEmpty = selectedArchetypes.allSatisfy { archetype in
            let archetypeCards = cards.filter { $0.type == archetype && $0.state == .unseen }
            return archetypeCards.isEmpty
        }
        
        if allArchetypesEmpty {
            Logger.info("🎉 MAJOR CELEBRATION: All archetypes cleared!", category: .card)
            return .major
        } else if currentArchetypeCards.isEmpty && selectedArchetypes.count > 1 {
            Logger.info("🎉 MINI CELEBRATION: Archetype \(currentArchetype.rawValue) cleared!", category: .card)
            return .mini(currentArchetype)
        }
        
        return .none
    }
    
    // MARK: - Sound Effects (Haptic Feedback)
    
    func playSwipeSound(direction: SwipeDirection, isLong: Bool) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        Logger.info("Swipe sound played: \(direction)", category: .haptic)
    }
    
    func playCelebrationSound() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Additional haptics for celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.notificationOccurred(.success)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            generator.notificationOccurred(.success)
        }
        
        Logger.info("Celebration sound played", category: .haptic)
    }
    
    // MARK: - Data Integrity

    func runDataIntegrityCheck(selectedArchetypes: [CardType] = [.mail, .ads]) {
        // Only run integrity check if we have cards
        guard !cards.isEmpty else {
            Logger.info("Skipping data integrity check - no cards loaded yet", category: .card)
            return
        }

        let report = DataIntegrityService.shared.checkIntegrity(
            cards: cards,
            selectedArchetypes: selectedArchetypes
        )

        if report.hasIssues {
            Logger.debug("Data integrity check: \(report.description)", category: .card)
        } else {
            let totalUnseen = report.unseenCardsPerArchetype.values.reduce(0, +)
            Logger.info("Data integrity check passed: \(cards.count) cards, \(totalUnseen) unseen", category: .card)
        }
    }
    
    // MARK: - Statistics

    func getCardStats() -> (total: Int, unseen: Int, actioned: Int, seen: Int, snoozed: Int) {
        let total = cards.count
        let unseen = cards.filter { $0.state == .unseen }.count
        let actioned = cards.filter { $0.state == .actioned }.count
        let seen = cards.filter { $0.state == .seen }.count
        let snoozed = cards.filter { $0.state == .snoozed }.count

        return (total, unseen, actioned, seen, snoozed)
    }

    // MARK: - Card State Persistence

    /// Save card state to UserDefaults
    private func saveCardState(_ state: CardState, for cardId: String) {
        let key = "card_state_\(cardId)"
        UserDefaults.standard.set(state.rawValue, forKey: key)
        Logger.info("Persisted card state: \(cardId) -> \(state.rawValue)", category: .card)
    }

    /// Load card state from UserDefaults
    private func loadCardState(for cardId: String) -> CardState? {
        let key = "card_state_\(cardId)"
        guard let stateRawValue = UserDefaults.standard.string(forKey: key),
              let state = CardState(rawValue: stateRawValue) else {
            return nil
        }
        return state
    }

    // MARK: - Priority Management

    /// Update card priority (user-controlled)
    func updateCardPriority(cardId: String, priority: Priority) {
        guard let index = cards.firstIndex(where: { $0.id == cardId }) else {
            Logger.error("Card not found for priority update: \(cardId)", category: .card)
            return
        }

        cards[index].priority = priority

        // Persist priority for real emails
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")
        if !useMockData {
            saveCardPriority(priority, for: cardId)
        }

        // Analytics: Track priority changes
        AnalyticsService.shared.log("card_priority_updated", properties: [
            "card_id": cardId,
            "priority": priority.rawValue,
            "archetype": cards[index].type.rawValue
        ])

        Logger.info("✅ Updated card priority: \(cardId) -> \(priority.displayName)", category: .card)
    }

    /// Save card priority to UserDefaults
    private func saveCardPriority(_ priority: Priority, for cardId: String) {
        let key = "card_priority_\(cardId)"
        UserDefaults.standard.set(priority.rawValue, forKey: key)
        Logger.info("Persisted card priority: \(cardId) -> \(priority.rawValue)", category: .card)
    }

    /// Load card priority from UserDefaults
    private func loadCardPriority(for cardId: String) -> Priority? {
        let key = "card_priority_\(cardId)"
        guard let priorityRawValue = UserDefaults.standard.string(forKey: key),
              let priority = Priority(rawValue: priorityRawValue) else {
            return nil
        }
        return priority
    }

    /// Clear all persisted card states (for testing or reset)
    func clearPersistedCardStates() {
        let defaults = UserDefaults.standard
        let keysToRemove = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("card_state_") }
        for key in keysToRemove {
            defaults.removeObject(forKey: key)
        }
        Logger.info("Cleared \(keysToRemove.count) persisted card states", category: .card)
    }

    /// Clear old card states (older than 7 days)
    func clearOldCardStates() {
        // This would require storing timestamps with states
        // For now, just clear states for cards not in current set
        let currentCardIds = Set(cards.map { $0.id })
        let defaults = UserDefaults.standard
        let allStateKeys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("card_state_") }

        var clearedCount = 0
        for key in allStateKeys {
            let cardId = String(key.dropFirst("card_state_".count))
            if !currentCardIds.contains(cardId) {
                defaults.removeObject(forKey: key)
                clearedCount += 1
            }
        }

        if clearedCount > 0 {
            Logger.info("Cleaned up \(clearedCount) old card states", category: .card)
        }
    }
}


