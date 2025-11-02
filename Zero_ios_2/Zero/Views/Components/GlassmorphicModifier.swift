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
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.3)
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
                        Color.white.opacity(0.2)
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
