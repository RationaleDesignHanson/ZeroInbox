import XCTest
@testable import Zero

/**
 * EmailCard Model Unit Tests
 * Tests primary action selection, action array handling, and backend contract
 *
 * Critical: Tests EmailCard.swift:23-30 primary action logic
 * Backend contract: rules-engine.js:130 sets isPrimary flag
 *
 * Run with: cmd+U in Xcode or `xcodebuild test -scheme Zero`
 */
class EmailCardTests: XCTestCase {

    // MARK: - Primary Action Selection Tests

    func testPrimaryActionFromSuggestedActions() {
        // Given: Email card with multiple actions
        let actions = [
            EmailAction(actionId: "track_package", displayName: "Track Package", actionType: .goTo, priority: 1, isPrimary: true, context: [:]),
            EmailAction(actionId: "view_order", displayName: "View Order", actionType: .goTo, priority: 2, isPrimary: false, context: [:]),
            EmailAction(actionId: "contact_support", displayName: "Contact", actionType: .goTo, priority: 3, isPrimary: false, context: [:])
        ]

        let emailCard = EmailCard(
            id: "test-001",
            messageId: "msg-001",
            from: "shipping@amazon.com",
            fromName: "Amazon Shipping",
            subject: "Your package has shipped",
            preview: "Your order #112-7654321 is on its way",
            date: Date(),
            isRead: false,
            isArchived: false,
            labels: [],
            intentId: "e-commerce.shipping.notification",
            intentDisplayName: "Shipping Notification",
            intentConfidence: 0.95,
            suggestedActions: actions,
            entities: [:],
            summary: "Package shipped"
        )

        // When: Access primary action
        let primaryAction = emailCard.suggestedActions?.first(where: { $0.isPrimary })

        // Then: First action should be primary
        XCTAssertNotNil(primaryAction)
        XCTAssertEqual(primaryAction?.actionId, "track_package")
        XCTAssertTrue(primaryAction?.isPrimary ?? false)
    }

    func testBackwardCompatibleSuggestedActionProperty() {
        // Given: Email card with actions
        let actions = [
            EmailAction(actionId: "pay_invoice", displayName: "Pay Invoice", actionType: .goTo, priority: 1, isPrimary: true, context: [:])
        ]

        let emailCard = EmailCard(
            id: "test-002",
            messageId: "msg-002",
            from: "billing@company.com",
            fromName: "Acme Billing",
            subject: "Invoice Due",
            preview: "Invoice INV-123 due Oct 30",
            date: Date(),
            isRead: false,
            isArchived: false,
            labels: [],
            intentId: "billing.invoice.due",
            intentDisplayName: "Invoice Due",
            intentConfidence: 0.88,
            suggestedActions: actions,
            entities: [:],
            summary: nil
        )

        // When: Access suggestedAction (singular, computed property)
        let suggestedAction = emailCard.suggestedAction

        // Then: Should return primary action ID
        XCTAssertEqual(suggestedAction, "pay_invoice")
    }

    func testNoActionsReturnsViewDocumentDefault() {
        // Given: Email card with no actions
        let emailCard = EmailCard(
            id: "test-003",
            messageId: "msg-003",
            from: "test@example.com",
            fromName: "Test User",
            subject: "Random Email",
            preview: "No clear intent",
            date: Date(),
            isRead: false,
            isArchived: false,
            labels: [],
            intentId: "unknown",
            intentDisplayName: "Unknown",
            intentConfidence: 0.3,
            suggestedActions: nil,  // No actions
            entities: [:],
            summary: nil
        )

        // When: Access suggestedAction
        let suggestedAction = emailCard.suggestedAction

        // Then: Should return default action
        XCTAssertEqual(suggestedAction, "view_document")
    }

    func testEmptyActionsArrayReturnsDefault() {
        // Given: Email card with empty actions array
        let emailCard = EmailCard(
            id: "test-004",
            messageId: "msg-004",
            from: "test@example.com",
            fromName: "Test User",
            subject: "Test",
            preview: "Test preview",
            date: Date(),
            isRead: false,
            isArchived: false,
            labels: [],
            intentId: "unknown",
            intentDisplayName: "Unknown",
            intentConfidence: 0.3,
            suggestedActions: [],  // Empty array
            entities: [:],
            summary: nil
        )

        let suggestedAction = emailCard.suggestedAction

        XCTAssertEqual(suggestedAction, "view_document")
    }

    // MARK: - Compound Action Tests

    func testCompoundActionAsPrimary() {
        // Given: Email with compound action
        let compoundAction = EmailAction(
            actionId: "track_with_calendar",
            displayName: "Track & Add to Calendar",
            actionType: .goTo,
            priority: 1,
            isPrimary: true,
            isCompound: true,
            compoundSteps: ["track_package", "add_to_calendar"],
            context: [
                "url": "https://ups.com/track",
                "deliveryDate": "2025-11-05"
            ]
        )

        let emailCard = EmailCard(
            id: "test-005",
            messageId: "msg-005",
            from: "shipping@amazon.com",
            fromName: "Amazon",
            subject: "Package arriving Nov 5",
            preview: "Your package arrives tomorrow",
            date: Date(),
            isRead: false,
            isArchived: false,
            labels: [],
            intentId: "e-commerce.shipping.notification",
            intentDisplayName: "Shipping",
            intentConfidence: 0.92,
            suggestedActions: [compoundAction],
            entities: [:],
            summary: nil
        )

        // When: Get primary action
        let primaryAction = emailCard.suggestedActions?.first(where: { $0.isPrimary })

        // Then: Compound action should be primary
        XCTAssertNotNil(primaryAction)
        XCTAssertEqual(primaryAction?.actionId, "track_with_calendar")
        XCTAssertTrue(primaryAction?.isCompound ?? false)
        XCTAssertEqual(primaryAction?.compoundSteps?.count, 2)
    }

    func testSignFormWithPaymentCompound() {
        // Given: Education email with sign & pay compound action
        let action = EmailAction(
            actionId: "sign_form_with_payment",
            displayName: "Sign & Pay",
            actionType: .inApp,
            priority: 1,
            isPrimary: true,
            isCompound: true,
            compoundSteps: ["sign_form", "pay_form_fee", "send_confirmation"],
            requiresResponse: true,
            isPremium: true,
            context: [
                "formName": "Field Trip Permission",
                "amount": "45.00"
            ]
        )

        let emailCard = EmailCard(
            id: "test-006",
            messageId: "msg-006",
            from: "teacher@school.edu",
            fromName: "Ms. Smith",
            subject: "Field Trip Permission Form",
            preview: "Sign and pay $45 by Wednesday",
            date: Date(),
            isRead: false,
            isArchived: false,
            labels: [],
            intentId: "education.permission.form",
            intentDisplayName: "Permission Form",
            intentConfidence: 0.89,
            suggestedActions: [action],
            entities: [:],
            summary: nil
        )

        let primaryAction = emailCard.suggestedActions?.first(where: { $0.isPrimary })

        XCTAssertNotNil(primaryAction)
        XCTAssertEqual(primaryAction?.actionId, "sign_form_with_payment")
        XCTAssertTrue(primaryAction?.isCompound ?? false)
        XCTAssertTrue(primaryAction?.requiresResponse ?? false)
        XCTAssertTrue(primaryAction?.isPremium ?? false)
        XCTAssertEqual(primaryAction?.compoundSteps?.count, 3)
    }

    // MARK: - Action Priority Tests

    func testActionsOrderedByPriority() {
        // Given: Actions with different priorities
        let actions = [
            EmailAction(actionId: "action_1", displayName: "Action 1", actionType: .goTo, priority: 1, isPrimary: true, context: [:]),
            EmailAction(actionId: "action_2", displayName: "Action 2", actionType: .goTo, priority: 2, isPrimary: false, context: [:]),
            EmailAction(actionId: "action_3", displayName: "Action 3", actionType: .goTo, priority: 3, isPrimary: false, context: [:])
        ]

        let emailCard = EmailCard(
            id: "test-007",
            messageId: "msg-007",
            from: "test@example.com",
            fromName: "Test",
            subject: "Test",
            preview: "Test",
            date: Date(),
            isRead: false,
            isArchived: false,
            labels: [],
            intentId: "test",
            intentDisplayName: "Test",
            intentConfidence: 0.8,
            suggestedActions: actions,
            entities: [:],
            summary: nil
        )

        // When: Get actions
        let cardActions = emailCard.suggestedActions ?? []

        // Then: Actions should maintain priority order
        XCTAssertEqual(cardActions.count, 3)
        XCTAssertEqual(cardActions[0].priority, 1)
        XCTAssertEqual(cardActions[1].priority, 2)
        XCTAssertEqual(cardActions[2].priority, 3)
    }

    // MARK: - Backend Contract Tests

    func testBackendActionContractStructure() {
        // Given: Action from backend with all required fields
        let action = EmailAction(
            actionId: "track_package",
            displayName: "Track Package",
            actionType: .goTo,
            priority: 1,
            isPrimary: true,
            isCompound: false,
            compoundSteps: nil,
            requiresResponse: false,
            isPremium: false,
            context: [
                "url": "https://ups.com/track?num=1Z999AA",
                "trackingNumber": "1Z999AA",
                "carrier": "UPS"
            ]
        )

        // Then: Verify all fields present
        XCTAssertEqual(action.actionId, "track_package")
        XCTAssertEqual(action.displayName, "Track Package")
        XCTAssertEqual(action.actionType, .goTo)
        XCTAssertEqual(action.priority, 1)
        XCTAssertTrue(action.isPrimary)
        XCTAssertFalse(action.isCompound ?? false)
        XCTAssertFalse(action.requiresResponse ?? false)
        XCTAssertFalse(action.isPremium ?? false)
        XCTAssertNotNil(action.context["url"])
    }

    func testEmailCardDecodingFromJSON() {
        // Given: JSON response from backend
        let json = """
        {
            "id": "card-001",
            "messageId": "msg-001",
            "from": "shipping@amazon.com",
            "fromName": "Amazon Shipping",
            "subject": "Your package shipped",
            "preview": "Order #112-7654321 is on its way",
            "date": "2025-11-01T10:00:00Z",
            "isRead": false,
            "isArchived": false,
            "labels": ["INBOX"],
            "intentId": "e-commerce.shipping.notification",
            "intentDisplayName": "Shipping Notification",
            "intentConfidence": 0.95,
            "suggestedActions": [
                {
                    "actionId": "track_package",
                    "displayName": "Track Package",
                    "actionType": "GO_TO",
                    "priority": 1,
                    "isPrimary": true,
                    "context": {
                        "url": "https://ups.com/track",
                        "trackingNumber": "1Z999AA"
                    }
                }
            ],
            "entities": {},
            "summary": "Package shipped"
        }
        """.data(using: .utf8)!

        // When: Decode JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Then: Should decode successfully
        XCTAssertNoThrow(try decoder.decode(EmailCard.self, from: json))

        if let emailCard = try? decoder.decode(EmailCard.self, from: json) {
            XCTAssertEqual(emailCard.id, "card-001")
            XCTAssertEqual(emailCard.intentId, "e-commerce.shipping.notification")
            XCTAssertEqual(emailCard.suggestedActions?.count, 1)
            XCTAssertEqual(emailCard.suggestedActions?.first?.actionId, "track_package")
            XCTAssertTrue(emailCard.suggestedActions?.first?.isPrimary ?? false)
        }
    }

    // MARK: - Entity Tests

    func testEntitiesPreservedInCard() {
        // Given: Email with entities
        let entities: [String: String] = [
            "trackingNumber": "1Z999AA10123456784",
            "carrier": "UPS",
            "orderNumber": "112-7654321",
            "deliveryDate": "2025-11-05"
        ]

        let emailCard = EmailCard(
            id: "test-008",
            messageId: "msg-008",
            from: "shipping@amazon.com",
            fromName: "Amazon",
            subject: "Package shipped",
            preview: "Your order is on its way",
            date: Date(),
            isRead: false,
            isArchived: false,
            labels: [],
            intentId: "e-commerce.shipping.notification",
            intentDisplayName: "Shipping",
            intentConfidence: 0.93,
            suggestedActions: [],
            entities: entities,
            summary: nil
        )

        // Then: Entities should be preserved
        XCTAssertEqual(emailCard.entities["trackingNumber"], "1Z999AA10123456784")
        XCTAssertEqual(emailCard.entities["carrier"], "UPS")
        XCTAssertEqual(emailCard.entities["orderNumber"], "112-7654321")
        XCTAssertEqual(emailCard.entities["deliveryDate"], "2025-11-05")
    }

    // MARK: - Edge Cases

    func testMultiplePrimaryActionsSelectsFirst() {
        // Given: Multiple actions marked as primary (backend error)
        let actions = [
            EmailAction(actionId: "action_1", displayName: "Action 1", actionType: .goTo, priority: 1, isPrimary: true, context: [:]),
            EmailAction(actionId: "action_2", displayName: "Action 2", actionType: .goTo, priority: 2, isPrimary: true, context: [:])
        ]

        let emailCard = EmailCard(
            id: "test-009",
            messageId: "msg-009",
            from: "test@example.com",
            fromName: "Test",
            subject: "Test",
            preview: "Test",
            date: Date(),
            isRead: false,
            isArchived: false,
            labels: [],
            intentId: "test",
            intentDisplayName: "Test",
            intentConfidence: 0.8,
            suggestedActions: actions,
            entities: [:],
            summary: nil
        )

        // When: Get primary action
        let primaryAction = emailCard.suggestedActions?.first(where: { $0.isPrimary })

        // Then: Should select first primary action
        XCTAssertEqual(primaryAction?.actionId, "action_1")
    }

    func testNoPrimaryActionSelectsFirst() {
        // Given: No actions marked as primary
        let actions = [
            EmailAction(actionId: "action_1", displayName: "Action 1", actionType: .goTo, priority: 1, isPrimary: false, context: [:]),
            EmailAction(actionId: "action_2", displayName: "Action 2", actionType: .goTo, priority: 2, isPrimary: false, context: [:])
        ]

        let emailCard = EmailCard(
            id: "test-010",
            messageId: "msg-010",
            from: "test@example.com",
            fromName: "Test",
            subject: "Test",
            preview: "Test",
            date: Date(),
            isRead: false,
            isArchived: false,
            labels: [],
            intentId: "test",
            intentDisplayName: "Test",
            intentConfidence: 0.8,
            suggestedActions: actions,
            entities: [:],
            summary: nil
        )

        // When: Access suggestedAction
        let suggestedAction = emailCard.suggestedAction

        // Then: Should return first action's ID
        XCTAssertEqual(suggestedAction, "action_1")
    }
}

/**
 * Test execution:
 *
 * Run in Xcode:
 *   cmd+U (run all tests)
 *
 * Run from command line:
 *   xcodebuild test -scheme Zero -destination 'platform=iOS Simulator,name=iPhone 15'
 *
 * Expected coverage:
 * - EmailCard.swift: >90%
 * - Primary action selection: 100%
 * - Backend contract validation: 100%
 */
