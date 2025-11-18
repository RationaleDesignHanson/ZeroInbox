//
//  ShoppingAutomationService.swift
//  Zero
//
//  AI-powered shopping automation using Steel.dev
//  Automates adding products to cart and navigating to checkout
//

import Foundation

/**
 * Shopping Automation Service
 * Handles AI-powered cart automation for product links in emails
 */
class ShoppingAutomationService {
    static let shared = ShoppingAutomationService()

    // Steel Agent service URL (port 8087 locally, proxied through gateway in production)
    private let serviceURL: String = {
        #if DEBUG
        return "http://localhost:8087"
        #else
        return "https://steel-agent-service-hqdlmnyzrq-uc.a.run.app"
        #endif
    }()

    private init() {}

    /**
     * Automate adding product to cart and navigate to checkout
     *
     * - Parameters:
     *   - productUrl: URL of the product page
     *   - productName: Name of the product
     *   - completion: Callback with result (success, checkoutURL, error)
     */
    func automateAddToCart(
        productUrl: String,
        productName: String,
        completion: @escaping (Result<ShoppingAutomationResult, Error>) -> Void
    ) {
        Logger.info("Starting shopping automation for: \(productName)", category: .action)

        // Prepare request
        let endpoint = "\(serviceURL)/api/shopping/add-to-cart"

        guard let url = URL(string: endpoint) else {
            Logger.error("Invalid shopping automation URL: \(endpoint)", category: .action)
            completion(.failure(ShoppingAutomationError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // Allow up to 60 seconds for automation

        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        Task {
            do {
                let result = try await self.automateAddToCartAsync(
                    productUrl: productUrl,
                    productName: productName
                )
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Async version of automateAddToCart
    private func automateAddToCartAsync(
        productUrl: String,
        productName: String
    ) async throws -> ShoppingAutomationResult {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        let endpoint = "\(serviceURL)/api/shopping/add-to-cart"

        guard let url = URL(string: endpoint) else {
            Logger.error("Invalid shopping automation URL: \(endpoint)", category: .action)
            throw ShoppingAutomationError.invalidURL
        }

        struct AddToCartRequest: Codable {
            let productUrl: String
            let productName: String
            let userSessionId: String
        }

        let requestBody = AddToCartRequest(
            productUrl: productUrl,
            productName: productName,
            userSessionId: UUID().uuidString
        )

        do {
            let result: ShoppingAutomationResponse = try await NetworkService.shared.request(
                url: url,
                method: .post,
                body: requestBody
            )

            if result.success {
                // Success! Use sessionViewerUrl to show actual browser session with item in cart
                let finalUrl = result.sessionViewerUrl ?? result.checkoutUrl ?? result.cartUrl ?? productUrl
                Logger.info("✅ Shopping automation succeeded: \(finalUrl)", category: .action)

                let automationResult = ShoppingAutomationResult(
                    success: true,
                    checkoutUrl: finalUrl,
                    productUrl: productUrl,
                    productName: productName,
                    fallbackMode: false,
                    message: result.message,
                    steps: result.steps
                )

                // Sync with Zero's internal shopping cart
                Task {
                    do {
                        _ = try await ShoppingCartService.shared.addToCart(
                            userId: AuthContext.getUserId(),
                            emailId: nil,
                            productUrl: productUrl,
                            productName: productName,
                            productImage: nil,
                            price: 0.0, // TODO: Extract actual price from automation result
                            originalPrice: nil,
                            quantity: 1,
                            merchant: result.steps?.first?.platform,
                            sku: nil,
                            category: nil,
                            expiresAt: nil
                        )
                        Logger.info("✅ Product synced to Zero cart: \(productName)", category: .shopping)
                    } catch {
                        Logger.error("Failed to sync product to Zero cart: \(error.localizedDescription)", category: .shopping)
                        // Don't fail the automation if cart sync fails
                    }
                }

                return automationResult
            } else {
                // Automation failed, but we have fallback
                Logger.warning("Shopping automation failed, using fallback: \(result.error ?? "unknown")", category: .action)

                let fallbackResult = ShoppingAutomationResult(
                    success: false,
                    checkoutUrl: result.productUrl ?? productUrl,
                    productUrl: productUrl,
                    productName: productName,
                    fallbackMode: true,
                    message: result.message ?? "Opening product page for manual checkout",
                    steps: result.steps
                )

                return fallbackResult
            }
        } catch let error as NetworkServiceError {
            Logger.error("Shopping automation network error", category: .action)

            // Check if it's a 503 (service unavailable) with fallback
            if let statusCode = error.statusCode, statusCode == 503 {
                Logger.info("Steel API not configured, using fallback mode", category: .action)

                let fallbackResult = ShoppingAutomationResult(
                    success: false,
                    checkoutUrl: productUrl,
                    productUrl: productUrl,
                    productName: productName,
                    fallbackMode: true,
                    message: "AI automation unavailable. Opening product page.",
                    steps: nil
                )

                return fallbackResult
            }

            throw error
        } catch {
            Logger.error("Failed to parse shopping automation response: \(error.localizedDescription)", category: .action)
            throw error
        }
    }

    /**
     * Get platform info for a product URL (diagnostic)
     */
    func getPlatformInfo(
        productUrl: String,
        completion: @escaping (Result<PlatformInfo, Error>) -> Void
    ) {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        Task {
            do {
                let platformInfo = try await getPlatformInfoAsync(productUrl: productUrl)
                completion(.success(platformInfo))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Async version of getPlatformInfo
    private func getPlatformInfoAsync(productUrl: String) async throws -> PlatformInfo {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        let endpoint = "\(serviceURL)/api/shopping/platform-info?url=\(productUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? productUrl)"

        guard let url = URL(string: endpoint) else {
            Logger.error("Invalid platform info URL: \(endpoint)", category: .action)
            throw ShoppingAutomationError.invalidURL
        }

        do {
            let platformInfo: PlatformInfo = try await NetworkService.shared.get(url: url)
            return platformInfo
        } catch let error as NetworkServiceError {
            Logger.error("Failed to fetch platform info: \(error.localizedDescription)", category: .action)
            throw ShoppingAutomationError.invalidURL
        } catch {
            Logger.error("Platform info request failed: \(error.localizedDescription)", category: .action)
            throw error
        }
    }
}

// MARK: - Models

struct ShoppingAutomationResult {
    let success: Bool
    let checkoutUrl: String
    let productUrl: String
    let productName: String
    let fallbackMode: Bool
    let message: String?
    let steps: [AutomationStep]?
}

struct ShoppingAutomationResponse: Codable {
    let success: Bool
    let checkoutUrl: String?
    let cartUrl: String?
    let sessionViewerUrl: String?  // Steel viewer URL with browser session
    let productUrl: String?
    let productName: String?
    let message: String?
    let error: String?
    let fallbackMode: Bool?
    let steps: [AutomationStep]?
}

struct AutomationStep: Codable {
    let step: String
    let success: Bool
    let platform: String?
    let selector: String?
    let error: String?
}

struct PlatformInfo: Codable {
    let url: String
    let platform: String
    let platformId: String
    let addToCartSelectors: [String]
    let checkoutSelectors: [String]
}

enum ShoppingAutomationError: Error, LocalizedError {
    case invalidURL
    case noData
    case automationFailed(message: String)
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid shopping automation URL"
        case .noData:
            return "No data received from shopping automation service"
        case .automationFailed(let message):
            return "Automation failed: \(message)"
        case .serviceUnavailable:
            return "Shopping automation service temporarily unavailable"
        }
    }
}
