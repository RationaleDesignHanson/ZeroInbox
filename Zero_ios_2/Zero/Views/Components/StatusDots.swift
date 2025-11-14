import SwiftUI

/// Status indicator dots that appear below sender information
/// Design system spec: 8×8pt circles with 6pt spacing
struct StatusDots: View {
    let dots: [StatusDotType]

    var body: some View {
        if !dots.isEmpty {
            HStack(spacing: 6) {
                ForEach(dots, id: \.rawValue) { dotType in
                    StatusDot(type: dotType)
                }
            }
        }
    }

    /// Convenience initializer from EmailCard properties
    init(from card: EmailCard) {
        var dots: [StatusDotType] = []

        if card.isVIP == true {
            dots.append(.vip)
        }

        if card.deadline != nil || card.urgent == true {
            dots.append(.deadline)
        }

        if card.isNewsletter == true {
            dots.append(.newsletter)
        }

        if card.isShoppingEmail == true {
            dots.append(.shopping)
        }

        self.dots = dots
    }

    /// Direct initializer with dot types
    init(dots: [StatusDotType]) {
        self.dots = dots
    }
}

// MARK: - Individual Status Dot

struct StatusDot: View {
    let type: StatusDotType

    var body: some View {
        Circle()
            .fill(type.color)
            .frame(width: 8, height: 8)
            .shadow(color: .black.opacity(DesignTokens.Opacity.overlayMedium), radius: 2, y: 2)
            .accessibilityLabel(type.accessibilityLabel)
    }
}

// MARK: - Preview

#Preview("All Status Dots") {
    VStack(spacing: 24) {
        // All dots together
        VStack(alignment: .leading, spacing: 8) {
            Text("All Status Types")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

            StatusDots(dots: StatusDotType.allCases)
        }

        Divider()
            .background(Color.white.opacity(DesignTokens.Opacity.overlayLight))

        // Individual dots with labels
        VStack(alignment: .leading, spacing: 16) {
            ForEach(StatusDotType.allCases, id: \.rawValue) { dotType in
                HStack(spacing: 12) {
                    StatusDot(type: dotType)

                    Text(dotType.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
        }

        Divider()
            .background(Color.white.opacity(DesignTokens.Opacity.overlayLight))

        // Real-world examples
        VStack(alignment: .leading, spacing: 16) {
            Text("Examples")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

            HStack(spacing: 12) {
                StatusDots(dots: [.vip, .deadline])
                Text("VIP with urgent deadline")
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
            }

            HStack(spacing: 12) {
                StatusDots(dots: [.shopping, .deadline])
                Text("Flash sale ending soon")
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
            }

            HStack(spacing: 12) {
                StatusDots(dots: [.newsletter])
                Text("Newsletter subscription")
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
            }
        }
    }
    .padding(DesignTokens.Spacing.card)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.05, green: 0.05, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
