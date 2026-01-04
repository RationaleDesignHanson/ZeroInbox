//
//  EmptyStates.swift
//  Zero
//
//  Created by Claude Code on 10/26/25.
//

import SwiftUI

/**
 * EmptyStates - Reusable empty state UI components
 *
 * Provides consistent empty state displays across the app:
 * - No content screens
 * - Onboarding prompts
 * - Call-to-action views
 *
 * Usage:
 * ```swift
 * // Basic empty state
 * EmptyStateView(
 *     icon: "tray",
 *     title: "No Emails",
 *     message: "Your inbox is empty",
 *     action: ("Refresh", { await refresh() })
 * )
 *
 * // No internet
 * NoInternetView(retryAction: { await loadData() })
 *
 * // No search results
 * NoSearchResultsView(query: "package")
 * ```
 */

// MARK: - Generic Empty State

struct GenericEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let action: (title: String, action: () -> Void)?
    let style: EmptyStateStyle
    
    @State private var iconAnimation = false

    init(
        icon: String,
        title: String,
        message: String,
        action: (String, () -> Void)? = nil,
        style: EmptyStateStyle = .standard
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.style = style
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated icon with glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(style.accentColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                    .scaleEffect(iconAnimation ? 1.1 : 0.9)
                
                // Icon circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                style.accentColor.opacity(0.2),
                                style.accentColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

            // Icon
            Image(systemName: icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [style.accentColor, style.accentColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(iconAnimation ? 1.05 : 1.0)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    iconAnimation = true
                }
            }

            // Title
            Text(title)
                .font(DesignTokens.Typography.headingMedium)
                .foregroundColor(.white)

            // Message
            Text(message)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)

            // Action button
            if let action = action {
                Button(action: action.action) {
                    HStack(spacing: 8) {
                    Text(action.title)
                            .font(DesignTokens.Typography.actionPrimary)
                    }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [style.accentColor, style.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                        .cornerRadius(DesignTokens.Radius.button)
                    .shadow(color: style.accentColor.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.12, green: 0.1, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

enum EmptyStateStyle {
    case standard
    case success
    case warning
    case info
    
    var accentColor: Color {
        switch self {
        case .standard: return Color(red: 0.4, green: 0.5, blue: 0.9)
        case .success: return Color(red: 0.3, green: 0.8, blue: 0.5)
        case .warning: return Color(red: 0.95, green: 0.6, blue: 0.2)
        case .info: return Color(red: 0.3, green: 0.7, blue: 0.9)
        }
    }
}

// MARK: - No Emails (World-Class Inbox Zero)

struct NoEmailsView: View {
    let refreshAction: (() async -> Void)?

    @State private var isRefreshing = false
    @State private var celebrationScale: CGFloat = 0
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.12, green: 0.1, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 28) {
            Spacer()

                // Celebratory icon with animation
                ZStack {
                    // Outer glow rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.green.opacity(0.3 - Double(i) * 0.1),
                                        Color.cyan.opacity(0.2 - Double(i) * 0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: CGFloat(120 + i * 30), height: CGFloat(120 + i * 30))
                            .scaleEffect(celebrationScale)
                            .opacity(1 - Double(i) * 0.3)
                    }
                    
                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.8, blue: 0.6),
                                    Color(red: 0.1, green: 0.6, blue: 0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.green.opacity(0.4), radius: 20, y: 4)
                        .scaleEffect(celebrationScale)
                    
                    // Check icon
                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(celebrationScale)
                }

                // Title
                Text("Inbox Zero")
                    .font(DesignTokens.Typography.displayMedium)
                    .foregroundColor(.white)
                    .opacity(celebrationScale)

                // Subtitle
                Text("You're all caught up!")
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(celebrationScale)

                // Stats or suggestion
                HStack(spacing: 24) {
                    StatBadge(icon: "envelope.fill", value: "0", label: "Unread")
                    StatBadge(icon: "bolt.fill", value: "0", label: "Actions")
                }
                .opacity(celebrationScale)
                .padding(.top, 8)

            if let refreshAction = refreshAction {
                    Button {
                        Task {
                            isRefreshing = true
                            await refreshAction()
                            isRefreshing = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isRefreshing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Check for new emails")
                        }
                        .font(DesignTokens.Typography.actionSecondary)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                    .disabled(isRefreshing)
                    .opacity(celebrationScale)
                    .padding(.top, 16)
            }

            Spacer()
        }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                celebrationScale = 1.0
            }
            HapticService.shared.celebration()
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(value)
                    .font(DesignTokens.Typography.headingSmall)
            }
            .foregroundColor(.white)
            
            Text(label)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.08))
        .cornerRadius(DesignTokens.Radius.button)
    }
}

// MARK: - No Search Results

struct NoSearchResultsView: View {
    let query: String
    let clearAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("No Results Found")
                .font(.title3)
                .fontWeight(.semibold)

            Text("We couldn't find anything matching \"\(query)\"")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let clearAction = clearAction {
                Button("Clear Search") {
                    clearAction()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - No Internet

struct NoInternetView: View {
    let retryAction: (() async -> Void)?

    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("No Internet Connection")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Please check your internet connection and try again.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let retryAction = retryAction {
                LoadingButton(
                    title: "Retry",
                    isLoading: isRetrying,
                    action: {
                        Task {
                            isRetrying = true
                            await retryAction()
                            isRetrying = false
                        }
                    }
                )
                .padding(.horizontal, 48)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - No Actions Available

struct NoActionsView: View {
    var body: some View {
        GenericEmptyState(
            icon: "bolt.slash",
            title: "No Actions Available",
            message: "We couldn't detect any actions in this email. Try swiping on other emails to see available actions."
        )
    }
}

// MARK: - Connect Email Account

struct ConnectEmailView: View {
    let connectAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "envelope.circle")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            // Title
            Text("Connect Your Email")
                .font(.title)
                .fontWeight(.bold)

            // Message
            Text("Zero works with your existing email account. Connect it to start taking action on your emails.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Features
            VStack(alignment: .leading, spacing: 16) {
                OnboardingFeatureRow(
                    icon: "lock.shield",
                    title: "Privacy First",
                    description: "Your emails stay on your device"
                )

                OnboardingFeatureRow(
                    icon: "bolt.fill",
                    title: "Instant Actions",
                    description: "Track, pay, and sign with a swipe"
                )

                OnboardingFeatureRow(
                    icon: "sparkles",
                    title: "AI Powered",
                    description: "Smart replies and summaries"
                )
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)

            // Connect button
            Button(action: connectAction) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("Connect Email")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(DesignTokens.Radius.button)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Premium Required

struct PremiumRequiredView: View {
    let feature: String
    let upgradeAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "star.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.yellow)

            // Title
            Text("Premium Feature")
                .font(.title2)
                .fontWeight(.bold)

            // Message
            Text("\(feature) is a premium feature. Upgrade to Zero Premium to unlock unlimited access.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Benefits
            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(text: "Unlimited premium actions")
                BenefitRow(text: "AI-powered smart replies")
                BenefitRow(text: "Digital signature capture")
                BenefitRow(text: "Smart shopping features")
                BenefitRow(text: "Priority support")
            }
            .padding(.horizontal, 48)
            .padding(.top, 8)

            // Upgrade button
            Button(action: upgradeAction) {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Premium")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(DesignTokens.Radius.button)
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct BenefitRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)

            Text(text)
                .font(.subheadline)

            Spacer()
        }
    }
}

// MARK: - No Drafts

struct NoDraftsView: View {
    var body: some View {
        GenericEmptyState(
            icon: "doc.text",
            title: "No Drafts",
            message: "You don't have any draft emails saved."
        )
    }
}

// MARK: - No Notifications

struct NoNotificationsView: View {
    var body: some View {
        GenericEmptyState(
            icon: "bell.slash",
            title: "No Notifications",
            message: "You're all caught up! No new notifications at this time."
        )
    }
}

// MARK: - No Archived Emails

struct NoArchivedEmailsView: View {
    var body: some View {
        GenericEmptyState(
            icon: "archivebox",
            title: "No Archived Emails",
            message: "Emails you archive will appear here for easy access."
        )
    }
}

// MARK: - First Time User

struct FirstTimeUserView: View {
    let getStartedAction: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon or illustration
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)

            VStack(spacing: 16) {
                Text("Welcome to Zero")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Transform your inbox from a todo list into a done list")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Value props
            VStack(spacing: 20) {
                ValuePropRow(
                    icon: "shippingbox",
                    title: "Track Packages",
                    description: "Instantly track shipments with one tap"
                )

                ValuePropRow(
                    icon: "creditcard",
                    title: "Pay Bills",
                    description: "Quick access to payment links"
                )

                ValuePropRow(
                    icon: "signature",
                    title: "Sign Documents",
                    description: "Capture signatures digitally"
                )

                ValuePropRow(
                    icon: "sparkles",
                    title: "AI Smart Replies",
                    description: "Get intelligent response suggestions"
                )
            }
            .padding(.horizontal, 32)

            // Get started button
            Button(action: getStartedAction) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(DesignTokens.Radius.button)
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct ValuePropRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(DesignTokens.Opacity.glassLight))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Compact Empty State

struct CompactEmptyState: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.card)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct EmptyStates_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NoEmailsView(refreshAction: { })
                .previewDisplayName("No Emails")

            NoSearchResultsView(query: "package", clearAction: {})
                .previewDisplayName("No Search Results")

            NoInternetView(retryAction: { })
                .previewDisplayName("No Internet")

            NoActionsView()
                .previewDisplayName("No Actions")

            ConnectEmailView(connectAction: {})
                .previewDisplayName("Connect Email")

            PremiumRequiredView(feature: "Digital Signatures", upgradeAction: {})
                .previewDisplayName("Premium Required")

            FirstTimeUserView(getStartedAction: {})
                .previewDisplayName("First Time User")

            CompactEmptyState(icon: "tray", message: "No messages")
                .previewDisplayName("Compact")
        }
    }
}
#endif
