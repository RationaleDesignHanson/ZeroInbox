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
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        let baseURL = APIConfig.baseURL
        let url = URL(string: "\(baseURL)/api/feedback/classification")!

        struct ClassificationFeedbackRequest: Codable {
            let emailId: String
            let originalCategory: String
            let correctedCategory: String
            let userEmail: String
        }

        let requestBody = ClassificationFeedbackRequest(
            emailId: emailId,
            originalCategory: originalCategory,
            correctedCategory: correctedCategory,
            userEmail: getUserEmail() ?? "anonymous"
        )

        Logger.info("📊 Submitting classification feedback: \(originalCategory) → \(correctedCategory)", category: .network)

        try await NetworkService.shared.post(
            url: url,
            body: requestBody
        )

        Logger.info("✅ Classification feedback submitted", category: .network)
    }

    /// Submit issue report
    func submitIssueReport(
        emailId: String?,
        emailFrom: String?,
        emailSubject: String?,
        issueDescription: String
    ) async throws {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        let baseURL = APIConfig.baseURL
        let url = URL(string: "\(baseURL)/api/feedback/issue")!

        struct IssueReportRequest: Codable {
            let emailId: String
            let emailFrom: String
            let emailSubject: String
            let issueDescription: String
            let userEmail: String
        }

        let requestBody = IssueReportRequest(
            emailId: emailId ?? "",
            emailFrom: emailFrom ?? "",
            emailSubject: emailSubject ?? "",
            issueDescription: issueDescription,
            userEmail: getUserEmail() ?? "anonymous"
        )

        Logger.info("🐛 Submitting issue report", category: .network)

        try await NetworkService.shared.post(
            url: url,
            body: requestBody
        )

        Logger.info("✅ Issue report submitted", category: .network)
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
        // Use centralized auth context (Week 6 Cleanup)
        return AuthContext.getAuthToken()
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
