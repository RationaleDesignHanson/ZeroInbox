import SwiftUI

/// Handles routing logic for action modals
/// Extracted from ContentView's 160-line switch statement for maintainability
class ModalRouter {
    
    /// Modal types that can be presented
    enum ModalDestination {
        // Existing cases
        case documentViewer(card: EmailCard)
        case spreadsheetViewer(card: EmailCard)
        case scheduleMeeting(card: EmailCard)
        case emailComposer(card: EmailCard, recipient: String? = nil, subject: String? = nil)
        case signForm(card: EmailCard, onComplete: (String) -> Void)
        case openApp(card: EmailCard)
        case openURL(url: String)
        case addToCalendar(card: EmailCard)
        case scheduledPurchase(card: EmailCard, action: EmailAction)
        case shoppingPurchase(card: EmailCard, selectedAction: String?)
        case snoozePicker(onConfirm: () -> Void)
        case saveForLater(card: EmailCard)
        case viewAttachments(card: EmailCard)
        case fallback(card: EmailCard)

        // Newly wired existing modals (Phase 3A)
        case addReminder(card: EmailCard)
        case addToWallet(card: EmailCard)
        case browseShopping(card: EmailCard)
        case cancelSubscription(card: EmailCard)
        case checkInFlight(card: EmailCard)
        case contactDriver(card: EmailCard)
        case newsletterSummary(card: EmailCard)
        case payInvoice(card: EmailCard)
        case pickupDetails(card: EmailCard)
        case quickReply(card: EmailCard)
        case reservation(card: EmailCard)
        case saveContact(card: EmailCard)
        case sendMessage(card: EmailCard)
        case share(card: EmailCard)
        case snooze(card: EmailCard)
        case trackPackage(card: EmailCard)
        case unsubscribe(card: EmailCard)
        case writeReview(card: EmailCard)

        // Phase 3B: New high-priority modals
        case addToNotes(card: EmailCard)

        // Phase 3C: Remaining HIGH priority modals
        case provideAccessCode(card: EmailCard)
        case viewActivity(card: EmailCard)
        case saveProperties(card: EmailCard)

        // Phase 3D: MEDIUM priority modals
        case scheduleDeliveryTime(card: EmailCard)
        case prepareForOutage(card: EmailCard)
        case viewActivityDetails(card: EmailCard)
        case readCommunityPost(card: EmailCard)

        // Phase 3E: LOW priority modals
        case viewOutageDetails(card: EmailCard)
        case viewPostComments(card: EmailCard)

        // Shopping Automation
        case shoppingAutomation(card: EmailCard, productUrl: String, productName: String)
    }

    /// Route an action to the appropriate modal
    /// - Parameters:
    ///   - card: The email card to route
    ///   - selectedActionId: Optional override action ID
    /// - Returns: The modal destination to present
    static func route(card: EmailCard, selectedActionId: String?) -> ModalDestination {
        let actionToRoute = selectedActionId ?? card.hpa
        let normalizedAction = actionToRoute.lowercased().replacingOccurrences(of: " ", with: "_")
        
        Logger.debug("Routing action: \(actionToRoute) -> \(normalizedAction)", category: .modal)
        Logger.debug("Card type: \(card.type), requiresSignature: \(String(describing: card.requiresSignature))", category: .modal)
        
        // Document review
        if normalizedAction.contains("review_approve") ||
           normalizedAction.contains("review_document") ||
           normalizedAction.contains("approve_document") ||
           normalizedAction.contains("view_document") ||
           (normalizedAction.contains("review") && normalizedAction.contains("approve")) ||
           (normalizedAction.contains("review") && normalizedAction.contains("document")) {
            Logger.info("Routing to DocumentViewerModal", category: .modal)
            return .documentViewer(card: card)
        }

        // Spreadsheet/Budget
        if normalizedAction.contains("budget") ||
           normalizedAction.contains("spreadsheet") ||
           normalizedAction.contains("view_budget") ||
           normalizedAction.contains("review_budget") ||
           normalizedAction.contains("auto_route") {
            Logger.info("Routing to SpreadsheetViewerModal", category: .modal)
            return .spreadsheetViewer(card: card)
        }
        
        // Schedule meeting/demo
        if normalizedAction.contains("schedule_demo") ||
           normalizedAction.contains("schedule_review") ||
           normalizedAction.contains("schedule_call") ||
           normalizedAction.contains("book_meeting") ||
           normalizedAction.contains("arrange_meeting") ||
           (normalizedAction.contains("schedule") && normalizedAction.contains("meeting")) ||
           (normalizedAction.contains("schedule") && normalizedAction.contains("call")) ||
           (normalizedAction.contains("book") && normalizedAction.contains("appointment")) {
            Logger.info("Routing to ScheduleMeetingModal", category: .modal)
            return .scheduleMeeting(card: card)
        }
        
        // CRM routing
        if normalizedAction.contains("route_crm") || 
           normalizedAction.contains("crm") || 
           normalizedAction.contains("route") {
            Logger.info("Routing to EmailComposerModal (CRM)", category: .modal)
            return .emailComposer(
                card: card,
                recipient: "Steve (Sales Manager)",
                subject: "Lead: \(card.company?.name ?? card.title)"
            )
        }
        
        // Sign & send
        if normalizedAction.contains("sign_send") ||
           normalizedAction.contains("sign_form") ||
           normalizedAction.contains("sign_permission") ||
           normalizedAction.contains("approve_sign") ||
           normalizedAction.contains("esign") ||
           normalizedAction.contains("sign") ||
           card.requiresSignature == true {
            Logger.info("Routing to SignFormModal", category: .modal)
            // Note: onComplete callback will be provided by caller
            return .signForm(card: card, onComplete: { _ in })
        }
        
        // Open in app
        if normalizedAction.contains("open_app") || 
           (normalizedAction.contains("open") && normalizedAction.contains("app")) {
            Logger.info("Routing to OpenAppModal", category: .modal)
            return .openApp(card: card)
        }
        
        // Calendar actions (excluding meeting scheduling and purchases)
        if normalizedAction.contains("add_to_calendar") ||
           normalizedAction.contains("save_date") ||
           normalizedAction.contains("add_event") ||
           (normalizedAction.contains("calendar") && !normalizedAction.contains("schedule")) ||
           (normalizedAction.contains("schedule") && !normalizedAction.contains("purchase") && !normalizedAction.contains("meeting") && !normalizedAction.contains("call") && !normalizedAction.contains("demo")) {
            Logger.info("Routing to AddToCalendarModal", category: .modal)
            return .addToCalendar(card: card)
        }
        
        // Scheduled purchase
        if normalizedAction.contains("schedule_purchase") ||
           (normalizedAction.contains("buy") && normalizedAction.contains("on")) {
            Logger.info("Routing to ScheduledPurchaseModal", category: .modal)
            if let action = card.suggestedActions?.first(where: { $0.actionId == "schedule_purchase" }) {
                return .scheduledPurchase(card: card, action: action)
            } else {
                Logger.warning("No schedule_purchase action found, falling back to email composer", category: .modal)
                return .emailComposer(card: card)
            }
        }

        // ========== PHASE 3A: Newly Wired Modals ==========

        // Quick Reply
        if normalizedAction.contains("quick_reply") {
            Logger.info("Routing to QuickReplyModal", category: .modal)
            return .quickReply(card: card)
        }

        // Pay Invoice
        if normalizedAction.contains("pay_invoice") {
            Logger.info("Routing to PayInvoiceModal", category: .modal)
            return .payInvoice(card: card)
        }

        // Track Package (IN_APP modal instead of GO_TO)
        if normalizedAction.contains("track_package") && card.suggestedActions?.first(where: { $0.actionId == "track_package" && $0.actionType.rawValue == "IN_APP" }) != nil {
            Logger.info("Routing to TrackPackageModal (IN_APP)", category: .modal)
            return .trackPackage(card: card)
        }

        // Contact Driver
        if normalizedAction.contains("contact_driver") {
            Logger.info("Routing to ContactDriverModal", category: .modal)
            return .contactDriver(card: card)
        }

        // Pickup Details
        if normalizedAction.contains("pickup") || normalizedAction.contains("view_pickup_details") {
            Logger.info("Routing to PickupDetailsModal", category: .modal)
            return .pickupDetails(card: card)
        }

        // Newsletter Summary (PREMIUM)
        if normalizedAction.contains("view_newsletter_summary") || normalizedAction.contains("newsletter_summary") {
            Logger.info("Routing to NewsletterSummaryModal", category: .modal)
            return .newsletterSummary(card: card)
        }

        // Add Reminder
        if normalizedAction.contains("add_reminder") || normalizedAction.contains("set_reminder") {
            Logger.info("Routing to AddReminderModal", category: .modal)
            return .addReminder(card: card)
        }

        // Add to Wallet (boarding passes, tickets, etc.)
        if normalizedAction.contains("add_to_wallet") || normalizedAction.contains("wallet") {
            Logger.info("Routing to AddToWalletModal", category: .modal)
            return .addToWallet(card: card)
        }

        // Save Contact
        if normalizedAction.contains("save_contact") {
            Logger.info("Routing to SaveContactModal", category: .modal)
            return .saveContact(card: card)
        }

        // Send Message (SMS/iMessage)
        if normalizedAction.contains("send_message") {
            Logger.info("Routing to SendMessageModal", category: .modal)
            return .sendMessage(card: card)
        }

        // Share (iOS Share Sheet)
        if normalizedAction.contains("share") && !normalizedAction.contains("team") {
            Logger.info("Routing to ShareModal", category: .modal)
            return .share(card: card)
        }

        // Write Review / Rate Product
        if normalizedAction.contains("write_review") || normalizedAction.contains("rate_product") || normalizedAction.contains("rate") {
            Logger.info("Routing to WriteReviewModal", category: .modal)
            return .writeReview(card: card)
        }

        // Cancel Subscription
        if normalizedAction.contains("cancel_subscription") {
            Logger.info("Routing to CancelSubscriptionModal", category: .modal)
            return .cancelSubscription(card: card)
        }

        // Unsubscribe
        if normalizedAction.contains("unsubscribe") {
            Logger.info("Routing to UnsubscribeModal", category: .modal)
            return .unsubscribe(card: card)
        }

        // Shopping Automation (AI-powered cart addition)
        if normalizedAction.contains("automated_add_to_cart") || normalizedAction.contains("add_to_cart_checkout") {
            Logger.info("Routing to ShoppingAutomationModal", category: .modal)
            // Extract productUrl and productName from action context
            if let action = card.suggestedActions?.first(where: { $0.actionId == "automated_add_to_cart" }),
               let context = action.context {
                let productUrl = context["productUrl"] ?? context["url"] ?? ""
                let productName = context["productName"] ?? card.title
                return .shoppingAutomation(card: card, productUrl: productUrl, productName: productName)
            } else {
                Logger.warning("Missing context for automated_add_to_cart, using fallback", category: .modal)
                return .shoppingPurchase(card: card, selectedAction: selectedActionId)
            }
        }

        // Browse Shopping
        if normalizedAction.contains("browse_shopping") || normalizedAction.contains("browse") {
            Logger.info("Routing to BrowseShoppingModal", category: .modal)
            return .browseShopping(card: card)
        }

        // Snooze (dedicated modal instead of picker)
        if normalizedAction == "snooze" || normalizedAction.contains("snooze_email") {
            Logger.info("Routing to SnoozeModal", category: .modal)
            return .snooze(card: card)
        }

        // Check In Flight (IN_APP modal when available, otherwise GO_TO)
        if normalizedAction.contains("check_in_flight") && card.suggestedActions?.first(where: { $0.actionId == "check_in_flight" && $0.actionType.rawValue == "IN_APP" }) != nil {
            Logger.info("Routing to CheckInFlightModal (IN_APP)", category: .modal)
            return .checkInFlight(card: card)
        }

        // Reservation (IN_APP modal when available, otherwise GO_TO)
        if normalizedAction.contains("view_reservation") && card.suggestedActions?.first(where: { $0.actionId == "view_reservation" && $0.actionType.rawValue == "IN_APP" }) != nil {
            Logger.info("Routing to ReservationModal (IN_APP)", category: .modal)
            return .reservation(card: card)
        }

        // ========== PHASE 3B: New High-Priority Modals ==========

        // Add to Notes
        if normalizedAction.contains("add_to_notes") || normalizedAction.contains("save_to_notes") {
            Logger.info("Routing to AddToNotesModal", category: .modal)
            return .addToNotes(card: card)
        }

        // Provide Access Code
        if normalizedAction.contains("provide_access_code") || normalizedAction.contains("access_code") {
            Logger.info("Routing to ProvideAccessCodeModal", category: .modal)
            return .provideAccessCode(card: card)
        }

        // View Activity / RSVP
        if normalizedAction.contains("view_activity") || normalizedAction.contains("rsvp") {
            Logger.info("Routing to ViewActivityModal", category: .modal)
            return .viewActivity(card: card)
        }

        // Save Properties
        if normalizedAction.contains("save_properties") || normalizedAction.contains("save_listing") {
            Logger.info("Routing to SavePropertiesModal", category: .modal)
            return .saveProperties(card: card)
        }

        // ========== PHASE 3D: MEDIUM Priority Modals ==========

        // Schedule Delivery Time
        if normalizedAction.contains("schedule_delivery") || normalizedAction.contains("choose_delivery_time") {
            Logger.info("Routing to ScheduleDeliveryTimeModal", category: .modal)
            return .scheduleDeliveryTime(card: card)
        }

        // Prepare for Outage
        if normalizedAction.contains("prepare_for_outage") || normalizedAction.contains("outage_preparation") {
            Logger.info("Routing to PrepareForOutageModal", category: .modal)
            return .prepareForOutage(card: card)
        }

        // View Activity Details
        if normalizedAction.contains("view_activity_details") || normalizedAction.contains("activity_itinerary") {
            Logger.info("Routing to ViewActivityDetailsModal", category: .modal)
            return .viewActivityDetails(card: card)
        }

        // Read Community Post
        if normalizedAction.contains("read_community_post") || normalizedAction.contains("read_post") || normalizedAction.contains("community_post") {
            Logger.info("Routing to ReadCommunityPostModal", category: .modal)
            return .readCommunityPost(card: card)
        }

        // ========== PHASE 3E: LOW Priority Modals ==========

        // View Outage Details
        if normalizedAction.contains("view_outage_details") || normalizedAction.contains("outage_status") || normalizedAction.contains("outage_info") {
            Logger.info("Routing to ViewOutageDetailsModal", category: .modal)
            return .viewOutageDetails(card: card)
        }

        // View Post Comments
        if normalizedAction.contains("view_post_comments") || normalizedAction.contains("view_comments") || normalizedAction.contains("read_comments") {
            Logger.info("Routing to ViewPostCommentsModal", category: .modal)
            return .viewPostComments(card: card)
        }

        // Shopping/deals
        if normalizedAction.contains("claim_deal") ||
           normalizedAction.contains("save_deal") ||
           normalizedAction.contains("compare") ||
           normalizedAction.contains("view_offer") {
            Logger.info("Routing to ShoppingPurchaseModal", category: .modal)
            // Note: viewModel will be provided by caller
            return .shoppingPurchase(card: card, selectedAction: selectedActionId)
        }

        // Book browsing (special case for shopping)
        if (normalizedAction.contains("view_details") || normalizedAction.contains("browse")) &&
            (card.title.lowercased().contains("book") ||
             card.summary.lowercased().contains("book") ||
             (card.body ?? "").lowercased().contains("book") ||
             card.summary.lowercased().contains("scholastic")) {
            Logger.info("Routing to ShoppingPurchaseModal (books)", category: .modal)
            return .shoppingPurchase(card: card, selectedAction: "browse_books")
        }

        // General shopping view for shop category cards
        if (normalizedAction.contains("view") || normalizedAction.contains("browse")) &&
           card.type == .ads {
            Logger.info("Routing to ShoppingPurchaseModal (general shop view)", category: .modal)
            return .shoppingPurchase(card: card, selectedAction: selectedActionId)
        }
        
        // Unsubscribe
        if normalizedAction.contains("not_interested") {
            Logger.info("Routing to EmailComposerModal (unsubscribe)", category: .modal)
            return .emailComposer(
                card: card,
                recipient: card.store,
                subject: "Unsubscribe Request"
            )
        }
        
        // Acknowledgment
        if normalizedAction.contains("acknowledge") || 
           normalizedAction.contains("confirm") || 
           normalizedAction.contains("express_interest") {
            Logger.info("Routing to EmailComposerModal (acknowledgment)", category: .modal)
            return .emailComposer(card: card)
        }
        
        // Delegation/sharing
        if normalizedAction.contains("delegate") || normalizedAction.contains("share_team") {
            Logger.info("Routing to EmailComposerModal (delegation)", category: .modal)
            return .emailComposer(card: card, subject: "FW: \(card.title)")
        }
        
        // Sales actions
        if normalizedAction.contains("fast_followup") || normalizedAction.contains("disqualify") {
            Logger.info("Routing to EmailComposerModal (sales action)", category: .modal)
            return .emailComposer(card: card)
        }
        
        // File by project
        if normalizedAction.contains("file_project") {
            Logger.info("Routing to SnoozePickerModal (file)", category: .modal)
            return .snoozePicker(onConfirm: {})
        }
        
        // Travel actions
        if normalizedAction.contains("check_in") || normalizedAction.contains("enroll") {
            Logger.info("Routing to EmailComposerModal (travel)", category: .modal)
            return .emailComposer(card: card)
        }
        
        // Security actions
        if normalizedAction.contains("verify") || 
           normalizedAction.contains("confirm_deny") || 
           normalizedAction.contains("report_suspicious") {
            Logger.info("Routing to EmailComposerModal (security)", category: .modal)
            return .emailComposer(card: card)
        }
        
        // Save for later / View later - Route to dedicated modal (NOT snooze picker)
        // IMPORTANT: This must come BEFORE generic "view...later" pattern to avoid false matches
        if normalizedAction.contains("save_for_later") ||
           normalizedAction == "save_later" ||
           normalizedAction == "view_later" ||
           normalizedAction.contains("save") && normalizedAction.contains("later") {
            Logger.info("Routing to SaveForLaterModal", category: .modal)
            return .saveForLater(card: card)
        }

        // Archive - Route to snooze picker
        if normalizedAction.contains("archive") {
            Logger.info("Routing to SnoozePickerModal (archive)", category: .modal)
            return .snoozePicker(onConfirm: {})
        }

        // Remind me / Snooze
        if normalizedAction.contains("remind") || normalizedAction.contains("snooze") {
            Logger.info("Routing to SnoozePickerModal (remind)", category: .modal)
            return .snoozePicker(onConfirm: {})
        }

        // View/Read later (for reading content, NOT saving)
        // Guard: Don't match if "save" or "later" together (those go to SaveForLaterModal above)
        if normalizedAction.contains("view") && normalizedAction.contains("read") &&
           !(normalizedAction.contains("save") || normalizedAction.contains("later")) {
            Logger.info("Routing to SnoozePickerModal (read later)", category: .modal)
            return .snoozePicker(onConfirm: {})
        }

        // ========== GO_TO ACTIONS (Open URLs) ==========

        // Track package
        if normalizedAction.contains("track_package") || normalizedAction.contains("track") {
            Logger.info("Routing to URL (track package)", category: .modal)
            if let action = card.suggestedActions?.first(where: { $0.actionId == "track_package" }),
               let context = action.context,
               let url = context["url"] {
                return .openURL(url: url)
            } else if let action = card.suggestedActions?.first(where: { $0.actionId.contains("track") }),
                      let context = action.context,
                      let url = context["url"] {
                return .openURL(url: url)
            }
        }

        // View order
        if normalizedAction.contains("view_order") {
            Logger.info("Routing to URL (view order)", category: .modal)
            if let action = card.suggestedActions?.first(where: { $0.actionId == "view_order" }),
               let context = action.context,
               let url = context["url"] {
                return .openURL(url: url)
            }
        }

        // Track delivery (food)
        if normalizedAction.contains("track_delivery") {
            Logger.info("Routing to URL (track delivery)", category: .modal)
            if let action = card.suggestedActions?.first(where: { $0.actionId == "track_delivery" }),
               let context = action.context,
               let url = context["url"] {
                return .openURL(url: url)
            }
        }

        // View reservation (restaurant)
        if normalizedAction.contains("view_reservation") {
            Logger.info("Routing to URL (view reservation)", category: .modal)
            if let action = card.suggestedActions?.first(where: { $0.actionId == "view_reservation" }),
               let context = action.context,
               let url = context["url"] {
                return .openURL(url: url)
            }
        }

        // Modify reservation
        if normalizedAction.contains("modify_reservation") {
            Logger.info("Routing to URL (modify reservation)", category: .modal)
            if let action = card.suggestedActions?.first(where: { $0.actionId == "modify_reservation" }),
               let context = action.context,
               let url = context["url"] {
                return .openURL(url: url)
            }
        }

        // Manage subscription
        if normalizedAction.contains("manage_subscription") {
            Logger.info("Routing to URL (manage subscription)", category: .modal)
            if let action = card.suggestedActions?.first(where: { $0.actionId == "manage_subscription" }),
               let context = action.context,
               let url = context["url"] {
                return .openURL(url: url)
            }
        }

        // Update payment
        if normalizedAction.contains("update_payment") {
            Logger.info("Routing to URL (update payment)", category: .modal)
            if let action = card.suggestedActions?.first(where: { $0.actionId == "update_payment" }),
               let context = action.context,
               let url = context["url"] {
                return .openURL(url: url)
            }
        }

        // Get directions
        if normalizedAction.contains("get_directions") {
            Logger.info("Routing to URL (get directions)", category: .modal)
            if let action = card.suggestedActions?.first(where: { $0.actionId == "get_directions" }),
               let context = action.context,
               let url = context["url"] {
                return .openURL(url: url)
            }
        }

        // View results (healthcare)
        if normalizedAction.contains("view_results") {
            Logger.info("Routing to URL (view results)", category: .modal)
            if let action = card.suggestedActions?.first(where: { $0.actionId == "view_results" }),
               let context = action.context,
               let url = context["url"] {
                return .openURL(url: url)
            }
        }

        // Check in appointment (healthcare)
        if normalizedAction.contains("check_in_appointment") {
            Logger.info("Routing to URL (check in appointment)", category: .modal)
            if let action = card.suggestedActions?.first(where: { $0.actionId == "check_in_appointment" }),
               let context = action.context,
               let url = context["url"] {
                return .openURL(url: url)
            }
        }

        // Check in flight
        if normalizedAction.contains("check_in_flight") {
            Logger.info("Routing to URL (check in flight)", category: .modal)
            if let action = card.suggestedActions?.first(where: { $0.actionId == "check_in_flight" }),
               let context = action.context,
               let url = context["url"] {
                return .openURL(url: url)
            }
        }

        // View itinerary
        if normalizedAction.contains("view_itinerary") {
            Logger.info("Routing to URL (view itinerary)", category: .modal)
            if let action = card.suggestedActions?.first(where: { $0.actionId == "view_itinerary" }),
               let context = action.context,
               let url = context["url"] {
                return .openURL(url: url)
            }
        }

        // Open link (generic URL action)
        if normalizedAction.contains("open_link") {
            Logger.info("Routing to URL (open link)", category: .modal)
            if let action = card.suggestedActions?.first(where: { $0.actionId == "open_link" }),
               let context = action.context,
               let url = context["url"] {
                return .openURL(url: url)
            }
        }

        // Payment actions (not covered by other routes)
        if normalizedAction.contains("pay") ||
           normalizedAction.contains("payment") ||
           normalizedAction.contains("invoice") ||
           normalizedAction.contains("bill") {
            Logger.info("Routing to payment action", category: .modal)
            // Try to find URL from action context
            if let action = card.suggestedActions?.first(where: { $0.actionId.lowercased().contains("pay") || $0.displayName.lowercased().contains("pay") }),
               let context = action.context,
               let url = context["url"] {
                return .openURL(url: url)
            }
            // Otherwise use email composer
            return .emailComposer(card: card, subject: "Payment for \(card.title)")
        }

        // Reply/Respond actions
        if normalizedAction.contains("reply") ||
           normalizedAction.contains("respond") ||
           normalizedAction.contains("answer") {
            Logger.info("Routing to EmailComposerModal (reply)", category: .modal)
            return .emailComposer(card: card)
        }

        // Generic GO_TO action fallback - Enhanced to try multiple matching strategies
        // Strategy 1: Match by exact actionId
        if let selectedId = selectedActionId,
           let action = card.suggestedActions?.first(where: { $0.actionId == selectedId }),
           action.actionType.rawValue == "GO_TO",
           let context = action.context,
           let url = context["url"] {
            Logger.info("Routing to URL (GO_TO by actionId): \(url)", category: .modal)
            return .openURL(url: url)
        }

        // Strategy 2: Match by normalized action name
        if let action = card.suggestedActions?.first(where: { $0.displayName.lowercased().replacingOccurrences(of: " ", with: "_") == normalizedAction }),
           action.actionType.rawValue == "GO_TO",
           let context = action.context,
           let url = context["url"] {
            Logger.info("Routing to URL (GO_TO by displayName): \(url)", category: .modal)
            return .openURL(url: url)
        }

        // Strategy 3: Match by actionId containing the normalized action
        if let action = card.suggestedActions?.first(where: { $0.actionId.lowercased().contains(normalizedAction) }),
           action.actionType.rawValue == "GO_TO",
           let context = action.context,
           let url = context["url"] {
            Logger.info("Routing to URL (GO_TO by partial match): \(url)", category: .modal)
            return .openURL(url: url)
        }

        // Strategy 4: If there's only one GO_TO action, use it
        let goToActions = card.suggestedActions?.filter { $0.actionType.rawValue == "GO_TO" } ?? []
        if goToActions.count == 1,
           let action = goToActions.first,
           let context = action.context,
           let url = context["url"] {
            Logger.info("Routing to URL (single GO_TO action): \(url)", category: .modal)
            return .openURL(url: url)
        }

        // Default fallback
        Logger.info("Routing to EmailComposerModal (default fallback)", category: .modal)
        return .fallback(card: card)
    }
}

