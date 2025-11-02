import Foundation

/// Service for managing admin feedback on suggested email actions
/// Feedback is used to improve action suggestion accuracy over time
class ActionFeedbackService {
    static let shared = ActionFeedbackService()

    // Admin endpoints deployed to Cloud Run
    private let baseURL = "https://emailshortform-classifier-514014482017.us-central1.run.app/api"

    // MARK: - Fetch Next Email for Action Review

    /// Fetches the next email with suggested actions for review
    /// Prioritizes emails with multiple actions or lower confidence
    func fetchNextEmailWithActions() async throws -> ClassifiedEmailWithActions {
        guard let url = URL(string: "\(baseURL)/admin/next-action-review") else {
            throw URLError(.badURL)
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            // Log the response for debugging
            if let httpResponse = response as? HTTPURLResponse {
                Logger.info("Fetch action review - Status: \(httpResponse.statusCode)", category: .app)

                // If not 200, log the response body
                if httpResponse.statusCode != 200 {
                    if let responseText = String(data: data, encoding: .utf8) {
                        Logger.error("API Error Response: \(responseText)", category: .app)
                    }
                    throw NSError(domain: "ActionFeedbackService", code: httpResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "Server returned status \(httpResponse.statusCode). The admin endpoint may not be deployed yet. Try using 'Load Sample' instead."
                    ])
                }
            }

            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(ClassifiedEmailWithActionsResponse.self, from: data)

            return ClassifiedEmailWithActions(
                id: decodedResponse.id,
                from: decodedResponse.from,
                subject: decodedResponse.subject,
                snippet: decodedResponse.snippet,
                timeAgo: decodedResponse.timeAgo,
                intent: decodedResponse.intent,
                suggestedActions: decodedResponse.suggestedActions.map { actionResponse in
                    EmailAction(
                        actionId: actionResponse.actionId,
                        displayName: actionResponse.displayName,
                        actionType: ActionType(rawValue: actionResponse.actionType) ?? .inApp,
                        isPrimary: actionResponse.isPrimary,
                        priority: actionResponse.priority
                    )
                },
                confidence: decodedResponse.confidence
            )
        } catch let decodingError as DecodingError {
            // Better error message for decoding issues
            Logger.error("JSON Decoding Error: \(decodingError)", category: .app)
            throw NSError(domain: "ActionFeedbackService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Data format error: The server returned unexpected data. Try using 'Load Sample' instead."
            ])
        } catch {
            throw error
        }
    }

    // MARK: - Generate Sample Email

    /// Generates a sample email with actions for testing the feedback interface
    func generateSampleEmailWithActions() async throws -> ClassifiedEmailWithActions {
        // Sample emails with realistic action suggestions
        let samples: [(String, String, String, String, [EmailAction])] = [
            (
                "tracking@amazon.com",
                "Your package has shipped - Track your order",
                "Order #123-456789 has shipped via UPS. Tracking number: 1Z999AA10123456784. Estimated delivery: Oct 28, 2025.",
                "e-commerce.shipping.notification",
                [
                    EmailAction(actionId: "track_package", displayName: "Track Package", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "view_order", displayName: "View Order", actionType: .goTo, isPrimary: false, priority: 2),
                    EmailAction(actionId: "contact_carrier", displayName: "Contact Carrier", actionType: .goTo, isPrimary: false, priority: 3)
                ]
            ),
            (
                "teacher@school.edu",
                "Field Trip Permission Form - Please Sign by Oct 25",
                "Please sign the attached permission form for the field trip to the Science Museum on Nov 15. Fee: $12 per student.",
                "education.permission.form",
                [
                    EmailAction(actionId: "sign_form", displayName: "Sign Form", actionType: .inApp, isPrimary: true, priority: 1),
                    EmailAction(actionId: "pay_form_fee", displayName: "Pay Fee ($12)", actionType: .goTo, isPrimary: false, priority: 2),
                    EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 3)
                ]
            ),
            (
                "billing@acme.com",
                "Invoice #INV-2025-1234 Due October 30",
                "Invoice INV-2025-1234 for $599.00 is due Oct 30, 2025. Pay online: https://pay.acme.com/INV-2025-1234",
                "billing.invoice.due",
                [
                    EmailAction(actionId: "pay_invoice", displayName: "Pay Invoice", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "view_invoice", displayName: "View Invoice", actionType: .goTo, isPrimary: false, priority: 2),
                    EmailAction(actionId: "download_receipt", displayName: "Download Receipt", actionType: .goTo, isPrimary: false, priority: 3)
                ]
            ),
            (
                "noreply@united.com",
                "Flight UA 123 Check-In Now Available",
                "Check in for flight UA 123 departing tomorrow at 9:00 AM from SFO to LAX. Check in: https://united.com/checkin/ABC123",
                "travel.flight.check-in",
                [
                    EmailAction(actionId: "check_in_flight", displayName: "Check In", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "view_itinerary", displayName: "View Itinerary", actionType: .goTo, isPrimary: false, priority: 2),
                    EmailAction(actionId: "add_to_wallet", displayName: "Add to Wallet", actionType: .inApp, isPrimary: false, priority: 3)
                ]
            ),
            (
                "deals@avantarte.com",
                "Limited Edition Print by Banksy - Launching Oct 31, 5pm UK",
                "New limited edition print \"Girl with Balloon\" launching Oct 31 at 5pm UK time. 100 prints available. Price: £595.",
                "shopping.scheduled-purchase",
                [
                    EmailAction(actionId: "schedule_purchase", displayName: "Set Purchase Reminder", actionType: .inApp, isPrimary: true, priority: 1),
                    EmailAction(actionId: "view_product", displayName: "View Product", actionType: .goTo, isPrimary: false, priority: 2),
                    EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 3)
                ]
            )
        ]

        let sample = samples.randomElement()!
        let confidence = Double.random(in: 0.60...0.95)

        return ClassifiedEmailWithActions(
            id: UUID().uuidString,
            from: sample.0,
            subject: sample.1,
            snippet: sample.2,
            timeAgo: "\(Int.random(in: 1...24)) hours ago",
            intent: sample.3,
            suggestedActions: sample.4,
            confidence: confidence
        )
    }

    // MARK: - Submit Feedback

    /// Submits admin feedback on action suggestions
    /// This feedback is used to:
    /// 1. Log incorrect action suggestions for analysis
    /// 2. Build training dataset for action model improvement
    /// 3. Identify missed actions (false negatives)
    func submitFeedback(_ feedback: ActionFeedback) async throws {
        guard let url = URL(string: "\(baseURL)/admin/action-feedback") else {
            throw URLError(.badURL)
        }

        // Convert to API format
        let payload: [String: Any] = [
            "emailId": feedback.emailId,
            "intent": feedback.intent,
            "originalActions": feedback.originalActions,
            "correctedActions": feedback.correctedActions as Any,
            "isCorrect": feedback.isCorrect,
            "missedActions": feedback.missedActions as Any,
            "unnecessaryActions": feedback.unnecessaryActions as Any,
            "confidence": feedback.confidence,
            "notes": feedback.notes as Any,
            "timestamp": ISO8601DateFormatter().string(from: feedback.timestamp),
            "reviewerId": "admin-user"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            // If backend not ready, log locally for MVP
            Logger.warning("Backend not available, logging action feedback locally for \(feedback.emailId)", category: .app)
            Logger.info("Action Feedback - Intent: \(feedback.intent), Correct: \(feedback.isCorrect)", category: .app)

            // Store in UserDefaults until backend is ready
            storeFeedbackLocally(feedback)
            return
        }

        Logger.info("Action feedback submitted successfully", category: .app)
    }

    // MARK: - Local Storage (MVP Fallback)

    /// Stores feedback locally when backend is unavailable
    private func storeFeedbackLocally(_ feedback: ActionFeedback) {
        let defaults = UserDefaults.standard
        var storedFeedback = loadLocalFeedback()
        storedFeedback.append(feedback)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let encoded = try? encoder.encode(storedFeedback) {
            defaults.set(encoded, forKey: "action_feedback")
            Logger.info("Stored action feedback locally (\(storedFeedback.count) total)", category: .app)
        }
    }

    /// Loads all locally stored action feedback
    func loadLocalFeedback() -> [ActionFeedback] {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "action_feedback") else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return (try? decoder.decode([ActionFeedback].self, from: data)) ?? []
    }

    // MARK: - Analytics

    /// Generates a feedback summary for action suggestion analysis
    func generateFeedbackSummary() -> ActionFeedbackSummary {
        let feedback = loadLocalFeedback()

        var intentAccuracy: [String: (correct: Int, total: Int)] = [:]
        var commonMissedActions: [String: Int] = [:]
        var commonUnnecessaryActions: [String: Int] = [:]

        for item in feedback {
            // Track accuracy per intent
            let intent = item.intent
            var stats = intentAccuracy[intent] ?? (correct: 0, total: 0)
            stats.total += 1
            if item.isCorrect {
                stats.correct += 1
            }
            intentAccuracy[intent] = stats

            // Track missed actions
            if let missed = item.missedActions {
                for action in missed {
                    commonMissedActions[action, default: 0] += 1
                }
            }

            // Track unnecessary actions
            if let unnecessary = item.unnecessaryActions {
                for action in unnecessary {
                    commonUnnecessaryActions[action, default: 0] += 1
                }
            }
        }

        // Convert to encodable format
        let encodableIntentAccuracy = intentAccuracy.mapValues { stats in
            IntentAccuracyItem(correct: stats.correct, total: stats.total)
        }

        let encodableMissedActions = commonMissedActions
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ActionCountItem(action: $0.key, count: $0.value) }

        let encodableUnnecessaryActions = commonUnnecessaryActions
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ActionCountItem(action: $0.key, count: $0.value) }

        return ActionFeedbackSummary(
            totalReviewed: feedback.count,
            overallAccuracy: feedback.isEmpty ? 0 : Double(feedback.filter { $0.isCorrect }.count) / Double(feedback.count),
            intentAccuracy: encodableIntentAccuracy,
            topMissedActions: encodableMissedActions,
            topUnnecessaryActions: encodableUnnecessaryActions
        )
    }

    /// Exports feedback summary as JSON for analysis
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

struct ClassifiedEmailWithActionsResponse: Codable {
    let id: String
    let from: String
    let subject: String
    let snippet: String
    let timeAgo: String
    let intent: String
    let suggestedActions: [EmailActionResponse]
    let confidence: Double
}

struct EmailActionResponse: Codable {
    let actionId: String
    let displayName: String
    let actionType: String
    let isPrimary: Bool
    let priority: Int?
}

// Helper struct for intent accuracy encoding
struct IntentAccuracyItem: Codable {
    let correct: Int
    let total: Int
}

// Helper struct for action count encoding
struct ActionCountItem: Codable {
    let action: String
    let count: Int
}

struct ActionFeedbackSummary: Codable {
    let totalReviewed: Int
    let overallAccuracy: Double
    let intentAccuracy: [String: IntentAccuracyItem]
    let topMissedActions: [ActionCountItem]
    let topUnnecessaryActions: [ActionCountItem]
}
