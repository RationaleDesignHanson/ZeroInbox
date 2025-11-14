import SwiftUI

/// Standard button component with consistent styling across the app
/// Supports primary (gradient), secondary (white 20%), and tertiary (white 10%) styles
/// Based on patterns from ReservationModal, EmailComposerModal, and other components
struct StandardButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle {
        case primary(gradient: LinearGradient)
        case secondary
        case tertiary
        case destructive
    }

    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary(gradient: LinearGradient(
            colors: [.blue, .purple],
            startPoint: .leading,
            endPoint: .trailing
        )),
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.inline) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: DesignTokens.Button.iconSize, weight: .semibold))
                }

                Text(title)
                    .font(DesignTokens.Typography.headingSmall)
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.Button.heightStandard)
            .foregroundColor(.white)
            .background(backgroundView)
            .cornerRadius(DesignTokens.Radius.button)
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary(let gradient):
            gradient
        case .secondary:
            DesignTokens.Colors.overlay20
        case .tertiary:
            DesignTokens.Colors.overlay10
        case .destructive:
            Color.red.opacity(DesignTokens.Opacity.textTertiary)
        }
    }
}

// MARK: - Convenience Initializers

extension StandardButton {
    /// Primary button with card type gradient
    init(_ title: String, icon: String? = nil, cardType: CardType, action: @escaping () -> Void) {
        self.init(
            title,
            icon: icon,
            style: .primary(gradient: ArchetypeConfig.config(for: cardType).gradient),
            action: action
        )
    }

    /// Secondary button (white 20% opacity)
    static func secondary(_ title: String, icon: String? = nil, action: @escaping () -> Void) -> StandardButton {
        StandardButton(title, icon: icon, style: .secondary, action: action)
    }

    /// Tertiary button (white 10% opacity)
    static func tertiary(_ title: String, icon: String? = nil, action: @escaping () -> Void) -> StandardButton {
        StandardButton(title, icon: icon, style: .tertiary, action: action)
    }

    /// Destructive button (red)
    static func destructive(_ title: String, icon: String? = nil, action: @escaping () -> Void) -> StandardButton {
        StandardButton(title, icon: icon, style: .destructive, action: action)
    }
}

// MARK: - Preview

#if DEBUG
struct StandardButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Primary with card gradient
                StandardButton("Add to Calendar", icon: "calendar.badge.plus", cardType: .mail) {}

                // Primary with custom gradient
                StandardButton(
                    "Continue",
                    icon: "arrow.right",
                    style: .primary(gradient: LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                ) {}

                // Secondary
                StandardButton.secondary("View Online", icon: "safari") {}

                // Tertiary
                StandardButton.tertiary("Share Details", icon: "square.and.arrow.up") {}

                // Destructive
                StandardButton.destructive("Delete", icon: "trash") {}
            }
            .padding()
        }
    }
}
#endif
