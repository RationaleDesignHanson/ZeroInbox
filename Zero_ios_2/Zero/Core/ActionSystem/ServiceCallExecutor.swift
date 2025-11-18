import Foundation

/**
 * ServiceCallExecutor - Executes service method calls from string descriptors
 *
 * Enables JSON configs to trigger Swift service methods
 * Format: "ServiceName.methodName"
 *
 * Example:
 *   try await ServiceCallExecutor.execute("UnsubscribeService.unsubscribe", context: context)
 *
 * Supported Services:
 * - UnsubscribeService
 * - CalendarService
 * - RemindersService
 * - ContactsService
 * - WalletService
 * - MessagesService
 */
actor ServiceCallExecutor {

    // MARK: - Public API

    /// Execute a service method call
    /// - Parameters:
    ///   - serviceCall: String in format "ServiceName.methodName"
    ///   - context: Action context with required parameters
    /// - Throws: ExecutorError if service/method not found or execution fails
    static func execute(_ serviceCall: String, context: ActionContext) async throws {
        Logger.info("Executing service call: \(serviceCall)", category: .action)

        let components = serviceCall.split(separator: ".").map(String.init)

        guard components.count == 2 else {
            throw ExecutorError.invalidFormat(serviceCall)
        }

        let serviceName = components[0]
        let methodName = components[1]

        switch serviceName {
        case "UnsubscribeService":
            try await executeUnsubscribeService(method: methodName, context: context)

        case "CalendarService":
            try await executeCalendarService(method: methodName, context: context)

        case "RemindersService":
            try await executeRemindersService(method: methodName, context: context)

        case "ContactsService":
            try await executeContactsService(method: methodName, context: context)

        case "WalletService":
            try await executeWalletService(method: methodName, context: context)

        case "MessagesService":
            try await executeMessagesService(method: methodName, context: context)

        case "AnalyticsService":
            try await executeAnalyticsService(method: methodName, context: context)

        default:
            throw ExecutorError.unknownService(serviceName)
        }

        Logger.info("✅ Service call completed: \(serviceCall)", category: .action)
    }

    // MARK: - Service Executors

    private static func executeUnsubscribeService(method: String, context: ActionContext) async throws {
        switch method {
        case "unsubscribe":
            guard let url = context.unsubscribeUrl else {
                throw ExecutorError.missingParameter("unsubscribeUrl")
            }

            try await UnsubscribeService.shared.unsubscribe(
                url: url,
                reason: context.optionalString(for: "reason"),
                customReason: context.optionalString(for: "customReason"),
                senderName: context.card.sender?.name
            )

        default:
            throw ExecutorError.unknownMethod(method)
        }
    }

    private static func executeCalendarService(method: String, context: ActionContext) async throws {
        switch method {
        case "addEvent":
            // Extract calendar event details from context
            let title = context.eventTitle ?? context.card.title
            let startDate = context.startDate ?? Date()
            let endDate = context.endDate ?? startDate.addingTimeInterval(3600)

            let eventData = CalendarService.CalendarEventData(
                title: title,
                startDate: startDate,
                endDate: endDate,
                location: context.location,
                notes: context.notes,
                url: context.meetingUrl.flatMap { URL(string: $0) },
                isAllDay: context.bool(for: "isAllDay", fallback: false)
            )

            try await CalendarService.shared.createEvent(eventData)

        case "addFromInvite":
            // Parse calendar invite from email
            guard let meetingTitle = context.optionalString(for: "meetingTitle"),
                  let _ = context.optionalString(for: "meetingTime") else {
                throw ExecutorError.missingParameter("meetingTitle or meetingTime")
            }

            // Create CalendarInvite model (if it exists in your codebase)
            // This is a simplified version - adjust based on your CalendarInvite model
            let startDate = context.date(for: "meetingTime") ?? Date()
            let endDate = startDate.addingTimeInterval(3600)

            let eventData = CalendarService.CalendarEventData(
                title: meetingTitle,
                startDate: startDate,
                endDate: endDate,
                location: context.location,
                notes: context.card.body,
                url: context.meetingUrl.flatMap { URL(string: $0) },
                isAllDay: false
            )

            try await CalendarService.shared.createEvent(eventData)

        default:
            throw ExecutorError.unknownMethod(method)
        }
    }

    private static func executeRemindersService(method: String, context: ActionContext) async throws {
        switch method {
        case "createReminder":
            let title = context.optionalString(for: "title") ?? context.card.title
            let notes = context.notes ?? context.card.summary
            let dueDate = context.date(for: "dueDate")
            let priority = context.int(for: "priority") ?? 0
            let url = context.url.flatMap { URL(string: $0) }

            return try await withCheckedThrowingContinuation { continuation in
                RemindersService.shared.createReminder(
                    title: title,
                    notes: notes,
                    dueDate: dueDate,
                    priority: priority,
                    url: url
                ) { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }

        case "createFromEmail":
            return try await withCheckedThrowingContinuation { continuation in
                RemindersService.shared.createReminderFromEmail(
                    card: context.card,
                    customTitle: context.optionalString(for: "customTitle"),
                    customDate: context.date(for: "customDate")
                ) { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }

        default:
            throw ExecutorError.unknownMethod(method)
        }
    }

    private static func executeContactsService(method: String, context: ActionContext) async throws {
        guard let sender = context.card.sender else {
            throw ExecutorError.missingParameter("sender")
        }

        switch method {
        case "saveContact":
            let phoneNumber = context.optionalString(for: "phoneNumber")
            let organization = context.optionalString(for: "organization") ?? context.card.company?.name
            let notes = context.notes

            _ = try await ContactsService.shared.saveContact(
                from: sender,
                phoneNumber: phoneNumber,
                organization: organization,
                notes: notes
            )

        default:
            throw ExecutorError.unknownMethod(method)
        }
    }

    private static func executeWalletService(method: String, context: ActionContext) async throws {
        switch method {
        case "addPass":
            guard let passUrl = context.url,
                  let _ = URL(string: passUrl) else {
                throw ExecutorError.missingParameter("passUrl")
            }

            // Note: WalletService requires presenting view controller
            // This will need to be handled differently in practice
            // For now, we'll throw an error indicating manual handling needed
            throw ExecutorError.requiresUIContext("WalletService.addPass requires presenting view controller")

        default:
            throw ExecutorError.unknownMethod(method)
        }
    }

    private static func executeMessagesService(method: String, context: ActionContext) async throws {
        switch method {
        case "sendMessage":
            guard let _ = context.array(for: "phoneNumbers") as? [String] else {
                throw ExecutorError.missingParameter("phoneNumbers")
            }

            let _ = context.optionalString(for: "messageBody") ?? ""

            // Note: MessagesService requires presenting view controller
            // This will need to be handled differently in practice
            throw ExecutorError.requiresUIContext("MessagesService.sendMessage requires presenting view controller")

        default:
            throw ExecutorError.unknownMethod(method)
        }
    }

    private static func executeAnalyticsService(method: String, context: ActionContext) async throws {
        switch method {
        case "log":
            let eventName = context.string(for: "eventName", fallback: "action_executed")
            var properties: [String: Any] = [
                "action_id": context.string(for: "actionId", fallback: "unknown"),
                "card_id": context.card.id,
                "card_type": context.card.type.rawValue
            ]

            // Merge additional properties from context
            if let additionalProps = context.dictionary(for: "properties") {
                properties.merge(additionalProps) { _, new in new }
            }

            AnalyticsService.shared.log(eventName, properties: properties)

        default:
            throw ExecutorError.unknownMethod(method)
        }
    }
}

// MARK: - Executor Errors

enum ExecutorError: LocalizedError {
    case invalidFormat(String)
    case unknownService(String)
    case unknownMethod(String)
    case missingParameter(String)
    case requiresUIContext(String)
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let call):
            return "Invalid service call format: '\(call)'. Expected 'ServiceName.methodName'"

        case .unknownService(let service):
            return "Unknown service: '\(service)'. Check that service is registered in ServiceCallExecutor."

        case .unknownMethod(let method):
            return "Unknown method: '\(method)'. Check that method exists on service."

        case .missingParameter(let param):
            return "Missing required parameter: '\(param)'. Ensure context includes this key."

        case .requiresUIContext(let message):
            return "Requires UI context: \(message). Use manual handling for this action."

        case .executionFailed(let message):
            return "Execution failed: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidFormat:
            return "Use format 'ServiceName.methodName'"

        case .unknownService:
            return "Check ServiceCallExecutor.swift for supported services"

        case .unknownMethod:
            return "Check service implementation for available methods"

        case .missingParameter(let param):
            return "Ensure ActionRegistry includes '\(param)' in requiredContextKeys"

        case .requiresUIContext:
            return "Handle this action manually with a custom modal"

        case .executionFailed:
            return "Check service logs for details"
        }
    }
}

// MARK: - Debugging

extension ServiceCallExecutor {
    /// Get list of supported services
    static var supportedServices: [String] {
        [
            "UnsubscribeService",
            "CalendarService",
            "RemindersService",
            "ContactsService",
            "WalletService",
            "MessagesService",
            "AnalyticsService"
        ]
    }

    /// Get list of supported methods for a service
    static func supportedMethods(for service: String) -> [String] {
        switch service {
        case "UnsubscribeService":
            return ["unsubscribe"]

        case "CalendarService":
            return ["addEvent", "addFromInvite"]

        case "RemindersService":
            return ["createReminder", "createFromEmail"]

        case "ContactsService":
            return ["saveContact"]

        case "WalletService":
            return ["addPass"]

        case "MessagesService":
            return ["sendMessage"]

        case "AnalyticsService":
            return ["log"]

        default:
            return []
        }
    }

    /// Validate service call format
    static func validate(_ serviceCall: String) -> ValidationResult {
        let components = serviceCall.split(separator: ".").map(String.init)

        guard components.count == 2 else {
            return .invalid(error: "Invalid format. Expected 'ServiceName.methodName'")
        }

        let serviceName = components[0]
        let methodName = components[1]

        guard supportedServices.contains(serviceName) else {
            return .invalid(error: "Unknown service: \(serviceName)")
        }

        let methods = supportedMethods(for: serviceName)
        guard methods.contains(methodName) else {
            return .invalid(error: "Unknown method '\(methodName)' for service '\(serviceName)'")
        }

        return .valid
    }

    enum ValidationResult {
        case valid
        case invalid(error: String)

        var isValid: Bool {
            if case .valid = self {
                return true
            }
            return false
        }
    }
}
