import SwiftUI

/// Design Tokens - Semantic naming system for consistent styling
/// Architecture: Primitive values → Semantic tokens → Component tokens
/// Version 2.0.0
/// Generated: 2025-12-18T23:11:14.273Z
/// DO NOT EDIT MANUALLY - This file is auto-generated from design-system/tokens.json
enum DesignTokens {

    // MARK: - Primitive Tokens (Raw values - internal use only)

    enum Primitive {
        /// Base size scale (powers of 2 and common increments)
        enum Size {
            static let xxxs: CGFloat = 2
            static let xxs: CGFloat = 4
            static let xs: CGFloat = 6
            static let sm: CGFloat = 8
            static let md: CGFloat = 10
            static let lg: CGFloat = 12
            static let xl: CGFloat = 16
            static let xxl: CGFloat = 20
            static let xxxl: CGFloat = 24
            static let xxxxl: CGFloat = 32
            static let xxxxxl: CGFloat = 48
        }

        /// Opacity scale (0.0 - 1.0)
        enum Opacity {
            static let none: Double = 0          // Fully transparent
            static let glass: Double = 0.05          // Ultra-transparent for glass effects
            static let subtle: Double = 0.1          // Barely visible
            static let light: Double = 0.2          // Light overlays
            static let medium: Double = 0.3          // Standard overlays
            static let strong: Double = 0.5          // Heavy overlays
            static let disabled: Double = 0.6          // Disabled/faded elements
            static let secondary: Double = 0.7          // Secondary text
            static let tertiary: Double = 0.8          // Tertiary text
            static let primary: Double = 0.9          // Primary readable text
            static let full: Double = 1          // Fully opaque
        }

        /// Blur radius scale (for glassmorphic effects)
        enum Blur {
            static let subtle: CGFloat = 10          // Light blur
            static let standard: CGFloat = 20          // Standard glassmorphic
            static let heavy: CGFloat = 30          // Intense glassmorphic
            static let ultra: CGFloat = 40          // Ultra-blurred backgrounds
        }

        /// Animation duration scale (in seconds)
        enum Duration {
            static let instant: Double = 0.1
            static let quick: Double = 0.2
            static let fast: Double = 0.3
            static let normal: Double = 0.5
            static let slow: Double = 0.7
            static let lazy: Double = 1
        }
    }


    // MARK: - Semantic Tokens (Usage-based - primary API)

    /// Spacing tokens - semantic names for layout spacing
    enum Spacing {
        static let card: CGFloat = Primitive.Size.xxxl // Card padding (24px)
        static let modal: CGFloat = Primitive.Size.xxxl // Modal padding (24px)
        static let section: CGFloat = Primitive.Size.xxl // Section gaps (20px)
        static let component: CGFloat = Primitive.Size.xl // Component spacing (16px)
        static let element: CGFloat = Primitive.Size.lg // Element spacing (12px)
        static let inline: CGFloat = Primitive.Size.sm // Inline spacing (8px)
        static let tight: CGFloat = Primitive.Size.xs // Tight spacing (6px)
        static let minimal: CGFloat = Primitive.Size.xxs // Minimal spacing (4px)
    }



    /// Corner radius tokens - semantic names for border radius
    enum Radius {
        static let card: CGFloat = Primitive.Size.xl // Main cards (16px)
        static let modal: CGFloat = Primitive.Size.xxl // Modals (20px)
        static let container: CGFloat = Primitive.Size.xl // Containers (16px)
        static let button: CGFloat = Primitive.Size.lg // Buttons (12px)
        static let chip: CGFloat = Primitive.Size.sm // Chips/pills (8px)
        static let minimal: CGFloat = Primitive.Size.xxs // Minimal rounding (4px)
        static let circle: CGFloat = 999 // Full circle
    }



    /// Opacity tokens - semantic names for transparency levels
    enum Opacity {
        // Glass/UI effects (ultra-transparent)
        static let glassUltraLight: Double = Primitive.Opacity.glass // 0.05
        static let glassLight: Double = Primitive.Opacity.subtle // 0.1
        static let glassMedium: Double = Primitive.Opacity.light // 0.2

        // Overlay effects
        static let overlayLight: Double = Primitive.Opacity.light // 0.2
        static let overlayMedium: Double = Primitive.Opacity.medium // 0.3
        static let overlayStrong: Double = Primitive.Opacity.strong // 0.5

        // Text hierarchy
        static let textDisabled: Double = Primitive.Opacity.disabled // 0.6
        static let textSubtle: Double = Primitive.Opacity.secondary // 0.7
        static let textTertiary: Double = Primitive.Opacity.tertiary // 0.8
        static let textSecondary: Double = Primitive.Opacity.primary // 0.9
        static let textPrimary: Double = Primitive.Opacity.full // 1
    }



    /// Color tokens - using semantic opacity values
    enum Colors {
        // Text hierarchy (white with semantic opacity)
        static let textPrimary = Color.white.opacity(Opacity.textPrimary)
        static let textSecondary = Color.white.opacity(Opacity.textSecondary)
        static let textTertiary = Color.white.opacity(Opacity.textTertiary)
        static let textSubtle = Color.white.opacity(Opacity.textSubtle)
        static let textFaded = Color.white.opacity(Opacity.textDisabled)
        static let textPlaceholder = Color.white.opacity(Opacity.textDisabled)

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

        // Archetype gradient colors (matching web demo)
        static let mailGradientStart = Color(red: 0.40, green: 0.49, blue: 0.92)      // #667eea - blue
        static let mailGradientEnd = Color(red: 0.46, green: 0.29, blue: 0.64)      // #764ba2 - purple
        static let adsGradientStart = Color(red: 0.09, green: 0.73, blue: 0.67)     // #16bbaa - teal/cyan
        static let adsGradientEnd = Color(red: 0.31, green: 0.82, blue: 0.62)       // #4fd19e - green

        // Ads-specific text colors (dark text for light backgrounds)
        static let adsTextPrimary = Color(red: 0.05, green: 0.35, blue: 0.30) // Dark teal - primary (rgb(0.05, 0.35, 0.30))
        static let adsTextSecondary = Color(red: 0.08, green: 0.45, blue: 0.38) // Medium teal - secondary (rgb(0.08, 0.45, 0.38))
        static let adsTextTertiary = Color(red: 0.10, green: 0.52, blue: 0.45) // Lighter teal - tertiary (rgb(0.10, 0.52, 0.45))
        static let adsTextSubtle = Color(red: 0.15, green: 0.60, blue: 0.52) // Subtle teal (rgb(0.15, 0.60, 0.52))
        static let adsTextFaded = Color(red: 0.20, green: 0.65, blue: 0.57).opacity(0.7) // Faded teal (rgb(0.20, 0.65, 0.57))

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
    /// World-class typography with refined hierarchy and optimal readability
    enum Typography {
        // Display (largest) - hero headlines, splash screens
        static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)

        // Headings - section titles, card titles
        static let headingLarge = Font.system(size: 22, weight: .bold, design: .rounded)
        static let headingMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headingSmall = Font.system(size: 17, weight: .semibold, design: .default)

        // Body text - main content, readable paragraphs
        static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)

        // Labels - UI labels, metadata, timestamps
        static let labelLarge = Font.system(size: 13, weight: .semibold, design: .default)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 11, weight: .regular, design: .default)

        // Email Card Typography (world-class card components)
        static let cardTitle = Font.system(size: 20, weight: .bold, design: .rounded)         // Email card title - prominent, scannable
        static let cardSender = Font.system(size: 16, weight: .semibold, design: .default)    // Clear sender identification
        static let cardSummary = Font.system(size: 15, weight: .regular, design: .default)    // Readable preview
        static let cardSectionHeader = Font.system(size: 13, weight: .bold, design: .default) // Section headers uppercase
        static let cardTimestamp = Font.system(size: 13, weight: .medium, design: .default)   // Subtle but legible
        static let cardMetadata = Font.system(size: 12, weight: .regular, design: .default)   // Secondary info

        // Thread Typography (for threaded card views)
        static let threadTitle = Font.system(size: 15, weight: .semibold, design: .default)
        static let threadSummary = Font.system(size: 16, weight: .regular, design: .default)
        static let threadMessageSender = Font.system(size: 14, weight: .semibold, design: .default)
        static let threadMessageBody = Font.system(size: 14, weight: .regular, design: .default)

        // Reader Typography (world-class email reader)
        static let readerSubject = Font.system(size: 24, weight: .bold, design: .rounded)     // Commanding presence for email subject
        static let readerSender = Font.system(size: 17, weight: .semibold, design: .default)  // Clear attribution
        static let readerBody = Font.system(size: 16, weight: .regular, design: .default)     // Optimal reading
        static let readerQuote = Font.system(size: 15, weight: .regular, design: .serif)      // Quoted text distinction
        static let readerMetadata = Font.system(size: 13, weight: .medium, design: .default)  // Timestamps, labels

        // Action Typography (buttons, CTAs)
        static let actionPrimary = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let actionSecondary = Font.system(size: 15, weight: .medium, design: .default)
        static let actionTertiary = Font.system(size: 14, weight: .medium, design: .default)

        // Badge Typography (status indicators, tags)
        static let badgeLarge = Font.system(size: 12, weight: .bold, design: .default)
        static let badgeSmall = Font.system(size: 10, weight: .bold, design: .default)

        // AI Analysis Typography (card AI preview section)
        static let aiAnalysisTitle = Font.system(size: 11, weight: .bold, design: .default)         // AI Analysis header title
        static let aiAnalysisSectionHeader = Font.system(size: 11, weight: .semibold, design: .default) // Section headers (SUGGESTED ACTIONS, etc)
        static let aiAnalysisActionText = Font.system(size: 15, weight: .regular, design: .default)    // Action item text
        static let aiAnalysisContextText = Font.system(size: 14, weight: .regular, design: .default)  // Context and explanation text
        static let aiAnalysisWhyText = Font.system(size: 14, weight: .regular, design: .default)      // Why this matters text
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

    /// AI Analysis box component tokens
    enum AIAnalysisBox {
        static let padding = Spacing.component
        static let radius = Radius.button
        static let borderWidth: CGFloat = 1.5
    }

    /// Bottom action bar component tokens
    enum BottomActionBar {
        static let height: CGFloat = 48
        static let padding = Spacing.element
        static let radius = Radius.chip
    }

    /// Shadow preset tokens
    enum Shadow {
        static let card = (color: Color.black.opacity(0.4), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(10))  // Updated to 0.4 (web demo)
        static let button = (color: Color.black.opacity(Opacity.overlayLight), radius: CGFloat(10), x: CGFloat(0), y: CGFloat(5))
        static let subtle = (color: Color.black.opacity(Opacity.glassLight), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))
    }



    /// Animation timing tokens
    enum Animation {
        // Duration presets
        static let quick = Primitive.Duration.quick
        static let standard = Primitive.Duration.normal
        static let slow = Primitive.Duration.slow
        
        // Spring presets for world-class microinteractions
        enum Spring {
            /// Snappy response for buttons and quick interactions
            static let snappy = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.7)
            /// Bouncy for playful elements
            static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
            /// Gentle for subtle transitions
            static let gentle = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
            /// Heavy for significant actions
            static let heavy = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.75)
        }
        
        // Easing presets
        enum Ease {
            static let `in` = SwiftUI.Animation.easeIn(duration: Primitive.Duration.normal)
            static let out = SwiftUI.Animation.easeOut(duration: Primitive.Duration.normal)
            static let inOut = SwiftUI.Animation.easeInOut(duration: Primitive.Duration.normal)
        }
    }



    /// Material tokens
    enum Materials {
        static let glassmorphic: Material = .ultraThinMaterial
        static let glassmorphicOpacity: Double = Opacity.glassUltraLight
    }

}

// MARK: - Color Extension for Hex Support

extension Color {
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
