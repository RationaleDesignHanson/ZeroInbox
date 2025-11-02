import ActivityKit
import SwiftUI

/// Live Activity for real-time package tracking
/// Shows tracking updates on Dynamic Island and Lock Screen (iOS 16+)
@available(iOS 16.1, *)
struct PackageTrackingAttributes: ActivityAttributes {

    // MARK: - Static Data (doesn't change during activity lifetime)

    /// Static package information
    public struct ContentState: Codable, Hashable {
        /// Current tracking status
        var status: TrackingStatus

        /// Current location (city, state)
        var currentLocation: String?

        /// Estimated delivery date/time
        var estimatedDelivery: String

        /// Last update timestamp
        var lastUpdated: Date

        /// Progress percentage (0-100)
        var progress: Int
    }

    /// Package tracking number
    var trackingNumber: String

    /// Carrier name (UPS, FedEx, USPS, etc.)
    var carrier: String

    /// Package description (optional)
    var description: String?
}

/// Tracking status for package
@available(iOS 16.1, *)
enum TrackingStatus: String, Codable, Hashable {
    case orderPlaced = "Order Placed"
    case shipped = "Shipped"
    case inTransit = "In Transit"
    case outForDelivery = "Out for Delivery"
    case delivered = "Delivered"
    case exception = "Delivery Exception"

    /// Icon for each status
    var icon: String {
        switch self {
        case .orderPlaced: return "shippingbox"
        case .shipped: return "shippingbox.fill"
        case .inTransit: return "truck.box"
        case .outForDelivery: return "truck.box.fill"
        case .delivered: return "checkmark.seal.fill"
        case .exception: return "exclamationmark.triangle.fill"
        }
    }

    /// Color for each status
    var color: Color {
        switch self {
        case .orderPlaced: return .gray
        case .shipped: return .blue
        case .inTransit: return .purple
        case .outForDelivery: return .orange
        case .delivered: return .green
        case .exception: return .red
        }
    }
}
