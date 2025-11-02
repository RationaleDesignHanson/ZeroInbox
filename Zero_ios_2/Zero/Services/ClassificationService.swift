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
        Logger.info("Classifying email: \(subject)", category: .classification)

        let url = URL(string: baseURL)!

        // Build request body
        let emailData: [String: Any] = [
            "subject": subject,
            "from": from,
            "body": body ?? "",
            "snippet": snippet ?? ""
        ]

        let requestBody: [String: Any] = [
            "email": emailData
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClassificationError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.error("API error: \(errorText)", category: .classification)
            throw ClassificationError.apiError(statusCode: httpResponse.statusCode, message: errorText)
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ClassificationError.invalidResponse
        }

        let result = try parseClassificationResult(from: json)

        Logger.info("Classified as \(result.type.displayName) with \(Int(result.confidence * 100))% confidence", category: .classification)
        return result
    }

    /// Classify multiple emails in batch
    /// - Parameter emails: Array of email data
    /// - Returns: Array of classification results
    func classifyBatch(
        emails: [(subject: String, from: String, body: String?, snippet: String?)]
    ) async throws -> [ClassificationResult] {
        Logger.info("Classifying batch of \(emails.count) emails", category: .classification)

        let url = URL(string: "\(AppEnvironment.current.classifierBaseURL)/classify/batch")!

        // Build request body
        let emailsData = emails.map { email in
            return [
                "subject": email.subject,
                "from": email.from,
                "body": email.body ?? "",
                "snippet": email.snippet ?? ""
            ] as [String: Any]
        }

        let requestBody: [String: Any] = [
            "emails": emailsData
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ClassificationError.invalidResponse
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let classifications = json["classifications"] as? [[String: Any]] else {
            throw ClassificationError.invalidResponse
        }

        let results = try classifications.map { try parseClassificationResult(from: $0) }

        Logger.info("Batch classified \(results.count) emails", category: .classification)
        return results
    }

    // MARK: - Private Methods

    /// Parse classification result from JSON
    private func parseClassificationResult(from json: [String: Any]) throws -> ClassificationResult {
        guard let typeString = json["type"] as? String,
              let type = CardType(rawValue: typeString),
              let priorityString = json["priority"] as? String,
              let priority = Priority(rawValue: priorityString),
              let hpa = json["hpa"] as? String,
              let confidence = json["confidence"] as? Double else {
            throw ClassificationError.parsingError
        }

        // Parse intent (optional)
        let intent = json["intent"] as? String
        let intentConfidence = json["intentConfidence"] as? Double

        // Parse suggested actions (optional)
        var suggestedActions: [EmailAction]? = nil
        if let actionsArray = json["suggestedActions"] as? [[String: Any]] {
            suggestedActions = try? actionsArray.map { actionJson in
                guard let actionId = actionJson["actionId"] as? String,
                      let displayName = actionJson["displayName"] as? String,
                      let actionTypeString = actionJson["actionType"] as? String,
                      let actionType = ActionType(rawValue: actionTypeString),
                      let isPrimary = actionJson["isPrimary"] as? Bool else {
                    throw ClassificationError.parsingError
                }

                let priority = actionJson["priority"] as? Int
                let context = actionJson["context"] as? [String: String]
                let isCompound = actionJson["isCompound"] as? Bool
                let compoundSteps = actionJson["compoundSteps"] as? [String]

                return EmailAction(
                    actionId: actionId,
                    displayName: displayName,
                    actionType: actionType,
                    isPrimary: isPrimary,
                    priority: priority,
                    context: context,
                    isCompound: isCompound,
                    compoundSteps: compoundSteps
                )
            }
        }

        return ClassificationResult(
            type: type,
            priority: priority,
            hpa: hpa,
            confidence: confidence,
            intent: intent,
            intentConfidence: intentConfidence,
            suggestedActions: suggestedActions
        )
    }
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
