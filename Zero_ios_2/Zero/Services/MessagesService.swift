import Foundation
import MessageUI
import UIKit

/// Service for sending SMS/iMessage from emails
class MessagesService: NSObject {
    static let shared = MessagesService()

    private var messageComposeDelegate: MessageComposeDelegate?

    private override init() {
        super.init()
    }

    // MARK: - Check Availability

    /// Check if device can send text messages
    static func canSendMessages() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }

    // MARK: - Send Message

    /// Send a text message (SMS/iMessage)
    /// - Parameters:
    ///   - recipients: Phone numbers or email addresses (for iMessage)
    ///   - body: Message body
    ///   - presentingViewController: View controller to present the message composer
    ///   - completion: Callback with success or error
    func sendMessage(
        to recipients: [String],
        body: String,
        presentingViewController: UIViewController,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard MFMessageComposeViewController.canSendText() else {
            completion(.failure(MessagesError.deviceCannotSendMessages))
            return
        }

        let messageVC = MFMessageComposeViewController()
        messageVC.recipients = recipients
        messageVC.body = body

        // Set up delegate
        messageComposeDelegate = MessageComposeDelegate(completion: completion)
        messageVC.messageComposeDelegate = messageComposeDelegate

        Logger.info("Presenting message composer for \(recipients.count) recipients", category: .action)

        presentingViewController.present(messageVC, animated: true)
    }

    // MARK: - Extract Phone Numbers from Email

    /// Extract phone numbers from email card
    func extractPhoneNumbers(from card: EmailCard) -> [String] {
        let text = "\(card.title) \(card.summary) \(card.body ?? "")"

        var phoneNumbers: [String] = []

        // Pattern for US phone numbers (various formats)
        let patterns = [
            #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#,           // 123-456-7890 or 1234567890
            #"\b\(\d{3}\)\s*\d{3}[-.]?\d{4}\b"#,         // (123) 456-7890
            #"\b\+1\s*\d{3}[-.]?\d{3}[-.]?\d{4}\b"#      // +1 123-456-7890
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let phone = String(text[range])
                            .replacingOccurrences(of: #"[^\d+]"#, with: "", options: .regularExpression)
                        if !phoneNumbers.contains(phone) {
                            phoneNumbers.append(phone)
                        }
                    }
                }
            }
        }

        return phoneNumbers
    }

    /// Detect if email suggests messaging opportunity
    func detectMessageOpportunity(in card: EmailCard) -> MessageOpportunity? {
        let text = "\(card.title) \(card.summary) \(card.body ?? "")".lowercased()

        // Extract phone numbers
        let phoneNumbers = extractPhoneNumbers(from: card)

        guard !phoneNumbers.isEmpty else {
            return nil
        }

        // Detect context for messaging
        var reason: String = "Contact via text message"
        var suggestedMessage: String? = nil

        // Driver/delivery context
        if text.contains("driver") || text.contains("delivery") {
            reason = "Text your driver"
            suggestedMessage = "Hi! I'm checking on my delivery. Thanks!"
        }

        // Support context
        else if text.contains("customer service") || text.contains("support") {
            reason = "Text customer support"
            suggestedMessage = "Hi, I'm reaching out regarding my recent order. Can you help?"
        }

        // RSVP context
        else if text.contains("rsvp") || text.contains("respond") {
            reason = "RSVP via text"
            suggestedMessage = "Thank you for the invitation! I'd love to attend."
        }

        // Confirmation context
        else if text.contains("confirm") || text.contains("confirmation") {
            reason = "Send confirmation"
            suggestedMessage = "Yes, confirmed! Looking forward to it."
        }

        return MessageOpportunity(
            phoneNumbers: phoneNumbers,
            reason: reason,
            suggestedMessage: suggestedMessage,
            recipientName: card.sender?.name
        )
    }

    /// Generate smart message based on email context
    func generateSmartMessage(for card: EmailCard, action: String) -> String {
        let text = "\(card.title) \(card.summary)".lowercased()

        switch action.lowercased() {
        case "driver", "delivery":
            if text.contains("picked up") || text.contains("pickup") {
                return "Hi! I'm here for pickup. Thanks!"
            }
            return "Hi! I'm checking on my delivery. Thanks!"

        case "confirm", "confirmation":
            if let kid = card.kid {
                return "Yes, confirmed for \(kid.name). Thank you!"
            }
            return "Yes, confirmed! Thank you."

        case "rsvp":
            return "Thank you for the invitation! Count us in."

        case "support", "help":
            if let company = card.company {
                return "Hi \(company.name) support, I need help with my recent order. Can you assist?"
            }
            return "Hi, I need some assistance. Can you help?"

        default:
            return "Hi! I'm reaching out regarding: \(card.title)"
        }
    }
}

// MARK: - Message Compose Delegate

private class MessageComposeDelegate: NSObject, MFMessageComposeViewControllerDelegate {
    private let completion: (Result<Void, Error>) -> Void

    init(completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
    }

    func messageComposeViewController(
        _ controller: MFMessageComposeViewController,
        didFinishWith result: MessageComposeResult
    ) {
        controller.dismiss(animated: true) {
            switch result {
            case .sent:
                Logger.info("Message sent successfully", category: .action)
                self.completion(.success(()))

            case .cancelled:
                Logger.info("Message cancelled by user", category: .action)
                self.completion(.failure(MessagesError.cancelled))

            case .failed:
                Logger.error("Message failed to send", category: .action)
                self.completion(.failure(MessagesError.sendFailed))

            @unknown default:
                self.completion(.failure(MessagesError.unknown))
            }
        }
    }
}

// MARK: - Models

struct MessageOpportunity {
    let phoneNumbers: [String]
    let reason: String
    let suggestedMessage: String?
    let recipientName: String?
}

// MARK: - Errors

enum MessagesError: LocalizedError {
    case deviceCannotSendMessages
    case cancelled
    case sendFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .deviceCannotSendMessages:
            return "This device cannot send text messages"
        case .cancelled:
            return "Message was cancelled"
        case .sendFailed:
            return "Failed to send message"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
