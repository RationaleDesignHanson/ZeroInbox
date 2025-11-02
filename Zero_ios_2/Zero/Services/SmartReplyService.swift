import Foundation

/// Service for generating AI-powered smart replies using Gemini
/// Provides 2-3 short, contextually relevant reply suggestions
class SmartReplyService {
    static let shared = SmartReplyService()

    private let geminiAPIKey: String
    // Use v1 API with gemini-1.5-flash (v1beta doesn't support 1.5 models)
    private let baseURL = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent"

    private init() {
        // Load API key from Environment
        self.geminiAPIKey = AppEnvironment.geminiAPIKey
    }

    // MARK: - Public Methods

    /// Generate 2-3 smart reply suggestions for an email
    /// - Parameters:
    ///   - email: The email to reply to
    ///   - userTone: Optional user tone preference (e.g., "professional", "casual", "friendly")
    ///   - context: Optional additional context or prior conversation
    /// - Returns: Array of 2-3 short reply suggestions
    func generateSmartReplies(
        for email: EmailCard,
        userTone: String? = nil,
        context: String? = nil
    ) async throws -> [String] {
        Logger.info("Generating replies for: \(email.title)", category: .email)

        // Build prompt for Gemini
        let prompt = buildSmartReplyPrompt(email: email, userTone: userTone, context: context)

        // Call Gemini API
        let response = try await callGeminiAPI(prompt: prompt)

        // Parse replies from response
        let replies = parseReplies(from: response)

        Logger.info("Generated \(replies.count) replies", category: .email)
        return replies
    }

    /// Generate smart replies with user's communication style
    /// Analyzes recent sent emails to match tone and style
    func generatePersonalizedReplies(
        for email: EmailCard,
        recentSentEmails: [String] = []
    ) async throws -> [String] {
        Logger.info("Generating personalized replies", category: .email)

        // Build tone profile from recent emails
        let toneProfile = analyzeToneProfile(from: recentSentEmails)

        // Generate replies with personalized tone
        return try await generateSmartReplies(
            for: email,
            userTone: toneProfile
        )
    }

    // MARK: - Private Methods

    /// Build prompt for Gemini API to generate smart replies
    private func buildSmartReplyPrompt(
        email: EmailCard,
        userTone: String?,
        context: String?
    ) -> String {
        var prompt = """
        You are an AI assistant helping generate SHORT, NATURAL email replies.

        EMAIL TO REPLY TO:
        From: \(email.sender?.name ?? "Unknown")
        Subject: \(email.title)
        Body: \(email.body ?? email.summary)

        """

        // Add tone guidance
        if let tone = userTone {
            prompt += """

            USER'S COMMUNICATION STYLE: \(tone)
            Match this tone in your replies.

            """
        }

        // Add context if available
        if let additionalContext = context {
            prompt += """

            CONVERSATION CONTEXT:
            \(additionalContext)

            """
        }

        prompt += """

        TASK: Generate 3 DIFFERENT smart reply options:
        1. A quick affirmative/acknowledgment reply (1-2 sentences)
        2. A polite question/clarification reply (1-2 sentences)
        3. A brief action-oriented reply (1-2 sentences)

        REQUIREMENTS:
        - Each reply must be SHORT (1-2 sentences maximum)
        - Sound NATURAL and conversational
        - Be contextually appropriate to the email
        - Match the user's tone if specified
        - Include NO greeting/signoff (just the message)
        - Be DIFFERENT from each other (don't repeat ideas)

        FORMAT YOUR RESPONSE EXACTLY AS:
        REPLY1: <first reply text>
        REPLY2: <second reply text>
        REPLY3: <third reply text>

        Generate the replies now:
        """

        return prompt
    }

    /// Call Gemini API with prompt
    private func callGeminiAPI(prompt: String) async throws -> String {
        guard !geminiAPIKey.isEmpty else {
            throw SmartReplyError.missingAPIKey
        }

        let url = URL(string: "\(baseURL)?key=\(geminiAPIKey)")!

        // Build request body
        let requestBody: [String: Any] = [
            "contents": [[
                "parts": [[
                    "text": prompt
                ]]
            ]],
            "generationConfig": [
                "temperature": 0.7,  // Balanced creativity
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 300,  // Short replies
                "stopSequences": []
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SmartReplyError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.error("Gemini API error: \(errorText)", category: .email)
            throw SmartReplyError.apiError(statusCode: httpResponse.statusCode, message: errorText)
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw SmartReplyError.invalidResponse
        }

        return text
    }

    /// Parse replies from Gemini response text
    private func parseReplies(from responseText: String) -> [String] {
        var replies: [String] = []

        // Look for REPLY1:, REPLY2:, REPLY3: format
        let patterns = ["REPLY1:", "REPLY2:", "REPLY3:"]

        for (index, pattern) in patterns.enumerated() {
            if let range = responseText.range(of: pattern) {
                let startIndex = range.upperBound

                // Find end of this reply (next REPLY pattern or end of string)
                var endIndex = responseText.endIndex
                if index < patterns.count - 1 {
                    let nextPattern = patterns[index + 1]
                    if let nextRange = responseText.range(of: nextPattern) {
                        endIndex = nextRange.lowerBound
                    }
                }

                // Extract and clean reply text
                let replyText = String(responseText[startIndex..<endIndex])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\n\n", with: " ")
                    .replacingOccurrences(of: "\n", with: " ")

                if !replyText.isEmpty {
                    replies.append(replyText)
                }
            }
        }

        // Fallback: if parsing failed, try to split by newlines
        if replies.isEmpty {
            let lines = responseText.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !$0.contains("REPLY") }

            replies = Array(lines.prefix(3))
        }

        // Ensure we have at least 2 replies
        if replies.count < 2 {
            // Generate fallback replies
            replies.append("Thanks for reaching out. I'll get back to you soon.")
            if replies.count < 2 {
                replies.append("Could you provide more details about this?")
            }
        }

        return Array(replies.prefix(3))  // Return max 3 replies
    }

    /// Analyze tone profile from recent sent emails
    private func analyzeToneProfile(from recentEmails: [String]) -> String {
        // Simple tone analysis based on common patterns
        // In production, this could use Gemini to analyze tone

        guard !recentEmails.isEmpty else {
            return "professional and friendly"
        }

        let combinedText = recentEmails.joined(separator: " ").lowercased()

        var characteristics: [String] = []

        // Check for formality
        if combinedText.contains("sincerely") || combinedText.contains("regards") {
            characteristics.append("formal")
        } else if combinedText.contains("thanks") || combinedText.contains("cheers") {
            characteristics.append("casual")
        }

        // Check for friendliness
        if combinedText.contains("!") && combinedText.filter({ $0 == "!" }).count > 3 {
            characteristics.append("enthusiastic")
        }

        // Check for brevity
        let avgWordCount = recentEmails.map { $0.split(separator: " ").count }.reduce(0, +) / max(recentEmails.count, 1)
        if avgWordCount < 50 {
            characteristics.append("concise")
        }

        return characteristics.isEmpty ? "professional and friendly" : characteristics.joined(separator: ", ")
    }
}

// MARK: - Error Types

enum SmartReplyError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parsingError

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Gemini API key not configured"
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .apiError(let statusCode, let message):
            return "Gemini API error (\(statusCode)): \(message)"
        case .parsingError:
            return "Failed to parse smart replies"
        }
    }
}
