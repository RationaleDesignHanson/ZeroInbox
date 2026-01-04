import SwiftUI

/// Bottom action bar for email cards with navigation dots and primary CTA
/// Matches the new card design layout
struct BottomActionBar: View {
    let ctaLabel: String
    let cardType: CardType
    var onCTATap: (() -> Void)? = nil
    var showNavigationHint: Bool = false

    // Conditional colors based on card type
    private var backgroundColor: Color {
        cardType == .ads ?
            Color.white.opacity(DesignTokens.Opacity.glassLight) :
            Color.white.opacity(DesignTokens.Opacity.glassUltraLight)
    }

    private var dotsColor: Color {
        cardType == .ads ?
            DesignTokens.Colors.adsTextSubtle :
            Color.white.opacity(DesignTokens.Opacity.textSubtle)
    }

    private var ctaBackgroundGradient: [Color] {
        cardType == .ads ? [
            DesignTokens.Colors.adsGradientStart,
            DesignTokens.Colors.adsGradientEnd
        ] : [
            Color.white.opacity(0.25),
            Color.white.opacity(0.15)
        ]
    }

    private var ctaTextColor: Color {
        cardType == .ads ?
            Color.white :
            Color.white.opacity(DesignTokens.Opacity.textPrimary)
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.component) {
            // Navigation hint dots
            if showNavigationHint {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(dotsColor)
                            .opacity(index == 2 ? 1.0 : (index == 1 ? 0.7 : 0.4))
                    }
                }
                .padding(.leading, DesignTokens.Spacing.inline)
            }

            Spacer()

            // Primary CTA Button
            Button(action: {
                HapticService.shared.mediumImpact()
                onCTATap?()
            }) {
                Text(ctaLabel)
                    .font(DesignTokens.Typography.actionSecondary)
                    .foregroundColor(ctaTextColor)
                    .padding(.horizontal, DesignTokens.Spacing.component)
                    .padding(.vertical, DesignTokens.Spacing.inline)
                    .background(
                        LinearGradient(
                            colors: ctaBackgroundGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(DesignTokens.BottomActionBar.radius)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(height: DesignTokens.BottomActionBar.height)
        .padding(.horizontal, DesignTokens.BottomActionBar.padding)
        .background(backgroundColor)
        .cornerRadius(DesignTokens.BottomActionBar.radius)
    }
}

// MARK: - Preview

#Preview("Bottom Action Bar - Mail") {
    ZStack {
        LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            BottomActionBar(
                ctaLabel: "Sign & Send",
                cardType: .mail,
                showNavigationHint: true
            )

            BottomActionBar(
                ctaLabel: "View Details",
                cardType: .mail,
                showNavigationHint: false
            )
        }
        .padding()
    }
}

#Preview("Bottom Action Bar - Ads") {
    ZStack {
        LinearGradient(
            colors: [DesignTokens.Colors.adsGradientStart, DesignTokens.Colors.adsGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            BottomActionBar(
                ctaLabel: "Claim Deal",
                cardType: .ads,
                showNavigationHint: true
            )

            BottomActionBar(
                ctaLabel: "Shop Now",
                cardType: .ads,
                showNavigationHint: false
            )
        }
        .padding()
    }
}







