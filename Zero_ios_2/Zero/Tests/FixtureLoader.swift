import Foundation

/// Helper class to load test fixtures from JSON files
/// Loads fixtures from the backend classifier service fixtures directory
class FixtureLoader {

    /// Load a fixture by filename from the backend classifier fixtures directory
    /// - Parameter filename: Name of the fixture file (e.g., "shopping-amazon-order-confirmation.json")
    /// - Returns: Dictionary representation of the JSON fixture
    /// - Throws: Error if file not found or invalid JSON
    static func loadFixture(named filename: String) throws -> [String: Any] {
        // Path to backend fixtures directory
        let fixturesPath = "/Users/matthanson/Zer0_Inbox/backend/services/classifier/__tests__/fixtures"
        let filePath = "\(fixturesPath)/\(filename)"

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            throw FixtureLoaderError.fileNotFound(filename)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FixtureLoaderError.invalidJSON(filename)
        }

        return json
    }

    /// Load a fixture and decode it to a specific type
    /// - Parameters:
    ///   - filename: Name of the fixture file
    ///   - type: The Codable type to decode to
    /// - Returns: Decoded instance of the specified type
    /// - Throws: Error if file not found, invalid JSON, or decoding fails
    static func loadFixture<T: Decodable>(named filename: String, as type: T.Type) throws -> T {
        let fixturesPath = "/Users/matthanson/Zer0_Inbox/backend/services/classifier/__tests__/fixtures"
        let filePath = "\(fixturesPath)/\(filename)"

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            throw FixtureLoaderError.fileNotFound(filename)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw FixtureLoaderError.decodingFailed(filename, error)
        }
    }

    /// Load all shopping fixtures
    /// - Returns: Array of shopping fixture dictionaries
    static func loadAllShoppingFixtures() throws -> [[String: Any]] {
        let shoppingFixtures = [
            "shopping-amazon-order-confirmation.json",
            "shopping-amazon-shipped.json",
            "shopping-amazon-delivered.json",
            "shopping-target-order.json",
            "shopping-bestbuy-multi-item.json",
            "shopping-order-cancelled.json",
            "shopping-refund-issued.json"
        ]

        return try shoppingFixtures.map { try loadFixture(named: $0) }
    }

    /// Load all newsletter/marketing fixtures
    /// - Returns: Array of newsletter fixture dictionaries
    static func loadAllNewsletterFixtures() throws -> [[String: Any]] {
        let newsletterFixtures = [
            "newsletter-substack.json",
            "newsletter-techcrunch.json",
            "marketing-retail-promo.json",
            "marketing-product-recommendations.json"
        ]

        return try newsletterFixtures.map { try loadFixture(named: $0) }
    }

    /// Load all critical (protected) fixtures
    /// - Returns: Array of critical fixture dictionaries
    static func loadAllCriticalFixtures() throws -> [[String: Any]] {
        let criticalFixtures = [
            "critical-bank-alert.json",
            "critical-password-reset.json",
            "critical-medical-appointment.json",
            "critical-utility-bill.json",
            "critical-2fa-code.json"
        ]

        return try criticalFixtures.map { try loadFixture(named: $0) }
    }

    /// Extract email body text from fixture
    /// - Parameter fixture: Fixture dictionary
    /// - Returns: Email body text
    static func extractBodyText(from fixture: [String: Any]) -> String {
        if let body = fixture["body"] as? [String: Any],
           let text = body["text"] as? String {
            return text
        }
        return ""
    }

    /// Extract email subject from fixture
    /// - Parameter fixture: Fixture dictionary
    /// - Returns: Email subject
    static func extractSubject(from fixture: [String: Any]) -> String {
        return fixture["subject"] as? String ?? ""
    }

    /// Extract sender email from fixture
    /// - Parameter fixture: Fixture dictionary
    /// - Returns: Sender email address
    static func extractSenderEmail(from fixture: [String: Any]) -> String {
        if let from = fixture["from"] as? [String: Any],
           let email = from["email"] as? String {
            return email
        }
        if let from = fixture["from"] as? String {
            return from
        }
        return ""
    }

    /// Extract entities from fixture
    /// - Parameter fixture: Fixture dictionary
    /// - Returns: Entities dictionary
    static func extractEntities(from fixture: [String: Any]) -> [String: Any] {
        return fixture["entities"] as? [String: Any] ?? [:]
    }
}

// MARK: - Errors

enum FixtureLoaderError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidJSON(String)
    case decodingFailed(String, Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Fixture file not found: \(filename)"
        case .invalidJSON(let filename):
            return "Invalid JSON in fixture file: \(filename)"
        case .decodingFailed(let filename, let error):
            return "Failed to decode fixture \(filename): \(error.localizedDescription)"
        }
    }
}

// MARK: - Test Fixture Models

/// Model for email fixture structure
struct EmailFixture: Codable {
    let id: String
    let subject: String
    let from: EmailFrom
    let to: String
    let date: String
    let body: EmailBody
    let classification: EmailClassification?
    let entities: [String: AnyCodable]?
    let headers: [String: String]?

    struct EmailFrom: Codable {
        let name: String
        let email: String
    }

    struct EmailBody: Codable {
        let text: String
        let html: String
    }

    struct EmailClassification: Codable {
        let type: String
        let category: String?
        let intent: String?
        let merchant: String?
        let shouldNeverUnsubscribe: Bool?
        let reason: String?
    }
}

/// Type-erased wrapper for decoding heterogeneous JSON
struct AnyCodable: Codable {
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
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
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
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Unsupported type"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}
