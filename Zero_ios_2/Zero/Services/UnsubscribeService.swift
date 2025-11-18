import Foundation

/// Service for handling email unsubscribe requests
class UnsubscribeService {

    // MARK: - Singleton

    static let shared = UnsubscribeService()

    private init() {}

    // MARK: - Public Methods

    /// Unsubscribe from a mailing list
    /// - Parameters:
    ///   - url: Unsubscribe URL from the email
    ///   - reason: Optional reason for unsubscribing
    ///   - customReason: Custom reason text if "Other" selected
    ///   - senderName: Name of the sender/company
    /// - Throws: UnsubscribeError if the unsubscribe fails
    func unsubscribe(
        url: String,
        reason: String?,
        customReason: String?,
        senderName: String?
    ) async throws {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService with async/await
        Logger.info("Attempting unsubscribe: \(url)", category: .action)

        // Validate URL
        guard let unsubscribeURL = URL(string: url) else {
            Logger.error("Invalid unsubscribe URL: \(url)", category: .action)
            throw UnsubscribeError.invalidURL
        }

        // Set custom headers for unsubscribe requests
        let headers = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
        ]

        do {
            // Most unsubscribe links are GET requests
            try await NetworkService.shared.request(
                url: unsubscribeURL,
                method: .get,
                headers: headers
            )

            Logger.info("Unsubscribe successful", category: .action)

            // Log analytics
            logUnsubscribeAnalytics(
                url: url,
                reason: reason,
                customReason: customReason,
                senderName: senderName
            )
        } catch let error as NetworkServiceError {
            // Map NetworkServiceError to UnsubscribeError
            if let statusCode = error.statusCode {
                // Accept 3xx redirects as success (common for unsubscribe flows)
                if (300...399).contains(statusCode) {
                    Logger.info("Unsubscribe redirect (3xx) - considering success", category: .action)
                    logUnsubscribeAnalytics(url: url, reason: reason, customReason: customReason, senderName: senderName)
                    return
                }
                Logger.error("Unsubscribe failed with status: \(statusCode)", category: .network)
                throw UnsubscribeError.serverError(statusCode)
            }
            Logger.error("Unsubscribe network error: \(error)", category: .network)
            throw UnsubscribeError.networkError(error)
        } catch {
            Logger.error("Unsubscribe error: \(error)", category: .network)
            throw UnsubscribeError.networkError(error)
        }
    }

    /// Legacy completion-handler version for backward compatibility
    /// - Parameters:
    ///   - url: Unsubscribe URL from the email
    ///   - reason: Optional reason for unsubscribing
    ///   - customReason: Custom reason text if "Other" selected
    ///   - senderName: Name of the sender/company
    ///   - completion: Result callback with success or error
    func unsubscribe(
        url: String,
        reason: String?,
        customReason: String?,
        senderName: String?,
        completion: @escaping (Result<Void, UnsubscribeError>) -> Void
    ) {
        Task {
            do {
                try await unsubscribe(url: url, reason: reason, customReason: customReason, senderName: senderName)
                completion(.success(()))
            } catch let error as UnsubscribeError {
                completion(.failure(error))
            } catch {
                completion(.failure(.networkError(error)))
            }
        }
    }

    // MARK: - Analytics

    private func logUnsubscribeAnalytics(
        url: String,
        reason: String?,
        customReason: String?,
        senderName: String?
    ) {
        var properties: [String: Any] = [
            "unsubscribe_url": url
        ]

        if let sender = senderName {
            properties["sender_name"] = sender
        }

        if let reason = reason {
            properties["reason"] = reason
        }

        if let custom = customReason, !custom.isEmpty {
            properties["custom_reason"] = custom
        }

        AnalyticsService.shared.log("unsubscribe_completed", properties: properties)

        Logger.info("Unsubscribe analytics logged for \(url)", category: .action)
    }
}

// MARK: - Errors

enum UnsubscribeError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid unsubscribe link. Please try opening the email directly."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server. Please try again."
        case .serverError(let code):
            return "Server error (code \(code)). The unsubscribe may still have worked - check your email."
        }
    }
}
