import XCTest
@testable import Zero

/**
 * ActionTestMatrix
 * Data-driven test generator for comprehensive action testing
 *
 * Programmatically generates test cases for all 144 actions from ActionCatalog
 * Ensures systematic coverage of GO_TO and IN_APP actions
 */

// MARK: - Test Data Structures

struct ActionTestCase {
    let actionId: String
    let displayName: String
    let actionType: ZeroActionType
    let mode: ZeroMode
    let intent: String
    let requiredContext: [String: String]
    let optionalContext: [String: String]
    let expectedBehavior: ExpectedBehavior

    enum ExpectedBehavior {
        case opensURL(expectedURL: String)
        case presentsModal(modalComponent: String)
        case showsError(message: String)
        case requestsPermission(permission: String)
    }
}

struct ActionCategory {
    let name: String
    let actions: [ActionTestCase]
    let priority: Int  // For test execution order
}

// MARK: - Action Test Matrix

class ActionTestMatrix {

    static let shared = ActionTestMatrix()

    private init() {}

    // MARK: - Registry Statistics

    /// Get current ActionRegistry statistics
    func getRegistryStats() -> (total: Int, goTo: Int, inApp: Int, mail: Int, ads: Int, both: Int) {
        let registry = ActionRegistry.shared
        let stats = registry.getStatistics()

        return (
            total: stats.totalActions,
            goTo: stats.goToActions,
            inApp: stats.inAppActions,
            mail: stats.mailModeActions,
            ads: stats.adsModeActions,
            both: stats.sharedActions
        )
    }

    /// Get all registered action IDs
    func getAllActionIds() -> [String] {
        return ActionRegistry.shared.getAllActionIds()
    }

    /// Get actions by type
    func getActionsByType(type: ZeroActionType) -> [ActionConfig] {
        return ActionRegistry.shared.registry.values.filter { $0.actionType == type }
    }

    /// Get actions by mode
    func getActionsByMode(mode: ZeroMode) -> [ActionConfig] {
        return ActionRegistry.shared.getActionsForMode(mode)
    }

    // MARK: - Test Case Generation

    /// Generate test cases for all registered actions
    func generateAllTestCases() -> [ActionTestCase] {
        let allActionIds = getAllActionIds()

        return allActionIds.compactMap { actionId in
            generateTestCase(for: actionId)
        }
    }

    /// Generate test case for specific action
    func generateTestCase(for actionId: String) -> ActionTestCase? {
        guard let actionConfig = ActionRegistry.shared.getAction(actionId) else {
            return nil
        }

        // Generate appropriate context data based on action requirements
        let context = generateContextData(for: actionConfig)

        // Determine expected behavior
        let expectedBehavior: ActionTestCase.ExpectedBehavior
        if actionConfig.actionType == .goTo {
            let expectedURL = generateExpectedURL(for: actionConfig, context: context.required)
            expectedBehavior = .opensURL(expectedURL: expectedURL)
        } else if let modalComponent = actionConfig.modalComponent {
            expectedBehavior = .presentsModal(modalComponent: modalComponent)
        } else {
            expectedBehavior = .showsError(message: "No modal component defined")
        }

        // Infer intent from action category
        let intent = inferIntent(for: actionConfig)

        return ActionTestCase(
            actionId: actionId,
            displayName: actionConfig.displayName,
            actionType: actionConfig.actionType,
            mode: actionConfig.mode,
            intent: intent,
            requiredContext: context.required,
            optionalContext: context.optional,
            expectedBehavior: expectedBehavior
        )
    }

    /// Generate test cases grouped by category
    func generateTestCasesByCategory() -> [ActionCategory] {
        return [
            generateECommerceCategory(),
            generateBillingCategory(),
            generateEducationCategory(),
            generateHealthcareCategory(),
            generateTravelCategory(),
            generateFinanceCategory(),
            generateShoppingAutomationCategory(),
            generateCivicCategory(),
            generateProfessionalCategory(),
            generateNativeIOSCategory()
        ]
    }

    // MARK: - Category Generators

    private func generateECommerceCategory() -> ActionCategory {
        let actionIds = ["track_package", "view_order", "write_review", "contact_driver"]
        let testCases = actionIds.compactMap { generateTestCase(for: $0) }

        return ActionCategory(
            name: "E-Commerce",
            actions: testCases,
            priority: 1
        )
    }

    private func generateBillingCategory() -> ActionCategory {
        let actionIds = ["pay_invoice", "manage_subscription", "cancel_subscription"]
        let testCases = actionIds.compactMap { generateTestCase(for: $0) }

        return ActionCategory(
            name: "Billing",
            actions: testCases,
            priority: 2
        )
    }

    private func generateEducationCategory() -> ActionCategory {
        let actionIds = ["view_assignment", "check_grade", "view_lms"]
        let testCases = actionIds.compactMap { generateTestCase(for: $0) }

        return ActionCategory(
            name: "Education",
            actions: testCases,
            priority: 3
        )
    }

    private func generateHealthcareCategory() -> ActionCategory {
        let actionIds = ["view_results", "view_prescription", "schedule_appointment",
                        "check_in_appointment", "view_pickup_details"]
        let testCases = actionIds.compactMap { generateTestCase(for: $0) }

        return ActionCategory(
            name: "Healthcare",
            actions: testCases,
            priority: 4
        )
    }

    private func generateTravelCategory() -> ActionCategory {
        let actionIds = ["check_in_flight", "view_itinerary", "view_reservation", "get_directions"]
        let testCases = actionIds.compactMap { generateTestCase(for: $0) }

        return ActionCategory(
            name: "Travel",
            actions: testCases,
            priority: 5
        )
    }

    private func generateFinanceCategory() -> ActionCategory {
        let actionIds = ["view_tax_notice"]
        let testCases = actionIds.compactMap { generateTestCase(for: $0) }

        return ActionCategory(
            name: "Finance",
            actions: testCases,
            priority: 6
        )
    }

    private func generateShoppingAutomationCategory() -> ActionCategory {
        let actionIds = ["claim_deal", "shop_now", "browse_shopping", "schedule_purchase"]
        let testCases = actionIds.compactMap { generateTestCase(for: $0) }

        return ActionCategory(
            name: "Shopping Automation",
            actions: testCases,
            priority: 7
        )
    }

    private func generateCivicCategory() -> ActionCategory {
        let actionIds = ["view_jury_summons", "view_voter_info"]
        let testCases = actionIds.compactMap { generateTestCase(for: $0) }

        return ActionCategory(
            name: "Civic & Government",
            actions: testCases,
            priority: 8
        )
    }

    private func generateProfessionalCategory() -> ActionCategory {
        let actionIds = ["view_task", "view_incident", "view_ticket", "route_crm",
                        "schedule_meeting", "delegate"]
        let testCases = actionIds.compactMap { generateTestCase(for: $0) }

        return ActionCategory(
            name: "Professional",
            actions: testCases,
            priority: 9
        )
    }

    private func generateNativeIOSCategory() -> ActionCategory {
        let actionIds = ["add_to_calendar", "add_reminder", "add_to_wallet",
                        "save_contact_native", "send_message", "share"]
        let testCases = actionIds.compactMap { generateTestCase(for: $0) }

        return ActionCategory(
            name: "Native iOS",
            actions: testCases,
            priority: 10
        )
    }

    // MARK: - Context Data Generation

    private func generateContextData(for action: ActionConfig) -> (required: [String: String], optional: [String: String]) {
        var required: [String: String] = [:]
        var optional: [String: String] = [:]

        // Generate required context
        for key in action.requiredContextKeys {
            required[key] = generateSampleValue(for: key, actionId: action.actionId)
        }

        // Generate optional context
        for key in action.optionalContextKeys {
            optional[key] = generateSampleValue(for: key, actionId: action.actionId)
        }

        return (required: required, optional: optional)
    }

    private func generateSampleValue(for key: String, actionId: String) -> String {
        switch key {
        // URLs
        case "url":
            return "https://example.com/\(actionId)"
        case "orderUrl":
            return "https://amazon.com/orders/123-4567890-1234567"
        case "trackingUrl":
            return "https://ups.com/track?num=1Z999AA10123456784"
        case "invoiceUrl":
            return "https://stripe.com/invoices/in_1234567890"
        case "assignmentUrl":
            return "https://classroom.google.com/c/123456/a/789012"
        case "checkInUrl":
            return "https://checkin.aa.com/boarding/AA1234"
        case "productUrl":
            return "https://amazon.com/dp/B08N5WRWNW"
        case "shopUrl", "dealUrl":
            return "https://target.com/deals"
        case "subscriptionUrl":
            return "https://subscriptions.example.com/manage"
        case "itineraryUrl":
            return "https://kayak.com/trips/123456"
        case "directionsUrl", "mapUrl":
            return "https://maps.apple.com/?address=1+Apple+Park+Way"
        case "unsubscribeUrl":
            return "https://example.com/unsubscribe?token=abc123"

        // Tracking & Shipping
        case "trackingNumber":
            return "1Z999AA10123456784"
        case "carrier":
            return "UPS"
        case "expectedDelivery":
            return "2024-01-15"
        case "currentStatus":
            return "In Transit"

        // Financial
        case "invoiceId":
            return "INV-2024-001234"
        case "amount":
            return "149.99"
        case "merchant", "serviceName":
            return "Acme Corporation"
        case "paymentLink":
            return "https://pay.stripe.com/invoice/acct_1234567890"
        case "dueDate":
            return "2024-01-31"

        // Flight & Travel
        case "flightNumber":
            return "AA1234"
        case "airline":
            return "American Airlines"
        case "departureTime":
            return "2024-01-15 14:30"
        case "gate":
            return "B12"
        case "seat":
            return "12A"
        case "reservationNumber":
            return "ABC123"
        case "venue":
            return "The French Laundry"

        // Education
        case "assignmentName":
            return "Math Homework Chapter 5"
        case "courseName":
            return "Introduction to Computer Science"
        case "gradeUrl":
            return "https://powerschool.com/grades/12345"
        case "platformName", "lmsUrl":
            return "Google Classroom"

        // Healthcare
        case "rxNumber", "prescriptionUrl":
            return "RX123456"
        case "pharmacy":
            return "CVS Pharmacy"
        case "resultsUrl", "testResultsUrl":
            return "https://myhealth.example.com/results/12345"
        case "appointmentUrl", "appointmentTime":
            return "2024-01-20 10:00 AM"
        case "providerName":
            return "Dr. Smith"

        // Email & Communication
        case "recipientEmail":
            return "test@example.com"
        case "subject":
            return "Re: Test Email"
        case "body":
            return "This is a test reply"
        case "template":
            return "quick_reply_template"

        // Calendar & Reminders
        case "eventTitle", "meetingTitle":
            return "Team Meeting"
        case "eventDate", "date":
            return "2024-01-25"
        case "eventTime":
            return "14:00"
        case "location", "address":
            return "123 Main St, San Francisco, CA"
        case "reminderTitle":
            return "Follow up on proposal"
        case "reminderText":
            return "Review project proposal"
        case "notes":
            return "Bring documents"
        case "attendees":
            return "john@example.com, jane@example.com"
        case "duration":
            return "60"

        // Products & Shopping
        case "productName":
            return "Wireless Headphones"
        case "orderNumber":
            return "112-1234567-8901234"
        case "productImage":
            return "https://example.com/product.jpg"
        case "reviewLink":
            return "https://amazon.com/review/write/B08N5WRWNW"
        case "promoCode":
            return "SAVE20"
        case "price":
            return "$99.99"
        case "category":
            return "Electronics"
        case "query":
            return "wireless headphones"

        // Documents
        case "documentUrl":
            return "https://docs.google.com/document/d/1234567890"
        case "documentName":
            return "Q4 Financial Report.pdf"
        case "spreadsheetUrl":
            return "https://docs.google.com/spreadsheets/d/1234567890"
        case "sheetName":
            return "Budget 2024"
        case "formUrl":
            return "https://forms.google.com/form/1234567890"

        // Contacts & Communication
        case "name":
            return "John Doe"
        case "email":
            return "john.doe@example.com"
        case "phone", "phoneNumber":
            return "+1 (555) 123-4567"
        case "driverName":
            return "Mike Johnson"
        case "driverPhone":
            return "+1 (555) 987-6543"
        case "vehicleInfo":
            return "Toyota Camry - ABC123"
        case "eta":
            return "15 minutes"

        // Work & Professional
        case "taskName", "taskDescription":
            return "Update website homepage"
        case "taskUrl":
            return "https://asana.com/task/1234567890"
        case "ticketNumber":
            return "TICKET-12345"
        case "ticketUrl":
            return "https://zendesk.com/tickets/12345"
        case "status":
            return "Open"
        case "incidentUrl":
            return "https://pagerduty.com/incidents/12345"
        case "incidentId":
            return "INC-2024-001"
        case "severity":
            return "High"
        case "crmUrl":
            return "https://salesforce.com/leads/00Q1234567890"
        case "contactName":
            return "Jane Smith"
        case "leadId":
            return "00Q1234567890"

        // Civic & Government
        case "summonsUrl":
            return "https://courts.example.gov/summons/12345"
        case "courtDate":
            return "2024-02-15"
        case "taxNoticeUrl":
            return "https://tax.example.gov/notice/12345"
        case "voterUrl":
            return "https://vote.example.gov/registration/12345"
        case "electionDate":
            return "2024-11-05"
        case "pollingLocation":
            return "Lincoln Elementary School"

        // Wallet & Passes
        case "passUrl":
            return "https://example.com/pass/12345.pkpass"
        case "passType":
            return "boarding_pass"

        // Content & Sharing
        case "content":
            return "Check out this article: https://example.com/article"
        case "appUrl":
            return "uber://ride"
        case "appName":
            return "Uber"
        case "summaryText":
            return "This week's top stories include..."
        case "topLinks":
            return "https://example.com/article1, https://example.com/article2"

        // Folders & Organization
        case "folderId":
            return "inbox/important"
        case "reminderTime":
            return "2024-01-20 09:00"
        case "snoozeUntil":
            return "tomorrow"
        case "purchaseDate":
            return "2024-02-01"

        default:
            return "test_\(key)_value"
        }
    }

    private func generateExpectedURL(for action: ActionConfig, context: [String: String]) -> String {
        // For GO_TO actions, generate expected URL from context
        if let url = context["url"] {
            return url
        }

        // Check for specific URL keys based on action ID
        let urlKeys = action.requiredContextKeys.filter { $0.hasSuffix("Url") }
        if let firstUrlKey = urlKeys.first, let url = context[firstUrlKey] {
            return url
        }

        return "https://example.com/\(action.actionId)"
    }

    private func inferIntent(for action: ActionConfig) -> String {
        // Infer intent category from action ID
        let actionId = action.actionId

        if actionId.contains("track") || actionId.contains("shipping") {
            return "e-commerce.shipping.notification"
        } else if actionId.contains("order") || actionId.contains("purchase") {
            return "e-commerce.order.confirmation"
        } else if actionId.contains("invoice") || actionId.contains("payment") {
            return "transactions.invoice"
        } else if actionId.contains("subscription") {
            return "transactions.subscription"
        } else if actionId.contains("flight") || actionId.contains("travel") {
            return "travel.flight"
        } else if actionId.contains("assignment") || actionId.contains("grade") {
            return "education.assignment"
        } else if actionId.contains("appointment") || actionId.contains("prescription") {
            return "healthcare.appointment"
        } else if actionId.contains("meeting") || actionId.contains("calendar") {
            return "scheduling.meeting-request"
        } else if actionId.contains("reminder") {
            return "scheduling.reminder"
        } else if actionId.contains("shop") || actionId.contains("deal") {
            return "ads.promotional"
        } else {
            return "general.inquiry"
        }
    }

    // MARK: - Coverage Analysis

    /// Identify actions that need additional test coverage
    func getUntestedActions(testedActionIds: Set<String>) -> [String] {
        let allActionIds = Set(getAllActionIds())
        let untestedIds = allActionIds.subtracting(testedActionIds)
        return Array(untestedIds).sorted()
    }

    /// Generate coverage report
    func generateCoverageReport(testedActionIds: Set<String>) -> CoverageReport {
        let stats = getRegistryStats()
        let untested = getUntestedActions(testedActionIds: testedActionIds)

        return CoverageReport(
            totalActions: stats.total,
            testedActions: testedActionIds.count,
            untestedActions: untested.count,
            coveragePercentage: Double(testedActionIds.count) / Double(stats.total) * 100,
            untestedActionIds: untested
        )
    }
}

// MARK: - Coverage Report

struct CoverageReport: CustomStringConvertible {
    let totalActions: Int
    let testedActions: Int
    let untestedActions: Int
    let coveragePercentage: Double
    let untestedActionIds: [String]

    var description: String {
        """

        ===========================================
        ACTION TEST COVERAGE REPORT
        ===========================================
        Total Actions:       \(totalActions)
        Tested Actions:      \(testedActions)
        Untested Actions:    \(untestedActions)
        Coverage:            \(String(format: "%.1f", coveragePercentage))%

        Untested Action IDs:
        \(untestedActionIds.map { "  - \($0)" }.joined(separator: "\n"))
        ===========================================

        """
    }
}
