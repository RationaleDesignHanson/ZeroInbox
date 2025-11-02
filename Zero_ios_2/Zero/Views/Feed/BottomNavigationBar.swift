import SwiftUI

/// Bottom navigation bar with Combo C design: collapsible actions with swipe/tap/sheet
/// - Collapsed: Single row with archetype, count, centered progress, menu button
/// - Quick actions (swipe up): Inline action buttons above main row
/// - Sheet (tap menu): Labeled bottom sheet with all actions
struct BottomNavigationBar: View {
    @ObservedObject var viewModel: EmailViewModel
    @Binding var showSplayView: Bool
    @Binding var showArchetypeSheet: Bool
    @Binding var showShoppingCart: Bool
    @Binding var showSettings: Bool
    @Binding var showSearch: Bool
    @Binding var showSavedMail: Bool
    let cartItemCount: Int
    let onRefresh: (() async -> Void)?

    @EnvironmentObject var navState: NavigationState

    // Animation states for progress bar
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var glowPulse: Double = 0.3
    @State private var colorRotation: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Quick Actions Row (conditionally shown via swipe or tap)
            if navState.actionsExpanded {
                HStack(spacing: 20) {
                    actionButton(icon: "gearshape.fill", label: "Settings", color: .cyan) {
                        showSettings = true
                        navState.collapseActions()
                        HapticService.shared.lightImpact()
                    }

                    actionButton(icon: "rectangle.grid.1x2", label: "Stacks", color: .blue) {
                        showSplayView = true
                        navState.collapseActions()
                        HapticService.shared.lightImpact()
                    }

                    actionButton(icon: "magnifyingglass", label: "Search", color: .purple) {
                        showSearch = true
                        navState.collapseActions()
                        HapticService.shared.lightImpact()
                    }

                    actionButton(icon: "folder.fill", label: "Saved", color: .pink) {
                        showSavedMail = true
                        navState.collapseActions()
                        HapticService.shared.lightImpact()
                    }

                    actionButton(icon: "arrow.clockwise", label: "Refresh", color: .green) {
                        Task {
                            await onRefresh?()
                        }
                        navState.collapseActions()
                        HapticService.shared.mediumImpact()
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(DesignTokens.Radius.card, corners: [.topLeft, .topRight])
                .overlay(
                    // Holographic top border
                    VStack {
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.4),
                                Color.purple.opacity(0.4),
                                Color.pink.opacity(0.4)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 1.5)
                        Spacer()
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Main Info Row
            HStack(spacing: 0) {
                // LEFT: Archetype + Count - refined typography
                HStack(spacing: 10) {
                    Button {
                        viewModel.switchToNextArchetype()
                        HapticService.shared.mediumImpact()
                        Logger.logUserAction("Archetype toggled", details: ["to": viewModel.currentArchetype.displayName])
                    } label: {
                        HStack(spacing: 6) {
                            Text(viewModel.currentArchetype.displayName)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)

                            // Subtle chevron indicator
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                                )
                        )
                    }

                    // Elegant separator
                    Text("·")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))

                    Text("\(viewModel.filteredCards.count) left")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // CENTER: Progress Bar - animated holographic effect
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 90, height: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                        )

                    // Holographic progress fill with color cycling
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan,
                                    Color.blue,
                                    Color.purple,
                                    Color.pink,
                                    Color.cyan
                                ]),
                                center: .center,
                                angle: .degrees(colorRotation)
                            )
                        )
                        .frame(width: 90 * progressPercent, height: 6)
                        .mask(
                            RoundedRectangle(cornerRadius: 3)
                                .frame(width: 90 * progressPercent, height: 6)
                        )
                        .overlay(
                            // Animated shimmer sweep
                            GeometryReader { geometry in
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.0),
                                        Color.white.opacity(0.7),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: geometry.size.width * 0.3)
                                .offset(x: geometry.size.width * shimmerOffset)
                                .opacity(progressPercent > 0 ? 1 : 0)
                            }
                            .mask(
                                RoundedRectangle(cornerRadius: 3)
                                    .frame(width: 90 * progressPercent, height: 6)
                            )
                        )
                        .shadow(color: currentGlowColor.opacity(glowPulse), radius: 6, x: 0, y: 0)
                        .animation(.easeInOut(duration: 0.5), value: progressPercent)
                }
                .frame(width: 90)
                .onAppear {
                    startProgressAnimations()
                }

                Spacer()

                // RIGHT: Menu Button - more refined
                Button {
                    navState.toggleActions()
                    HapticService.shared.lightImpact()
                } label: {
                    ZStack {
                        // Subtle background
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 36, height: 36)

                        // Icon with holographic hint
                        Image(systemName: navState.actionsExpanded ? "xmark" : "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .rotationEffect(.degrees(navState.actionsExpanded ? 90 : 0))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: navState.actionsExpanded)
                    }
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            navState.showSheet()
                            HapticService.shared.mediumImpact()
                        }
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    // Base glass effect - more transparent and blurred
                    RoundedRectangle(cornerRadius: navState.actionsExpanded ? 0 : DesignTokens.Radius.card)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(
                            .ultraThinMaterial.opacity(0.6),
                            in: RoundedRectangle(cornerRadius: navState.actionsExpanded ? 0 : DesignTokens.Radius.card)
                        )

                    // Holographic rim lighting - iridescent effect
                    RoundedRectangle(cornerRadius: navState.actionsExpanded ? 0 : DesignTokens.Radius.card)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.6),
                                    Color.cyan.opacity(0.4),
                                    Color.purple.opacity(0.5),
                                    Color.pink.opacity(0.3),
                                    Color.blue.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )

                    // Inner glow for depth
                    RoundedRectangle(cornerRadius: navState.actionsExpanded ? 0 : DesignTokens.Radius.card)
                        .strokeBorder(
                            Color.white.opacity(0.15),
                            lineWidth: 0.5
                        )
                        .blur(radius: 2)
                }
            )
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -5)  // Premium floating shadow
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { gesture in
                        if gesture.translation.height < -30 && !navState.actionsExpanded {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                navState.actionsExpanded = true
                            }
                            HapticService.shared.mediumImpact()
                        } else if gesture.translation.height > 30 && navState.actionsExpanded {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                navState.actionsExpanded = false
                            }
                            HapticService.shared.lightImpact()
                        }
                    }
            )
        }
        .padding(.horizontal, DesignTokens.Spacing.card)
        .padding(.bottom, 32)  // Reduced for cleaner look
        .sheet(isPresented: $navState.sheetPresented) {
            ActionsBottomSheet(
                showSettings: $showSettings,
                showSplayView: $showSplayView,
                showSearch: $showSearch,
                showSavedMail: $showSavedMail,
                onRefresh: onRefresh
            )
            .onDisappear {
                navState.dismissSheet()
            }
        }
    }

    // MARK: - Action Button

    @ViewBuilder
    private func actionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .blur(radius: 8)

                    // Icon
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Computed Properties

    /// Calculate progress percentage for current archetype
    private var progressPercent: Double {
        let totalCards = viewModel.cards.filter { $0.type == viewModel.currentArchetype }.count
        let remaining = viewModel.filteredCards.count
        guard totalCards > 0 else { return 0 }
        return max(0, 1.0 - (Double(remaining) / Double(totalCards)))
    }

    /// Current glow color based on rotation cycle
    private var currentGlowColor: Color {
        let colors: [Color] = [.cyan, .blue, .purple, .pink]
        let index = Int(colorRotation / 90) % colors.count
        return colors[index]
    }

    // MARK: - Animation Functions

    /// Start continuous animations for progress bar
    private func startProgressAnimations() {
        // Shimmer sweep animation - continuous left to right
        withAnimation(
            Animation.linear(duration: 2.0)
                .repeatForever(autoreverses: false)
        ) {
            shimmerOffset = 1.3  // Move past the end
        }

        // Color rotation - slow continuous cycle
        withAnimation(
            Animation.linear(duration: 8.0)
                .repeatForever(autoreverses: false)
        ) {
            colorRotation = 360
        }

        // Glow pulse - breathing effect
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            glowPulse = 0.7
        }
    }
}

// RoundedCorner extension already defined in SaveSnoozeMenuView.swift

// MARK: - Preview
#if DEBUG
struct BottomNavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            BottomNavigationBar(
                viewModel: EmailViewModel(
                    userPreferences: UserPreferencesService(),
                    appState: AppStateManager(),
                    cardManagement: CardManagementService()
                ),
                showSplayView: .constant(false),
                showArchetypeSheet: .constant(false),
                showShoppingCart: .constant(false),
                showSettings: .constant(false),
                showSearch: .constant(false),
                showSavedMail: .constant(false),
                cartItemCount: 3,
                onRefresh: {
                    print("Refresh triggered from preview")
                }
            )
            .environmentObject(NavigationState())
        }
    }
}
#endif
