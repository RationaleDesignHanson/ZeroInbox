import Foundation

/**
 * Action Placeholders Repository
 *
 * Provides placeholder URLs and mock context for actions when real data is missing.
 * Makes flows feel more complete by ensuring every action has a fallback.
 *
 * Usage:
 * - ActionPlaceholders.getPlaceholderURL(for: "track_package")
 * - ActionPlaceholders.getPlaceholderContext(for: "pay_invoice")
 * - ActionPlaceholders.validateActionContext(action)
 */

struct ActionPlaceholders {

    // MARK: - Placeholder URL Generation

    /// Get a placeholder URL for an action type
    /// Returns a realistic-looking URL that demonstrates the action flow
    static func getPlaceholderURL(for actionId: String) -> String {
        switch actionId {
        // Shopping & E-commerce
        case "track_package":
            return "https://www.ups.com/track?tracknum=1Z999AA10123456789"
        case "view_order":
            return "https://www.amazon.com/gp/your-account/order-details?orderID=123-4567890-1234567"
        case "buy_again":
            return "https://www.amazon.com/gp/buy-again/ref=ppx_yo2ov_dt_b_auto_order"
        case "return_item":
            return "https://www.amazon.com/gp/returns/homepage.html"
        case "write_review":
            return "https://www.amazon.com/review/create-review?asin=B0EXAMPLE"
        case "complete_cart":
            return "https://www.amazon.com/gp/cart/view.html"
        case "view_cart":
            return "https://www.rei.com/ShoppingCart"
        case "view_deals":
            return "https://www.target.com/c/top-deals/-/N-4sglm"
        case "shop_now":
            return "https://www.patagonia.com/shop/new-arrivals"
        case "view_product":
            return "https://www.bestbuy.com/site/sony-wh-1000xm5/6505727.p"
        case "claim_deal":
            return "https://www.bestbuy.com/site/promo/black-friday-preview"
        case "compare":
            return "https://camelcamelcamel.com/product/B0EXAMPLE"
        case "rate_product":
            return "https://www.amazon.com/review/create-review"
        case "copy_promo_code":
            return "https://www.retailmenot.com/view/example.com"
        case "schedule_purchase":
            return "https://example.com/shop" // Handled in-app, fallback URL

        // Travel & Hospitality
        case "check_in_flight":
            return "https://www.united.com/ual/en/us/fly/travel/checkin.html"
        case "view_itinerary":
            return "https://www.expedia.com/trips/12345678"
        case "view_reservation":
            return "https://www.opentable.com/my/booking/details?rid=123456"
        case "modify_reservation":
            return "https://www.opentable.com/modify/123456"
        case "manage_booking":
            return "https://www.hyatt.com/en-US/reservation/modify"
        case "add_to_wallet":
            return "https://www.apple.com/wallet/" // Handled in-app
        case "get_directions":
            return "https://maps.google.com/?q=destination"
        case "contact_driver":
            return "https://help.uber.com/riders/article/contact-driver"

        // Finance & Billing
        case "pay_invoice":
            return "https://pay.stripe.com/invoice/acct_example"
        case "view_invoice":
            return "https://billing.example.com/invoices/INV-2025-001"
        case "download_receipt":
            return "https://www.amazon.com/gp/css/summary/print.html?orderID=123"
        case "download_report":
            return "https://portal.example.com/reports/download/12345"
        case "update_payment":
            return "https://www.hulu.com/account/payment"
        case "reset_password":
            return "https://account.example.com/password/reset"
        case "verify_account":
            return "https://account.example.com/verify?token=abc123"
        case "review_security":
            return "https://myaccount.google.com/security-checkup"

        // Healthcare
        case "check_in_appointment":
            return "https://healthy.kaiserpermanente.org/ncal/pages/appointment-check-in"
        case "view_pickup_details":
            return "https://www.cvs.com/account/prescription-center.html"
        case "view_results":
            return "https://healthy.kaiserpermanente.org/ncal/pages/test-results"
        case "schedule_meeting":
            return "https://healthy.kaiserpermanente.org/ncal/pages/schedule"

        // Education
        case "view_assignment":
            return "https://classroom.google.com/c/assignment/123456"
        case "check_grade":
            return "https://powerschool.school.edu/guardian/home.html"
        case "sign_form":
            return "https://forms.school.edu/permission/field-trip-2025"
        case "pay_form_fee":
            return "https://school.edu/payments/pay-online"

        // Support & Communication
        case "view_ticket":
            return "https://support.zendesk.com/hc/en-us/requests/12345"
        case "reply_to_ticket":
            return "https://support.zendesk.com/hc/en-us/requests/12345"
        case "contact_support":
            return "https://help.example.com/contact"
        case "quick_reply":
            return "mailto:sender@example.com" // Handled in-app
        case "reply":
            return "mailto:sender@example.com" // Handled in-app

        // Subscriptions
        case "manage_subscription":
            return "https://account.example.com/subscription"
        case "cancel_subscription":
            return "https://account.example.com/subscription/cancel"
        case "unsubscribe":
            return "https://example.com/unsubscribe?email=user@example.com"

        // Work & Productivity
        case "view_task":
            return "https://jira.atlassian.com/browse/PROJ-123"
        case "view_incident":
            return "https://app.pagerduty.com/incidents/P123456"
        case "view_document":
            return "https://docs.google.com/document/d/1234567890/edit"
        case "view_spreadsheet":
            return "https://docs.google.com/spreadsheets/d/1234567890/edit"
        case "view_proposal":
            return "https://proposals.example.com/view/abc123"
        case "join_meeting":
            return "https://zoom.us/j/1234567890"
        case "register_event":
            return "https://eventbrite.com/e/event-registration-12345"
        case "route_crm":
            return "https://salesforce.com/lead/00Q12345"
        case "delegate":
            return "https://asana.com/task/1234567890"
        case "review_approve":
            return "https://github.com/org/repo/pull/123"

        // Social & Events
        case "rsvp_yes", "rsvp_no":
            return "https://partiful.com/e/abc123"
        case "take_survey":
            return "https://forms.gle/abcd1234"
        case "view_agenda":
            return "https://calendar.google.com/calendar/event?eid=abc123"

        // Security
        case "verify_device":
            return "https://account.example.com/security/verify-device"
        case "report_suspicious":
            return "https://support.example.com/report-phishing"
        case "revoke_secret":
            return "https://github.com/settings/tokens"

        // Generic actions
        case "open_link", "view_details":
            return "https://example.com/view/details"
        case "archive":
            return "https://mail.google.com" // Handled in-app
        case "save_for_later":
            return "https://pocket.com/add" // Handled in-app
        case "share":
            return "https://share.example.com" // Handled in-app

        default:
            return "https://example.com/action/\(actionId)"
        }
    }

    // MARK: - Placeholder Context Generation

    /// Get placeholder context data for an action
    /// Provides realistic mock data to demonstrate the action flow
    static func getPlaceholderContext(for actionId: String) -> [String: String] {
        switch actionId {
        // Shopping & E-commerce
        case "track_package":
            return [
                "trackingNumber": "1Z999AA10123456789",
                "carrier": "UPS",
                "trackingUrl": getPlaceholderURL(for: actionId),
                "estimatedDelivery": "Tomorrow by 8 PM"
            ]
        case "view_order":
            return [
                "orderNumber": "123-4567890-1234567",
                "orderUrl": getPlaceholderURL(for: actionId),
                "merchant": "Amazon"
            ]
        case "write_review":
            return [
                "productName": "Sample Product",
                "reviewLink": getPlaceholderURL(for: actionId),
                "orderNumber": "123-4567890"
            ]
        case "buy_again":
            return [
                "productName": "Previous Order Item",
                "reorderUrl": getPlaceholderURL(for: actionId)
            ]
        case "return_item":
            return [
                "orderNumber": "123-4567890",
                "returnUrl": getPlaceholderURL(for: actionId),
                "productName": "Sample Product"
            ]
        case "complete_cart":
            return [
                "cartUrl": getPlaceholderURL(for: actionId),
                "itemCount": "3"
            ]
        case "claim_deal":
            return [
                "dealUrl": getPlaceholderURL(for: actionId),
                "promoCode": "SAVE20",
                "discount": "20%"
            ]
        case "schedule_purchase":
            return [
                "productName": "Sample Product",
                "productUrl": getPlaceholderURL(for: "shop_now"),
                "saleDate": "Next Friday",
                "price": "$99.99"
            ]

        // Travel & Hospitality
        case "check_in_flight":
            return [
                "flightNumber": "UA 1234",
                "airline": "United Airlines",
                "checkInUrl": getPlaceholderURL(for: actionId),
                "departureTime": "Tomorrow 9:00 AM",
                "confirmationCode": "ABC123"
            ]
        case "view_reservation":
            return [
                "reservationUrl": getPlaceholderURL(for: actionId),
                "confirmationCode": "RES-123456",
                "venue": "Sample Restaurant",
                "date": "Friday 7:30 PM"
            ]
        case "get_directions":
            return [
                "location": "Sample Location",
                "address": "123 Main St, San Francisco, CA",
                "mapsUrl": "https://maps.google.com/?q=123+Main+St+San+Francisco"
            ]
        case "contact_driver":
            return [
                "driverName": "John D.",
                "vehicle": "Black Honda Civic",
                "eta": "5 minutes",
                "phone": "(555) 123-4567"
            ]

        // Finance & Billing
        case "pay_invoice":
            return [
                "invoiceId": "INV-2025-001",
                "amount": "$599.00",
                "merchant": "Acme Corp",
                "paymentUrl": getPlaceholderURL(for: actionId),
                "dueDate": "November 30"
            ]
        case "download_receipt":
            return [
                "receiptUrl": getPlaceholderURL(for: actionId),
                "orderNumber": "123-4567890",
                "amount": "$125.00"
            ]
        case "verify_account":
            return [
                "verificationLink": getPlaceholderURL(for: actionId)
            ]
        case "reset_password":
            return [
                "resetLink": getPlaceholderURL(for: actionId)
            ]

        // Healthcare
        case "check_in_appointment":
            return [
                "checkInUrl": getPlaceholderURL(for: actionId),
                "appointmentDate": "Tomorrow 2:00 PM",
                "provider": "Dr. Smith",
                "location": "Medical Center"
            ]
        case "view_pickup_details":
            return [
                "rxNumber": "RX-123456",
                "pharmacy": "CVS Pharmacy",
                "address": "123 Main St",
                "phone": "(555) 987-6543"
            ]

        // Education
        case "view_assignment":
            return [
                "assignmentUrl": getPlaceholderURL(for: actionId),
                "title": "Math Homework Chapter 8",
                "dueDate": "Friday"
            ]
        case "check_grade":
            return [
                "gradeUrl": getPlaceholderURL(for: actionId),
                "subject": "Mathematics",
                "grade": "A-"
            ]
        case "sign_form":
            return [
                "formUrl": getPlaceholderURL(for: actionId),
                "formType": "Permission Form",
                "dueDate": "Next Week"
            ]
        case "pay_form_fee":
            return [
                "paymentUrl": getPlaceholderURL(for: actionId),
                "amount": "$25.00",
                "description": "Field Trip Fee"
            ]

        // Support
        case "view_ticket":
            return [
                "ticketUrl": getPlaceholderURL(for: actionId),
                "ticketId": "SUPP-12345",
                "status": "Open"
            ]
        case "contact_support":
            return [
                "supportUrl": getPlaceholderURL(for: actionId)
            ]

        // Subscriptions
        case "manage_subscription":
            return [
                "subscriptionUrl": getPlaceholderURL(for: actionId),
                "service": "Premium Plan",
                "renewalDate": "December 1"
            ]
        case "unsubscribe":
            return [
                "unsubscribeUrl": getPlaceholderURL(for: actionId)
            ]

        // Work & Productivity
        case "view_task":
            return [
                "taskUrl": getPlaceholderURL(for: actionId),
                "taskId": "PROJ-123",
                "title": "Sample Task"
            ]
        case "join_meeting":
            return [
                "meetingUrl": getPlaceholderURL(for: actionId),
                "meetingTime": "2:00 PM Today"
            ]
        case "view_document":
            return [
                "documentUrl": getPlaceholderURL(for: actionId),
                "title": "Q4 Report"
            ]

        // Events
        case "rsvp_yes":
            return [
                "eventUrl": getPlaceholderURL(for: "rsvp_yes"),
                "eventTitle": "Team Dinner",
                "eventDate": "Friday 7:00 PM"
            ]
        case "take_survey":
            return [
                "surveyUrl": getPlaceholderURL(for: actionId),
                "title": "Customer Feedback"
            ]

        default:
            return [
                "url": getPlaceholderURL(for: actionId)
            ]
        }
    }

    // MARK: - Context Validation

    struct ValidationResult {
        let isValid: Bool
        let missingKeys: [String]
        let suggestions: [String: String]

        var hasPlaceholderAvailable: Bool {
            return !suggestions.isEmpty
        }
    }

    /// Validate action context and provide placeholder suggestions if incomplete
    static func validateActionContext(_ action: EmailAction) -> ValidationResult {
        let context = action.context ?? [:]
        let actionId = action.actionId

        // Define required keys for each action type
        let requiredKeys = getRequiredKeys(for: actionId)

        // Check which required keys are missing
        let missingKeys = requiredKeys.filter { context[$0] == nil || context[$0]?.isEmpty == true }

        // Generate placeholder suggestions for missing keys
        let placeholderContext = getPlaceholderContext(for: actionId)
        var suggestions: [String: String] = [:]
        for key in missingKeys {
            if let placeholderValue = placeholderContext[key] {
                suggestions[key] = placeholderValue
            }
        }

        return ValidationResult(
            isValid: missingKeys.isEmpty,
            missingKeys: missingKeys,
            suggestions: suggestions
        )
    }

    /// Get required context keys for an action
    private static func getRequiredKeys(for actionId: String) -> [String] {
        switch actionId {
        case "track_package":
            return ["trackingNumber", "carrier", "trackingUrl"]
        case "pay_invoice":
            return ["amount", "paymentUrl"]
        case "check_in_flight":
            return ["flightNumber", "airline", "checkInUrl"]
        case "write_review":
            return ["productName", "reviewLink"]
        case "view_order":
            return ["orderUrl"]
        case "contact_driver":
            return ["driverName"]
        case "view_reservation":
            return ["reservationUrl"]
        case "get_directions":
            return ["mapsUrl"]
        case "check_in_appointment":
            return ["checkInUrl"]
        case "view_assignment":
            return ["assignmentUrl"]
        case "view_ticket":
            return ["ticketUrl"]
        case "join_meeting":
            return ["meetingUrl"]
        case "manage_subscription":
            return ["subscriptionUrl"]
        case "unsubscribe":
            return ["unsubscribeUrl"]
        default:
            return ["url"]
        }
    }

    // MARK: - Helper: Apply Placeholders to Action

    /// Apply placeholder context to an action with missing data
    /// Returns a new EmailAction with placeholder context filled in
    static func applyPlaceholders(to action: EmailAction) -> EmailAction {
        let validation = validateActionContext(action)

        // If valid, return original action
        guard !validation.isValid else {
            return action
        }

        // Merge existing context with placeholder suggestions
        var updatedContext = action.context ?? [:]
        for (key, value) in validation.suggestions {
            if updatedContext[key] == nil || updatedContext[key]?.isEmpty == true {
                updatedContext[key] = value
            }
        }

        // Create new action with updated context
        return EmailAction(
            actionId: action.actionId,
            displayName: action.displayName,
            actionType: action.actionType,
            isPrimary: action.isPrimary,
            priority: action.priority,
            context: updatedContext,
            isCompound: action.isCompound,
            compoundSteps: action.compoundSteps
        )
    }
}

// MARK: - Logging Extension

extension ActionPlaceholders {
    /// Log placeholder usage for debugging
    static func logPlaceholderUsage(for actionId: String, missingKeys: [String]) {
        Logger.info("⚠️ Using placeholders for action '\(actionId)'", category: .action)
        Logger.info("Missing keys: \(missingKeys.joined(separator: ", "))", category: .action)
        Logger.info("Placeholder URL: \(getPlaceholderURL(for: actionId))", category: .action)
    }
}
