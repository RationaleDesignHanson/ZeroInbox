import Foundation

class ThreadingService {
    static let shared = ThreadingService()

    private init() {}

    // MARK: - Thread Detection

    /// Group emails into conversation threads
    func groupIntoThreads(_ emails: [EmailCard]) -> [[EmailCard]] {
        var threads: [[EmailCard]] = []
        var processed: Set<String> = []

        for email in emails {
            // Skip if already processed
            if processed.contains(email.id) {
                continue
            }

            // Find all related emails
            let thread = findThread(for: email, in: emails, processed: &processed)
            if !thread.isEmpty {
                threads.append(thread.sorted { $0.timestamp > $1.timestamp })
            }
        }

        return threads
    }

    /// Find all emails in the same thread
    private func findThread(for email: EmailCard, in emails: [EmailCard], processed: inout Set<String>) -> [EmailCard] {
        var thread: [EmailCard] = []
        var toProcess: [EmailCard] = [email]

        while !toProcess.isEmpty {
            let current = toProcess.removeFirst()

            // Skip if already processed
            if processed.contains(current.id) {
                continue
            }

            // Mark as processed
            processed.insert(current.id)
            thread.append(current)

            // Find related emails
            let related = emails.filter { candidate in
                !processed.contains(candidate.id) && areInSameThread(current, candidate)
            }

            toProcess.append(contentsOf: related)
        }

        return thread
    }

    /// Check if two emails belong to the same thread
    func areInSameThread(_ email1: EmailCard, _ email2: EmailCard) -> Bool {
        // Method 1: Same thread ID (if provided by email service)
        if let thread1 = email1.threadId, let thread2 = email2.threadId {
            return thread1 == thread2
        }

        // Method 2: Subject line matching (ignoring Re:, Fwd:, etc.)
        let subject1 = normalizeSubject(email1.title)
        let subject2 = normalizeSubject(email2.title)

        guard !subject1.isEmpty && !subject2.isEmpty else {
            return false
        }

        if subject1 == subject2 {
            // Check if they're from the same sender/recipient pair
            if hasSameSenderRecipientPair(email1, email2) {
                // Check if timestamps are within reasonable range (60 days)
                let timeInterval = abs(email1.timestamp.timeIntervalSince(email2.timestamp))
                return timeInterval < 60 * 24 * 60 * 60 // 60 days
            }
        }

        // Method 3: In-Reply-To or References headers (if available)
        if let replyTo1 = email1.inReplyTo, let messageId2 = email2.messageId {
            return replyTo1 == messageId2
        }

        if let replyTo2 = email2.inReplyTo, let messageId1 = email1.messageId {
            return replyTo2 == messageId1
        }

        return false
    }

    /// Normalize subject line for comparison
    private func normalizeSubject(_ subject: String) -> String {
        var normalized = subject.lowercased().trimmingCharacters(in: .whitespaces)

        // Remove common prefixes
        let prefixes = ["re:", "fw:", "fwd:", "aw:", "[external]", "[external email]"]
        for prefix in prefixes {
            if normalized.hasPrefix(prefix) {
                normalized = String(normalized.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        // Remove multiple spaces
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return normalized
    }

    /// Check if emails are between the same sender/recipient pair
    private func hasSameSenderRecipientPair(_ email1: EmailCard, _ email2: EmailCard) -> Bool {
        guard let sender1 = email1.sender?.email?.lowercased(),
              let sender2 = email2.sender?.email?.lowercased() else {
            return false
        }

        // Same sender
        if sender1 == sender2 {
            return true
        }

        // Bi-directional conversation (sender1 sent to sender2, sender2 replied to sender1)
        // This would require recipient info which we may not have
        // For now, just check same sender

        return false
    }

    // MARK: - Thread Metadata

    /// Get thread summary
    func getThreadSummary(_ thread: [EmailCard]) -> ThreadSummary {
        guard !thread.isEmpty else {
            return ThreadSummary(messageCount: 0, participants: [], latestTimestamp: Date(), hasUnread: false)
        }

        // Get all unique participants
        var participants: Set<String> = []
        for email in thread {
            if let sender = email.sender?.email {
                participants.insert(sender)
            }
        }

        // Get latest timestamp
        let latestTimestamp = thread.map { $0.timestamp }.max() ?? Date()

        // Check if any unread
        let hasUnread = thread.contains { $0.hasRead == false }

        return ThreadSummary(
            messageCount: thread.count,
            participants: Array(participants),
            latestTimestamp: latestTimestamp,
            hasUnread: hasUnread
        )
    }

    /// Get thread subject (most recent email title)
    func getThreadSubject(_ thread: [EmailCard]) -> String {
        guard let latest = thread.max(by: { $0.timestamp < $1.timestamp }) else {
            return ""
        }
        return normalizeSubject(latest.title)
    }
}

// MARK: - Thread Summary Model

struct ThreadSummary {
    let messageCount: Int
    let participants: [String]
    let latestTimestamp: Date
    let hasUnread: Bool
}
