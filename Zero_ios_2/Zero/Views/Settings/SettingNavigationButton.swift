import SwiftUI

/// Reusable navigation button setting component
/// Eliminates ~28 lines of duplicate code per navigation button
struct SettingNavigationButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    let disabled: Bool
    let style: ButtonStyle

    @Environment(\.colorScheme) var colorScheme

    enum ButtonStyle {
        case standard
        case gradient(colors: [Color])
        case prominent
    }

    init(
        title: String,
        description: String,
        icon: String,
        color: Color,
        disabled: Bool = false,
        style: ButtonStyle = .standard,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.disabled = disabled
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: {
            if !disabled {
                HapticService.shared.lightImpact()
                action()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(disabled ? textColor.opacity(0.3) : color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(disabled ? textColor.opacity(0.3) : textColor)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textColor.opacity(DesignTokens.Opacity.overlayMedium))
            }
            .padding(DesignTokens.Spacing.section)
            .background(backgroundView)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, DesignTokens.Spacing.section)
        .opacity(disabled ? 0.5 : 1.0)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .standard:
            RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                .fill(cardBackgroundColor.opacity(DesignTokens.Opacity.glassUltraLight))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                        .strokeBorder(color.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                )

        case .gradient(let colors):
            RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                .fill(
                    LinearGradient(
                        colors: colors.map { $0.opacity(DesignTokens.Opacity.overlayLight) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                        .strokeBorder(
                            LinearGradient(
                                colors: colors.map { $0.opacity(DesignTokens.Opacity.overlayMedium) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )

        case .prominent:
            RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                .fill(color.opacity(DesignTokens.Opacity.overlayLight))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                        .strokeBorder(color.opacity(DesignTokens.Opacity.overlayStrong), lineWidth: 2)
                )
        }
    }

    private var textColor: Color {
        // Settings screen always has dark background, so always use white text
        .white
    }

    private var cardBackgroundColor: Color {
        // Settings screen always has dark background
        Color(white: 0.18)
    }
}
