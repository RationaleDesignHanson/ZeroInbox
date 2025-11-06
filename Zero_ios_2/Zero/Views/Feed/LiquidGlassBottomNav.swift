import SwiftUI

/// Simplified bottom navigation bar matching web demo design
/// Uses Apple's liquid glass materials for premium native appearance
struct LiquidGlassBottomNav: View {
    @ObservedObject var viewModel: EmailViewModel
    @Binding var showShoppingCart: Bool
    @Binding var showSettings: Bool
    @Binding var showSearch: Bool
    var cartItemCount: Int
    var mailCount: Int = 0  // Number of remaining mail emails
    var adsCount: Int = 0   // Number of remaining ads emails
    var totalInitialCards: Int = 0  // Total cards at start (for progress calculation)
    var onRefresh: () async -> Void

    var body: some View {
        // Single unified floating island with integrated progress
        VStack(spacing: 0) {
            // Progress meter integrated at top of island (compact single-line)
            if showProgressMeter {
                progressMeter
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                // Subtle divider
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
            }

            // Main navigation content
            HStack(spacing: 0) {
                // LEFT SECTION: Archetype Toggle
                archetypeToggleSection

                Spacer()

                // RIGHT SECTION: Action Icons
                actionIconsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            // Premium iOS liquid glass with web demo gradient
            ZStack {
                // Base gradient matching web demo (#1a1a2e → #2d1b4e → #4a1942 → #1f1f3a)
                LinearGradient(
                    colors: [
                        Color(red: 0x1a/255, green: 0x1a/255, blue: 0x2e/255),
                        Color(red: 0x2d/255, green: 0x1b/255, blue: 0x4e/255),
                        Color(red: 0x4a/255, green: 0x19/255, blue: 0x42/255),
                        Color(red: 0x1f/255, green: 0x1f/255, blue: 0x3a/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Premium iOS blur material for glass effect
                .background(.regularMaterial.opacity(0.6))

                // Subtle highlight overlay for depth
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color.clear,
                        Color.black.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .cornerRadius(20)  // Rounded corners for island effect
        .padding(.horizontal, 16)  // Side padding creates floating effect
        .padding(.bottom, 16)  // Bottom padding lifts it off screen edge
        .shadow(color: Color.black.opacity(0.4), radius: 20, y: -5)  // Elevated shadow
    }

    // MARK: - Progress Calculation

    private var remainingCards: Int {
        mailCount + adsCount
    }

    private var progressPercentage: Double {
        guard totalInitialCards > 0 else { return 0.0 }
        let processed = totalInitialCards - remainingCards
        let percentage = Double(processed) / Double(totalInitialCards)
        // Clamp between 0 and 1 to prevent invalid frame dimensions
        return max(0.0, min(1.0, percentage.isNaN ? 0.0 : percentage))
    }

    private var showProgressMeter: Bool {
        totalInitialCards > 0  // Show progress bar as long as we have cards
    }

    private func validProgressWidth(geometryWidth: CGFloat) -> CGFloat {
        // Ensure geometry width is valid
        guard geometryWidth.isFinite, geometryWidth > 0 else { return 0 }

        // Calculate progress width with safety checks
        let progressWidth = geometryWidth * CGFloat(progressPercentage)

        // Ensure result is valid and within bounds
        guard progressWidth.isFinite else { return 0 }
        return max(0, min(geometryWidth, progressWidth))
    }

    // MARK: - Left Section: Archetype Toggle

    private var archetypeToggleSection: some View {
        HStack(spacing: 8) {
            archetypePill(.mail, isActive: viewModel.currentArchetype == .mail)
            archetypePill(.ads, isActive: viewModel.currentArchetype == .ads)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private func archetypePill(_ type: CardType, isActive: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                // Switch to the selected archetype
                viewModel.currentArchetype = type
                // Reset to first card of this archetype
                viewModel.currentIndex = 0
            }
        } label: {
            HStack(spacing: 4) {
                Text(type.displayName)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isActive ? archetypeGradient(for: type) :
                LinearGradient(
                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(alignment: .topTrailing) {
            // Email counter badge
            let count = type == .mail ? mailCount : adsCount
            if count > 0 {
                emailCountBadge(count: count)
            }
        }
    }

    private func emailCountBadge(count: Int) -> some View {
        Text("\(count)")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .offset(x: 4, y: -4)
    }

    private func archetypeGradient(for type: CardType) -> LinearGradient {
        switch type {
        case .mail:
            return LinearGradient(
                colors: [DesignTokens.Colors.mailGradientStart, DesignTokens.Colors.mailGradientEnd],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .ads:
            return LinearGradient(
                colors: [DesignTokens.Colors.adsGradientStart, DesignTokens.Colors.adsGradientEnd],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    // MARK: - Right Section: Action Icons

    private var actionIconsSection: some View {
        HStack(spacing: 12) {
            // Shopping Cart with Badge
            navIcon(systemImage: "cart.fill") {
                showShoppingCart = true
            }
            .overlay(alignment: .topTrailing) {
                if cartItemCount > 0 {
                    cartBadge
                }
            }

            // Settings
            navIcon(systemImage: "gearshape.fill") {
                showSettings = true
            }

            // Search
            navIcon(systemImage: "magnifyingglass") {
                showSearch = true
            }

            // Refresh
            navIcon(systemImage: "arrow.clockwise") {
                Task {
                    await onRefresh()
                }
            }
        }
    }

    private func navIcon(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.15))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var cartBadge: some View {
        Text("\(cartItemCount)")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(4)
            .background(
                Circle()
                    .fill(Color.red)
                    .shadow(color: Color.red.opacity(0.5), radius: 4, x: 0, y: 2)
            )
            .offset(x: 6, y: -6)
    }

    // MARK: - Progress Meter

    private var progressMeter: some View {
        HStack(spacing: 8) {
            // Label and percentage
            HStack(spacing: 4) {
                Text("INBOX PROGRESS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.5)

                Text("\(Int(progressPercentage * 100))%")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .fixedSize()

            // Progress bar (expands to fill available space)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)

                    // Filled progress with holographic gradient
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.cyan.opacity(0.9),
                                    Color.blue.opacity(1.0),
                                    Color.purple.opacity(0.9),
                                    Color.pink.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: validProgressWidth(geometryWidth: geometry.size.width), height: 4)
                        .shadow(color: Color.cyan.opacity(0.6), radius: 4, x: 0, y: 0)
                }
            }
            .frame(height: 4)
        }
    }

    // MARK: - Holographic Top Border

    private var holographicTopBorder: some View {
        ZStack {
            // Main holographic gradient border (thicker + more visible)
            LinearGradient(
                colors: [
                    Color.cyan.opacity(0.95),
                    Color.blue.opacity(1.0),
                    Color.purple.opacity(0.95),
                    Color.pink.opacity(0.9)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)
            .shadow(color: Color.cyan.opacity(0.6), radius: 6, x: 0, y: 0)

            // Strong glow effect
            LinearGradient(
                colors: [
                    Color.cyan.opacity(0.7),
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.7),
                    Color.pink.opacity(0.6)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 8)
            .blur(radius: 6)
        }
    }
}
