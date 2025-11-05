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

        let payload: [String: Any] = [
            "productUrl": productUrl,
            "productName": productName,
            "userSessionId": UUID().uuidString
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            Logger.error("Failed to serialize shopping automation request", category: .action)
            completion(.failure(error))
            return
        }

        // Execute request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.error("Shopping automation network error: \(error.localizedDescription)", category: .action)
                completion(.failure(error))
                return
            }

            guard let data = data else {
                Logger.error("No data received from shopping automation service", category: .action)
                completion(.failure(ShoppingAutomationError.noData))
                return
            }

            // Parse response
            do {
                let result = try JSONDecoder().decode(ShoppingAutomationResponse.self, from: data)

                if result.success {
                    // Success! Return checkout URL
                    Logger.info("✅ Shopping automation succeeded: \(result.checkoutUrl ?? "unknown")", category: .action)

                    let automationResult = ShoppingAutomationResult(
                        success: true,
                        checkoutUrl: result.checkoutUrl ?? result.cartUrl ?? productUrl,
                        productUrl: productUrl,
                        productName: productName,
                        fallbackMode: false,
                        message: result.message,
                        steps: result.steps
                    )

                    completion(.success(automationResult))
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

                    completion(.success(fallbackResult))
                }

            } catch {
                Logger.error("Failed to parse shopping automation response: \(error.localizedDescription)", category: .action)

                // Check if it's a 503 (service unavailable) with fallback
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 503 {
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

                    completion(.success(fallbackResult))
                } else {
                    completion(.failure(error))
                }
            }
        }

        task.resume()
    }

    /**
     * Get platform info for a product URL (diagnostic)
     */
    func getPlatformInfo(
        productUrl: String,
        completion: @escaping (Result<PlatformInfo, Error>) -> Void
    ) {
        let endpoint = "\(serviceURL)/api/shopping/platform-info?url=\(productUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? productUrl)"

        guard let url = URL(string: endpoint) else {
            completion(.failure(ShoppingAutomationError.invalidURL))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(ShoppingAutomationError.noData))
                return
            }

            do {
                let platformInfo = try JSONDecoder().decode(PlatformInfo.self, from: data)
                completion(.success(platformInfo))
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
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
