import Foundation

/// Service for managing admin feedback on suggested email actions
/// Feedback is used to improve action suggestion accuracy over time
class ActionFeedbackService {
    static let shared = ActionFeedbackService()

    // Admin endpoints deployed to Cloud Run
    private let baseURL = "https://emailshortform-classifier-514014482017.us-central1.run.app/api"

    // MARK: - Comprehensive Corpus

    /// Cached comprehensive corpus data (loaded once)
    private var cachedCorpus: [CorpusEmail]?

    /// Corpus email structure matching comprehensive-corpus.json
    struct CorpusEmail: Codable {
        let subject: String
        let from: String
        let body: String
        let intent: String
        let generated: Bool
    }

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

    // MARK: - Comprehensive Corpus Loading

    /// Loads comprehensive email corpus from JSON file
    /// Caches result for performance
    private func loadComprehensiveCorpus() -> [CorpusEmail] {
        // Return cached corpus if already loaded
        if let cached = cachedCorpus {
            return cached
        }

        // Load from bundle
        guard let url = Bundle.main.url(forResource: "comprehensive-corpus", withExtension: "json", subdirectory: "data") else {
            Logger.error("Could not find comprehensive-corpus.json in bundle", category: .app)
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let corpus = try decoder.decode([CorpusEmail].self, from: data)

            // Cache the loaded corpus
            cachedCorpus = corpus

            Logger.info("Loaded comprehensive corpus: \(corpus.count) emails, \(Set(corpus.map { $0.intent }).count) unique intents", category: .app)
            return corpus
        } catch {
            Logger.error("Failed to load comprehensive corpus: \(error)", category: .app)
            return []
        }
    }

    // MARK: - Intent to Action Mapping

    /// Maps email intent to appropriate suggested actions using ActionRegistry
    private func mapIntentToActions(_ intent: String) -> [EmailAction] {
        let components = intent.split(separator: ".")
        guard !components.isEmpty else { return [] }

        let category = String(components[0])
        let subcategory = components.count > 1 ? String(components[1]) : nil

        var actions: [EmailAction] = []

        // Map intents to action IDs based on hierarchical patterns
        switch category {
        case "e-commerce":
            switch subcategory {
            case "return":
                actions = [
                    EmailAction(actionId: "view_order", displayName: "View Order", actionType: .goTo, isPrimary: false, priority: 2),
                    EmailAction(actionId: "track_package", displayName: "Track Package", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "open_link", displayName: "View Return Label", actionType: .goTo, isPrimary: false, priority: 3)
                ]
            case "shipping":
                actions = [
                    EmailAction(actionId: "track_package", displayName: "Track Package", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "view_order", displayName: "View Order", actionType: .goTo, isPrimary: false, priority: 2),
                    EmailAction(actionId: "add_to_calendar", displayName: "Add Delivery Date", actionType: .inApp, isPrimary: false, priority: 3)
                ]
            case "refund", "cart":
                actions = [
                    EmailAction(actionId: "view_order", displayName: "View Order", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "open_link", displayName: "Complete Purchase", actionType: .goTo, isPrimary: false, priority: 2)
                ]
            default:
                actions = [
                    EmailAction(actionId: "shop_now", displayName: "Shop Now", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "view_order", displayName: "View Order", actionType: .goTo, isPrimary: false, priority: 2)
                ]
            }

        case "education":
            switch subcategory {
            case "permission":
                actions = [
                    EmailAction(actionId: "sign_form", displayName: "Sign Form", actionType: .inApp, isPrimary: true, priority: 1),
                    EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 2),
                    EmailAction(actionId: "view_document", displayName: "View Details", actionType: .inApp, isPrimary: false, priority: 3)
                ]
            case "assignment":
                actions = [
                    EmailAction(actionId: "view_assignment", displayName: "View Assignment", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "add_to_calendar", displayName: "Add Due Date", actionType: .inApp, isPrimary: false, priority: 2),
                    EmailAction(actionId: "set_reminder", displayName: "Set Reminder", actionType: .inApp, isPrimary: false, priority: 3)
                ]
            case "grade":
                actions = [
                    EmailAction(actionId: "check_grade", displayName: "Check Grade", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "view_lms", displayName: "View LMS", actionType: .goTo, isPrimary: false, priority: 2)
                ]
            default:
                actions = [
                    EmailAction(actionId: "view_lms", displayName: "View LMS", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "reply", displayName: "Reply", actionType: .inApp, isPrimary: false, priority: 2)
                ]
            }

        case "billing":
            actions = [
                EmailAction(actionId: "pay_invoice", displayName: "Pay Invoice", actionType: .goTo, isPrimary: true, priority: 1),
                EmailAction(actionId: "view_order", displayName: "View Invoice", actionType: .goTo, isPrimary: false, priority: 2),
                EmailAction(actionId: "add_to_calendar", displayName: "Add Due Date", actionType: .inApp, isPrimary: false, priority: 3)
            ]

        case "travel":
            switch subcategory {
            case "flight":
                actions = [
                    EmailAction(actionId: "check_in_flight", displayName: "Check In", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "view_itinerary", displayName: "View Itinerary", actionType: .goTo, isPrimary: false, priority: 2),
                    EmailAction(actionId: "add_to_wallet", displayName: "Add to Wallet", actionType: .inApp, isPrimary: false, priority: 3)
                ]
            case "hotel", "booking":
                actions = [
                    EmailAction(actionId: "view_reservation", displayName: "View Reservation", actionType: .inApp, isPrimary: true, priority: 1),
                    EmailAction(actionId: "get_directions", displayName: "Get Directions", actionType: .goTo, isPrimary: false, priority: 2),
                    EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 3)
                ]
            default:
                actions = [
                    EmailAction(actionId: "view_itinerary", displayName: "View Itinerary", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 2)
                ]
            }

        case "healthcare":
            switch subcategory {
            case "prescription":
                actions = [
                    EmailAction(actionId: "view_pickup_details", displayName: "View Pickup Details", actionType: .inApp, isPrimary: true, priority: 1),
                    EmailAction(actionId: "view_prescription", displayName: "View Prescription", actionType: .goTo, isPrimary: false, priority: 2),
                    EmailAction(actionId: "get_directions", displayName: "Get Directions", actionType: .goTo, isPrimary: false, priority: 3)
                ]
            case "appointment":
                actions = [
                    EmailAction(actionId: "check_in_appointment", displayName: "Check In", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 2),
                    EmailAction(actionId: "get_directions", displayName: "Get Directions", actionType: .goTo, isPrimary: false, priority: 3)
                ]
            case "results":
                actions = [
                    EmailAction(actionId: "view_results", displayName: "View Results", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "schedule_appointment", displayName: "Schedule Follow-up", actionType: .goTo, isPrimary: false, priority: 2)
                ]
            default:
                actions = [
                    EmailAction(actionId: "schedule_appointment", displayName: "Schedule Appointment", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "view_results", displayName: "View Portal", actionType: .goTo, isPrimary: false, priority: 2)
                ]
            }

        case "shopping":
            switch subcategory {
            case "scheduled-purchase":
                actions = [
                    EmailAction(actionId: "schedule_purchase", displayName: "Set Purchase Reminder", actionType: .inApp, isPrimary: true, priority: 1),
                    EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 2),
                    EmailAction(actionId: "open_link", displayName: "View Product", actionType: .goTo, isPrimary: false, priority: 3)
                ]
            default:
                actions = [
                    EmailAction(actionId: "shop_now", displayName: "Shop Now", actionType: .goTo, isPrimary: true, priority: 1),
                    EmailAction(actionId: "claim_deal", displayName: "Claim Deal", actionType: .inApp, isPrimary: false, priority: 2)
                ]
            }

        case "account":
            actions = [
                EmailAction(actionId: "open_link", displayName: "Review Activity", actionType: .goTo, isPrimary: true, priority: 1),
                EmailAction(actionId: "reply", displayName: "Contact Support", actionType: .inApp, isPrimary: false, priority: 2)
            ]

        case "civic":
            actions = [
                EmailAction(actionId: "view_tax_notice", displayName: "View Notice", actionType: .goTo, isPrimary: true, priority: 1),
                EmailAction(actionId: "add_to_calendar", displayName: "Add Deadline", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "set_reminder", displayName: "Set Reminder", actionType: .inApp, isPrimary: false, priority: 3)
            ]

        case "career":
            actions = [
                EmailAction(actionId: "reply", displayName: "Reply", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "open_link", displayName: "View Details", actionType: .goTo, isPrimary: false, priority: 3)
            ]

        case "dining":
            actions = [
                EmailAction(actionId: "track_package", displayName: "Track Delivery", actionType: .goTo, isPrimary: true, priority: 1),
                EmailAction(actionId: "write_review", displayName: "Write Review", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "contact_driver", displayName: "Contact Driver", actionType: .inApp, isPrimary: false, priority: 3)
            ]

        case "content":
            actions = [
                EmailAction(actionId: "view_newsletter_summary", displayName: "View Summary", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "unsubscribe", displayName: "Unsubscribe", actionType: .goTo, isPrimary: false, priority: 2)
            ]

        case "communication":
            actions = [
                EmailAction(actionId: "reply", displayName: "Reply", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "add_to_calendar", displayName: "Schedule Meeting", actionType: .inApp, isPrimary: false, priority: 2)
            ]

        default:
            // Generic fallback actions
            actions = [
                EmailAction(actionId: "view_details", displayName: "View Details", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "reply", displayName: "Reply", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "save_for_later", displayName: "Save for Later", actionType: .inApp, isPrimary: false, priority: 3)
            ]
        }

        // Validate actions exist in ActionRegistry
        let registry = ActionRegistry.shared
        let validActions = actions.filter { action in
            registry.getAction(action.actionId) != nil
        }

        if validActions.count < actions.count {
            let invalidIds = actions.filter { action in
                registry.getAction(action.actionId) == nil
            }.map { $0.actionId }
            Logger.warning("Some action IDs not found in ActionRegistry for intent \(intent): \(invalidIds)", category: .app)
        }

        return validActions
    }

    // MARK: - Generate Sample Email

    /// Generates a sample email with actions from comprehensive corpus
    /// Loads from 642 email corpus and maps intents to actions using ActionRegistry
    func generateSampleEmailWithActions() async throws -> ClassifiedEmailWithActions {
        // Load comprehensive corpus (cached after first load)
        let corpus = loadComprehensiveCorpus()

        // If corpus failed to load, provide helpful error
        guard !corpus.isEmpty else {
            throw NSError(domain: "ActionFeedbackService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Could not load email corpus. Ensure comprehensive-corpus.json is included in the app bundle under data/ directory."
            ])
        }

        // Randomly select an email from the corpus
        guard let selectedEmail = corpus.randomElement() else {
            throw NSError(domain: "ActionFeedbackService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to select random email from corpus"
            ])
        }

        // Map intent to suggested actions using ActionRegistry
        let suggestedActions = mapIntentToActions(selectedEmail.intent)

        // Generate realistic confidence score
        let confidence = Double.random(in: 0.60...0.95)

        // Generate random time ago
        let hoursAgo = Int.random(in: 1...48)
        let timeAgo: String
        if hoursAgo == 1 {
            timeAgo = "1 hour ago"
        } else if hoursAgo < 24 {
            timeAgo = "\(hoursAgo) hours ago"
        } else {
            let daysAgo = hoursAgo / 24
            timeAgo = daysAgo == 1 ? "1 day ago" : "\(daysAgo) days ago"
        }

        Logger.info("Generated sample email from corpus - Intent: \(selectedEmail.intent), Actions: \(suggestedActions.count)", category: .app)

        return ClassifiedEmailWithActions(
            id: UUID().uuidString,
            from: selectedEmail.from,
            subject: selectedEmail.subject,
            snippet: selectedEmail.body,
            timeAgo: timeAgo,
            intent: selectedEmail.intent,
            suggestedActions: suggestedActions,
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
