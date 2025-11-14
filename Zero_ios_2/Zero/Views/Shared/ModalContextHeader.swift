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
                Image(systemName: getIconForAction(actionName))
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

    /// Get SF Symbol icon name for action type
    private func getIconForAction(_ action: String) -> String {
        let lowercasedAction = action.lowercased()

        // Education/School
        if lowercasedAction.contains("grade") || lowercasedAction.contains("assignment") {
            return "chart.bar.fill"
        }
        if lowercasedAction.contains("homework") || lowercasedAction.contains("study") {
            return "pencil.and.outline"
        }

        // Forms & Signatures
        if lowercasedAction.contains("sign") || lowercasedAction.contains("form") {
            return "signature"
        }

        // Shopping
        if lowercasedAction.contains("shop") || lowercasedAction.contains("browse") || lowercasedAction.contains("deal") || lowercasedAction.contains("cart") {
            return "cart.fill"
        }
        if lowercasedAction.contains("track") || lowercasedAction.contains("package") || lowercasedAction.contains("delivery") {
            return "shippingbox.fill"
        }
        if lowercasedAction.contains("pay") || lowercasedAction.contains("invoice") || lowercasedAction.contains("bill") {
            return "creditcard.fill"
        }

        // Travel
        if lowercasedAction.contains("flight") || lowercasedAction.contains("check in") || lowercasedAction.contains("boarding") {
            return "airplane"
        }
        if lowercasedAction.contains("hotel") || lowercasedAction.contains("reservation") || lowercasedAction.contains("booking") {
            return "building.2.fill"
        }

        // Work/Business
        if lowercasedAction.contains("meeting") || lowercasedAction.contains("schedule") || lowercasedAction.contains("demo") || lowercasedAction.contains("calendar") {
            return "calendar"
        }
        if lowercasedAction.contains("document") || lowercasedAction.contains("review") || lowercasedAction.contains("approve") {
            return "doc.text.fill"
        }
        if lowercasedAction.contains("spreadsheet") || lowercasedAction.contains("report") {
            return "tablecells.fill"
        }

        // Healthcare/Appointments
        if lowercasedAction.contains("appointment") || lowercasedAction.contains("doctor") || lowercasedAction.contains("prescription") || lowercasedAction.contains("pickup") {
            return "cross.case.fill"
        }

        // Food/Restaurants
        if lowercasedAction.contains("restaurant") || lowercasedAction.contains("menu") || lowercasedAction.contains("order food") {
            return "fork.knife"
        }

        // Security/Account
        if lowercasedAction.contains("security") || lowercasedAction.contains("verify") || lowercasedAction.contains("password") {
            return "lock.shield.fill"
        }

        // Social/Events
        if lowercasedAction.contains("event") || lowercasedAction.contains("rsvp") || lowercasedAction.contains("invitation") {
            return "party.popper.fill"
        }

        // Newsletter
        if lowercasedAction.contains("newsletter") || lowercasedAction.contains("summary") {
            return "newspaper.fill"
        }

        // Generic actions
        if lowercasedAction.contains("view") || lowercasedAction.contains("detail") {
            return "eye.fill"
        }

        // Generic link/browser
        return "link"
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
