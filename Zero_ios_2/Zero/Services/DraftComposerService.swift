import Foundation

/// Service for generating AI-powered email draft replies
class DraftComposerService {
    static let shared = DraftComposerService()

    private let openAIAPIKey = AppEnvironment.openAIKey
    private let openAIEndpoint = "https://api.openai.com/v1/chat/completions"

    // MARK: - Draft Generation

    /// Generate a complete email draft based on context
    func generateDraft(
        emailContext: EmailDraftContext,
        tone: DraftTone = .professional
    ) async throws -> EmailDraft {
        let startTime = Date()

        Logger.info("Generating draft for: \(emailContext.subject), tone: \(tone.rawValue)", category: .email)

        // Build prompt for OpenAI
        let prompt = buildPrompt(context: emailContext, tone: tone)

        // Call OpenAI API
        let draftContent = try await callOpenAI(prompt: prompt)

        let latency = Date().timeIntervalSince(startTime)

        Logger.info("Draft generated in \(String(format: "%.2f", latency))s", category: .email)

        return EmailDraft(
            id: UUID().uuidString,
            content: draftContent,
            tone: tone,
            context: emailContext,
            generatedAt: Date(),
            model: "gpt-4",
            latency: latency,
            edited: false
        )
    }

    // MARK: - Prompt Building

    private func buildPrompt(context: EmailDraftContext, tone: DraftTone) -> String {
        var prompt = """
        You are an AI email assistant helping compose a reply to an email.

        EMAIL SUBJECT: \(context.subject)
        FROM: \(context.senderName)

        EMAIL CONTENT:
        \(context.emailBody)

        """

        // Add thread context if available
        if let thread = context.threadHistory, !thread.isEmpty {
            prompt += """

            PREVIOUS THREAD:
            \(thread.joined(separator: "\n---\n"))

            """
        }

        // Add user intent if specified
        if let intent = context.userIntent {
            prompt += """

            USER INTENT: \(intent)

            """
        }

        prompt += """

        TONE: \(tone.description)

        INSTRUCTIONS:
        - Write a complete, well-structured email reply
        - Match the \(tone.rawValue) tone
        - Be factually accurate - do not make up information
        - Keep it concise but complete (2-4 paragraphs max)
        - Do NOT include subject line, greeting, or signature
        - Start directly with the body content
        - Sound natural and human

        REPLY:
        """

        return prompt
    }

    // MARK: - OpenAI API Call

    private func callOpenAI(prompt: String) async throws -> String {
        guard !openAIAPIKey.isEmpty else {
            throw DraftComposerError.missingAPIKey
        }

        let url = URL(string: openAIEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are a helpful email composition assistant."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 500
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DraftComposerError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            Logger.error("OpenAI API error: \(httpResponse.statusCode)", category: .email)
            throw DraftComposerError.apiError(httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw DraftComposerError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Feedback Logging

    /// Log user feedback on draft (for model tuning)
    func logFeedback(draft: EmailDraft, action: FeedbackAction, editedContent: String? = nil) {
        Logger.info("Feedback logged: \(action.rawValue)", category: .analytics)

        let feedback = DraftFeedback(
            draftId: draft.id,
            action: action,
            originalContent: draft.content,
            editedContent: editedContent,
            tone: draft.tone,
            latency: draft.latency,
            timestamp: Date()
        )

        // Store feedback (in production, send to analytics service)
        saveFeedbackLocally(feedback)
    }

    private func saveFeedbackLocally(_ feedback: DraftFeedback) {
        let key = "draftFeedback"
        var feedbackLog: [DraftFeedback] = []

        if let data = UserDefaults.standard.data(forKey: key),
           let existing = try? JSONDecoder().decode([DraftFeedback].self, from: data) {
            feedbackLog = existing
        }

        feedbackLog.append(feedback)

        if let data = try? JSONEncoder().encode(feedbackLog) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Models

/// Context for generating an email draft
struct EmailDraftContext {
    let emailId: String
    let subject: String
    let senderName: String
    let emailBody: String
    let threadHistory: [String]?
    let userIntent: String?
}

/// Generated email draft
struct EmailDraft: Identifiable, Codable {
    let id: String
    let content: String
    let tone: DraftTone
    let context: EmailDraftContext
    let generatedAt: Date
    let model: String
    let latency: TimeInterval
    var edited: Bool
}

/// Tone options for draft generation
enum DraftTone: String, CaseIterable, Codable {
    case professional = "Professional"
    case friendly = "Friendly"
    case casual = "Casual"
    case formal = "Formal"

    var description: String {
        switch self {
        case .professional:
            return "Professional and polished, suitable for business communication"
        case .friendly:
            return "Warm and approachable while maintaining professionalism"
        case .casual:
            return "Relaxed and conversational"
        case .formal:
            return "Highly formal and respectful"
        }
    }

    var icon: String {
        switch self {
        case .professional: return "briefcase"
        case .friendly: return "hand.wave"
        case .casual: return "bubble.left.and.bubble.right"
        case .formal: return "text.badge.checkmark"
        }
    }
}

/// User feedback action on draft
enum FeedbackAction: String, Codable {
    case approved = "approved"
    case edited = "edited"
    case discarded = "discarded"
    case regenerated = "regenerated"
}

/// Feedback log for draft
struct DraftFeedback: Codable {
    let draftId: String
    let action: FeedbackAction
    let originalContent: String
    let editedContent: String?
    let tone: DraftTone
    let latency: TimeInterval
    let timestamp: Date
}

// MARK: - Errors

enum DraftComposerError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not configured"
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .apiError(let code):
            return "OpenAI API error: \(code)"
        }
    }
}

// Make EmailDraftContext Codable
extension EmailDraftContext: Codable {}
