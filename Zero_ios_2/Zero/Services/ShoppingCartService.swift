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
        let url = URL(string: "\(baseURL)/cart/add")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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

        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(AddToCartResponse.self, from: data)
    }

    // MARK: - Get User's Cart
    func getCart(userId: String) async throws -> GetCartResponse {
        let url = URL(string: "\(baseURL)/cart/\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(GetCartResponse.self, from: data)
    }

    // MARK: - Update Item Quantity
    func updateQuantity(userId: String, itemId: String, quantity: Int) async throws {
        let url = URL(string: "\(baseURL)/cart/\(userId)/\(itemId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["quantity": quantity]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Remove Item from Cart
    func removeItem(userId: String, itemId: String) async throws {
        let url = URL(string: "\(baseURL)/cart/\(userId)/\(itemId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Clear Cart
    func clearCart(userId: String) async throws {
        let url = URL(string: "\(baseURL)/cart/\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Get Cart Summary
    func getCartSummary(userId: String) async throws -> CartSummary {
        let url = URL(string: "\(baseURL)/cart/\(userId)/summary")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        struct SummaryResponse: Codable {
            let success: Bool
            let summary: CartSummary
        }

        let decoded = try JSONDecoder().decode(SummaryResponse.self, from: data)
        return decoded.summary
    }
}
