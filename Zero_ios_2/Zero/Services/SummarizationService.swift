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
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw SummarizationError.notAuthenticated
        }

        Logger.info("Requesting AI summary for email: \(card.id)", category: .email)

        guard let url = URL(string: "\(baseURL)/emails/summarize") else {
            throw SummarizationError.invalidResponse
        }

        struct SummarizeEmailRequest: Codable {
            let emailId: String
            let subject: String
            let from: String
            let body: String
            let snippet: String
            let type: String
        }

        struct GenericSummaryResponse: Codable {
            let summary: String
        }

        let requestBody = SummarizeEmailRequest(
            emailId: card.id,
            subject: card.title,
            from: card.sender?.name ?? card.company?.name ?? "Unknown",
            body: card.body ?? card.summary,
            snippet: String(card.summary.prefix(500)),
            type: card.type.rawValue
        )

        do {
            let summaryResponse: GenericSummaryResponse = try await NetworkService.shared.request(
                url: url,
                method: .post,
                headers: ["Authorization": "Bearer \(token)"],
                body: requestBody
            )

            Logger.info("AI summary generated successfully for \(card.id)", category: .email)
            return summaryResponse.summary
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                Logger.error("Email summarization failed with status \(statusCode)", category: .email)
            }
            throw SummarizationError.requestFailed
        }
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
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        guard let token = authToken ?? loadTokenFromKeychain() else {
            throw SummarizationError.notAuthenticated
        }

        Logger.info("Requesting newsletter summary for: \(card.id)", category: .email)

        guard let url = URL(string: "\(baseURL)/emails/summarize/newsletter") else {
            throw SummarizationError.invalidResponse
        }

        struct SummarizeNewsletterRequest: Codable {
            let emailId: String
            let subject: String
            let from: String
            let body: String
            let snippet: String
        }

        struct LinkData: Codable {
            let title: String
            let url: String
            let description: String?
        }

        struct SummaryResponse: Codable {
            let summary: String
            let keyLinks: [LinkData]
            let keyTopics: [String]?
        }

        let requestBody = SummarizeNewsletterRequest(
            emailId: card.id,
            subject: card.title,
            from: card.company?.name ?? "Unknown",
            body: card.summary,
            snippet: String(card.summary.prefix(500))
        )

        do {
            let summaryResponse: SummaryResponse = try await NetworkService.shared.request(
                url: url,
                method: .post,
                headers: ["Authorization": "Bearer \(token)"],
                body: requestBody
            )

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
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                Logger.error("Newsletter summarization failed with status \(statusCode)", category: .email)
            }
            throw SummarizationError.requestFailed
        }
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
