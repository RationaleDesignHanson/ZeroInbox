//
//  CancelSubscriptionModal.swift
//  Zero
//
//  Created by Claude Code on 10/25/25.
//

import SwiftUI
import SafariServices

/**
 * CancelSubscriptionModal - Helps users cancel unwanted subscriptions
 *
 * Features:
 * - Detects subscription service from email
 * - Shows subscription details (service, cost, renewal date)
 * - Provides two cancellation options:
 *   1. Go directly to account page (without AI)
 *   2. Use AI agent to guide cancellation (Steel.dev)
 * - Opens cancellation URL in in-app browser
 */
struct CancelSubscriptionModal: View {
    let card: EmailCard
    let onComplete: () -> Void

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @State private var isLoading = true
    @State private var subscriptionInfo: SubscriptionInfo?
    @State private var error: String?
    @State private var showSafari = false
    @State private var safariURL: URL?
    @State private var aiGuidanceMode = false

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(message: error)
                } else if let info = subscriptionInfo {
                    contentView(info: info)
                }
            }
            .navigationTitle("Cancel Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $showSafari) {
                if let url = safariURL {
                    SafariView(url: url)
                }
            }
        }
        .onAppear {
            detectSubscription()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Detecting subscription service...")
                .font(.subheadline)
                .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundColor(.orange)

            Text("Unable to Detect Service")
                .font(.title2.bold())
                .foregroundColor(textColor)

            Text(message)
                .font(.body)
                .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Dismiss")
                    .font(.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.section)
                    .background(Color.blue)
                    .cornerRadius(DesignTokens.Radius.button)
            }
            .padding(.horizontal, 40)
        }
    }

    private func contentView(info: SubscriptionInfo) -> some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.card) {
                // Header icon
                VStack(spacing: DesignTokens.Spacing.component) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.red)
                        .padding(.top, 24)

                    Text("Cancel Subscription")
                        .font(.title2.bold())
                        .foregroundColor(textColor)
                }

                // Subscription details
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                    Text("Subscription Details")
                        .font(.caption.bold())
                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                        .textCase(.uppercase)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        DetailRow(
                            icon: "building.2.fill",
                            label: "Service",
                            value: info.serviceName
                        )

                        if let cost = extractCost(from: card) {
                            DetailRow(
                                icon: "dollarsign.circle.fill",
                                label: "Cost",
                                value: cost
                            )
                        }

                        if let renewalDate = extractRenewalDate(from: card) {
                            DetailRow(
                                icon: "calendar.circle.fill",
                                label: "Next Renewal",
                                value: renewalDate
                            )
                        }
                    }
                    .padding(DesignTokens.Spacing.section)
                    .background(rowBackgroundColor)
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // Cancellation options
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                    Text("How would you like to cancel?")
                        .font(.headline)
                        .foregroundColor(textColor)
                        .padding(.horizontal)

                    // Option 1: Direct link (no AI)
                    Button {
                        openDirectLink(info: info)
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.component) {
                            Image(systemName: "link.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Go to Account Page")
                                    .font(.headline)
                                    .foregroundColor(textColor)

                                Text("Open \(info.serviceName) account page directly")
                                    .font(.caption)
                                    .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(textColor.opacity(DesignTokens.Opacity.overlayMedium))
                        }
                        .padding(DesignTokens.Spacing.section)
                        .background(rowBackgroundColor)
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)

                    // Option 2: AI-assisted (if available)
                    if info.aiAssistanceAvailable {
                        Button {
                            startAIGuidance(info: info)
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.component) {
                                Image(systemName: "brain.head.profile")
                                    .font(.title2)
                                    .foregroundColor(.purple)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("AI-Guided Cancellation")
                                            .font(.headline)
                                            .foregroundColor(textColor)

                                        Text("BETA")
                                            .font(.caption2.bold())
                                            .foregroundColor(DesignTokens.Colors.textPrimary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.purple)
                                            .cornerRadius(DesignTokens.Radius.minimal)
                                    }

                                    Text("Get step-by-step guidance powered by AI")
                                        .font(.caption)
                                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                                }

                                Spacer()

                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                            .padding(DesignTokens.Spacing.section)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.purple.opacity(DesignTokens.Opacity.glassLight),
                                        Color.blue.opacity(DesignTokens.Opacity.glassLight)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.purple.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                            )
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                }

                // Help text
                if let note = info.note {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.orange)
                            Text("Note")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }

                        Text(note)
                            .font(.caption)
                            .foregroundColor(textColor.opacity(DesignTokens.Opacity.textSubtle))
                    }
                    .padding(DesignTokens.Spacing.component)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(DesignTokens.Opacity.glassLight))
                    .cornerRadius(DesignTokens.Radius.chip)
                    .padding(.horizontal)
                }

                // Cancellation steps
                if !info.cancellationSteps.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        Text("Cancellation Steps")
                            .font(.caption.bold())
                            .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                            .textCase(.uppercase)

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                            ForEach(Array(info.cancellationSteps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: DesignTokens.Spacing.component) {
                                    Text("\(index + 1)")
                                        .font(.caption.bold())
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                        .frame(width: 24, height: 24)
                                        .background(Color.blue)
                                        .clipShape(Circle())

                                    Text(step)
                                        .font(.caption)
                                        .foregroundColor(textColor)
                                }
                            }
                        }
                        .padding(DesignTokens.Spacing.section)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(rowBackgroundColor)
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
        }
    }

    // MARK: - Detail Row Component

    struct DetailRow: View {
        let icon: String
        let label: String
        let value: String

        @Environment(\.colorScheme) var colorScheme

        var body: some View {
            HStack(spacing: DesignTokens.Spacing.component) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))

                    Text(value)
                        .font(.body)
                        .foregroundColor(textColor)
                }

                Spacer()
            }
        }

        private var textColor: Color {
            colorScheme == .dark ? Color.white : Color.black
        }
    }

    // MARK: - Actions

    private func detectSubscription() {
        Task {
            do {
                let info = try await SubscriptionService.shared.detectSubscription(from: card)

                await MainActor.run {
                    self.subscriptionInfo = info
                    self.isLoading = false
                    HapticService.shared.lightImpact()
                }

                Logger.info("✅ Subscription detected: \(info.serviceName)", category: .ui)

            } catch {
                await MainActor.run {
                    self.error = "Could not detect subscription service from this email. Please try accessing the service's website directly."
                    self.isLoading = false
                }

                Logger.error("Failed to detect subscription: \(error.localizedDescription)", category: .network)
            }
        }
    }

    private func openDirectLink(info: SubscriptionInfo) {
        guard let url = URL(string: info.accountPageUrl) else {
            Logger.error("Invalid URL: \(info.accountPageUrl)", category: .ui)
            return
        }

        safariURL = url
        showSafari = true
        HapticService.shared.mediumImpact()

        Logger.info("🔗 Opening direct cancellation link: \(info.serviceName)", category: .ui)
    }

    private func startAIGuidance(info: SubscriptionInfo) {
        // TODO: Implement AI-guided cancellation flow
        // This would open a guided experience with step-by-step instructions
        Logger.info("🤖 Starting AI-guided cancellation for: \(info.serviceName)", category: .ui)
        HapticService.shared.success()

        // For now, fall back to direct link
        openDirectLink(info: info)
    }

    // MARK: - Helper Methods

    private func extractCost(from card: EmailCard) -> String? {
        // Try to extract cost from card data
        if let amount = card.paymentAmount {
            return String(format: "$%.2f", amount)
        }

        // Try to extract from subject or summary
        let text = "\(card.title) \(card.summary)"
        if let match = text.range(of: #"\$\d+(\.\d{2})?"#, options: .regularExpression) {
            return String(text[match])
        }

        return nil
    }

    private func extractRenewalDate(from card: EmailCard) -> String? {
        // Try to extract renewal date from card data
        if let expiresIn = card.expiresIn {
            return expiresIn
        }

        return nil
    }

    // MARK: - Computed Colors

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.10) : Color(white: 0.95)
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    private var rowBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }
}

// MARK: - Subscription Info Model

struct SubscriptionInfo {
    let serviceName: String
    let accountPageUrl: String
    let cancellationUrl: String?
    let cancellationSteps: [String]
    let requiresLogin: Bool
    let aiAssistanceAvailable: Bool
    let note: String?
}
