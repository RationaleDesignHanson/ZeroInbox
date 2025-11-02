import Foundation

/// Service for detecting and grouping email threads
class EmailThreadService {
    static let shared = EmailThreadService()

    private init() {}

    // MARK: - Thread Grouping

    /// Group emails by thread using conservative matching algorithm
    func groupEmailsByThread(_ emails: [EmailCard]) -> [SearchResult] {
        var threads: [String: [EmailCard]] = [:]

        // Group emails by thread ID
        for email in emails {
            let threadID = generateThreadID(for: email)
            threads[threadID, default: []].append(email)
        }

        // Convert to SearchResult objects
        return threads.map { threadID, messages in
            let sortedMessages = messages.sorted {
                // Sort by timestamp if available, otherwise by timeAgo
                if let time1 = $0.timestamp, let time2 = $1.timestamp {
                    return time1 > time2
                }
                // Fallback: parse timeAgo (rough estimation)
                return parseTimeAgo($0.timeAgo) > parseTimeAgo($1.timeAgo)
            }

            let latestEmail = sortedMessages.first!

            return SearchResult(
                threadId: threadID,
                messageCount: messages.count,
                latestEmail: convertToPreview(latestEmail),
                allMessages: sortedMessages.map { convertToMessagePreview($0) }
            )
        }
        .sorted {
            // Sort threads by latest message
            parseTimeAgo($0.latestEmail.timeAgo) > parseTimeAgo($1.latestEmail.timeAgo)
        }
    }

    // MARK: - Thread ID Generation

    /// Generate consistent thread ID for an email
    /// Uses subject matching + sender correlation
    func generateThreadID(for email: EmailCard) -> String {
        // Clean and normalize subject
        let cleanSubject = cleanSubject(email.title)

        // Get sender identifier
        let senderKey = email.sender?.email ?? email.sender?.name ?? "unknown"

        // Generate consistent hash
        let combined = "\(cleanSubject)-\(senderKey)".lowercased()
        return String(combined.hashValue)
    }

    /// Clean email subject by removing Re:, Fwd:, etc.
    func cleanSubject(_ subject: String) -> String {
        var cleaned = subject

        // Remove common prefixes (case-insensitive)
        let prefixes = ["Re: ", "RE: ", "Fwd: ", "FWD: ", "Fw: ", "FW: "]
        for prefix in prefixes {
            if cleaned.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
            }
        }

        // Trim whitespace and normalize
        return cleaned.trimmingCharacters(in: .whitespaces).lowercased()
    }

    // MARK: - Thread Detection

    /// Check if two emails belong to the same thread
    func areInSameThread(_ email1: EmailCard, _ email2: EmailCard) -> Bool {
        // Method 1: Same subject (cleaned)
        let subject1 = cleanSubject(email1.title)
        let subject2 = cleanSubject(email2.title)

        if subject1 == subject2 && !subject1.isEmpty {
            // Check sender/recipient overlap
            if hasSenderRecipientOverlap(email1, email2) {
                // Check timestamp proximity (within 30 days)
                if isWithinTimeProximity(email1, email2, days: 30) {
                    return true
                }
            }
        }

        return false
    }

    /// Check if emails have sender/recipient overlap
    func hasSenderRecipientOverlap(_ email1: EmailCard, _ email2: EmailCard) -> Bool {
        let sender1 = email1.sender?.email ?? email1.sender?.name ?? ""
        let sender2 = email2.sender?.email ?? email2.sender?.name ?? ""

        // Same sender or one is replying to the other
        return sender1 == sender2 || !sender1.isEmpty && !sender2.isEmpty
    }

    /// Check if emails are within time proximity
    func isWithinTimeProximity(_ email1: EmailCard, _ email2: EmailCard, days: Int) -> Bool {
        // If timestamps available, use them
        if let time1 = email1.timestamp, let time2 = email2.timestamp {
            let interval = abs(time1.timeIntervalSince(time2))
            let dayInterval = interval / (24 * 60 * 60)
            return dayInterval <= Double(days)
        }

        // Fallback: assume within proximity if both recent
        return true
    }

    // MARK: - Conversion Helpers

    /// Convert EmailCard to SearchEmailPreview
    private func convertToPreview(_ card: EmailCard) -> SearchEmailPreview {
        return SearchEmailPreview(
            id: card.id,
            type: card.type,
            state: card.state,
            priority: card.priority,
            hpa: card.hpa,
            timeAgo: card.timeAgo,
            title: card.title,
            summary: card.summary,
            sender: card.sender,
            threadLength: card.threadLength ?? 1
        )
    }

    /// Convert EmailCard to SearchMessagePreview
    private func convertToMessagePreview(_ card: EmailCard) -> SearchMessagePreview {
        return SearchMessagePreview(
            id: card.id,
            type: card.type,
            state: card.state,
            priority: card.priority,
            hpa: card.hpa,
            timeAgo: card.timeAgo,
            title: card.title,
            summary: card.summary,
            sender: card.sender,
            threadLength: card.threadLength ?? 1
        )
    }

    /// Parse timeAgo string to comparable value (rough estimation)
    private func parseTimeAgo(_ timeAgo: String) -> Int {
        let lowercased = timeAgo.lowercased()

        if lowercased.contains("just now") || lowercased.contains("now") {
            return 10000000
        } else if lowercased.contains("min") {
            if let value = Int(lowercased.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                return 1000000 - value
            }
            return 1000000
        } else if lowercased.contains("hour") {
            if let value = Int(lowercased.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                return 100000 - (value * 60)
            }
            return 100000
        } else if lowercased.contains("day") || lowercased.contains("yesterday") {
            if let value = Int(lowercased.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                return 10000 - (value * 1440)
            }
            return 10000
        } else if lowercased.contains("week") {
            if let value = Int(lowercased.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                return 1000 - (value * 10080)
            }
            return 1000
        } else if lowercased.contains("month") {
            if let value = Int(lowercased.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                return 100 - (value * 43200)
            }
            return 100
        }

        return 0
    }

    // MARK: - Thread Analysis

    /// Get thread statistics
    func getThreadStats(for thread: SearchResult) -> ThreadStats {
        let participants = Set(thread.allMessages.compactMap { $0.sender?.email })
        let timeSpan = calculateTimeSpan(for: thread.allMessages)
        let hasAttachments = thread.allMessages.contains { $0.threadLength > 0 } // Rough proxy

        return ThreadStats(
            messageCount: thread.messageCount,
            participantCount: participants.count,
            timeSpan: timeSpan,
            hasAttachments: hasAttachments,
            latestTimestamp: thread.latestEmail.timeAgo
        )
    }

    /// Calculate time span of thread
    private func calculateTimeSpan(for messages: [SearchMessagePreview]) -> String {
        guard messages.count > 1 else { return "Single message" }

        // Estimate based on timeAgo of first and last
        let first = messages.first?.timeAgo ?? ""
        let last = messages.last?.timeAgo ?? ""

        if first == last {
            return "Same time"
        }

        return "Over \(messages.count) messages"
    }
}

// MARK: - Supporting Types

struct ThreadStats {
    let messageCount: Int
    let participantCount: Int
    let timeSpan: String
    let hasAttachments: Bool
    let latestTimestamp: String
}

// MARK: - EmailCard Extension

extension EmailCard {
    /// Computed timestamp from timeAgo string (rough estimation)
    var timestamp: Date? {
        let lowercased = timeAgo.lowercased()
        let now = Date()

        if lowercased.contains("just now") || lowercased.contains("now") {
            return now
        } else if lowercased.contains("min") {
            if let value = Int(lowercased.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                return Calendar.current.date(byAdding: .minute, value: -value, to: now)
            }
        } else if lowercased.contains("hour") {
            if let value = Int(lowercased.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                return Calendar.current.date(byAdding: .hour, value: -value, to: now)
            }
        } else if lowercased.contains("day") || lowercased.contains("yesterday") {
            if let value = Int(lowercased.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                return Calendar.current.date(byAdding: .day, value: -value, to: now)
            }
            return Calendar.current.date(byAdding: .day, value: -1, to: now)
        } else if lowercased.contains("week") {
            if let value = Int(lowercased.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                return Calendar.current.date(byAdding: .day, value: -(value * 7), to: now)
            }
        }

        return nil
    }
}
