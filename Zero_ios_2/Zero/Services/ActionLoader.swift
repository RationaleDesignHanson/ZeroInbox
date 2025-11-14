import Foundation

/**
 * ActionLoader
 * Loads action definitions from JSON configuration files
 *
 * Phase 3.1: JSON Action Configuration System
 *
 * Reads JSON files from Config/Actions/ directory
 * Parses and validates action definitions
 * Caches actions in memory for performance
 * Provides lookup API for ActionRegistry
 *
 * Usage:
 *   let loader = ActionLoader.shared
 *   if let action = loader.loadAction(id: "track_package") {
 *       // Use JSON-defined action
 *   }
 *
 * SETUP REQUIRED:
 * This file needs to be added to Xcode project manually:
 * 1. Open Zero.xcodeproj in Xcode
 * 2. Right-click Services folder → Add Files to "Zero"
 * 3. Select ActionLoader.swift
 * 4. Ensure "Zero" target is checked
 */
class ActionLoader {

    // MARK: - Singleton

    static let shared = ActionLoader()

    // MARK: - Properties

    /// Cached action definitions loaded from JSON
    private var actionCache: [String: JSONAction] = [:]

    /// Whether actions have been loaded
    private var isLoaded = false

    // MARK: - Initialization

    private init() {
        loadAllActions()
    }

    // MARK: - Public API

    /// Load a specific action by ID
    /// Returns nil if action not found in JSON files
    func loadAction(id: String) -> JSONAction? {
        if !isLoaded {
            loadAllActions()
        }
        return actionCache[id]
    }

    /// Get all loaded actions
    func getAllActions() -> [JSONAction] {
        if !isLoaded {
            loadAllActions()
        }
        return Array(actionCache.values)
    }

    /// Get actions for specific mode
    func getActions(for mode: String) -> [JSONAction] {
        if !isLoaded {
            loadAllActions()
        }
        return actionCache.values.filter { action in
            action.mode == mode || action.mode == "both"
        }
    }

    /// Reload actions from disk (for development/testing)
    func reload() {
        actionCache.removeAll()
        isLoaded = false
        loadAllActions()
    }

    // MARK: - Private Methods

    /// Load all action JSON files from Config/Actions/
    private func loadAllActions() {
        guard !isLoaded else { return }

        // Get path to Config/Actions directory
        guard let actionsPath = Bundle.main.path(forResource: "Config/Actions", ofType: nil) else {
            Logger.warning("Actions directory not found in bundle", category: .action)
            isLoaded = true
            return
        }

        // Get all JSON files in directory
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(atPath: actionsPath) else {
            Logger.warning("Could not read actions directory", category: .action)
            isLoaded = true
            return
        }

        // Filter for JSON files (exclude schema)
        let jsonFiles = files.filter { $0.hasSuffix(".json") && !$0.contains("schema") }

        Logger.info("Found \(jsonFiles.count) action JSON files", category: .action)

        // Load each file
        for filename in jsonFiles {
            let filePath = (actionsPath as NSString).appendingPathComponent(filename)
            loadActionsFromFile(path: filePath, filename: filename)
        }

        isLoaded = true
        Logger.info("Loaded \(actionCache.count) actions from JSON", category: .action)
    }

    /// Load actions from a single JSON file
    private func loadActionsFromFile(path: String, filename: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            Logger.warning("Could not read file: \(filename)", category: .action)
            return
        }

        do {
            let decoder = JSONDecoder()
            let actionFile = try decoder.decode(ActionJSONFile.self, from: data)

            // Validate schema version
            guard actionFile.schemaVersion == "1.0" else {
                Logger.error("Unsupported schema version in \(filename): \(actionFile.schemaVersion)", category: .action)
                return
            }

            // Cache actions
            for action in actionFile.actions {
                actionCache[action.actionId] = action
            }

            Logger.info("Loaded \(actionFile.actions.count) actions from \(filename)", category: .action)

        } catch {
            Logger.error("Failed to parse \(filename): \(error.localizedDescription)", category: .action)
        }
    }
}

// MARK: - Data Models

/// Root structure of action JSON files
struct ActionJSONFile: Codable {
    let schemaVersion: String
    let category: String?
    let description: String?
    let actions: [JSONAction]
}

/// JSON action definition
struct JSONAction: Codable {
    let actionId: String
    let displayName: String
    let description: String?
    let actionType: String  // "IN_APP" or "GO_TO"
    let mode: String        // "mail", "ads", or "both"
    let category: String?
    let icon: String?
    let color: String?
    let priority: Int
    let isPremium: Bool?
    let modalComponent: String?
    let analyticsEvent: String?
    let confirmation: JSONConfirmation?
    let undo: JSONUndoConfig?
    let availability: JSONAvailability?
    let context: JSONActionContext?
}

/// Confirmation configuration
struct JSONConfirmation: Codable {
    let type: String  // "none", "simple", "detailed"
    let message: String?
    let title: String?
    let confirmText: String?
    let cancelText: String?
}

/// Undo configuration
struct JSONUndoConfig: Codable {
    let toastMessage: String?
    let undoWindowSeconds: Int?
    let undoActionId: String?
    let countdownStyle: String?  // "progressBar", "circularRing", "numeric", "none"
}

/// Availability rules
struct JSONAvailability: Codable {
    let conditions: [JSONCondition]?
    let requiresPermissions: [String]?
}

/// Availability condition
struct JSONCondition: Codable {
    let field: String
    let operator_: String  // "equals", "notEquals", "contains", etc.
    let value: String?

    enum CodingKeys: String, CodingKey {
        case field
        case operator_ = "operator"
        case value
    }
}

/// Action context configuration
struct JSONActionContext: Codable {
    let requiredKeys: [String]?
    let optionalKeys: [String]?
    let fallbackBehavior: String?
}

// MARK: - JSON to ActionConfig Conversion

extension JSONAction {

    /// Convert JSON action to ActionConfig for ActionRegistry
    /// Maps JSON strings to Swift enums and handles type conversions
    func toActionConfig() -> ActionConfig? {
        // Parse action type
        guard let actionType = ZeroActionType(rawValue: self.actionType) else {
            Logger.error("Invalid actionType '\(self.actionType)' for action: \(actionId)", category: .action)
            return nil
        }

        // Parse mode
        guard let mode = ZeroMode(rawValue: self.mode) else {
            Logger.error("Invalid mode '\(self.mode)' for action: \(actionId)", category: .action)
            return nil
        }

        // Convert priority int to ActionPriority enum
        let actionPriority = mapPriorityToEnum(self.priority)

        // Parse fallback behavior
        let fallback = parseFallbackBehavior(context?.fallbackBehavior)

        // Parse required permission (based on isPremium flag)
        let permission: ActionPermission = (isPremium == true) ? .premium : .free

        // Parse confirmation requirement
        let confirmationReq = parseConfirmation()

        // Get analytics event (default to action_<actionId>)
        let analytics = analyticsEvent ?? "action_\(actionId)"

        return ActionConfig(
            actionId: actionId,
            displayName: displayName,
            actionType: actionType,
            mode: mode,
            modalComponent: modalComponent,
            requiredContextKeys: context?.requiredKeys ?? [],
            optionalContextKeys: context?.optionalKeys ?? [],
            fallbackBehavior: fallback,
            analyticsEvent: analytics,
            priority: actionPriority,
            description: description,
            featureFlag: nil,  // Not yet supported in JSON
            requiredPermission: permission,
            availability: .alwaysAvailable,  // TODO: Parse from JSON availability field
            confirmationRequirement: confirmationReq
        )
    }

    // MARK: - Helper Methods

    /// Map numeric priority to ActionPriority enum
    private func mapPriorityToEnum(_ value: Int) -> ActionPriority {
        switch value {
        case 95...100:
            return .critical
        case 90..<95:
            return .veryHigh
        case 85..<90:
            return .high
        case 80..<85:
            return .mediumHigh
        case 75..<80:
            return .medium
        case 70..<75:
            return .mediumLow
        case 65..<70:
            return .low
        default:
            return .veryLow
        }
    }

    /// Parse fallback behavior string
    private func parseFallbackBehavior(_ behavior: String?) -> ActionConfig.FallbackBehavior {
        guard let behavior = behavior else { return .showError }

        switch behavior.lowercased() {
        case "showerror", "show_error":
            return .showError
        case "showtoast", "show_toast":
            return .showToast
        case "openemailcomposer", "open_email_composer":
            return .openEmailComposer
        case "donothing", "do_nothing":
            return .doNothing
        default:
            Logger.warning("Unknown fallback behavior '\(behavior)', defaulting to showError", category: .action)
            return .showError
        }
    }

    /// Parse confirmation and undo configuration
    private func parseConfirmation() -> ConfirmationRequirement {
        // Check for undo configuration
        if let undo = self.undo {
            let seconds = undo.undoWindowSeconds ?? 5
            let countdown = parseCountdownStyle(undo.countdownStyle)
            let message = undo.toastMessage ?? "Action completed. Tap to undo."

            return .undoWithToast(
                toastMessage: message,
                undoWindowSeconds: seconds,
                countdownStyle: countdown
            )
        }

        // Check for confirmation requirement
        if let confirmation = self.confirmation {
            switch confirmation.type.lowercased() {
            case "none":
                return .none
            case "simple":
                let message = confirmation.message ?? "Are you sure?"
                return .simpleConfirmation(message: message)
            case "detailed":
                let message = confirmation.message ?? "Confirm action?"
                let confirm = confirmation.confirmText ?? "Confirm"
                let cancel = confirmation.cancelText ?? "Cancel"
                return .detailedConfirmation(
                    title: confirmation.title,
                    message: message,
                    confirmText: confirm,
                    cancelText: cancel
                )
            default:
                return .none
            }
        }

        return .none
    }

    /// Parse countdown style string
    private func parseCountdownStyle(_ style: String?) -> UndoCountdownStyle {
        guard let style = style else { return .progressBar }

        switch style.lowercased() {
        case "progressbar", "progress_bar":
            return .progressBar
        case "circularring", "circular_ring":
            return .circularRing
        case "numeric":
            return .numeric
        case "none":
            return .none
        default:
            Logger.warning("Unknown countdown style '\(style)', defaulting to progressBar", category: .action)
            return .progressBar
        }
    }
}
