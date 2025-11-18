import SwiftUI

/// Glassmorphic effect modifier inspired by swipe-app
/// Creates premium frosted glass effect with rim lighting and specular highlights
struct GlassmorphicModifier: ViewModifier {
    var opacity: Double
    var blur: CGFloat
    var cornerRadius: CGFloat

    init(
        opacity: Double = DesignTokens.Opacity.glassUltraLight,
        blur: CGFloat = 30,
        cornerRadius: CGFloat = DesignTokens.Radius.card
    ) {
        self.opacity = opacity
        self.blur = blur
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Frosted glass base (ultra-low opacity)
                    Color.white.opacity(opacity)

                    // System material blur for native frosted glass effect
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                }
            )
            .overlay(
                // Glass rim lighting (gradient border for shimmer effect)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(DesignTokens.Opacity.glassLight),
                                Color.white.opacity(DesignTokens.Opacity.overlayMedium)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(
                // Specular highlight (simulates light reflection/shine)
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.4),
                        Color.clear,
                        Color.clear,
                        Color.white.opacity(DesignTokens.Opacity.overlayLight)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(cornerRadius)
                .allowsHitTesting(false)
            )
    }
}

/// UIKit bridge for system blur effect
/// Provides native iOS frosted glass material
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

/// Convenience extension for applying glassmorphic effect
extension View {
    /// Apply glassmorphic frosted glass effect
    /// - Parameters:
    ///   - opacity: Background opacity (default: glassUltraLight for maximum gradient visibility)
    ///   - blur: Blur radius (default: 30)
    ///   - cornerRadius: Corner radius (default: Radius.card)
    func glassmorphic(
        opacity: Double = DesignTokens.Opacity.glassUltraLight,
        blur: CGFloat = 30,
        cornerRadius: CGFloat = DesignTokens.Radius.card
    ) -> some View {
        self.modifier(GlassmorphicModifier(opacity: opacity, blur: blur, cornerRadius: cornerRadius))
    }
}

// MARK: - Glass Card Styles (Phase 5: Card Styling Consolidation)

/// Simple glass card with padding and border
/// Replaces the most common duplicated pattern (50+ occurrences)
struct GlassCardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let borderColor: Color
    let borderOpacity: Double
    let padding: CGFloat

    init(
        cornerRadius: CGFloat = DesignTokens.Radius.container,
        borderColor: Color = .white,
        borderOpacity: Double = DesignTokens.Opacity.overlayMedium,
        padding: CGFloat = DesignTokens.Spacing.section
    ) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderOpacity = borderOpacity
        self.padding = padding
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(borderColor.opacity(borderOpacity), lineWidth: 1)
                    )
            )
    }
}

/// Solid card style with shadow
struct SolidCardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let backgroundColor: Color
    let shadowRadius: CGFloat
    let padding: CGFloat

    init(
        cornerRadius: CGFloat = DesignTokens.Radius.container,
        backgroundColor: Color = Color(white: 0.15),
        shadowRadius: CGFloat = 8,
        padding: CGFloat = DesignTokens.Spacing.section
    ) {
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.shadowRadius = shadowRadius
        self.padding = padding
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .shadow(color: Color.black.opacity(0.2), radius: shadowRadius, x: 0, y: 4)
            )
    }
}

/// Gradient card style with border
struct GradientCardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let colors: [Color]
    let borderColor: Color?
    let padding: CGFloat

    init(
        cornerRadius: CGFloat = DesignTokens.Radius.container,
        colors: [Color],
        borderColor: Color? = nil,
        padding: CGFloat = DesignTokens.Spacing.section
    ) {
        self.cornerRadius = cornerRadius
        self.colors = colors
        self.borderColor = borderColor
        self.padding = padding
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Group {
                            if let borderColor = borderColor {
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .strokeBorder(borderColor.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                            }
                        }
                    )
            )
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Apply simple glass card style (most common pattern)
    /// - Parameters:
    ///   - cornerRadius: Corner radius (default: container)
    ///   - borderColor: Border color (default: white)
    ///   - borderOpacity: Border opacity (default: overlayMedium)
    ///   - padding: Inner padding (default: section)
    func glassCard(
        cornerRadius: CGFloat = DesignTokens.Radius.container,
        borderColor: Color = .white,
        borderOpacity: Double = DesignTokens.Opacity.overlayMedium,
        padding: CGFloat = DesignTokens.Spacing.section
    ) -> some View {
        self.modifier(GlassCardStyle(
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            borderOpacity: borderOpacity,
            padding: padding
        ))
    }

    /// Apply solid card style with shadow
    /// - Parameters:
    ///   - cornerRadius: Corner radius (default: container)
    ///   - backgroundColor: Background color (default: dark gray)
    ///   - shadowRadius: Shadow blur radius (default: 8)
    ///   - padding: Inner padding (default: section)
    func solidCard(
        cornerRadius: CGFloat = DesignTokens.Radius.container,
        backgroundColor: Color = Color(white: 0.15),
        shadowRadius: CGFloat = 8,
        padding: CGFloat = DesignTokens.Spacing.section
    ) -> some View {
        self.modifier(SolidCardStyle(
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            shadowRadius: shadowRadius,
            padding: padding
        ))
    }

    /// Apply gradient card style
    /// - Parameters:
    ///   - cornerRadius: Corner radius (default: container)
    ///   - colors: Gradient colors
    ///   - borderColor: Optional border color
    ///   - padding: Inner padding (default: section)
    func gradientCard(
        cornerRadius: CGFloat = DesignTokens.Radius.container,
        colors: [Color],
        borderColor: Color? = nil,
        padding: CGFloat = DesignTokens.Spacing.section
    ) -> some View {
        self.modifier(GradientCardStyle(
            cornerRadius: cornerRadius,
            colors: colors,
            borderColor: borderColor,
            padding: padding
        ))
    }
}
