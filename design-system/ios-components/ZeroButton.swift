//
//  ZeroButton.swift
//  Zero Design System
//
//  READY TO INTEGRATE - Drop into: Zero_ios_2/Zero/Core/UI/Components/
//  Requires: DesignTokens.swift in Zero/Config/
//
//  Usage:
//  ZeroButton(title: "Continue", style: .primary, size: .large) {
//      // Action
//  }
//

import SwiftUI

struct ZeroButton: View {
    // MARK: - Types

    enum Style {
        case primary
        case secondary
        case destructive
        case text
        case ghost

        var backgroundColor: Color {
            switch self {
            case .primary: return DesignTokens.Colors.accentBlue
            case .secondary: return DesignTokens.Colors.overlay10
            case .destructive: return DesignTokens.Colors.errorPrimary
            case .text, .ghost: return .clear
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary, .destructive: return DesignTokens.Colors.textInverse
            case .secondary: return DesignTokens.Colors.textPrimary
            case .text, .ghost: return DesignTokens.Colors.accentBlue
            }
        }

        var borderColor: Color? {
            switch self {
            case .ghost: return DesignTokens.Colors.borderSubtle
            default: return nil
            }
        }
    }

    enum Size {
        case large    // 56px
        case medium   // 44px
        case small    // 36px

        var height: CGFloat {
            switch self {
            case .large: return DesignTokens.Button.heightStandard
            case .medium: return DesignTokens.Button.heightCompact
            case .small: return 36
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .large: return 24
            case .medium: return 20
            case .small: return 16
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .large: return 20
            case .medium: return 18
            case .small: return 16
            }
        }

        var font: Font {
            switch self {
            case .large: return DesignTokens.Typography.bodyLarge
            case .medium: return DesignTokens.Typography.bodyMedium
            case .small: return DesignTokens.Typography.bodySmall
            }
        }
    }

    // MARK: - Properties

    let title: String
    let icon: String? // SF Symbol name
    let iconPosition: IconPosition
    let style: Style
    let size: Size
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    enum IconPosition {
        case leading
        case trailing
    }

    // MARK: - Initializers

    init(
        title: String,
        icon: String? = nil,
        iconPosition: IconPosition = .leading,
        style: Style = .primary,
        size: Size = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.iconPosition = iconPosition
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.inline) {
                if iconPosition == .leading {
                    iconView
                }

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)
                }

                if iconPosition == .trailing {
                    iconView
                }
            }
            .foregroundColor(style.foregroundColor)
            .frame(maxWidth: .infinity, minHeight: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(style.backgroundColor)
            .cornerRadius(DesignTokens.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .stroke(style.borderColor ?? .clear, lineWidth: 1)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .disabled(isDisabled || isLoading)
    }

    @ViewBuilder
    private var iconView: some View {
        if let icon = icon, !isLoading {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .semibold))
        }
    }
}

// MARK: - Previews

#Preview("Button Styles") {
    VStack(spacing: DesignTokens.Spacing.element) {
        ZeroButton(title: "Primary Button", style: .primary, size: .large) {}
        ZeroButton(title: "Secondary Button", style: .secondary, size: .large) {}
        ZeroButton(title: "Destructive Button", style: .destructive, size: .large) {}
        ZeroButton(title: "Text Button", style: .text, size: .large) {}
        ZeroButton(title: "Ghost Button", style: .ghost, size: .large) {}
    }
    .padding()
}

#Preview("Button Sizes") {
    VStack(spacing: DesignTokens.Spacing.element) {
        ZeroButton(title: "Large Button", size: .large) {}
        ZeroButton(title: "Medium Button", size: .medium) {}
        ZeroButton(title: "Small Button", size: .small) {}
    }
    .padding()
}

#Preview("Button States") {
    VStack(spacing: DesignTokens.Spacing.element) {
        ZeroButton(title: "Normal", style: .primary, size: .large) {}
        ZeroButton(title: "Loading", style: .primary, size: .large, isLoading: true) {}
        ZeroButton(title: "Disabled", style: .primary, size: .large, isDisabled: true) {}
    }
    .padding()
}

#Preview("Buttons with Icons") {
    VStack(spacing: DesignTokens.Spacing.element) {
        ZeroButton(title: "Continue", icon: "arrow.right", iconPosition: .trailing, style: .primary, size: .large) {}
        ZeroButton(title: "Back", icon: "arrow.left", iconPosition: .leading, style: .secondary, size: .large) {}
        ZeroButton(title: "Delete", icon: "trash", style: .destructive, size: .large) {}
        ZeroButton(title: "Add to Calendar", icon: "calendar.badge.plus", style: .primary, size: .medium) {}
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: DesignTokens.Spacing.element) {
        ZeroButton(title: "Primary", style: .primary, size: .large) {}
        ZeroButton(title: "Secondary", style: .secondary, size: .large) {}
        ZeroButton(title: "Destructive", style: .destructive, size: .large) {}
    }
    .padding()
    .preferredColorScheme(.dark)
}
