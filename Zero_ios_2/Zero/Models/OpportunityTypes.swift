import Foundation

/// Represents an opportunity to add a pass to Apple Wallet
/// Used by WalletService and AddToWalletModal
struct PassOpportunity {
    enum PassType {
        case boardingPass
        case eventTicket
        case coupon
        case storeCard
        case generic
    }

    let type: PassType
    let title: String
    let description: String
    let extractedURLs: [URL]
}
