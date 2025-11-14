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

/// Skeleton loader for email cards
struct EmailCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Sender and time
            HStack {
                ShimmerBox(width: 120, height: 16)
                Spacer()
                ShimmerBox(width: 60, height: 14)
            }

            // Subject
            ShimmerBox(width: 200, height: 18)

            // Preview
            VStack(alignment: .leading, spacing: 6) {
                ShimmerBox(width: .infinity, height: 14)
                ShimmerBox(width: 250, height: 14)
            }

            // Tags
            HStack(spacing: DesignTokens.Spacing.inline) {
                ShimmerBox(width: 60, height: 24, cornerRadius: DesignTokens.Radius.button)
                ShimmerBox(width: 80, height: 24, cornerRadius: DesignTokens.Radius.button)
            }
        }
        .padding(DesignTokens.Spacing.section)
        .background(Color(.systemBackground))
        .cornerRadius(DesignTokens.Radius.button)
        .shadow(color: .black.opacity(DesignTokens.Opacity.glassUltraLight), radius: 4, y: 2)
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
