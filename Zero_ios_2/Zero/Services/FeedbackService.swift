//
//  FeedbackService.swift
//  Zero
//
//  Created by Claude Code on 10/25/25.
//

import Foundation

/**
 * FeedbackService - Handles classification feedback and issue reports
 *
 * Provides methods to:
 * - Submit classification corrections (Mail ↔ Ads)
 * - Report issues to support team
 */
class FeedbackService {
    static let shared = FeedbackService()

    private init() {}

    /// Submit classification feedback (user corrects category)
    func submitClassificationFeedback(
        emailId: String,
        originalCategory: String,
        correctedCategory: String
    ) async throws {
        let baseURL = APIConfig.baseURL
        let url = URL(string: "\(baseURL)/api/feedback/classification")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        if let token = getUserAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "emailId": emailId,
            "originalCategory": originalCategory,
            "correctedCategory": correctedCategory,
            "userEmail": getUserEmail() ?? "anonymous"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        Logger.info("📊 Submitting classification feedback: \(originalCategory) → \(correctedCategory)", category: .network)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedbackError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            Logger.error("Classification feedback failed: \(httpResponse.statusCode)", category: .network)
            throw FeedbackError.serverError(httpResponse.statusCode)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            Logger.info("✅ Classification feedback submitted: \(json)", category: .network)
        }
    }

    /// Submit issue report
    func submitIssueReport(
        emailId: String?,
        emailFrom: String?,
        emailSubject: String?,
        issueDescription: String
    ) async throws {
        let baseURL = APIConfig.baseURL
        let url = URL(string: "\(baseURL)/api/feedback/issue")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        if let token = getUserAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "emailId": emailId ?? "",
            "emailFrom": emailFrom ?? "",
            "emailSubject": emailSubject ?? "",
            "issueDescription": issueDescription,
            "userEmail": getUserEmail() ?? "anonymous"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        Logger.info("🐛 Submitting issue report", category: .network)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedbackError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            Logger.error("Issue report failed: \(httpResponse.statusCode)", category: .network)
            throw FeedbackError.serverError(httpResponse.statusCode)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            Logger.info("✅ Issue report submitted: \(json)", category: .network)
        }
    }

    // MARK: - Helpers

    private func getUserEmail() -> String? {
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")
        if useMockData {
            return nil
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "EmailShortForm",
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let attributes = result as? [String: Any],
           let emailData = attributes[kSecAttrAccount as String] as? String {
            return emailData
        }

        return nil
    }

    private func getUserAuthToken() -> String? {
        // TODO: Implement auth token retrieval
        return nil
    }
}

// MARK: - Errors

enum FeedbackError: Error {
    case invalidResponse
    case serverError(Int)
    case networkError

    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .networkError:
            return "Network connection failed"
        }
    }
}
