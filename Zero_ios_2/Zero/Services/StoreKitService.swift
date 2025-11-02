//
//  StoreKitService.swift
//  Zero
//
//  Created by Claude Code on 10/26/25.
//

import Foundation
import StoreKit

/**
 * StoreKitService - Production-ready in-app purchase management
 *
 * Features:
 * - StoreKit 2 async/await API
 * - Automatic transaction verification
 * - Subscription status monitoring
 * - Receipt validation
 * - Restore purchases
 * - Family Sharing support
 * - Transaction listener for renewals
 *
 * Product IDs:
 * - Monthly: "com.zero.premium.monthly"
 * - Yearly: "com.zero.premium.yearly"
 *
 * Usage:
 * ```swift
 * // Fetch products
 * await StoreKitService.shared.loadProducts()
 *
 * // Purchase subscription
 * let success = await StoreKitService.shared.purchase(.monthly)
 *
 * // Restore purchases
 * await StoreKitService.shared.restorePurchases()
 *
 * // Check subscription status
 * let isSubscribed = await StoreKitService.shared.isSubscribed
 * ```
 */
@MainActor
class StoreKitService: ObservableObject {

    // MARK: - Singleton
    static let shared = StoreKitService()

    // MARK: - Published Properties
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false

    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Product IDs
    enum ProductID: String, CaseIterable {
        case monthly = "com.zero.premium.monthly"
        case yearly = "com.zero.premium.yearly"

        var displayName: String {
            switch self {
            case .monthly: return "Monthly Premium"
            case .yearly: return "Yearly Premium"
            }
        }
    }

    // MARK: - Initialization
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        Logger.info("StoreKitService initialized", category: .analytics)
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public API

    /// Load products from App Store
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIDs)

            products = storeProducts.sorted { product1, product2 in
                // Sort by price (yearly first as it's cheaper per month)
                if let price1 = Double(product1.displayPrice.filter({ $0.isNumber || $0 == "." })),
                   let price2 = Double(product2.displayPrice.filter({ $0.isNumber || $0 == "." })) {
                    return price1 > price2
                }
                return false
            }

            Logger.info("Loaded \(products.count) products from App Store", category: .analytics)

            // Check current entitlements
            await updatePurchasedProducts()

        } catch {
            Logger.error("Failed to load products: \(error.localizedDescription)", category: .analytics)
        }
    }

    /// Purchase a subscription
    func purchase(_ productID: ProductID) async -> PurchaseResult {
        guard let product = products.first(where: { $0.id == productID.rawValue }) else {
            Logger.error("Product not found: \(productID.rawValue)", category: .analytics)
            return .failure(.productNotFound)
        }

        Logger.info("Initiating purchase: \(productID.rawValue)", category: .analytics)

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify transaction
                let transaction = try checkVerified(verification)

                // Grant access
                await transaction.finish()
                await updatePurchasedProducts()

                Logger.info("✅ Purchase successful: \(productID.rawValue)", category: .analytics)
                return .success(transaction)

            case .userCancelled:
                Logger.info("User cancelled purchase", category: .analytics)
                return .failure(.userCancelled)

            case .pending:
                Logger.info("Purchase pending approval", category: .analytics)
                return .failure(.pending)

            @unknown default:
                Logger.warning("Unknown purchase result", category: .analytics)
                return .failure(.unknown)
            }

        } catch {
            Logger.error("Purchase failed: \(error.localizedDescription)", category: .analytics)
            return .failure(.unknown)
        }
    }

    /// Restore previous purchases
    func restorePurchases() async -> RestoreResult {
        Logger.info("Restoring purchases", category: .analytics)

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()

            if purchasedProductIDs.isEmpty {
                Logger.info("No purchases to restore", category: .analytics)
                return .noPurchases
            } else {
                Logger.info("✅ Restored \(purchasedProductIDs.count) purchases", category: .analytics)
                return .success(purchasedProductIDs.count)
            }

        } catch {
            Logger.error("Restore failed: \(error.localizedDescription)", category: .analytics)
            return .failure
        }
    }

    /// Check if user has an active subscription
    var isSubscribed: Bool {
        !purchasedProductIDs.isEmpty
    }

    /// Get active subscription product ID
    var activeSubscription: ProductID? {
        if purchasedProductIDs.contains(ProductID.yearly.rawValue) {
            return .yearly
        } else if purchasedProductIDs.contains(ProductID.monthly.rawValue) {
            return .monthly
        }
        return nil
    }

    /// Get product by ID
    func getProduct(_ productID: ProductID) -> Product? {
        products.first(where: { $0.id == productID.rawValue })
    }

    // MARK: - Private Methods

    /// Listen for transaction updates (renewals, etc.)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()

                    await MainActor.run {
                        Logger.info("Transaction updated: \(transaction.productID)", category: .analytics)
                    }

                } catch {
                    await MainActor.run {
                        Logger.error("Transaction verification failed: \(error.localizedDescription)", category: .analytics)
                    }
                }
            }
        }
    }

    /// Update purchased products from current entitlements
    private func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if subscription is active
                if let expirationDate = transaction.expirationDate {
                    if expirationDate > Date() {
                        purchasedIDs.insert(transaction.productID)
                    }
                } else {
                    // Non-consumable or active subscription without expiration
                    purchasedIDs.insert(transaction.productID)
                }

            } catch {
                Logger.error("Failed to verify entitlement: \(error.localizedDescription)", category: .analytics)
            }
        }

        purchasedProductIDs = purchasedIDs

        // Update UserPermissions
        if !purchasedIDs.isEmpty {
            UserPermissions.shared.setPremium(true)

            // Set subscription plan
            if let subscription = activeSubscription {
                UserPermissions.shared.setCustomData(key: "subscription_type", value: subscription.rawValue)
            }
        } else {
            UserPermissions.shared.setPremium(false)
        }

        Logger.info("Updated purchased products: \(purchasedIDs)", category: .analytics)
    }

    /// Verify transaction signature
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            // Verification failed
            throw StoreKitError.verificationFailed

        case .verified(let safe):
            // Verification succeeded
            return safe
        }
    }
}

// MARK: - Result Types

enum PurchaseResult {
    case success(Transaction)
    case failure(PurchaseError)
}

enum PurchaseError: Error, LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case verificationFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found in App Store"
        case .userCancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending approval"
        case .verificationFailed:
            return "Transaction verification failed"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

enum RestoreResult {
    case success(Int) // Number of restored purchases
    case noPurchases
    case failure
}

enum StoreKitError: Error {
    case verificationFailed
}

// MARK: - StoreKit Testing Helper

#if DEBUG
extension StoreKitService {
    /// Reset subscription status (for testing only)
    func debugResetSubscription() {
        purchasedProductIDs = []
        UserPermissions.shared.resetToFree()
        Logger.info("🧪 DEBUG: Reset subscription status", category: .analytics)
    }

    /// Mock purchase (for testing only)
    func debugMockPurchase(_ productID: ProductID) {
        purchasedProductIDs.insert(productID.rawValue)
        UserPermissions.shared.setPremium(true)
        Logger.info("🧪 DEBUG: Mocked purchase: \(productID.rawValue)", category: .analytics)
    }
}
#endif

// MARK: - Extensions

extension Product {
    /// Get localized price string
    var localizedPrice: String {
        displayPrice
    }

    /// Get subscription period (monthly/yearly)
    var subscriptionPeriod: String? {
        subscription?.subscriptionPeriod.localizedPeriod
    }
}

extension Product.SubscriptionPeriod {
    /// Get human-readable subscription period
    var localizedPeriod: String {
        switch unit {
        case .day:
            return value == 1 ? "day" : "\(value) days"
        case .week:
            return value == 1 ? "week" : "\(value) weeks"
        case .month:
            return value == 1 ? "month" : "\(value) months"
        case .year:
            return value == 1 ? "year" : "\(value) years"
        @unknown default:
            return "period"
        }
    }
}
