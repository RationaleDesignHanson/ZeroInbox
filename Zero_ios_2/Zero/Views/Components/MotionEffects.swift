import SwiftUI

// MARK: - Scroll-Linked Header

/// Header that shrinks/expands based on scroll position
struct ScrollLinkedHeader<Content: View, Header: View>: View {
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let header: () -> Header
    let content: () -> Content
    
    @State private var scrollOffset: CGFloat = 0
    
    init(
        minHeight: CGFloat = 60,
        maxHeight: CGFloat = 120,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.header = header
        self.content = content
    }
    
    private var progress: CGFloat {
        let range = maxHeight - minHeight
        let offset = min(max(-scrollOffset, 0), range)
        return offset / range
    }
    
    private var currentHeight: CGFloat {
        maxHeight - (progress * (maxHeight - minHeight))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Scrollable content
            ScrollView {
                VStack(spacing: 0) {
                    // Spacer for header
                    Color.clear
                        .frame(height: maxHeight)
                    
                    // Main content
                    content()
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            
            // Floating header
            header()
                .frame(height: currentHeight)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial.opacity(progress > 0.1 ? 1 : 0))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: progress)
        }
    }
}

// MARK: - Parallax Container

/// Container with parallax scrolling effect
struct ParallaxContainer<Background: View, Content: View>: View {
    let parallaxStrength: CGFloat
    let background: () -> Background
    let content: () -> Content
    
    @State private var scrollOffset: CGFloat = 0
    
    init(
        parallaxStrength: CGFloat = 0.5,
        @ViewBuilder background: @escaping () -> Background,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.parallaxStrength = parallaxStrength
        self.background = background
        self.content = content
    }
    
    var body: some View {
        GeometryReader { outerGeometry in
            ZStack {
                // Parallax background
                background()
                    .frame(
                        width: outerGeometry.size.width,
                        height: outerGeometry.size.height * 1.3
                    )
                    .offset(y: -scrollOffset * parallaxStrength)
                    .clipped()
                
                // Scrollable content
                ScrollView {
                    content()
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geometry.frame(in: .named("parallax")).minY
                                )
                            }
                        )
                }
                .coordinateSpace(name: "parallax")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
            }
        }
    }
}

// MARK: - Scroll Velocity Modifier

/// Applies effects based on scroll velocity
struct ScrollVelocityModifier: ViewModifier {
    @State private var lastOffset: CGFloat = 0
    @State private var velocity: CGFloat = 0
    @State private var lastUpdate: Date = Date()
    
    let onVelocityChange: (CGFloat) -> Void
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .global).minY
                        )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { newOffset in
                let now = Date()
                let timeDelta = now.timeIntervalSince(lastUpdate)
                
                if timeDelta > 0.01 { // Throttle updates
                    let newVelocity = (newOffset - lastOffset) / CGFloat(timeDelta)
                    velocity = newVelocity
                    onVelocityChange(newVelocity)
                    
                    lastOffset = newOffset
                    lastUpdate = now
                }
            }
    }
}

// MARK: - Rubber Band Scroll Effect

/// Enhanced rubber band effect for scroll boundaries
struct RubberBandModifier: ViewModifier {
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    let resistance: CGFloat
    let maxStretch: CGFloat
    
    init(resistance: CGFloat = 0.55, maxStretch: CGFloat = 100) {
        self.resistance = resistance
        self.maxStretch = maxStretch
    }
    
    private func rubberBand(_ offset: CGFloat) -> CGFloat {
        let sign: CGFloat = offset < 0 ? -1 : 1
        let absOffset = abs(offset)
        // Rubber band formula: f(x) = (1 - (1 / (x/d + 1))) * d
        let d = maxStretch
        return sign * (1 - (1 / ((absOffset / d) + 1))) * d
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: rubberBand(dragOffset))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation.height * resistance
                    }
                    .onEnded { _ in
                        isDragging = false
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                            dragOffset = 0
                        }
                    }
            )
    }
}

// MARK: - Scroll Fade Effect

/// Fades content as it scrolls away from view
struct ScrollFadeModifier: ViewModifier {
    let threshold: CGFloat
    let direction: ScrollFadeDirection
    
    @State private var opacity: Double = 1.0
    
    enum ScrollFadeDirection {
        case top
        case bottom
        case both
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollPositionPreferenceKey.self,
                            value: ScrollPosition(
                                minY: geometry.frame(in: .global).minY,
                                maxY: geometry.frame(in: .global).maxY,
                                screenHeight: UIScreen.main.bounds.height
                            )
                        )
                }
            )
            .onPreferenceChange(ScrollPositionPreferenceKey.self) { position in
                updateOpacity(for: position)
            }
    }
    
    private func updateOpacity(for position: ScrollPosition) {
        let safeArea: CGFloat = 100
        var newOpacity: Double = 1.0
        
        switch direction {
        case .top:
            if position.minY < safeArea {
                newOpacity = max(0, Double(position.minY / safeArea))
            }
        case .bottom:
            let bottomDistance = position.screenHeight - position.maxY
            if bottomDistance < safeArea {
                newOpacity = max(0, Double(bottomDistance / safeArea))
            }
        case .both:
            if position.minY < safeArea {
                newOpacity = min(newOpacity, max(0, Double(position.minY / safeArea)))
            }
            let bottomDistance = position.screenHeight - position.maxY
            if bottomDistance < safeArea {
                newOpacity = min(newOpacity, max(0, Double(bottomDistance / safeArea)))
            }
        }
        
        opacity = newOpacity
    }
}

// MARK: - Stagger Reveal Animation

/// Reveals items with staggered timing as they scroll into view
struct StaggerRevealModifier: ViewModifier {
    let delay: Double
    let animation: Animation
    
    @State private var hasAppeared = false
    
    init(delay: Double = 0, animation: Animation = .spring(response: 0.5, dampingFraction: 0.8)) {
        self.delay = delay
        self.animation = animation
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 30)
            .onAppear {
                withAnimation(animation.delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

// MARK: - Scale On Scroll

/// Scales content based on scroll position
struct ScaleOnScrollModifier: ViewModifier {
    let minScale: CGFloat
    let maxScale: CGFloat
    
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .global).minY
                        )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                let screenCenter = UIScreen.main.bounds.height / 2
                let distance = abs(offset - screenCenter)
                let normalizedDistance = min(distance / screenCenter, 1.0)
                scale = maxScale - (normalizedDistance * (maxScale - minScale))
            }
    }
}

// MARK: - Preference Keys

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScrollPosition: Equatable {
    let minY: CGFloat
    let maxY: CGFloat
    let screenHeight: CGFloat
}

struct ScrollPositionPreferenceKey: PreferenceKey {
    static var defaultValue: ScrollPosition = ScrollPosition(minY: 0, maxY: 0, screenHeight: 0)
    static func reduce(value: inout ScrollPosition, nextValue: () -> ScrollPosition) {
        value = nextValue()
    }
}

// MARK: - View Extensions

extension View {
    /// Track scroll velocity and trigger callback
    func onScrollVelocity(_ callback: @escaping (CGFloat) -> Void) -> some View {
        modifier(ScrollVelocityModifier(onVelocityChange: callback))
    }
    
    /// Apply rubber band effect to boundaries
    func rubberBand(resistance: CGFloat = 0.55, maxStretch: CGFloat = 100) -> some View {
        modifier(RubberBandModifier(resistance: resistance, maxStretch: maxStretch))
    }
    
    /// Fade content as it scrolls
    func scrollFade(threshold: CGFloat = 100, direction: ScrollFadeModifier.ScrollFadeDirection = .both) -> some View {
        modifier(ScrollFadeModifier(threshold: threshold, direction: direction))
    }
    
    /// Reveal with staggered animation
    func staggerReveal(delay: Double = 0, animation: Animation = .spring(response: 0.5, dampingFraction: 0.8)) -> some View {
        modifier(StaggerRevealModifier(delay: delay, animation: animation))
    }
    
    /// Scale based on scroll position
    func scaleOnScroll(min: CGFloat = 0.9, max: CGFloat = 1.0) -> some View {
        modifier(ScaleOnScrollModifier(minScale: min, maxScale: max))
    }
}

// MARK: - Preview

#Preview("Motion Effects") {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 100)
                    .overlay(
                        Text("Item \(index)")
                            .foregroundColor(.white)
                    )
                    .staggerReveal(delay: Double(index) * 0.05)
                    .scrollFade(direction: .both)
            }
        }
        .padding()
    }
    .background(Color.black)
}

