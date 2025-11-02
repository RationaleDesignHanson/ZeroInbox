import SwiftUI

struct ArchetypeConfig {
    let type: CardType
    let displayName: String
    let gradient: LinearGradient

    // Binary Classification Gradients (v2.0)
    static let all: [CardType: ArchetypeConfig] = [
        // MAIL - Bright Blue/Cyan (all non-promotional emails)
        .mail: ArchetypeConfig(
            type: .mail,
            displayName: "Mail",
            gradient: LinearGradient(
                colors: [
                    Color(hex: "3b82f6"),  // Bright blue #3b82f6
                    Color(hex: "0ea5e9")   // Vibrant cyan #0ea5e9
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),

        // ADS - Green/Emerald (marketing, promotions, newsletters)
        .ads: ArchetypeConfig(
            type: .ads,
            displayName: "Ads",
            gradient: LinearGradient(
                colors: [
                    Color(hex: "10b981"),  // Teal green #10b981
                    Color(hex: "34ecb3")   // Bright emerald #34ecb3
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    ]

    static func config(for type: CardType) -> ArchetypeConfig {
        return all[type] ?? all[.mail]!
    }
}

