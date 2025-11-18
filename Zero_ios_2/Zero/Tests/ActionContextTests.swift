import XCTest
@testable import Zero

/**
 * ActionContextTests - Unit tests for ActionContext type-safe wrapper
 *
 * Tests:
 * - Type-safe accessors (string, int, double, bool, date, array, dictionary)
 * - Convenience properties for common context keys
 * - Validation of required keys
 * - Date parsing from various formats
 */
class ActionContextTests: XCTestCase {

    // MARK: - Test Data

    private var mockCard: EmailCard!

    override func setUp() {
        super.setUp()
        mockCard = EmailCard(
            id: "test-card-123",
            type: .mail,
            state: .unseen,
            priority: .medium,
            hpa: "3h",
            timeAgo: "3 hours ago",
            title: "Test Email",
            summary: "Test summary",
            body: "Test body content",
            metaCTA: "View Details",
            sender: SenderInfo(
                name: "Test Sender",
                initial: "TS",
                email: "test@example.com"
            )
        )
    }

    // MARK: - Basic Type Accessors

    func testStringAccessor() {
        let context = ActionContext(card: mockCard, context: [
            "name": "John Doe",
            "emptyString": ""
        ])

        XCTAssertEqual(context.string(for: "name"), "John Doe")
        XCTAssertEqual(context.string(for: "nonexistent"), "")
        XCTAssertEqual(context.string(for: "nonexistent", fallback: "default"), "default")
        XCTAssertEqual(context.string(for: "emptyString"), "")
    }

    func testOptionalStringAccessor() {
        let context = ActionContext(card: mockCard, context: [
            "name": "John Doe"
        ])

        XCTAssertEqual(context.optionalString(for: "name"), "John Doe")
        XCTAssertNil(context.optionalString(for: "nonexistent"))
    }

    func testIntAccessor() {
        let context = ActionContext(card: mockCard, context: [
            "count": 42,
            "zero": 0
        ])

        XCTAssertEqual(context.int(for: "count"), 42)
        XCTAssertEqual(context.int(for: "zero"), 0)
        XCTAssertNil(context.int(for: "nonexistent"))
    }

    func testDoubleAccessor() {
        let context = ActionContext(card: mockCard, context: [
            "price": 123.45,
            "zero": 0.0
        ])

        XCTAssertEqual(context.double(for: "price"), 123.45)
        XCTAssertEqual(context.double(for: "zero"), 0.0)
        XCTAssertNil(context.double(for: "nonexistent"))
    }

    func testBoolAccessor() {
        let context = ActionContext(card: mockCard, context: [
            "isActive": true,
            "isDisabled": false
        ])

        XCTAssertTrue(context.bool(for: "isActive"))
        XCTAssertFalse(context.bool(for: "isDisabled"))
        XCTAssertFalse(context.bool(for: "nonexistent"))
        XCTAssertTrue(context.bool(for: "nonexistent", fallback: true))
    }

    func testArrayAccessor() {
        let context = ActionContext(card: mockCard, context: [
            "items": ["apple", "banana", "cherry"],
            "numbers": [1, 2, 3]
        ])

        XCTAssertEqual((context.array(for: "items") as? [String])?.count, 3)
        XCTAssertEqual((context.array(for: "numbers") as? [Int])?.count, 3)
        XCTAssertNil(context.array(for: "nonexistent"))
    }

    func testDictionaryAccessor() {
        let context = ActionContext(card: mockCard, context: [
            "metadata": ["key1": "value1", "key2": 123]
        ])

        let metadata = context.dictionary(for: "metadata")
        XCTAssertNotNil(metadata)
        XCTAssertEqual(metadata?["key1"] as? String, "value1")
        XCTAssertEqual(metadata?["key2"] as? Int, 123)
        XCTAssertNil(context.dictionary(for: "nonexistent"))
    }

    // MARK: - Date Parsing

    func testDateAccessorISO8601() {
        let context = ActionContext(card: mockCard, context: [
            "meetingTime": "2025-03-15T14:30:00Z"
        ])

        let date = context.date(for: "meetingTime")
        XCTAssertNotNil(date)

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date!)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 15)
    }

    func testDateAccessorCommonFormats() {
        let testCases: [String: (Int, Int, Int)] = [
            "2025-03-15": (2025, 3, 15),
            "2025-03-15 14:30:00": (2025, 3, 15),
            "03/15/2025": (2025, 3, 15)
        ]

        for (dateString, expected) in testCases {
            let context = ActionContext(card: mockCard, context: ["date": dateString])
            let date = context.date(for: "date")

            XCTAssertNotNil(date, "Failed to parse date: \(dateString)")

            if let date = date {
                let calendar = Calendar(identifier: .gregorian)
                let components = calendar.dateComponents([.year, .month, .day], from: date)
                XCTAssertEqual(components.year, expected.0, "Year mismatch for: \(dateString)")
                XCTAssertEqual(components.month, expected.1, "Month mismatch for: \(dateString)")
                XCTAssertEqual(components.day, expected.2, "Day mismatch for: \(dateString)")
            }
        }
    }

    func testDateAccessorInvalidFormat() {
        let context = ActionContext(card: mockCard, context: [
            "invalidDate": "not a date"
        ])

        XCTAssertNil(context.date(for: "invalidDate"))
    }

    // MARK: - Convenience Properties

    func testTrackingConvenienceProperties() {
        let context = ActionContext(card: mockCard, context: [
            "trackingNumber": "1Z999AA10123456784",
            "carrier": "UPS",
            "trackingUrl": "https://ups.com/track",
            "estimatedDelivery": "2025-03-20",
            "deliveryStatus": "In Transit"
        ])

        XCTAssertEqual(context.trackingNumber, "1Z999AA10123456784")
        XCTAssertEqual(context.carrier, "UPS")
        XCTAssertEqual(context.trackingUrl, "https://ups.com/track")
        XCTAssertNotNil(context.estimatedDelivery)
        XCTAssertEqual(context.deliveryStatus, "In Transit")
    }

    func testPaymentConvenienceProperties() {
        let context = ActionContext(card: mockCard, context: [
            "invoiceId": "INV-12345",
            "amount": "$123.45",
            "dueDate": "2025-03-31",
            "paymentLink": "https://example.com/pay"
        ])

        XCTAssertEqual(context.invoiceId, "INV-12345")
        XCTAssertEqual(context.amount, "$123.45")
        XCTAssertNotNil(context.dueDate)
        XCTAssertEqual(context.paymentLink, "https://example.com/pay")
    }

    func testCalendarConvenienceProperties() {
        let context = ActionContext(card: mockCard, context: [
            "eventTitle": "Team Meeting",
            "startDate": "2025-03-15T14:00:00Z",
            "endDate": "2025-03-15T15:00:00Z",
            "location": "Conference Room A",
            "meetingUrl": "https://zoom.us/j/123456789"
        ])

        XCTAssertEqual(context.eventTitle, "Team Meeting")
        XCTAssertNotNil(context.startDate)
        XCTAssertNotNil(context.endDate)
        XCTAssertEqual(context.location, "Conference Room A")
        XCTAssertEqual(context.meetingUrl, "https://zoom.us/j/123456789")
    }

    func testFlightConvenienceProperties() {
        let context = ActionContext(card: mockCard, context: [
            "flightNumber": "UA1234",
            "airline": "United Airlines",
            "checkInUrl": "https://united.com/checkin",
            "departureTime": "2025-03-20T08:00:00Z",
            "gate": "B12",
            "seat": "14A"
        ])

        XCTAssertEqual(context.flightNumber, "UA1234")
        XCTAssertEqual(context.airline, "United Airlines")
        XCTAssertEqual(context.checkInUrl, "https://united.com/checkin")
        XCTAssertNotNil(context.departureTime)
        XCTAssertEqual(context.gate, "B12")
        XCTAssertEqual(context.seat, "14A")
    }

    func testShoppingConvenienceProperties() {
        let context = ActionContext(card: mockCard, context: [
            "productName": "Wireless Headphones",
            "productUrl": "https://store.com/headphones",
            "price": 99.99,
            "salePrice": 79.99,
            "discount": 20
        ])

        XCTAssertEqual(context.productName, "Wireless Headphones")
        XCTAssertEqual(context.productUrl, "https://store.com/headphones")
        XCTAssertEqual(context.price, 99.99)
        XCTAssertEqual(context.salePrice, 79.99)
        XCTAssertEqual(context.discount, 20)
    }

    func testSubscriptionConvenienceProperties() {
        let context = ActionContext(card: mockCard, context: [
            "unsubscribeUrl": "https://example.com/unsubscribe",
            "subscriptionName": "Weekly Newsletter",
            "billingPeriod": "monthly"
        ])

        XCTAssertEqual(context.unsubscribeUrl, "https://example.com/unsubscribe")
        XCTAssertEqual(context.subscriptionName, "Weekly Newsletter")
        XCTAssertEqual(context.billingPeriod, "monthly")
    }

    func testGenericConvenienceProperties() {
        let context = ActionContext(card: mockCard, context: [
            "url": "https://example.com",
            "description": "Test description",
            "notes": "Important notes"
        ])

        XCTAssertEqual(context.url, "https://example.com")
        XCTAssertEqual(context.contextDescription, "Test description")
        XCTAssertEqual(context.notes, "Important notes")
    }

    // MARK: - Fallback Behavior

    func testConveniencePropertyFallbacks() {
        // Test that convenience properties fall back to alternate keys
        let context = ActionContext(card: mockCard, context: [
            "url": "https://example.com",  // Used by trackingUrl, productUrl, documentUrl
            "status": "Delivered",          // Used by deliveryStatus
            "amountDue": "$50.00",          // Used by amount
            "title": "Meeting",             // Used by eventTitle
            "confirmationNumber": "ABC123"  // Used by reservationId
        ])

        XCTAssertEqual(context.trackingUrl, "https://example.com")
        XCTAssertEqual(context.productUrl, "https://example.com")
        XCTAssertEqual(context.documentUrl, "https://example.com")
        XCTAssertEqual(context.deliveryStatus, "Delivered")
        XCTAssertEqual(context.amount, "$50.00")
        XCTAssertEqual(context.eventTitle, "Meeting")
        XCTAssertEqual(context.reservationId, "ABC123")
    }

    // MARK: - Validation

    func testValidationWithAllKeysPresent() {
        let context = ActionContext(card: mockCard, context: [
            "trackingNumber": "123",
            "carrier": "UPS",
            "url": "https://example.com"
        ])

        let result = context.validate(requiredKeys: ["trackingNumber", "carrier", "url"])
        XCTAssertTrue(result.isValid)
    }

    func testValidationWithMissingKeys() {
        let context = ActionContext(card: mockCard, context: [
            "trackingNumber": "123"
        ])

        let result = context.validate(requiredKeys: ["trackingNumber", "carrier", "url"])
        XCTAssertFalse(result.isValid)

        if case .invalid(let missingKeys) = result {
            XCTAssertEqual(missingKeys.count, 2)
            XCTAssertTrue(missingKeys.contains("carrier"))
            XCTAssertTrue(missingKeys.contains("url"))
        } else {
            XCTFail("Expected invalid result with missing keys")
        }
    }

    func testValidationWithEmptyRequiredKeys() {
        let context = ActionContext(card: mockCard, context: [:])
        let result = context.validate(requiredKeys: [])
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Raw Access

    func testRawContextAccess() {
        let rawData: [String: Any] = [
            "key1": "value1",
            "key2": 123,
            "key3": true
        ]
        let context = ActionContext(card: mockCard, context: rawData)

        XCTAssertEqual(context.raw.count, 3)
        XCTAssertEqual(context.keys.count, 3)
        XCTAssertTrue(context.has("key1"))
        XCTAssertTrue(context.has("key2"))
        XCTAssertTrue(context.has("key3"))
        XCTAssertFalse(context.has("nonexistent"))
    }

    func testEmptyContext() {
        let context = ActionContext(card: mockCard, context: nil)

        XCTAssertEqual(context.raw.count, 0)
        XCTAssertEqual(context.keys.count, 0)
        XCTAssertFalse(context.has("anyKey"))
        XCTAssertNil(context.trackingNumber)
        XCTAssertEqual(context.string(for: "anyKey"), "")
    }

    // MARK: - CustomStringConvertible

    func testDescriptionOutput() {
        let context = ActionContext(card: mockCard, context: [
            "key1": "value1",
            "key2": "value2"
        ])

        let description = context.description
        XCTAssertTrue(description.contains("ActionContext"))
        XCTAssertTrue(description.contains("test-card-123"))
        XCTAssertTrue(description.contains("key1"))
        XCTAssertTrue(description.contains("key2"))
    }
}
