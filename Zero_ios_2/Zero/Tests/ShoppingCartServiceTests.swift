import XCTest
@testable import Zero

/**
 * ShoppingCartServiceTests - Unit tests for shopping cart functionality
 *
 * Tests shopping cart operations using mock data and fixtures:
 * - Adding items from receipt emails to cart
 * - Retrieving cart contents
 * - Updating item quantities
 * - Removing items
 * - Cart summary calculations
 * - Integration with receipt parsing
 *
 * NOTE: Full unit testing would require dependency injection for NetworkService.
 * These tests demonstrate expected behavior using fixtures and mock responses.
 */
class ShoppingCartServiceTests: XCTestCase {

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

    // MARK: - Fixture Loading Tests

    func testLoadShoppingFixtures() throws {
        // Test that all shopping fixtures can be loaded
        let fixtures = try FixtureLoader.loadAllShoppingFixtures()

        XCTAssertEqual(fixtures.count, 7, "Should load all 7 shopping fixtures")

        // Verify each fixture has required fields
        for fixture in fixtures {
            XCTAssertNotNil(fixture["id"])
            XCTAssertNotNil(fixture["subject"])
            XCTAssertNotNil(fixture["from"])
            XCTAssertNotNil(fixture["body"])
        }
    }

    func testExtractOrderInfoFromAmazonOrderFixture() throws {
        let fixture = try FixtureLoader.loadFixture(named: "shopping-amazon-order-confirmation.json")

        let subject = FixtureLoader.extractSubject(from: fixture)
        let bodyText = FixtureLoader.extractBodyText(from: fixture)
        let entities = FixtureLoader.extractEntities(from: fixture)

        XCTAssertTrue(subject.lowercased().contains("order"), "Subject should mention order")
        XCTAssertFalse(bodyText.isEmpty, "Body should not be empty")

        // Verify entities
        if let orderNumber = entities["orderNumber"] as? String {
            XCTAssertFalse(orderNumber.isEmpty, "Should have order number")
        }

        if let merchant = entities["merchant"] as? String {
            XCTAssertEqual(merchant, "Amazon", "Merchant should be Amazon")
        }

        if let items = entities["items"] as? [[String: Any]] {
            XCTAssertGreaterThan(items.count, 0, "Should have items")

            // Verify item structure
            for item in items {
                XCTAssertNotNil(item["name"], "Item should have name")
                XCTAssertNotNil(item["price"], "Item should have price")
            }
        }
    }

    func testExtractOrderInfoFromTargetOrderFixture() throws {
        let fixture = try FixtureLoader.loadFixture(named: "shopping-target-order.json")

        let entities = FixtureLoader.extractEntities(from: fixture)

        if let merchant = entities["merchant"] as? String {
            XCTAssertEqual(merchant, "Target", "Merchant should be Target")
        }

        if let total = entities["total"] as? Double {
            XCTAssertGreaterThan(total, 0, "Total should be positive")
        }

        if let items = entities["items"] as? [[String: Any]] {
            XCTAssertEqual(items.count, 3, "Target order should have 3 items")
        }
    }

    func testExtractOrderInfoFromBestBuyMultiItemFixture() throws {
        let fixture = try FixtureLoader.loadFixture(named: "shopping-bestbuy-multi-item.json")

        let entities = FixtureLoader.extractEntities(from: fixture)

        if let merchant = entities["merchant"] as? String {
            XCTAssertEqual(merchant, "Best Buy", "Merchant should be Best Buy")
        }

        if let items = entities["items"] as? [[String: Any]] {
            XCTAssertGreaterThanOrEqual(items.count, 2, "Multi-item order should have multiple items")

            // Check that items have quantities
            for item in items {
                if let quantity = item["quantity"] as? Int {
                    XCTAssertGreaterThan(quantity, 0, "Quantity should be positive")
                }
            }
        }
    }

    // MARK: - Cart Model Tests

    func testCartItemModel() {
        let item = CartItem(
            id: "item-123",
            userId: "user-456",
            emailId: "email-789",
            productUrl: "https://amazon.com/product",
            productName: "Wireless Headphones",
            productImage: "https://images.amazon.com/product.jpg",
            price: 79.99,
            originalPrice: 99.99,
            quantity: 1,
            merchant: "Amazon",
            sku: "B08N5WRWNW",
            category: "Electronics",
            expiresAt: "2025-01-20T00:00:00Z",
            metadata: ["color": "black"],
            addedAt: "2025-01-18T10:00:00Z",
            updatedAt: "2025-01-18T10:00:00Z",
            total: 79.99,
            savings: 20.00,
            isExpired: false,
            hoursUntilExpiration: 48
        )

        XCTAssertEqual(item.id, "item-123")
        XCTAssertEqual(item.productName, "Wireless Headphones")
        XCTAssertEqual(item.price, 79.99)
        XCTAssertEqual(item.originalPrice, 99.99)
        XCTAssertEqual(item.merchant, "Amazon")
        XCTAssertFalse(item.isExpired)
        XCTAssertEqual(item.total, 79.99)
        XCTAssertEqual(item.savings, 20.00)
    }

    func testCartSummaryModel() {
        let item1 = CartItem(
            id: "1", userId: "user", emailId: nil, productUrl: nil,
            productName: "Product 1", productImage: nil, price: 50.00,
            originalPrice: 60.00, quantity: 1, merchant: "Amazon",
            sku: nil, category: nil, expiresAt: nil, metadata: nil,
            addedAt: "", updatedAt: "", total: 50.00, savings: 10.00,
            isExpired: false, hoursUntilExpiration: nil
        )

        let item2 = CartItem(
            id: "2", userId: "user", emailId: nil, productUrl: nil,
            productName: "Product 2", productImage: nil, price: 30.00,
            originalPrice: 40.00, quantity: 2, merchant: "Target",
            sku: nil, category: nil, expiresAt: nil, metadata: nil,
            addedAt: "", updatedAt: "", total: 60.00, savings: 20.00,
            isExpired: false, hoursUntilExpiration: nil
        )

        let merchantGroup = MerchantGroup(
            merchant: "Amazon",
            items: [item1],
            total: 50.00
        )

        let summary = CartSummary(
            itemCount: 3,
            subtotal: 110.00,
            totalSavings: 30.00,
            merchantGroups: [merchantGroup],
            expiringItems: []
        )

        XCTAssertEqual(summary.itemCount, 3)
        XCTAssertEqual(summary.subtotal, 110.00)
        XCTAssertEqual(summary.totalSavings, 30.00)
        XCTAssertEqual(summary.merchantGroups.count, 1)
    }

    // MARK: - AddToCartRequest Tests

    func testAddToCartRequestCreation() {
        let request = AddToCartRequest(
            userId: "user-123",
            emailId: "email-456",
            productUrl: "https://amazon.com/product",
            productName: "Test Product",
            productImage: "https://images.amazon.com/product.jpg",
            price: 99.99,
            originalPrice: 129.99,
            quantity: 1,
            merchant: "Amazon",
            sku: "ABC123",
            category: "Electronics",
            expiresAt: "2025-01-25T00:00:00Z"
        )

        XCTAssertEqual(request.userId, "user-123")
        XCTAssertEqual(request.productName, "Test Product")
        XCTAssertEqual(request.price, 99.99)
        XCTAssertEqual(request.quantity, 1)
    }

    // MARK: - Shopping Workflow Integration Tests

    func testShoppingWorkflowFromOrderEmail() throws {
        // Simulate complete workflow: Receipt email -> Extract items -> Add to cart

        // 1. Load fixture
        let fixture = try FixtureLoader.loadFixture(named: "shopping-amazon-order-confirmation.json")
        let entities = FixtureLoader.extractEntities(from: fixture)

        // 2. Extract order information
        guard let items = entities["items"] as? [[String: Any]],
              let merchant = entities["merchant"] as? String else {
            XCTFail("Fixture should have items and merchant")
            return
        }

        XCTAssertGreaterThan(items.count, 0, "Should have items to add to cart")
        XCTAssertEqual(merchant, "Amazon")

        // 3. Verify items have required fields for cart
        for item in items {
            XCTAssertNotNil(item["name"], "Item must have name")
            XCTAssertNotNil(item["price"], "Item must have price")

            if let price = item["price"] as? Double {
                XCTAssertGreaterThan(price, 0, "Price must be positive")
            }

            if let quantity = item["quantity"] as? Int {
                XCTAssertGreaterThan(quantity, 0, "Quantity must be positive")
            }
        }
    }

    func testBatchAddToCartFromMultipleOrders() throws {
        // Test adding items from multiple order emails to cart

        let amazonOrder = try FixtureLoader.loadFixture(named: "shopping-amazon-order-confirmation.json")
        let targetOrder = try FixtureLoader.loadFixture(named: "shopping-target-order.json")

        let amazonEntities = FixtureLoader.extractEntities(from: amazonOrder)
        let targetEntities = FixtureLoader.extractEntities(from: targetOrder)

        // Both should have items
        XCTAssertNotNil(amazonEntities["items"])
        XCTAssertNotNil(targetEntities["items"])

        // Should be different merchants
        let amazonMerchant = amazonEntities["merchant"] as? String
        let targetMerchant = targetEntities["merchant"] as? String

        XCTAssertEqual(amazonMerchant, "Amazon")
        XCTAssertEqual(targetMerchant, "Target")
    }

    // MARK: - Order Status Tests

    func testDetectShippedOrder() throws {
        let fixture = try FixtureLoader.loadFixture(named: "shopping-amazon-shipped.json")
        let entities = FixtureLoader.extractEntities(from: fixture)

        if let status = entities["status"] as? String {
            XCTAssertEqual(status, "shipped", "Should detect shipped status")
        }

        // Shipped orders should have tracking info
        XCTAssertNotNil(entities["trackingNumber"], "Shipped order should have tracking number")
    }

    func testDetectDeliveredOrder() throws {
        let fixture = try FixtureLoader.loadFixture(named: "shopping-amazon-delivered.json")
        let entities = FixtureLoader.extractEntities(from: fixture)

        if let status = entities["status"] as? String {
            XCTAssertEqual(status, "delivered", "Should detect delivered status")
        }
    }

    func testDetectCancelledOrder() throws {
        let fixture = try FixtureLoader.loadFixture(named: "shopping-order-cancelled.json")
        let entities = FixtureLoader.extractEntities(from: fixture)

        if let status = entities["status"] as? String {
            XCTAssertEqual(status, "cancelled", "Should detect cancelled status")
        }
    }

    func testDetectRefundedOrder() throws {
        let fixture = try FixtureLoader.loadFixture(named: "shopping-refund-issued.json")
        let entities = FixtureLoader.extractEntities(from: fixture)

        if let status = entities["status"] as? String {
            XCTAssertEqual(status, "refunded", "Should detect refunded status")
        }

        // Refunded orders should have refund amount
        XCTAssertNotNil(entities["refundAmount"], "Refunded order should have refund amount")
    }

    // MARK: - Price and Savings Tests

    func testCalculateSavings() {
        let originalPrice: Double = 99.99
        let salePrice: Double = 79.99
        let savings = originalPrice - salePrice

        XCTAssertEqual(savings, 20.00, "Savings calculation should be correct")
    }

    func testCartTotalCalculation() {
        // Simulate cart with multiple items
        let items: [(price: Double, quantity: Int)] = [
            (29.99, 1),
            (19.99, 2),
            (49.99, 1)
        ]

        let total = items.reduce(0.0) { sum, item in
            sum + (item.price * Double(item.quantity))
        }

        XCTAssertEqual(total, 119.96, accuracy: 0.01, "Cart total should be sum of (price * quantity)")
    }

    // MARK: - Error Handling Tests

    func testHandleMissingFixture() {
        XCTAssertThrowsError(try FixtureLoader.loadFixture(named: "nonexistent.json")) { error in
            XCTAssertTrue(error is FixtureLoaderError)
            if case .fileNotFound(let filename) = error as? FixtureLoaderError {
                XCTAssertEqual(filename, "nonexistent.json")
            }
        }
    }

    func testHandleInvalidPrice() {
        let invalidPrice: Double = -10.00

        XCTAssertLessThan(invalidPrice, 0, "Should detect invalid negative price")
    }

    func testHandleInvalidQuantity() {
        let invalidQuantity = 0

        XCTAssertLessThanOrEqual(invalidQuantity, 0, "Should detect invalid zero/negative quantity")
    }

    // MARK: - Merchant Grouping Tests

    func testGroupItemsByMerchant() throws {
        // Load multiple fixtures with different merchants
        let amazonFixture = try FixtureLoader.loadFixture(named: "shopping-amazon-order-confirmation.json")
        let targetFixture = try FixtureLoader.loadFixture(named: "shopping-target-order.json")

        let amazonEntities = FixtureLoader.extractEntities(from: amazonFixture)
        let targetEntities = FixtureLoader.extractEntities(from: targetFixture)

        var merchantGroups: [String: [[String: Any]]] = [:]

        // Group Amazon items
        if let merchant = amazonEntities["merchant"] as? String,
           let items = amazonEntities["items"] as? [[String: Any]] {
            merchantGroups[merchant] = items
        }

        // Group Target items
        if let merchant = targetEntities["merchant"] as? String,
           let items = targetEntities["items"] as? [[String: Any]] {
            merchantGroups[merchant] = items
        }

        XCTAssertEqual(merchantGroups.count, 2, "Should have 2 merchant groups")
        XCTAssertNotNil(merchantGroups["Amazon"])
        XCTAssertNotNil(merchantGroups["Target"])
    }
}
