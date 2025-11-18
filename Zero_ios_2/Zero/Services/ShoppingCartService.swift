import Foundation

// MARK: - Shopping Cart Models
struct CartItem: Codable, Identifiable {
    let id: String
    let userId: String
    let emailId: String?
    let productUrl: String?
    let productName: String
    let productImage: String?
    let price: Double
    let originalPrice: Double?
    let quantity: Int
    let merchant: String?
    let sku: String?
    let category: String?
    let expiresAt: String?
    let metadata: [String: String]?
    let addedAt: String
    let updatedAt: String
    let total: Double
    let savings: Double
    let isExpired: Bool
    let hoursUntilExpiration: Int?
}

struct CartSummary: Codable {
    let itemCount: Int
    let subtotal: Double
    let totalSavings: Double
    let merchantGroups: [MerchantGroup]
    let expiringItems: [ExpiringItem]
}

struct MerchantGroup: Codable {
    let merchant: String
    let items: [CartItem]
    let total: Double
}

struct ExpiringItem: Codable {
    let id: String
    let productName: String
    let hoursUntilExpiration: Int
}

struct AddToCartRequest: Codable {
    let userId: String
    let emailId: String?
    let productUrl: String?
    let productName: String
    let productImage: String?
    let price: Double
    let originalPrice: Double?
    let quantity: Int
    let merchant: String?
    let sku: String?
    let category: String?
    let expiresAt: String?
}

struct AddToCartResponse: Codable {
    let success: Bool
    let item: CartItem
    let summary: CartSummary
}

struct GetCartResponse: Codable {
    let success: Bool
    let cart: [CartItem]
    let summary: CartSummary
}

// MARK: - Shopping Cart Service
class ShoppingCartService: ShoppingCartServiceProtocol {
    static let shared = ShoppingCartService()

    private let baseURL = "http://localhost:8084"  // Shopping agent service

    private init() {
        Logger.info("Shopping cart service initialized", category: .shopping)
    }

    // MARK: - Add Item to Cart
    func addToCart(
        userId: String,
        emailId: String?,
        productUrl: String?,
        productName: String,
        productImage: String?,
        price: Double,
        originalPrice: Double?,
        quantity: Int = 1,
        merchant: String?,
        sku: String? = nil,
        category: String? = nil,
        expiresAt: String? = nil
    ) async throws -> AddToCartResponse {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        let requestBody = AddToCartRequest(
            userId: userId,
            emailId: emailId,
            productUrl: productUrl,
            productName: productName,
            productImage: productImage,
            price: price,
            originalPrice: originalPrice,
            quantity: quantity,
            merchant: merchant,
            sku: sku,
            category: category,
            expiresAt: expiresAt
        )

        return try await NetworkService.shared.post(
            url: URL(string: "\(baseURL)/cart/add")!,
            body: requestBody
        )
    }

    // MARK: - Get User's Cart
    func getCart(userId: String) async throws -> GetCartResponse {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        return try await NetworkService.shared.get(url: URL(string: "\(baseURL)/cart/\(userId)")!)
    }

    // MARK: - Update Item Quantity
    func updateQuantity(userId: String, itemId: String, quantity: Int) async throws {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        struct QuantityUpdate: Codable {
            let quantity: Int
        }
        try await NetworkService.shared.request(
            url: URL(string: "\(baseURL)/cart/\(userId)/\(itemId)")!,
            method: NetworkService.HTTPMethod.patch,
            body: QuantityUpdate(quantity: quantity)
        )
    }

    // MARK: - Remove Item from Cart
    func removeItem(userId: String, itemId: String) async throws {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        try await NetworkService.shared.delete(url: URL(string: "\(baseURL)/cart/\(userId)/\(itemId)")!)
    }

    // MARK: - Clear Cart
    func clearCart(userId: String) async throws {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        try await NetworkService.shared.delete(url: URL(string: "\(baseURL)/cart/\(userId)")!)
    }

    // MARK: - Get Cart Summary
    func getCartSummary(userId: String) async throws -> CartSummary {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        struct SummaryResponse: Codable {
            let success: Bool
            let summary: CartSummary
        }

        let response: SummaryResponse = try await NetworkService.shared.get(
            url: URL(string: "\(baseURL)/cart/\(userId)/summary")!
        )
        return response.summary
    }
}
