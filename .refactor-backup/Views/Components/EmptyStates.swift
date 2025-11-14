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

    init(
        icon: String,
        title: String,
        message: String,
        action: (String, () -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Action button
            if let action = action {
                Button(action: action.action) {
                    Text(action.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - No Emails

struct NoEmailsView: View {
    let refreshAction: (() async -> Void)?

    @State private var isRefreshing = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Emails")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your inbox is empty. Check back later or connect your email account.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let refreshAction = refreshAction {
                LoadingButton(
                    title: "Refresh",
                    isLoading: isRefreshing,
                    action: {
                        Task {
                            isRefreshing = true
                            await refreshAction()
                            isRefreshing = false
                        }
                    }
                )
                .padding(.horizontal, 48)
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
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
                .cornerRadius(12)
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
                .cornerRadius(12)
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
                    .cornerRadius(12)
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
                    .fill(Color.blue.opacity(0.1))
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
        .padding(32)
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
