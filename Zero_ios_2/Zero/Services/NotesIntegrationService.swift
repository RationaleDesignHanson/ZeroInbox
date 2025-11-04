import Foundation
import UIKit

/// Service for integrating with iOS Notes app
/// Since iOS doesn't provide a direct Notes API, this service formats content
/// for sharing to Notes via the iOS share sheet
class NotesIntegrationService {
    static let shared = NotesIntegrationService()

    private init() {}

    // MARK: - Note Opportunity Detection

    struct NoteOpportunity {
        let title: String
        let content: String
        let tags: [String]
        let suggestedFolder: String?
    }

    /// Detect if an email is a good candidate for saving to Notes
    func detectNoteOpportunity(in card: EmailCard) -> NoteOpportunity? {
        let text = card.title.lowercased()
        let summary = card.summary.lowercased()
        let body = (card.body ?? "").lowercased()

        // Patterns that indicate note-worthy content
        let notePatterns = [
            "reference", "guide", "tutorial", "instructions", "recipe",
            "tips", "notes", "directions", "procedure", "checklist",
            "confirmation", "itinerary", "schedule", "agenda"
        ]

        let isNoteWorthy = notePatterns.contains { pattern in
            text.contains(pattern) || summary.contains(pattern) || body.contains(pattern)
        }

        guard isNoteWorthy else { return nil }

        // Generate title
        let title = generateNoteTitle(from: card)

        // Format content
        let content = formatNoteContent(from: card)

        // Detect tags
        let tags = detectTags(from: card)

        // Suggest folder based on card type
        let folder = suggestFolder(for: card)

        return NoteOpportunity(
            title: title,
            content: content,
            tags: tags,
            suggestedFolder: folder
        )
    }

    // MARK: - Note Formatting

    /// Generate an appropriate note title from email card
    private func generateNoteTitle(from card: EmailCard) -> String {
        let text = card.title.lowercased()

        // Recipe
        if text.contains("recipe") {
            return "Recipe: \(card.title)"
        }

        // Travel/Itinerary
        if text.contains("itinerary") || text.contains("trip") || text.contains("travel") {
            return "Travel: \(card.title)"
        }

        // Reference/Guide
        if text.contains("guide") || text.contains("tutorial") || text.contains("instructions") {
            return "Guide: \(card.title)"
        }

        // Meeting notes
        if text.contains("meeting") || text.contains("agenda") {
            return "Meeting: \(card.title)"
        }

        // Confirmation
        if text.contains("confirmation") {
            return "Confirmation: \(card.title)"
        }

        // Default
        return card.title
    }

    /// Format email content into a well-structured note
    func formatNoteContent(from card: EmailCard) -> String {
        var content = ""

        // Title
        content += "\(card.title)\n"
        content += String(repeating: "=", count: min(card.title.count, 50)) + "\n\n"

        // Metadata
        content += "📧 From: \(card.sender?.name ?? "Unknown")\n"
        if let email = card.sender?.email {
            content += "✉️ Email: \(email)\n"
        }

        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        content += "📅 Date: \(card.timeAgo)\n"

        // Company/Store
        if let company = card.company?.name ?? card.store {
            content += "🏢 From: \(company)\n"
        }

        content += "\n"

        // Summary
        content += "Summary\n"
        content += "-------\n"
        content += "\(card.summary)\n\n"

        // Body content (if available and substantial)
        if let body = card.body, !body.isEmpty, body.count > 50 {
            content += "Details\n"
            content += "-------\n"
            content += "\(body)\n\n"
        }

        // Action items
        if let actions = card.suggestedActions, !actions.isEmpty {
            content += "Action Items\n"
            content += "------------\n"
            for action in actions.prefix(5) {
                content += "• \(action.displayName)\n"
            }
            content += "\n"
        }

        // Entities (important info)
        var entities: [String] = []

        if let amount = card.paymentAmount {
            entities.append("💵 Amount: $\(String(format: "%.2f", amount))")
        }

        if let meetingTime = card.calendarInvite?.meetingTime {
            entities.append("📅 Event: \(meetingTime)")
        }

        if let tracking = card.trackingNumber {
            entities.append("📦 Tracking: \(tracking)")
        }

        if !entities.isEmpty {
            content += "Key Information\n"
            content += "---------------\n"
            entities.forEach { content += "\($0)\n" }
            content += "\n"
        }

        // Footer
        content += "---\n"
        content += "Saved from Zero Email\n"
        content += "\(Date().formatted())\n"

        return content
    }

    /// Detect relevant tags from email content
    private func detectTags(from card: EmailCard) -> [String] {
        var tags: [String] = []

        let text = (card.title + " " + card.summary + " " + (card.body ?? "")).lowercased()

        // Category-based tags
        if text.contains("recipe") || text.contains("cooking") { tags.append("recipes") }
        if text.contains("travel") || text.contains("trip") || text.contains("flight") { tags.append("travel") }
        if text.contains("meeting") || text.contains("agenda") { tags.append("meetings") }
        if text.contains("reference") || text.contains("guide") { tags.append("reference") }
        if text.contains("work") || text.contains("project") { tags.append("work") }
        if text.contains("personal") { tags.append("personal") }
        if text.contains("health") || text.contains("medical") { tags.append("health") }
        if text.contains("finance") || text.contains("payment") { tags.append("finance") }

        // Card type based tags
        switch card.type {
        case .mail:
            if let email = card.sender?.email, let domain = email.split(separator: "@").last {
                tags.append(String(domain))
            }
        case .ads:
            tags.append("promotions")
        }

        return Array(Set(tags)) // Remove duplicates
    }

    /// Suggest a folder name based on card category
    private func suggestFolder(for card: EmailCard) -> String? {
        let text = (card.title + " " + card.summary).lowercased()

        if text.contains("work") || text.contains("project") || text.contains("meeting") {
            return "Work"
        }

        if text.contains("travel") || text.contains("trip") {
            return "Travel"
        }

        if text.contains("recipe") || text.contains("cooking") {
            return "Recipes"
        }

        if text.contains("reference") || text.contains("guide") || text.contains("tutorial") {
            return "Reference"
        }

        return "Email Notes"
    }

    // MARK: - Share to Notes

    /// Create a share activity to send content to Notes app
    /// Returns a UIActivityViewController that the caller should present
    func createShareActivity(
        title: String,
        content: String,
        presentingViewController: UIViewController? = nil
    ) -> UIActivityViewController {
        // Create attributed string for better formatting
        let fullText = "\(title)\n\n\(content)"

        let activityViewController = UIActivityViewController(
            activityItems: [fullText],
            applicationActivities: nil
        )

        // Exclude activities we don't want
        activityViewController.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks,
            .postToFacebook,
            .postToTwitter,
            .postToWeibo,
            .postToVimeo,
            .postToTencentWeibo,
            .postToFlickr
        ]

        return activityViewController
    }

    /// Copy note content to clipboard for manual paste into Notes
    func copyToClipboard(title: String, content: String) {
        let fullText = "\(title)\n\n\(content)"
        UIPasteboard.general.string = fullText
        Logger.info("Note content copied to clipboard", category: .action)
    }
}

// MARK: - Errors

enum NotesError: LocalizedError {
    case sharingFailed
    case clipboardFailed

    var errorDescription: String? {
        switch self {
        case .sharingFailed:
            return "Failed to share note to Notes app"
        case .clipboardFailed:
            return "Failed to copy note to clipboard"
        }
    }
}
