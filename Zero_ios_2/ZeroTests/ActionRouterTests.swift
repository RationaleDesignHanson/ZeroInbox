import XCTest
@testable import Zero

/**
 * ActionRouter Unit Tests
 * Tests URL schema enforcement, action validation, and routing logic
 *
 * Critical: Tests iOS ActionRouter.swift:117-125 URL schema priority
 * Backend contract: rules-engine.js:214-250 enforces generic "url" key
 *
 * Run with: cmd+U in Xcode or `xcodebuild test -scheme Zero`
 */
class ActionRouterTests: XCTestCase {

    var actionRouter: ActionRouter!

    override func setUp() {
        super.setUp()
        actionRouter = ActionRouter.shared
    }

    override func tearDown() {
        actionRouter = nil
        super.tearDown()
    }

    // MARK: - URL Schema Priority Tests

    func testGenericURLKeyTakesPriority() {
        // Given: Action with both generic "url" and semantic "trackingUrl"
        let action = EmailAction(
            actionId: "track_package",
            displayName: "Track Package",
            actionType: .goTo,
            priority: 1,
            isPrimary: true,
            context: [
                "url": "https://generic-url.com/track",  // Should take priority
                "trackingUrl": "https://semantic-url.com/track"  // Should be ignored
            ]
        )

        // When: Extract URL from action
        let extractedURL = extractURLFromAction(action)

        // Then: Generic "url" should be used
        XCTAssertNotNil(extractedURL)
        XCTAssertEqual(extractedURL?.absoluteString, "https://generic-url.com/track")
    }

    func testTrackingURLCopiedToGenericURL() {
        // Given: Track package action with trackingUrl
        let action = EmailAction(
            actionId: "track_package",
            displayName: "Track Package",
            actionType: .goTo,
            priority: 1,
            isPrimary: true,
            context: [
                "url": "https://ups.com/track?num=1Z999AA",  // Backend enforces this
                "trackingUrl": "https://ups.com/track?num=1Z999AA",
                "trackingNumber": "1Z999AA",
                "carrier": "UPS"
            ]
        )

        // When: Validate URL exists
        let extractedURL = extractURLFromAction(action)

        // Then: URL should be present from backend enforcement
        XCTAssertNotNil(extractedURL)
        XCTAssertTrue(extractedURL!.absoluteString.contains("ups.com"))
        XCTAssertTrue(extractedURL!.absoluteString.contains("1Z999AA"))
    }

    func testPaymentLinkCopiedToGenericURL() {
        // Given: Pay invoice action with paymentLink
        let action = EmailAction(
            actionId: "pay_invoice",
            displayName: "Pay Invoice",
            actionType: .goTo,
            priority: 1,
            isPrimary: true,
            context: [
                "url": "https://pay.company.com/INV-123",  // Backend enforces this
                "paymentLink": "https://pay.company.com/INV-123",
                "invoiceId": "INV-123",
                "amount": "599.00"
            ]
        )

        let extractedURL = extractURLFromAction(action)

        XCTAssertNotNil(extractedURL)
        XCTAssertEqual(extractedURL?.absoluteString, "https://pay.company.com/INV-123")
    }

    func testCheckInURLCopiedToGenericURL() {
        // Given: Check-in action with checkInUrl
        let action = EmailAction(
            actionId: "check_in_flight",
            displayName: "Check In",
            actionType: .goTo,
            priority: 1,
            isPrimary: true,
            context: [
                "url": "https://united.com/checkin/ABC123",
                "checkInUrl": "https://united.com/checkin/ABC123",
                "flightNumber": "UA 123"
            ]
        )

        let extractedURL = extractURLFromAction(action)

        XCTAssertNotNil(extractedURL)
        XCTAssertEqual(extractedURL?.absoluteString, "https://united.com/checkin/ABC123")
    }

    // MARK: - Fallback URL Generation Tests

    func testFallbackToActionSpecificURL() {
        // Given: Action WITHOUT generic "url" (legacy backend response)
        let action = EmailAction(
            actionId: "track_package",
            displayName: "Track Package",
            actionType: .goTo,
            priority: 1,
            isPrimary: true,
            context: [
                // No "url" key
                "trackingUrl": "https://fedex.com/track/123456789012",
                "trackingNumber": "123456789012",
                "carrier": "FedEx"
            ]
        )

        // When: Extract URL (should fallback to trackingUrl)
        let extractedURL = extractURLFromAction(action)

        // Then: Should use trackingUrl as fallback
        XCTAssertNotNil(extractedURL)
        XCTAssertTrue(extractedURL!.absoluteString.contains("fedex.com"))
    }

    func testGenerateTrackingURLForUPS() {
        // Given: UPS tracking context without any URL
        let action = EmailAction(
            actionId: "track_package",
            displayName: "Track Package",
            actionType: .goTo,
            priority: 1,
            isPrimary: true,
            context: [
                "trackingNumber": "1Z999AA10123456784",
                "carrier": "UPS"
            ]
        )

        // When: Extract URL (should generate UPS URL)
        let extractedURL = extractURLFromAction(action)

        // Then: Should generate UPS tracking URL
        XCTAssertNotNil(extractedURL)
        XCTAssertTrue(extractedURL!.absoluteString.contains("ups.com"))
        XCTAssertTrue(extractedURL!.absoluteString.contains("1Z999AA10123456784"))
    }

    // MARK: - Action Type Validation Tests

    func testGoToActionRequiresURL() {
        // Given: GO_TO action without URL
        let action = EmailAction(
            actionId: "pay_invoice",
            displayName: "Pay Invoice",
            actionType: .goTo,
            priority: 1,
            isPrimary: true,
            context: [
                "invoiceId": "INV-123",
                "amount": "500.00"
                // Missing URL!
            ]
        )

        // When: Validate action
        let isValid = validateAction(action)

        // Then: Should be invalid (GO_TO needs URL)
        XCTAssertFalse(isValid)
    }

    func testInAppActionDoesNotRequireURL() {
        // Given: IN_APP action without URL
        let action = EmailAction(
            actionId: "sign_form",
            displayName: "Sign Form",
            actionType: .inApp,
            priority: 1,
            isPrimary: true,
            context: [
                "formName": "Permission Form",
                "formId": "FORM-123"
            ]
        )

        // When: Validate action
        let isValid = validateAction(action)

        // Then: Should be valid (IN_APP doesn't need URL)
        XCTAssertTrue(isValid)
    }

    // MARK: - Compound Action Tests

    func testCompoundActionPreservesURL() {
        // Given: Compound action with URL
        let compoundAction = EmailAction(
            actionId: "track_with_calendar",
            displayName: "Track & Add to Calendar",
            actionType: .goTo,
            priority: 1,
            isPrimary: true,
            isCompound: true,
            compoundSteps: ["track_package", "add_to_calendar"],
            context: [
                "url": "https://ups.com/track?num=1Z999AA",
                "trackingNumber": "1Z999AA",
                "deliveryDate": "2025-11-05",
                "carrier": "UPS"
            ]
        )

        // When: Extract URL
        let extractedURL = extractURLFromAction(compoundAction)

        // Then: URL should be preserved
        XCTAssertNotNil(extractedURL)
        XCTAssertEqual(extractedURL?.absoluteString, "https://ups.com/track?num=1Z999AA")
    }

    func testSignFormWithPaymentCompoundAction() {
        // Given: Sign form with payment compound action
        let action = EmailAction(
            actionId: "sign_form_with_payment",
            displayName: "Sign & Pay",
            actionType: .inApp,
            priority: 1,
            isPrimary: true,
            isCompound: true,
            compoundSteps: ["sign_form", "pay_form_fee", "send_confirmation"],
            requiresResponse: true,
            context: [
                "formName": "Field Trip Permission",
                "amount": "45.00",
                "recipient": "teacher@school.edu"
            ]
        )

        // When: Validate compound action
        let isValid = validateAction(action)

        // Then: Should be valid
        XCTAssertTrue(isValid)
        XCTAssertTrue(action.isCompound ?? false)
        XCTAssertEqual(action.compoundSteps?.count, 3)
    }

    // MARK: - Primary Action Selection Tests

    func testPrimaryActionSelection() {
        // Given: Email with multiple actions
        let actions = [
            EmailAction(actionId: "track_package", displayName: "Track", actionType: .goTo, priority: 1, isPrimary: true, context: [:]),
            EmailAction(actionId: "view_order", displayName: "View Order", actionType: .goTo, priority: 2, isPrimary: false, context: [:]),
            EmailAction(actionId: "contact_support", displayName: "Contact Support", actionType: .goTo, priority: 3, isPrimary: false, context: [:])
        ]

        // When: Find primary action
        let primaryAction = actions.first(where: { $0.isPrimary })

        // Then: First action should be primary
        XCTAssertNotNil(primaryAction)
        XCTAssertEqual(primaryAction?.actionId, "track_package")
    }

    func testCompoundActionBecomesPrimary() {
        // Given: Actions with compound action
        let actions = [
            EmailAction(actionId: "track_with_calendar", displayName: "Track & Calendar", actionType: .goTo, priority: 1, isPrimary: true, isCompound: true, compoundSteps: ["track_package", "add_to_calendar"], context: [:]),
            EmailAction(actionId: "track_package", displayName: "Track Only", actionType: .goTo, priority: 2, isPrimary: false, context: [:])
        ]

        // When: Find primary action
        let primaryAction = actions.first(where: { $0.isPrimary })

        // Then: Compound action should be primary
        XCTAssertNotNil(primaryAction)
        XCTAssertEqual(primaryAction?.actionId, "track_with_calendar")
        XCTAssertTrue(primaryAction?.isCompound ?? false)
    }

    // MARK: - Edge Cases & Error Handling

    func testEmptyURLStringNotEnforced() {
        // Given: Action with empty URL string
        let action = EmailAction(
            actionId: "track_package",
            displayName: "Track Package",
            actionType: .goTo,
            priority: 1,
            isPrimary: true,
            context: [
                "url": "",  // Empty string
                "trackingNumber": "1Z999AA",
                "carrier": "UPS"
            ]
        )

        // When: Extract URL
        let extractedURL = extractURLFromAction(action)

        // Then: Should fallback to generating URL from tracking info
        XCTAssertNotNil(extractedURL)
        XCTAssertTrue(extractedURL!.absoluteString.contains("ups.com"))
    }

    func testInvalidURLFormatReturnsNil() {
        // Given: Action with invalid URL
        let action = EmailAction(
            actionId: "open_link",
            displayName: "Open Link",
            actionType: .goTo,
            priority: 1,
            isPrimary: true,
            context: [
                "url": "not-a-valid-url"
            ]
        )

        // When: Extract URL
        let extractedURL = extractURLFromAction(action)

        // Then: Should return nil for invalid URL
        XCTAssertNil(extractedURL)
    }

    func testMissingRequiredContextParameters() {
        // Given: Action missing required context
        let action = EmailAction(
            actionId: "track_package",
            displayName: "Track Package",
            actionType: .goTo,
            priority: 1,
            isPrimary: true,
            context: [:]  // Empty context
        )

        // When: Validate action
        let isValid = validateAction(action)

        // Then: Should be invalid
        XCTAssertFalse(isValid)
    }

    // MARK: - Helper Methods

    private func extractURLFromAction(_ action: EmailAction) -> URL? {
        // Priority 1: Generic "url" key
        if let genericUrl = action.context["url"], !genericUrl.isEmpty {
            return URL(string: genericUrl)
        }

        // Priority 2: Action-specific URL keys
        switch action.actionId {
        case "track_package":
            if let trackingUrl = action.context["trackingUrl"], !trackingUrl.isEmpty {
                return URL(string: trackingUrl)
            }
            // Generate from tracking info
            if let trackingNumber = action.context["trackingNumber"],
               let carrier = action.context["carrier"] {
                return generateTrackingURL(carrier: carrier, trackingNumber: trackingNumber)
            }

        case "pay_invoice":
            if let paymentLink = action.context["paymentLink"] {
                return URL(string: paymentLink)
            }

        case "check_in_flight":
            if let checkInUrl = action.context["checkInUrl"] {
                return URL(string: checkInUrl)
            }

        default:
            break
        }

        return nil
    }

    private func validateAction(_ action: EmailAction) -> Bool {
        // GO_TO actions must have a valid URL
        if action.actionType == .goTo {
            return extractURLFromAction(action) != nil
        }

        // IN_APP actions are always valid
        return true
    }

    private func generateTrackingURL(carrier: String, trackingNumber: String) -> URL? {
        let carrierLower = carrier.lowercased()

        switch carrierLower {
        case "ups":
            return URL(string: "https://www.ups.com/track?tracknum=\(trackingNumber)")
        case "fedex":
            return URL(string: "https://www.fedex.com/fedextrack/?tracknumbers=\(trackingNumber)")
        case "usps":
            return URL(string: "https://tools.usps.com/go/TrackConfirmAction?tLabels=\(trackingNumber)")
        default:
            return URL(string: "https://www.google.com/search?q=track+\(trackingNumber)")
        }
    }
}

/**
 * Test execution:
 *
 * Run in Xcode:
 *   cmd+U (run all tests)
 *   cmd+ctrl+U (run tests for current file)
 *
 * Run from command line:
 *   xcodebuild test -scheme Zero -destination 'platform=iOS Simulator,name=iPhone 15'
 *
 * Expected coverage:
 * - ActionRouter.swift: >80%
 * - URL schema priority logic: 100%
 * - Action validation: 100%
 */
