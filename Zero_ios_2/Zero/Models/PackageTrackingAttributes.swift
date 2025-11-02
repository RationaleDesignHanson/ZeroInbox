import ActivityKit
import Foundation

/// Tracking status for package delivery
enum TrackingStatus: String, Codable, Hashable {
    case orderPlaced = "order_placed"
    case shipped = "shipped"
    case inTransit = "in_transit"
    case outForDelivery = "out_for_delivery"
    case delivered = "delivered"
    case exception = "exception"

    var displayName: String {
        switch self {
        case .orderPlaced: return "Order Placed"
        case .shipped: return "Shipped"
        case .inTransit: return "In Transit"
        case .outForDelivery: return "Out for Delivery"
        case .delivered: return "Delivered"
        case .exception: return "Exception"
        }
    }

    var icon: String {
        switch self {
        case .orderPlaced: return "checkmark.circle.fill"
        case .shipped: return "shippingbox.fill"
        case .inTransit: return "box.truck.fill"
        case .outForDelivery: return "location.fill"
        case .delivered: return "house.fill"
        case .exception: return "exclamationmark.triangle.fill"
        }
    }
}

/// Activity Attributes for package tracking Live Activities
/// Displays package tracking status on Dynamic Island and Lock Screen
@available(iOS 16.1, *)
struct PackageTrackingAttributes: ActivityAttributes {
    /// Static attributes (don't change during activity lifetime)
    public struct ContentState: Codable, Hashable {
        /// Current tracking status
        var status: TrackingStatus

        /// Current location of package
        var currentLocation: String?

        /// Estimated delivery date/time
        var estimatedDelivery: String

        /// Last update timestamp
        var lastUpdated: Date

        /// Progress percentage (0-100)
        var progress: Int
    }

    // Fixed attributes (set when activity is created)

    /// Package tracking number
    let trackingNumber: String

    /// Carrier name (UPS, FedEx, USPS, etc.)
    let carrier: String

    /// Optional package description
    let description: String?
}
