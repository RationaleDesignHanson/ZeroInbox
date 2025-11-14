import SwiftUI

/// Status dot types matching the design system specifications
/// These colored indicators appear below sender information in email cards
enum StatusDotType: String, CaseIterable {
    case vip = "VIP Contact"
    case deadline = "Urgent Deadline"
    case newsletter = "Newsletter"
    case shopping = "Shopping/Deal"

    /// Color from design system specification
    var color: Color {
        switch self {
        case .vip:
            return Color(hex: "FFD700")  // Gold
        case .deadline:
            return Color(hex: "FF3B30")  // Red
        case .newsletter:
            return Color(hex: "007AFF")  // Blue
        case .shopping:
            return Color(hex: "AF52DE")  // Purple
        }
    }

    /// Accessibility label for VoiceOver
    var accessibilityLabel: String {
        return rawValue
    }
}
