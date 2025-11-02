import SwiftUI

/// Shared Color extension for hex string initialization
/// This extension is used throughout the app to avoid duplicate definitions
extension Color {
    /// Initialize Color from hex string
    /// - Parameter hex: Hex string in format "#RRGGBB", "RRGGBB", "#RGB", or "#RRGGBBAA"
    /// - Supports 3-digit (RGB), 6-digit (RRGGBB), and 8-digit (RRGGBBAA) hex codes
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
            (a, r, g, b) = (255, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - Vibrant Color Palette

    /// Vibrant color constants for the bright poppy aesthetic
    static let vibrantBlue = Color(hex: "3b82f6")
    static let vibrantPurple = Color(hex: "a855f7")
    static let vibrantPink = Color(hex: "ec4899")
    static let vibrantCyan = Color(hex: "0ea5e9")
    static let vibrantGreen = Color(hex: "10b981")
    static let vibrantEmerald = Color(hex: "34ecb3")
    static let vibrantYellow = Color(hex: "fbbf24")
    static let vibrantOrange = Color(hex: "f97316")

    // Celebration gradient colors
    static let celebrationPurpleBlue = Color(hex: "667eea")
    static let celebrationDeepPurple = Color(hex: "764ba2")
    static let celebrationBrightPink = Color(hex: "f093fb")
}
