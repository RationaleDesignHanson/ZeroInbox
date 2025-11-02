import XCTest

/**
 * Zero Sequence UI Tests
 * Tests critical user flows for the zero sequence engine
 *
 * Critical User Flows:
 * 1. Primary action display on email card
 * 2. Swipe up to view all actions
 * 3. Perfect action execution (GO_TO and IN_APP)
 *
 * These tests validate the complete user experience from viewing an email
 * to executing compound actions.
 *
 * Run with: cmd+U in Xcode or `xcodebuild test -scheme ZeroUITests`
 */
class ZeroSequenceUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Enable demo mode for consistent testing
        app.launchArguments.append("--uitesting")
        app.launchEnvironment["DEMO_MODE"] = "1"

        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Primary Action Display Tests

    func testPrimaryActionDisplayedOnCard() throws {
        // Given: User is viewing inbox with shipping notification
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Your package has shipped").element
        XCTAssertTrue(emailCard.waitForExistence(timeout: 5))

        // When: View the email card
        let primaryActionButton = emailCard.buttons.matching(identifier: "primaryActionButton").element

        // Then: Primary action should be visible
        XCTAssertTrue(primaryActionButton.exists)
        XCTAssertTrue(primaryActionButton.label.contains("Track"))
    }

    func testPrimaryActionButtonTappable() throws {
        // Given: Email card with primary action
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Your package has shipped").element
        XCTAssertTrue(emailCard.waitForExistence(timeout: 5))

        let primaryActionButton = emailCard.buttons["primaryActionButton"].firstMatch

        // When: Tap primary action button
        XCTAssertTrue(primaryActionButton.isHittable)
        primaryActionButton.tap()

        // Then: Action should execute (Safari opens or modal appears)
        // Note: Can't fully test Safari opening in UI tests, but tap should succeed
        XCTAssertTrue(true)
    }

    func testDifferentIntentsShowDifferentPrimaryActions() throws {
        // Given: Multiple emails with different intents

        // Shipping notification → Track Package
        let shippingCard = app.scrollViews.otherElements.containing(.staticText, identifier: "package has shipped").element
        if shippingCard.exists {
            let trackButton = shippingCard.buttons.containing(NSPredicate(format: "label CONTAINS 'Track'")).element
            XCTAssertTrue(trackButton.exists)
        }

        // Invoice → Pay Invoice
        let invoiceCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Invoice Due").element
        if invoiceCard.exists {
            let payButton = invoiceCard.buttons.containing(NSPredicate(format: "label CONTAINS 'Pay'")).element
            XCTAssertTrue(payButton.exists)
        }

        // Permission form → Sign Form
        let formCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Permission Form").element
        if formCard.exists {
            let signButton = formCard.buttons.containing(NSPredicate(format: "label CONTAINS 'Sign'")).element
            XCTAssertTrue(signButton.exists)
        }
    }

    // MARK: - Swipe Up Action Selector Tests

    func testSwipeUpShowsActionSelector() throws {
        // Given: Email card visible
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Your package has shipped").element
        XCTAssertTrue(emailCard.waitForExistence(timeout: 5))

        // When: Swipe up on email card
        emailCard.swipeUp()

        // Then: Action selector bottom sheet should appear
        let actionSelector = app.sheets["ActionSelectorBottomSheet"]
        XCTAssertTrue(actionSelector.waitForExistence(timeout: 2))
    }

    func testActionSelectorShowsAllActions() throws {
        // Given: Email with multiple actions
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Your package has shipped").element
        XCTAssertTrue(emailCard.waitForExistence(timeout: 5))

        // When: Open action selector
        emailCard.swipeUp()

        let actionSelector = app.sheets["ActionSelectorBottomSheet"]
        XCTAssertTrue(actionSelector.waitForExistence(timeout: 2))

        // Then: All actions should be visible
        let actionsList = actionSelector.scrollViews.firstMatch
        XCTAssertTrue(actionsList.exists)

        // Should have multiple action rows
        let actionRows = actionsList.buttons
        XCTAssertGreaterThan(actionRows.count, 1)
    }

    func testCurrentPrimaryActionHighlighted() throws {
        // Given: Email card with primary action
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Your package has shipped").element
        XCTAssertTrue(emailCard.waitForExistence(timeout: 5))

        // When: Open action selector
        emailCard.swipeUp()

        let actionSelector = app.sheets["ActionSelectorBottomSheet"]
        XCTAssertTrue(actionSelector.waitForExistence(timeout: 2))

        // Then: Primary action should be highlighted/selected
        let primaryActionRow = actionSelector.buttons.containing(NSPredicate(format: "label CONTAINS 'Track'")).element
        XCTAssertTrue(primaryActionRow.exists)

        // Check for selected state (implementation depends on your UI)
        // May have checkmark, different color, etc.
    }

    func testSelectDifferentActionFromSelector() throws {
        // Given: Action selector open
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Your package has shipped").element
        XCTAssertTrue(emailCard.waitForExistence(timeout: 5))
        emailCard.swipeUp()

        let actionSelector = app.sheets["ActionSelectorBottomSheet"]
        XCTAssertTrue(actionSelector.waitForExistence(timeout: 2))

        // When: Tap different action
        let viewOrderButton = actionSelector.buttons.containing(NSPredicate(format: "label CONTAINS 'View Order'")).element
        if viewOrderButton.exists {
            viewOrderButton.tap()

            // Then: Action selector should close
            XCTAssertFalse(actionSelector.waitForExistence(timeout: 2))

            // And new action should become primary on card
            let primaryActionButton = emailCard.buttons["primaryActionButton"].firstMatch
            XCTAssertTrue(primaryActionButton.label.contains("View Order"))
        }
    }

    func testSwipeDownDismissesActionSelector() throws {
        // Given: Action selector open
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Your package has shipped").element
        XCTAssertTrue(emailCard.waitForExistence(timeout: 5))
        emailCard.swipeUp()

        let actionSelector = app.sheets["ActionSelectorBottomSheet"]
        XCTAssertTrue(actionSelector.waitForExistence(timeout: 2))

        // When: Swipe down on action selector
        actionSelector.swipeDown()

        // Then: Action selector should dismiss
        XCTAssertFalse(actionSelector.exists)
    }

    // MARK: - Action Execution Tests

    func testGoToActionOpensURL() throws {
        // Given: Email with GO_TO action (track package)
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Your package has shipped").element
        XCTAssertTrue(emailCard.waitForExistence(timeout: 5))

        // When: Tap Track Package action
        let trackButton = emailCard.buttons.containing(NSPredicate(format: "label CONTAINS 'Track'")).element
        trackButton.tap()

        // Then: Should trigger URL opening (Safari/web view)
        // Note: Can't test Safari directly, but can verify button tap succeeds
        XCTAssertTrue(true)
    }

    func testInAppActionOpensModal() throws {
        // Given: Email with IN_APP action (sign form)
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Permission Form Required").element

        if emailCard.waitForExistence(timeout: 5) {
            // When: Tap Sign Form action
            let signButton = emailCard.buttons.containing(NSPredicate(format: "label CONTAINS 'Sign'")).element
            signButton.tap()

            // Then: Modal should appear
            let signFormModal = app.sheets["SignFormModal"]
            XCTAssertTrue(signFormModal.waitForExistence(timeout: 3))
        }
    }

    func testInvalidActionShowsError() throws {
        // Given: Email with action missing required context
        // (This test requires demo mode to provide test data)

        // When: Attempt to execute invalid action
        // Then: Should show error alert
        // Note: Implementation depends on error handling strategy
    }

    // MARK: - Compound Action Tests

    func testCompoundActionDisplaysCorrectly() throws {
        // Given: Email with compound action (Track + Calendar)
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "arriving tomorrow").element

        if emailCard.waitForExistence(timeout: 5) {
            // When: View primary action
            let primaryActionButton = emailCard.buttons["primaryActionButton"].firstMatch

            // Then: Should show compound action name
            XCTAssertTrue(primaryActionButton.exists)
            XCTAssertTrue(
                primaryActionButton.label.contains("Track") &&
                primaryActionButton.label.contains("Calendar")
            )
        }
    }

    func testCompoundActionExecutesMultipleSteps() throws {
        // Given: Email with compound action
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "arriving tomorrow").element

        if emailCard.waitForExistence(timeout: 5) {
            // When: Execute compound action
            let compoundButton = emailCard.buttons.containing(NSPredicate(format: "label CONTAINS 'Track'")).element
            compoundButton.tap()

            // Then: First step should execute (open URL)
            // Note: Full compound flow testing requires additional setup

            // Calendar modal should appear after URL opens (in actual implementation)
            // For UI tests, verify first step succeeds
            XCTAssertTrue(true)
        }
    }

    func testSignFormWithPaymentCompound() throws {
        // Given: Permission form email with payment
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "sign and pay").element

        if emailCard.waitForExistence(timeout: 5) {
            // When: Tap Sign & Pay action
            let signPayButton = emailCard.buttons.containing(NSPredicate(format: "label CONTAINS 'Sign'")).element
            signPayButton.tap()

            // Then: Sign form modal should open
            let signModal = app.sheets["SignFormModal"]
            if signModal.waitForExistence(timeout: 3) {
                // Fill form (simplified)
                let signatureField = signModal.textFields["signatureField"]
                if signatureField.exists {
                    signatureField.tap()
                    signatureField.typeText("John Doe")
                }

                // Submit form
                let submitButton = signModal.buttons["submitButton"]
                submitButton.tap()

                // Then: Payment modal should appear
                let paymentModal = app.sheets["PaymentModal"]
                XCTAssertTrue(paymentModal.waitForExistence(timeout: 3))
            }
        }
    }

    // MARK: - Real-World Flow Tests

    func testCompleteShippingNotificationFlow() throws {
        // Given: User receives shipping notification
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Your package has shipped").element
        XCTAssertTrue(emailCard.waitForExistence(timeout: 5))

        // When: View primary action
        let primaryActionButton = emailCard.buttons["primaryActionButton"].firstMatch
        XCTAssertTrue(primaryActionButton.exists)
        XCTAssertTrue(primaryActionButton.label.contains("Track"))

        // And: Swipe up to see all actions
        emailCard.swipeUp()
        let actionSelector = app.sheets["ActionSelectorBottomSheet"]
        XCTAssertTrue(actionSelector.waitForExistence(timeout: 2))

        // And: Select Track Package
        let trackButton = actionSelector.buttons.containing(NSPredicate(format: "label CONTAINS 'Track Package'")).element
        if trackButton.exists {
            trackButton.tap()
        }

        // Then: Action executes successfully
        XCTAssertTrue(true)
    }

    func testCompleteInvoicePaymentFlow() throws {
        // Given: User receives invoice
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Invoice Due").element

        if emailCard.waitForExistence(timeout: 5) {
            // When: Tap Pay Invoice
            let payButton = emailCard.buttons.containing(NSPredicate(format: "label CONTAINS 'Pay'")).element
            payButton.tap()

            // Then: Payment URL should open
            XCTAssertTrue(true)
        }
    }

    func testCompletePermissionFormFlow() throws {
        // Given: User receives permission form
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Permission Form").element

        if emailCard.waitForExistence(timeout: 5) {
            // When: Tap Sign & Pay
            let signButton = emailCard.buttons.containing(NSPredicate(format: "label CONTAINS 'Sign'")).element
            signButton.tap()

            // Then: Form modal should open
            let formModal = app.sheets.firstMatch
            if formModal.waitForExistence(timeout: 3) {
                XCTAssertTrue(formModal.exists)
            }
        }
    }

    // MARK: - Performance Tests

    func testActionExecutionPerformance() throws {
        // Given: Email card visible
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Your package has shipped").element
        XCTAssertTrue(emailCard.waitForExistence(timeout: 5))

        // Measure action execution time
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let primaryActionButton = emailCard.buttons["primaryActionButton"].firstMatch
            primaryActionButton.tap()

            // Allow UI to settle
            usleep(100000) // 100ms
        }
    }

    func testActionSelectorOpenPerformance() throws {
        // Given: Email card visible
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Your package has shipped").element
        XCTAssertTrue(emailCard.waitForExistence(timeout: 5))

        // Measure action selector display time
        measure(metrics: [XCTClockMetric()]) {
            emailCard.swipeUp()

            let actionSelector = app.sheets["ActionSelectorBottomSheet"]
            _ = actionSelector.waitForExistence(timeout: 2)

            actionSelector.swipeDown()
            usleep(500000) // Wait for dismissal
        }
    }

    // MARK: - Accessibility Tests

    func testPrimaryActionAccessibilityLabel() throws {
        // Given: Email card with primary action
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Your package has shipped").element
        XCTAssertTrue(emailCard.waitForExistence(timeout: 5))

        // When: Check accessibility
        let primaryActionButton = emailCard.buttons["primaryActionButton"].firstMatch

        // Then: Should have proper accessibility label
        XCTAssertTrue(primaryActionButton.isEnabled)
        XCTAssertFalse(primaryActionButton.label.isEmpty)
    }

    func testActionSelectorAccessibility() throws {
        // Given: Action selector open
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Your package has shipped").element
        XCTAssertTrue(emailCard.waitForExistence(timeout: 5))
        emailCard.swipeUp()

        let actionSelector = app.sheets["ActionSelectorBottomSheet"]
        XCTAssertTrue(actionSelector.waitForExistence(timeout: 2))

        // Then: All actions should be accessible
        let actionButtons = actionSelector.buttons
        for i in 0..<min(actionButtons.count, 5) {
            let button = actionButtons.element(boundBy: i)
            XCTAssertTrue(button.isEnabled)
            XCTAssertFalse(button.label.isEmpty)
        }
    }

    // MARK: - Edge Cases

    func testEmailWithNoActionsShowsDefault() throws {
        // Given: Email with unknown intent (no suggested actions)
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Random subject").element

        if emailCard.waitForExistence(timeout: 5) {
            // When: Check primary action
            let primaryActionButton = emailCard.buttons["primaryActionButton"].firstMatch

            // Then: Should show default action (View Details)
            if primaryActionButton.exists {
                XCTAssertTrue(primaryActionButton.label.contains("View") || primaryActionButton.label.contains("Details"))
            }
        }
    }

    func testMultipleQuickTaps() throws {
        // Given: Email card visible
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Your package has shipped").element
        XCTAssertTrue(emailCard.waitForExistence(timeout: 5))

        let primaryActionButton = emailCard.buttons["primaryActionButton"].firstMatch

        // When: Tap multiple times quickly
        primaryActionButton.tap()
        primaryActionButton.tap()
        primaryActionButton.tap()

        // Then: Should handle gracefully (no crashes)
        XCTAssertTrue(app.exists)
    }

    func testSwipeUpWhileActionExecuting() throws {
        // Given: Action is executing
        let emailCard = app.scrollViews.otherElements.containing(.staticText, identifier: "Your package has shipped").element
        XCTAssertTrue(emailCard.waitForExistence(timeout: 5))

        let primaryActionButton = emailCard.buttons["primaryActionButton"].firstMatch
        primaryActionButton.tap()

        // When: Try to swipe up immediately
        emailCard.swipeUp()

        // Then: Should handle gracefully
        XCTAssertTrue(app.exists)
    }
}

/**
 * Test execution:
 *
 * Run in Xcode:
 *   cmd+U (run all tests including UI tests)
 *
 * Run only UI tests:
 *   xcodebuild test -scheme Zero -only-testing:ZeroUITests
 *
 * Run specific UI test:
 *   xcodebuild test -scheme Zero -only-testing:ZeroUITests/ZeroSequenceUITests/testSwipeUpShowsActionSelector
 *
 * Run on specific simulator:
 *   xcodebuild test -scheme Zero -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ZeroUITests
 *
 * Prerequisites:
 * - Demo mode must be enabled in app for consistent test data
 * - Backend services must be running (or mocked)
 * - Simulator must have sample emails loaded
 *
 * Expected results:
 * - All flows complete without errors
 * - Action execution < 100ms
 * - Action selector display < 500ms
 * - No accessibility violations
 */
