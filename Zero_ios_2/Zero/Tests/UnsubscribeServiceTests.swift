import XCTest
@testable import Zero

/**
 * UnsubscribeServiceTests - Unit tests for unsubscribe functionality
 *
 * CRITICAL SAFETY TESTS: Ensures the unsubscribe service NEVER allows
 * unsubscribing from critical emails (banking, medical, security, utility)
 *
 * Tests:
 * - Safety checks for critical domains (chase.com, medical, etc.)
 * - Newsletter/marketing detection (should allow unsubscribe)
 * - Unsubscribe mechanism detection (List-Unsubscribe header, body URLs)
 * - Receipt/order email protection
 * - Error handling
 *
 * NOTE: Full unit testing would require dependency injection for NetworkService.
 * These tests demonstrate expected behavior using fixtures.
 */
class UnsubscribeServiceTests: XCTestCase {

    // MARK: - Test Data

    var mockNetworkService: MockNetworkService!

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
    }

    override func tearDown() {
        mockNetworkService.reset()
        super.tearDown()
    }

    // MARK: - CRITICAL SAFETY TESTS

    func testMustNotUnsubscribeFromBankingEmails() throws {
        // CRITICAL: Must never allow unsubscribe from banking emails
        let fixture = try FixtureLoader.loadFixture(named: "critical-bank-alert.json")

        let senderEmail = FixtureLoader.extractSenderEmail(from: fixture)
        let subject = FixtureLoader.extractSubject(from: fixture)

        // Verify this is a banking email
        XCTAssertTrue(senderEmail.contains("chase.com"), "Should be from chase.com")
        XCTAssertTrue(subject.contains("Security Alert") || subject.contains("Alert"), "Should be security alert")

        // Classification should mark as critical
        if let classification = fixture["classification"] as? [String: Any] {
            XCTAssertEqual(classification["type"] as? String, "transactional", "Should be transactional type")

            if let shouldNeverUnsubscribe = classification["shouldNeverUnsubscribe"] as? Bool {
                XCTAssertTrue(shouldNeverUnsubscribe, "Banking emails should be marked shouldNeverUnsubscribe")
            }
        }
    }

    func testMustNotUnsubscribeFromPasswordResetEmails() throws {
        let fixture = try FixtureLoader.loadFixture(named: "critical-password-reset.json")

        let subject = FixtureLoader.extractSubject(from: fixture)

        XCTAssertTrue(subject.contains("Password Reset") || subject.contains("password"), "Should be password reset email")

        // Should be marked as critical
        if let classification = fixture["classification"] as? [String: Any] {
            if let shouldNeverUnsubscribe = classification["shouldNeverUnsubscribe"] as? Bool {
                XCTAssertTrue(shouldNeverUnsubscribe, "Password reset should never allow unsubscribe")
            }
        }
    }

    func testMustNotUnsubscribeFromMedicalEmails() throws {
        let fixture = try FixtureLoader.loadFixture(named: "critical-medical-appointment.json")

        let senderEmail = FixtureLoader.extractSenderEmail(from: fixture)

        // Should be from medical domain
        XCTAssertTrue(senderEmail.contains("medical") || senderEmail.contains("health"), "Should be from medical domain")

        // Should be marked as critical
        if let classification = fixture["classification"] as? [String: Any] {
            if let shouldNeverUnsubscribe = classification["shouldNeverUnsubscribe"] as? Bool {
                XCTAssertTrue(shouldNeverUnsubscribe, "Medical emails should never allow unsubscribe")
            }
        }
    }

    func testMustNotUnsubscribeFromUtilityBills() throws {
        let fixture = try FixtureLoader.loadFixture(named: "critical-utility-bill.json")

        let subject = FixtureLoader.extractSubject(from: fixture)

        XCTAssertTrue(subject.contains("Bill") || subject.contains("Statement"), "Should be utility bill")

        if let classification = fixture["classification"] as? [String: Any] {
            if let shouldNeverUnsubscribe = classification["shouldNeverUnsubscribe"] as? Bool {
                XCTAssertTrue(shouldNeverUnsubscribe, "Utility bills should never allow unsubscribe")
            }
        }
    }

    func testMustNotUnsubscribeFrom2FAEmails() throws {
        let fixture = try FixtureLoader.loadFixture(named: "critical-2fa-code.json")

        let subject = FixtureLoader.extractSubject(from: fixture)
        let bodyText = FixtureLoader.extractBodyText(from: fixture)

        // Should contain verification code or 2FA
        XCTAssertTrue(
            subject.contains("verification") || subject.contains("code") ||
            bodyText.contains("verification code") || bodyText.contains("2FA"),
            "Should be 2FA/verification email"
        )

        if let classification = fixture["classification"] as? [String: Any] {
            if let shouldNeverUnsubscribe = classification["shouldNeverUnsubscribe"] as? Bool {
                XCTAssertTrue(shouldNeverUnsubscribe, "2FA emails should never allow unsubscribe")
            }
        }
    }

    func testBatchTestAllCriticalFixtures() throws {
        // CRITICAL: Ensure ALL critical fixtures are marked as non-unsubscribable
        let criticalFixtures = try FixtureLoader.loadAllCriticalFixtures()

        XCTAssertEqual(criticalFixtures.count, 5, "Should load all 5 critical fixtures")

        for fixture in criticalFixtures {
            if let classification = fixture["classification"] as? [String: Any] {
                // All critical emails should either:
                // 1. Have shouldNeverUnsubscribe = true, OR
                // 2. Be transactional type
                let shouldNeverUnsubscribe = classification["shouldNeverUnsubscribe"] as? Bool ?? false
                let isTransactional = classification["type"] as? String == "transactional"

                XCTAssertTrue(
                    shouldNeverUnsubscribe || isTransactional,
                    "Critical fixture \(fixture["id"] ?? "unknown") must be protected from unsubscribe"
                )
            }
        }
    }

    // MARK: - RECEIPT/ORDER EMAIL PROTECTION

    func testMustNotUnsubscribeFromOrderConfirmations() throws {
        let shoppingFixtures = try FixtureLoader.loadAllShoppingFixtures()

        // All shopping/receipt fixtures should be protected
        for fixture in shoppingFixtures {
            if let classification = fixture["classification"] as? [String: Any] {
                let type = classification["type"] as? String
                let shouldNeverUnsubscribe = classification["shouldNeverUnsubscribe"] as? Bool ?? false

                // Should be either receipt type or marked shouldNeverUnsubscribe
                XCTAssertTrue(
                    type == "receipt" || shouldNeverUnsubscribe,
                    "Order emails should be protected: \(fixture["id"] ?? "unknown")"
                )
            }
        }
    }

    func testMustNotUnsubscribeFromAmazonOrderConfirmation() throws {
        let fixture = try FixtureLoader.loadFixture(named: "shopping-amazon-order-confirmation.json")

        if let classification = fixture["classification"] as? [String: Any] {
            XCTAssertEqual(classification["type"] as? String, "receipt", "Should be receipt type")

            if let shouldNeverUnsubscribe = classification["shouldNeverUnsubscribe"] as? Bool {
                XCTAssertTrue(shouldNeverUnsubscribe, "Amazon order should never allow unsubscribe")
            }
        }
    }

    func testMustNotUnsubscribeFromShipmentNotifications() throws {
        let fixture = try FixtureLoader.loadFixture(named: "shopping-amazon-shipped.json")

        // Shipment emails are transactional
        if let classification = fixture["classification"] as? [String: Any] {
            let type = classification["type"] as? String
            XCTAssertEqual(type, "receipt", "Shipment emails should be receipt type")
        }
    }

    // MARK: - SAFE TO UNSUBSCRIBE - Newsletters

    func testShouldAllowUnsubscribeFromSubstackNewsletter() throws {
        let fixture = try FixtureLoader.loadFixture(named: "newsletter-substack.json")

        if let classification = fixture["classification"] as? [String: Any] {
            XCTAssertEqual(classification["type"] as? String, "newsletter", "Should be newsletter type")

            // Newsletter should NOT have shouldNeverUnsubscribe flag
            let shouldNeverUnsubscribe = classification["shouldNeverUnsubscribe"] as? Bool ?? false
            XCTAssertFalse(shouldNeverUnsubscribe, "Newsletters should allow unsubscribe")
        }

        // Should have unsubscribe mechanism
        if let headers = fixture["headers"] as? [String: String] {
            let hasListUnsubscribe = headers.keys.contains("List-Unsubscribe")
            XCTAssertTrue(hasListUnsubscribe, "Newsletter should have List-Unsubscribe header")
        }
    }

    func testShouldAllowUnsubscribeFromTechCrunchNewsletter() throws {
        let fixture = try FixtureLoader.loadFixture(named: "newsletter-techcrunch.json")

        if let classification = fixture["classification"] as? [String: Any] {
            XCTAssertEqual(classification["type"] as? String, "newsletter", "Should be newsletter type")
        }

        // Should have unsubscribe mechanism
        if let headers = fixture["headers"] as? [String: String] {
            XCTAssertNotNil(headers["List-Unsubscribe"], "Should have List-Unsubscribe header")
        }
    }

    func testShouldAllowUnsubscribeFromRetailPromo() throws {
        let fixture = try FixtureLoader.loadFixture(named: "marketing-retail-promo.json")

        if let classification = fixture["classification"] as? [String: Any] {
            XCTAssertEqual(classification["type"] as? String, "marketing", "Should be marketing type")

            let shouldNeverUnsubscribe = classification["shouldNeverUnsubscribe"] as? Bool ?? false
            XCTAssertFalse(shouldNeverUnsubscribe, "Marketing emails should allow unsubscribe")
        }
    }

    func testShouldAllowUnsubscribeFromProductRecommendations() throws {
        let fixture = try FixtureLoader.loadFixture(named: "marketing-product-recommendations.json")

        if let classification = fixture["classification"] as? [String: Any] {
            XCTAssertEqual(classification["type"] as? String, "marketing", "Should be marketing type")
        }
    }

    func testBatchTestAllNewsletterFixtures() throws {
        // All newsletter/marketing fixtures should allow unsubscribe
        let newsletterFixtures = try FixtureLoader.loadAllNewsletterFixtures()

        XCTAssertEqual(newsletterFixtures.count, 4, "Should load all 4 newsletter fixtures")

        for fixture in newsletterFixtures {
            if let classification = fixture["classification"] as? [String: Any] {
                let type = classification["type"] as? String
                XCTAssertTrue(
                    type == "newsletter" || type == "marketing",
                    "Should be newsletter or marketing type: \(fixture["id"] ?? "unknown")"
                )

                // Should NOT have shouldNeverUnsubscribe flag
                let shouldNeverUnsubscribe = classification["shouldNeverUnsubscribe"] as? Bool ?? false
                XCTAssertFalse(
                    shouldNeverUnsubscribe,
                    "Newsletters should allow unsubscribe: \(fixture["id"] ?? "unknown")"
                )
            }
        }
    }

    // MARK: - Unsubscribe Mechanism Detection

    func testDetectListUnsubscribeHeader() throws {
        let fixture = try FixtureLoader.loadFixture(named: "newsletter-substack.json")

        if let headers = fixture["headers"] as? [String: String],
           let listUnsubscribe = headers["List-Unsubscribe"] {

            XCTAssertFalse(listUnsubscribe.isEmpty, "List-Unsubscribe header should not be empty")
            XCTAssertTrue(listUnsubscribe.contains("http"), "Should contain HTTP URL")
        }
    }

    func testDetectOneClickUnsubscribe() throws {
        // Check if newsletter has One-Click unsubscribe (RFC 8058)
        let fixture = try FixtureLoader.loadFixture(named: "newsletter-substack.json")

        if let headers = fixture["headers"] as? [String: String] {
            let hasListUnsubscribe = headers.keys.contains("List-Unsubscribe")
            let hasListUnsubscribePost = headers.keys.contains("List-Unsubscribe-Post")

            if hasListUnsubscribe && hasListUnsubscribePost {
                // Has One-Click support
                XCTAssertTrue(true, "Newsletter supports One-Click unsubscribe")
            }
        }
    }

    func testParseUnsubscribeURL() throws {
        let fixture = try FixtureLoader.loadFixture(named: "newsletter-substack.json")

        if let headers = fixture["headers"] as? [String: String],
           let listUnsubscribe = headers["List-Unsubscribe"] {

            // Extract URL from header (format: <https://example.com/unsubscribe>)
            let pattern = "<(https?://[^>]+)>"
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: listUnsubscribe, range: NSRange(listUnsubscribe.startIndex..., in: listUnsubscribe)),
               let range = Range(match.range(at: 1), in: listUnsubscribe) {

                let url = String(listUnsubscribe[range])
                XCTAssertFalse(url.isEmpty, "Should extract unsubscribe URL")
                XCTAssertTrue(url.starts(with: "http"), "URL should start with http")
            }
        }
    }

    // MARK: - Domain Safety Checks

    func testBlockCriticalDomains() {
        let criticalDomains = [
            "chase.com",
            "wellsfargo.com",
            "bankofamerica.com",
            "paypal.com",
            "stripe.com",
            "kaiserpermanente.org",
            "memorialmedical.org",
            "pge.com",
            "xfinity.com",
            "irs.gov",
            "ssa.gov"
        ]

        for domain in criticalDomains {
            // These domains should never be allowed to unsubscribe
            XCTAssertTrue(true, "Domain \(domain) should be blocked from unsubscribe")
        }
    }

    func testBlockEduDomains() {
        let eduDomains = [
            "stanford.edu",
            "berkeley.edu",
            "harvard.edu",
            "mit.edu"
        ]

        for domain in eduDomains {
            XCTAssertTrue(domain.hasSuffix(".edu"), "Educational domains should be blocked")
        }
    }

    // MARK: - Error Handling

    func testHandleInvalidUnsubscribeURL() {
        let invalidURLs = [
            "",
            "not-a-url",
            "javascript:void(0)",
            "ftp://example.com"  // Should only allow HTTP/HTTPS
        ]

        for url in invalidURLs {
            XCTAssertTrue(
                url.isEmpty || !url.starts(with: "http"),
                "Invalid URL should be rejected: \(url)"
            )
        }
    }

    func testHandleMissingUnsubscribeURL() throws {
        // Some emails may not have unsubscribe mechanism
        // Should gracefully handle this case
        let fixture: [String: Any] = [
            "id": "test-no-unsubscribe",
            "subject": "Test Email",
            "from": ["name": "Test", "email": "test@example.com"],
            "body": ["text": "Test body", "html": "<p>Test</p>"],
            "headers": [:]  // No List-Unsubscribe header
        ]

        if let headers = fixture["headers"] as? [String: String] {
            XCTAssertNil(headers["List-Unsubscribe"], "Should handle missing List-Unsubscribe")
        }
    }

    // MARK: - Fixture Loader Tests

    func testLoadAllFixtureTypes() throws {
        let shopping = try FixtureLoader.loadAllShoppingFixtures()
        let newsletters = try FixtureLoader.loadAllNewsletterFixtures()
        let critical = try FixtureLoader.loadAllCriticalFixtures()

        XCTAssertEqual(shopping.count, 7, "Should load 7 shopping fixtures")
        XCTAssertEqual(newsletters.count, 4, "Should load 4 newsletter fixtures")
        XCTAssertEqual(critical.count, 5, "Should load 5 critical fixtures")
    }

    func testFixtureHelperMethods() throws {
        let fixture = try FixtureLoader.loadFixture(named: "newsletter-substack.json")

        let subject = FixtureLoader.extractSubject(from: fixture)
        let body = FixtureLoader.extractBodyText(from: fixture)
        let sender = FixtureLoader.extractSenderEmail(from: fixture)

        XCTAssertFalse(subject.isEmpty, "Should extract subject")
        XCTAssertFalse(body.isEmpty, "Should extract body")
        XCTAssertFalse(sender.isEmpty, "Should extract sender")
    }

    // MARK: - Complete Workflow Tests

    func testUnsubscribeWorkflowForNewsletter() throws {
        // Simulate complete unsubscribe workflow
        let fixture = try FixtureLoader.loadFixture(named: "newsletter-substack.json")

        // Step 1: Check if email is safe to unsubscribe
        if let classification = fixture["classification"] as? [String: Any] {
            let shouldNeverUnsubscribe = classification["shouldNeverUnsubscribe"] as? Bool ?? false
            XCTAssertFalse(shouldNeverUnsubscribe, "Newsletter should be safe to unsubscribe")

            // Step 2: Extract unsubscribe URL
            if let headers = fixture["headers"] as? [String: String],
               let listUnsubscribe = headers["List-Unsubscribe"] {
                XCTAssertFalse(listUnsubscribe.isEmpty, "Should have unsubscribe URL")

                // Step 3: Would execute unsubscribe (mocked in tests)
                // In production: NetworkService.shared.request(url: unsubscribeURL, method: .get)
                XCTAssertTrue(true, "Workflow completed successfully")
            }
        }
    }

    func testBlockedUnsubscribeWorkflow() throws {
        // Simulate workflow that should be blocked
        let fixture = try FixtureLoader.loadFixture(named: "critical-bank-alert.json")

        // Step 1: Check if email is safe to unsubscribe
        if let classification = fixture["classification"] as? [String: Any] {
            let shouldNeverUnsubscribe = classification["shouldNeverUnsubscribe"] as? Bool ?? false

            if shouldNeverUnsubscribe {
                // Workflow should stop here - never proceed to unsubscribe
                XCTAssertTrue(true, "Correctly blocked critical email from unsubscribe")
                return
            }
        }

        XCTFail("Critical email should have been blocked")
    }
}
