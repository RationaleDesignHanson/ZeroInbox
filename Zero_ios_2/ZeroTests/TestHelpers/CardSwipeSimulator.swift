import XCTest
@testable import Zero

/**
 * CardSwipeSimulator - Test Helper
 * Simulates swipe gestures on email cards for testing intent→action flows
 * Provides utilities to test the complete flow:
 *   Card with intent → Swipe right → Action executed → Card dismissed
 */

class CardSwipeSimulator {

    // Track executed actions for validation
    private(set) var executedActions: [ActionExecution] = []
    private(set) var dismissedCards: Set<String> = []

    // Services
    private let cardManagement: CardManagementService
    private let actionRouter: ActionRouter

    // Test delegate to capture action execution
    weak var testDelegate: SwipeSimulatorDelegate?

    init(cardManagement: CardManagementService, actionRouter: ActionRouter) {
        self.cardManagement = cardManagement
        self.actionRouter = actionRouter
    }

    // MARK: - Swipe Simulation

    /**
     * Simulate right swipe on a card
     * Returns the actionId that would be executed
     */
    func simulateRightSwipe(on card: EmailCard, customActions: [String: String] = [:]) -> ActionExecution {
        // Get effective action (respects custom overrides)
        let effectiveActionId = getEffectiveAction(for: card, customActions: customActions)

        // Find the action from card's suggested actions
        guard let action = card.suggestedActions?.first(where: { $0.actionId == effectiveActionId }) else {
            let execution = ActionExecution(
                cardId: card.id,
                intent: card.intent ?? "unknown",
                actionId: effectiveActionId,
                actionType: nil,
                wasSuccessful: false,
                error: "Action not found in card's suggested actions"
            )
            executedActions.append(execution)
            return execution
        }

        // Validate action can be executed
        let validation = validateAction(action)

        if validation.isValid {
            // Successful execution
            let execution = ActionExecution(
                cardId: card.id,
                intent: card.intent ?? "unknown",
                actionId: action.actionId,
                actionType: action.actionType,
                wasSuccessful: true,
                error: nil
            )

            // Mark card as actioned and dismissed
            dismissedCards.insert(card.id)
            executedActions.append(execution)
            testDelegate?.didExecuteAction(execution)

            return execution
        } else {
            // Failed execution - card NOT dismissed
            let execution = ActionExecution(
                cardId: card.id,
                intent: card.intent ?? "unknown",
                actionId: action.actionId,
                actionType: action.actionType,
                wasSuccessful: false,
                error: validation.error
            )
            executedActions.append(execution)
            testDelegate?.didFailAction(execution)

            return execution
        }
    }

    /**
     * Simulate left swipe (mark as read)
     */
    func simulateLeftSwipe(on card: EmailCard) {
        dismissedCards.insert(card.id)
    }

    /**
     * Simulate down swipe (snooze)
     */
    func simulateDownSwipe(on card: EmailCard) {
        dismissedCards.insert(card.id)
    }

    // MARK: - Action Validation

    private func validateAction(_ action: EmailAction) -> (isValid: Bool, error: String?) {
        // Check if action exists in registry
        guard let actionConfig = ActionRegistry.shared.getAction(action.actionId) else {
            return (false, "Action '\(action.actionId)' not found in registry")
        }

        // Validate required context
        let validation = ActionRegistry.shared.validateAction(action.actionId, context: action.context)
        if !validation.isValid {
            return (false, "Missing required context: \(validation.missingKeys.joined(separator: ", "))")
        }

        // GO_TO actions need a URL
        if action.actionType == .goTo {
            let hasURL = extractURL(from: action) != nil
            if !hasURL {
                return (false, "GO_TO action missing URL")
            }
        }

        return (true, nil)
    }

    private func extractURL(from action: EmailAction) -> URL? {
        guard let context = action.context else { return nil }

        // Priority 1: Generic "url" key
        if let genericUrl = context["url"], !genericUrl.isEmpty {
            return URL(string: genericUrl)
        }

        // Priority 2: Action-specific URL keys
        let urlKeys = ["trackingUrl", "paymentLink", "checkInUrl", "reviewLink", "orderUrl"]
        for key in urlKeys {
            if let urlString = context[key], !urlString.isEmpty {
                return URL(string: urlString)
            }
        }

        return nil
    }

    // MARK: - Helper Methods

    private func getEffectiveAction(for card: EmailCard, customActions: [String: String]) -> String {
        // Check for custom action override
        if let customAction = customActions[card.id] {
            return customAction
        }

        // Get primary action
        if let primaryAction = card.suggestedActions?.first(where: { $0.isPrimary }) {
            return primaryAction.actionId
        }

        // Fallback to first action
        if let firstAction = card.suggestedActions?.first {
            return firstAction.actionId
        }

        // Default
        return "view_document"
    }

    /**
     * Check if card was dismissed after swipe
     */
    func wasCardDismissed(_ cardId: String) -> Bool {
        return dismissedCards.contains(cardId)
    }

    /**
     * Get last executed action
     */
    func lastExecutedAction() -> ActionExecution? {
        return executedActions.last
    }

    /**
     * Reset simulator state for next test
     */
    func reset() {
        executedActions.removeAll()
        dismissedCards.removeAll()
    }
}

// MARK: - Supporting Types

struct ActionExecution {
    let cardId: String
    let intent: String
    let actionId: String
    let actionType: ActionType?
    let wasSuccessful: Bool
    let error: String?
}

protocol SwipeSimulatorDelegate: AnyObject {
    func didExecuteAction(_ execution: ActionExecution)
    func didFailAction(_ execution: ActionExecution)
}

// MARK: - XCTest Assertions

extension XCTestCase {

    /**
     * Assert that action executed successfully
     */
    func assertActionExecuted(
        _ execution: ActionExecution,
        expectedActionId: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(execution.wasSuccessful, "Action execution failed: \(execution.error ?? "unknown error")", file: file, line: line)
        XCTAssertEqual(execution.actionId, expectedActionId, "Wrong action executed", file: file, line: line)
    }

    /**
     * Assert that card was dismissed after action
     */
    func assertCardDismissed(
        _ cardId: String,
        simulator: CardSwipeSimulator,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(simulator.wasCardDismissed(cardId), "Card was not dismissed after action", file: file, line: line)
    }

    /**
     * Assert that card was NOT dismissed (e.g., due to validation failure)
     */
    func assertCardNotDismissed(
        _ cardId: String,
        simulator: CardSwipeSimulator,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertFalse(simulator.wasCardDismissed(cardId), "Card should not be dismissed when action fails", file: file, line: line)
    }
}
