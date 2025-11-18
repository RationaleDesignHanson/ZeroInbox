import SwiftUI

/// Reusable context header for action modals
/// Shows action name and email context so users remember why they're performing the action
struct ModalContextHeader: View {
    let actionName: String
    let cardTitle: String
    let cardType: CardType?
    let onDismiss: (() -> Void)?

    init(
        actionName: String,
        cardTitle: String,
        cardType: CardType? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.actionName = actionName
        self.cardTitle = cardTitle
        self.cardType = cardType
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left: Action icon + name (SF Symbol instead of emoji)
            HStack(spacing: 8) {
                Image(systemName: ActionIconMapper.icon(for: actionName))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                    .frame(width: 20, height: 20)

                Text(actionName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            // Separator bullet
            Text("•")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))

            // Right: Card title (context)
            Text(cardTitle)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Close button (if dismiss handler provided)
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                        .font(.title2)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            .ultraThinMaterial.opacity(DesignTokens.Opacity.textTertiary)
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                .frame(height: 1),
            alignment: .bottom
        )
    }

}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ModalContextHeader(
            actionName: "Sign Form",
            cardTitle: "Field trip permission form - due Wednesday",
            cardType: .mail
        )

        ModalContextHeader(
            actionName: "Track Package",
            cardTitle: "Your Amazon order has shipped",
            cardType: .ads,
            onDismiss: {}
        )

        ModalContextHeader(
            actionName: "Review Document",
            cardTitle: "Q4 Budget Proposal needs approval",
            cardType: .mail
        )
    }
    .padding()
    .background(
        LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
