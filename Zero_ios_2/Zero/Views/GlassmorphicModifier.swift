import SwiftUI

struct GlassmorphicModifier: ViewModifier {
    var opacity: Double = 0.03
    var blur: CGFloat = 30
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Frosted glass base
                    Color.white.opacity(opacity)
                    
                    // iOS blur effect
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                }
            )
            .overlay(
                // Glass rim lighting
                RoundedRectangle(cornerRadius: 24)
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
                // Specular highlight
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
                .allowsHitTesting(false)
            )
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

extension View {
    func glassmorphic(opacity: Double = 0.03, blur: CGFloat = 30) -> some View {
        self.modifier(GlassmorphicModifier(opacity: opacity, blur: blur))
    }
}

