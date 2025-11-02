import Foundation
import PassKit
import UIKit

/// Service for adding boarding passes and tickets to Apple Wallet
class WalletService {
    static let shared = WalletService()

    private init() {}

    // MARK: - Add Pass to Wallet

    /// Add a pass (boarding pass, event ticket, etc.) to Apple Wallet
    /// - Parameters:
    ///   - passData: The .pkpass file data
    ///   - completion: Callback with success or error
    func addPassToWallet(
        passData: Data,
        presentingViewController: UIViewController,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        do {
            // Create PKPass from data
            let pass = try PKPass(data: passData)

            // Check if pass can be added
            guard PKAddPassesViewController.canAddPasses() else {
                completion(.failure(WalletError.cannotAddPasses))
                return
            }

            // Create add passes view controller
            guard let addPassVC = PKAddPassesViewController(pass: pass) else {
                completion(.failure(WalletError.failedToCreateViewController))
                return
            }

            // Present the view controller
            presentingViewController.present(addPassVC, animated: true) {
                Logger.info("Wallet pass presented to user", category: .action)
                completion(.success(()))
            }

        } catch {
            Logger.error("Failed to add pass to wallet: \(error.localizedDescription)", category: .action)
            completion(.failure(WalletError.invalidPassData(error)))
        }
    }

    /// Download pass from URL and add to wallet
    /// - Parameters:
    ///   - url: URL to .pkpass file
    ///   - presentingViewController: View controller to present the add pass UI
    ///   - completion: Callback with success or error
    func downloadAndAddPass(
        from url: URL,
        presentingViewController: UIViewController,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Logger.info("Downloading pass from: \(url.absoluteString)", category: .action)

        // Download pass data
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.error("Failed to download pass: \(error.localizedDescription)", category: .action)
                    completion(.failure(WalletError.downloadFailed(error)))
                    return
                }

                guard let data = data else {
                    completion(.failure(WalletError.noData))
                    return
                }

                // Add pass to wallet
                self?.addPassToWallet(
                    passData: data,
                    presentingViewController: presentingViewController,
                    completion: completion
                )
            }
        }.resume()
    }

    // MARK: - Generate Passes (if backend provides raw data)

    /// Check if we can add passes to wallet
    static func canAddPasses() -> Bool {
        return PKAddPassesViewController.canAddPasses()
    }

    // MARK: - Check for Pass URLs in Email

    /// Extract pass URLs from email content
    /// Common patterns:
    /// - Airlines: "boarding pass", "mobile boarding pass"
    /// - Events: "ticket", "event pass", "admission"
    func extractPassURLs(from text: String) -> [URL] {
        var urls: [URL] = []

        // Pattern 1: Look for .pkpass links
        let pkpassPattern = #"https?://[^\s<>"]+\.pkpass"#
        if let regex = try? NSRegularExpression(pattern: pkpassPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text),
                   let url = URL(string: String(text[range])) {
                    urls.append(url)
                }
            }
        }

        // Pattern 2: Look for wallet/pass endpoints
        let passEndpointPattern = #"https?://[^\s<>"]+/(?:wallet|pass|boarding-pass|ticket)/[^\s<>"]*"#
        if let regex = try? NSRegularExpression(pattern: passEndpointPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text),
                   let url = URL(string: String(text[range])) {
                    urls.append(url)
                }
            }
        }

        return urls
    }

    /// Detect if email contains a boarding pass or ticket
    func detectPassOpportunity(in card: EmailCard) -> PassOpportunity? {
        let text = "\(card.title) \(card.summary) \(card.body ?? "")".lowercased()

        // Check for boarding pass
        if text.contains("boarding pass") ||
           text.contains("mobile boarding pass") ||
           text.contains("check in") && text.contains("flight") {

            // Extract flight info
            let flightNumber = extractFlightNumber(from: text)

            return PassOpportunity(
                type: .boardingPass,
                title: "Add Boarding Pass to Wallet",
                description: flightNumber.map { "Flight \($0)" } ?? "Add your boarding pass for easy access",
                extractedURLs: extractPassURLs(from: "\(card.title) \(card.summary) \(card.body ?? "")")
            )
        }

        // Check for event tickets
        if text.contains("ticket") || text.contains("admission") || text.contains("event pass") {
            return PassOpportunity(
                type: .eventTicket,
                title: "Add Ticket to Wallet",
                description: "Add your event ticket for easy access",
                extractedURLs: extractPassURLs(from: "\(card.title) \(card.summary) \(card.body ?? "")")
            )
        }

        // Check for coupons/offers
        if text.contains("coupon") || text.contains("offer") || text.contains("discount code") {
            return PassOpportunity(
                type: .coupon,
                title: "Add Coupon to Wallet",
                description: "Save this offer to your wallet",
                extractedURLs: extractPassURLs(from: "\(card.title) \(card.summary) \(card.body ?? "")")
            )
        }

        return nil
    }

    // MARK: - Helper Methods

    private func extractFlightNumber(from text: String) -> String? {
        // Pattern: Airline code (2 letters) + flight number (1-4 digits)
        let pattern = #"\b([A-Z]{2})\s*(\d{1,4})\b"#

        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {

            if let airlineRange = Range(match.range(at: 1), in: text),
               let numberRange = Range(match.range(at: 2), in: text) {
                let airline = text[airlineRange]
                let number = text[numberRange]
                return "\(airline)\(number)"
            }
        }

        return nil
    }
}

// MARK: - Errors
// Note: PassOpportunity struct is defined in Models/OpportunityTypes.swift

enum WalletError: LocalizedError {
    case cannotAddPasses
    case failedToCreateViewController
    case invalidPassData(Error)
    case downloadFailed(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .cannotAddPasses:
            return "This device cannot add passes to Apple Wallet"
        case .failedToCreateViewController:
            return "Failed to create Wallet view controller"
        case .invalidPassData(let error):
            return "Invalid pass data: \(error.localizedDescription)"
        case .downloadFailed(let error):
            return "Failed to download pass: \(error.localizedDescription)"
        case .noData:
            return "No pass data received"
        }
    }
}
