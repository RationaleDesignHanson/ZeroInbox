import Foundation

/// Protocol defining shopping cart service operations
/// Enables dependency injection and testing with mock implementations
protocol ShoppingCartServiceProtocol {
    
    // MARK: - Cart Operations
    
    /// Add item to user's cart
    func addToCart(
        userId: String,
        emailId: String?,
        productUrl: String?,
        productName: String,
        productImage: String?,
        price: Double,
        originalPrice: Double?,
        quantity: Int,
        merchant: String?,
        sku: String?,
        category: String?,
        expiresAt: String?
    ) async throws -> AddToCartResponse
    
    /// Get user's cart
    func getCart(userId: String) async throws -> GetCartResponse
    
    /// Get cart summary (item count, totals, etc.)
    func getCartSummary(userId: String) async throws -> CartSummary
    
    /// Update item quantity
    func updateQuantity(userId: String, itemId: String, quantity: Int) async throws
    
    /// Remove item from cart
    func removeItem(userId: String, itemId: String) async throws
    
    /// Clear entire cart
    func clearCart(userId: String) async throws
}

// MARK: - Default Implementation for Optional Parameters

extension ShoppingCartServiceProtocol {
    func addToCart(
        userId: String,
        emailId: String? = nil,
        productUrl: String? = nil,
        productName: String,
        productImage: String? = nil,
        price: Double,
        originalPrice: Double? = nil,
        quantity: Int = 1,
        merchant: String? = nil,
        sku: String? = nil,
        category: String? = nil,
        expiresAt: String? = nil
    ) async throws -> AddToCartResponse {
        return try await addToCart(
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
    }
}

