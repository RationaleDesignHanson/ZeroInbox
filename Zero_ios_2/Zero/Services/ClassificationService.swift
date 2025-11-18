import Foundation

/// Service for ML-based email classification using the backend classifier service
/// Provides intent detection, entity extraction, and action suggestions (PRD 4.1)
class ClassificationService {
    static let shared = ClassificationService()

    private let baseURL: String

    private init() {
        // Use Environment to get the correct classifier API base URL
        self.baseURL = "\(AppEnvironment.current.classifierBaseURL)/classify"
    }

    // MARK: - Public Methods

    /// Classify a single email using ML-based classifier
    /// - Parameter email: Email content to classify
    /// - Returns: Classification result with intent, actions, and archetype
    func classifyEmail(
        subject: String,
        from: String,
        body: String?,
        snippet: String?
    ) async throws -> ClassificationResult {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        Logger.info("Classifying email: \(subject)", category: .classification)

        let url = URL(string: baseURL)!

        struct EmailData: Codable {
            let subject: String
            let from: String
            let body: String
            let snippet: String
        }

        struct ClassifyRequest: Codable {
            let email: EmailData
        }

        let requestBody = ClassifyRequest(
            email: EmailData(
                subject: subject,
                from: from,
                body: body ?? "",
                snippet: snippet ?? ""
            )
        )

        do {
            let response: ClassificationResponse = try await NetworkService.shared.post(
                url: url,
                body: requestBody
            )

            let result = try parseClassificationResponse(response)

            Logger.info("Classified as \(result.type.displayName) with \(Int(result.confidence * 100))% confidence", category: .classification)
            return result
        } catch let error as NetworkServiceError {
            if let statusCode = error.statusCode {
                Logger.error("API error: \(statusCode)", category: .classification)
                throw ClassificationError.apiError(statusCode: statusCode, message: error.errorDescription ?? "Unknown error")
            }
            throw ClassificationError.invalidResponse
        }
    }

    /// Classify multiple emails in batch
    /// - Parameter emails: Array of email data
    /// - Returns: Array of classification results
    func classifyBatch(
        emails: [(subject: String, from: String, body: String?, snippet: String?)]
    ) async throws -> [ClassificationResult] {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        Logger.info("Classifying batch of \(emails.count) emails", category: .classification)

        let url = URL(string: "\(AppEnvironment.current.classifierBaseURL)/classify/batch")!

        struct EmailData: Codable {
            let subject: String
            let from: String
            let body: String
            let snippet: String
        }

        struct BatchClassifyRequest: Codable {
            let emails: [EmailData]
        }

        struct BatchClassifyResponse: Codable {
            let classifications: [ClassificationResponse]
        }

        let requestBody = BatchClassifyRequest(
            emails: emails.map { email in
                EmailData(
                    subject: email.subject,
                    from: email.from,
                    body: email.body ?? "",
                    snippet: email.snippet ?? ""
                )
            }
        )

        let response: BatchClassifyResponse = try await NetworkService.shared.post(
            url: url,
            body: requestBody
        )

        let results = try response.classifications.map { try parseClassificationResponse($0) }

        Logger.info("Batch classified \(results.count) emails", category: .classification)
        return results
    }

    // MARK: - Private Methods

    /// Parse classification response into result
    private func parseClassificationResponse(_ response: ClassificationResponse) throws -> ClassificationResult {
        guard let type = CardType(rawValue: response.type),
              let priority = Priority(rawValue: response.priority) else {
            throw ClassificationError.parsingError
        }

        // Parse suggested actions if present
        let suggestedActions = response.suggestedActions?.map { actionResponse in
            EmailAction(
                actionId: actionResponse.actionId,
                displayName: actionResponse.displayName,
                actionType: ActionType(rawValue: actionResponse.actionType) ?? .inApp,
                isPrimary: actionResponse.isPrimary,
                priority: actionResponse.priority,
                context: actionResponse.context,
                isCompound: actionResponse.isCompound,
                compoundSteps: actionResponse.compoundSteps
            )
        }

        return ClassificationResult(
            type: type,
            priority: priority,
            hpa: response.hpa,
            confidence: response.confidence,
            intent: response.intent,
            intentConfidence: response.intentConfidence,
            suggestedActions: suggestedActions
        )
    }
}

// MARK: - API Response Models

/// Classification API response structure
struct ClassificationResponse: Codable {
    let type: String
    let priority: String
    let hpa: String
    let confidence: Double
    let intent: String?
    let intentConfidence: Double?
    let suggestedActions: [SuggestedActionResponse]?
}

/// Suggested action response structure
struct SuggestedActionResponse: Codable {
    let actionId: String
    let displayName: String
    let actionType: String
    let isPrimary: Bool
    let priority: Int?
    let context: [String: String]?
    let isCompound: Bool?
    let compoundSteps: [String]?
}

// MARK: - Classification Result Model

/// Result of email classification
struct ClassificationResult {
    let type: CardType
    let priority: Priority
    let hpa: String
    let confidence: Double
    let intent: String?
    let intentConfidence: Double?
    let suggestedActions: [EmailAction]?
}

// MARK: - Error Types

enum ClassificationError: Error, LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parsingError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from classification service"
        case .apiError(let statusCode, let message):
            return "Classification API error (\(statusCode)): \(message)"
        case .parsingError:
            return "Failed to parse classification result"
        }
    }
}
