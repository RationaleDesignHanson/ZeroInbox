import SwiftUI

/// Vibrant gradient button style inspired by swipe-app
/// Creates blue-to-purple gradient buttons with shadows and press animations
struct GradientButtonStyle: ButtonStyle {
    var colors: [Color]
    var startPoint: UnitPoint
    var endPoint: UnitPoint
    var shadowColor: Color

    init(
        colors: [Color] = [.vibrantBlue, .vibrantPurple],
        startPoint: UnitPoint = .leading,
        endPoint: UnitPoint = .trailing
    ) {
        self.colors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.shadowColor = colors.first ?? .blue
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
            .cornerRadius(16)
            .shadow(color: shadowColor.opacity(0.4), radius: 10, y: 5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

/// Preset gradient button styles
extension ButtonStyle where Self == GradientButtonStyle {
    /// Default blue-to-purple gradient (primary actions)
    static var gradientPrimary: GradientButtonStyle {
        GradientButtonStyle()
    }

    /// Purple-to-pink gradient (lifestyle actions)
    static var gradientLifestyle: GradientButtonStyle {
        GradientButtonStyle(colors: [.vibrantPurple, .vibrantPink])
    }

    /// Green-to-emerald gradient (shopping actions)
    static var gradientShop: GradientButtonStyle {
        GradientButtonStyle(colors: [.vibrantGreen, .vibrantEmerald])
    }

    /// Blue-to-cyan gradient (personal/work actions)
    static var gradientBlue: GradientButtonStyle {
        GradientButtonStyle(colors: [.vibrantBlue, .vibrantCyan])
    }

    /// Orange-to-yellow gradient (urgent actions)
    static var gradientUrgent: GradientButtonStyle {
        GradientButtonStyle(colors: [.vibrantOrange, .vibrantYellow])
    }
}

/// Convenience extension for applying gradient button styles
extension View {
    /// Apply gradient button style with custom colors
    func gradientButtonStyle(colors: [Color], startPoint: UnitPoint = .leading, endPoint: UnitPoint = .trailing) -> some View {
        self.buttonStyle(GradientButtonStyle(colors: colors, startPoint: startPoint, endPoint: endPoint))
    }
}
