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
                    .fill(
                        viewModel.currentArchetype == .ads ?
                            DesignTokens.Colors.adsTextSubtle.opacity(0.15) :
                            Color.white.opacity(0.15)
                    )
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
            // Premium iOS liquid glass - changes based on archetype
            ZStack {
                // Base gradient changes for ads vs mail
                baseGradient

                // Premium iOS blur material for glass effect
                .background(.regularMaterial.opacity(DesignTokens.Opacity.textDisabled))

                // Subtle highlight overlay for depth
                highlightOverlay
            }
        )
        .cornerRadius(DesignTokens.Radius.modal)  // Rounded corners for island effect
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
        .background(
            viewModel.currentArchetype == .ads ?
                DesignTokens.Colors.adsTextSubtle.opacity(0.15) :
                Color.black.opacity(DesignTokens.Opacity.overlayMedium)
        )
        .cornerRadius(DesignTokens.Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    viewModel.currentArchetype == .ads ?
                        DesignTokens.Colors.adsTextSubtle.opacity(DesignTokens.Opacity.overlayLight) :
                        Color.white.opacity(DesignTokens.Opacity.overlayLight),
                    lineWidth: 1
                )
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
                    colors: [Color.white.opacity(DesignTokens.Opacity.glassLight), Color.white.opacity(DesignTokens.Opacity.glassLight)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(viewModel.currentArchetype == .ads ? DesignTokens.Colors.adsTextPrimary : .white)
            .cornerRadius(DesignTokens.Radius.button)
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
                    .fill(Color.black.opacity(DesignTokens.Opacity.textDisabled))
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                viewModel.currentArchetype == .ads ?
                                    DesignTokens.Colors.adsTextSubtle.opacity(DesignTokens.Opacity.overlayMedium) :
                                    Color.white.opacity(DesignTokens.Opacity.overlayMedium),
                                lineWidth: 1
                            )
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
                .foregroundColor(viewModel.currentArchetype == .ads ? DesignTokens.Colors.adsTextPrimary : .white)
                .frame(width: 36, height: 36)
                .background(
                    viewModel.currentArchetype == .ads ?
                        DesignTokens.Colors.adsTextSubtle.opacity(0.15) :
                        Color.white.opacity(0.15)
                )
                .cornerRadius(DesignTokens.Radius.button)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            viewModel.currentArchetype == .ads ?
                                DesignTokens.Colors.adsTextSubtle.opacity(DesignTokens.Opacity.overlayLight) :
                                Color.white.opacity(DesignTokens.Opacity.overlayLight),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var cartBadge: some View {
        Text("\(cartItemCount)")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(DesignTokens.Spacing.minimal)
            .background(
                Circle()
                    .fill(Color.red)
                    .shadow(color: Color.red.opacity(DesignTokens.Opacity.overlayStrong), radius: 4, x: 0, y: 2)
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
                    .foregroundColor(
                        viewModel.currentArchetype == .ads ?
                            DesignTokens.Colors.adsTextSecondary :
                            .white.opacity(DesignTokens.Opacity.textSubtle)
                    )
                    .tracking(0.5)

                Text("\(Int(progressPercentage * 100))%")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(
                        viewModel.currentArchetype == .ads ?
                            DesignTokens.Colors.adsTextPrimary :
                            .white.opacity(DesignTokens.Opacity.textSecondary)
                    )
            }
            .fixedSize()

            // Progress bar (expands to fill available space)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            viewModel.currentArchetype == .ads ?
                                DesignTokens.Colors.adsTextSubtle.opacity(DesignTokens.Opacity.overlayLight) :
                                Color.white.opacity(DesignTokens.Opacity.overlayLight)
                        )
                        .frame(height: 4)

                    // Filled progress with holographic gradient (changes for ads)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressBarGradient)
                        .frame(width: validProgressWidth(geometryWidth: geometry.size.width), height: 4)
                        .shadow(color: progressGlowColor.opacity(DesignTokens.Opacity.textDisabled), radius: 4, x: 0, y: 0)
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
                    Color.blue.opacity(DesignTokens.Opacity.textPrimary),
                    Color.purple.opacity(0.95),
                    Color.pink.opacity(DesignTokens.Opacity.textSecondary)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)
            .shadow(color: Color.cyan.opacity(DesignTokens.Opacity.textDisabled), radius: 6, x: 0, y: 0)

            // Strong glow effect
            LinearGradient(
                colors: [
                    Color.cyan.opacity(DesignTokens.Opacity.textSubtle),
                    Color.blue.opacity(DesignTokens.Opacity.textTertiary),
                    Color.purple.opacity(DesignTokens.Opacity.textSubtle),
                    Color.pink.opacity(DesignTokens.Opacity.textDisabled)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 8)
            .blur(radius: 6)
        }
    }

    // MARK: - Color Schemes Based on Archetype

    /// Base gradient background - changes for ads vs mail
    private var baseGradient: LinearGradient {
        if viewModel.currentArchetype == .ads {
            // Light white/green scheme for ads
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.85),
                    Color(red: 0.85, green: 0.95, blue: 0.88).opacity(0.95),  // Light green tint
                    Color(red: 0.80, green: 0.93, blue: 0.86).opacity(0.90),  // Slightly more green
                    Color.white.opacity(0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Dark purple scheme for mail (web demo gradient)
            return LinearGradient(
                colors: [
                    Color(red: 0x1a/255, green: 0x1a/255, blue: 0x2e/255),
                    Color(red: 0x2d/255, green: 0x1b/255, blue: 0x4e/255),
                    Color(red: 0x4a/255, green: 0x19/255, blue: 0x42/255),
                    Color(red: 0x1f/255, green: 0x1f/255, blue: 0x3a/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Highlight overlay for depth
    private var highlightOverlay: LinearGradient {
        if viewModel.currentArchetype == .ads {
            // Subtle highlights for light green theme
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.4),
                    Color.clear,
                    DesignTokens.Colors.adsGradientStart.opacity(0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            // Dark purple highlights for mail
            return LinearGradient(
                colors: [
                    Color.white.opacity(DesignTokens.Opacity.glassUltraLight),
                    Color.clear,
                    Color.black.opacity(DesignTokens.Opacity.glassLight)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    /// Progress bar gradient - changes for ads vs mail
    private var progressBarGradient: LinearGradient {
        if viewModel.currentArchetype == .ads {
            // Green gradient for ads
            return LinearGradient(
                colors: [
                    DesignTokens.Colors.adsGradientStart.opacity(DesignTokens.Opacity.textSecondary),
                    DesignTokens.Colors.adsGradientEnd.opacity(DesignTokens.Opacity.textPrimary),
                    DesignTokens.Colors.adsGradientStart.opacity(DesignTokens.Opacity.textSecondary),
                    DesignTokens.Colors.adsGradientEnd.opacity(DesignTokens.Opacity.textTertiary)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            // Purple/blue gradient for mail
            return LinearGradient(
                colors: [
                    Color.cyan.opacity(DesignTokens.Opacity.textSecondary),
                    Color.blue.opacity(DesignTokens.Opacity.textPrimary),
                    Color.purple.opacity(DesignTokens.Opacity.textSecondary),
                    Color.pink.opacity(DesignTokens.Opacity.textTertiary)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    /// Progress glow color
    private var progressGlowColor: Color {
        viewModel.currentArchetype == .ads ? DesignTokens.Colors.adsGradientEnd : Color.cyan
    }
}
