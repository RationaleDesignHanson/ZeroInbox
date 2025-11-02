import Foundation

/// Service for AI-powered email summarization
class SummarizationService {

    // MARK: - Configuration

    static let shared = SummarizationService()

    private let baseURL: String
    private var authToken: String?

    init() {
        self.baseURL = AppEnvironment.current.apiBaseURL
        // Try to load token from keychain
        self.authToken = loadTokenFromKeychain()
    }

    // MARK: - Email Summarization (Generic)

    /// Summarize any email with AI (not just newsletters)
    /// Returns a concise AI-generated summary
    func summarizeEmail(
        card: EmailCard,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        Task {
            do {
                let summary = try await summarizeEmailAsync(card: card)
                completion(.success(summary))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Async version of summarizeEmail
    private func summarizeEmailAsync(card: EmailCard) async throws -> String {
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw SummarizationError.notAuthenticated
        }

        Logger.info("Requesting AI summary for email: \(card.id)", category: .email)

        // Build request to generic summarize endpoint (gateway route: /api/emails/summarize)
        var request = URLRequest(url: URL(string: "\(baseURL)/emails/summarize")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // Request body with email content
        let body: [String: Any] = [
            "emailId": card.id,
            "subject": card.title,
            "from": card.sender?.name ?? card.company?.name ?? "Unknown",
            "body": card.body ?? card.summary,
            "snippet": card.summary.prefix(500),
            "type": card.type.rawValue
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.error("Invalid HTTP response for email summary", category: .email)
            throw SummarizationError.requestFailed
        }

        Logger.info("Email summary response status: \(httpResponse.statusCode)", category: .email)

        guard httpResponse.statusCode == 200 else {
            Logger.error("Email summarization failed with status \(httpResponse.statusCode)", category: .email)
            if let responseStr = String(data: data, encoding: .utf8) {
                Logger.error("Response body: \(responseStr)", category: .email)
            }
            throw SummarizationError.requestFailed
        }

        // Parse response
        struct GenericSummaryResponse: Codable {
            let summary: String
        }

        let summaryResponse = try JSONDecoder().decode(GenericSummaryResponse.self, from: data)
        Logger.info("AI summary generated successfully for \(card.id)", category: .email)

        return summaryResponse.summary
    }

    // MARK: - Newsletter Summarization

    /// Summarize a newsletter email with AI
    /// Returns a summary with key highlights and extracted links
    func summarizeNewsletter(
        card: EmailCard,
        completion: @escaping (Result<NewsletterSummary, Error>) -> Void
    ) {
        Task {
            do {
                let summary = try await summarizeNewsletterAsync(card: card)
                completion(.success(summary))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Async version of summarizeNewsletter
    private func summarizeNewsletterAsync(card: EmailCard) async throws -> NewsletterSummary {
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw SummarizationError.notAuthenticated
        }

        Logger.info("Requesting newsletter summary for: \(card.id)", category: .email)

        // Build request (gateway route: /api/emails/summarize/newsletter)
        var request = URLRequest(url: URL(string: "\(baseURL)/emails/summarize/newsletter")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30  // Longer timeout for AI processing

        // Request body with email content
        let body: [String: Any] = [
            "emailId": card.id,
            "subject": card.title,
            "from": card.company?.name ?? "Unknown",
            "body": card.summary,  // Full email body
            "snippet": card.summary.prefix(500)
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.error("Invalid HTTP response for newsletter summary", category: .email)
            throw SummarizationError.requestFailed
        }

        Logger.info("Newsletter summary response status: \(httpResponse.statusCode)", category: .email)

        guard httpResponse.statusCode == 200 else {
            Logger.error("Newsletter summarization failed with status \(httpResponse.statusCode)", category: .email)
            if let responseStr = String(data: data, encoding: .utf8) {
                Logger.error("Response body: \(responseStr)", category: .email)
            }
            throw SummarizationError.requestFailed
        }

        // Parse response
        struct SummaryResponse: Codable {
            let summary: String
            let keyLinks: [LinkData]
            let keyTopics: [String]?
        }

        struct LinkData: Codable {
            let title: String
            let url: String
            let description: String?
        }

        let summaryResponse = try JSONDecoder().decode(SummaryResponse.self, from: data)

        // Convert to NewsletterSummary
        let links = summaryResponse.keyLinks.map { linkData in
            EmailCard.NewsletterLink(
                title: linkData.title,
                url: linkData.url,
                description: linkData.description
            )
        }

        Logger.info("Newsletter summary generated successfully for \(card.id) with \(links.count) links", category: .email)

        return NewsletterSummary(
            summary: summaryResponse.summary,
            links: links,
            keyTopics: summaryResponse.keyTopics ?? []
        )
    }

    // MARK: - Keychain Management

    private func loadTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "EmailShortForm",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }
}

// MARK: - Supporting Types

/// Newsletter summarization result
struct NewsletterSummary {
    let summary: String
    let links: [EmailCard.NewsletterLink]
    let keyTopics: [String]
}

/// Errors that can occur during summarization
enum SummarizationError: LocalizedError {
    case notAuthenticated
    case requestFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please sign in."
        case .requestFailed:
            return "Failed to generate summary. Please try again."
        case .invalidResponse:
            return "Invalid response from server."
        }
    }
}
