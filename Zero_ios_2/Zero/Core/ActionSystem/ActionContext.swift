import Foundation

/**
 * ActionContext - Type-safe wrapper around action context dictionary
 *
 * Replaces unsafe dictionary access with typed accessors
 * Provides convenience methods for common context keys
 *
 * Usage:
 *   let context = ActionContext(card: emailCard, context: action.context)
 *   let trackingNumber = context.trackingNumber  // Optional<String>
 *   let carrier = context.string(for: "carrier", fallback: "Unknown")
 */
struct ActionContext {
    private let rawContext: [String: Any]
    let card: EmailCard

    // MARK: - Initialization

    init(card: EmailCard, context: [String: Any]?) {
        self.card = card
        self.rawContext = context ?? [:]
    }

    // MARK: - Type-Safe Accessors

    /// Get string value for key with fallback
    func string(for key: String, fallback: String = "") -> String {
        rawContext[key] as? String ?? fallback
    }

    /// Get optional string value for key
    func optionalString(for key: String) -> String? {
        rawContext[key] as? String
    }

    /// Get date value for key (parses ISO8601 strings)
    func date(for key: String) -> Date? {
        guard let dateString = rawContext[key] as? String else { return nil }

        // Try ISO8601 first
        if let date = ISO8601DateFormatter().date(from: dateString) {
            return date
        }

        // Try common formats
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd",
            "MM/dd/yyyy"
        ]

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }

    /// Get boolean value for key with fallback
    func bool(for key: String, fallback: Bool = false) -> Bool {
        rawContext[key] as? Bool ?? fallback
    }

    /// Get integer value for key
    func int(for key: String) -> Int? {
        rawContext[key] as? Int
    }

    /// Get double value for key
    func double(for key: String) -> Double? {
        rawContext[key] as? Double
    }

    /// Get array value for key
    func array(for key: String) -> [Any]? {
        rawContext[key] as? [Any]
    }

    /// Get dictionary value for key
    func dictionary(for key: String) -> [String: Any]? {
        rawContext[key] as? [String: Any]
    }

    // MARK: - Convenience Accessors (Common Context Keys)

    // Tracking & Shipping
    var trackingNumber: String? { optionalString(for: "trackingNumber") }
    var carrier: String? { optionalString(for: "carrier") }
    var trackingUrl: String? { optionalString(for: "trackingUrl") ?? optionalString(for: "url") }
    var estimatedDelivery: Date? { date(for: "estimatedDelivery") ?? date(for: "deliveryDate") }
    var deliveryStatus: String? { optionalString(for: "deliveryStatus") ?? optionalString(for: "status") }

    // Payments
    var invoiceId: String? { optionalString(for: "invoiceId") }
    var amount: String? { optionalString(for: "amount") ?? optionalString(for: "amountDue") }
    var merchant: String? { optionalString(for: "merchant") ?? card.company?.name }
    var dueDate: Date? { date(for: "dueDate") }
    var paymentLink: String? { optionalString(for: "paymentLink") ?? optionalString(for: "paymentUrl") }

    // Calendar & Events
    var eventTitle: String? { optionalString(for: "eventTitle") ?? optionalString(for: "title") }
    var startDate: Date? { date(for: "startDate") ?? date(for: "meetingTime") }
    var endDate: Date? { date(for: "endDate") }
    var location: String? { optionalString(for: "location") }
    var meetingUrl: String? { optionalString(for: "meetingUrl") ?? optionalString(for: "joinUrl") }

    // Flight & Travel
    var flightNumber: String? { optionalString(for: "flightNumber") }
    var airline: String? { optionalString(for: "airline") }
    var checkInUrl: String? { optionalString(for: "checkInUrl") }
    var departureTime: Date? { date(for: "departureTime") }
    var gate: String? { optionalString(for: "gate") }
    var seat: String? { optionalString(for: "seat") }

    // Shopping
    var productName: String? { optionalString(for: "productName") }
    var productUrl: String? { optionalString(for: "productUrl") ?? optionalString(for: "url") }
    var productImage: String? { optionalString(for: "productImage") }
    var price: Double? { double(for: "price") }
    var salePrice: Double? { double(for: "salePrice") }
    var discount: Int? { int(for: "discount") }

    // Subscriptions
    var unsubscribeUrl: String? { optionalString(for: "unsubscribeUrl") }
    var subscriptionName: String? { optionalString(for: "subscriptionName") }
    var billingPeriod: String? { optionalString(for: "billingPeriod") }

    // Forms & Documents
    var documentUrl: String? { optionalString(for: "documentUrl") ?? optionalString(for: "url") }
    var formUrl: String? { optionalString(for: "formUrl") }
    var deadline: Date? { date(for: "deadline") }

    // Reservations
    var reservationId: String? { optionalString(for: "reservationId") ?? optionalString(for: "confirmationNumber") }
    var reservationDate: Date? { date(for: "reservationDate") }
    var guestCount: Int? { int(for: "guestCount") ?? int(for: "guests") }

    // Generic
    var url: String? { optionalString(for: "url") }
    var contextDescription: String? { optionalString(for: "description") }
    var notes: String? { optionalString(for: "notes") }

    // MARK: - Raw Access (for debugging)

    /// Get raw context dictionary (use sparingly)
    var raw: [String: Any] {
        rawContext
    }

    /// Get all keys in context
    var keys: [String] {
        Array(rawContext.keys)
    }

    /// Check if key exists
    func has(_ key: String) -> Bool {
        rawContext[key] != nil
    }

    // MARK: - Validation

    /// Validate that required keys exist
    func validate(requiredKeys: [String]) -> ValidationResult {
        let missingKeys = requiredKeys.filter { !has($0) }

        if missingKeys.isEmpty {
            return .valid
        } else {
            return .invalid(missingKeys: missingKeys)
        }
    }

    enum ValidationResult {
        case valid
        case invalid(missingKeys: [String])

        var isValid: Bool {
            if case .valid = self {
                return true
            }
            return false
        }
    }
}

// MARK: - CustomStringConvertible

extension ActionContext: CustomStringConvertible {
    var description: String {
        "ActionContext(card: \(card.id), keys: \(keys.joined(separator: ", ")))"
    }
}

// MARK: - Debugging Extensions

extension ActionContext {
    /// Pretty-print context for debugging
    func debugPrint() {
        print("=== ActionContext Debug ===")
        print("Card ID: \(card.id)")
        print("Card Title: \(card.title)")
        print("\nContext Keys (\(keys.count)):")
        for key in keys.sorted() {
            let value = rawContext[key] ?? "nil"
            print("  \(key): \(value)")
        }
        print("===========================")
    }
}
