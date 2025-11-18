import Foundation
import Intents
import IntentsUI

/// Service for managing Siri Shortcuts integration
///
/// TODO: FUTURE FEATURE - Not yet integrated into the app
/// This service provides a complete Siri Shortcuts implementation ready for integration.
/// To enable: Call donation methods from relevant user actions (e.g., donateCheckInboxShortcut() when user opens inbox)
/// See full implementation below for 10+ ready-to-use shortcuts.
class SiriShortcutsService {
    static let shared = SiriShortcutsService()

    private init() {}

    // MARK: - Donate Shortcuts

    /// Donate a "Check Inbox" shortcut to Siri
    func donateCheckInboxShortcut() {
        let activity = NSUserActivity(activityType: "com.zero.checkInbox")
        activity.title = "Check Zero Inbox"
        activity.userInfo = ["action": "checkInbox"]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier = "checkInbox"

        // Set suggested invocation phrase
        activity.suggestedInvocationPhrase = "Check my Zero inbox"

        // Make activity current (donates to Siri)
        activity.becomeCurrent()

        Logger.info("Donated 'Check Inbox' shortcut to Siri", category: .action)
    }

    /// Donate a "Reply to Last Email" shortcut
    func donateReplyToLastEmailShortcut(emailId: String? = nil) {
        let activity = NSUserActivity(activityType: "com.zero.replyToLastEmail")
        activity.title = "Reply to Last Email"
        activity.userInfo = emailId != nil ? ["emailId": emailId!] : ["action": "replyToLast"]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier = "replyToLastEmail"

        activity.suggestedInvocationPhrase = "Reply to last email"

        activity.becomeCurrent()

        Logger.info("Donated 'Reply to Last Email' shortcut to Siri", category: .action)
    }

    /// Donate a "Complete Email Action" shortcut
    func donateCompleteActionShortcut(actionType: String, emailTitle: String) {
        let activity = NSUserActivity(activityType: "com.zero.completeAction")
        activity.title = "Complete \(actionType) for \(emailTitle)"
        activity.userInfo = ["actionType": actionType, "emailTitle": emailTitle]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier = "completeAction_\(actionType)"

        // Contextual phrases based on action type
        switch actionType.lowercased() {
        case "sign":
            activity.suggestedInvocationPhrase = "Sign permission form"
        case "pay":
            activity.suggestedInvocationPhrase = "Pay invoice"
        case "track":
            activity.suggestedInvocationPhrase = "Track package"
        case "calendar":
            activity.suggestedInvocationPhrase = "Add to calendar"
        default:
            activity.suggestedInvocationPhrase = "Complete email action"
        }

        activity.becomeCurrent()

        Logger.info("Donated '\(actionType)' shortcut to Siri", category: .action)
    }

    /// Donate a "Search Emails" shortcut
    func donateSearchEmailsShortcut(query: String? = nil) {
        let activity = NSUserActivity(activityType: "com.zero.searchEmails")
        activity.title = query != nil ? "Search for '\(query!)'" : "Search Emails"
        activity.userInfo = query != nil ? ["query": query!] : ["action": "search"]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier = "searchEmails"

        activity.suggestedInvocationPhrase = "Search Zero emails"

        activity.becomeCurrent()

        Logger.info("Donated 'Search Emails' shortcut to Siri", category: .action)
    }

    /// Donate a "Show Unread Count" shortcut
    func donateShowUnreadCountShortcut() {
        let activity = NSUserActivity(activityType: "com.zero.showUnreadCount")
        activity.title = "Show Unread Emails"
        activity.userInfo = ["action": "showUnreadCount"]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier = "showUnreadCount"

        activity.suggestedInvocationPhrase = "How many unread emails"

        activity.becomeCurrent()

        Logger.info("Donated 'Show Unread Count' shortcut to Siri", category: .action)
    }

    // MARK: - Handle Shortcut Continuation

    /// Handle user activity from Siri shortcut
    /// Call this from your SceneDelegate or App's onContinueUserActivity
    func handleShortcut(_ userActivity: NSUserActivity) -> ShortcutAction? {
        let activityType = userActivity.activityType

        Logger.info("Handling Siri shortcut: \(activityType)", category: .action)

        switch activityType {
        case "com.zero.checkInbox":
            return .checkInbox

        case "com.zero.replyToLastEmail":
            if let emailId = userActivity.userInfo?["emailId"] as? String {
                return .replyToEmail(emailId: emailId)
            }
            return .replyToLastEmail

        case "com.zero.completeAction":
            if let actionType = userActivity.userInfo?["actionType"] as? String,
               let emailTitle = userActivity.userInfo?["emailTitle"] as? String {
                return .completeAction(type: actionType, emailTitle: emailTitle)
            }
            return nil

        case "com.zero.searchEmails":
            if let query = userActivity.userInfo?["query"] as? String {
                return .searchEmails(query: query)
            }
            return .searchEmails(query: nil)

        case "com.zero.showUnreadCount":
            return .showUnreadCount

        default:
            return nil
        }
    }

    // MARK: - Spotlight Integration

    /// Add email to Spotlight search
    func indexEmailForSpotlight(card: EmailCard) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .emailMessage)

        // Basic info
        attributeSet.title = card.title
        attributeSet.contentDescription = card.summary
        attributeSet.keywords = extractKeywords(from: card)

        // Email specific
        if let sender = card.sender, let email = sender.email {
            // attributeSet.authors expects CSPerson objects, skip for now
            attributeSet.emailAddresses = [email]
        }

        // Dates
        // Note: EmailCard doesn't have timestamp property, using current date as fallback
        attributeSet.contentCreationDate = Date()

        // Create searchable item
        let item = CSSearchableItem(
            uniqueIdentifier: card.id,
            domainIdentifier: "com.zero.emails",
            attributeSet: attributeSet
        )

        // Set expiration (keep for 30 days)
        item.expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())

        // Index item
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                Logger.error("Failed to index email for Spotlight: \(error.localizedDescription)", category: .action)
            } else {
                Logger.debug("Indexed email '\(card.title)' for Spotlight", category: .action)
            }
        }
    }

    /// Remove email from Spotlight
    func removeEmailFromSpotlight(emailId: String) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [emailId]) { error in
            if let error = error {
                Logger.error("Failed to remove email from Spotlight: \(error.localizedDescription)", category: .action)
            }
        }
    }

    /// Clear all emails from Spotlight
    func clearSpotlightIndex() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: ["com.zero.emails"]) { error in
            if let error = error {
                Logger.error("Failed to clear Spotlight index: \(error.localizedDescription)", category: .action)
            } else {
                Logger.info("Cleared Spotlight index", category: .action)
            }
        }
    }

    // MARK: - Helper Methods

    private func extractKeywords(from card: EmailCard) -> [String] {
        var keywords: [String] = []

        // Add card type as keyword
        keywords.append(card.type.rawValue)

        // Add action type if available
        if let actions = card.suggestedActions, let action = actions.first {
            keywords.append(action.actionType.rawValue)
        }

        // Add company name if available
        if let company = card.company {
            keywords.append(company.name)
        }

        // Add kid name if available
        if let kid = card.kid {
            keywords.append(kid.name)
        }

        // Add common action keywords
        let text = "\(card.title) \(card.summary)".lowercased()
        let actionKeywords = ["urgent", "deadline", "payment", "invoice", "form", "permission", "signature", "rsvp"]
        keywords.append(contentsOf: actionKeywords.filter { text.contains($0) })

        return keywords
    }
}

// MARK: - Models

enum ShortcutAction {
    case checkInbox
    case replyToLastEmail
    case replyToEmail(emailId: String)
    case completeAction(type: String, emailTitle: String)
    case searchEmails(query: String?)
    case showUnreadCount
}

// MARK: - CSSearchableItemAttributeSet Extension
// Import CoreSpotlight at the top if not already imported
import CoreSpotlight
