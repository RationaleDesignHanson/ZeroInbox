//
//  SubscriptionService.swift
//  Zero
//
//  Created by Claude Code on 10/25/25.
//

import Foundation

/**
 * SubscriptionService - Handles subscription cancellation API calls
 *
 * Methods:
 * - detectSubscription: Detect service from email
 * - getSubscriptionInfo: Get cancellation info for a service
 * - startGuidedCancellation: Start AI-guided cancellation
 */
class SubscriptionService {
    static let shared = SubscriptionService()

    private init() {}

    /// Detect subscription service from email
    func detectSubscription(from card: EmailCard) async throws -> SubscriptionInfo {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        let baseURL = APIConfig.baseURL
        let url = URL(string: "\(baseURL)/api/subscription/detect")!

        struct EmailData: Codable {
            let from: String
            let subject: String
            let body: String
        }

        struct DetectRequest: Codable {
            let email: EmailData
        }

        struct DetectResponse: Codable {
            let detected: Bool
            let serviceName: String?
        }

        let requestBody = DetectRequest(
            email: EmailData(
                from: card.sender?.email ?? "",
                subject: card.title,
                body: card.summary
            )
        )

        Logger.info("📊 Detecting subscription service", category: .network)

        let response: DetectResponse = try await NetworkService.shared.post(
            url: url,
            body: requestBody
        )

        guard response.detected, let serviceName = response.serviceName else {
            throw SubscriptionError.serviceNotDetected
        }

        Logger.info("✅ Subscription detected: \(serviceName)", category: .network)

        // Get full subscription info
        return try await getSubscriptionInfo(for: serviceName)
    }

    /// Get subscription cancellation info for a specific service
    func getSubscriptionInfo(for serviceName: String) async throws -> SubscriptionInfo {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        let baseURL = APIConfig.baseURL
        let encodedName = serviceName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? serviceName
        let url = URL(string: "\(baseURL)/api/subscription/info?service=\(encodedName)")!

        struct InfoResponse: Codable {
            let serviceName: String
            let accountPageUrl: String
            let cancellationUrl: String?
            let cancellationSteps: [String]
            let requiresLogin: Bool
            let aiAssistanceAvailable: Bool
            let note: String?
        }

        Logger.info("📊 Fetching subscription info for: \(serviceName)", category: .network)

        let response: InfoResponse = try await NetworkService.shared.get(url: url)

        let info = SubscriptionInfo(
            serviceName: response.serviceName,
            accountPageUrl: response.accountPageUrl,
            cancellationUrl: response.cancellationUrl,
            cancellationSteps: response.cancellationSteps,
            requiresLogin: response.requiresLogin,
            aiAssistanceAvailable: response.aiAssistanceAvailable,
            note: response.note
        )

        Logger.info("✅ Subscription info retrieved: \(info.serviceName)", category: .network)

        return info
    }

    /// Start AI-guided cancellation (Steel.dev)
    func startGuidedCancellation(for serviceName: String) async throws -> GuidedCancellationResult {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        let baseURL = APIConfig.baseURL
        let url = URL(string: "\(baseURL)/api/subscription/cancel/guided")!

        struct GuidedCancellationRequest: Codable {
            let serviceName: String
            let userSessionId: String
        }

        struct StepData: Codable {
            let step: Int
            let action: String
            let description: String
            let success: Bool
        }

        struct GuidedCancellationResponse: Codable {
            let success: Bool
            let serviceName: String
            let steps: [StepData]
            let nextSteps: [String]
            let requiresLogin: Bool
            let note: String?
        }

        let requestBody = GuidedCancellationRequest(
            serviceName: serviceName,
            userSessionId: UUID().uuidString
        )

        Logger.info("🤖 Starting AI-guided cancellation for: \(serviceName)", category: .network)

        let response: GuidedCancellationResponse = try await NetworkService.shared.post(
            url: url,
            body: requestBody
        )

        guard response.success else {
            throw SubscriptionError.aiGuidanceFailed
        }

        // Convert response steps to CancellationStep
        let steps = response.steps.map { stepData in
            CancellationStep(
                stepNumber: stepData.step,
                action: stepData.action,
                description: stepData.description,
                success: stepData.success
            )
        }

        let result = GuidedCancellationResult(
            serviceName: response.serviceName,
            steps: steps,
            nextSteps: response.nextSteps,
            requiresLogin: response.requiresLogin,
            note: response.note
        )

        Logger.info("✅ AI guidance started: \(result.serviceName)", category: .network)

        return result
    }

    // MARK: - Helpers

    private func getUserAuthToken() -> String? {
        // Use centralized auth context (Week 6 Cleanup)
        return AuthContext.getAuthToken()
    }
}

// MARK: - Models

struct GuidedCancellationResult {
    let serviceName: String
    let steps: [CancellationStep]
    let nextSteps: [String]
    let requiresLogin: Bool
    let note: String?
}

struct CancellationStep {
    let stepNumber: Int
    let action: String
    let description: String
    let success: Bool
}

// MARK: - Errors

enum SubscriptionError: Error {
    case invalidResponse
    case serverError(Int)
    case networkError
    case serviceNotDetected
    case aiGuidanceFailed

    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .networkError:
            return "Network connection failed"
        case .serviceNotDetected:
            return "Could not detect subscription service"
        case .aiGuidanceFailed:
            return "AI guidance not available"
        }
    }
}
