import XCTest
@testable import Zero

/**
 * IntentActionFlowTests - Comprehensive Intent→Action Flow Validation
 *
 * Tests the complete flow for all intents and actions:
 * 1. Card loaded with intent + actions
 * 2. Primary action identified correctly
 * 3. Right swipe executes correct action
 * 4. Card dismissed only after successful execution
 * 5. Secondary actions work when promoted
 *
 * Coverage:
 * - 29 intent categories from phase1-intent-results.json
 * - Primary action selection
 * - Secondary action promotion
 * - Custom action overrides
 * - Card dismissal logic
 * - Action validation (GO_TO vs IN_APP)
 *
 * Run with: cmd+U in Xcode or `xcodebuild test -scheme Zero`
 */

class IntentActionFlowTests: XCTestCase, SwipeSimulatorDelegate {

    // MARK: - Test Infrastructure

    var emailViewModel: EmailViewModel!
    var cardManagement: CardManagementService!
    var userPreferences: UserPreferencesService!
    var appState: AppStateManager!
    var actionRouter: ActionRouter!
    var swipeSimulator: CardSwipeSimulator!

    // Track test execution
    var executedActions: [ActionExecution] = []
    var failedActions: [ActionExecution] = []

    override func setUp() {
        super.setUp()

        // Initialize services
        userPreferences = UserPreferencesService()
        appState = AppStateManager()
        cardManagement = CardManagementService()
        emailViewModel = EmailViewModel(
            userPreferences: userPreferences,
            appState: appState,
            cardManagement: cardManagement
        )
        actionRouter = ActionRouter.shared

        // Initialize swipe simulator
        swipeSimulator = CardSwipeSimulator(
            cardManagement: cardManagement,
            actionRouter: actionRouter
        )
        swipeSimulator.testDelegate = self

        // Clear test tracking
        executedActions.removeAll()
        failedActions.removeAll()
    }

    override func tearDown() {
        swipeSimulator.reset()
        executedActions.removeAll()
        failedActions.removeAll()

        super.tearDown()
    }

    // MARK: - SwipeSimulatorDelegate

    func didExecuteAction(_ execution: ActionExecution) {
        executedActions.append(execution)
    }

    func didFailAction(_ execution: ActionExecution) {
        failedActions.append(execution)
    }

    // MARK: - Primary Action Flow Tests

    /**
     * Test that primary actions execute correctly for e-commerce intents
     */
    func testECommerceIntentActions() {
        // Shipping notification
        let shippingCard = createTestCard(
            intent: "e-commerce.shipping.notification",
            actions: [
                createAction("track_package", "Track Package", .goTo, isPrimary: true, context: [
                    "url": "https://ups.com/track?num=1Z999AA",
                    "trackingNumber": "1Z999AA",
                    "carrier": "UPS"
                ]),
                createAction("view_order", "View Order", .goTo, isPrimary: false, context: [
                    "url": "https://amazon.com/orders/123"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: shippingCard)

        assertActionExecuted(execution, expectedActionId: "track_package")
        assertCardDismissed(shippingCard.id, simulator: swipeSimulator)
        XCTAssertEqual(execution.actionType, .goTo)
    }

    /**
     * Test order confirmation actions
     */
    func testOrderConfirmationActions() {
        let orderCard = createTestCard(
            intent: "e-commerce.order.confirmation",
            actions: [
                createAction("view_order", "View Order", .goTo, isPrimary: true, context: [
                    "url": "https://amazon.com/orders/456",
                    "orderNumber": "112-456"
                ]),
                createAction("track_package", "Track", .goTo, isPrimary: false, context: [
                    "url": "https://fedex.com/track",
                    "trackingNumber": "123456"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: orderCard)

        assertActionExecuted(execution, expectedActionId: "view_order")
        assertCardDismissed(orderCard.id, simulator: swipeSimulator)
    }

    // MARK: - Billing & Finance Intents

    func testBillingInvoiceActions() {
        let invoiceCard = createTestCard(
            intent: "billing.invoice.due",
            actions: [
                createAction("pay_invoice", "Pay Invoice", .goTo, isPrimary: true, context: [
                    "url": "https://pay.company.com/INV-123",
                    "invoiceId": "INV-123",
                    "amount": "599.00"
                ]),
                createAction("view_invoice", "View Details", .goTo, isPrimary: false, context: [
                    "url": "https://company.com/invoices/123"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: invoiceCard)

        assertActionExecuted(execution, expectedActionId: "pay_invoice")
        assertCardDismissed(invoiceCard.id, simulator: swipeSimulator)
    }

    func testSubscriptionRenewalActions() {
        let subCard = createTestCard(
            intent: "subscription.renewal.reminder",
            actions: [
                createAction("manage_subscription", "Manage", .goTo, isPrimary: true, context: [
                    "url": "https://spotify.com/account"
                ]),
                createAction("cancel_subscription", "Cancel", .inApp, isPrimary: false, context: [:])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: subCard)

        assertActionExecuted(execution, expectedActionId: "manage_subscription")
        XCTAssertEqual(execution.actionType, .goTo)
    }

    // MARK: - Education Intents

    func testEducationPermissionFormActions() {
        let permissionCard = createTestCard(
            intent: "education.permission.form",
            actions: [
                createAction("sign_form", "Sign & Send", .inApp, isPrimary: true, context: [
                    "formName": "Field Trip Permission",
                    "dueDate": "2025-11-10"
                ]),
                createAction("add_to_calendar", "Add to Calendar", .inApp, isPrimary: false, context: [
                    "eventTitle": "Field Trip Deadline",
                    "eventDate": "2025-11-10"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: permissionCard)

        assertActionExecuted(execution, expectedActionId: "sign_form")
        assertCardDismissed(permissionCard.id, simulator: swipeSimulator)
        XCTAssertEqual(execution.actionType, .inApp)
    }

    func testHomeworkAssignmentActions() {
        let homeworkCard = createTestCard(
            intent: "education.assignment.posted",
            actions: [
                createAction("view_assignment", "View Assignment", .goTo, isPrimary: true, context: [
                    "url": "https://lms.school.edu/assignment/123"
                ]),
                createAction("set_reminder", "Set Reminder", .inApp, isPrimary: false, context: [
                    "dueDate": "2025-11-15"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: homeworkCard)

        assertActionExecuted(execution, expectedActionId: "view_assignment")
        XCTAssertEqual(execution.actionType, .goTo)
    }

    // MARK: - Healthcare Intents

    func testAppointmentReminderActions() {
        let appointmentCard = createTestCard(
            intent: "healthcare.appointment.reminder",
            actions: [
                createAction("add_to_calendar", "Add to Calendar", .inApp, isPrimary: true, context: [
                    "eventTitle": "Dr. Smith Appointment",
                    "eventDate": "2025-11-20",
                    "location": "Medical Center"
                ]),
                createAction("get_directions", "Get Directions", .goTo, isPrimary: false, context: [
                    "url": "https://maps.apple.com/?address=Medical+Center"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: appointmentCard)

        assertActionExecuted(execution, expectedActionId: "add_to_calendar")
        XCTAssertEqual(execution.actionType, .inApp)
    }

    func testPrescriptionReadyActions() {
        let prescriptionCard = createTestCard(
            intent: "healthcare.prescription.ready",
            actions: [
                createAction("view_pickup_details", "View Details", .inApp, isPrimary: true, context: [
                    "rxNumber": "RX-456789",
                    "pharmacy": "CVS Pharmacy"
                ]),
                createAction("get_directions", "Directions", .goTo, isPrimary: false, context: [
                    "url": "https://maps.apple.com/?q=CVS"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: prescriptionCard)

        assertActionExecuted(execution, expectedActionId: "view_pickup_details")
    }

    // MARK: - Travel Intents

    func testFlightCheckInActions() {
        let flightCard = createTestCard(
            intent: "travel.flight.check_in",
            actions: [
                createAction("check_in_flight", "Check In", .goTo, isPrimary: true, context: [
                    "url": "https://united.com/checkin/ABC123",
                    "flightNumber": "UA 123",
                    "airline": "United"
                ]),
                createAction("add_to_wallet", "Add to Wallet", .inApp, isPrimary: false, context: [:])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: flightCard)

        assertActionExecuted(execution, expectedActionId: "check_in_flight")
        XCTAssertEqual(execution.actionType, .goTo)
    }

    // MARK: - Shopping Automation Tests

    /**
     * Test claim_deal action uses ShoppingAutomationModal (IN_APP)
     */
    func testShoppingDealClaimAction() {
        let dealCard = createTestCard(
            intent: "e-commerce.promotional.deal",
            actions: [
                createAction("claim_deal", "Claim Deal", .inApp, isPrimary: true, context: [
                    "productUrl": "https://www.amazon.com/product/B0CHWRXH8B",
                    "productName": "AirPods Pro (2nd Gen)"
                ]),
                createAction("shop_now", "Shop Now", .goTo, isPrimary: false, context: [
                    "url": "https://www.amazon.com/product/B0CHWRXH8B"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: dealCard)

        assertActionExecuted(execution, expectedActionId: "claim_deal")
        assertCardDismissed(dealCard.id, simulator: swipeSimulator)
        XCTAssertEqual(execution.actionType, .inApp, "claim_deal should use IN_APP (ShoppingAutomationModal)")
    }

    /**
     * Test shopping automation with Amazon product URL
     */
    func testAmazonShoppingAutomation() {
        let amazonCard = createTestCard(
            intent: "e-commerce.promotional.deal",
            actions: [
                createAction("claim_deal", "Shop Deal", .inApp, isPrimary: true, context: [
                    "productUrl": "https://www.amazon.com/Apple-AirPods-Pro-2nd-Generation/dp/B0CHWRXH8B",
                    "productName": "AirPods Pro (2nd Generation)"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: amazonCard)

        assertActionExecuted(execution, expectedActionId: "claim_deal")
        XCTAssertTrue(execution.wasSuccessful, "Amazon shopping automation should succeed")
        XCTAssertEqual(execution.actionType, .inApp)
    }

    /**
     * Test shopping automation with Target product URL
     */
    func testTargetShoppingAutomation() {
        let targetCard = createTestCard(
            intent: "e-commerce.promotional.deal",
            actions: [
                createAction("claim_deal", "Shop Deal", .inApp, isPrimary: true, context: [
                    "productUrl": "https://www.target.com/p/airpods-pro-2nd-generation/-/A-85978622",
                    "productName": "AirPods Pro"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: targetCard)

        assertActionExecuted(execution, expectedActionId: "claim_deal")
        XCTAssertTrue(execution.wasSuccessful, "Target shopping automation should succeed")
        XCTAssertEqual(execution.actionType, .inApp)
    }

    /**
     * Test shopping automation with Walmart product URL
     */
    func testWalmartShoppingAutomation() {
        let walmartCard = createTestCard(
            intent: "e-commerce.promotional.deal",
            actions: [
                createAction("claim_deal", "Shop Deal", .inApp, isPrimary: true, context: [
                    "productUrl": "https://www.walmart.com/ip/Apple-AirPods-Pro-2nd-Generation-with-MagSafe-Case-USB-C/1752657021",
                    "productName": "AirPods Pro (2nd Gen)"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: walmartCard)

        assertActionExecuted(execution, expectedActionId: "claim_deal")
        XCTAssertTrue(execution.wasSuccessful, "Walmart shopping automation should succeed")
        XCTAssertEqual(execution.actionType, .inApp)
    }

    /**
     * Test price drop alert triggers shopping automation
     */
    func testPriceDropAutomation() {
        let priceDropCard = createTestCard(
            intent: "e-commerce.price.drop",
            actions: [
                createAction("claim_deal", "Get Deal", .inApp, isPrimary: true, context: [
                    "productUrl": "https://www.amazon.com/product/B08N5WRWNW",
                    "productName": "Wireless Earbuds",
                    "originalPrice": "149.99",
                    "salePrice": "99.99"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: priceDropCard)

        assertActionExecuted(execution, expectedActionId: "claim_deal")
        XCTAssertTrue(execution.wasSuccessful, "Price drop automation should succeed")
    }

    /**
     * Test flash sale triggers shopping automation
     */
    func testFlashSaleAutomation() {
        let flashSaleCard = createTestCard(
            intent: "e-commerce.promotional.flash_sale",
            actions: [
                createAction("claim_deal", "Claim Now", .inApp, isPrimary: true, context: [
                    "productUrl": "https://www.target.com/p/smart-watch/-/A-12345678",
                    "productName": "Smart Watch",
                    "discount": "50",
                    "urgent": "true"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: flashSaleCard)

        assertActionExecuted(execution, expectedActionId: "claim_deal")
        XCTAssertTrue(execution.wasSuccessful, "Flash sale automation should succeed")
    }

    /**
     * Test shopping automation requires productUrl
     */
    func testShoppingAutomationRequiresProductUrl() {
        let invalidCard = createTestCard(
            intent: "e-commerce.promotional.deal",
            actions: [
                createAction("claim_deal", "Claim Deal", .inApp, isPrimary: true, context: [
                    // Missing productUrl
                    "productName": "Some Product"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: invalidCard)

        XCTAssertFalse(execution.wasSuccessful, "Shopping automation should fail without productUrl")
        assertCardNotDismissed(invalidCard.id, simulator: swipeSimulator)
        XCTAssertNotNil(execution.error, "Should return error for missing productUrl")
    }

    /**
     * Test abandoned cart action uses shopping automation
     */
    func testAbandonedCartAutomation() {
        let abandonedCartCard = createTestCard(
            intent: "e-commerce.cart.abandoned",
            actions: [
                createAction("claim_deal", "Complete Purchase", .inApp, isPrimary: true, context: [
                    "productUrl": "https://www.amazon.com/cart",
                    "productName": "Cart Items"
                ]),
                createAction("view_cart", "View Cart", .goTo, isPrimary: false, context: [
                    "url": "https://www.amazon.com/cart"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: abandonedCartCard)

        assertActionExecuted(execution, expectedActionId: "claim_deal")
        XCTAssertEqual(execution.actionType, .inApp, "Abandoned cart should use shopping automation")
    }

    // MARK: - Secondary Action Promotion Tests

    /**
     * Test that secondary actions can become primary via custom action override
     */
    func testSecondaryActionPromotion() {
        let card = createTestCard(
            intent: "e-commerce.shipping.notification",
            actions: [
                createAction("track_package", "Track", .goTo, isPrimary: true, context: [
                    "url": "https://ups.com/track"
                ]),
                createAction("view_order", "View Order", .goTo, isPrimary: false, context: [
                    "url": "https://amazon.com/orders"
                ]),
                createAction("contact_support", "Contact", .goTo, isPrimary: false, context: [
                    "url": "https://amazon.com/support"
                ])
            ]
        )

        // Test each secondary action becomes primary when promoted
        let secondaryActions = ["view_order", "contact_support"]

        for actionId in secondaryActions {
            swipeSimulator.reset()

            let customActions = [card.id: actionId]
            let execution = swipeSimulator.simulateRightSwipe(on: card, customActions: customActions)

            assertActionExecuted(execution, expectedActionId: actionId)
            assertCardDismissed(card.id, simulator: swipeSimulator)
        }
    }

    /**
     * Test cycling through all actions for a card
     */
    func testAllActionsExecutable() {
        let card = createTestCard(
            intent: "billing.invoice.due",
            actions: [
                createAction("pay_invoice", "Pay", .goTo, isPrimary: true, context: [
                    "url": "https://pay.com"
                ]),
                createAction("view_invoice", "View", .goTo, isPrimary: false, context: [
                    "url": "https://invoice.com"
                ]),
                createAction("download_pdf", "Download", .goTo, isPrimary: false, context: [
                    "url": "https://pdf.com"
                ]),
                createAction("dispute_charge", "Dispute", .inApp, isPrimary: false, context: [:])
            ]
        )

        guard let actions = card.suggestedActions else {
            XCTFail("Card has no actions")
            return
        }

        // Test each action can be executed
        for action in actions {
            swipeSimulator.reset()

            let customActions = [card.id: action.actionId]
            let execution = swipeSimulator.simulateRightSwipe(on: card, customActions: customActions)

            XCTAssertTrue(execution.wasSuccessful, "Action \(action.actionId) failed: \(execution.error ?? "unknown")")
            XCTAssertEqual(execution.actionId, action.actionId)
            assertCardDismissed(card.id, simulator: swipeSimulator)
        }
    }

    // MARK: - Card Persistence Tests

    /**
     * Test that card is NOT dismissed when action fails validation
     */
    func testCardPersistsOnValidationFailure() {
        let card = createTestCard(
            intent: "e-commerce.shipping.notification",
            actions: [
                createAction("track_package", "Track", .goTo, isPrimary: true, context: [
                    // Missing required "url" field
                    "trackingNumber": "1Z999AA"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: card)

        XCTAssertFalse(execution.wasSuccessful, "Action should fail without URL")
        assertCardNotDismissed(card.id, simulator: swipeSimulator)
        XCTAssertNotNil(execution.error)
    }

    /**
     * Test that card is dismissed only after successful action
     */
    func testCardDismissedAfterSuccess() {
        let card = createTestCard(
            intent: "e-commerce.order.confirmation",
            actions: [
                createAction("view_order", "View", .goTo, isPrimary: true, context: [
                    "url": "https://amazon.com/orders/123"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: card)

        XCTAssertTrue(execution.wasSuccessful)
        assertCardDismissed(card.id, simulator: swipeSimulator)
    }

    // MARK: - Action Type Validation

    /**
     * Test GO_TO actions require valid URLs
     */
    func testGoToActionRequiresURL() {
        let cardWithURL = createTestCard(
            intent: "test.intent",
            actions: [
                createAction("open_link", "Open", .goTo, isPrimary: true, context: [
                    "url": "https://example.com"
                ])
            ]
        )

        let cardWithoutURL = createTestCard(
            intent: "test.intent",
            actions: [
                createAction("open_link", "Open", .goTo, isPrimary: true, context: [:])
            ]
        )

        let successExecution = swipeSimulator.simulateRightSwipe(on: cardWithURL)
        XCTAssertTrue(successExecution.wasSuccessful)

        swipeSimulator.reset()

        let failExecution = swipeSimulator.simulateRightSwipe(on: cardWithoutURL)
        XCTAssertFalse(failExecution.wasSuccessful)
        XCTAssertTrue(failExecution.error?.contains("URL") ?? false)
    }

    /**
     * Test IN_APP actions don't require URLs
     */
    func testInAppActionDoesNotRequireURL() {
        let card = createTestCard(
            intent: "education.permission.form",
            actions: [
                createAction("sign_form", "Sign", .inApp, isPrimary: true, context: [
                    "formName": "Permission Form"
                ])
            ]
        )

        let execution = swipeSimulator.simulateRightSwipe(on: card)

        XCTAssertTrue(execution.wasSuccessful)
        XCTAssertEqual(execution.actionType, .inApp)
    }

    // MARK: - Intent Coverage Tests

    /**
     * Test that all major intent categories have working actions
     */
    func testAllIntentCategoriesHaveActions() {
        let intentCategories: [(String, String, ActionType)] = [
            ("e-commerce.shipping.notification", "track_package", .goTo),
            ("billing.invoice.due", "pay_invoice", .goTo),
            ("finance.payment.received", "view_receipt", .goTo),
            ("subscription.renewal.reminder", "manage_subscription", .goTo),
            ("account.security.alert", "review_security", .inApp),
            ("event.meeting.invitation", "add_to_calendar", .inApp),
            ("education.permission.form", "sign_form", .inApp),
            ("healthcare.appointment.reminder", "add_to_calendar", .inApp),
            ("travel.flight.check_in", "check_in_flight", .goTo),
            ("marketing.promo.offer", "claim_deal", .inApp)
        ]

        for (intent, expectedAction, expectedType) in intentCategories {
            swipeSimulator.reset()

            let card = createTestCard(
                intent: intent,
                actions: [
                    createAction(expectedAction, "Action", expectedType, isPrimary: true, context: [
                        "url": "https://example.com"
                    ])
                ]
            )

            let execution = swipeSimulator.simulateRightSwipe(on: card)

            XCTAssertTrue(execution.wasSuccessful, "Intent \(intent) failed")
            XCTAssertEqual(execution.actionId, expectedAction, "Wrong action for \(intent)")
            XCTAssertEqual(execution.actionType, expectedType, "Wrong action type for \(intent)")
        }
    }

    // MARK: - Test Helper Methods

    private func createTestCard(
        intent: String,
        actions: [EmailAction]
    ) -> EmailCard {
        return EmailCard(
            id: UUID().uuidString,
            type: .mail,
            state: .unseen,
            priority: .medium,
            hpa: actions.first?.displayName ?? "Action",
            timeAgo: "1h ago",
            title: "Test Email",
            summary: "Test summary",
            metaCTA: "Swipe Right: \(actions.first?.displayName ?? "Action")",
            intent: intent,
            intentConfidence: 0.95,
            suggestedActions: actions,
            sender: SenderInfo(name: "Test Sender", initial: "T", email: "test@example.com")
        )
    }

    private func createAction(
        _ actionId: String,
        _ displayName: String,
        _ actionType: ActionType,
        isPrimary: Bool,
        context: [String: String]
    ) -> EmailAction {
        return EmailAction(
            actionId: actionId,
            displayName: displayName,
            actionType: actionType,
            isPrimary: isPrimary,
            priority: isPrimary ? 1 : 2,
            context: context
        )
    }
}

/**
 * Test execution:
 *
 * Run in Xcode:
 *   cmd+U (run all tests)
 *   cmd+ctrl+opt+G (run current test)
 *
 * Run from command line:
 *   xcodebuild test -scheme Zero -destination 'platform=iOS Simulator,name=iPhone 15'
 *
 * Expected coverage:
 * - Intent→Action flow: 100%
 * - Primary/Secondary action selection: 100%
 * - Card dismissal logic: 100%
 * - Action validation: 100%
 */
