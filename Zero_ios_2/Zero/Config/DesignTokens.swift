import SwiftUI

/// Design Tokens - Semantic naming system for consistent styling
/// Architecture: Primitive values → Semantic tokens → Component tokens
/// Version 2.0 - Redesigned for scalability and extensibility
enum DesignTokens {

    // MARK: - Primitive Tokens (Raw values - internal use only)

    enum Primitive {
        /// Base size scale (powers of 2 and common increments)
        enum Size {
            static let xxxs: CGFloat = 2
            static let xxs: CGFloat = 4
            static let xs: CGFloat = 6
            static let sm: CGFloat = 8
            static let md: CGFloat = 12
            static let lg: CGFloat = 16
            static let xl: CGFloat = 20
            static let xxl: CGFloat = 24
            static let xxxl: CGFloat = 32
            static let xxxxl: CGFloat = 48
        }

        /// Opacity scale (0.0 - 1.0)
        enum Opacity {
            static let none: Double = 0.0
            static let glass: Double = 0.05          // Ultra-transparent for glass effects
            static let subtle: Double = 0.1          // Barely visible
            static let light: Double = 0.2           // Light overlays
            static let medium: Double = 0.3          // Standard overlays
            static let strong: Double = 0.5          // Heavy overlays
            static let disabled: Double = 0.6        // Disabled/faded elements
            static let secondary: Double = 0.7       // Secondary text
            static let tertiary: Double = 0.8        // Tertiary text
            static let primary: Double = 0.9         // Primary readable text
            static let full: Double = 1.0            // Fully opaque
        }

        /// Animation duration scale (in seconds)
        enum Duration {
            static let instant: Double = 0.1
            static let quick: Double = 0.2
            static let fast: Double = 0.3
            static let normal: Double = 0.5
            static let slow: Double = 0.7
            static let lazy: Double = 1.0
        }
    }

    // MARK: - Semantic Tokens (Usage-based - primary API)

    /// Spacing tokens - semantic names for layout spacing
    enum Spacing {
        static let card: CGFloat = Primitive.Size.xxl          // 24 - Card padding
        static let modal: CGFloat = Primitive.Size.xxl         // 24 - Modal padding
        static let section: CGFloat = Primitive.Size.xl        // 20 - Section gaps
        static let component: CGFloat = Primitive.Size.lg      // 16 - Component spacing
        static let element: CGFloat = Primitive.Size.md        // 12 - Element spacing
        static let inline: CGFloat = Primitive.Size.sm         // 8 - Inline spacing
        static let tight: CGFloat = Primitive.Size.xs          // 6 - Tight spacing
        static let minimal: CGFloat = Primitive.Size.xxs       // 4 - Minimal spacing
    }

    /// Corner radius tokens - semantic names for border radius
    enum Radius {
        static let card: CGFloat = Primitive.Size.xxl          // 24 - Main cards
        static let modal: CGFloat = Primitive.Size.xl          // 20 - Modals
        static let container: CGFloat = Primitive.Size.lg      // 16 - Containers
        static let button: CGFloat = Primitive.Size.md         // 12 - Buttons
        static let chip: CGFloat = Primitive.Size.sm           // 8 - Chips/pills
        static let minimal: CGFloat = Primitive.Size.xxs       // 4 - Minimal rounding
        static let circle: CGFloat = 999                        // Full circle
    }

    /// Opacity tokens - semantic names for transparency levels
    enum Opacity {
        // Glass/UI effects (ultra-transparent)
        static let glassUltraLight: Double = Primitive.Opacity.glass     // 0.05
        static let glassLight: Double = Primitive.Opacity.subtle         // 0.1
        static let glassMedium: Double = Primitive.Opacity.light         // 0.2

        // Overlay effects
        static let overlayLight: Double = Primitive.Opacity.light        // 0.2
        static let overlayMedium: Double = Primitive.Opacity.medium      // 0.3
        static let overlayStrong: Double = Primitive.Opacity.strong      // 0.5

        // Text hierarchy
        static let textDisabled: Double = Primitive.Opacity.disabled     // 0.6
        static let textSubtle: Double = Primitive.Opacity.secondary      // 0.7
        static let textTertiary: Double = Primitive.Opacity.tertiary     // 0.8
        static let textSecondary: Double = Primitive.Opacity.primary     // 0.9
        static let textPrimary: Double = Primitive.Opacity.full          // 1.0
    }

    /// Color tokens - using semantic opacity values
    enum Colors {
        // Text hierarchy (white with semantic opacity)
        static let textPrimary = Color.white.opacity(Opacity.textPrimary)
        static let textSecondary = Color.white.opacity(Opacity.textSecondary)
        static let textTertiary = Color.white.opacity(Opacity.textTertiary)
        static let textSubtle = Color.white.opacity(Opacity.textSubtle)
        static let textFaded = Color.white.opacity(Opacity.textDisabled)
        static let textPlaceholder = Color.white.opacity(Opacity.overlayMedium)

        // Borders and dividers
        static let borderStrong = Color.white.opacity(Opacity.overlayMedium)
        static let border = Color.white.opacity(Opacity.overlayLight)
        static let borderSubtle = Color.white.opacity(Opacity.glassLight)
        static let borderFaint = Color.white.opacity(Opacity.glassUltraLight)

        // Background overlays
        static let overlay20 = Color.white.opacity(Opacity.overlayLight)
        static let overlay10 = Color.white.opacity(Opacity.glassLight)
        static let overlay5 = Color.white.opacity(Opacity.glassUltraLight)

        // Black overlays for backgrounds
        static let backgroundDark = Color.black.opacity(0.8)
        static let backgroundMedium = Color.black.opacity(0.5)
        static let backgroundLight = Color.black.opacity(0.3)

        // Accent colors (from existing usage)
        static let accentBlue = Color.blue.opacity(0.8)
        static let accentGreen = Color.green.opacity(0.8)
        static let accentPurple = Color.purple.opacity(0.8)
        static let accentRed = Color.red

        // Semantic colors (for alerts, states, etc)
        static let errorPrimary = Color.red
        static let errorBackground = Color.red.opacity(0.15)
        static let errorBorder = Color.red.opacity(0.5)
        static let errorText = Color.red.opacity(0.8)

        static let warningPrimary = Color.orange
        static let warningBackground = Color.orange.opacity(0.15)
        static let warningBorder = Color.orange.opacity(0.5)

        static let successPrimary = Color.green
        static let successBackground = Color.green.opacity(0.1)
        static let successBorder = Color.green.opacity(0.3)

        static let infoPrimary = Color.blue
        static let infoBackground = Color.blue.opacity(0.15)
        static let infoBorder = Color.blue.opacity(0.5)
    }

    /// Typography tokens - semantic font scale
    enum Typography {
        // Display (largest)
        static let displayLarge = Font.system(.largeTitle, weight: .bold)
        static let displayMedium = Font.system(.title, weight: .bold)

        // Headings
        static let headingLarge = Font.system(.title2, weight: .bold)
        static let headingMedium = Font.system(.title3, weight: .semibold)
        static let headingSmall = Font.system(.headline, weight: .semibold)

        // Body text
        static let bodyLarge = Font.system(.body, weight: .regular)
        static let bodyMedium = Font.system(.callout, weight: .regular)
        static let bodySmall = Font.system(.subheadline, weight: .regular)

        // Labels
        static let labelLarge = Font.system(.caption, weight: .bold)
        static let labelMedium = Font.system(.caption, weight: .regular)
        static let labelSmall = Font.system(.caption2, weight: .regular)
    }

    // MARK: - Component Tokens (Compound values for specific components)

    /// Card component tokens
    enum Card {
        static let padding = Spacing.card
        static let radius = Radius.card
        static let shadowRadius: CGFloat = 20
        static let shadowOpacity = Opacity.overlayMedium
        static let glassOpacity = Opacity.glassUltraLight
    }

    /// Button component tokens
    enum Button {
        static let padding = Spacing.component
        static let radius = Radius.button
        static let heightStandard: CGFloat = 56
        static let heightCompact: CGFloat = 44
        static let heightSmall: CGFloat = 32
        static let iconSize: CGFloat = 20
    }

    /// Modal component tokens
    enum Modal {
        static let padding = Spacing.modal
        static let radius = Radius.modal
        static let overlayOpacity = Opacity.overlayStrong
    }

    /// Badge component tokens
    enum Badge {
        static let size: CGFloat = 12
        static let sizeLarge: CGFloat = 16
        static let offsetX: CGFloat = 4
        static let offsetY: CGFloat = -4
        static let borderWidth: CGFloat = 2
    }

    /// Alert component tokens
    enum AlertCard {
        static let borderWidth: CGFloat = 2
        static let borderWidthSubtle: CGFloat = 1
    }

    /// Shadow preset tokens
    enum Shadow {
        static let card = (color: Color.black.opacity(Opacity.overlayMedium), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(10))
        static let button = (color: Color.black.opacity(Opacity.overlayLight), radius: CGFloat(10), x: CGFloat(0), y: CGFloat(5))
        static let subtle = (color: Color.black.opacity(Opacity.glassLight), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))
    }

    /// Animation timing tokens
    enum Animation {
        static let quick = Primitive.Duration.quick
        static let standard = Primitive.Duration.normal
        static let slow = Primitive.Duration.slow
    }

    /// Material tokens
    enum Materials {
        static let glassmorphic: Material = .ultraThinMaterial
        static let glassmorphicOpacity: Double = Opacity.glassUltraLight
    }
}
