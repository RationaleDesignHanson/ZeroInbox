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
    let priority: Int  // Higher = more important
    let description: String?

    // v2.1 - Enhanced Validation
    let featureFlag: String?  // Feature flag key for A/B testing
    let requiredPermission: ActionPermission  // Permission level required
    let availability: ActionAvailability  // Time/condition-based availability

    enum FallbackBehavior: String {
        case showError = "show_error"
        case showToast = "show_toast"
        case openEmailComposer = "open_email_composer"
        case doNothing = "do_nothing"
    }

    /// Initialize with default values for v2.1 fields
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
        priority: Int,
        description: String? = nil,
        featureFlag: String? = nil,
        requiredPermission: ActionPermission = .free,
        availability: ActionAvailability = .alwaysAvailable
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
                priority: 90,
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
                priority: 95,
                description: "Pay invoice with amount and merchant details",
                requiredPermission: .premium
            ),

            // Check In Flight - High-fidelity modal with flight details (PREMIUM)
            ActionConfig(
                actionId: "check_in_flight",
                displayName: "Check In Flight",
                actionType: .inApp,
                mode: .both,
                modalComponent: "CheckInFlightModal",
                requiredContextKeys: ["flightNumber", "airline"],
                optionalContextKeys: ["checkInUrl", "departureTime", "gate", "seat"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_check_in_flight",
                priority: 95,
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
                priority: 70,
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
                priority: 85,
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
                priority: 80,
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
                priority: 95,
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
                priority: 85,
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
                priority: 80,
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
                priority: 75,
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
                priority: 70,
                description: "Add reminder to iOS Reminders"
            ),

            // Set Reminder (generic)
            ActionConfig(
                actionId: "set_reminder",
                displayName: "Set Reminder",
                actionType: .inApp,
                mode: .mail,
                modalComponent: "AddReminderModal",
                requiredContextKeys: [],
                optionalContextKeys: ["dueDate", "reminderText"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_set_reminder",
                priority: 70,
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
                priority: 75,
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
                priority: 70,
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
                priority: 65,
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
                priority: 80,
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
                priority: 70,
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
                priority: 70,
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
                priority: 85,
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
                priority: 80,
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
                priority: 75,
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
                priority: 90,
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
                priority: 85,
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
                priority: 85,
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
                priority: 90,
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
                priority: 95,
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
                priority: 95,
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
                priority: 90,
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
                priority: 80,
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
                priority: 90,
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
                priority: 75,
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
                priority: 70,
                description: "Route lead to CRM system"
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
                priority: 75,
                description: "Browse shopping products"
            ),

            // Schedule Purchase (PREMIUM)
            ActionConfig(
                actionId: "schedule_purchase",
                displayName: "Schedule Purchase",
                actionType: .inApp,
                mode: .ads,
                modalComponent: "ScheduledPurchaseModal",
                requiredContextKeys: [],
                optionalContextKeys: ["productName", "price", "purchaseDate"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_schedule_purchase",
                priority: 80,
                description: "Schedule future purchase with reminder",
                requiredPermission: .premium
            ),

            // View Newsletter Summary (PREMIUM - AI-powered)
            ActionConfig(
                actionId: "view_newsletter_summary",
                displayName: "View Newsletter Summary",
                actionType: .inApp,
                mode: .ads,
                modalComponent: "NewsletterSummaryModal",
                requiredContextKeys: [],
                optionalContextKeys: ["summaryText", "topLinks"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_view_newsletter_summary",
                priority: 70,
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
                priority: 85,
                description: "Unsubscribe from mailing list",
                requiredPermission: .premium
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
                priority: 75,
                description: "Open shopping link"
            ),

            // Claim Deal
            ActionConfig(
                actionId: "claim_deal",
                displayName: "Claim Deal",
                actionType: .goTo,
                mode: .ads,
                modalComponent: nil,
                requiredContextKeys: ["dealUrl"],
                optionalContextKeys: ["promoCode"],
                fallbackBehavior: .showError,
                analyticsEvent: "action_claim_deal",
                priority: 80,
                description: "Claim promotional deal"
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
                priority: 85,
                description: "Cancel subscription service"
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
                priority: 60,
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
                priority: 85,
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
                priority: 70,
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
                priority: 75,
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
                priority: 65,
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
                priority: 70,
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
                priority: 75,
                description: "View reservation details"
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
                priority: 75,
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
                priority: 75,
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
                priority: 80,
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
                priority: 80,
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
                priority: 60,
                description: "Open generic URL"
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
