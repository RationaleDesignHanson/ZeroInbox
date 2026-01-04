import Foundation
import SwiftUI

/// Destructive action configuration (Wave 2)
struct DestructiveActionConfig: Codable {
    let title: String
    let confirmationTitle: String?
    let confirmationMessage: String?
    let action: ButtonAction
    let analytics: AnalyticsConfig?
}

/// Permissions configuration (Wave 2)
struct PermissionsConfig: Codable {
    let required: [String]     // Required permissions (e.g., "calendar", "contacts")
    let optional: [String]     // Optional permissions
}

/// Loading states configuration (Wave 2)
struct LoadingStatesConfig: Codable {
    let submitting: String     // Message while submitting
    let success: String        // Success message
    let error: String          // Error message
}

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
struct ModalConfig: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: IconConfig?
    let sections: [ModalSection]
    let primaryButton: ButtonConfig
    let secondaryButton: ButtonConfig?
    let layout: ModalLayout

    // Wave 2 additions
    let tertiaryButton: ButtonConfig?
    let cancelButton: ButtonConfig?
    let destructiveAction: DestructiveActionConfig?
    let permissions: PermissionsConfig?
    let loadingStates: LoadingStatesConfig?

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
        layout: ModalLayout = .standard,
        tertiaryButton: ButtonConfig? = nil,
        cancelButton: ButtonConfig? = nil,
        destructiveAction: DestructiveActionConfig? = nil,
        permissions: PermissionsConfig? = nil,
        loadingStates: LoadingStatesConfig? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.sections = sections
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.layout = layout
        self.tertiaryButton = tertiaryButton
        self.cancelButton = cancelButton
        self.destructiveAction = destructiveAction
        self.permissions = permissions
        self.loadingStates = loadingStates
    }
}

// MARK: - Codable Conformance

extension ModalConfig: Codable {
    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, icon, sections, primaryButton, secondaryButton, layout
        case tertiaryButton, cancelButton, destructiveAction, permissions, loadingStates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        icon = try container.decodeIfPresent(IconConfig.self, forKey: .icon)
        sections = try container.decode([ModalSection].self, forKey: .sections)
        primaryButton = try container.decode(ButtonConfig.self, forKey: .primaryButton)
        secondaryButton = try container.decodeIfPresent(ButtonConfig.self, forKey: .secondaryButton)
        layout = try container.decodeIfPresent(ModalLayout.self, forKey: .layout) ?? .standard

        // Wave 2 additions
        tertiaryButton = try container.decodeIfPresent(ButtonConfig.self, forKey: .tertiaryButton)
        cancelButton = try container.decodeIfPresent(ButtonConfig.self, forKey: .cancelButton)
        destructiveAction = try container.decodeIfPresent(DestructiveActionConfig.self, forKey: .destructiveAction)
        permissions = try container.decodeIfPresent(PermissionsConfig.self, forKey: .permissions)
        loadingStates = try container.decodeIfPresent(LoadingStatesConfig.self, forKey: .loadingStates)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encode(sections, forKey: .sections)
        try container.encode(primaryButton, forKey: .primaryButton)
        try container.encodeIfPresent(secondaryButton, forKey: .secondaryButton)
        try container.encode(layout, forKey: .layout)

        // Wave 2 additions
        try container.encodeIfPresent(tertiaryButton, forKey: .tertiaryButton)
        try container.encodeIfPresent(cancelButton, forKey: .cancelButton)
        try container.encodeIfPresent(destructiveAction, forKey: .destructiveAction)
        try container.encodeIfPresent(permissions, forKey: .permissions)
        try container.encodeIfPresent(loadingStates, forKey: .loadingStates)
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

    // Wave 2 additions
    let collapsible: Bool?            // Section can be collapsed
    let collapsed: Bool?              // Initial collapsed state
    let visibilityCondition: VisibilityCondition?  // Conditional visibility

    enum SectionLayout: String, Codable {
        case vertical      // Stack fields vertically
        case horizontal    // Stack fields horizontally
        case grid          // 2-column grid
    }

    enum BackgroundStyle: String, Codable {
        case glass         // Glassmorphic background
        case card          // Card background
        case plain         // Plain background (Wave 2)
        case none          // No background
    }

    init(
        id: String,
        title: String? = nil,
        fields: [FieldConfig],
        layout: SectionLayout = .vertical,
        background: BackgroundStyle? = .glass,
        collapsible: Bool? = nil,
        collapsed: Bool? = nil,
        visibilityCondition: VisibilityCondition? = nil
    ) {
        self.id = id
        self.title = title
        self.fields = fields
        self.layout = layout
        self.background = background
        self.collapsible = collapsible
        self.collapsed = collapsed
        self.visibilityCondition = visibilityCondition
    }
}

// MARK: - Supporting Structs

/// Visibility condition for conditional field/section display
struct VisibilityCondition: Codable {
    let field: String              // Field ID to watch
    let equals: AnyCodableValue    // Value to match for visibility
}

/// Rich picker option with icon and description
struct PickerOption: Codable, Identifiable {
    let value: String
    let label: String
    let icon: String?              // SF Symbol name
    let description: String?        // Subtitle/helper text

    var id: String { value }
}

/// Type-erased codable value (supports String, Int, Bool, Double)
enum AnyCodableValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else {
            throw DecodingError.typeMismatch(
                AnyCodableValue.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    /// Get string representation
    var stringValue: String {
        switch self {
        case .string(let value): return value
        case .int(let value): return String(value)
        case .double(let value): return String(value)
        case .bool(let value): return String(value)
        case .null: return ""
        }
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

    // Wave 2 additions
    let helpText: String?                 // Helper text below field
    let visibilityCondition: VisibilityCondition?  // Conditional visibility
    let defaultValue: AnyCodableValue?    // Default value for field
    let maxLines: Int?                    // Max lines for textArea
    let characterLimit: Int?              // Character count limit
    let pickerOptions: [PickerOption]?   // Rich picker options with icons/descriptions
    let calculation: String?              // Formula for calculated fields (e.g., "{price} * {quantity}")

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

        // Wave 2 additions
        case multiSelect             // Multiple selection with checkboxes
        case searchField             // Search input with magnifying glass icon
        case stars                   // Star rating display (read-only, 1-5 stars)
        case textArea                // Multi-line text input (enhanced textInputMultiline)
        case calculated              // Calculated field based on formula
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
        validation: ValidationRule? = nil,
        helpText: String? = nil,
        visibilityCondition: VisibilityCondition? = nil,
        defaultValue: AnyCodableValue? = nil,
        maxLines: Int? = nil,
        characterLimit: Int? = nil,
        pickerOptions: [PickerOption]? = nil,
        calculation: String? = nil
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
        self.helpText = helpText
        self.visibilityCondition = visibilityCondition
        self.defaultValue = defaultValue
        self.maxLines = maxLines
        self.characterLimit = characterLimit
        self.pickerOptions = pickerOptions
        self.calculation = calculation
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
    let analytics: AnalyticsConfig?   // Wave 2: Analytics tracking

    enum ButtonStyle: String, Codable {
        case primary           // Gradient button (main action)
        case secondary         // Glass button (alternate action)
        case tertiary          // Tertiary button (Wave 2)
        case plain             // Plain text button (Wave 2)
        case destructive       // Red button (dangerous action)
        case link              // Text-only link button
    }

    init(title: String, style: ButtonStyle, action: ButtonAction, analytics: AnalyticsConfig? = nil) {
        self.title = title
        self.style = style
        self.action = action
        self.analytics = analytics
    }
}

/// Analytics configuration for button actions
struct AnalyticsConfig: Codable {
    let eventName: String
    let properties: [String: String]?  // Key-value pairs with placeholder support (e.g., "{ticketId}")
}

// MARK: - Button Actions

enum ButtonAction: Codable, Equatable {
    case openURL(contextKey: String)
    case copyToClipboard(contextKey: String)
    case submit(contextKey: String?)        // Wave 2: Submit form (optional service call via contextKey)
    case custom(contextKey: String)         // Wave 2: Custom action handler
    case share
    case dismiss

    // MARK: - Codable Conformance

    enum CodingKeys: String, CodingKey {
        case type
        case contextKey
        case serviceCall  // Legacy support
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
            // Wave 2: contextKey is optional for submit
            let key = try container.decodeIfPresent(String.self, forKey: .contextKey)
            self = .submit(contextKey: key)

        case "custom":
            // Wave 2: custom action with required contextKey
            let key = try container.decode(String.self, forKey: .contextKey)
            self = .custom(contextKey: key)

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

        case .submit(let key):
            try container.encode("submit", forKey: .type)
            try container.encodeIfPresent(key, forKey: .contextKey)

        case .custom(let key):
            try container.encode("custom", forKey: .type)
            try container.encode(key, forKey: .contextKey)

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
