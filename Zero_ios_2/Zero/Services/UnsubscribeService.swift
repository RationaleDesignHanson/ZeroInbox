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
    ///   - completion: Result callback with success or error
    func unsubscribe(
        url: String,
        reason: String?,
        customReason: String?,
        senderName: String?,
        completion: @escaping (Result<Void, UnsubscribeError>) -> Void
    ) {
        // Log unsubscribe attempt
        Logger.info("Attempting unsubscribe: \(url)", category: .action)

        // Validate URL
        guard let unsubscribeURL = URL(string: url) else {
            Logger.error("Invalid unsubscribe URL: \(url)", category: .action)
            completion(.failure(.invalidURL))
            return
        }

        // Create URL request
        var request = URLRequest(url: unsubscribeURL)
        request.httpMethod = "GET" // Most unsubscribe links are GET requests
        request.timeoutInterval = 30

        // Set user agent to identify as iOS app
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
            forHTTPHeaderField: "User-Agent"
        )

        // Execute request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for network errors
            if let error = error {
                Logger.error("Unsubscribe network error: \(error.localizedDescription)", category: .network)
                completion(.failure(.networkError(error)))
                return
            }

            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.error("Invalid HTTP response for unsubscribe", category: .network)
                completion(.failure(.invalidResponse))
                return
            }

            Logger.info("Unsubscribe response status: \(httpResponse.statusCode)", category: .network)

            // Accept 2xx and 3xx status codes as success
            if (200...399).contains(httpResponse.statusCode) {
                // Log analytics
                self.logUnsubscribeAnalytics(
                    url: url,
                    reason: reason,
                    customReason: customReason,
                    senderName: senderName
                )

                completion(.success(()))
            } else {
                Logger.error("Unsubscribe failed with status: \(httpResponse.statusCode)", category: .network)
                completion(.failure(.serverError(httpResponse.statusCode)))
            }
        }

        task.resume()
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
