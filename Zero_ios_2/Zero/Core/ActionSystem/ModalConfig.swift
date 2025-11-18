import Foundation
import SwiftUI

/**
 * ModalConfig - Complete configuration for a data-driven modal
 *
 * Enables JSON-defined modal UIs without writing Swift code
 * Used by GenericActionModal to render dynamic layouts
 *
 * Example JSON:
 * {
 *   "id": "track_package",
 *   "title": "Track Your Package",
 *   "icon": { "systemName": "shippingbox.fill", "size": "large" },
 *   "sections": [...],
 *   "primaryButton": { "title": "Track", "action": { "type": "openURL", ... } }
 * }
 */
struct ModalConfig: Codable, Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: IconConfig?
    let sections: [ModalSection]
    let primaryButton: ButtonConfig
    let secondaryButton: ButtonConfig?
    let layout: ModalLayout

    enum ModalLayout: String, Codable {
        case standard      // Icon, title, sections, button
        case form          // Title, form fields, submit
        case detail        // Header, detail sections, action buttons
        case timeline      // Header, timeline view, action
    }

    /// Default layout if not specified
    init(
        id: String,
        title: String,
        subtitle: String? = nil,
        icon: IconConfig? = nil,
        sections: [ModalSection],
        primaryButton: ButtonConfig,
        secondaryButton: ButtonConfig? = nil,
        layout: ModalLayout = .standard
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.sections = sections
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.layout = layout
    }
}

// MARK: - Icon Configuration

struct IconConfig: Codable {
    let systemName: String           // SF Symbol name
    let colorKey: String?            // Context key for dynamic color
    let staticColor: String?         // Static color name
    let size: IconSize

    enum IconSize: String, Codable {
        case small, medium, large

        var points: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 40
            case .large: return 64
            }
        }
    }

    init(
        systemName: String,
        colorKey: String? = nil,
        staticColor: String? = nil,
        size: IconSize = .medium
    ) {
        self.systemName = systemName
        self.colorKey = colorKey
        self.staticColor = staticColor
        self.size = size
    }
}

// MARK: - Section Configuration

struct ModalSection: Codable, Identifiable {
    let id: String
    let title: String?
    let fields: [FieldConfig]
    let layout: SectionLayout
    let background: BackgroundStyle?

    enum SectionLayout: String, Codable {
        case vertical      // Stack fields vertically
        case horizontal    // Stack fields horizontally
        case grid          // 2-column grid
    }

    enum BackgroundStyle: String, Codable {
        case glass         // Glassmorphic background
        case card          // Card background
        case none          // No background
    }

    init(
        id: String,
        title: String? = nil,
        fields: [FieldConfig],
        layout: SectionLayout = .vertical,
        background: BackgroundStyle? = .glass
    ) {
        self.id = id
        self.title = title
        self.fields = fields
        self.layout = layout
        self.background = background
    }
}

// MARK: - Field Configuration

struct FieldConfig: Codable, Identifiable {
    let id: String
    let label: String?
    let type: FieldType
    let contextKey: String           // Maps to ActionContext key
    let required: Bool
    let copyable: Bool
    let placeholder: String?
    let formatting: FormattingRule?
    let colorMapping: [String: String]?  // For statusBadge, etc.
    let validation: ValidationRule?      // Validation rules (Phase 2.1)

    enum FieldType: String, Codable {
        // Display-only fields
        case text                    // Simple text display
        case textMultiline           // Multi-line text
        case badge                   // Monospaced badge (tracking numbers, codes)
        case statusBadge             // Colored status badge
        case date                    // Date display
        case dateTime                // Date + time display
        case currency                // Currency display
        case link                    // Clickable link
        case button                  // Action button
        case image                   // Image display
        case divider                 // Visual separator

        // Interactive input fields (Phase 2)
        case textInput               // Editable text field
        case textInputMultiline      // Editable multi-line text
        case datePicker              // Date selection picker
        case timePicker              // Time selection picker
        case dateTimePicker          // Date + time selection picker
        case toggle                  // Boolean switch
        case picker                  // Dropdown selection (requires options)
        case slider                  // Numeric slider (requires min/max)
        case checkbox                // Single checkbox (boolean)

        // Advanced interactive fields (Phase 2.2)
        case segmentedControl        // iOS segmented control (multiple choice)
        case stepper                 // Numeric stepper (+/- buttons)
        case rating                  // Star rating input (1-5 stars)
    }

    init(
        id: String,
        label: String? = nil,
        type: FieldType,
        contextKey: String,
        required: Bool = false,
        copyable: Bool = false,
        placeholder: String? = nil,
        formatting: FormattingRule? = nil,
        colorMapping: [String: String]? = nil,
        validation: ValidationRule? = nil
    ) {
        self.id = id
        self.label = label
        self.type = type
        self.contextKey = contextKey
        self.required = required
        self.copyable = copyable
        self.placeholder = placeholder
        self.formatting = formatting
        self.colorMapping = colorMapping
        self.validation = validation
    }
}

// MARK: - Formatting Rules

struct FormattingRule: Codable {
    let type: FormattingType
    let options: [String: String]?

    enum FormattingType: String, Codable {
        case dateRelative      // "2 days from now"
        case dateShort         // "Mar 15"
        case dateFull          // "March 15, 2025"
        case dateTime          // "Mar 15, 2025 at 3:00 PM"
        case currency          // "$123.45"
        case percent           // "25%"
        case uppercase         // "HELLO"
        case lowercase         // "hello"
        case capitalized       // "Hello World"
        case phone             // "(123) 456-7890"
        case email             // "user@example.com"
    }

    init(type: FormattingType, options: [String: String]? = nil) {
        self.type = type
        self.options = options
    }
}

// MARK: - Validation Rules

struct ValidationRule: Codable {
    let type: ValidationType
    let minLength: Int?
    let maxLength: Int?
    let pattern: String?             // Regex pattern
    let errorMessage: String?        // Custom error message

    enum ValidationType: String, Codable {
        case email                   // Email format validation
        case phone                   // Phone number format
        case url                     // URL format validation
        case numeric                 // Numbers only
        case alphanumeric            // Letters and numbers only
        case minLength               // Minimum character length
        case maxLength               // Maximum character length
        case regex                   // Custom regex pattern
        case notEmpty                // Non-empty string
        case dateRange               // Date within range
        case numberRange             // Number within range
    }

    init(
        type: ValidationType,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        pattern: String? = nil,
        errorMessage: String? = nil
    ) {
        self.type = type
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
        self.errorMessage = errorMessage
    }

    /// Validate a string value
    func validate(_ value: String) -> ValidationResult {
        switch type {
        case .email:
            return validateEmail(value)
        case .phone:
            return validatePhone(value)
        case .url:
            return validateURL(value)
        case .numeric:
            return validateNumeric(value)
        case .alphanumeric:
            return validateAlphanumeric(value)
        case .minLength:
            return validateMinLength(value)
        case .maxLength:
            return validateMaxLength(value)
        case .regex:
            return validateRegex(value)
        case .notEmpty:
            return validateNotEmpty(value)
        case .dateRange, .numberRange:
            return .valid  // Handled separately for date/number types
        }
    }

    private func validateEmail(_ value: String) -> ValidationResult {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: value)
            ? .valid
            : .invalid(message: errorMessage ?? "Invalid email address")
    }

    private func validatePhone(_ value: String) -> ValidationResult {
        let phoneRegex = "^[\\d\\s\\-\\(\\)\\+]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        let digitsOnly = value.filter { $0.isNumber }
        return (predicate.evaluate(with: value) && digitsOnly.count >= 10)
            ? .valid
            : .invalid(message: errorMessage ?? "Invalid phone number")
    }

    private func validateURL(_ value: String) -> ValidationResult {
        guard let url = URL(string: value),
              url.scheme != nil,
              url.host != nil else {
            return .invalid(message: errorMessage ?? "Invalid URL")
        }
        return .valid
    }

    private func validateNumeric(_ value: String) -> ValidationResult {
        return value.allSatisfy({ $0.isNumber || $0 == "." || $0 == "-" })
            ? .valid
            : .invalid(message: errorMessage ?? "Must contain only numbers")
    }

    private func validateAlphanumeric(_ value: String) -> ValidationResult {
        return value.allSatisfy({ $0.isLetter || $0.isNumber })
            ? .valid
            : .invalid(message: errorMessage ?? "Must contain only letters and numbers")
    }

    private func validateMinLength(_ value: String) -> ValidationResult {
        guard let minLength = minLength else { return .valid }
        return value.count >= minLength
            ? .valid
            : .invalid(message: errorMessage ?? "Must be at least \(minLength) characters")
    }

    private func validateMaxLength(_ value: String) -> ValidationResult {
        guard let maxLength = maxLength else { return .valid }
        return value.count <= maxLength
            ? .valid
            : .invalid(message: errorMessage ?? "Must be no more than \(maxLength) characters")
    }

    private func validateRegex(_ value: String) -> ValidationResult {
        guard let pattern = pattern else { return .valid }
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: value)
            ? .valid
            : .invalid(message: errorMessage ?? "Invalid format")
    }

    private func validateNotEmpty(_ value: String) -> ValidationResult {
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? .valid
            : .invalid(message: errorMessage ?? "This field cannot be empty")
    }

    enum ValidationResult {
        case valid
        case invalid(message: String)

        var isValid: Bool {
            if case .valid = self {
                return true
            }
            return false
        }

        var errorMessage: String? {
            if case .invalid(let message) = self {
                return message
            }
            return nil
        }
    }
}

// MARK: - Button Configuration

struct ButtonConfig: Codable {
    let title: String
    let style: ButtonStyle
    let action: ButtonAction

    enum ButtonStyle: String, Codable {
        case primary           // Gradient button (main action)
        case secondary         // Glass button (alternate action)
        case destructive       // Red button (dangerous action)
        case link              // Text-only link button
    }

    init(title: String, style: ButtonStyle, action: ButtonAction) {
        self.title = title
        self.style = style
        self.action = action
    }
}

// MARK: - Button Actions

enum ButtonAction: Codable, Equatable {
    case openURL(contextKey: String)
    case copyToClipboard(contextKey: String)
    case submit(serviceCall: String)
    case share
    case dismiss

    // MARK: - Codable Conformance

    enum CodingKeys: String, CodingKey {
        case type
        case contextKey
        case serviceCall
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "openURL":
            let key = try container.decode(String.self, forKey: .contextKey)
            self = .openURL(contextKey: key)

        case "copyToClipboard":
            let key = try container.decode(String.self, forKey: .contextKey)
            self = .copyToClipboard(contextKey: key)

        case "submit":
            let call = try container.decode(String.self, forKey: .serviceCall)
            self = .submit(serviceCall: call)

        case "share":
            self = .share

        case "dismiss":
            self = .dismiss

        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown button action type: \(type)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .openURL(let key):
            try container.encode("openURL", forKey: .type)
            try container.encode(key, forKey: .contextKey)

        case .copyToClipboard(let key):
            try container.encode("copyToClipboard", forKey: .type)
            try container.encode(key, forKey: .contextKey)

        case .submit(let call):
            try container.encode("submit", forKey: .type)
            try container.encode(call, forKey: .serviceCall)

        case .share:
            try container.encode("share", forKey: .type)

        case .dismiss:
            try container.encode("dismiss", forKey: .type)
        }
    }
}

// MARK: - Validation

extension ModalConfig {
    /// Validate that config is well-formed
    func validate() -> ValidationResult {
        var errors: [String] = []

        // Check title
        if title.isEmpty {
            errors.append("Title cannot be empty")
        }

        // Check sections
        if sections.isEmpty {
            errors.append("Must have at least one section")
        }

        // Validate each section
        for section in sections {
            if section.fields.isEmpty {
                errors.append("Section '\(section.id)' has no fields")
            }

            // Validate each field
            for field in section.fields {
                if field.contextKey.isEmpty {
                    errors.append("Field '\(field.id)' has empty contextKey")
                }
            }
        }

        if errors.isEmpty {
            return .valid
        } else {
            return .invalid(errors: errors)
        }
    }

    enum ValidationResult {
        case valid
        case invalid(errors: [String])

        var isValid: Bool {
            if case .valid = self {
                return true
            }
            return false
        }
    }
}

// MARK: - Helper Extensions

extension ModalConfig {
    /// Load modal config from JSON file
    static func load(from filename: String, bundle: Bundle = .main) -> ModalConfig? {
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            Logger.error("Modal config file not found: \(filename).json", category: .action)
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(ModalConfig.self, from: data)

            // Validate before returning
            let validation = config.validate()
            if !validation.isValid {
                if case .invalid(let errors) = validation {
                    Logger.error("Modal config validation failed: \(errors.joined(separator: ", "))", category: .action)
                }
                return nil
            }

            return config
        } catch {
            Logger.error("Failed to load modal config: \(error.localizedDescription)", category: .action)
            return nil
        }
    }

    /// Create from JSON data
    static func from(data: Data) -> ModalConfig? {
        do {
            let config = try JSONDecoder().decode(ModalConfig.self, from: data)

            // Validate before returning
            let validation = config.validate()
            if !validation.isValid {
                if case .invalid(let errors) = validation {
                    Logger.error("Modal config validation failed: \(errors.joined(separator: ", "))", category: .action)
                }
                return nil
            }

            return config
        } catch {
            Logger.error("Failed to decode modal config: \(error.localizedDescription)", category: .action)
            return nil
        }
    }
}

// MARK: - Sample Configs (for testing)

extension ModalConfig {
    /// Sample config for testing
    static var sample: ModalConfig {
        ModalConfig(
            id: "sample",
            title: "Sample Modal",
            subtitle: "This is a sample modal configuration",
            icon: IconConfig(systemName: "star.fill", staticColor: "yellow", size: .large),
            sections: [
                ModalSection(
                    id: "info",
                    title: "Information",
                    fields: [
                        FieldConfig(
                            id: "name",
                            label: "Name",
                            type: .text,
                            contextKey: "name",
                            required: true
                        ),
                        FieldConfig(
                            id: "status",
                            label: "Status",
                            type: .statusBadge,
                            contextKey: "status"
                        )
                    ],
                    layout: .vertical,
                    background: .glass
                )
            ],
            primaryButton: ButtonConfig(
                title: "Continue",
                style: .primary,
                action: .dismiss
            ),
            secondaryButton: ButtonConfig(
                title: "Cancel",
                style: .secondary,
                action: .dismiss
            ),
            layout: .standard
        )
    }

    /// Fallback config when modal config fails to load
    static func fallback(actionId: String, card: EmailCard) -> ModalConfig {
        ModalConfig(
            id: actionId,
            title: card.title,
            subtitle: card.summary,
            icon: IconConfig(systemName: "doc.text.fill", staticColor: "blue", size: .medium),
            sections: [
                ModalSection(
                    id: "details",
                    title: "Details",
                    fields: [
                        FieldConfig(
                            id: "summary",
                            label: "Summary",
                            type: .textMultiline,
                            contextKey: "summary"
                        )
                    ],
                    layout: .vertical,
                    background: .card
                )
            ],
            primaryButton: ButtonConfig(
                title: "Close",
                style: .primary,
                action: .dismiss
            ),
            layout: .standard
        )
    }
}
