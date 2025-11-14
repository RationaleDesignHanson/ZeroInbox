import Foundation
import SwiftUI

/**
 * ActionRegistry (v2.0)
 * Single source of truth for all user actions in Zero
 * Replaces scattered action definitions across ActionRouter, ModalRouter, ContextualActionService
 */

// MARK: - Zero Mode Definition

/// Zero's binary mode system (Mail vs Ads)
enum ZeroMode: String, Codable {
    case mail = "mail"
    case ads = "ads"
    case both = "both"  // Action works in any mode

    var displayName: String {
        switch self {
        case .mail: return "Mail"
        case .ads: return "Ads"
        case .both: return "Both"
        }
    }
}

// MARK: - Action Type Definition

/// How the action is executed
enum ZeroActionType: String, Codable {
    case goTo = "GO_TO"      // Opens external URL (Safari, web links)
    case inApp = "IN_APP"    // Opens modal within app
}

// MARK: - Confirmation & Undo Requirements

/// Countdown UI style for undo toast
enum UndoCountdownStyle {
    case progressBar        // Linear progress bar at bottom of toast
    case circularRing       // Circular progress ring around undo button
    case numeric            // Simple numeric countdown (10, 9, 8...)
    case none               // No visual countdown
}

/// Undo configuration for reversible actions
struct UndoConfig {
    let toastMessage: String
    let undoWindowSeconds: TimeInterval
    let undoActionId: String?  // Optional paired undo action
    let countdownStyle: UndoCountdownStyle  // Visual countdown indicator

    /// Default undo window (10 seconds for thoughtful decisions)
    static let defaultWindow: TimeInterval = 10.0

    init(
        toastMessage: String,
        undoWindowSeconds: TimeInterval = 10.0,
        undoActionId: String? = nil,
        countdownStyle: UndoCountdownStyle = .progressBar
    ) {
        self.toastMessage = toastMessage
        self.undoWindowSeconds = undoWindowSeconds
        self.undoActionId = undoActionId
        self.countdownStyle = countdownStyle
    }
}

/// Confirmation and undo requirement for high-stakes actions
/// Supports Raya/Hinge-style optimistic patterns with undo windows
enum ConfirmationRequirement {
    case none                                           // No confirmation or undo needed
    case simple(message: String)                        // Basic confirmation alert
    case detailed(title: String, message: String, confirmText: String, cancelText: String)  // Full confirmation dialog
    case undoable(config: UndoConfig)                  // Execute immediately, show toast with undo button (Raya/Hinge pattern)
    case confirmWithUndo(confirmation: String, undo: UndoConfig)  // Confirm first, then show undo toast

    var requiresConfirmation: Bool {
        switch self {
        case .none, .undoable:
            return false
        case .simple, .detailed, .confirmWithUndo:
            return true
        }
    }

    var supportsUndo: Bool {
        switch self {
        case .undoable, .confirmWithUndo:
            return true
        case .none, .simple, .detailed:
            return false
        }
    }

    var undoConfig: UndoConfig? {
        switch self {
        case .undoable(let config):
            return config
        case .confirmWithUndo(_, let undo):
            return undo
        case .none, .simple, .detailed:
            return nil
        }
    }
}

// MARK: - Action Configuration

/// Complete configuration for a single action
struct ActionConfig {
    let actionId: String
    let displayName: String
    let actionType: ZeroActionType
    let mode: ZeroMode
    let modalComponent: String?  // Modal name if IN_APP
    let requiredContextKeys: [String]  // Required context data (e.g., ["trackingNumber", "carrier"])
    let optionalContextKeys: [String]  // Optional context data
    let fallbackBehavior: FallbackBehavior
    let analyticsEvent: String
    let priority: ActionPriority  // Semantic priority level
    let description: String?

    // v2.1 - Enhanced Validation
    let featureFlag: String?  // Feature flag key for A/B testing
    let requiredPermission: ActionPermission  // Permission level required
    let availability: ActionAvailability  // Time/condition-based availability

    // v2.2 - Confirmation & Undo
    let confirmationRequirement: ConfirmationRequirement  // Pre-confirmation or post-execution undo

    enum FallbackBehavior: String {
        case showError = "show_error"
        case showToast = "show_toast"
        case openEmailComposer = "open_email_composer"
        case doNothing = "do_nothing"
    }

    /// Initialize with default values for v2.1, v2.2, and v2.3 fields
    init(
        actionId: String,
        displayName: String,
        actionType: ZeroActionType,
        mode: ZeroMode,
        modalComponent: String? = nil,
        requiredContextKeys: [String] = [],
        optionalContextKeys: [String] = [],
        fallbackBehavior: FallbackBehavior,
        analyticsEvent: String,
        priority: ActionPriority,
        description: String? = nil,
        featureFlag: String? = nil,
        requiredPermission: ActionPermission = .free,
        availability: ActionAvailability = .alwaysAvailable,
        confirmationRequirement: ConfirmationRequirement = .none
    ) {
        self.actionId = actionId
        self.displayName = displayName
        self.actionType = actionType
        self.mode = mode
        self.modalComponent = modalComponent
        self.requiredContextKeys = requiredContextKeys
        self.optionalContextKeys = optionalContextKeys
        self.fallbackBehavior = fallbackBehavior
        self.analyticsEvent = analyticsEvent
        self.priority = priority
        self.description = description
        self.featureFlag = featureFlag
        self.requiredPermission = requiredPermission
        self.availability = availability
        self.confirmationRequirement = confirmationRequirement
    }
}

// MARK: - Action Priority

/// Semantic priority levels for action importance
/// Higher priority actions appear first in UI, get better placement, and are emphasized
enum ActionPriority: Int, Codable, Comparable {
    case critical = 95      // Life-critical, legal, or high-stakes financial (court, payments, medical)
    case veryHigh = 90      // Time-sensitive or high-value actions (flight check-in, job offers, urgent tasks)
    case high = 85          // Important but not urgent (invoices, appointments, reservations)
    case mediumHigh = 80    // Useful actions with moderate impact (scheduling, document viewing)
    case medium = 75        // Standard actions with clear value (tasks, shopping, communication)
    case mediumLow = 70     // Helpful but not essential (reminders, notes, secondary actions)
    case low = 65           // Nice-to-have features (social, sharing, preferences)
    case veryLow = 60       // Utility actions, fallbacks, generic actions

    /// Raw priority value for sorting and comparison
    var value: Int { rawValue }

    /// Human-readable description
    var description: String {
        switch self {
        case .critical: return "Critical"
        case .veryHigh: return "Very High"
        case .high: return "High"
        case .mediumHigh: return "Medium-High"
        case .medium: return "Medium"
        case .mediumLow: return "Medium-Low"
        case .low: return "Low"
        case .veryLow: return "Very Low"
        }
    }

    static func < (lhs: ActionPriority, rhs: ActionPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Action Permission

/// Permission level required to use an action
enum ActionPermission: String, Codable {
    case free = "free"              // Available to all users
    case premium = "premium"        // Requires premium subscription
    case beta = "beta"              // Beta testers only
    case admin = "admin"            // Admin/developer only
}

// MARK: - Action Availability

/// Time/condition-based availability rules
enum ActionAvailability {
    case alwaysAvailable
    case timeWindow(start: Int, end: Int)  // Available between hours (24h format)
    case afterDate(Date)                    // Available after specific date
    case beforeDate(Date)                   // Available until specific date
    case custom((UserContext) -> Bool)      // Custom availability function

    /// Check if action is currently available
    func isAvailable(userContext: UserContext) -> Bool {
        switch self {
        case .alwaysAvailable:
            return true

        case .timeWindow(let start, let end):
            let hour = Calendar.current.component(.hour, from: Date())
            if start < end {
                return hour >= start && hour < end
            } else {
                // Handle wrap-around (e.g., 22:00 to 06:00)
                return hour >= start || hour < end
            }

        case .afterDate(let date):
            return Date() >= date

        case .beforeDate(let date):
            return Date() <= date

        case .custom(let checkFunction):
            return checkFunction(userContext)
        }
    }
}

// MARK: - User Context

/// User context for permission and availability checking
struct UserContext {
    let isPremium: Bool
    let isBeta: Bool
    let isAdmin: Bool
    let userId: String?
    let featureFlags: [String: Bool]  // Feature flag overrides
    let customData: [String: Any]     // Additional context data

    /// Default free user context
    static let defaultUser = UserContext(
        isPremium: false,
        isBeta: false,
        isAdmin: false,
        userId: nil,
        featureFlags: [:],
        customData: [:]
    )

    /// Check if user has required permission
    func hasPermission(_ permission: ActionPermission) -> Bool {
        switch permission {
        case .free:
            return true
        case .premium:
            return isPremium
        case .beta:
            return isBeta || isAdmin
        case .admin:
            return isAdmin
        }
    }

    /// Check if feature flag is enabled
    func isFeatureEnabled(_ flagKey: String) -> Bool {
        return featureFlags[flagKey] ?? false
    }
}

// MARK: - Action Registry

/// Centralized registry of all actions
class ActionRegistry {
    static let shared = ActionRegistry()

    private init() {}

    // MARK: - Registry Data

    /// All registered actions (actionId -> ActionConfig)
    private(set) lazy var registry: [String: ActionConfig] = {
        var actions: [String: ActionConfig] = [:]

        // Register all actions
        allActions.forEach { action in
            actions[action.actionId] = action
        }

        return actions
    }()

    // MARK: - High-Fidelity Actions (Premium Modals)

    private var highFidelityActions: [ActionConfig] {
        [
            // Track Package - High-fidelity modal with carrier info, tracking timeline (PREMIUM)
            ActionConfig(
                actionId: "track_package",
                displayName: "Track Package",
                actionType: .inApp,
                mode: .both,
                modalComponent: "TrackPackageModal",
                requiredContextKeys: ["trackingNumber", "carrier"],
                optionalContextKeys: ["url", "expectedDelivery", "currentStatus"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_track_package",
                priority: .veryHigh,
                description: "Track package delivery status with carrier details",
                requiredPermission: .premium
            ),

            // Pay Invoice - High-fidelity modal with payment amount, merchant info (PREMIUM)
            ActionConfig(
                actionId: "pay_invoice",
                displayName: "Pay Invoice",
                actionType: .inApp,
                mode: .both,
                modalComponent: "PayInvoiceModal",
                requiredContextKeys: ["invoiceId", "amount", "merchant"],
                optionalContextKeys: ["paymentLink", "dueDate", "description"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_pay_invoice",
                priority: .critical,
                description: "Pay invoice with amount and merchant details",
                requiredPermission: .premium,
                confirmationRequirement: .confirmWithUndo(
                    confirmation: "Confirm payment to {merchant} for ${amount}?",
                    undo: UndoConfig(toastMessage: "Payment sent. Tap to undo.")
                )
            ),

            // Check In Flight - High-fidelity modal with flight details (PREMIUM)
            ActionConfig(
                actionId: "check_in_flight",
                displayName: "Check In",
                actionType: .inApp,
                mode: .both,
                modalComponent: "CheckInFlightModal",
                requiredContextKeys: ["flightNumber", "airline"],
                optionalContextKeys: ["checkInUrl", "departureTime", "gate", "seat"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_check_in_flight",
                priority: .critical,
                description: "Check in for flight with airline details",
                requiredPermission: .premium
            ),

            // Write Review - High-fidelity modal with product info
            ActionConfig(
                actionId: "write_review",
                displayName: "Write Review",
                actionType: .inApp,
                mode: .both,
                modalComponent: "WriteReviewModal",
                requiredContextKeys: ["productName"],
                optionalContextKeys: ["reviewLink", "orderNumber", "productImage"],
                fallbackBehavior: .openEmailComposer,
                analyticsEvent: "action_write_review",
                priority: .mediumLow,
                description: "Write product review"
            ),

            // Contact Driver - High-fidelity modal with driver contact info
            ActionConfig(
                actionId: "contact_driver",
                displayName: "Contact Driver",
                actionType: .inApp,
                mode: .both,
                modalComponent: "ContactDriverModal",
                requiredContextKeys: [],
                optionalContextKeys: ["driverName", "driverPhone", "vehicleInfo", "eta"],
                fallbackBehavior: .openEmailComposer,
                analyticsEvent: "action_contact_driver",
                priority: .high,
                description: "Contact delivery driver"
            ),

            // View Pickup Details - High-fidelity modal with pharmacy/prescription info
            ActionConfig(
                actionId: "view_pickup_details",
                displayName: "View Pickup Details",
                actionType: .inApp,
                mode: .both,
                modalComponent: "PickupDetailsModal",
                requiredContextKeys: ["pharmacy"],
                optionalContextKeys: ["rxNumber", "address", "phone", "hours"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_pickup_details",
                priority: .mediumHigh,
                description: "View prescription pickup details"
            ),
        ]
    }

    // MARK: - Mail Mode Actions

    private var mailModeActions: [ActionConfig] {
        [
            // Sign Form (PREMIUM)
            ActionConfig(
                actionId: "sign_form",
                displayName: "Sign Form",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "SignFormModal",
                requiredContextKeys: [],
                optionalContextKeys: ["formUrl", "documentName"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_sign_form",
                priority: .critical,
                description: "Digitally sign form or document",
                requiredPermission: .premium
            ),

            // Quick Reply
            ActionConfig(
                actionId: "quick_reply",
                displayName: "Quick Reply",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "QuickReplyModal",
                requiredContextKeys: ["recipientEmail", "subject"],
                optionalContextKeys: ["body", "template"],
                fallbackBehavior: .openEmailComposer,
                analyticsEvent: "action_quick_reply",
                priority: .high,
                description: "Send quick reply to email"
            ),

            // Add to Calendar
            ActionConfig(
                actionId: "add_to_calendar",
                displayName: "Add to Calendar",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "AddToCalendarModal",
                requiredContextKeys: [],
                optionalContextKeys: ["eventTitle", "eventDate", "eventTime", "location"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_add_to_calendar",
                priority: .mediumHigh,
                description: "Add event to iOS Calendar"
            ),

            // Schedule Meeting
            ActionConfig(
                actionId: "schedule_meeting",
                displayName: "Schedule Meeting",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "ScheduleMeetingModal",
                requiredContextKeys: [],
                optionalContextKeys: ["meetingTitle", "attendees", "duration"],
                fallbackBehavior: .openEmailComposer,
                analyticsEvent: "action_schedule_meeting",
                priority: .medium,
                description: "Schedule meeting with attendees"
            ),

            // Add Reminder
            ActionConfig(
                actionId: "add_reminder",
                displayName: "Add Reminder",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "AddReminderModal",
                requiredContextKeys: [],
                optionalContextKeys: ["reminderTitle", "dueDate", "notes"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_add_reminder",
                priority: .mediumLow,
                description: "Add reminder to iOS Reminders"
            ),

            // Set Reminder (generic)
            ActionConfig(
                actionId: "set_reminder",
                displayName: "Remind me on {saleDateShort}",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "AddReminderModal",
                requiredContextKeys: [],
                optionalContextKeys: ["dueDate", "reminderText"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_set_reminder",
                priority: .mediumLow,
                description: "Set generic reminder"
            ),

            // View Document
            ActionConfig(
                actionId: "view_document",
                displayName: "View Document",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "DocumentViewerModal",
                requiredContextKeys: [],
                optionalContextKeys: ["documentUrl", "documentName"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_document",
                priority: .medium,
                description: "View attached document"
            ),

            // View Spreadsheet
            ActionConfig(
                actionId: "view_spreadsheet",
                displayName: "View Spreadsheet",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "SpreadsheetViewerModal",
                requiredContextKeys: [],
                optionalContextKeys: ["spreadsheetUrl", "sheetName"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_spreadsheet",
                priority: .mediumLow,
                description: "View spreadsheet or budget document"
            ),

            // Acknowledge
            ActionConfig(
                actionId: "acknowledge",
                displayName: "Acknowledge",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "QuickReplyModal",
                requiredContextKeys: ["recipientEmail", "subject"],
                optionalContextKeys: [],
                fallbackBehavior: .openEmailComposer,
                analyticsEvent: "action_acknowledge",
                priority: .low,
                description: "Send acknowledgment reply"
            ),

            // Reply
            ActionConfig(
                actionId: "reply",
                displayName: "Reply",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "QuickReplyModal",
                requiredContextKeys: ["recipientEmail", "subject"],
                optionalContextKeys: ["body"],
                fallbackBehavior: .openEmailComposer,
                analyticsEvent: "action_reply",
                priority: .mediumHigh,
                description: "Reply to email"
            ),

            // Delegate
            ActionConfig(
                actionId: "delegate",
                displayName: "Delegate Task",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "EmailComposerModal",
                requiredContextKeys: [],
                optionalContextKeys: ["recipientEmail", "taskDescription"],
                fallbackBehavior: .openEmailComposer,
                analyticsEvent: "action_delegate",
                priority: .mediumLow,
                description: "Delegate task to colleague"
            ),

            // Save for Later
            ActionConfig(
                actionId: "save_for_later",
                displayName: "Save for Later",
                actionType: .inApp,
                mode: .both,
                modalComponent: "SaveForLaterModal",
                requiredContextKeys: [],
                optionalContextKeys: ["folderId", "reminderTime", "snoozeUntil"],
                fallbackBehavior: .showToast,
                analyticsEvent: "action_save_for_later",
                priority: .mediumLow,
                description: "Save email to folder or set reminder"
            ),

            // === EDUCATION ACTIONS ===

            // View Assignment
            ActionConfig(
                actionId: "view_assignment",
                displayName: "View Assignment",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["assignmentUrl", "assignmentName", "dueDate"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_assignment",
                priority: .high,
                description: "View school assignment details"
            ),

            // Check Grade
            ActionConfig(
                actionId: "check_grade",
                displayName: "Check Grade",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["gradeUrl", "courseName"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_check_grade",
                priority: .mediumHigh,
                description: "View grade or report card"
            ),

            // View LMS (Learning Management System)
            ActionConfig(
                actionId: "view_lms",
                displayName: "View LMS",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["lmsUrl", "platformName"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_lms",
                priority: .medium,
                description: "Open learning management system"
            ),

            // === HEALTHCARE ACTIONS ===

            // View Results
            ActionConfig(
                actionId: "view_results",
                displayName: "View Results",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["resultsUrl", "testResultsUrl", "reportType"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_results",
                priority: .veryHigh,
                description: "View medical test results"
            ),

            // View Prescription
            ActionConfig(
                actionId: "view_prescription",
                displayName: "View Prescription",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["prescriptionUrl", "rxNumber"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_prescription",
                priority: .high,
                description: "View prescription details"
            ),

            // Schedule Appointment
            ActionConfig(
                actionId: "schedule_appointment",
                displayName: "Schedule Appointment",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["schedulingUrl", "providerName"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_schedule_appointment",
                priority: .high,
                description: "Schedule medical appointment"
            ),

            // Check In Appointment
            ActionConfig(
                actionId: "check_in_appointment",
                displayName: "Check In",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["checkInUrl", "appointmentUrl", "appointmentTime"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_check_in_appointment",
                priority: .veryHigh,
                description: "Check in for medical appointment"
            ),

            // === CIVIC & GOVERNMENT ACTIONS ===

            // View Jury Summons
            ActionConfig(
                actionId: "view_jury_summons",
                displayName: "View Jury Summons",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["summonsUrl", "courtDate", "location"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_jury_summons",
                priority: .critical,
                description: "View jury duty summons details"
            ),

            // View Tax Notice
            ActionConfig(
                actionId: "view_tax_notice",
                displayName: "View Tax Notice",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["taxNoticeUrl", "dueDate", "amount"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_tax_notice",
                priority: .critical,
                description: "View tax notice or bill"
            ),

            // View Voter Information
            ActionConfig(
                actionId: "view_voter_info",
                displayName: "View Voter Info",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["voterUrl", "electionDate", "pollingLocation"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_voter_info",
                priority: .veryHigh,
                description: "View voting information and polling location"
            ),

            // === PROFESSIONAL/WORK ACTIONS ===

            // View Task
            ActionConfig(
                actionId: "view_task",
                displayName: "View Task",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["taskUrl", "taskName", "dueDate"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_task",
                priority: .mediumHigh,
                description: "View project task details"
            ),

            // View Incident
            ActionConfig(
                actionId: "view_incident",
                displayName: "View Incident",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["incidentUrl", "incidentId", "severity"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_incident",
                priority: .veryHigh,
                description: "View incident or alert details"
            ),

            // View Ticket
            ActionConfig(
                actionId: "view_ticket",
                displayName: "View Ticket",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["ticketUrl", "ticketNumber", "status"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_ticket",
                priority: .medium,
                description: "View support ticket"
            ),

            // Route to CRM
            ActionConfig(
                actionId: "route_crm",
                displayName: "Route to CRM",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "EmailComposerModal",
                requiredContextKeys: [],
                optionalContextKeys: ["crmUrl", "contactName", "leadId"],
                fallbackBehavior: .openEmailComposer,
                analyticsEvent: "action_route_crm",
                priority: .mediumLow,
                description: "Route lead to CRM system"
            ),

            // === BILLING ACTIONS (IN_APP) ===

            // Set Payment Reminder
            ActionConfig(
                actionId: "set_payment_reminder",
                displayName: "Set Reminder",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "AddReminderModal",
                requiredContextKeys: ["dueDate"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_set_payment_reminder",
                priority: .medium,
                description: "Set reminder to pay invoice"
            ),

            // === CAREER ACTIONS (IN_APP) ===

            // View Onboarding Info
            ActionConfig(
                actionId: "view_onboarding_info",
                displayName: "View Onboarding Info",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "ViewDetailsModal",
                requiredContextKeys: [],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_onboarding_info",
                priority: .veryHigh,
                description: "View new hire onboarding information"
            ),

            // === HEALTHCARE IN_APP ACTIONS ===

            // File Insurance Claim
            ActionConfig(
                actionId: "file_insurance_claim",
                displayName: "File Insurance Claim",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "FileInsuranceClaimModal",
                requiredContextKeys: [],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_file_insurance_claim",
                priority: .veryHigh,
                description: "File insurance claim for medical bill reimbursement"
            ),

            // Pickup Details
            ActionConfig(
                actionId: "pickup_prescription",
                displayName: "Pickup Details",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "PickupDetailsModal",
                requiredContextKeys: ["medication"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_pickup_prescription",
                priority: .veryHigh,
                description: "View prescription pickup information"
            ),

            // === EDUCATION IN_APP ACTIONS ===

            // Pay Fee
            ActionConfig(
                actionId: "pay_form_fee",
                displayName: "Pay Fee",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "PayFeeModal",
                requiredContextKeys: ["amount"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_pay_form_fee",
                priority: .high,
                description: "Pay associated form fee"
            ),

            // View Practice Info
            ActionConfig(
                actionId: "view_practice_details",
                displayName: "View Practice Info",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "ViewPracticeInfoModal",
                requiredContextKeys: ["sport", "dateTime"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_practice_details",
                priority: .veryHigh,
                description: "View practice details"
            ),

            // Accept Event
            ActionConfig(
                actionId: "accept_school_event",
                displayName: "Accept Event",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "AcceptEventModal",
                requiredContextKeys: ["event", "dateTime"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_accept_school_event",
                priority: .veryHigh,
                description: "Accept school event invitation and add to calendar"
            ),

            // View Announcement
            ActionConfig(
                actionId: "view_team_announcement",
                displayName: "View Announcement",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "ViewAnnouncementModal",
                requiredContextKeys: ["sport", "team"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_team_announcement",
                priority: .veryHigh,
                description: "View team announcement details"
            ),

            // Add to Calendar
            ActionConfig(
                actionId: "add_activity_to_calendar",
                displayName: "Add to Calendar",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "AddtoCalendarModal",
                requiredContextKeys: ["date"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_add_activity_to_calendar",
                priority: .medium,
                description: "Add activity to calendar"
            ),

            // === THREAD FINDER ACTIONS ===

            // View Extracted Content
            ActionConfig(
                actionId: "view_extracted_content",
                displayName: "View Extracted Content",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "ViewExtractedContentModal",
                requiredContextKeys: ["extractedContent"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_extracted_content",
                priority: .veryHigh,
                description: "View automatically extracted data from link (Thread Finder)"
            ),

            // Retry Extraction
            ActionConfig(
                actionId: "schedule_extraction_retry",
                displayName: "Retry Extraction",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "RetryExtractionModal",
                requiredContextKeys: ["link"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_schedule_extraction_retry",
                priority: .medium,
                description: "Retry automatic data extraction (Thread Finder)"
            ),
        ]
    }

    // MARK: - Ads Mode Actions

    private var adsModeActions: [ActionConfig] {
        [
            // Browse Shopping
            ActionConfig(
                actionId: "browse_shopping",
                displayName: "Browse Shopping",
                actionType: .inApp,
                mode: .ads,
                modalComponent: "BrowseShoppingModal",
                requiredContextKeys: [],
                optionalContextKeys: ["productUrl", "category", "query"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_browse_shopping",
                priority: .medium,
                description: "Browse shopping products"
            ),

            // Schedule Purchase (PREMIUM)
            ActionConfig(
                actionId: "schedule_purchase",
                displayName: "Buy on {saleDateShort}",
                actionType: .inApp,
                mode: .ads,
                modalComponent: "ScheduledPurchaseModal",
                requiredContextKeys: [],
                optionalContextKeys: ["productName", "price", "purchaseDate"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_schedule_purchase",
                priority: .mediumHigh,
                description: "Schedule future purchase with reminder",
                requiredPermission: .premium
            ),

            // View Newsletter Summary (PREMIUM - AI-powered)
            ActionConfig(
                actionId: "view_newsletter_summary",
                displayName: "View Summary",
                actionType: .inApp,
                mode: .ads,
                modalComponent: "NewsletterSummaryModal",
                requiredContextKeys: [],
                optionalContextKeys: ["summaryText", "topLinks"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_newsletter_summary",
                priority: .mediumLow,
                description: "View AI-generated newsletter summary",
                requiredPermission: .premium
            ),

            // Unsubscribe (PREMIUM - one-tap unsubscribe)
            ActionConfig(
                actionId: "unsubscribe",
                displayName: "Unsubscribe",
                actionType: .goTo,
                mode: .ads,
                modalComponent: nil,
                requiredContextKeys: ["unsubscribeUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_unsubscribe",
                priority: .high,
                description: "Unsubscribe from mailing list",
                requiredPermission: .premium,
                confirmationRequirement: .undoable(
                    config: UndoConfig(toastMessage: "Unsubscribed. Tap to undo.")
                )
            ),

            // Shop Now
            ActionConfig(
                actionId: "shop_now",
                displayName: "Shop Now",
                actionType: .goTo,
                mode: .ads,
                modalComponent: nil,
                requiredContextKeys: ["shopUrl"],
                optionalContextKeys: ["productUrl"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_shop_now",
                priority: .medium,
                description: "Open shopping link"
            ),

            // Claim Deal (Shopping Automation)
            ActionConfig(
                actionId: "claim_deal",
                displayName: "Claim Deal",
                actionType: .inApp,
                mode: .ads,
                modalComponent: "ShoppingAutomationModal",
                requiredContextKeys: ["productUrl"],
                optionalContextKeys: ["productName", "dealUrl", "promoCode"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_claim_deal",
                priority: .mediumHigh,
                description: "Automatically add product to cart using Steel.dev browser automation"
            ),

            // Cancel Subscription
            ActionConfig(
                actionId: "cancel_subscription",
                displayName: "Cancel Subscription",
                actionType: .inApp,
                mode: .ads,
                modalComponent: "CancelSubscriptionModal",
                requiredContextKeys: [],
                optionalContextKeys: ["serviceName", "cancellationUrl"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_cancel_subscription",
                priority: .high,
                description: "Cancel subscription service",
                confirmationRequirement: .undoable(
                    config: UndoConfig(toastMessage: "Subscription cancelled. Tap to undo.")
                )
            ),
        ]
    }

    // MARK: - Shared Actions (Both Modes)

    private var sharedActions: [ActionConfig] {
        [
            // View Details (generic fallback)
            ActionConfig(
                actionId: "view_details",
                displayName: "View Details",
                actionType: .inApp,
                mode: .both,
                modalComponent: "ViewDetailsModal",
                requiredContextKeys: [],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_details",
                priority: .veryLow,
                description: "View email details"
            ),

            // Native iOS: Add to Wallet
            ActionConfig(
                actionId: "add_to_wallet",
                displayName: "Add to Wallet",
                actionType: .inApp,
                mode: .both,
                modalComponent: "AddToWalletModal",
                requiredContextKeys: [],
                optionalContextKeys: ["passUrl", "passType"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_add_to_wallet",
                priority: .high,
                description: "Add pass to Apple Wallet"
            ),

            // Native iOS: Save Contact
            ActionConfig(
                actionId: "save_contact_native",
                displayName: "Save Contact",
                actionType: .inApp,
                mode: .both,
                modalComponent: "SaveContactModal",
                requiredContextKeys: [],
                optionalContextKeys: ["name", "email", "phone"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_save_contact",
                priority: .mediumLow,
                description: "Save contact to iOS Contacts"
            ),

            // Native iOS: Send Message
            ActionConfig(
                actionId: "send_message",
                displayName: "Send Message",
                actionType: .inApp,
                mode: .both,
                modalComponent: "SendMessageModal",
                requiredContextKeys: [],
                optionalContextKeys: ["phoneNumber", "message"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_send_message",
                priority: .medium,
                description: "Send SMS/iMessage"
            ),

            // Native iOS: Share
            ActionConfig(
                actionId: "share",
                displayName: "Share",
                actionType: .inApp,
                mode: .both,
                modalComponent: "ShareModal",
                requiredContextKeys: ["content"],
                optionalContextKeys: [],
                fallbackBehavior: .doNothing,
                analyticsEvent: "action_share",
                priority: .low,
                description: "Share via iOS share sheet"
            ),

            // Open App
            ActionConfig(
                actionId: "open_app",
                displayName: "Open App",
                actionType: .inApp,
                mode: .both,
                modalComponent: "OpenAppModal",
                requiredContextKeys: [],
                optionalContextKeys: ["appUrl", "appName"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_open_app",
                priority: .mediumLow,
                description: "Open external app"
            ),

            // View Reservation
            ActionConfig(
                actionId: "view_reservation",
                displayName: "View Reservation",
                actionType: .inApp,
                mode: .both,
                modalComponent: "ReservationModal",
                requiredContextKeys: [],
                optionalContextKeys: ["reservationNumber", "venue", "date"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_reservation",
                priority: .medium,
                description: "View reservation details"
            ),

            // === COMMUNICATION & FEEDBACK ===

            // Accept Invitation
            ActionConfig(
                actionId: "rsvp_yes",
                displayName: "Accept Invitation",
                actionType: .inApp,
                mode: .both,
                modalComponent: "AcceptInvitationModal",
                requiredContextKeys: [],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_rsvp_yes",
                priority: .veryHigh,
                description: "Accept invitation"
            ),

            // Decline Invitation
            ActionConfig(
                actionId: "rsvp_no",
                displayName: "Decline Invitation",
                actionType: .inApp,
                mode: .both,
                modalComponent: "DeclineInvitationModal",
                requiredContextKeys: [],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_rsvp_no",
                priority: .medium,
                description: "Decline invitation",
                confirmationRequirement: .undoable(
                    config: UndoConfig(toastMessage: "Invitation declined. Tap to undo.", undoActionId: "rsvp_yes")
                )
            ),

            // Reply to Thread
            ActionConfig(
                actionId: "reply_to_thread",
                displayName: "Reply",
                actionType: .inApp,
                mode: .both,
                modalComponent: "ReplyModal",
                requiredContextKeys: [],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_reply_to_thread",
                priority: .veryHigh,
                description: "Reply to email thread"
            ),

            // View Introduction
            ActionConfig(
                actionId: "view_introduction",
                displayName: "View Introduction",
                actionType: .inApp,
                mode: .both,
                modalComponent: "ViewIntroductionModal",
                requiredContextKeys: ["introducedPerson"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_introduction",
                priority: .veryHigh,
                description: "View introduction details"
            ),

            // Add to Notes
            ActionConfig(
                actionId: "add_to_notes",
                displayName: "Add to Notes",
                actionType: .inApp,
                mode: .both,
                modalComponent: "AddtoNotesModal",
                requiredContextKeys: [],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_add_to_notes",
                priority: .veryHigh,
                description: "Save email content to iOS Notes app"
            ),

            // Say Thanks
            ActionConfig(
                actionId: "reply_thanks",
                displayName: "Say Thanks",
                actionType: .inApp,
                mode: .both,
                modalComponent: "SayThanksModal",
                requiredContextKeys: ["sender"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_reply_thanks",
                priority: .high,
                description: "Send quick thank you reply"
            ),

            // === SHOPPING & E-COMMERCE ===

            // Copy Code
            ActionConfig(
                actionId: "copy_promo_code",
                displayName: "Copy Code",
                actionType: .inApp,
                mode: .both,
                modalComponent: "CopyCodeModal",
                requiredContextKeys: ["promoCode"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_copy_promo_code",
                priority: .high,
                description: "Copy promo code"
            ),

            // Add to Cart & Checkout
            ActionConfig(
                actionId: "automated_add_to_cart",
                displayName: "Add to Cart & Checkout",
                actionType: .inApp,
                mode: .both,
                modalComponent: "AddtoCart&CheckoutModal",
                requiredContextKeys: ["productUrl", "productName"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_automated_add_to_cart",
                priority: .veryHigh,
                description: "AI agent adds item to cart and opens checkout"
            ),

            // Rate Product
            ActionConfig(
                actionId: "rate_product",
                displayName: "Rate Product",
                actionType: .inApp,
                mode: .both,
                modalComponent: "RateProductModal",
                requiredContextKeys: ["productName"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_rate_product",
                priority: .high,
                description: "Quick star rating"
            ),

            // Set Price Alert
            ActionConfig(
                actionId: "set_price_alert",
                displayName: "Set Price Alert",
                actionType: .inApp,
                mode: .both,
                modalComponent: "SetPriceAlertModal",
                requiredContextKeys: ["productName"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_set_price_alert",
                priority: .high,
                description: "Get notified of price changes"
            ),

            // Notify When Back
            ActionConfig(
                actionId: "notify_restock",
                displayName: "Notify When Back",
                actionType: .inApp,
                mode: .both,
                modalComponent: "NotifyWhenBackModal",
                requiredContextKeys: ["productName"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_notify_restock",
                priority: .high,
                description: "Get notified when item restocks"
            ),

            // === DELIVERY & LOGISTICS ===

            // Provide Access Code
            ActionConfig(
                actionId: "provide_access_code",
                displayName: "Provide Access Code",
                actionType: .inApp,
                mode: .both,
                modalComponent: "ProvideAccessCodeModal",
                requiredContextKeys: ["trackingNumber"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_provide_access_code",
                priority: .medium,
                description: "Provide building or gate access code for delivery"
            ),

            // === SUPPORT & SUBSCRIPTION ===

            // Reply to Ticket
            ActionConfig(
                actionId: "reply_to_ticket",
                displayName: "Reply",
                actionType: .inApp,
                mode: .both,
                modalComponent: "ReplyModal",
                requiredContextKeys: ["ticketId"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_reply_to_ticket",
                priority: .high,
                description: "Reply to support ticket"
            ),

            // View Benefits
            ActionConfig(
                actionId: "view_benefits",
                displayName: "View Benefits",
                actionType: .inApp,
                mode: .both,
                modalComponent: "ViewBenefitsModal",
                requiredContextKeys: ["serviceName"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_benefits",
                priority: .veryHigh,
                description: "View subscription benefits and rewards"
            ),

            // === FINANCE ===

            // Schedule Payment
            ActionConfig(
                actionId: "schedule_payment",
                displayName: "Schedule Payment",
                actionType: .inApp,
                mode: .both,
                modalComponent: "SchedulePaymentModal",
                requiredContextKeys: ["amountDue", "dueDate"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_schedule_payment",
                priority: .high,
                description: "Schedule automatic payment",
                confirmationRequirement: .confirmWithUndo(
                    confirmation: "Schedule ${amountDue} payment for {dueDate}?",
                    undo: UndoConfig(toastMessage: "Payment scheduled. Tap to undo.")
                )
            ),

            // === UTILITY ===

            // View Preparation Tips
            ActionConfig(
                actionId: "prepare_for_outage",
                displayName: "View Preparation Tips",
                actionType: .inApp,
                mode: .both,
                modalComponent: "ViewPreparationTipsModal",
                requiredContextKeys: [],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_prepare_for_outage",
                priority: .high,
                description: "View tips to prepare for power outage"
            ),

            // Set Outage Reminder
            ActionConfig(
                actionId: "set_outage_reminder",
                displayName: "Set Reminder",
                actionType: .inApp,
                mode: .both,
                modalComponent: "SetReminderModal",
                requiredContextKeys: ["outageStart"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_set_outage_reminder",
                priority: .medium,
                description: "Remind before planned outage"
            ),

            // === PROFESSIONAL SERVICES ===

            // View Mortgage Details
            ActionConfig(
                actionId: "view_mortgage_details",
                displayName: "View Mortgage Details",
                actionType: .inApp,
                mode: .both,
                modalComponent: "ViewMortgageDetailsModal",
                requiredContextKeys: [],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_mortgage_details",
                priority: .veryHigh,
                description: "View mortgage or refinancing details"
            ),

            // View Legal Document
            ActionConfig(
                actionId: "view_legal_document",
                displayName: "View Document",
                actionType: .inApp,
                mode: .both,
                modalComponent: "ViewDocumentModal",
                requiredContextKeys: [],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_legal_document",
                priority: .veryHigh,
                description: "View legal document details"
            ),
        ]
    }

    // MARK: - GO_TO Actions (External URLs)

    private var goToActions: [ActionConfig] {
        [
            // View Order
            ActionConfig(
                actionId: "view_order",
                displayName: "View Order",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["orderUrl"],
                optionalContextKeys: ["orderNumber"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_order",
                priority: .medium,
                description: "View order details online"
            ),

            // Manage Subscription
            ActionConfig(
                actionId: "manage_subscription",
                displayName: "Manage Subscription",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["subscriptionUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_manage_subscription",
                priority: .medium,
                description: "Manage subscription settings"
            ),

            // View Itinerary
            ActionConfig(
                actionId: "view_itinerary",
                displayName: "View Itinerary",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["itineraryUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_itinerary",
                priority: .mediumHigh,
                description: "View travel itinerary"
            ),

            // Get Directions
            ActionConfig(
                actionId: "get_directions",
                displayName: "Get Directions",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["directionsUrl"],
                optionalContextKeys: ["mapUrl", "address"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_get_directions",
                priority: .mediumHigh,
                description: "Get directions to location"
            ),

            // Open Link
            ActionConfig(
                actionId: "open_link",
                displayName: "Open Link",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_open_link",
                priority: .veryLow,
                description: "Open generic URL"
            ),

            // === ACCOUNT ACTIONS ===

            // Reset Password
            ActionConfig(
                actionId: "reset_password",
                displayName: "Reset Password",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "resetLink"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_reset_password",
                priority: .veryHigh,
                description: "Reset account password"
            ),

            // Review Security
            ActionConfig(
                actionId: "review_security",
                displayName: "Review Security",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["securityUrl"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_review_security",
                priority: .veryHigh,
                description: "Review security settings"
            ),

            // Revoke Secret
            ActionConfig(
                actionId: "revoke_secret",
                displayName: "Revoke Secret",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "actionUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_revoke_secret",
                priority: .veryHigh,
                description: "Revoke exposed API key or secret",
                confirmationRequirement: .detailed(
                    title: "Revoke API Key",
                    message: "This will immediately revoke the exposed API key or secret. Any services using this key will stop working.",
                    confirmText: "Revoke Key",
                    cancelText: "Cancel"
                )
            ),

            // Verify Account
            ActionConfig(
                actionId: "verify_account",
                displayName: "Verify Account",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "verificationLink"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_verify_account",
                priority: .veryHigh,
                description: "Verify email or account"
            ),

            // Verify Device
            ActionConfig(
                actionId: "verify_device",
                displayName: "Verify Device",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["verificationUrl"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_verify_device",
                priority: .veryHigh,
                description: "Verify new device login"
            ),

            // === BILLING ACTIONS ===

            // Download Receipt
            ActionConfig(
                actionId: "download_receipt",
                displayName: "Download Receipt",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "receiptUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_download_receipt",
                priority: .high,
                description: "Download payment receipt"
            ),

            // Update Payment
            ActionConfig(
                actionId: "update_payment",
                displayName: "Update Payment",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["paymentUrl"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_update_payment",
                priority: .high,
                description: "Update payment method"
            ),

            // View Invoice
            ActionConfig(
                actionId: "view_invoice",
                displayName: "View Invoice",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["invoiceUrl", "invoiceId"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_invoice",
                priority: .high,
                description: "View invoice details"
            ),

            // === CAREER ACTIONS ===

            // Accept Offer
            ActionConfig(
                actionId: "accept_offer",
                displayName: "Accept Offer",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "offerUrl"],
                optionalContextKeys: ["company", "position"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_accept_offer",
                priority: .veryHigh,
                description: "Accept job offer",
                confirmationRequirement: .detailed(
                    title: "Accept Job Offer",
                    message: "This will formally accept your job offer. Make sure you've reviewed all terms and conditions before proceeding.",
                    confirmText: "Accept Offer",
                    cancelText: "Review Again"
                )
            ),

            // Check Application Status
            ActionConfig(
                actionId: "check_application_status",
                displayName: "Check Status",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["applicationUrl", "company", "position"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_check_application_status",
                priority: .veryHigh,
                description: "Check application status"
            ),

            // Schedule Interview
            ActionConfig(
                actionId: "schedule_interview",
                displayName: "Schedule Interview",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "interviewUrl"],
                optionalContextKeys: ["company", "position"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_schedule_interview",
                priority: .veryHigh,
                description: "Schedule interview time"
            ),

            // View Job Details
            ActionConfig(
                actionId: "view_job_details",
                displayName: "View Job Details",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: ["jobUrl"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_job_details",
                priority: .high,
                description: "View detailed job description"
            ),

            // Buy Again
            ActionConfig(
                actionId: "buy_again",
                displayName: "Buy Again",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "orderNumber"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_buy_again",
                priority: .high,
                description: "Reorder the same items"
            ),


            // Return Item
            ActionConfig(
                actionId: "return_item",
                displayName: "Return Item",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "orderNumber"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_return_item",
                priority: .veryHigh,
                description: "Initiate return process"
            ),


            // Join Meeting
            ActionConfig(
                actionId: "join_meeting",
                displayName: "Join Meeting",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "meetingUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_join_meeting",
                priority: .veryHigh,
                description: "Join video meeting"
            ),


            // Register
            ActionConfig(
                actionId: "register_event",
                displayName: "Register",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "registrationLink"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_register_event",
                priority: .veryHigh,
                description: "Register for event"
            ),


            // Modify Reservation
            ActionConfig(
                actionId: "modify_reservation",
                displayName: "Modify Reservation",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "confirmationCode"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_modify_reservation",
                priority: .high,
                description: "Modify restaurant reservation"
            ),


            // Track Delivery
            ActionConfig(
                actionId: "track_delivery",
                displayName: "Track Delivery",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "trackingUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_track_delivery",
                priority: .veryHigh,
                description: "Track food delivery in real-time"
            ),


            // Change Preferences
            ActionConfig(
                actionId: "change_delivery_preferences",
                displayName: "Change Preferences",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_change_delivery_preferences",
                priority: .high,
                description: "Update delivery time or location preferences"
            ),


            // View Message
            ActionConfig(
                actionId: "view_lms_message",
                displayName: "View Message",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url", "messageUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_lms_message",
                priority: .veryHigh,
                description: "View Canvas/Classroom message from teacher"
            ),


            // Reply to Teacher
            ActionConfig(
                actionId: "reply_to_teacher",
                displayName: "Reply to Teacher",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url", "teacher"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_reply_to_teacher",
                priority: .high,
                description: "Reply to teacher message"
            ),


            // Submit Assignment
            ActionConfig(
                actionId: "submit_assignment",
                displayName: "Submit Assignment",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url", "assignmentUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_submit_assignment",
                priority: .veryHigh,
                description: "Go to assignment submission page"
            ),


            // Register
            ActionConfig(
                actionId: "register_for_sports",
                displayName: "Register",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url", "registrationUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_register_for_sports",
                priority: .veryHigh,
                description: "Register for youth sports or activity"
            ),


            // View Schedule
            ActionConfig(
                actionId: "view_game_schedule",
                displayName: "View Schedule",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_game_schedule",
                priority: .veryHigh,
                description: "View game schedule"
            ),


            // RSVP to Game
            ActionConfig(
                actionId: "rsvp_game",
                displayName: "RSVP to Game",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_rsvp_game",
                priority: .high,
                description: "RSVP for game attendance"
            ),


            // RSVP to Event
            ActionConfig(
                actionId: "rsvp_school_event",
                displayName: "RSVP to Event",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_rsvp_school_event",
                priority: .high,
                description: "RSVP for school event"
            ),


            // Manage Booking
            ActionConfig(
                actionId: "manage_booking",
                displayName: "Manage Booking",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "confirmationCode"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_manage_booking",
                priority: .medium,
                description: "Manage reservation"
            ),


            // Take Survey
            ActionConfig(
                actionId: "take_survey",
                displayName: "Take Survey",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "surveyLink"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_take_survey",
                priority: .veryHigh,
                description: "Complete survey"
            ),


            // View Product
            ActionConfig(
                actionId: "view_product",
                displayName: "View Product",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "productUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_product",
                priority: .veryHigh,
                description: "View product details"
            ),


            // Complete Order
            ActionConfig(
                actionId: "complete_cart",
                displayName: "Complete Order",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "cartUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_complete_cart",
                priority: .veryHigh,
                description: "Complete cart checkout"
            ),


            // Redeem Rewards
            ActionConfig(
                actionId: "redeem_rewards",
                displayName: "Redeem Rewards",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_redeem_rewards",
                priority: .veryHigh,
                description: "Redeem loyalty points or rewards"
            ),


            // View Announcement
            ActionConfig(
                actionId: "view_announcement",
                displayName: "View Announcement",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_announcement",
                priority: .veryHigh,
                description: "View brand announcement details"
            ),


            // Contact Support
            ActionConfig(
                actionId: "contact_support",
                displayName: "Contact Support",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_contact_support",
                priority: .mediumLow,
                description: "Contact customer support"
            ),


            // Book Appointment
            ActionConfig(
                actionId: "book_appointment",
                displayName: "Book Appointment",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_book_appointment",
                priority: .veryHigh,
                description: "Schedule or book a new appointment"
            ),


            // Confirm Appointment
            ActionConfig(
                actionId: "confirm_appointment",
                displayName: "Confirm Appointment",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_confirm_appointment",
                priority: .veryHigh,
                description: "Confirm medical appointment"
            ),


            // Reschedule
            ActionConfig(
                actionId: "reschedule_appointment",
                displayName: "Reschedule",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_reschedule_appointment",
                priority: .veryHigh,
                description: "Reschedule appointment"
            ),


            // Download Results
            ActionConfig(
                actionId: "download_results",
                displayName: "Download Results",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url", "resultsUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_download_results",
                priority: .veryHigh,
                description: "Download medical test results"
            ),


            // View Referral
            ActionConfig(
                actionId: "view_referral",
                displayName: "View Referral",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_referral",
                priority: .veryHigh,
                description: "View specialist referral details"
            ),


            // Schedule Test
            ActionConfig(
                actionId: "schedule_test",
                displayName: "Schedule Test",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_schedule_test",
                priority: .veryHigh,
                description: "Schedule medical test or lab work"
            ),


            // View Claim
            ActionConfig(
                actionId: "view_claim_status",
                displayName: "View Claim",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url", "claimNumber"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_claim_status",
                priority: .veryHigh,
                description: "View insurance claim status"
            ),


            // View Statement
            ActionConfig(
                actionId: "view_statement",
                displayName: "View Statement",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "accountId"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_statement",
                priority: .veryHigh,
                description: "View financial statement"
            ),


            // Update Payment
            ActionConfig(
                actionId: "update_payment_method",
                displayName: "Update Payment",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_update_payment_method",
                priority: .veryHigh,
                description: "Update payment method"
            ),


            // Download Tax Form
            ActionConfig(
                actionId: "download_tax_document",
                displayName: "Download Tax Form",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "taxYear"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_download_tax_document",
                priority: .veryHigh,
                description: "Download tax document"
            ),


            // Dispute Transaction
            ActionConfig(
                actionId: "dispute_transaction",
                displayName: "Dispute Transaction",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_dispute_transaction",
                priority: .veryHigh,
                description: "Report fraudulent transaction"
            ),


            // View Credit Report
            ActionConfig(
                actionId: "view_credit_report",
                displayName: "View Credit Report",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_credit_report",
                priority: .veryHigh,
                description: "View credit score and report"
            ),


            // View Portfolio
            ActionConfig(
                actionId: "view_portfolio",
                displayName: "View Portfolio",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "accountId"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_portfolio",
                priority: .veryHigh,
                description: "View investment portfolio"
            ),


            // Verify Transaction
            ActionConfig(
                actionId: "verify_transaction",
                displayName: "Verify Transaction",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_verify_transaction",
                priority: .veryHigh,
                description: "Verify suspicious transaction"
            ),


            // Track Return
            ActionConfig(
                actionId: "track_return",
                displayName: "Track Return",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "orderNumber"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_track_return",
                priority: .veryHigh,
                description: "Track return shipment status"
            ),


            // Print Label
            ActionConfig(
                actionId: "print_return_label",
                displayName: "Print Label",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "orderNumber"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_print_return_label",
                priority: .veryHigh,
                description: "Print return shipping label"
            ),


            // View Refund
            ActionConfig(
                actionId: "view_refund_status",
                displayName: "View Refund",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "refundAmount"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_refund_status",
                priority: .veryHigh,
                description: "View refund processing status"
            ),


            // Reorder
            ActionConfig(
                actionId: "reorder_item",
                displayName: "Reorder",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "productName"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_reorder_item",
                priority: .veryHigh,
                description: "Reorder out-of-stock item"
            ),


            // View Warranty
            ActionConfig(
                actionId: "view_warranty",
                displayName: "View Warranty",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "productName"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_warranty",
                priority: .veryHigh,
                description: "View warranty details"
            ),


            // View Outage Info
            ActionConfig(
                actionId: "view_outage_details",
                displayName: "View Outage Info",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_outage_details",
                priority: .veryHigh,
                description: "View power outage details and affected areas"
            ),


            // Schedule Delivery
            ActionConfig(
                actionId: "schedule_delivery_time",
                displayName: "Schedule Delivery",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_schedule_delivery_time",
                priority: .veryHigh,
                description: "Choose delivery time window"
            ),


            // View Homes
            ActionConfig(
                actionId: "view_property_listings",
                displayName: "View Homes",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_property_listings",
                priority: .veryHigh,
                description: "View recommended property listings"
            ),


            // Save Favorites
            ActionConfig(
                actionId: "save_properties",
                displayName: "Save Favorites",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_save_properties",
                priority: .high,
                description: "Save properties to favorites"
            ),


            // Schedule Tour
            ActionConfig(
                actionId: "schedule_showing",
                displayName: "Schedule Tour",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_schedule_showing",
                priority: .high,
                description: "Schedule property showing"
            ),


            // Read Post
            ActionConfig(
                actionId: "read_community_post",
                displayName: "Read Post",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_read_community_post",
                priority: .veryHigh,
                description: "Read community post"
            ),


            // View Comments
            ActionConfig(
                actionId: "view_post_comments",
                displayName: "View Comments",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_post_comments",
                priority: .high,
                description: "Read post comments and discussion"
            ),


            // Reply
            ActionConfig(
                actionId: "reply_to_post",
                displayName: "Reply",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_reply_to_post",
                priority: .medium,
                description: "Reply to community post"
            ),


            // View Activity
            ActionConfig(
                actionId: "view_activity_details",
                displayName: "View Activity",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_activity_details",
                priority: .veryHigh,
                description: "View educational activity details"
            ),


            // Book Tickets
            ActionConfig(
                actionId: "book_activity_tickets",
                displayName: "Book Tickets",
                actionType: .goTo,
                mode: .mail,
                modalComponent: nil,
                requiredContextKeys: ["url"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_book_activity_tickets",
                priority: .high,
                description: "Book tickets for activity"
            ),


            // === CIVIC, EDUCATION, FINANCE, REAL ESTATE, SOCIAL, SUBSCRIPTION ===

            // Apply for Permit
            ActionConfig(
                actionId: "apply_for_permit",
                displayName: "Apply for Permit",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "applicationUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_apply_for_permit",
                priority: .medium,
                description: "Apply for government permit",
                confirmationRequirement: .simple(message: "Submit permit application? This will begin the official application process.")
            ),

            // Confirm Appearance
            ActionConfig(
                actionId: "confirm_court_appearance",
                displayName: "Confirm Appearance",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "confirmationUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_confirm_court_appearance",
                priority: .medium,
                description: "Confirm court appearance or jury duty",
                confirmationRequirement: .detailed(
                    title: "Confirm Court Appearance",
                    message: "This will confirm your attendance for court or jury duty. This action cannot be undone.",
                    confirmText: "Confirm Appearance",
                    cancelText: "Cancel"
                )
            ),

            // Pay Property Tax
            ActionConfig(
                actionId: "pay_property_tax",
                displayName: "Pay Property Tax",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "paymentUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_pay_property_tax",
                priority: .medium,
                description: "Pay property tax bill",
                confirmationRequirement: .confirmWithUndo(
                    confirmation: "Confirm property tax payment?",
                    undo: UndoConfig(toastMessage: "Tax payment initiated. Tap to undo.")
                )
            ),

            // Register to Vote
            ActionConfig(
                actionId: "register_to_vote",
                displayName: "Register to Vote",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "registrationUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_register_to_vote",
                priority: .medium,
                description: "Complete voter registration"
            ),

            // Renew License
            ActionConfig(
                actionId: "renew_license",
                displayName: "Renew License",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "renewalUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_renew_license",
                priority: .medium,
                description: "Renew driver license or ID"
            ),

            // View Ballot
            ActionConfig(
                actionId: "view_ballot",
                displayName: "View Ballot",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "guideUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_ballot",
                priority: .medium,
                description: "View sample ballot and voting guide"
            ),

            // Download Attachment
            ActionConfig(
                actionId: "download_attachment",
                displayName: "Download Attachment",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "attachmentUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_download_attachment",
                priority: .mediumLow,
                description: "Download assignment attachment (PDF, worksheet, rubric)"
            ),

            // Open Original Link
            ActionConfig(
                actionId: "open_original_link",
                displayName: "Open Original Link",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "link"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_open_original_link",
                priority: .mediumLow,
                description: "Open the original link in browser"
            ),

            // Pay Bill
            ActionConfig(
                actionId: "pay_utility_bill",
                displayName: "Pay Bill",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "billUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_pay_utility_bill",
                priority: .medium,
                description: "Pay utility bill online",
                confirmationRequirement: .confirmWithUndo(
                    confirmation: "Confirm utility bill payment?",
                    undo: UndoConfig(toastMessage: "Bill payment sent. Tap to undo.")
                )
            ),

            // Schedule Inspection
            ActionConfig(
                actionId: "schedule_inspection",
                displayName: "Schedule Inspection",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "schedulingUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_schedule_inspection",
                priority: .medium,
                description: "Schedule real estate inspection"
            ),

            // Accept Invitation
            ActionConfig(
                actionId: "accept_social_invitation",
                displayName: "Accept Invitation",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "invitationLink"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_accept_social_invitation",
                priority: .low,
                description: "Accept social platform invitation"
            ),

            // Share Activity
            ActionConfig(
                actionId: "share_achievement",
                displayName: "Share Activity",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "activityUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_share_achievement",
                priority: .low,
                description: "Share fitness achievement on social media"
            ),

            // Verify Account
            ActionConfig(
                actionId: "verify_social_account",
                displayName: "Verify Account",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "verificationLink"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_verify_social_account",
                priority: .low,
                description: "Verify social platform account"
            ),

            // View Activity
            ActionConfig(
                actionId: "view_activity",
                displayName: "View Activity",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "activityUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_activity",
                priority: .low,
                description: "View fitness activity that received kudos"
            ),

            // View Message
            ActionConfig(
                actionId: "view_social_message",
                displayName: "View Message",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "messageUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_social_message",
                priority: .low,
                description: "View social platform message"
            ),

            // Cancel Service
            ActionConfig(
                actionId: "cancel_subscription_service",
                displayName: "Cancel Service",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "cancellationUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_cancel_subscription_service",
                priority: .medium,
                description: "Cancel subscription service"
            ),

            // Extend Trial
            ActionConfig(
                actionId: "extend_trial",
                displayName: "Extend Trial",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "extensionUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_extend_trial",
                priority: .mediumLow,
                description: "Extend free trial period"
            ),

            // Upgrade Now
            ActionConfig(
                actionId: "upgrade_subscription",
                displayName: "Upgrade Now",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "upgradeUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_upgrade_subscription",
                priority: .medium,
                description: "Upgrade subscription plan"
            ),

            // View Usage
            ActionConfig(
                actionId: "view_usage",
                displayName: "View Usage",
                actionType: .goTo,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["url", "usageUrl"],
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_usage",
                priority: .mediumLow,
                description: "View subscription usage details"
            ),
        ]
    }

    // MARK: - All Actions Combined

    private var allActions: [ActionConfig] {
        highFidelityActions +
        mailModeActions +
        adsModeActions +
        sharedActions +
        goToActions
    }

    // MARK: - Public Methods

    /// Get action configuration by ID
    func getAction(_ actionId: String) -> ActionConfig? {
        return registry[actionId]
    }

    /// Get all actions for a specific mode
    func getActionsForMode(_ mode: ZeroMode) -> [ActionConfig] {
        return registry.values.filter { action in
            action.mode == mode || action.mode == .both
        }
    }

    /// Validate if action can be executed with given context
    func validateAction(_ actionId: String, context: [String: String]?) -> ValidationResult {
        guard let action = getAction(actionId) else {
            return ValidationResult(
                isValid: false,
                missingKeys: [],
                error: "Action '\(actionId)' not found in registry"
            )
        }

        let providedKeys = Set(context?.keys.map { $0 } ?? [])
        let requiredKeys = Set(action.requiredContextKeys)
        let missingKeys = requiredKeys.subtracting(providedKeys)

        if missingKeys.isEmpty {
            return ValidationResult(isValid: true, missingKeys: [], error: nil)
        } else {
            return ValidationResult(
                isValid: false,
                missingKeys: Array(missingKeys),
                error: "Missing required context: \(missingKeys.joined(separator: ", "))"
            )
        }
    }

    /// Check if action is valid for current mode
    func isActionValidForMode(_ actionId: String, currentMode: CardType) -> Bool {
        guard let action = getAction(actionId) else { return false }

        // Convert CardType to ZeroMode
        let zeroMode: ZeroMode = currentMode == .mail ? .mail : .ads

        return action.mode == zeroMode || action.mode == .both
    }

    /// Get all action IDs
    func getAllActionIds() -> [String] {
        return Array(registry.keys).sorted()
    }

    /// Get action count by type
    func getActionCountByType() -> (goTo: Int, inApp: Int) {
        let goTo = registry.values.filter { $0.actionType == .goTo }.count
        let inApp = registry.values.filter { $0.actionType == .inApp }.count
        return (goTo: goTo, inApp: inApp)
    }

    /// Get action count by mode
    func getActionCountByMode() -> (mail: Int, ads: Int, both: Int) {
        let mail = registry.values.filter { $0.mode == .mail }.count
        let ads = registry.values.filter { $0.mode == .ads }.count
        let both = registry.values.filter { $0.mode == .both }.count
        return (mail: mail, ads: ads, both: both)
    }

    // MARK: - Enhanced Validation (v2.1)

    /// Get all available actions for user context (filters by permissions, feature flags, availability)
    func getAvailableActions(
        for mode: ZeroMode,
        userContext: UserContext,
        emailContext: [String: String]? = nil
    ) -> [ActionConfig] {
        let modeActions = getActionsForMode(mode)

        return modeActions.filter { action in
            isActionAvailable(action, userContext: userContext, emailContext: emailContext)
        }
    }

    /// Check if specific action is available for user (comprehensive check)
    func isActionAvailable(
        _ action: ActionConfig,
        userContext: UserContext,
        emailContext: [String: String]? = nil
    ) -> Bool {
        // 1. Check permission
        guard userContext.hasPermission(action.requiredPermission) else {
            return false
        }

        // 2. Check feature flag (if set)
        if let featureFlag = action.featureFlag {
            guard userContext.isFeatureEnabled(featureFlag) else {
                return false
            }
        }

        // 3. Check availability (time-based, date-based, custom)
        guard action.availability.isAvailable(userContext: userContext) else {
            return false
        }

        // 4. Check required context (if emailContext provided)
        if let emailContext = emailContext {
            let validation = validateAction(action.actionId, context: emailContext)
            guard validation.isValid else {
                return false
            }
        }

        return true
    }

    /// Check if action is available by ID
    func isActionAvailable(
        _ actionId: String,
        userContext: UserContext,
        emailContext: [String: String]? = nil
    ) -> Bool {
        guard let action = getAction(actionId) else { return false }
        return isActionAvailable(action, userContext: userContext, emailContext: emailContext)
    }

    /// Get availability reason (for debugging/UI messages)
    func getAvailabilityReason(
        _ actionId: String,
        userContext: UserContext,
        emailContext: [String: String]? = nil
    ) -> String? {
        guard let action = getAction(actionId) else {
            return "Action not found"
        }

        // Check permission
        if !userContext.hasPermission(action.requiredPermission) {
            switch action.requiredPermission {
            case .premium:
                return "Requires Premium subscription"
            case .beta:
                return "Available to Beta testers only"
            case .admin:
                return "Admin access required"
            default:
                return nil
            }
        }

        // Check feature flag
        if let featureFlag = action.featureFlag, !userContext.isFeatureEnabled(featureFlag) {
            return "Feature not enabled"
        }

        // Check availability
        if !action.availability.isAvailable(userContext: userContext) {
            switch action.availability {
            case .timeWindow(let start, let end):
                return "Available between \(start):00 and \(end):00"
            case .afterDate(let date):
                return "Available after \(date.formatted(date: .abbreviated, time: .omitted))"
            case .beforeDate(let date):
                return "Available until \(date.formatted(date: .abbreviated, time: .omitted))"
            default:
                return "Not currently available"
            }
        }

        // Check context
        if let emailContext = emailContext {
            let validation = validateAction(action.actionId, context: emailContext)
            if !validation.isValid {
                return validation.error
            }
        }

        return nil  // Action is available
    }
}

// MARK: - Validation Result

struct ValidationResult {
    let isValid: Bool
    let missingKeys: [String]
    let error: String?
}

// MARK: - Registry Statistics

extension ActionRegistry {
    /// Get registry statistics for debugging
    func getStatistics() -> RegistryStatistics {
        let typeCounts = getActionCountByType()
        let modeCounts = getActionCountByMode()

        return RegistryStatistics(
            totalActions: registry.count,
            goToActions: typeCounts.goTo,
            inAppActions: typeCounts.inApp,
            mailModeActions: modeCounts.mail,
            adsModeActions: modeCounts.ads,
            sharedActions: modeCounts.both,
            highFidelityActions: highFidelityActions.count
        )
    }
}

struct RegistryStatistics {
    let totalActions: Int
    let goToActions: Int
    let inAppActions: Int
    let mailModeActions: Int
    let adsModeActions: Int
    let sharedActions: Int
    let highFidelityActions: Int

    var description: String {
        """
        ActionRegistry Statistics:
        - Total Actions: \(totalActions)
        - GO_TO Actions: \(goToActions)
        - IN_APP Actions: \(inAppActions)
        - Mail Mode: \(mailModeActions)
        - Ads Mode: \(adsModeActions)
        - Shared (Both): \(sharedActions)
        - High-Fidelity Modals: \(highFidelityActions)
        """
    }
}
