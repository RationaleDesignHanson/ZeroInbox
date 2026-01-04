//
//  LoadingStates.swift
//  Zero
//
//  Created by Claude Code on 10/26/25.
//

import SwiftUI

/**
 * LoadingStates - Reusable loading indicators and skeletons
 *
 * Provides consistent loading UI across the app:
 * - Spinners
 * - Skeleton loaders
 * - Progress indicators
 * - Inline loading states
 *
 * Usage:
 * ```swift
 * // Simple spinner
 * LoadingSpinner(text: "Loading emails...")
 *
 * // Skeleton card
 * EmailCardSkeleton()
 *
 * // Inline loading
 * InlineLoader(isLoading: $isLoading) {
 *     Text("Content")
 * }
 * ```
 */

// MARK: - Loading Spinner

struct LoadingSpinner: View {
    let text: String?
    let size: LoadingSize

    init(text: String? = nil, size: LoadingSize = .medium) {
        self.text = text
        self.size = size
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.section) {
            ProgressView()
                .scaleEffect(size.scale)
                .progressViewStyle(CircularProgressViewStyle())

            if let text = text {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Skeleton Loaders

/// World-class skeleton loader for email cards - matches actual card layout
struct EmailCardSkeleton: View {
    let cardType: CardType
    @State private var isAnimating = false

    init(cardType: CardType = .mail) {
        self.cardType = cardType
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
            // Header - Avatar, name, time
            HStack(alignment: .top, spacing: DesignTokens.Spacing.component) {
                // View button skeleton
                ShimmerBoxDark(width: 56, height: 56, cornerRadius: DesignTokens.Radius.button)
                
                // Name and time
                VStack(alignment: .leading, spacing: 6) {
                    ShimmerBoxDark(width: 140, height: 18)
                    ShimmerBoxDark(width: 80, height: 14)
                }
                
                Spacer()
                
                // Priority badge skeleton
                ShimmerBoxDark(width: 60, height: 24, cornerRadius: DesignTokens.Radius.minimal)
            }

            // Title
            ShimmerBoxDark(width: nil, height: 22)
            
            // AI Preview section
            VStack(alignment: .leading, spacing: 10) {
                // Section header
                ShimmerBoxDark(width: 80, height: 13)
                // Summary lines
                ShimmerBoxDark(width: nil, height: 16)
                ShimmerBoxDark(width: 260, height: 16)
                ShimmerBoxDark(width: 200, height: 16)
            }
            .padding(DesignTokens.Spacing.element)
            .background(Color.white.opacity(0.06))
            .cornerRadius(DesignTokens.Radius.button)

            // Action button skeleton
            ShimmerBoxDark(width: nil, height: 48, cornerRadius: 12)
        }
        .padding(DesignTokens.Spacing.section)
        .padding(.top, 4)
        .padding(.bottom, DesignTokens.Spacing.section)
        .frame(width: UIScreen.main.bounds.width - 48)
        .background(
            ZStack {
                // Dark gradient base matching card backgrounds
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.08, blue: 0.18),
                        Color(red: 0.15, green: 0.1, blue: 0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Ultra-thin material overlay
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.3)
            }
        )
        .cornerRadius(DesignTokens.Radius.card)
        .shadow(color: .black.opacity(DesignTokens.Opacity.overlayMedium), radius: 20)
    }
}

/// Skeleton for email reader view
struct EmailReaderSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header section
            HStack(spacing: 14) {
                ShimmerBoxDark(width: 52, height: 52, cornerRadius: 26)
                
                VStack(alignment: .leading, spacing: 6) {
                    ShimmerBoxDark(width: 160, height: 18)
                    ShimmerBoxDark(width: 100, height: 14)
            }
            }
            .padding(DesignTokens.Spacing.component)
            .background(glassBackground)
            .cornerRadius(DesignTokens.Radius.card)

            // Subject
            ShimmerBoxDark(width: nil, height: 28)
                .padding(DesignTokens.Spacing.component)
                .background(glassBackground)
                .cornerRadius(DesignTokens.Radius.button)
            
            // Body content
            VStack(alignment: .leading, spacing: 10) {
                ShimmerBoxDark(width: nil, height: 16)
                ShimmerBoxDark(width: nil, height: 16)
                ShimmerBoxDark(width: 280, height: 16)
                ShimmerBoxDark(width: nil, height: 16)
                ShimmerBoxDark(width: 220, height: 16)
            }
            .padding(DesignTokens.Spacing.component)
            .background(glassBackground)
            .cornerRadius(DesignTokens.Radius.button)

            // Actions
            HStack(spacing: 12) {
                ShimmerBoxDark(width: nil, height: 50, cornerRadius: DesignTokens.Radius.button)
            }
            .padding(DesignTokens.Spacing.component)
            .background(glassBackground)
            .cornerRadius(DesignTokens.Radius.card)
        }
        .padding(.horizontal, 16)
    }
    
    private var glassBackground: some View {
        ZStack {
            Color.white.opacity(0.06)
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        }
    }
}

/// Skeleton for inbox list items
struct InboxItemSkeleton: View {
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.element) {
            // Avatar
            ShimmerBoxDark(width: 48, height: 48, cornerRadius: 24)
            
            VStack(alignment: .leading, spacing: 6) {
                // Sender
                ShimmerBoxDark(width: 140, height: 16)
                // Subject
                ShimmerBoxDark(width: 200, height: 14)
                // Preview
                ShimmerBoxDark(width: 160, height: 12)
            }

            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                ShimmerBoxDark(width: 50, height: 12)
                ShimmerBoxDark(width: 20, height: 20, cornerRadius: 10)
            }
        }
        .padding(DesignTokens.Spacing.element)
        .background(Color.white.opacity(0.04))
        .cornerRadius(DesignTokens.Radius.button)
    }
}

/// Skeleton loader for action buttons
struct ActionButtonSkeleton: View {
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.component) {
            ShimmerBox(width: 40, height: 40, cornerRadius: DesignTokens.Spacing.inline)

            VStack(alignment: .leading, spacing: 4) {
                ShimmerBox(width: 100, height: 16)
                ShimmerBox(width: 150, height: 12)
            }

            Spacer()

            ShimmerBox(width: 24, height: 24, cornerRadius: DesignTokens.Radius.button)
        }
        .padding(DesignTokens.Spacing.section)
        .background(Color(.systemGray6))
        .cornerRadius(DesignTokens.Radius.button)
    }
}

/// Skeleton loader for list items
struct ListItemSkeleton: View {
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.component) {
            ShimmerBox(width: 44, height: 44, cornerRadius: 22)

            VStack(alignment: .leading, spacing: 6) {
                ShimmerBox(width: 150, height: 16)
                ShimmerBox(width: 200, height: 14)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, DesignTokens.Spacing.inline)
    }
}

// MARK: - Shimmer Box

struct ShimmerBox: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    @State private var isAnimating = false

    init(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = DesignTokens.Spacing.inline) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(DesignTokens.Opacity.overlayMedium),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 300 : -300)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .cornerRadius(cornerRadius)
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Shimmer Box Dark (for dark mode / card backgrounds)

/// Premium shimmer effect optimized for dark backgrounds
struct ShimmerBoxDark: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    @State private var shimmerOffset: CGFloat = -1.0

    init(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = 6) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.15),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: shimmerOffset * geometry.size.width)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .frame(width: width, height: height)
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.8)
                    .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 1.5
            }
        }
    }
}

// MARK: - Skeleton Card Stack

/// Shows a stack of skeleton cards for loading state
struct SkeletonCardStack: View {
    let count: Int
    
    init(count: Int = 3) {
        self.count = count
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<min(count, 3), id: \.self) { index in
                EmailCardSkeleton()
                    .scaleEffect(1.0 - CGFloat(index) * 0.03)
                    .offset(y: CGFloat(index) * 8)
                    .opacity(1.0 - Double(index) * 0.15)
            }
            }
    }
}

// MARK: - Inline Loader

/// Shows loading spinner inline with content
struct InlineLoader<Content: View>: View {
    @Binding var isLoading: Bool
    let content: () -> Content
    let loadingText: String?

    init(
        isLoading: Binding<Bool>,
        loadingText: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isLoading = isLoading
        self.loadingText = loadingText
        self.content = content
    }

    var body: some View {
        if isLoading {
            LoadingSpinner(text: loadingText, size: .small)
        } else {
            content()
        }
    }
}

// MARK: - Pull to Refresh Loader

struct PullToRefreshLoader: View {
    let isRefreshing: Bool

    var body: some View {
        HStack(spacing: 12) {
            if isRefreshing {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Refreshing...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .opacity(isRefreshing ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: isRefreshing)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let text: String?

    func body(content: Content) -> some View {
        ZStack {
            content

            if isLoading {
                Color.black.opacity(DesignTokens.Opacity.overlayMedium)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))

                    if let text = text {
                        Text(text)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
                .padding(DesignTokens.Spacing.card)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                        .fill(Color(.systemGray))
                        .shadow(radius: 10)
                )
            }
        }
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, text: String? = nil) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading, text: text))
    }
}

// MARK: - Loading Button

struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }

                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignTokens.Spacing.section)
            .background(isLoading ? Color.gray : Color.blue)
            .foregroundColor(DesignTokens.Colors.textPrimary)
            .cornerRadius(DesignTokens.Radius.button)
        }
        .disabled(isLoading)
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let progress: Double // 0.0 to 1.0
    let color: Color

    init(progress: Double, color: Color = .blue) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: DesignTokens.Spacing.inline)
                    .cornerRadius(DesignTokens.Radius.minimal)

                // Progress
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * progress, height: DesignTokens.Spacing.inline)
                    .cornerRadius(DesignTokens.Radius.minimal)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: DesignTokens.Spacing.inline)
    }
}

// MARK: - Determinate Progress

struct DeterminateProgress: View {
    let current: Int
    let total: Int
    let label: String

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(current) / \(total)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressBar(progress: progress)
        }
    }
}

// MARK: - Supporting Types

enum LoadingSize {
    case small
    case medium
    case large

    var scale: CGFloat {
        switch self {
        case .small: return 0.8
        case .medium: return 1.0
        case .large: return 1.5
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct LoadingStates_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                Group {
                    Text("Loading Spinners")
                        .font(.headline)

                    LoadingSpinner(text: "Loading emails...", size: .small)
                        .frame(height: 100)

                    LoadingSpinner(text: "Processing...", size: .medium)
                        .frame(height: 100)

                    LoadingSpinner(text: "Please wait...", size: .large)
                        .frame(height: 120)
                }

                Divider()

                Group {
                    Text("Skeleton Loaders")
                        .font(.headline)

                    EmailCardSkeleton()

                    ActionButtonSkeleton()

                    ListItemSkeleton()
                }

                Divider()

                Group {
                    Text("Progress Indicators")
                        .font(.headline)

                    ProgressBar(progress: 0.3)
                        .padding(.horizontal)

                    ProgressBar(progress: 0.7, color: .green)
                        .padding(.horizontal)

                    DeterminateProgress(current: 7, total: 10, label: "Loading emails")
                        .padding(.horizontal)
                }

                Divider()

                Group {
                    Text("Loading Button")
                        .font(.headline)

                    LoadingButton(title: "Submit", isLoading: true, action: {})
                        .padding(.horizontal)

                    LoadingButton(title: "Submit", isLoading: false, action: {})
                        .padding(.horizontal)
                }
            }
            .padding()
        }
    }
}
#endif
