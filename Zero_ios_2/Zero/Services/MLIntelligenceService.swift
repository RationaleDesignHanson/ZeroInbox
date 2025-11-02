import Foundation

/**
 * ML Intelligence Service (Phase 4)
 * Corpus-trained intent classification and entity extraction
 *
 * Features:
 * - API-powered intent classification using Gemini with few-shot learning
 * - Entity extraction (dates, amounts, tracking numbers, etc.)
 * - 24-hour cache for predictions
 * - Offline fallback to rule-based classification
 * - Async/await support
 */

// MARK: - API Response Models

struct IntentClassification: Codable {
    let intent: String
    let confidence: Double
    let reasoning: String
    let category: String
    let fromCache: Bool?
    let timestamp: String
    let usedExamples: Int?
}

struct EntityExtractionResponse: Codable {
    let entities: [ExtractedEntity]
    let entityCount: Int
    let fromCache: Bool?
    let timestamp: String
    let usedExamples: Int?
}

struct ExtractedEntity: Codable, Identifiable {
    var id: String { "\(type)_\(value)" }
    let type: String
    let value: String
    let normalized: String?
}

struct FullAnalysisResponse: Codable {
    let intent: String
    let confidence: Double
    let reasoning: String?
    let category: String
    let entities: [ExtractedEntity]
    let entityCount: Int
    let timestamp: String
    let usedExamples: Int?
}

struct IntentsResponse: Codable {
    let intents: [String]
    let categories: [String: [String]]
    let totalIntents: Int
}

// MARK: - ML Intelligence Service

@MainActor
class MLIntelligenceService: ObservableObject {
    static let shared = MLIntelligenceService()

    @Published var isLoading = false
    @Published var error: String?

    // Cached predictions
    private var cachedClassifications: [String: IntentClassification] = [:]
    private var cachedEntities: [String: EntityExtractionResponse] = [:]
    private var cacheTimestamps: [String: Date] = [:]

    // Cache expiration (24 hours)
    private let cacheExpirationInterval: TimeInterval = 24 * 60 * 60

    // API Configuration
    private let intelligenceServiceBaseURL: String

    private init() {
        // Use environment variable or default
        if let urlString = ProcessInfo.processInfo.environment["ML_INTELLIGENCE_URL"] {
            self.intelligenceServiceBaseURL = urlString
        } else if let urlString = Bundle.main.infoDictionary?["ML_INTELLIGENCE_URL"] as? String {
            self.intelligenceServiceBaseURL = urlString
        } else {
            self.intelligenceServiceBaseURL = "http://localhost:8089"
        }
    }

    // MARK: - Public API

    /**
     * Classify email intent
     */
    func classifyIntent(
        subject: String,
        body: String,
        userId: String,
        forceRefresh: Bool = false
    ) async -> IntentClassification? {
        let cacheKey = "\(subject)|\(body)"

        // Check cache first
        if !forceRefresh && isCacheValid(for: cacheKey) {
            if let cached = cachedClassifications[cacheKey] {
                print("📦 Using cached intent classification")
                return cached
            }
        }

        // Call API
        do {
            let classification = try await fetchIntentClassification(
                subject: subject,
                body: body,
                userId: userId
            )

            // Cache the result
            cachedClassifications[cacheKey] = classification
            cacheTimestamps[cacheKey] = Date()

            print("✅ Classified as: \(classification.intent) (confidence: \(classification.confidence))")
            return classification

        } catch {
            print("⚠️ Failed to classify intent: \(error.localizedDescription)")
            print("📱 Using fallback classification")

            // Return fallback classification
            return fallbackClassifyIntent(subject: subject, body: body)
        }
    }

    /**
     * Extract entities from email
     */
    func extractEntities(
        subject: String,
        body: String,
        userId: String,
        forceRefresh: Bool = false
    ) async -> [ExtractedEntity] {
        let cacheKey = "\(subject)|\(body)"

        // Check cache first
        if !forceRefresh && isCacheValid(for: cacheKey) {
            if let cached = cachedEntities[cacheKey] {
                print("📦 Using cached entity extraction")
                return cached.entities
            }
        }

        // Call API
        do {
            let response = try await fetchEntityExtraction(
                subject: subject,
                body: body,
                userId: userId
            )

            // Cache the result
            cachedEntities[cacheKey] = response
            cacheTimestamps[cacheKey] = Date()

            print("✅ Extracted \(response.entityCount) entities")
            return response.entities

        } catch {
            print("⚠️ Failed to extract entities: \(error.localizedDescription)")
            print("📱 Using fallback extraction")

            // Return fallback entities
            return fallbackExtractEntities(subject: subject, body: body)
        }
    }

    /**
     * Full email analysis (intent + entities)
     */
    func analyzeEmail(
        subject: String,
        body: String,
        userId: String,
        forceRefresh: Bool = false
    ) async -> (intent: IntentClassification?, entities: [ExtractedEntity]) {
        // Try full analysis endpoint first (more efficient)
        do {
            let analysis = try await fetchFullAnalysis(
                subject: subject,
                body: body,
                userId: userId
            )

            let classification = IntentClassification(
                intent: analysis.intent,
                confidence: analysis.confidence,
                reasoning: analysis.reasoning ?? "",
                category: analysis.category,
                fromCache: false,
                timestamp: analysis.timestamp,
                usedExamples: analysis.usedExamples
            )

            return (classification, analysis.entities)

        } catch {
            print("⚠️ Full analysis failed, falling back to separate calls")

            // Fallback to separate calls
            async let intentTask = classifyIntent(subject: subject, body: body, userId: userId, forceRefresh: forceRefresh)
            async let entitiesTask = extractEntities(subject: subject, body: body, userId: userId, forceRefresh: forceRefresh)

            let (intent, entities) = await (intentTask, entitiesTask)
            return (intent, entities)
        }
    }

    /**
     * Get all available intents
     */
    func getAvailableIntents() async -> [String] {
        do {
            let url = URL(string: "\(intelligenceServiceBaseURL)/api/intelligence/intents")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(IntentsResponse.self, from: data)
            return response.intents
        } catch {
            print("⚠️ Failed to fetch intents: \(error.localizedDescription)")
            return []
        }
    }

    /**
     * Invalidate cache
     */
    func invalidateCache() {
        cachedClassifications.removeAll()
        cachedEntities.removeAll()
        cacheTimestamps.removeAll()
        print("🗑️ Invalidated ML intelligence cache")
    }

    // MARK: - Private Methods

    /**
     * Check if cache is valid
     */
    private func isCacheValid(for key: String) -> Bool {
        guard let timestamp = cacheTimestamps[key] else {
            return false
        }

        let elapsed = Date().timeIntervalSince(timestamp)
        return elapsed < cacheExpirationInterval
    }

    /**
     * Fetch intent classification from API
     */
    private func fetchIntentClassification(
        subject: String,
        body: String,
        userId: String
    ) async throws -> IntentClassification {
        let url = URL(string: "\(intelligenceServiceBaseURL)/api/intelligence/classify")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let requestBody: [String: Any] = [
            "subject": subject,
            "body": body,
            "userId": userId
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MLIntelligenceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw MLIntelligenceError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(IntentClassification.self, from: data)
    }

    /**
     * Fetch entity extraction from API
     */
    private func fetchEntityExtraction(
        subject: String,
        body: String,
        userId: String
    ) async throws -> EntityExtractionResponse {
        let url = URL(string: "\(intelligenceServiceBaseURL)/api/intelligence/extract-entities")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let requestBody: [String: Any] = [
            "subject": subject,
            "body": body,
            "userId": userId
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MLIntelligenceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw MLIntelligenceError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(EntityExtractionResponse.self, from: data)
    }

    /**
     * Fetch full analysis from API
     */
    private func fetchFullAnalysis(
        subject: String,
        body: String,
        userId: String
    ) async throws -> FullAnalysisResponse {
        let url = URL(string: "\(intelligenceServiceBaseURL)/api/intelligence/analyze")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let requestBody: [String: Any] = [
            "subject": subject,
            "body": body,
            "userId": userId
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MLIntelligenceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw MLIntelligenceError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(FullAnalysisResponse.self, from: data)
    }

    /**
     * Fallback intent classification (rule-based)
     */
    private func fallbackClassifyIntent(subject: String, body: String) -> IntentClassification {
        let text = "\(subject) \(body)".lowercased()

        // Simple keyword matching
        if text.contains("invoice") || text.contains("payment due") || text.contains("bill") {
            return IntentClassification(
                intent: "billing.invoice.due",
                confidence: 0.6,
                reasoning: "Keyword match (fallback)",
                category: "billing",
                fromCache: false,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                usedExamples: 0
            )
        } else if text.contains("shipped") || text.contains("tracking") || text.contains("delivery") {
            return IntentClassification(
                intent: "e-commerce.shipping.notification",
                confidence: 0.6,
                reasoning: "Keyword match (fallback)",
                category: "e-commerce",
                fromCache: false,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                usedExamples: 0
            )
        } else if text.contains("meeting") || text.contains("calendar") || text.contains("zoom") {
            return IntentClassification(
                intent: "event.meeting.invitation",
                confidence: 0.6,
                reasoning: "Keyword match (fallback)",
                category: "event",
                fromCache: false,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                usedExamples: 0
            )
        } else if text.contains("security") || text.contains("suspicious") || text.contains("verify") {
            return IntentClassification(
                intent: "account.security.alert",
                confidence: 0.6,
                reasoning: "Keyword match (fallback)",
                category: "account",
                fromCache: false,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                usedExamples: 0
            )
        } else {
            return IntentClassification(
                intent: "communication.general",
                confidence: 0.5,
                reasoning: "No clear match (fallback)",
                category: "communication",
                fromCache: false,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                usedExamples: 0
            )
        }
    }

    /**
     * Fallback entity extraction (regex-based)
     */
    private func fallbackExtractEntities(subject: String, body: String) -> [ExtractedEntity] {
        let text = "\(subject) \(body)"
        var entities: [ExtractedEntity] = []

        // Extract tracking numbers
        let trackingPatterns = [
            "\\b1Z[0-9A-Z]{16}\\b",  // UPS
            "\\b[0-9]{22}\\b",       // FedEx
            "\\b[0-9]{12}\\b"        // USPS
        ]

        for pattern in trackingPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let value = String(text[range])
                        entities.append(ExtractedEntity(
                            type: "tracking_number",
                            value: value,
                            normalized: nil
                        ))
                    }
                }
            }
        }

        // Extract amounts
        if let regex = try? NSRegularExpression(pattern: "\\$[0-9,]+\\.?[0-9]*") {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let value = String(text[range])
                    let normalized = value.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
                    entities.append(ExtractedEntity(
                        type: "amount",
                        value: value,
                        normalized: normalized
                    ))
                }
            }
        }

        // Extract URLs
        if let regex = try? NSRegularExpression(pattern: "https?://[^\\s<>\"]+") {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let value = String(text[range])
                    entities.append(ExtractedEntity(
                        type: "url",
                        value: value,
                        normalized: nil
                    ))
                }
            }
        }

        return entities
    }

    /**
     * Get cache info for debugging
     */
    func getCacheInfo() -> String {
        var info = "ML Intelligence Cache Info:\n"
        info += "- Classifications cached: \(cachedClassifications.count)\n"
        info += "- Entity extractions cached: \(cachedEntities.count)\n"

        let now = Date()
        let validCount = cacheTimestamps.filter { now.timeIntervalSince($0.value) < cacheExpirationInterval }.count
        info += "- Valid cache entries: \(validCount)\n"
        info += "- Cache TTL: 24 hours\n"

        return info
    }
}

// MARK: - Errors

enum MLIntelligenceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network error"
        }
    }
}
