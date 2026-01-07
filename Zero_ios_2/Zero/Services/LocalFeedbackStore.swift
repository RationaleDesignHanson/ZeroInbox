import Foundation

/// Local storage for model tuning feedback
/// Stores feedback as JSONL (JSON Lines) for easy export and processing
/// No backend required - user can manually export and share feedback data
class LocalFeedbackStore {
    static let shared = LocalFeedbackStore()

    private let fileURL: URL

    private init() {
        // Store feedback in Documents directory so it's accessible via Files app
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsPath.appendingPathComponent("zero-feedback-export.jsonl")

        Logger.info("LocalFeedbackStore initialized: \(fileURL.path)", category: .app)
    }

    // MARK: - Save Feedback

    /// Saves feedback submission to local JSONL file
    /// Format: One JSON object per line (JSONL)
    func saveFeedback(_ submission: FeedbackSubmission) {
        do {
            // Encode to JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.sortedKeys] // Consistent ordering

            let data = try encoder.encode(submission)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                Logger.error("Failed to convert feedback to string", category: .app)
                return
            }

            // Append to JSONL file
            let line = jsonString + "\n"

            if FileManager.default.fileExists(atPath: fileURL.path) {
                // Append to existing file
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    defer { try? fileHandle.close() }
                    fileHandle.seekToEndOfFile()
                    if let lineData = line.data(using: .utf8) {
                        fileHandle.write(lineData)
                        Logger.info("Appended feedback to JSONL: \(submission.emailId)", category: .app)
                    }
                }
            } else {
                // Create new file
                try line.write(to: fileURL, atomically: true, encoding: .utf8)
                Logger.info("Created new feedback JSONL file with first entry", category: .app)
            }

        } catch {
            Logger.error("Failed to save feedback locally: \(error)", category: .app)
        }
    }

    // MARK: - Export

    /// Returns URL to feedback file for sharing
    /// Returns nil if no feedback exists
    func exportFeedback() -> URL? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            Logger.warning("No feedback file to export", category: .app)
            return nil
        }
        return fileURL
    }

    // MARK: - Statistics

    /// Returns count of feedback entries
    func getFeedbackCount() -> Int {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return 0
        }
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }
        return lines.count
    }

    /// Returns file size in bytes
    func getFileSize() -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path) else {
            return nil
        }
        return attributes[.size] as? Int64
    }

    // MARK: - Clear (for testing)

    /// Clears all feedback data
    /// Use only for testing or when user wants to reset
    func clearAllFeedback() {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                Logger.info("Cleared all feedback data", category: .app)
            }
        } catch {
            Logger.error("Failed to clear feedback: \(error)", category: .app)
        }
    }
}

// MARK: - Feedback Submission Model

/// Combined feedback submission for both category and actions
/// Optimized for OpenAI fine-tuning format
struct FeedbackSubmission: Codable {
    let emailId: String
    let timestamp: String // ISO8601 format

    // Email content (sanitized for PII)
    let subject: String
    let from: String
    let fromDomain: String?        // Email domain extracted (e.g., "gmail.com")
    let body: String?
    let snippet: String?

    // Privacy tracking
    let sanitizationApplied: Bool  // Whether PII sanitization was applied
    let sanitizationVersion: String // Version of sanitization algorithm used

    // Classification feedback
    let classifiedCategory: String // Original AI classification
    let correctedCategory: String  // Human correction
    let classificationConfidence: Double

    // Action feedback
    let suggestedActions: [String] // Original AI suggestions
    let missedActions: [String]?   // Actions AI should have suggested
    let unnecessaryActions: [String]? // Actions AI shouldn't have suggested

    // Optional metadata
    let notes: String?
    let intent: String?

    init(
        emailId: String,
        subject: String,
        from: String,
        fromDomain: String?,
        body: String?,
        snippet: String?,
        sanitizationApplied: Bool,
        sanitizationVersion: String,
        classifiedCategory: String,
        correctedCategory: String,
        classificationConfidence: Double,
        suggestedActions: [String],
        missedActions: [String]?,
        unnecessaryActions: [String]?,
        notes: String?,
        intent: String?
    ) {
        self.emailId = emailId
        self.timestamp = ISO8601DateFormatter().string(from: Date())
        self.subject = subject
        self.from = from
        self.fromDomain = fromDomain
        self.body = body
        self.snippet = snippet
        self.sanitizationApplied = sanitizationApplied
        self.sanitizationVersion = sanitizationVersion
        self.classifiedCategory = classifiedCategory
        self.correctedCategory = correctedCategory
        self.classificationConfidence = classificationConfidence
        self.suggestedActions = suggestedActions
        self.missedActions = missedActions
        self.unnecessaryActions = unnecessaryActions
        self.notes = notes
        self.intent = intent
    }
}
