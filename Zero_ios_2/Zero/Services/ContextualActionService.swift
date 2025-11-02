import Foundation
import SwiftUI

/// Service for generating context-aware action suggestions based on email content
class ContextualActionService {
    static let shared = ContextualActionService()

    // MARK: - Action Suggestion

    /// Generate contextual action suggestions for an email
    func suggestActions(for card: EmailCard) -> [ContextualAction] {
        var suggestions: [ContextualAction] = []

        // Analyze email content for action opportunities
        let content = (card.body ?? card.summary).lowercased()
        let subject = card.title.lowercased()

        // 1. Calendar Events
        suggestions.append(contentsOf: detectEventOpportunities(card: card, content: content, subject: subject))

        // 2. Reminders
        if let reminderSuggestion = detectReminderOpportunity(card: card, content: content, subject: subject) {
            suggestions.append(reminderSuggestion)
        }

        // 3. Payment/Financial Actions
        if let paymentSuggestion = detectPaymentOpportunity(card: card, content: content, subject: subject) {
            suggestions.append(paymentSuggestion)
        }

        // 4. Shopping Actions (can return multiple)
        suggestions.append(contentsOf: detectShoppingOpportunities(card: card, content: content, subject: subject))

        // 5. Document Actions
        if let documentSuggestion = detectDocumentOpportunity(card: card, content: content, subject: subject) {
            suggestions.append(documentSuggestion)
        }

        // 6. Contact Actions
        if let contactSuggestion = detectContactOpportunity(card: card, content: content, subject: subject) {
            suggestions.append(contactSuggestion)
        }

        // 7. Quick Reply Suggestions
        if let replySuggestion = detectReplyOpportunity(card: card, content: content, subject: subject) {
            suggestions.append(replySuggestion)
        }

        // 8. Native iOS Integrations - Add to Wallet
        if let walletSuggestion = detectWalletOpportunity(card: card, content: content, subject: subject) {
            suggestions.append(walletSuggestion)
        }

        // 9. Native iOS Integrations - Save Contact
        if let contactSaveSuggestion = detectSaveContactOpportunity(card: card, content: content, subject: subject) {
            suggestions.append(contactSaveSuggestion)
        }

        // 10. Native iOS Integrations - Send Message (SMS/iMessage)
        if let messageSuggestion = detectSendMessageOpportunity(card: card, content: content, subject: subject) {
            suggestions.append(messageSuggestion)
        }

        // 11. Native iOS Integrations - Share
        if let shareSuggestion = detectShareOpportunity(card: card, content: content, subject: subject) {
            suggestions.append(shareSuggestion)
        }

        // Sort by priority (critical first)
        return suggestions.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }

    // MARK: - Detection Methods

    private func detectEventOpportunities(card: EmailCard, content: String, subject: String) -> [ContextualAction] {
        var actions: [ContextualAction] = []

        // Check if email contains event-related keywords
        let eventKeywords = ["meeting", "appointment", "event", "conference", "webinar", "class", "field trip", "rsvp"]

        guard eventKeywords.contains(where: { content.contains($0) || subject.contains($0) }) else {
            return []
        }

        // Check if we already have thread data with event
        if let threadData = card.threadData,
           !threadData.context.upcomingEvents.isEmpty {
            let event = threadData.context.upcomingEvents[0]
            actions.append(ContextualAction(
                id: UUID().uuidString,
                type: .addToCalendar,
                title: "Add to Calendar",
                description: "Add \(event.originalText) to your calendar",
                icon: "calendar.badge.plus",
                color: .blue,
                priority: .high,
                handler: {
                    // Calendar action will be handled by CalendarManager
                    Logger.info("Adding event to calendar", category: .action)
                }
            ))
        } else {
            actions.append(ContextualAction(
                id: UUID().uuidString,
                type: .addToCalendar,
                title: "Add to Calendar",
                description: "Add this event to your calendar",
                icon: "calendar.badge.plus",
                color: .blue,
                priority: .medium,
                handler: {
                    Logger.info("Creating calendar event", category: .action)
                }
            ))
        }

        return actions
    }

    private func detectReminderOpportunity(card: EmailCard, content: String, subject: String) -> ContextualAction? {
        // Check for deadline/reminder keywords
        let reminderKeywords = ["due", "deadline", "reminder", "don't forget", "remember to", "expires", "by"]

        guard reminderKeywords.contains(where: { content.contains($0) || subject.contains($0) }) else {
            return nil
        }

        return ContextualAction(
            id: UUID().uuidString,
            type: .setReminder,
            title: "Set Reminder",
            description: "Create a reminder for this deadline",
            icon: "bell.badge.fill",
            color: .orange,
            priority: .high,
            handler: {
                Logger.info("Setting reminder", category: .action)
            }
        )
    }

    private func detectPaymentOpportunity(card: EmailCard, content: String, subject: String) -> ContextualAction? {
        // Check for payment keywords
        let paymentKeywords = ["invoice", "bill", "payment due", "pay now", "amount due", "$"]

        guard paymentKeywords.contains(where: { content.contains($0) || subject.contains($0) }) else {
            return nil
        }

        // If we have invoice data from thread data
        if let threadData = card.threadData,
           !threadData.context.purchases.isEmpty,
           let purchase = threadData.context.purchases.first,
           let amount = purchase.amount {

            return ContextualAction(
                id: UUID().uuidString,
                type: .makePayment,
                title: "Pay Now",
                description: "Pay $\(String(format: "%.2f", amount))",
                icon: "creditcard.fill",
                color: .green,
                priority: .critical,
                handler: {
                    Logger.info("Opening payment flow", category: .action)
                }
            )
        }

        return ContextualAction(
            id: UUID().uuidString,
            type: .makePayment,
            title: "View Invoice",
            description: "Review and pay invoice",
            icon: "doc.text.fill",
            color: .purple,
            priority: .high,
            handler: {
                Logger.info("Opening invoice", category: .action)
            }
        )
    }

    private func detectShoppingOpportunities(card: EmailCard, content: String, subject: String) -> [ContextualAction] {
        var actions: [ContextualAction] = []

        // Check for supply/purchase needs (science fair, school events, etc.)
        let supplyKeywords = ["supplies", "materials", "bring", "need to purchase", "need to buy", "get", "pick up"]
        let hasSupplyNeed = supplyKeywords.contains(where: { content.contains($0) || subject.contains($0) })

        if hasSupplyNeed {
            // Check for specific supply mentions in thread data
            if let threadData = card.threadData,
               !threadData.context.purchases.isEmpty {
                let purchase = threadData.context.purchases[0]
                let itemDescription = purchase.invoiceNumber ?? "required items"
                actions.append(ContextualAction(
                    id: UUID().uuidString,
                    type: .purchaseSupplies,
                    title: "Purchase Supplies",
                    description: "Get \(itemDescription)",
                    icon: "cart.fill",
                    color: .green,
                    priority: .high,
                    handler: {
                        Logger.info("Opening shopping for supplies", category: .action)
                    }
                ))
            } else {
                // Generic supply purchase action
                actions.append(ContextualAction(
                    id: UUID().uuidString,
                    type: .purchaseSupplies,
                    title: "Purchase Supplies",
                    description: "Get required items",
                    icon: "cart.fill",
                    color: .green,
                    priority: .high,
                    handler: {
                        Logger.info("Opening shopping for supplies", category: .action)
                    }
                ))
            }
        }

        // Check for shopping cards
        if card.type == .ads || card.type == .ads {
            // Check for time-sensitive shopping opportunities
            if content.contains("sale ends") || content.contains("limited time") || content.contains("expires") {
                actions.append(ContextualAction(
                    id: UUID().uuidString,
                    type: .shopNow,
                    title: "Shop Before It Ends",
                    description: "Limited time offer - act fast!",
                    icon: "timer",
                    color: .red,
                    priority: .critical,
                    handler: {
                        Logger.info("Opening shopping link", category: .action)
                    }
                ))
            } else if let _ = card.salePrice {
                actions.append(ContextualAction(
                    id: UUID().uuidString,
                    type: .shopNow,
                    title: "View Deal",
                    description: "Check out this discounted item",
                    icon: "tag.fill",
                    color: .green,
                    priority: .medium,
                    handler: {
                        Logger.info("Opening product page", category: .action)
                    }
                ))
            }
        }

        // Check for book-related content
        let bookKeywords = ["book", "reading", "library", "novel", "author", "browse books"]
        if bookKeywords.contains(where: { content.contains($0) || subject.contains($0) }) {
            actions.append(ContextualAction(
                id: UUID().uuidString,
                type: .browseBooks,
                title: "Browse Books",
                description: "Find related books",
                icon: "book.fill",
                color: .orange,
                priority: .medium,
                handler: {
                    Logger.info("Opening book browser", category: .action)
                }
            ))
        }

        return actions
    }

    private func detectDocumentOpportunity(card: EmailCard, content: String, subject: String) -> ContextualAction? {
        // Check for document keywords
        let documentKeywords = ["attached", "attachment", "pdf", "document", "form", "sign", "review"]

        guard documentKeywords.contains(where: { content.contains($0) || subject.contains($0) }) else {
            return nil
        }

        if card.requiresSignature == true {
            return ContextualAction(
                id: UUID().uuidString,
                type: .signDocument,
                title: "Sign Form",
                description: "Digital signature required",
                icon: "signature",
                color: .purple,
                priority: .high,
                handler: {
                    Logger.info("Opening signature modal", category: .action)
                }
            )
        }

        return ContextualAction(
            id: UUID().uuidString,
            type: .openDocument,
            title: "View Attachment",
            description: "Open attached document",
            icon: "doc.fill",
            color: .blue,
            priority: .medium,
            handler: {
                Logger.info("Opening document", category: .action)
            }
        )
    }

    private func detectContactOpportunity(card: EmailCard, content: String, subject: String) -> ContextualAction? {
        // Check for contact-related keywords
        let contactKeywords = ["call me", "phone", "contact", "reach out", "get in touch"]

        guard contactKeywords.contains(where: { content.contains($0) || subject.contains($0) }) else {
            return nil
        }

        return ContextualAction(
            id: UUID().uuidString,
            type: .saveContact,
            title: "Save Contact",
            description: "Add sender to contacts",
            icon: "person.crop.circle.badge.plus",
            color: .blue,
            priority: .low,
            handler: {
                Logger.info("Saving contact", category: .action)
            }
        )
    }

    private func detectReplyOpportunity(card: EmailCard, content: String, subject: String) -> ContextualAction? {
        // Check if email requires urgent response
        let urgentKeywords = ["urgent", "asap", "immediately", "time sensitive", "right away", "quick response"]

        guard urgentKeywords.contains(where: { content.contains($0) || subject.contains($0) }) else {
            return nil
        }

        return ContextualAction(
            id: UUID().uuidString,
            type: .quickReply,
            title: "Quick Reply",
            description: "Urgent response needed",
            icon: "arrowshape.turn.up.left.fill",
            color: .red,
            priority: .critical,
            handler: {
                Logger.info("Opening reply composer", category: .action)
            }
        )
    }

    private func detectWalletOpportunity(card: EmailCard, content: String, subject: String) -> ContextualAction? {
        // Only suggest wallet if we have strong indicators, not just generic mentions

        // BOARDING PASS - High confidence required
        if (content.contains("boarding pass") || content.contains("mobile boarding pass")) &&
           (content.contains("gate") || content.contains("seat") || content.contains("departure") ||
            content.contains("flight") || content.contains("terminal")) {

            // Extra check: Look for flight number pattern (e.g., "UA 123", "AA1234")
            let flightPattern = #"[A-Z]{2}\s*\d{1,4}"#
            let hasFlightNumber = (try? NSRegularExpression(pattern: flightPattern, options: []))
                .flatMap { regex in
                    regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content))
                } != nil

            if hasFlightNumber {
                return ContextualAction(
                    id: UUID().uuidString,
                    type: .addToWallet,
                    title: "Add to Wallet",
                    description: "Add boarding pass for quick airport access",
                    icon: "airplane.departure",
                    color: .blue,
                    priority: .critical,  // Make this CRITICAL priority for primary action
                    handler: {
                        Logger.info("Opening wallet modal for boarding pass", category: .action)
                    }
                )
            }
        }

        // EVENT TICKET - Must have specific indicators
        if (content.contains("ticket") || content.contains("e-ticket")) &&
           (content.contains("venue") || content.contains("admission") || content.contains("entry") ||
            content.contains("concert") || content.contains("event") || content.contains("show") ||
            content.contains("game") || content.contains("theatre") || content.contains("theater")) &&
           !content.contains("support ticket") &&  // Exclude support tickets
           !content.contains("raffle") {           // Exclude raffle tickets

            return ContextualAction(
                id: UUID().uuidString,
                type: .addToWallet,
                title: "Add Ticket to Wallet",
                description: "Easy access at venue entrance",
                icon: "ticket.fill",
                color: .purple,
                priority: .high,
                handler: {
                    Logger.info("Opening wallet modal for event ticket", category: .action)
                }
            )
        }

        return nil
    }

    private func detectSaveContactOpportunity(card: EmailCard, content: String, subject: String) -> ContextualAction? {
        // Only suggest if there's a phone number - otherwise not useful enough
        let phoneNumbers = ContactsService.shared.extractPhoneNumbers(from: "\(card.title) \(card.summary) \(card.body ?? "")")

        guard !phoneNumbers.isEmpty else {
            return nil
        }

        // Now check if this is a contact-worthy context
        // DRIVER/DELIVERY - High priority, very actionable
        if content.contains("driver") || content.contains("delivery driver") || content.contains("courier") {
            return ContextualAction(
                id: UUID().uuidString,
                type: .saveContactNative,
                title: "Save Driver Contact",
                description: "Quick access for delivery communications",
                icon: "person.crop.circle.badge.plus",
                color: .blue,
                priority: .high,  // Higher priority when it's a driver
                handler: {
                    Logger.info("Opening save contact modal for driver", category: .action)
                }
            )
        }

        // SUPPORT/SERVICE - Medium priority
        if content.contains("customer service") || content.contains("support team") ||
           content.contains("service representative") || content.contains("help desk") {
            return ContextualAction(
                id: UUID().uuidString,
                type: .saveContactNative,
                title: "Save Support Contact",
                description: "Save support number for future reference",
                icon: "person.crop.circle.badge.plus",
                color: .blue,
                priority: .medium,
                handler: {
                    Logger.info("Opening save contact modal for support", category: .action)
                }
            )
        }

        // BUSINESS CONTACT - Only if sender is clearly a business
        if let sender = card.sender,
           !sender.name.isEmpty,
           (sender.name.contains("Inc") || sender.name.contains("LLC") || sender.name.contains("Corp") ||
            content.contains("account manager") || content.contains("sales")) {
            return ContextualAction(
                id: UUID().uuidString,
                type: .saveContactNative,
                title: "Save Contact",
                description: "Add business contact to iOS Contacts",
                icon: "person.crop.circle.badge.plus",
                color: .blue,
                priority: .low,  // Lower priority for generic business contacts
                handler: {
                    Logger.info("Opening save contact modal for business", category: .action)
                }
            )
        }

        return nil
    }

    private func detectSendMessageOpportunity(card: EmailCard, content: String, subject: String) -> ContextualAction? {
        // Only suggest if there's a phone number
        let phoneNumbers = MessagesService.shared.extractPhoneNumbers(from: card)

        guard !phoneNumbers.isEmpty else {
            return nil
        }

        // DRIVER/DELIVERY CONTEXT - Most relevant for messaging
        // Look for active delivery scenarios where user might need to contact driver
        if (content.contains("driver") || content.contains("delivery driver")) &&
           (content.contains("on the way") || content.contains("arriving") || content.contains("nearby") ||
            content.contains("delivered") || content.contains("pickup") || content.contains("drop off")) {

            return ContextualAction(
                id: UUID().uuidString,
                type: .sendMessage,
                title: "Text Driver",
                description: "Message your driver about delivery",
                icon: "message.fill",
                color: .green,
                priority: .critical,  // CRITICAL - very time sensitive
                handler: {
                    Logger.info("Opening send message modal for driver", category: .action)
                }
            )
        }

        // SMS EXPLICITLY MENTIONED - User was told to text
        if content.contains("text me") || content.contains("text us") ||
           content.contains("send a text") || content.contains("reply via text") {
            return ContextualAction(
                id: UUID().uuidString,
                type: .sendMessage,
                title: "Send Text Message",
                description: "Reply via SMS as requested",
                icon: "message.fill",
                color: .green,
                priority: .high,
                handler: {
                    Logger.info("Opening send message modal", category: .action)
                }
            )
        }

        // RSVP VIA TEXT - Common pattern
        if (content.contains("rsvp") || content.contains("confirm attendance")) &&
           (content.contains("text") || content.contains("message")) {
            return ContextualAction(
                id: UUID().uuidString,
                type: .sendMessage,
                title: "RSVP via Text",
                description: "Confirm your attendance by text",
                icon: "message.fill",
                color: .green,
                priority: .high,
                handler: {
                    Logger.info("Opening send message modal for RSVP", category: .action)
                }
            )
        }

        // Otherwise, don't suggest - email is probably better
        return nil
    }

    private func detectShareOpportunity(card: EmailCard, content: String, subject: String) -> ContextualAction? {
        // TRACKING NUMBER - Very shareable with family
        // Check for tracking number in content
        let trackingKeywords = ["tracking", "tracking number", "track your package", "shipment"]
        if trackingKeywords.contains(where: { content.contains($0) || subject.contains($0) }) {
            return ContextualAction(
                id: UUID().uuidString,
                type: .share,
                title: "Share Tracking",
                description: "Share tracking info with family",
                icon: "square.and.arrow.up",
                color: .blue,
                priority: .medium,  // Medium priority - useful but not urgent
                handler: {
                    Logger.info("Opening share sheet for tracking", category: .action)
                }
            )
        }

        // EVENT DETAILS - Worth sharing
        if (content.contains("event") || content.contains("invitation")) &&
           (content.contains("location") || content.contains("address") || content.contains("venue")) {
            return ContextualAction(
                id: UUID().uuidString,
                type: .share,
                title: "Share Event Details",
                description: "Forward event info to others",
                icon: "square.and.arrow.up",
                color: .blue,
                priority: .low,
                handler: {
                    Logger.info("Opening share sheet for event", category: .action)
                }
            )
        }

        // DEAL/PROMO CODE - Shareable with friends
        if (content.contains("promo code") || content.contains("discount code") || content.contains("referral")) &&
           !content.contains("exclusive") {  // Don't share exclusive codes
            return ContextualAction(
                id: UUID().uuidString,
                type: .share,
                title: "Share Promo Code",
                description: "Share this deal with friends",
                icon: "square.and.arrow.up",
                color: .blue,
                priority: .low,
                handler: {
                    Logger.info("Opening share sheet for promo", category: .action)
                }
            )
        }

        // Otherwise don't suggest - most emails aren't worth sharing
        return nil
    }
}

// MARK: - Models

/// Represents a contextual action suggestion
struct ContextualAction: Identifiable {
    let id: String
    let type: ContextualActionType
    let title: String
    let description: String
    let icon: String
    let color: Color
    let priority: ActionPriority
    let handler: () -> Void
}

enum ContextualActionType: String, Codable {
    case addToCalendar = "add_to_calendar"
    case setReminder = "set_reminder"
    case makePayment = "make_payment"
    case shopNow = "shop_now"
    case purchaseSupplies = "purchase_supplies"
    case browseBooks = "browse_books"
    case signDocument = "sign_document"
    case openDocument = "open_document"
    case saveContact = "save_contact"
    case quickReply = "quick_reply"
    // Native iOS Integrations
    case addToWallet = "add_to_wallet"
    case saveContactNative = "save_contact_native"
    case sendMessage = "send_message"
    case share = "share"
}

enum ActionPriority: Int {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}
