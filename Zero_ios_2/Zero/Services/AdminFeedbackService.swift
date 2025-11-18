#if DEBUG
import Foundation

/// Service for managing admin feedback on email classifications
/// Feedback is used to improve classification accuracy over time
class AdminFeedbackService {
    static let shared = AdminFeedbackService()

    // Admin endpoints deployed to Cloud Run - works on both Simulator and real devices
    private let baseURL = "https://emailshortform-classifier-514014482017.us-central1.run.app/api"

    // MARK: - Fetch Next Email for Review

    /// Fetches the next unreviewed email from the classifier service
    /// Prioritizes low-confidence classifications that need human review
    func fetchNextEmail() async throws -> ClassifiedEmail {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        guard let url = URL(string: "\(baseURL)/admin/next-review") else {
            throw URLError(.badURL)
        }

        let response: ClassifiedEmailResponse = try await NetworkService.shared.get(url: url)

        return ClassifiedEmail(
            id: response.id,
            from: response.from,
            subject: response.subject,
            snippet: response.snippet,
            timeAgo: response.timeAgo,
            classifiedType: CardType(rawValue: response.classifiedType) ?? .mail,
            priority: Priority(rawValue: response.priority) ?? .medium,
            confidence: response.confidence
        )
    }

    // MARK: - Generate Sample Email

    /// Generates a sample email for testing the feedback interface
    /// Useful when no real emails are available for review
    func generateSampleEmail() async throws -> ClassifiedEmail {
        // For MVP, generate locally. In production, this would call backend
        let samples: [(String, String, String, CardType, Priority)] = [
            (
                "sarah.j@techcorp.com",
                "Q4 Product Roadmap Review - Action Required",
                "Hi team, I've attached the Q4 roadmap. Please review sections 2-4 and provide feedback by EOD Friday. We need to finalize priorities before the stakeholder meeting next week.",
                .mail,
                .high
            ),
            (
                "deals@amazon.com",
                "48-Hour Flash Sale: Sony WH-1000XM5 Headphones",
                "Premium noise-canceling headphones now 35% off for Prime members. Limited stock available. Sale ends Sunday at midnight. Free shipping included.",
                .ads,
                .medium
            ),
            (
                "teacher@elementaryschool.edu",
                "Field Trip Permission Form - Due October 25",
                "Dear Parents, Your child's class will visit the Natural History Museum on Nov 15. Please sign the attached permission form and return by Oct 25. Cost is $12 per student.",
                .mail,
                .high
            ),
            (
                "leads@salesforce.com",
                "Enterprise Demo Request - Acme Corp ($250K opportunity)",
                "Warm lead from Acme Corp CFO interested in Enterprise plan. 500-person company, current contract ending Q1. Requested demo for next Tuesday 2PM. High intent signals.",
                .mail,
                .critical
            ),
            (
                "noreply@github.com",
                "[repo-name] Build failed on main branch",
                "Pipeline #1247 failed with 3 test failures in the authentication module. Last commit by john.doe broke UserService tests. Branch is blocked from merging.",
                .mail,
                .critical
            )
        ]

        let sample = samples.randomElement()!
        let confidence = Double.random(in: 0.55...0.95)  // Mix of high and low confidence

        return ClassifiedEmail(
            id: UUID().uuidString,
            from: sample.0,
            subject: sample.1,
            snippet: sample.2,
            timeAgo: "\(Int.random(in: 1...24)) hours ago",
            classifiedType: sample.3,
            priority: sample.4,
            confidence: confidence
        )
    }

    // MARK: - Submit Feedback

    /// Submits admin feedback on a classification
    /// This feedback is used to:
    /// 1. Immediately log misclassifications for analysis
    /// 2. Build training dataset for model improvement
    /// 3. Generate periodic retraining reports
    func submitFeedback(_ feedback: ClassificationFeedback) async throws {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        guard let url = URL(string: "\(baseURL)/admin/feedback") else {
            throw URLError(.badURL)
        }

        struct ClassificationFeedbackRequest: Codable {
            let emailId: String
            let originalType: String
            let correctedType: String?
            let isCorrect: Bool
            let confidence: Double
            let notes: String?
            let timestamp: String
            let reviewerId: String
        }

        let requestBody = ClassificationFeedbackRequest(
            emailId: feedback.emailId,
            originalType: feedback.originalType.rawValue,
            correctedType: feedback.correctedType?.rawValue,
            isCorrect: feedback.isCorrect,
            confidence: feedback.confidence,
            notes: feedback.notes,
            timestamp: ISO8601DateFormatter().string(from: feedback.timestamp),
            reviewerId: AuthContext.getAdminId()
        )

        do {
            try await NetworkService.shared.post(url: url, body: requestBody)
            Logger.info("Feedback submitted successfully", category: .app)
        } catch {
            // If backend not ready, just log locally for MVP
            Logger.warning("Backend not available, logging feedback locally for \(feedback.emailId)", category: .app)
            Logger.info("Feedback - Original: \(feedback.originalType.displayName), Correct: \(feedback.isCorrect)", category: .app)

            // For MVP: Store in UserDefaults until backend is ready
            storeFeedbackLocally(feedback)
        }
    }

    // MARK: - Local Storage (MVP Fallback)

    /// Stores feedback locally when backend is unavailable
    /// This allows the feature to work immediately while backend is developed
    private func storeFeedbackLocally(_ feedback: ClassificationFeedback) {
        let defaults = UserDefaults.standard
        var storedFeedback = loadLocalFeedback()
        storedFeedback.append(feedback)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let encoded = try? encoder.encode(storedFeedback) {
            defaults.set(encoded, forKey: "classification_feedback")
            Logger.info("Stored feedback locally (\(storedFeedback.count) total)", category: .app)
        }
    }

    /// Loads all locally stored feedback
    /// Useful for exporting or syncing with backend later
    func loadLocalFeedback() -> [ClassificationFeedback] {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "classification_feedback") else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return (try? decoder.decode([ClassificationFeedback].self, from: data)) ?? []
    }

    // MARK: - Analytics

    /// Generates a feedback summary for analysis
    /// Shows classification accuracy and common errors
    func generateFeedbackSummary() -> FeedbackSummary {
        let feedback = loadLocalFeedback()

        var typeAccuracy: [CardType: (correct: Int, total: Int)] = [:]
        var commonMisclassifications: [(from: CardType, to: CardType, count: Int)] = []

        for item in feedback {
            // Track accuracy per type
            let type = item.originalType
            var stats = typeAccuracy[type] ?? (correct: 0, total: 0)
            stats.total += 1
            if item.isCorrect {
                stats.correct += 1
            }
            typeAccuracy[type] = stats

            // Track misclassifications
            if !item.isCorrect, let corrected = item.correctedType {
                // Find or create misclassification pair
                if let index = commonMisclassifications.firstIndex(where: { $0.from == type && $0.to == corrected }) {
                    commonMisclassifications[index].count += 1
                } else {
                    commonMisclassifications.append((from: type, to: corrected, count: 1))
                }
            }
        }

        // Sort misclassifications by frequency
        commonMisclassifications.sort { $0.count > $1.count }

        return FeedbackSummary(
            totalReviewed: feedback.count,
            overallAccuracy: feedback.isEmpty ? 0 : Double(feedback.filter { $0.isCorrect }.count) / Double(feedback.count),
            typeAccuracy: typeAccuracy,
            topMisclassifications: Array(commonMisclassifications.prefix(5))
        )
    }

    /// Exports feedback summary as JSON for analysis
    /// Can be imported into analysis tools or ML training pipelines
    func exportSummaryJSON() -> String? {
        let summary = generateFeedbackSummary()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        guard let data = try? encoder.encode(summary),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }

        return json
    }
}

// MARK: - API Response Models

struct ClassifiedEmailResponse: Codable {
    let id: String
    let from: String
    let subject: String
    let snippet: String
    let timeAgo: String
    let classifiedType: String
    let priority: String
    let confidence: Double
}

struct FeedbackSummary: Codable {
    let totalReviewed: Int
    let overallAccuracy: Double
    let typeAccuracy: [String: AccuracyStats]
    let topMisclassifications: [Misclassification]

    init(totalReviewed: Int, overallAccuracy: Double, typeAccuracy: [CardType: (correct: Int, total: Int)], topMisclassifications: [(from: CardType, to: CardType, count: Int)]) {
        self.totalReviewed = totalReviewed
        self.overallAccuracy = overallAccuracy

        // Convert CardType to String for JSON encoding
        self.typeAccuracy = typeAccuracy.reduce(into: [:]) { result, pair in
            let accuracy = pair.value.total > 0 ? Double(pair.value.correct) / Double(pair.value.total) : 0
            result[pair.key.rawValue] = AccuracyStats(
                correct: pair.value.correct,
                total: pair.value.total,
                accuracy: accuracy
            )
        }

        self.topMisclassifications = topMisclassifications.map {
            Misclassification(from: $0.from.rawValue, to: $0.to.rawValue, count: $0.count)
        }
    }
}

struct AccuracyStats: Codable {
    let correct: Int
    let total: Int
    let accuracy: Double
}

struct Misclassification: Codable {
    let from: String
    let to: String
    let count: Int
}
#endif
