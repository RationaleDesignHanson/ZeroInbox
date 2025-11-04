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

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
