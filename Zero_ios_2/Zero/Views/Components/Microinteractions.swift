import SwiftUI

// MARK: - Press Scale Effect

/// A button style that provides satisfying press feedback with scale and opacity
struct PressableButtonStyle: ButtonStyle {
    let scale: CGFloat
    let opacity: CGFloat
    let hapticStyle: HapticStyle
    
    enum HapticStyle {
        case none
        case light
        case medium
        case heavy
        case soft
    }
    
    init(scale: CGFloat = 0.96, opacity: CGFloat = 0.85, haptic: HapticStyle = .light) {
        self.scale = scale
        self.opacity = opacity
        self.hapticStyle = haptic
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? opacity : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    triggerHaptic()
                }
            }
    }
    
    private func triggerHaptic() {
        switch hapticStyle {
        case .none: break
        case .light: HapticService.shared.lightImpact()
        case .medium: HapticService.shared.mediumImpact()
        case .heavy: HapticService.shared.heavyImpact()
        case .soft: HapticService.shared.softImpact()
        }
    }
}

// MARK: - Bounce Press Style

/// Button style with bounce animation on press
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.interpolatingSpring(stiffness: 400, damping: 10), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticService.shared.lightImpact()
                }
            }
    }
}

// MARK: - Card Press Style

/// Specialized press style for email cards with subtle depth change
struct CardPressStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && isEnabled ? 0.98 : 1.0)
            .brightness(configuration.isPressed && isEnabled ? -0.02 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Tap Ripple Effect

/// Ripple effect view modifier for tap feedback
struct TapRippleModifier: ViewModifier {
    @State private var ripplePosition: CGPoint = .zero
    @State private var isAnimating = false
    let color: Color
    
    init(color: Color = .white.opacity(0.3)) {
        self.color = color
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    ZStack {
                        if isAnimating {
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .scaleEffect(isAnimating ? 8 : 0)
                                .opacity(isAnimating ? 0 : 0.5)
                                .position(ripplePosition)
                                .animation(.easeOut(duration: 0.5), value: isAnimating)
                        }
                    }
                    .allowsHitTesting(false)
                }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isAnimating {
                            ripplePosition = value.location
                            isAnimating = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isAnimating = false
                            }
                        }
                    }
            )
    }
}

// MARK: - Glow Pulse Effect

/// Pulsing glow effect for attention-grabbing elements
struct GlowPulseModifier: ViewModifier {
    @State private var isPulsing = false
    let color: Color
    let radius: CGFloat
    let duration: Double
    
    init(color: Color = .white, radius: CGFloat = 10, duration: Double = 1.5) {
        self.color = color
        self.radius = radius
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isPulsing ? 0.6 : 0.2), radius: isPulsing ? radius : radius * 0.5)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Shake Effect

/// Shake animation for error states
struct ShakeModifier: ViewModifier {
    @Binding var isShaking: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: isShaking ? -10 : 0)
            .animation(
                isShaking ?
                    Animation.interpolatingSpring(stiffness: 500, damping: 5)
                        .repeatCount(3, autoreverses: true) : .default,
                value: isShaking
            )
            .onChange(of: isShaking) { _, shaking in
                if shaking {
                    HapticService.shared.error()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isShaking = false
                    }
                }
            }
    }
}

// MARK: - Success Check Animation

/// Animated checkmark for success states
struct SuccessCheckView: View {
    @State private var showCheck = false
    let size: CGFloat
    let color: Color
    let onComplete: (() -> Void)?
    
    init(size: CGFloat = 60, color: Color = .green, onComplete: (() -> Void)? = nil) {
        self.size = size
        self.color = color
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
                .scaleEffect(showCheck ? 1 : 0)
            
            Circle()
                .strokeBorder(color, lineWidth: 3)
                .frame(width: size, height: size)
                .scaleEffect(showCheck ? 1 : 0)
            
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(color)
                .scaleEffect(showCheck ? 1 : 0)
                .rotationEffect(.degrees(showCheck ? 0 : -90))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showCheck)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showCheck = true
                HapticService.shared.success()
                
                if let completion = onComplete {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        completion()
                    }
                }
            }
        }
    }
}

// MARK: - Floating Action Animation

/// Floating/breathing animation for action buttons
struct FloatingModifier: ViewModifier {
    @State private var isFloating = false
    let amplitude: CGFloat
    let duration: Double
    
    init(amplitude: CGFloat = 4, duration: Double = 2.0) {
        self.amplitude = amplitude
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -amplitude : amplitude)
            .animation(
                .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                isFloating = true
            }
    }
}

// MARK: - Stagger Animation Container

/// Container that staggers child animations
struct StaggeredAnimationContainer<Content: View>: View {
    let content: Content
    let itemCount: Int
    let baseDelay: Double
    let stagger: Double
    @State private var appeared = false
    
    init(
        itemCount: Int,
        baseDelay: Double = 0.1,
        stagger: Double = 0.05,
        @ViewBuilder content: () -> Content
    ) {
        self.itemCount = itemCount
        self.baseDelay = baseDelay
        self.stagger = stagger
        self.content = content()
    }
    
    var body: some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(baseDelay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Interactive Scale Modifier

/// Scale effect that responds to continuous gesture
struct InteractiveScaleModifier: ViewModifier {
    @GestureState private var isPressed = false
    let minScale: CGFloat
    let maxScale: CGFloat
    
    init(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05) {
        self.minScale = minScale
        self.maxScale = maxScale
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? minScale : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
            .gesture(
                LongPressGesture(minimumDuration: .infinity)
                    .updating($isPressed) { currentState, gestureState, _ in
                        gestureState = currentState
                    }
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply pressable button style with customizable parameters
    func pressable(scale: CGFloat = 0.96, opacity: CGFloat = 0.85, haptic: PressableButtonStyle.HapticStyle = .light) -> some View {
        self.buttonStyle(PressableButtonStyle(scale: scale, opacity: opacity, haptic: haptic))
    }
    
    /// Apply bounce press animation
    func bouncePress() -> some View {
        self.buttonStyle(BounceButtonStyle())
    }
    
    /// Apply card press style
    func cardPress(isEnabled: Bool = true) -> some View {
        self.buttonStyle(CardPressStyle(isEnabled: isEnabled))
    }
    
    /// Apply tap ripple effect
    func tapRipple(color: Color = .white.opacity(0.3)) -> some View {
        self.modifier(TapRippleModifier(color: color))
    }
    
    /// Apply glow pulse effect
    func glowPulse(color: Color = .white, radius: CGFloat = 10, duration: Double = 1.5) -> some View {
        self.modifier(GlowPulseModifier(color: color, radius: radius, duration: duration))
    }
    
    /// Apply shake animation
    func shake(isShaking: Binding<Bool>) -> some View {
        self.modifier(ShakeModifier(isShaking: isShaking))
    }
    
    /// Apply floating animation
    func floating(amplitude: CGFloat = 4, duration: Double = 2.0) -> some View {
        self.modifier(FloatingModifier(amplitude: amplitude, duration: duration))
    }
    
    /// Apply interactive scale on press
    func interactiveScale(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05) -> some View {
        self.modifier(InteractiveScaleModifier(minScale: minScale, maxScale: maxScale))
    }
}

// MARK: - Preview

#Preview("Microinteractions") {
    VStack(spacing: 24) {
        Button("Pressable Button") {}
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .pressable()
        
        Button("Bounce Button") {}
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
            .bouncePress()
        
        Text("Glow Pulse")
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
            .glowPulse(color: .purple)
        
        Text("Floating")
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(12)
            .floating()
        
        SuccessCheckView()
    }
    .padding()
    .background(Color.black)
}

