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

    // v2.3 - JSON Modal Configuration
    let modalConfigJSON: String?  // JSON config filename (e.g., "track_package" → Config/ModalConfigs/track_package.json)

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
        confirmationRequirement: ConfirmationRequirement = .none,
        modalConfigJSON: String? = nil
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
        self.modalConfigJSON = modalConfigJSON
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
    /// Phase 3 Optimization: Merges JSON and Swift actions at initialization time
    /// This eliminates repeated JSON parsing on every action lookup
    private(set) lazy var registry: [String: ActionConfig] = {
        var actions: [String: ActionConfig] = [:]

        // PHASE 3: Load JSON actions first (takes priority)
        Logger.info("Initializing ActionRegistry with JSON+Swift hybrid registry", category: .action)

        let jsonActions = ActionLoader.shared.getAllActions()
        var jsonLoadedCount = 0
        var jsonFailedCount = 0

        for jsonAction in jsonActions {
            if let actionConfig = jsonAction.toActionConfig() {
                actions[actionConfig.actionId] = actionConfig
                jsonLoadedCount += 1
            } else {
                Logger.warning("Failed to convert JSON action '\(jsonAction.actionId)' to ActionConfig", category: .action)
                jsonFailedCount += 1
            }
        }

        Logger.info("Loaded \(jsonLoadedCount) actions from JSON (\(jsonFailedCount) failed)", category: .action)

        // FALLBACK: Register Swift actions (won't overwrite JSON actions)
        var swiftActionCount = 0
        allActions.forEach { action in
            if actions[action.actionId] == nil {
                actions[action.actionId] = action
                swiftActionCount += 1
            }
        }

        Logger.info("Registered \(swiftActionCount) Swift fallback actions", category: .action)
        Logger.info("Total actions in registry: \(actions.count)", category: .action)

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
                modalComponent: nil,
                requiredContextKeys: ["trackingNumber", "carrier"],
                optionalContextKeys: ["url", "expectedDelivery", "currentStatus"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_track_package",
                priority: .veryHigh,
                description: "Track package delivery status with carrier details",
                requiredPermission: .premium,
                modalConfigJSON: "track_package"
            ),

            // Pay Invoice - High-fidelity modal with payment amount, merchant info (PREMIUM)
            ActionConfig(
                actionId: "pay_invoice",
                displayName: "Pay Invoice",
                actionType: .inApp,
                mode: .both,
                modalComponent: nil,
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
                ),
                modalConfigJSON: "pay_invoice"
            ),

            // Check In Flight - High-fidelity modal with flight details (PREMIUM)
            ActionConfig(
                actionId: "check_in_flight",
                displayName: "Check In",
                actionType: .inApp,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["flightNumber", "airline"],
                optionalContextKeys: ["checkInUrl", "departureTime", "gate", "seat"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_check_in_flight",
                priority: .critical,
                description: "Check in for flight with airline details",
                requiredPermission: .premium,
                modalConfigJSON: "check_in_flight"
            ),

            // Write Review - High-fidelity modal with product info
            ActionConfig(
                actionId: "write_review",
                displayName: "Write Review",
                actionType: .inApp,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["productName"],
                optionalContextKeys: ["reviewLink", "orderNumber", "productImage"],
                fallbackBehavior: .openEmailComposer,
                analyticsEvent: "action_write_review",
                priority: .mediumLow,
                description: "Write product review",
                modalConfigJSON: "write_review"
            ),

            // Contact Driver - High-fidelity modal with driver contact info
            ActionConfig(
                actionId: "contact_driver",
                displayName: "Contact Driver",
                actionType: .inApp,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: [],
                optionalContextKeys: ["driverName", "driverPhone", "vehicleInfo", "eta"],
                fallbackBehavior: .openEmailComposer,
                analyticsEvent: "action_contact_driver",
                priority: .high,
                description: "Contact delivery driver",
                modalConfigJSON: "contact_driver"
            ),

            // View Pickup Details - High-fidelity modal with pharmacy/prescription info
            ActionConfig(
                actionId: "view_pickup_details",
                displayName: "View Pickup Details",
                actionType: .inApp,
                mode: .both,
                modalComponent: nil,
                requiredContextKeys: ["pharmacy"],
                optionalContextKeys: ["rxNumber", "address", "phone", "hours"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_pickup_details",
                priority: .mediumHigh,
                description: "View prescription pickup details",
                modalConfigJSON: "view_pickup_details"
            ),
        ]
    }

    // MARK: - Mail Mode Actions

    private var mailModeActions: [ActionConfig] {
        [
            // Sign Form (PREMIUM)
            inApp("sign_form", "Sign Form", .critical, "Digitally sign form or document", mode: .mail,
                  optionalContextKeys: ["formUrl", "documentName"], modalConfigJSON: "sign_form", requiredPermission: .premium),

            // Quick Reply
            inApp("quick_reply", "Quick Reply", .high, "Send quick reply to email", mode: .mail,
                  requiredContextKeys: ["recipientEmail", "subject"], optionalContextKeys: ["body", "template"],
                  fallbackBehavior: .openEmailComposer, modalConfigJSON: "quick_reply"),

            // Add to Calendar
            inApp("add_to_calendar", "Add to Calendar", .mediumHigh, "Add event to iOS Calendar", mode: .mail,
                  optionalContextKeys: ["eventTitle", "eventDate", "eventTime", "location"], modalConfigJSON: "add_to_calendar"),

            // Schedule Meeting
            inApp("schedule_meeting", "Schedule Meeting", .medium, "Schedule meeting with attendees", mode: .mail,
                  optionalContextKeys: ["meetingTitle", "attendees", "duration"], fallbackBehavior: .openEmailComposer, modalConfigJSON: "schedule_meeting"),

            // Add Reminder
            inApp("add_reminder", "Add Reminder", .mediumLow, "Add reminder to iOS Reminders", mode: .mail,
                  optionalContextKeys: ["reminderTitle", "dueDate", "notes"], modalConfigJSON: "add_reminder"),

            // Set Reminder (generic)
            inApp("set_reminder", "Remind me on {saleDateShort}", .mediumLow, "Set generic reminder", mode: .mail,
                  optionalContextKeys: ["dueDate", "reminderText"], modalConfigJSON: "add_reminder"),

            // View Document
            inApp("view_document", "View Document", .medium, "View attached document", mode: .mail,
                  optionalContextKeys: ["documentUrl", "documentName"], modalComponent: "DocumentViewerModal"),

            // View Spreadsheet
            inApp("view_spreadsheet", "View Spreadsheet", .mediumLow, "View spreadsheet or budget document", mode: .mail,
                  optionalContextKeys: ["spreadsheetUrl", "sheetName"], modalComponent: "SpreadsheetViewerModal"),

            // Acknowledge
            inApp("acknowledge", "Acknowledge", .low, "Send acknowledgment reply", mode: .mail,
                  requiredContextKeys: ["recipientEmail", "subject"], fallbackBehavior: .openEmailComposer),

            // Reply
            inApp("reply", "Reply", .mediumHigh, "Reply to email", mode: .mail,
                  requiredContextKeys: ["recipientEmail", "subject"], optionalContextKeys: ["body"], fallbackBehavior: .openEmailComposer),

            // Delegate
            inApp("delegate", "Delegate Task", .mediumLow, "Delegate task to colleague", mode: .mail,
                  optionalContextKeys: ["recipientEmail", "taskDescription"], fallbackBehavior: .openEmailComposer, modalComponent: "EmailComposerModal"),

            // Save for Later
            inApp("save_for_later", "Save for Later", .mediumLow, "Save email to folder or set reminder", mode: .both,
                  optionalContextKeys: ["folderId", "reminderTime", "snoozeUntil"], fallbackBehavior: .showToast, modalComponent: "SaveForLaterModal"),

            // === EDUCATION ACTIONS ===

            // View Assignment
            goTo("view_assignment", "View Assignment", ["url"], .high, "View school assignment details", mode: .mail,
                 optionalContextKeys: ["assignmentUrl", "assignmentName", "dueDate"]),

            // Check Grade
            goTo("check_grade", "Check Grade", ["url"], .mediumHigh, "View grade or report card", mode: .mail,
                 optionalContextKeys: ["gradeUrl", "courseName"]),

            // View LMS (Learning Management System)
            goTo("view_lms", "View LMS", ["url"], .medium, "Open learning management system", mode: .mail,
                 optionalContextKeys: ["lmsUrl", "platformName"]),

            // === HEALTHCARE ACTIONS ===

            // View Results
            goTo("view_results", "View Results", ["url"], .veryHigh, "View medical test results", mode: .mail,
                 optionalContextKeys: ["resultsUrl", "testResultsUrl", "reportType"]),

            // View Prescription
            goTo("view_prescription", "View Prescription", ["url"], .high, "View prescription details", mode: .mail,
                 optionalContextKeys: ["prescriptionUrl", "rxNumber"]),

            // Schedule Appointment
            goTo("schedule_appointment", "Schedule Appointment", ["url"], .high, "Schedule medical appointment", mode: .mail,
                 optionalContextKeys: ["schedulingUrl", "providerName"]),

            // Check In Appointment
            goTo("check_in_appointment", "Check In", ["url"], .veryHigh, "Check in for medical appointment", mode: .mail,
                 optionalContextKeys: ["checkInUrl", "appointmentUrl", "appointmentTime"]),

            // === CIVIC & GOVERNMENT ACTIONS ===

            // View Jury Summons
            goTo("view_jury_summons", "View Jury Summons", ["url"], .critical, "View jury duty summons details", mode: .mail,
                 optionalContextKeys: ["summonsUrl", "courtDate", "location"]),

            // View Tax Notice
            goTo("view_tax_notice", "View Tax Notice", ["url"], .critical, "View tax notice or bill", mode: .mail,
                 optionalContextKeys: ["taxNoticeUrl", "dueDate", "amount"]),

            // View Voter Information
            goTo("view_voter_info", "View Voter Info", ["url"], .veryHigh, "View voting information and polling location", mode: .mail,
                 optionalContextKeys: ["voterUrl", "electionDate", "pollingLocation"]),

            // === PROFESSIONAL/WORK ACTIONS ===

            // View Task
            goTo("view_task", "View Task", ["url"], .mediumHigh, "View project task details", mode: .mail,
                 optionalContextKeys: ["taskUrl", "taskName", "dueDate"]),

            // View Incident
            goTo("view_incident", "View Incident", ["url"], .veryHigh, "View incident or alert details", mode: .mail,
                 optionalContextKeys: ["incidentUrl", "incidentId", "severity"]),

            // View Ticket
            goTo("view_ticket", "View Ticket", ["url"], .medium, "View support ticket", mode: .mail,
                 optionalContextKeys: ["ticketUrl", "ticketNumber", "status"]),

            // Route to CRM
            inApp("route_crm", "Route to CRM", .mediumLow, "Route lead to CRM system", mode: .mail,
                  optionalContextKeys: ["crmUrl", "contactName", "leadId"], fallbackBehavior: .openEmailComposer, modalComponent: "EmailComposerModal"),

            // === BILLING ACTIONS (IN_APP) ===

            // Set Payment Reminder
            inApp("set_payment_reminder", "Set Reminder", .medium, "Set reminder to pay invoice", mode: .mail,
                  requiredContextKeys: ["dueDate"]),

            // === CAREER ACTIONS (IN_APP) ===

            // View Onboarding Info
            inApp("view_onboarding_info", "View Onboarding Info", .veryHigh, "View new hire onboarding information", mode: .mail,
                  modalComponent: "ViewDetailsModal"),

            // === HEALTHCARE IN_APP ACTIONS ===

            // File Insurance Claim
            inApp("file_insurance_claim", "File Insurance Claim", .veryHigh, "File insurance claim for medical bill reimbursement", mode: .mail,
                  modalComponent: "FileInsuranceClaimModal"),

            // Pickup Details
            inApp("pickup_prescription", "Pickup Details", .veryHigh, "View prescription pickup information", mode: .mail,
                  requiredContextKeys: ["medication"]),

            // === EDUCATION IN_APP ACTIONS ===

            // Pay Fee
            inApp("pay_form_fee", "Pay Fee", .high, "Pay associated form fee", mode: .mail,
                  requiredContextKeys: ["amount"], modalComponent: "PayFeeModal"),

            // View Practice Info
            inApp("view_practice_details", "View Practice Info", .veryHigh, "View practice details", mode: .mail,
                  requiredContextKeys: ["sport", "dateTime"], modalComponent: "ViewPracticeInfoModal"),

            // Accept Event
            inApp("accept_school_event", "Accept Event", .veryHigh, "Accept school event invitation and add to calendar", mode: .mail,
                  requiredContextKeys: ["event", "dateTime"], modalComponent: "AcceptEventModal"),

            // View Announcement
            inApp("view_team_announcement", "View Announcement", .veryHigh, "View team announcement details", mode: .mail,
                  requiredContextKeys: ["sport", "team"], modalComponent: "ViewAnnouncementModal"),

            // Add to Calendar
            inApp("add_activity_to_calendar", "Add to Calendar", .medium, "Add activity to calendar", mode: .mail,
                  requiredContextKeys: ["date"], modalComponent: "AddtoCalendarModal"),

            // === THREAD FINDER ACTIONS ===

            // View Extracted Content
            inApp("view_extracted_content", "View Extracted Content", .veryHigh, "View automatically extracted data from link (Thread Finder)", mode: .mail,
                  requiredContextKeys: ["extractedContent"], modalComponent: "ViewExtractedContentModal"),

            // Retry Extraction
            inApp("schedule_extraction_retry", "Retry Extraction", .medium, "Retry automatic data extraction (Thread Finder)", mode: .mail,
                  requiredContextKeys: ["link"], modalComponent: "RetryExtractionModal"),
        ]
    }

    // MARK: - Ads Mode Actions

    private var adsModeActions: [ActionConfig] {
        [
            // Browse Shopping
            inApp("browse_shopping", "Browse Shopping", .medium, "Browse shopping products", mode: .ads,
                  optionalContextKeys: ["productUrl", "category", "query"], modalComponent: "BrowseShoppingModal", modalConfigJSON: "browse_shopping"),

            // Schedule Purchase (PREMIUM)
            inApp("schedule_purchase", "Buy on {saleDateShort}", .mediumHigh, "Schedule future purchase with reminder", mode: .ads,
                  optionalContextKeys: ["productName", "price", "purchaseDate"], modalConfigJSON: "scheduled_purchase", requiredPermission: .premium),

            // View Newsletter Summary (PREMIUM - AI-powered)
            inApp("view_newsletter_summary", "View Summary", .mediumLow, "View AI-generated newsletter summary", mode: .ads,
                  optionalContextKeys: ["summaryText", "topLinks"], modalConfigJSON: "newsletter_summary", requiredPermission: .premium),

            // Unsubscribe (PREMIUM - one-tap unsubscribe)
            goTo("unsubscribe", "Unsubscribe", ["unsubscribeUrl"], .high, "Unsubscribe from mailing list", mode: .ads,
                 confirmationRequirement: .undoable(config: UndoConfig(toastMessage: "Unsubscribed. Tap to undo.")), modalConfigJSON: "unsubscribe"),

            // Shop Now
            goTo("shop_now", "Shop Now", ["shopUrl"], .medium, "Open shopping link", mode: .ads,
                 optionalContextKeys: ["productUrl"]),

            // View Offer / Check Offer
            goTo("view_offer", "Check Offer", ["offerUrl"], .medium, "View offer details", mode: .ads,
                 optionalContextKeys: ["productUrl", "dealUrl"]),

            // Claim Deal (Shopping Automation)
            inApp("claim_deal", "Claim Deal", .mediumHigh, "Automatically add product to cart using Steel.dev browser automation", mode: .ads,
                  requiredContextKeys: ["productUrl"], optionalContextKeys: ["productName", "dealUrl", "promoCode"], modalComponent: "ShoppingAutomationModal"),

            // Cancel Subscription
            inApp("cancel_subscription", "Cancel Subscription", .high, "Cancel subscription service", mode: .ads,
                  optionalContextKeys: ["serviceName", "cancellationUrl"], modalConfigJSON: "cancel_subscription",
                  confirmationRequirement: .undoable(config: UndoConfig(toastMessage: "Subscription cancelled. Tap to undo."))),
        ]
    }

    // MARK: - Shared Actions (Both Modes)

    private var sharedActions: [ActionConfig] {
        [
            // View Details (generic fallback)
            inApp("view_details", "View Details", .veryLow, "View email details", mode: .both,
                  modalComponent: "ViewDetailsModal"),

            // Native iOS: Add to Wallet
            inApp("add_to_wallet", "Add to Wallet", .high, "Add pass to Apple Wallet", mode: .both,
                  optionalContextKeys: ["passUrl", "passType"], modalConfigJSON: "add_to_wallet"),

            // Native iOS: Save Contact
            inApp("save_contact_native", "Save Contact", .mediumLow, "Save contact to iOS Contacts", mode: .both,
                  optionalContextKeys: ["name", "email", "phone"], modalConfigJSON: "save_contact"),

            // Native iOS: Send Message
            inApp("send_message", "Send Message", .medium, "Send SMS/iMessage", mode: .both,
                  optionalContextKeys: ["phoneNumber", "message"], modalConfigJSON: "send_message"),

            // Native iOS: Share
            inApp("share", "Share", .low, "Share via iOS share sheet", mode: .both,
                  requiredContextKeys: ["content"], fallbackBehavior: .doNothing, modalConfigJSON: "share"),

            // Open App
            inApp("open_app", "Open App", .mediumLow, "Open external app", mode: .both,
                  optionalContextKeys: ["appUrl", "appName"], modalConfigJSON: "open_app"),

            // View Reservation
            inApp("view_reservation", "View Reservation", .medium, "View reservation details",
                mode: .both,
                optionalContextKeys: ["reservationNumber", "venue", "date"],
                modalComponent: "ReservationModal",
                modalConfigJSON: "reservation"
            ),

            // === COMMUNICATION & FEEDBACK ===

            // Accept Invitation
            inApp("rsvp_yes", "Accept Invitation", .veryHigh, "Accept invitation",
                mode: .both,
                modalComponent: "AcceptInvitationModal",
                modalConfigJSON: "rsvp"
            ),

            // Decline Invitation
            inApp("rsvp_no", "Decline Invitation", .medium, "Decline invitation",
                mode: .both,
                modalComponent: "DeclineInvitationModal",
                modalConfigJSON: "rsvp",
                confirmationRequirement: .undoable(
                    config: UndoConfig(toastMessage: "Invitation declined. Tap to undo.", undoActionId: "rsvp_yes")
                )
            ),

            // Reply to Thread
            inApp("reply_to_thread", "Reply", .veryHigh, "Reply to email thread",
                mode: .both,
                modalComponent: "ReplyModal"
            ),

            // View Introduction
            inApp("view_introduction", "View Introduction", .veryHigh, "View introduction details",
                mode: .both,
                requiredContextKeys: ["introducedPerson"],
                modalComponent: "ViewIntroductionModal"
            ),

            // Add to Notes
            inApp("add_to_notes", "Add to Notes", .veryHigh, "Save email content to iOS Notes app",
                mode: .both,
                modalComponent: "AddtoNotesModal",
                modalConfigJSON: "add_to_notes"
            ),

            // Say Thanks
            inApp("reply_thanks", "Say Thanks", .high, "Send quick thank you reply",
                mode: .both,
                requiredContextKeys: ["sender"],
                modalComponent: "SayThanksModal"
            ),

            // === SHOPPING & E-COMMERCE ===

            // Copy Code
            inApp("copy_promo_code", "Copy Code", .high, "Copy promo code",
                mode: .both,
                requiredContextKeys: ["promoCode"],
                modalComponent: "CopyCodeModal"
            ),

            // Add to Cart & Checkout
            inApp("automated_add_to_cart", "Add to Cart & Checkout", .veryHigh, "AI agent adds item to cart and opens checkout",
                mode: .both,
                requiredContextKeys: ["productUrl", "productName"],
                modalComponent: "AddtoCart&CheckoutModal"
            ),

            // Rate Product
            inApp("rate_product", "Rate Product", .high, "Quick star rating",
                mode: .both,
                requiredContextKeys: ["productName"],
                modalComponent: "RateProductModal"
            ),

            // Set Price Alert
            inApp("set_price_alert", "Set Price Alert", .high, "Get notified of price changes",
                mode: .both,
                requiredContextKeys: ["productName"],
                modalComponent: "SetPriceAlertModal"
            ),

            // Notify When Back
            inApp("notify_restock", "Notify When Back", .high, "Get notified when item restocks",
                mode: .both,
                requiredContextKeys: ["productName"],
                modalComponent: "NotifyWhenBackModal"
            ),

            // === DELIVERY & LOGISTICS ===

            // Provide Access Code
            inApp("provide_access_code", "Provide Access Code", .medium, "Provide building or gate access code for delivery",
                mode: .both,
                requiredContextKeys: ["trackingNumber"],
                modalComponent: nil,
                modalConfigJSON: "provide_access_code"
            ),

            // === SUPPORT & SUBSCRIPTION ===

            // Reply to Ticket
            inApp("reply_to_ticket", "Reply", .high, "Reply to support ticket",
                mode: .both,
                requiredContextKeys: ["ticketId"],
                modalComponent: "ReplyModal"
            ),

            // View Benefits
            inApp("view_benefits", "View Benefits", .veryHigh, "View subscription benefits and rewards",
                mode: .both,
                requiredContextKeys: ["serviceName"],
                modalComponent: "ViewBenefitsModal"
            ),

            // === FINANCE ===

            // Schedule Payment
            inApp("schedule_payment", "Schedule Payment", .high, "Schedule automatic payment",
                mode: .both,
                requiredContextKeys: ["amountDue", "dueDate"],
                modalComponent: "SchedulePaymentModal",
                confirmationRequirement: .confirmWithUndo(
                    confirmation: "Schedule ${amountDue} payment for {dueDate}?",
                    undo: UndoConfig(toastMessage: "Payment scheduled. Tap to undo.")
                )
            ),

            // === UTILITY ===

            // View Preparation Tips
            inApp("prepare_for_outage", "View Preparation Tips", .high, "View tips to prepare for power outage",
                mode: .both,
                modalComponent: "PrepareForOutageModal",
                modalConfigJSON: "prepare_for_outage"
            ),

            // Set Outage Reminder
            inApp("set_outage_reminder", "Set Reminder", .medium, "Remind before planned outage",
                mode: .both,
                requiredContextKeys: ["outageStart"],
                modalComponent: "SetReminderModal"
            ),

            // === PROFESSIONAL SERVICES ===

            // View Mortgage Details
            inApp("view_mortgage_details", "View Mortgage Details", .veryHigh, "View mortgage or refinancing details",
                mode: .both,
                modalComponent: "ViewMortgageDetailsModal"
            ),

            // View Legal Document
            inApp("view_legal_document", "View Document", .veryHigh, "View legal document details",
                mode: .both,
                modalComponent: "ViewDocumentModal"
            ),
        ]
    }

    // MARK: - GO_TO Actions (External URLs)

    private var goToActions: [ActionConfig] {
        [
            // Basic actions
            goTo("view_order", "View Order", ["orderUrl"], .medium, "View order details online", optionalContextKeys: ["orderNumber"]),
            goTo("manage_subscription", "Manage Subscription", ["subscriptionUrl"], .medium, "Manage subscription settings"),
            goTo("view_itinerary", "View Itinerary", ["itineraryUrl"], .mediumHigh, "View travel itinerary"),
            goTo("get_directions", "Get Directions", ["directionsUrl"], .mediumHigh, "Get directions to location", optionalContextKeys: ["mapUrl", "address"]),
            goTo("open_link", "Open Link", ["url"], .veryLow, "Open generic URL"),

            // === ACCOUNT ACTIONS ===
            goTo("reset_password", "Reset Password", ["url", "resetLink"], .veryHigh, "Reset account password"),
            goTo("review_security", "Review Security", ["url"], .veryHigh, "Review security settings", optionalContextKeys: ["securityUrl"]),
            goTo("revoke_secret", "Revoke Secret", ["url", "actionUrl"], .veryHigh, "Revoke exposed API key or secret",
                confirmationRequirement: .detailed(title: "Revoke API Key", message: "This will immediately revoke the exposed API key or secret. Any services using this key will stop working.", confirmText: "Revoke Key", cancelText: "Cancel")),
            goTo("verify_account", "Verify Account", ["url", "verificationLink"], .veryHigh, "Verify email or account", modalConfigJSON: "verify_account"),
            goTo("verify_device", "Verify Device", ["url"], .veryHigh, "Verify new device login", optionalContextKeys: ["verificationUrl"]),

            // === BILLING ACTIONS ===
            goTo("download_receipt", "Download Receipt", ["url", "receiptUrl"], .high, "Download payment receipt"),
            goTo("update_payment", "Update Payment", ["url"], .high, "Update payment method", optionalContextKeys: ["paymentUrl"], modalConfigJSON: "update_payment"),
            goTo("view_invoice", "View Invoice", ["url"], .high, "View invoice details", optionalContextKeys: ["invoiceUrl", "invoiceId"]),

            // === CAREER ACTIONS ===
            goTo("accept_offer", "Accept Offer", ["url", "offerUrl"], .veryHigh, "Accept job offer", optionalContextKeys: ["company", "position"],
                confirmationRequirement: .detailed(title: "Accept Job Offer", message: "This will formally accept your job offer. Make sure you've reviewed all terms and conditions before proceeding.", confirmText: "Accept Offer", cancelText: "Review Again")),
            goTo("check_application_status", "Check Status", ["url"], .veryHigh, "Check application status", optionalContextKeys: ["applicationUrl", "company", "position"]),
            goTo("schedule_interview", "Schedule Interview", ["url", "interviewUrl"], .veryHigh, "Schedule interview time", optionalContextKeys: ["company", "position"]),
            goTo("view_job_details", "View Job Details", ["url"], .high, "View detailed job description", optionalContextKeys: ["jobUrl"]),
            goTo("buy_again", "Buy Again", ["url", "orderNumber"], .high, "Reorder the same items"),
            goTo("return_item", "Return Item", ["url", "orderNumber"], .veryHigh, "Initiate return process"),
            goTo("join_meeting", "Join Meeting", ["url", "meetingUrl"], .veryHigh, "Join video meeting"),
            goTo("register_event", "Register", ["url", "registrationLink"], .veryHigh, "Register for event"),
            goTo("modify_reservation", "Modify Reservation", ["url", "confirmationCode"], .high, "Modify restaurant reservation"),
            goTo("track_delivery", "Track Delivery", ["url", "trackingUrl"], .veryHigh, "Track food delivery in real-time"),
            goTo("change_delivery_preferences", "Change Preferences", ["url"], .high, "Update delivery time or location preferences"),

            // Mail-mode actions
            goTo("view_lms_message", "View Message", ["url", "messageUrl"], .veryHigh, "View Canvas/Classroom message from teacher", mode: .mail),
            goTo("reply_to_teacher", "Reply to Teacher", ["url", "teacher"], .high, "Reply to teacher message", mode: .mail),
            goTo("submit_assignment", "Submit Assignment", ["url", "assignmentUrl"], .veryHigh, "Go to assignment submission page", mode: .mail),
            goTo("register_for_sports", "Register", ["url", "registrationUrl"], .veryHigh, "Register for youth sports or activity", mode: .mail),
            goTo("view_game_schedule", "View Schedule", ["url"], .veryHigh, "View game schedule", mode: .mail),
            goTo("rsvp_game", "RSVP to Game", ["url"], .high, "RSVP for game attendance", mode: .mail),
            goTo("rsvp_school_event", "RSVP to Event", ["url"], .high, "RSVP for school event", mode: .mail),

            // More basic actions
            goTo("manage_booking", "Manage Booking", ["url", "confirmationCode"], .medium, "Manage reservation"),
            goTo("take_survey", "Take Survey", ["url", "surveyLink"], .veryHigh, "Complete survey"),
            goTo("view_product", "View Product", ["url", "productUrl"], .veryHigh, "View product details"),
            goTo("complete_cart", "Complete Order", ["url", "cartUrl"], .veryHigh, "Complete cart checkout"),
            goTo("redeem_rewards", "Redeem Rewards", ["url"], .veryHigh, "Redeem loyalty points or rewards"),
            goTo("view_announcement", "View Announcement", ["url"], .veryHigh, "View brand announcement details"),
            goTo("contact_support", "Contact Support", ["url"], .mediumLow, "Contact customer support"),

            // Medical appointments
            goTo("book_appointment", "Book Appointment", ["url"], .veryHigh, "Schedule or book a new appointment", mode: .mail),
            goTo("confirm_appointment", "Confirm Appointment", ["url"], .veryHigh, "Confirm medical appointment", mode: .mail),
            goTo("reschedule_appointment", "Reschedule", ["url"], .veryHigh, "Reschedule appointment", mode: .mail),
            goTo("download_results", "Download Results", ["url", "resultsUrl"], .veryHigh, "Download medical test results", mode: .mail),
            goTo("view_referral", "View Referral", ["url"], .veryHigh, "View specialist referral details", mode: .mail),
            goTo("schedule_test", "Schedule Test", ["url"], .veryHigh, "Schedule medical test or lab work", mode: .mail),
            goTo("view_claim_status", "View Claim", ["url", "claimNumber"], .veryHigh, "View insurance claim status", mode: .mail),

            // Financial actions
            goTo("view_statement", "View Statement", ["url", "accountId"], .veryHigh, "View financial statement"),
            goTo("update_payment_method", "Update Payment", ["url"], .veryHigh, "Update payment method", modalConfigJSON: "update_payment"),
            goTo("download_tax_document", "Download Tax Form", ["url", "taxYear"], .veryHigh, "Download tax document"),
            goTo("dispute_transaction", "Dispute Transaction", ["url"], .veryHigh, "Report fraudulent transaction"),
            goTo("view_credit_report", "View Credit Report", ["url"], .veryHigh, "View credit score and report"),
            goTo("view_portfolio", "View Portfolio", ["url", "accountId"], .veryHigh, "View investment portfolio"),
            goTo("verify_transaction", "Verify Transaction", ["url"], .veryHigh, "Verify suspicious transaction"),

            // Shipping and returns
            goTo("track_return", "Track Return", ["url", "orderNumber"], .veryHigh, "Track return shipment status"),
            goTo("print_return_label", "Print Label", ["url", "orderNumber"], .veryHigh, "Print return shipping label"),
            goTo("view_refund_status", "View Refund", ["url", "refundAmount"], .veryHigh, "View refund processing status"),
            goTo("reorder_item", "Reorder", ["url", "productName"], .veryHigh, "Reorder out-of-stock item"),
            goTo("view_warranty", "View Warranty", ["url", "productName"], .veryHigh, "View warranty details"),

            // Utilities and services
            goTo("view_outage_details", "View Outage Info", ["url"], .veryHigh, "View power outage details and affected areas"),
            goTo("schedule_delivery_time", "Schedule Delivery", ["url"], .veryHigh, "Choose delivery time window"),

            // Real estate
            goTo("view_property_listings", "View Homes", ["url"], .veryHigh, "View recommended property listings"),
            goTo("save_properties", "Save Favorites", ["url"], .high, "Save properties to favorites"),
            goTo("schedule_showing", "Schedule Tour", ["url"], .high, "Schedule property showing"),

            // Social and community
            goTo("read_community_post", "Read Post", ["url"], .veryHigh, "Read community post"),
            goTo("view_post_comments", "View Comments", ["url"], .high, "Read post comments and discussion"),
            goTo("reply_to_post", "Reply", ["url"], .medium, "Reply to community post"),
            goTo("view_activity_details", "View Activity", ["url"], .veryHigh, "View educational activity details", mode: .mail),
            goTo("book_activity_tickets", "Book Tickets", ["url"], .high, "Book tickets for activity", mode: .mail),

            // === CIVIC, EDUCATION, FINANCE, REAL ESTATE, SOCIAL, SUBSCRIPTION ===
            goTo("apply_for_permit", "Apply for Permit", ["url", "applicationUrl"], .medium, "Apply for government permit",
                confirmationRequirement: .simple(message: "Submit permit application? This will begin the official application process.")),
            goTo("confirm_court_appearance", "Confirm Appearance", ["url", "confirmationUrl"], .medium, "Confirm court appearance or jury duty",
                confirmationRequirement: .detailed(title: "Confirm Court Appearance", message: "This will confirm your attendance for court or jury duty. This action cannot be undone.", confirmText: "Confirm Appearance", cancelText: "Cancel")),
            goTo("pay_property_tax", "Pay Property Tax", ["url", "paymentUrl"], .medium, "Pay property tax bill",
                confirmationRequirement: .confirmWithUndo(confirmation: "Confirm property tax payment?", undo: UndoConfig(toastMessage: "Tax payment initiated. Tap to undo."))),
            goTo("register_to_vote", "Register to Vote", ["url", "registrationUrl"], .medium, "Complete voter registration"),
            goTo("renew_license", "Renew License", ["url", "renewalUrl"], .medium, "Renew driver license or ID"),
            goTo("view_ballot", "View Ballot", ["url", "guideUrl"], .medium, "View sample ballot and voting guide"),
            goTo("download_attachment", "Download Attachment", ["url", "attachmentUrl"], .mediumLow, "Download assignment attachment (PDF, worksheet, rubric)"),
            goTo("open_original_link", "Open Original Link", ["url", "link"], .mediumLow, "Open the original link in browser"),
            goTo("pay_utility_bill", "Pay Bill", ["url", "billUrl"], .medium, "Pay utility bill online",
                confirmationRequirement: .confirmWithUndo(confirmation: "Confirm utility bill payment?", undo: UndoConfig(toastMessage: "Bill payment sent. Tap to undo."))),
            goTo("schedule_inspection", "Schedule Inspection", ["url", "schedulingUrl"], .medium, "Schedule real estate inspection"),
            goTo("accept_social_invitation", "Accept Invitation", ["url", "invitationLink"], .low, "Accept social platform invitation"),
            goTo("share_achievement", "Share Activity", ["url", "activityUrl"], .low, "Share fitness achievement on social media"),
            goTo("verify_social_account", "Verify Account", ["url", "verificationLink"], .low, "Verify social platform account"),
            goTo("view_activity", "View Activity", ["url", "activityUrl"], .low, "View fitness activity that received kudos"),
            goTo("view_social_message", "View Message", ["url", "messageUrl"], .low, "View social platform message"),
            goTo("cancel_subscription_service", "Cancel Service", ["url", "cancellationUrl"], .medium, "Cancel subscription service"),
            goTo("extend_trial", "Extend Trial", ["url", "extensionUrl"], .mediumLow, "Extend free trial period"),
            goTo("upgrade_subscription", "Upgrade Now", ["url", "upgradeUrl"], .medium, "Upgrade subscription plan"),
            goTo("view_usage", "View Usage", ["url", "usageUrl"], .mediumLow, "View subscription usage details"),
        ]
    }

    // Helper function for GO_TO actions
    private func goTo(
        _ actionId: String,
        _ displayName: String,
        _ requiredContextKeys: [String],
        _ priority: ActionPriority,
        _ description: String,
        mode: ZeroMode = .both,
        optionalContextKeys: [String] = [],
        confirmationRequirement: ConfirmationRequirement = .none,
        modalConfigJSON: String? = nil
    ) -> ActionConfig {
        ActionConfig(
            actionId: actionId,
            displayName: displayName,
            actionType: .goTo,
            mode: mode,
            modalComponent: nil,
            requiredContextKeys: requiredContextKeys,
            optionalContextKeys: optionalContextKeys,
            fallbackBehavior: .showError,
            analyticsEvent: "action_\(actionId)",
            priority: priority,
            description: description,
            confirmationRequirement: confirmationRequirement,
            modalConfigJSON: modalConfigJSON
        )
    }

    // Helper function for IN_APP actions
    private func inApp(
        _ actionId: String,
        _ displayName: String,
        _ priority: ActionPriority,
        _ description: String,
        mode: ZeroMode,
        requiredContextKeys: [String] = [],
        optionalContextKeys: [String] = [],
        fallbackBehavior: ActionConfig.FallbackBehavior = .showError,
        modalComponent: String? = nil,
        modalConfigJSON: String? = nil,
        requiredPermission: ActionPermission = .free,
        confirmationRequirement: ConfirmationRequirement = .none
    ) -> ActionConfig {
        ActionConfig(
            actionId: actionId,
            displayName: displayName,
            actionType: .inApp,
            mode: mode,
            modalComponent: modalComponent,
            requiredContextKeys: requiredContextKeys,
            optionalContextKeys: optionalContextKeys,
            fallbackBehavior: fallbackBehavior,
            analyticsEvent: "action_\(actionId)",
            priority: priority,
            description: description,
            requiredPermission: requiredPermission,
            confirmationRequirement: confirmationRequirement,
            modalConfigJSON: modalConfigJSON
        )
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
    /// Phase 3 Optimized: Uses pre-merged JSON+Swift registry
    /// Registry is initialized once with JSON actions taking priority over Swift
    /// This provides O(1) dictionary lookup instead of repeated JSON parsing
    func getAction(_ actionId: String) -> ActionConfig? {
        return registry[actionId]
    }

    /// Get all actions for a specific mode
    /// Phase 3 Optimized: Uses pre-merged registry (no JSON parsing)
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

        return validateAction(action, context: context)
    }

    /// Week 5 Performance: Optimized version that accepts ActionConfig to avoid repeated lookups
    func validateAction(_ actionConfig: ActionConfig, context: [String: String]?) -> ValidationResult {
        let providedKeys = Set(context?.keys.map { $0 } ?? [])
        let requiredKeys = Set(actionConfig.requiredContextKeys)
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

    /// Week 5 Performance: Optimized version that accepts ActionConfig to avoid repeated lookups
    func isActionValidForMode(_ actionConfig: ActionConfig, currentMode: CardType) -> Bool {
        // Convert CardType to ZeroMode
        let zeroMode: ZeroMode = currentMode == .mail ? .mail : .ads

        return actionConfig.mode == zeroMode || actionConfig.mode == .both
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
