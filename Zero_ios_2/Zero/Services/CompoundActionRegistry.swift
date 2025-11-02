import Foundation

/**
 * CompoundActionRegistry
 * Defines all multi-step action flows with end behavior rules
 * Backend decides if compound action is primary based on email context
 *
 * Business Rules:
 * - "requiresResponse" = true → ends with email composer
 * - "requiresResponse" = false → returns to app or dismisses
 * - Backend sets isPrimary based on intent confidence and context completeness
 */

struct CompoundActionDefinition {
    let actionId: String
    let displayName: String
    let steps: [String]  // Ordered list of step actionIds
    let endBehavior: CompoundEndBehavior
    let requiresResponse: Bool  // Determines if email composer is needed
    let isPremium: Bool
    let description: String

    enum CompoundEndBehavior {
        case emailComposer(template: EmailComposerTemplate)
        case dismissWithSuccess
        case returnToApp
    }

    struct EmailComposerTemplate {
        let subjectPrefix: String
        let bodyTemplate: String
        let includeOriginalSender: Bool
    }
}

class CompoundActionRegistry {
    static let shared = CompoundActionRegistry()

    private init() {}

    // MARK: - Compound Action Definitions

    private(set) lazy var compoundActions: [String: CompoundActionDefinition] = {
        var actions: [String: CompoundActionDefinition] = [:]

        allCompoundActions.forEach { action in
            actions[action.actionId] = action
        }

        return actions
    }()

    private var allCompoundActions: [CompoundActionDefinition] {
        [
            // MARK: - EDUCATION & CHILDCARE COMPOUND FLOWS

            // Sign form → Pay fee → Email confirmation (EXISTING - enhanced)
            CompoundActionDefinition(
                actionId: "sign_form_with_payment",
                displayName: "Sign & Pay Permission Form",
                steps: ["sign_form", "pay_form_fee", "email_composer"],
                endBehavior: .emailComposer(template: CompoundActionDefinition.EmailComposerTemplate(
                    subjectPrefix: "Re: Permission Form - Signed & Paid",
                    bodyTemplate: "Hi {sender_name},\n\nI've signed the permission form and completed the ${amount} payment via {payment_method}.\n\nThank you!",
                    includeOriginalSender: true
                )),
                requiresResponse: true,  // Permission slips need confirmation
                isPremium: true,
                description: "Sign permission form, pay associated fee, send email confirmation to sender"
            ),

            // Sign form → Add to calendar → Email confirmation (NEW - childcare events)
            CompoundActionDefinition(
                actionId: "sign_form_with_calendar",
                displayName: "Sign Form & Add to Calendar",
                steps: ["sign_form", "add_to_calendar", "email_composer"],
                endBehavior: .emailComposer(template: CompoundActionDefinition.EmailComposerTemplate(
                    subjectPrefix: "Re: {form_name} - Signed & Calendar Updated",
                    bodyTemplate: "Hi {sender_name},\n\nI've signed the form and added the event to my calendar for {event_date}.\n\nLooking forward to it!",
                    includeOriginalSender: true
                )),
                requiresResponse: true,  // School forms with events need confirmation
                isPremium: true,
                description: "Sign form (e.g., field trip), add event to calendar, confirm attendance with sender"
            ),

            // Sign form → Email confirmation (basic permission form flow)
            CompoundActionDefinition(
                actionId: "sign_and_send",
                displayName: "Sign & Send",
                steps: ["sign_form", "email_composer"],
                endBehavior: .emailComposer(template: CompoundActionDefinition.EmailComposerTemplate(
                    subjectPrefix: "Re: {form_name} - Signed",
                    bodyTemplate: "Hi {sender_name},\n\nI've signed the form and it's ready to go.\n\nThank you!",
                    includeOriginalSender: true
                )),
                requiresResponse: true,  // Permission forms need confirmation
                isPremium: false,  // Basic sign and send is free
                description: "Sign permission form and send confirmation email to sender (basic permission form flow)"
            ),

            // MARK: - SHOPPING COMPOUND FLOWS

            // Track package → Add to calendar (NEW - delivery planning)
            CompoundActionDefinition(
                actionId: "track_with_calendar",
                displayName: "Track Package & Schedule Delivery",
                steps: ["track_package", "add_to_calendar"],
                endBehavior: .returnToApp,  // No response needed - personal action
                requiresResponse: false,
                isPremium: true,
                description: "View package tracking info, add estimated delivery date/time to calendar for planning"
            ),

            // Schedule purchase → Add to calendar (NEW - sale reminders)
            CompoundActionDefinition(
                actionId: "schedule_purchase_with_reminder",
                displayName: "Schedule Purchase with Calendar Reminder",
                steps: ["schedule_purchase", "add_to_calendar"],
                endBehavior: .returnToApp,  // No response needed - personal planning
                requiresResponse: false,
                isPremium: true,
                description: "Set reminder for product launch/sale, add notification to calendar 15min before"
            ),

            // MARK: - PAYMENT COMPOUND FLOWS

            // Pay invoice → Email receipt confirmation (NEW - bill payments)
            CompoundActionDefinition(
                actionId: "pay_invoice_with_confirmation",
                displayName: "Pay Invoice & Send Confirmation",
                steps: ["pay_invoice", "email_composer"],
                endBehavior: .emailComposer(template: CompoundActionDefinition.EmailComposerTemplate(
                    subjectPrefix: "Re: Invoice {invoice_id} - Payment Sent",
                    bodyTemplate: "Hi {merchant},\n\nI've completed payment of {amount} for invoice {invoice_id} via {payment_method}.\n\nPlease confirm receipt.\n\nThank you!",
                    includeOriginalSender: true
                )),
                requiresResponse: true,  // Payment confirmations need response from merchant
                isPremium: true,
                description: "Complete invoice payment, send confirmation email to merchant requesting receipt"
            ),

            // MARK: - TRAVEL COMPOUND FLOWS

            // Check in flight → Add to wallet (NEW - boarding passes)
            CompoundActionDefinition(
                actionId: "check_in_with_wallet",
                displayName: "Check In & Add Boarding Pass to Wallet",
                steps: ["check_in_flight", "add_to_wallet"],
                endBehavior: .returnToApp,  // No response needed - personal action
                requiresResponse: false,
                isPremium: true,
                description: "Check in for flight online, add boarding pass to Apple Wallet for easy access"
            ),

            // MARK: - CALENDAR COMPOUND FLOWS

            // Add to calendar → Set reminder (NEW - event prep)
            CompoundActionDefinition(
                actionId: "calendar_with_reminder",
                displayName: "Add to Calendar with Pre-Event Reminder",
                steps: ["add_to_calendar", "add_reminder"],
                endBehavior: .returnToApp,  // No response needed - personal planning
                requiresResponse: false,
                isPremium: false,  // Basic calendar functionality - keep free
                description: "Add event to iOS Calendar, set reminder (default 15min before event start)"
            ),

            // MARK: - SUBSCRIPTION COMPOUND FLOWS

            // Cancel subscription → Email confirmation (NEW - cancellation confirmation)
            CompoundActionDefinition(
                actionId: "cancel_with_confirmation",
                displayName: "Cancel Subscription & Request Confirmation",
                steps: ["cancel_subscription", "email_composer"],
                endBehavior: .emailComposer(template: CompoundActionDefinition.EmailComposerTemplate(
                    subjectPrefix: "Re: Subscription Cancellation Request",
                    bodyTemplate: "Hi {service_name} Support,\n\nI'd like to cancel my subscription as discussed. Please confirm the cancellation and let me know the final billing date.\n\nThank you!",
                    includeOriginalSender: true
                )),
                requiresResponse: true,  // Cancellation requests need confirmation from service
                isPremium: false,  // Keep unsubscribe/cancel flow free (customer-friendly)
                description: "Cancel subscription, send confirmation request to service support team"
            )
        ]
    }

    // MARK: - Query Methods

    /// Get compound action definition by ID
    func getCompoundAction(_ actionId: String) -> CompoundActionDefinition? {
        return compoundActions[actionId]
    }

    /// Check if action is compound
    func isCompoundAction(_ actionId: String) -> Bool {
        return compoundActions[actionId] != nil
    }

    /// Get all compound actions requiring email composer (requiresResponse = true)
    func getCompoundActionsRequiringResponse() -> [CompoundActionDefinition] {
        return compoundActions.values.filter { $0.requiresResponse }
    }

    /// Get all compound actions that return to app (requiresResponse = false)
    func getPersonalCompoundActions() -> [CompoundActionDefinition] {
        return compoundActions.values.filter { !$0.requiresResponse }
    }

    /// Get all premium compound actions
    func getPremiumCompoundActions() -> [CompoundActionDefinition] {
        return compoundActions.values.filter { $0.isPremium }
    }

    /// Get all free compound actions
    func getFreeCompoundActions() -> [CompoundActionDefinition] {
        return compoundActions.values.filter { !$0.isPremium }
    }

    /// Get compound action count
    func getCompoundActionCount() -> (total: Int, premium: Int, free: Int, requiresResponse: Int) {
        let total = compoundActions.count
        let premium = compoundActions.values.filter { $0.isPremium }.count
        let free = compoundActions.values.filter { !$0.isPremium }.count
        let requiresResponse = compoundActions.values.filter { $0.requiresResponse }.count

        return (total: total, premium: premium, free: free, requiresResponse: requiresResponse)
    }

    /// Get all compound action IDs
    func getAllCompoundActionIds() -> [String] {
        return Array(compoundActions.keys).sorted()
    }

    /// Validate compound action steps against ActionRegistry
    func validateCompoundAction(_ actionId: String, registry: ActionRegistry) -> (isValid: Bool, missingActions: [String]) {
        guard let compound = getCompoundAction(actionId) else {
            return (isValid: false, missingActions: [])
        }

        var missingActions: [String] = []

        for stepActionId in compound.steps {
            if registry.getAction(stepActionId) == nil {
                missingActions.append(stepActionId)
            }
        }

        return (isValid: missingActions.isEmpty, missingActions: missingActions)
    }
}

// MARK: - Registry Statistics

extension CompoundActionRegistry {
    /// Get statistics for debugging and admin dashboard
    func getStatistics() -> CompoundRegistryStatistics {
        let counts = getCompoundActionCount()

        return CompoundRegistryStatistics(
            totalCompoundActions: counts.total,
            premiumCompoundActions: counts.premium,
            freeCompoundActions: counts.free,
            requiresResponseCount: counts.requiresResponse,
            personalActionsCount: counts.total - counts.requiresResponse
        )
    }
}

struct CompoundRegistryStatistics {
    let totalCompoundActions: Int
    let premiumCompoundActions: Int
    let freeCompoundActions: Int
    let requiresResponseCount: Int
    let personalActionsCount: Int

    var description: String {
        """
        CompoundActionRegistry Statistics:
        - Total Compound Actions: \(totalCompoundActions)
        - Premium Compound Actions: \(premiumCompoundActions)
        - Free Compound Actions: \(freeCompoundActions)
        - Requires Email Response: \(requiresResponseCount)
        - Personal Actions (no response): \(personalActionsCount)
        """
    }
}
