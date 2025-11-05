import Foundation
import UIKit
import SafariServices

/**
 * ActionRouter (v1.2 - ActionRegistry Integration)
 * Routes and executes actions based on actionId and type
 * Handles both GO_TO (external URLs) and IN_APP (modal) actions
 * Now uses ActionRegistry as single source of truth
 */

class ActionRouter: ObservableObject {
    static let shared = ActionRouter()

    @Published var activeModal: ActionModal?
    @Published var showingModal: Bool = false
    @Published var showingPreviewModal: ActionPreviewModal?
    @Published var errorMessage: String?
    @Published var showingError: Bool = false

    // Current mode for mode validation
    @Published var currentMode: CardType = .mail

    // ActionRegistry reference
    private let registry = ActionRegistry.shared

    private init() {}
    
    /**
     * Execute an action based on its type (v1.2 - with validation)
     */
    func executeAction(_ action: EmailAction, card: EmailCard, from viewController: UIViewController? = nil) {
        Logger.info("Executing action \(action.actionId)", category: .action)

        // Step 1: Check if action exists in registry
        guard let actionConfig = registry.getAction(action.actionId) else {
            Logger.error("Action '\(action.actionId)' not found in registry", category: .action)
            showError("Action '\(action.displayName)' is not supported")
            return
        }

        // Step 2: Validate mode compatibility
        if !registry.isActionValidForMode(action.actionId, currentMode: currentMode) {
            Logger.error("Action '\(action.actionId)' not valid for current mode: \(currentMode.rawValue)", category: .action)
            showError("'\(action.displayName)' is not available in \(currentMode.rawValue.capitalized) mode")

            // Analytics: Track mode validation failure
            AnalyticsService.shared.log("action_mode_validation_failed", properties: [
                "action_id": action.actionId,
                "current_mode": currentMode.rawValue,
                "required_mode": actionConfig.mode.rawValue
            ])
            return
        }

        // Step 3: Validate required context (with placeholder fallback)
        let validation = registry.validateAction(action.actionId, context: action.context)
        if !validation.isValid {
            Logger.warning("Action '\(action.actionId)' missing required context: \(validation.missingKeys.joined(separator: ", ")) - Attempting placeholder fill", category: .action)

            // Try to apply placeholders to fill missing context
            let actionWithPlaceholders = ActionPlaceholders.applyPlaceholders(to: action)

            // Validate again after applying placeholders
            let revalidation = registry.validateAction(action.actionId, context: actionWithPlaceholders.context)
            if !revalidation.isValid {
                Logger.error("Action '\(action.actionId)' still invalid after applying placeholders", category: .action)
                showError("Missing information: \(validation.missingKeys.joined(separator: ", "))")

                // Analytics: Track validation failure even with placeholders
                AnalyticsService.shared.log("action_context_validation_failed", properties: [
                    "action_id": action.actionId,
                    "missing_keys": validation.missingKeys.joined(separator: ", "),
                    "error": validation.error ?? "Unknown error",
                    "placeholders_attempted": true
                ])
                return
            }

            // Success! Continue with placeholder-filled action
            Logger.info("✅ Action '\(action.actionId)' validated after applying placeholders", category: .action)

            // Analytics: Track placeholder usage
            AnalyticsService.shared.log("action_used_placeholder", properties: [
                "action_id": action.actionId,
                "action_display_name": action.displayName,
                "missing_keys_filled": validation.missingKeys.joined(separator: ", "),
                "placeholder_context_applied": true
            ])

            // Execute with placeholders
            executeWithPlaceholders(actionWithPlaceholders, card: card, from: viewController)
            return
        }

        // Analytics: Track successful action execution
        AnalyticsService.shared.log("action_executed", properties: [
            "action_id": action.actionId,
            "action_display_name": action.displayName,
            "action_type": action.actionType == .goTo ? "GO_TO" : "IN_APP",
            "is_primary": action.isPrimary,
            "priority": action.priority ?? actionConfig.priority,
            "card_archetype": card.type.rawValue,
            "card_intent": card.intent ?? "unknown",
            "card_priority": card.priority.rawValue,
            "has_context": action.context != nil,
            "is_compound": action.isCompound ?? false,
            "had_preview": shouldShowPreview(for: action.actionId),
            "current_mode": currentMode.rawValue,
            "action_mode": actionConfig.mode.rawValue
        ])

        // Step 4: Execute based on type
        switch action.actionType {
        case .goTo:
            executeGoToAction(action, card: card, from: viewController)
        case .inApp:
            executeInAppAction(action, card: card)
        }
    }
    
    /**
     * Execute action with placeholders (when original validation failed)
     * Shows user feedback that placeholder data is being used
     */
    private func executeWithPlaceholders(_ action: EmailAction, card: EmailCard, from viewController: UIViewController?) {
        Logger.info("Executing action '\(action.actionId)' with placeholder data", category: .action)

        // Show user that we're using placeholder/sample data
        showError("Using sample data for '\(action.displayName)'")

        // Execute normally - placeholders are already applied to context
        switch action.actionType {
        case .goTo:
            executeGoToAction(action, card: card, from: viewController)
        case .inApp:
            executeInAppAction(action, card: card)
        }
    }

    // MARK: - GO_TO Actions (External URLs)

    private func executeGoToAction(_ action: EmailAction, card: EmailCard, from viewController: UIViewController?) {
        // Check if this action should show a preview modal first
        if shouldShowPreview(for: action.actionId) {
            showPreviewModal(for: action, card: card)
            return
        }

        guard let context = action.context else {
            showError("Unable to complete action - missing information")
            Logger.warning("No context provided for GO_TO action: \(action.actionId)", category: .action)
            return
        }

        var urlString: String?

        // PRIORITY 1: Check for generic "url" key (backend guarantee via rules-engine.js URL schema enforcement)
        // Backend automatically copies semantic URL keys (trackingUrl, invoiceUrl, etc.) to "url" for iOS compatibility
        if let genericUrl = context["url"], !genericUrl.isEmpty {
            urlString = genericUrl
            Logger.info("✅ Using backend-provided generic 'url' key for \(action.actionId)", category: .action)
        } else {
            // PRIORITY 2: Fallback to action-specific URL generation (for backward compatibility)
            Logger.info("⚠️ No generic 'url' found, using action-specific URL logic for \(action.actionId)", category: .action)
        }

        // Generate URL based on actionId (only if generic URL not found)
        if urlString == nil {
            switch action.actionId {
        case "track_package":
            urlString = generateTrackingURL(context: context)
            
        case "pay_invoice":
            urlString = context["paymentLink"]
            
        case "view_order":
            urlString = context["orderUrl"]
            
        case "check_in_flight":
            urlString = context["checkInUrl"]
            
        case "reset_password", "verify_account":
            urlString = context["resetLink"] ?? context["verificationLink"]
            
        case "register_event":
            urlString = context["registrationLink"]
            
        case "write_review":
            urlString = context["reviewLink"]
            
        case "view_assignment", "check_grade":
            urlString = context["assignmentUrl"] ?? context["gradeUrl"]
            
        case "view_ticket":
            urlString = context["ticketUrl"]
            
        case "view_task":
            urlString = context["taskUrl"]
            
        case "view_incident":
            urlString = context["incidentUrl"]
            
        case "join_meeting":
            urlString = context["meetingUrl"]
            
        case "view_itinerary":
            urlString = context["itineraryUrl"]
            
        case "download_receipt":
            urlString = context["receiptUrl"]
            
        case "claim_deal", "view_product":
            urlString = context["dealUrl"] ?? context["productUrl"]
            
        case "complete_cart":
            urlString = context["cartUrl"]

        case "buy_again":
            urlString = context["reorderUrl"]

        case "return_item":
            urlString = context["returnUrl"]

        case "manage_booking":
            urlString = context["bookingUrl"]

        case "contact_support":
            urlString = context["supportUrl"]

        case "open_link":
            urlString = context["url"]

        case "add_to_wallet":
            // Add to Apple Wallet - will be handled as IN_APP with PassKit
            // For now, fallback to wallet URL if provided
            urlString = context["walletUrl"]

        case "check_in_appointment":
            urlString = context["checkInUrl"] ?? context["appointmentUrl"]

        case "view_reservation", "modify_reservation":
            urlString = context["reservationUrl"] ?? context["bookingUrl"]

        case "view_spreadsheet":
            urlString = context["spreadsheetUrl"] ?? context["documentUrl"]

        case "view_document":
            // Priority: 1. Attachment URL (real emails), 2. Context documentUrl (mock/external links)
            if let attachments = card.attachments, !attachments.isEmpty {
                // Real email with attachments - use Gmail attachment API URL
                let attachment = attachments[0]  // Use first attachment
                urlString = generateAttachmentURL(for: attachment, card: card)
                Logger.info("Using attachment URL for view_document: \(attachment.filename)", category: .action)
            } else {
                // Mock data or external document link
                urlString = context["documentUrl"]
                Logger.info("Using context documentUrl for view_document", category: .action)
            }

        case "view_proposal":
            urlString = context["proposalUrl"]

        case "view_cart":
            urlString = context["cartUrl"]

        case "view_deals":
            urlString = context["dealsUrl"]

        case "view_agenda":
            urlString = context["agendaUrl"]

        case "view_results":
            urlString = context["resultsUrl"] ?? context["testResultsUrl"]

        case "shop_now":
            urlString = context["shopUrl"] ?? context["productUrl"]

        case "track_delivery":
            urlString = context["deliveryUrl"] ?? context["trackingUrl"]

        case "download_report":
            urlString = context["reportUrl"] ?? context["downloadUrl"]

        case "get_directions":
            urlString = context["directionsUrl"] ?? context["mapUrl"]

        case "take_survey":
            urlString = context["surveyUrl"]

        case "manage_subscription":
            urlString = context["subscriptionUrl"] ?? context["manageUrl"]

        case "unsubscribe":
            // Unsubscribe now handled as IN_APP modal for better UX
            // This case kept for backward compatibility if action type is GO_TO
            urlString = context["unsubscribeUrl"]

        default:
            urlString = context["url"]
            }
        }

        // Open URL (with placeholder fallback for missing URLs)
        if let urlString = urlString, let url = URL(string: urlString) {
            openURL(url, from: viewController)
        } else {
            // Use ActionPlaceholders when URL is missing
            Logger.warning("⚠️ MISSING URL CONTEXT for action: \(action.actionId) - Using placeholder URL", category: .action)
            Logger.info("Context keys available: \(context.keys.joined(separator: ", "))", category: .action)

            let placeholderUrl = ActionPlaceholders.getPlaceholderURL(for: action.actionId)

            if let url = URL(string: placeholderUrl) {
                Logger.info("📦 Using placeholder URL for \(action.actionId): \(placeholderUrl)", category: .action)

                // Analytics: Track placeholder usage
                AnalyticsService.shared.log("action_used_placeholder", properties: [
                    "action_id": action.actionId,
                    "action_display_name": action.displayName,
                    "placeholder_url": placeholderUrl,
                    "missing_url": true
                ])

                showError("Using sample data for '\(action.displayName)'")
                openURL(url, from: viewController)
            } else {
                Logger.error("❌ Failed to generate placeholder URL for \(action.actionId)", category: .action)
                showError("Unable to open link for \(action.displayName)")
            }
        }
    }
    
    private func generateTrackingURL(context: [String: String]) -> String? {
        guard let trackingNumber = context["trackingNumber"] else {
            return nil
        }

        let carrier = context["carrier"]?.lowercased() ?? ""

        let carrierUrls: [String: String] = [
            "ups": "https://www.ups.com/track?tracknum=\(trackingNumber)",
            "fedex": "https://www.fedex.com/fedextrack/?tracknumbers=\(trackingNumber)",
            "usps": "https://tools.usps.com/go/TrackConfirmAction?tLabels=\(trackingNumber)",
            "dhl": "https://www.dhl.com/en/express/tracking.html?AWB=\(trackingNumber)",
            "amazon": "https://www.amazon.com/progress-tracker/package?itemId=\(trackingNumber)"
        ]

        for (key, urlTemplate) in carrierUrls {
            if carrier.contains(key) {
                return urlTemplate
            }
        }

        // Generic tracking search
        return "https://www.google.com/search?q=track+\(trackingNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trackingNumber)"
    }

    /// Generate Gmail attachment download URL for real emails with attachments
    private func generateAttachmentURL(for attachment: EmailAttachment, card: EmailCard) -> String? {
        // For real Gmail attachments, we'd construct the Gmail API attachment URL
        // Format: https://www.googleapis.com/gmail/v1/users/me/messages/{messageId}/attachments/{attachmentId}
        // This would require OAuth token and proper API call handling

        // For now, return a URL that would trigger the attachment viewer modal
        // The actual download would be handled by EmailAPIService

        guard let messageId = attachment.messageId else {
            Logger.warning("Attachment missing messageId, cannot generate URL", category: .action)
            return nil
        }

        // Return a custom app URL scheme that will be handled by the app
        // This prevents external browser opening and keeps user in-app
        return "emailshortform://attachment/\(messageId)/\(attachment.id)"
    }
    
    private func openURL(_ url: URL, from viewController: UIViewController?) {
        // Try to open in Safari View Controller for better UX
        if let vc = viewController {
            let safariVC = SFSafariViewController(url: url)
            vc.present(safariVC, animated: true)
        } else {
            // Fallback to opening in Safari app
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - IN_APP Actions (Modal Actions)

    private func executeInAppAction(_ action: EmailAction, card: EmailCard) {
        // Use registry to get modal component, then map to ActionModal enum
        let modal = buildModalForAction(action, card: card)

        DispatchQueue.main.async {
            self.activeModal = modal
            self.showingModal = true
        }
    }

    /**
     * Build modal for action using ActionRegistry (v1.2)
     * This replaces the giant switch statement with registry-powered routing
     */
    private func buildModalForAction(_ action: EmailAction, card: EmailCard) -> ActionModal {
        let actionId = action.actionId
        let context = action.context ?? [:]

        // Query registry for modal component
        guard let actionConfig = registry.getAction(actionId),
              let modalComponent = actionConfig.modalComponent else {
            Logger.warning("No modal component for action '\(actionId)', using viewDetails fallback", category: .action)
            return .viewDetails(card: card, context: context)
        }

        // Map modal component name to ActionModal enum
        // This is the ONLY place where action → modal mapping exists
        switch modalComponent {
        // High-Fidelity Modals
        case "TrackPackageModal":
            return .trackPackage(
                card: card,
                trackingNumber: context["trackingNumber"] ?? "Unknown",
                carrier: context["carrier"] ?? "Carrier",
                trackingUrl: context["url"] ?? "",
                context: context
            )

        case "PayInvoiceModal":
            return .payInvoice(
                card: card,
                invoiceId: context["invoiceId"] ?? "Unknown",
                amount: context["amount"] ?? context["amountDue"] ?? "$0.00",
                merchant: context["merchant"] ?? card.company?.name ?? "Merchant",
                context: context
            )

        case "CheckInFlightModal":
            return .checkInFlight(
                card: card,
                flightNumber: context["flightNumber"] ?? "Unknown",
                airline: context["airline"] ?? "Airline",
                checkInUrl: context["checkInUrl"] ?? "",
                context: context
            )

        case "WriteReviewModal":
            return .writeReview(
                card: card,
                productName: context["productName"] ?? "Product",
                reviewLink: context["reviewLink"] ?? "",
                context: context
            )

        case "ContactDriverModal":
            return .contactDriver(card: card, driverInfo: context)

        case "PickupDetailsModal":
            return .viewPickupDetails(
                card: card,
                rxNumber: context["rxNumber"] ?? "N/A",
                pharmacy: context["pharmacy"] ?? "Pharmacy",
                context: context
            )

        // Mail Mode Modals
        case "SignFormModal":
            return .signForm(card: card, context: context)

        case "QuickReplyModal":
            let recipientEmail = context["recipientEmail"] ?? card.sender?.email ?? "unknown@email.com"
            let subject = context["subject"] ?? "Re: \(card.title)"
            return .quickReply(card: card, recipientEmail: recipientEmail, subject: subject, context: context)

        case "AddToCalendarModal":
            return .addToCalendar(card: card, context: context)

        case "ScheduleMeetingModal":
            return .scheduleMeeting(card: card, context: context)

        case "AddReminderModal":
            return .setReminder(card: card, dueDate: context["dueDate"])

        case "DocumentViewerModal":
            return .viewDetails(card: card, context: context)

        case "SpreadsheetViewerModal":
            return .viewDetails(card: card, context: context)

        case "EmailComposerModal":
            let recipientEmail = context["recipientEmail"] ?? card.sender?.email ?? "unknown@email.com"
            let subject = context["subject"] ?? "Re: \(card.title)"
            return .quickReply(card: card, recipientEmail: recipientEmail, subject: subject, context: context)

        case "SaveForLaterModal":
            return .saveForLater(card: card, context: context)

        case "AttachmentViewerModal":
            return .viewAttachments(card: card, context: context)

        // Ads Mode Modals
        case "BrowseShoppingModal":
            return .browseShopping(card: card, context: context)

        case "ScheduledPurchaseModal":
            return .scheduledPurchase(card: card, context: context)

        case "ShoppingAutomationModal":
            let productUrl = context["productUrl"] ?? context["url"] ?? ""
            let productName = context["productName"] ?? "Product"
            return .automatedAddToCart(card: card, productUrl: productUrl, productName: productName, context: context)

        case "NewsletterSummaryModal":
            return .viewNewsletterSummary(card: card, context: context)

        case "CancelSubscriptionModal":
            return .cancelSubscription(card: card, context: context)

        case "UnsubscribeModal":
            guard let unsubscribeUrl = context["unsubscribeUrl"] else {
                Logger.warning("Missing unsubscribeUrl for UnsubscribeModal, using viewDetails", category: .action)
                return .viewDetails(card: card, context: context)
            }
            return .unsubscribe(card: card, unsubscribeUrl: unsubscribeUrl, context: context)

        // Shared Modals
        case "ViewDetailsModal":
            return .viewDetails(card: card, context: context)

        case "AddToWalletModal":
            return .addToWallet(card: card)

        case "SaveContactModal":
            return .saveContact(card: card)

        case "SendMessageModal":
            return .sendMessage(card: card)

        case "ShareModal":
            let shareContent = generateShareContent(from: card)
            return .share(card: card, content: shareContent)

        case "OpenAppModal":
            return .viewDetails(card: card, context: context)

        case "ReservationModal":
            return .viewReservation(card: card, context: context)

        // Legacy/Special Cases (still use hardcoded logic for complex behavior)
        case "RSVPModal":
            return .rsvp(card: card, response: actionId == "rsvp_yes")

        case "RateProductModal":
            return .rateProduct(card: card, productName: context["productName"] ?? "Product")

        case "PromoCodeModal":
            return .copyPromoCode(code: context["promoCode"] ?? "")

        case "PaymentModal":
            return .payment(card: card, amount: parseAmount(from: action.context), description: "Form Fee")

        case "TicketReplyModal":
            return .replyToTicket(card: card, ticketId: context["ticketId"])

        case "SecurityReviewModal":
            return .reviewSecurity(card: card, context: context)

        case "UpdatePaymentModal":
            return .updatePayment(card: card, context: context)

        default:
            Logger.warning("Unknown modal component '\(modalComponent)' for action '\(actionId)', using viewDetails", category: .action)
            return .viewDetails(card: card, context: context)
        }
    }
    
    private func parseAmount(from context: [String: String]?) -> Double {
        guard let amountString = context?["amount"] else { return 0.0 }
        return Double(amountString) ?? 0.0
    }

    /// Generate shareable content from email card
    private func generateShareContent(from card: EmailCard) -> String {
        var content = card.title

        // Add relevant context based on card type
        if !card.summary.isEmpty {
            content += "\n\n\(card.summary)"
        }

        // Extract specific shareable info from the email
        let body = card.body ?? ""

        // Tracking numbers
        if let trackingNumber = extractTrackingNumber(from: body) {
            content += "\n\nTracking: \(trackingNumber)"
        }

        // Confirmation codes
        if let confirmationCode = extractConfirmationCode(from: body) {
            content += "\n\nConfirmation: \(confirmationCode)"
        }

        // URLs (first one found)
        if let url = extractFirstURL(from: body) {
            content += "\n\n\(url)"
        }

        return content
    }

    private func extractTrackingNumber(from text: String) -> String? {
        // Common tracking number patterns
        let patterns = [
            #"1Z[0-9A-Z]{16}"#,  // UPS
            #"\d{12,14}"#,        // FedEx
            #"\d{20,22}"#         // USPS
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                if let range = Range(match.range, in: text) {
                    return String(text[range])
                }
            }
        }
        return nil
    }

    private func extractConfirmationCode(from text: String) -> String? {
        let pattern = #"confirmation\s*(?:code|number)?:?\s*([A-Z0-9]{6,12})"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        return nil
    }

    private func extractFirstURL(from text: String) -> String? {
        let pattern = #"https?://[^\s]+"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            return String(text[range])
        }
        return nil
    }
    
    // MARK: - Preview Modal Handling
    
    private func shouldShowPreview(for actionId: String) -> Bool {
        // Actions that benefit from showing evidence before execution
        let previewActions = ["track_package", "pay_invoice", "write_review", "check_in_flight"]
        return previewActions.contains(actionId)
    }
    
    private func showPreviewModal(for action: EmailAction, card: EmailCard) {
        let context = action.context ?? [:]

        switch action.actionId {
        case "track_package":
            if let trackingNumber = context["trackingNumber"],
               let carrier = context["carrier"],
               let url = context["url"] {
                DispatchQueue.main.async {
                    self.showingPreviewModal = .tracking(
                        card: card,
                        trackingNumber: trackingNumber,
                        carrier: carrier,
                        trackingUrl: url
                    )
                }
            } else {
                showError("Missing tracking information")
                Logger.warning("Missing required fields for tracking preview", category: .action)
            }

        case "pay_invoice":
            if let amount = context["amount"] ?? context["amountDue"],
               let url = context["paymentLink"] {
                let merchant = context["merchant"] ?? card.company?.name ?? "Merchant"
                DispatchQueue.main.async {
                    self.showingPreviewModal = .payment(
                        card: card,
                        amount: amount,
                        merchant: merchant,
                        paymentUrl: url
                    )
                }
            } else {
                showError("Missing payment information")
                Logger.warning("Missing required fields for payment preview", category: .action)
            }

        case "write_review":
            if let productName = context["productName"],
               let url = context["reviewLink"] {
                DispatchQueue.main.async {
                    self.showingPreviewModal = .review(
                        card: card,
                        productName: productName,
                        reviewUrl: url
                    )
                }
            } else {
                showError("Missing review information")
                Logger.warning("Missing required fields for review preview", category: .action)
            }

        default:
            // No preview, execute directly
            break
        }
    }

    // MARK: - Error Handling

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showingError = true

            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showingError = false
            }
        }
    }
    
    // MARK: - Compound Action Handling

    func executeCompoundAction(_ action: EmailAction, card: EmailCard) {
        guard let steps = action.compoundSteps, steps.count > 0 else {
            executeInAppAction(action, card: card)
            return
        }

        // Get compound definition for end behavior
        let compoundDef = CompoundActionRegistry.shared.getCompoundAction(action.actionId)

        // Show compound action flow modal with end behavior
        DispatchQueue.main.async {
            self.activeModal = .compoundFlow(
                card: card,
                steps: steps,
                context: action.context ?? [:],
                endBehavior: compoundDef?.endBehavior
            )
            self.showingModal = true
        }
    }
}

// MARK: - Action Preview Modal Types

enum ActionPreviewModal: Identifiable {
    case tracking(card: EmailCard, trackingNumber: String, carrier: String, trackingUrl: String)
    case payment(card: EmailCard, amount: String, merchant: String, paymentUrl: String)
    case review(card: EmailCard, productName: String, reviewUrl: String)
    
    var id: String {
        switch self {
        case .tracking(let card, _, _, _): return "track_preview_\(card.id)"
        case .payment(let card, _, _, _): return "payment_preview_\(card.id)"
        case .review(let card, _, _): return "review_preview_\(card.id)"
        }
    }
}

// MARK: - Action Modal Types

enum ActionModal: Identifiable {
    case signForm(card: EmailCard, context: [String: String])
    case payment(card: EmailCard, amount: Double, description: String)
    case addToCalendar(card: EmailCard, context: [String: String])
    case rsvp(card: EmailCard, response: Bool)
    case rateProduct(card: EmailCard, productName: String)
    case copyPromoCode(code: String)
    case setReminder(card: EmailCard, dueDate: String?)
    case quickReply(card: EmailCard, recipientEmail: String, subject: String, context: [String: Any])
    case saveForLater(card: EmailCard, context: [String: Any])
    case viewDetails(card: EmailCard, context: [String: Any])
    case replyToTicket(card: EmailCard, ticketId: String?)
    case compoundFlow(card: EmailCard, steps: [String], context: [String: String], endBehavior: CompoundActionDefinition.CompoundEndBehavior?)
    case viewNewsletterSummary(card: EmailCard, context: [String: Any])
    case browseShopping(card: EmailCard, context: [String: Any])
    case contactDriver(card: EmailCard, driverInfo: [String: Any])
    case viewPickupDetails(card: EmailCard, rxNumber: String, pharmacy: String, context: [String: Any])
    case trackPackage(card: EmailCard, trackingNumber: String, carrier: String, trackingUrl: String, context: [String: Any])
    case payInvoice(card: EmailCard, invoiceId: String, amount: String, merchant: String, context: [String: Any])
    case checkInFlight(card: EmailCard, flightNumber: String, airline: String, checkInUrl: String, context: [String: Any])
    case writeReview(card: EmailCard, productName: String, reviewLink: String, context: [String: Any])
    case scheduledPurchase(card: EmailCard, context: [String: Any])
    case scheduleMeeting(card: EmailCard, context: [String: Any])
    case reviewSecurity(card: EmailCard, context: [String: Any])
    case updatePayment(card: EmailCard, context: [String: Any])
    case archiveEmail(card: EmailCard)
    case acknowledge(card: EmailCard)
    case reportSuspicious(card: EmailCard)
    case resendEmail(card: EmailCard)
    case routeToCRM(card: EmailCard, context: [String: Any])
    case delegateTask(card: EmailCard, context: [String: Any])
    case compareProducts(card: EmailCard, context: [String: Any])
    case reviewApprove(card: EmailCard, context: [String: Any])

    // Native iOS Integrations
    case addToWallet(card: EmailCard)
    case addReminder(card: EmailCard, context: [String: Any])
    case saveContact(card: EmailCard)
    case sendMessage(card: EmailCard)
    case share(card: EmailCard, content: String)
    case viewReservation(card: EmailCard, context: [String: Any])

    // Subscription Management
    case cancelSubscription(card: EmailCard, context: [String: Any])
    case unsubscribe(card: EmailCard, unsubscribeUrl: String, context: [String: Any])

    // Attachment Viewing
    case viewAttachments(card: EmailCard, context: [String: Any])

    // Shopping Automation
    case automatedAddToCart(card: EmailCard, productUrl: String, productName: String, context: [String: Any])

    var id: String {
        switch self {
        case .signForm(let card, _): return "sign_\(card.id)"
        case .payment(let card, _, _): return "pay_\(card.id)"
        case .addToCalendar(let card, _): return "calendar_\(card.id)"
        case .rsvp(let card, _): return "rsvp_\(card.id)"
        case .rateProduct(let card, _): return "rate_\(card.id)"
        case .copyPromoCode(let code): return "promo_\(code)"
        case .setReminder(let card, _): return "reminder_\(card.id)"
        case .quickReply(let card, _, _, _): return "reply_\(card.id)"
        case .saveForLater(let card, _): return "save_\(card.id)"
        case .viewDetails(let card, _): return "details_\(card.id)"
        case .replyToTicket(let card, _): return "ticket_\(card.id)"
        case .compoundFlow(let card, _, _, _): return "compound_\(card.id)"
        case .viewNewsletterSummary(let card, _): return "newsletter_\(card.id)"
        case .browseShopping(let card, _): return "shop_\(card.id)"
        case .contactDriver(let card, _): return "driver_\(card.id)"
        case .viewPickupDetails(let card, _, _, _): return "pickup_\(card.id)"
        case .trackPackage(let card, _, _, _, _): return "track_\(card.id)"
        case .payInvoice(let card, _, _, _, _): return "payinvoice_\(card.id)"
        case .checkInFlight(let card, _, _, _, _): return "checkin_\(card.id)"
        case .writeReview(let card, _, _, _): return "review_\(card.id)"
        case .scheduledPurchase(let card, _): return "schedule_purchase_\(card.id)"
        case .scheduleMeeting(let card, _): return "schedule_meeting_\(card.id)"
        case .reviewSecurity(let card, _): return "review_security_\(card.id)"
        case .updatePayment(let card, _): return "update_payment_\(card.id)"
        case .archiveEmail(let card): return "archive_\(card.id)"
        case .acknowledge(let card): return "acknowledge_\(card.id)"
        case .reportSuspicious(let card): return "report_suspicious_\(card.id)"
        case .resendEmail(let card): return "resend_\(card.id)"
        case .routeToCRM(let card, _): return "route_crm_\(card.id)"
        case .delegateTask(let card, _): return "delegate_\(card.id)"
        case .compareProducts(let card, _): return "compare_\(card.id)"
        case .reviewApprove(let card, _): return "review_approve_\(card.id)"
        case .addToWallet(let card): return "wallet_\(card.id)"
        case .addReminder(let card, _): return "reminder_native_\(card.id)"
        case .saveContact(let card): return "contact_\(card.id)"
        case .sendMessage(let card): return "message_\(card.id)"
        case .share(let card, _): return "share_\(card.id)"
        case .viewReservation(let card, _): return "reservation_\(card.id)"
        case .cancelSubscription(let card, _): return "cancel_subscription_\(card.id)"
        case .unsubscribe(let card, _, _): return "unsubscribe_\(card.id)"
        case .viewAttachments(let card, _): return "attachments_\(card.id)"
        case .automatedAddToCart(let card, _, _, _): return "automated_add_to_cart_\(card.id)"
        }
    }
}

// MARK: - Helper Extensions

extension ActionRouter {
    /**
     * Get primary action from card's suggested actions
     */
    func getPrimaryAction(from card: EmailCard) -> EmailAction? {
        guard let actions = card.suggestedActions, !actions.isEmpty else {
            return nil
        }
        return actions.first(where: { $0.isPrimary }) ?? actions.first
    }
    
    /**
     * Get secondary actions from card's suggested actions
     */
    func getSecondaryActions(from card: EmailCard) -> [EmailAction] {
        guard let actions = card.suggestedActions else {
            return []
        }
        return actions.filter { !$0.isPrimary }
    }
}

