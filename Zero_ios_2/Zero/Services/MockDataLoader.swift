import Foundation

/**
 * MockDataLoader
 * Loads EmailCard mock data from JSON fixtures
 * Replaces hardcoded mock data in DataGenerator.swift
 */

enum MockDataLoaderError: Error {
    case fileNotFound(String)
    case invalidJSON(String)
    case decodingFailed(String, Error)
    case categoryNotFound(String)
    case invalidSchema(String)

    var localizedDescription: String {
        switch self {
        case .fileNotFound(let path):
            return "Mock data file not found: \(path)"
        case .invalidJSON(let path):
            return "Invalid JSON in file: \(path)"
        case .decodingFailed(let path, let error):
            return "Failed to decode \(path): \(error.localizedDescription)"
        case .categoryNotFound(let category):
            return "Category not found: \(category)"
        case .invalidSchema(let reason):
            return "Invalid schema: \(reason)"
        }
    }
}

class MockDataLoader {

    // MARK: - Configuration

    private let fixturesPath: String
    private let bundle: Bundle

    /// Initialize with custom fixtures path (for testing)
    init(fixturesPath: String = "Tests/Fixtures/MockEmails", bundle: Bundle = .main) {
        self.fixturesPath = fixturesPath
        self.bundle = bundle
    }

    // MARK: - Public API

    /// Load a single email from JSON file
    /// - Parameter relativePath: Path relative to MockEmails/ (e.g., "newsletters/tech_weekly")
    /// - Returns: EmailCard instance
    func loadEmail(from relativePath: String) throws -> EmailCard {
        let fullPath = "\(fixturesPath)/\(relativePath).json"

        guard let url = bundle.url(forResource: fullPath, withExtension: nil) else {
            // Try alternative: load from file system if not in bundle
            let fileURL = URL(fileURLWithPath: fullPath)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw MockDataLoaderError.fileNotFound(fullPath)
            }
            return try loadEmailFromURL(fileURL)
        }

        return try loadEmailFromURL(url)
    }

    /// Load all emails from a category folder
    /// - Parameter category: Category name (e.g., "newsletters", "receipts")
    /// - Returns: Array of EmailCards
    func loadCategory(_ category: String) throws -> [EmailCard] {
        let categoryPath = "\(fixturesPath)/\(category)"

        guard let categoryURL = bundle.url(forResource: categoryPath, withExtension: nil) else {
            // Try file system
            let fileURL = URL(fileURLWithPath: categoryPath)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw MockDataLoaderError.categoryNotFound(category)
            }
            return try loadCategoryFromURL(fileURL)
        }

        return try loadCategoryFromURL(categoryURL)
    }

    /// Load all emails from all categories
    /// - Returns: Array of all EmailCards
    func loadAllEmails() throws -> [EmailCard] {
        let categories = [
            "newsletters", "receipts", "travel", "packages", "events",
            "bills", "subscriptions", "food", "education", "finance",
            "health", "professional", "social", "entertainment", "security"
        ]

        var allEmails: [EmailCard] = []

        for category in categories {
            do {
                let emails = try loadCategory(category)
                allEmails.append(contentsOf: emails)
            } catch MockDataLoaderError.categoryNotFound {
                // Category folder doesn't exist yet, skip
                continue
            } catch {
                Logger.warning("Failed to load category \(category): \(error)", category: .data)
                continue
            }
        }

        return allEmails
    }

    /// Validate a JSON file against schema
    /// - Parameter relativePath: Path to JSON file
    /// - Returns: true if valid, false otherwise
    func validate(relativePath: String) -> Bool {
        do {
            _ = try loadEmail(from: relativePath)
            return true
        } catch {
            Logger.error("Validation failed for \(relativePath): \(error)", category: .data)
            return false
        }
    }

    // MARK: - Private Helpers

    private func loadEmailFromURL(_ url: URL) throws -> EmailCard {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw MockDataLoaderError.fileNotFound(url.path)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let mockEmail = try decoder.decode(MockEmailCard.self, from: data)
            return mockEmail.toEmailCard()
        } catch {
            throw MockDataLoaderError.decodingFailed(url.path, error)
        }
    }

    private func loadCategoryFromURL(_ url: URL) throws -> [EmailCard] {
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) else {
            throw MockDataLoaderError.categoryNotFound(url.path)
        }

        var emails: [EmailCard] = []

        for case let fileURL as URL in enumerator where fileURL.pathExtension == "json" {
            do {
                let email = try loadEmailFromURL(fileURL)
                emails.append(email)
            } catch {
                Logger.warning("Failed to load \(fileURL.lastPathComponent): \(error)", category: .data)
                continue
            }
        }

        return emails
    }
}

// MARK: - MockEmailCard (Codable representation)

/// Codable representation of EmailCard for JSON serialization
private struct MockEmailCard: Codable {
    let id: String
    let type: String
    let state: String
    let priority: String
    let hpa: String
    let timeAgo: String
    let title: String
    let summary: String
    let aiGeneratedSummary: String?
    let body: String
    let htmlBody: String?
    let metaCTA: String
    let intent: String
    let intentConfidence: Double
    let suggestedActions: [MockEmailAction]
    let sender: MockSenderInfo
    let kid: String?
    let company: String?
    let store: String?
    let airline: String?
    let productImageUrl: String?
    let brandName: String?
    let originalPrice: Double?
    let salePrice: Double?
    let discount: String?
    let urgent: Bool
    let expiresIn: String?
    let requiresSignature: Bool?
    let paymentAmount: Double?
    let paymentDescription: String?
    let value: Double?
    let probability: Double?
    let score: Double?
    let keyLinks: [MockNewsletterLink]?
    let keyTopics: [String]?

    func toEmailCard() -> EmailCard {
        EmailCard(
            id: id,
            type: CardType(rawValue: type) ?? .mail,
            state: parseState(state),
            priority: parsePriority(priority),
            hpa: hpa,
            timeAgo: timeAgo,
            title: title,
            summary: summary,
            aiGeneratedSummary: aiGeneratedSummary,
            body: body,
            htmlBody: htmlBody,
            metaCTA: metaCTA,
            intent: intent,
            intentConfidence: intentConfidence,
            suggestedActions: suggestedActions.map { $0.toEmailAction() },
            sender: sender.toSenderInfo(),
            kid: kid,
            company: company,
            store: store,
            airline: airline,
            productImageUrl: productImageUrl,
            brandName: brandName,
            originalPrice: originalPrice,
            salePrice: salePrice,
            discount: discount,
            urgent: urgent,
            expiresIn: expiresIn,
            requiresSignature: requiresSignature,
            paymentAmount: paymentAmount,
            paymentDescription: paymentDescription,
            value: value,
            probability: probability,
            score: score,
            keyLinks: keyLinks?.map { $0.toNewsletterLink() },
            keyTopics: keyTopics
        )
    }

    private func parseState(_ state: String) -> CardState {
        switch state {
        case "unseen": return .unseen
        case "seen": return .seen
        case "archived": return .archived
        default: return .unseen
        }
    }

    private func parsePriority(_ priority: String) -> EmailPriority {
        switch priority {
        case "critical": return .critical
        case "veryHigh": return .veryHigh
        case "high": return .high
        case "mediumHigh": return .mediumHigh
        case "medium": return .medium
        case "low": return .low
        default: return .medium
        }
    }
}

private struct MockEmailAction: Codable {
    let actionId: String
    let displayName: String
    let actionType: String
    let isPrimary: Bool
    let priority: Int
    let context: [String: AnyCodable]?

    func toEmailAction() -> EmailAction {
        EmailAction(
            actionId: actionId,
            displayName: displayName,
            actionType: actionType == "GO_TO" ? .goTo : .inApp,
            isPrimary: isPrimary,
            priority: priority,
            context: context?.mapValues { $0.value }
        )
    }
}

private struct MockSenderInfo: Codable {
    let name: String
    let initial: String
    let email: String?

    func toSenderInfo() -> SenderInfo {
        SenderInfo(name: name, initial: initial, email: email)
    }
}

private struct MockNewsletterLink: Codable {
    let title: String
    let url: String
    let description: String

    func toNewsletterLink() -> EmailCard.NewsletterLink {
        EmailCard.NewsletterLink(title: title, url: url, description: description)
    }
}

// MARK: - AnyCodable Helper

/// Helper for decoding heterogeneous dictionaries
private struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported type"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Unsupported type"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}
