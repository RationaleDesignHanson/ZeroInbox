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
        let baseURL = APIConfig.baseURL
        let url = URL(string: "\(baseURL)/api/subscription/detect")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        if let token = getUserAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let emailData: [String: Any] = [
            "from": card.sender?.email ?? "",
            "subject": card.title,
            "body": card.summary
        ]

        let body: [String: Any] = [
            "email": emailData
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        Logger.info("📊 Detecting subscription service", category: .network)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            Logger.error("Subscription detection failed: \(httpResponse.statusCode)", category: .network)
            throw SubscriptionError.serverError(httpResponse.statusCode)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let detected = json["detected"] as? Bool,
              detected,
              let serviceName = json["serviceName"] as? String else {
            throw SubscriptionError.serviceNotDetected
        }

        Logger.info("✅ Subscription detected: \(serviceName)", category: .network)

        // Get full subscription info
        return try await getSubscriptionInfo(for: serviceName)
    }

    /// Get subscription cancellation info for a specific service
    func getSubscriptionInfo(for serviceName: String) async throws -> SubscriptionInfo {
        let baseURL = APIConfig.baseURL
        let encodedName = serviceName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? serviceName
        let url = URL(string: "\(baseURL)/api/subscription/info?service=\(encodedName)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Add auth token if available
        if let token = getUserAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        Logger.info("📊 Fetching subscription info for: \(serviceName)", category: .network)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            Logger.error("Subscription info fetch failed: \(httpResponse.statusCode)", category: .network)
            throw SubscriptionError.serverError(httpResponse.statusCode)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SubscriptionError.invalidResponse
        }

        // Parse response
        let info = SubscriptionInfo(
            serviceName: json["serviceName"] as? String ?? serviceName,
            accountPageUrl: json["accountPageUrl"] as? String ?? "",
            cancellationUrl: json["cancellationUrl"] as? String,
            cancellationSteps: json["cancellationSteps"] as? [String] ?? [],
            requiresLogin: json["requiresLogin"] as? Bool ?? true,
            aiAssistanceAvailable: json["aiAssistanceAvailable"] as? Bool ?? false,
            note: json["note"] as? String
        )

        Logger.info("✅ Subscription info retrieved: \(info.serviceName)", category: .network)

        return info
    }

    /// Start AI-guided cancellation (Steel.dev)
    func startGuidedCancellation(for serviceName: String) async throws -> GuidedCancellationResult {
        let baseURL = APIConfig.baseURL
        let url = URL(string: "\(baseURL)/api/subscription/cancel/guided")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        if let token = getUserAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "serviceName": serviceName,
            "userSessionId": UUID().uuidString
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        Logger.info("🤖 Starting AI-guided cancellation for: \(serviceName)", category: .network)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            Logger.error("AI-guided cancellation failed: \(httpResponse.statusCode)", category: .network)
            throw SubscriptionError.serverError(httpResponse.statusCode)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool,
              success else {
            throw SubscriptionError.aiGuidanceFailed
        }

        // Parse guidance result
        let steps = (json["steps"] as? [[String: Any]])?.compactMap { stepData in
            CancellationStep(
                stepNumber: stepData["step"] as? Int ?? 0,
                action: stepData["action"] as? String ?? "",
                description: stepData["description"] as? String ?? "",
                success: stepData["success"] as? Bool ?? false
            )
        } ?? []

        let result = GuidedCancellationResult(
            serviceName: json["serviceName"] as? String ?? serviceName,
            steps: steps,
            nextSteps: json["nextSteps"] as? [String] ?? [],
            requiresLogin: json["requiresLogin"] as? Bool ?? true,
            note: json["note"] as? String
        )

        Logger.info("✅ AI guidance started: \(result.serviceName)", category: .network)

        return result
    }

    // MARK: - Helpers

    private func getUserAuthToken() -> String? {
        // TODO: Implement auth token retrieval
        return nil
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
