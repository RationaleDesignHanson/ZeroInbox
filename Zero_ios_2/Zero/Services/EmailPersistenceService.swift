import Foundation

/// Service for persisting email cards to local storage
/// Prevents loss of real emails when app is closed/reopened
class EmailPersistenceService {
    static let shared = EmailPersistenceService()

    private let fileManager = FileManager.default
    private let persistenceKey = "persisted_email_cards"
    private let timestampKey = "persisted_email_timestamp"
    private let expirationHours: TimeInterval = 24 // 24 hours

    private init() {}

    // MARK: - Persistence Directory

    /// Get or create persistence directory in app's documents folder
    private func getPersistenceDirectory() -> URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            Logger.error("Could not access documents directory", category: .app)
            return nil
        }

        let persistenceDirectory = documentsDirectory.appendingPathComponent("EmailCache", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: persistenceDirectory.path) {
            do {
                try fileManager.createDirectory(at: persistenceDirectory, withIntermediateDirectories: true)
                Logger.info("Created persistence directory at \(persistenceDirectory.path)", category: .app)
            } catch {
                Logger.error("Failed to create persistence directory: \(error.localizedDescription)", category: .app)
                return nil
            }
        }

        return persistenceDirectory
    }

    /// Get file URL for persisted emails
    private func getEmailsFileURL() -> URL? {
        return getPersistenceDirectory()?.appendingPathComponent("emails.json")
    }

    // MARK: - Save

    /// Save email cards to local storage
    func saveEmails(_ cards: [EmailCard]) {
        guard !cards.isEmpty else {
            Logger.warning("Attempted to save empty email array", category: .app)
            return
        }

        guard let fileURL = getEmailsFileURL() else {
            Logger.error("Could not get file URL for email persistence", category: .app)
            return
        }

        do {
            // Encode cards to JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(cards)

            // Write to file
            try data.write(to: fileURL, options: .atomic)

            // Save timestamp
            UserDefaults.standard.set(Date(), forKey: timestampKey)

            Logger.info("✅ Successfully persisted \(cards.count) emails to \(fileURL.lastPathComponent)", category: .app)
        } catch {
            Logger.error("Failed to persist emails: \(error.localizedDescription)", category: .app)
        }
    }

    // MARK: - Load

    /// Load email cards from local storage
    /// Returns nil if no persisted data, expired, or error
    func loadEmails() -> [EmailCard]? {
        // Check if data has expired
        if isDataExpired() {
            Logger.info("Persisted email data has expired (>24 hours old), clearing", category: .app)
            clearPersistedEmails()
            return nil
        }

        guard let fileURL = getEmailsFileURL() else {
            Logger.error("Could not get file URL for email loading", category: .app)
            return nil
        }

        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            Logger.info("No persisted email data found", category: .app)
            return nil
        }

        do {
            // Read data
            let data = try Data(contentsOf: fileURL)

            // Decode JSON
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let cards = try decoder.decode([EmailCard].self, from: data)

            Logger.info("✅ Successfully loaded \(cards.count) persisted emails", category: .app)
            return cards
        } catch {
            Logger.error("Failed to load persisted emails: \(error.localizedDescription)", category: .app)
            // Clear corrupted data
            clearPersistedEmails()
            return nil
        }
    }

    // MARK: - Expiration

    /// Check if persisted data has expired (older than 24 hours)
    private func isDataExpired() -> Bool {
        guard let timestamp = UserDefaults.standard.object(forKey: timestampKey) as? Date else {
            return true // No timestamp means expired
        }

        let age = Date().timeIntervalSince(timestamp)
        let expirationInterval = expirationHours * 3600 // Convert hours to seconds

        return age > expirationInterval
    }

    /// Get age of persisted data in hours
    func getDataAgeInHours() -> Double? {
        guard let timestamp = UserDefaults.standard.object(forKey: timestampKey) as? Date else {
            return nil
        }

        let age = Date().timeIntervalSince(timestamp)
        return age / 3600 // Convert seconds to hours
    }

    // MARK: - Clear

    /// Clear all persisted email data
    func clearPersistedEmails() {
        guard let fileURL = getEmailsFileURL() else { return }

        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
                Logger.info("Cleared persisted email data", category: .app)
            }

            // Clear timestamp
            UserDefaults.standard.removeObject(forKey: timestampKey)
        } catch {
            Logger.error("Failed to clear persisted emails: \(error.localizedDescription)", category: .app)
        }
    }

    // MARK: - Deduplication

    /// Merge new emails with persisted emails, deduplicating by ID
    /// Keeps newer cards when duplicates are found
    func mergeWithPersistedEmails(newCards: [EmailCard]) -> [EmailCard] {
        guard let persistedCards = loadEmails() else {
            return newCards
        }

        // Create dictionary of persisted cards by ID for quick lookup
        var emailsById = Dictionary(uniqueKeysWithValues: persistedCards.map { ($0.id, $0) })

        // Add/update with new cards (overwrites duplicates)
        for card in newCards {
            emailsById[card.id] = card
        }

        let mergedCards = Array(emailsById.values)
        Logger.info("Merged emails: \(persistedCards.count) persisted + \(newCards.count) new = \(mergedCards.count) total (deduplicated)", category: .app)

        return mergedCards
    }
}
