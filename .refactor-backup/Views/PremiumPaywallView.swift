//
//  PremiumPaywallView.swift
//  Zero
//
//  Created by Claude Code on 10/26/25.
//

import SwiftUI

/**
 * PremiumPaywallView - Beautiful subscription/upgrade screen
 *
 * Features:
 * - Showcases premium features with compelling visuals
 * - Pricing options (monthly/yearly with savings)
 * - Feature comparison list
 * - Glassmorphic design matching app aesthetic
 * - Haptic feedback for selections
 * - Analytics tracking for conversion funnel
 *
 * Design Philosophy:
 * - Show value first (features before price)
 * - Make free tier clear but less prominent
 * - Annual plan highlighted (better for LTV)
 * - Social proof / testimonials
 * - Easy to dismiss (builds trust)
 */
struct PremiumPaywallView: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme

    // Optional: specify which action triggered the paywall for analytics
    var triggeredBy: String?

    // Experiment variants
    @State private var ctaVariant: ExperimentVariant = .control
    @State private var messagingVariant: ExperimentVariant = .control
    @State private var pricingVariant: ExperimentVariant = .control

    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false

    // StoreKit integration
    @StateObject private var storeKit = StoreKitService.shared

    private let experimentService = ExperimentService.shared

    private var userId: String {
        UserPermissions.shared.getUserContext().userId ?? UUID().uuidString
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.8),
                        Color.blue.opacity(0.6),
                        Color.cyan.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: UUID())

                ScrollView {
                    VStack(spacing: 0) {
                        // Hero section
                        heroSection

                        // Feature list
                        featuresSection

                        // Pricing cards
                        pricingSection

                        // Social proof
                        socialProofSection

                        // FAQ teaser
                        faqSection

                        // Terms & Privacy
                        legalSection

                        Spacer(minLength: 100)
                    }
                }

                // Floating CTA button
                VStack {
                    Spacer()
                    ctaButton
                }

                // Success overlay
                if showSuccess {
                    successOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        logDismissal()
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Restore") {
                        restorePurchases()
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            assignExperiments()
            logImpression()
        }
        .task {
            // Load StoreKit products
            await storeKit.loadProducts()
        }
        .alert("Subscription Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: DesignTokens.Spacing.section) {
            // Premium icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow.opacity(0.3), .orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .padding(.top, 40)

            // Title
            VStack(spacing: DesignTokens.Spacing.inline) {
                Text(PaywallExperimentVariants.heroTitle(variant: messagingVariant))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Text(PaywallExperimentVariants.heroSubtitle(variant: messagingVariant))
                    .font(.title3)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
        }
        .padding(.bottom, 32)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
            Text("What's Included")
                .font(.title2.bold())
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .padding(.horizontal, DesignTokens.Spacing.card)

            VStack(spacing: DesignTokens.Spacing.component) {
                FeatureRow(
                    icon: "signature",
                    title: "Sign Forms Digitally",
                    description: "One-tap digital signature for permission forms and documents"
                )

                FeatureRow(
                    icon: "creditcard.fill",
                    title: "Pay Invoices",
                    description: "Quick payment interface for bills with Venmo/Zelle/Apple Pay"
                )

                FeatureRow(
                    icon: "shippingbox.fill",
                    title: "Track Packages",
                    description: "Real-time tracking with UPS, FedEx, USPS, and Amazon integration"
                )

                FeatureRow(
                    icon: "airplane",
                    title: "Flight Check-In",
                    description: "One-tap check-in with boarding pass added to Apple Wallet"
                )

                FeatureRow(
                    icon: "calendar.badge.plus",
                    title: "Schedule Purchases",
                    description: "Smart reminders for product launches and limited-edition sales"
                )

                FeatureRow(
                    icon: "doc.text.magnifyingglass",
                    title: "AI Newsletter Summaries",
                    description: "Claude AI-powered summaries of long newsletters"
                )

                FeatureRow(
                    icon: "envelope.badge.fill",
                    title: "One-Tap Unsubscribe",
                    description: "Instantly unsubscribe from any mailing list or newsletter"
                )
            }
            .padding(.horizontal, DesignTokens.Spacing.card)
        }
        .padding(.vertical, 24)
        .background(
            Color.white.opacity(0.08)
                .blur(radius: 20)
        )
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: DesignTokens.Spacing.section) {
            Text("Choose Your Plan")
                .font(.title2.bold())
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .padding(.top, 32)

            // Yearly Plan (Recommended)
            PricingCard(
                plan: .yearly,
                isSelected: selectedPlan == .yearly,
                onTap: {
                    selectPlan(.yearly)
                }
            )

            // Monthly Plan
            PricingCard(
                plan: .monthly,
                isSelected: selectedPlan == .monthly,
                onTap: {
                    selectPlan(.monthly)
                }
            )
        }
        .padding(.horizontal, DesignTokens.Spacing.card)
    }

    // MARK: - Social Proof

    private var socialProofSection: some View {
        VStack(spacing: DesignTokens.Spacing.section) {
            HStack(spacing: 4) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }

                Text("4.8")
                    .font(.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Text("(2.4K reviews)")
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.Colors.textSubtle)
            }

            Text(PaywallExperimentVariants.socialProofMessage(variant: messagingVariant))
                .font(.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Text("— Sarah M., Premium User")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 32)
    }

    // MARK: - FAQ Teaser

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
            Text("Frequently Asked Questions")
                .font(.headline)
                .foregroundColor(DesignTokens.Colors.textPrimary)

            FAQItem(
                question: "Can I cancel anytime?",
                answer: "Yes! Cancel anytime from your account settings with no penalties."
            )

            FAQItem(
                question: "What payment methods do you accept?",
                answer: "We accept all major credit cards, Apple Pay, and PayPal."
            )

            FAQItem(
                question: "Is there a free trial?",
                answer: "Yes! Get 7 days free when you subscribe to any plan."
            )
        }
        .padding(DesignTokens.Spacing.card)
        .background(
            Color.white.opacity(0.08)
                .cornerRadius(DesignTokens.Radius.container)
        )
        .padding(.horizontal, DesignTokens.Spacing.card)
        .padding(.vertical, DesignTokens.Spacing.section)
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: DesignTokens.Spacing.inline) {
            HStack(spacing: DesignTokens.Spacing.section) {
                Button("Terms of Service") {
                    openURL("https://zero.app/terms")
                }

                Text("•")
                    .foregroundColor(.white.opacity(0.4))

                Button("Privacy Policy") {
                    openURL("https://zero.app/privacy")
                }
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.6))

            Text("Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 24)
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Button {
            subscribe()
        } label: {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(PaywallExperimentVariants.ctaButtonText(variant: ctaVariant))
                        .font(.headline)
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    Image(systemName: "arrow.right")
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [.green, .green.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(DesignTokens.Radius.container)
            .shadow(color: .green.opacity(0.5), radius: 20, x: 0, y: 10)
        }
        .disabled(isProcessing)
        .padding(.horizontal, DesignTokens.Spacing.card)
        .padding(.bottom, 32)
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.card) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("Welcome to Premium!")
                    .font(.title.bold())
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Text("You now have access to all premium features")
                    .font(.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    showSuccess = false
                    isPresented = false
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.section)
                        .background(Color.green)
                        .cornerRadius(DesignTokens.Radius.button)
                }
                .padding(.horizontal, 40)
            }
            .padding(40)
        }
    }

    // MARK: - Actions

    private func selectPlan(_ plan: SubscriptionPlan) {
        selectedPlan = plan
        HapticService.shared.lightImpact()

        Logger.info("User selected plan: \(plan.rawValue)", category: .userPreferences)

        // Analytics - track plan selection
        AnalyticsService.shared.log(.planSelected, parameters: [
            "plan": plan.rawValue,
            "source": triggeredBy ?? "unknown"
        ])
    }

    private func subscribe() {
        guard !isProcessing else { return }

        isProcessing = true
        HapticService.shared.mediumImpact()

        Logger.info("User initiated subscription: \(selectedPlan.rawValue)", category: .userPreferences)

        // Analytics - track subscription attempt
        AnalyticsService.shared.log(.subscriptionInitiated, parameters: [
            "plan": selectedPlan.rawValue,
            "source": triggeredBy ?? "unknown",
            "price": selectedPlan.totalPrice
        ])

        Task {
            // Map SubscriptionPlan to StoreKit ProductID
            let productID: StoreKitService.ProductID = selectedPlan == .monthly ? .monthly : .yearly

            // Attempt purchase through StoreKit
            let result = await storeKit.purchase(productID)

            await MainActor.run {
                isProcessing = false

                switch result {
                case .success:
                    // Purchase successful!
                    showSuccess = true
                    HapticService.shared.success()

                    Logger.info("✅ Subscription successful: \(selectedPlan.rawValue)", category: .userPreferences)

                    // Analytics - track successful subscription
                    AnalyticsService.shared.log(.subscriptionCompleted, parameters: [
                        "plan": selectedPlan.rawValue,
                        "source": triggeredBy ?? "unknown",
                        "price": selectedPlan.totalPrice
                    ])

                    // Set user property for subscription status
                    AnalyticsService.shared.setUserProperty("premium", forName: .subscriptionStatus)
                    AnalyticsService.shared.setUserProperty(selectedPlan.rawValue, forName: .subscriptionPlan)

                    // Track experiment outcomes
                    experimentService.trackOutcome(experiment: .paywallCTA, outcome: .subscribed)
                    experimentService.trackOutcome(experiment: .paywallMessaging, outcome: .subscribed)
                    experimentService.trackOutcome(experiment: .paywallPricing, outcome: .subscribed, value: selectedPlan.rawValue)

                case .failure(let error):
                    // Purchase failed
                    Logger.error("Subscription failed: \(error.localizedDescription)", category: .userPreferences)

                    // Don't show error for user cancellation
                    if case .userCancelled = error {
                        Logger.info("User cancelled subscription", category: .userPreferences)

                        // Track experiment outcome for cancellation
                        experimentService.trackOutcome(experiment: .paywallCTA, outcome: .dismissed)
                        experimentService.trackOutcome(experiment: .paywallMessaging, outcome: .dismissed)
                        experimentService.trackOutcome(experiment: .paywallPricing, outcome: .dismissed)
                    } else {
                        // Show error for other failures
                        errorMessage = error.localizedDescription
                        showError = true
                        HapticService.shared.error()

                        // Analytics - track failed subscription
                        AnalyticsService.shared.log(.subscriptionFailed, parameters: [
                            "plan": selectedPlan.rawValue,
                            "source": triggeredBy ?? "unknown",
                            "error": error.localizedDescription
                        ])
                    }
                }
            }
        }
    }

    private func restorePurchases() {
        HapticService.shared.lightImpact()
        Logger.info("User tapped restore purchases", category: .userPreferences)

        // Analytics - track restore attempt
        AnalyticsService.shared.log(.restorePurchasesAttempted, parameters: [
            "source": triggeredBy ?? "unknown"
        ])

        Task {
            let result = await storeKit.restorePurchases()

            await MainActor.run {
                switch result {
                case .success(let count):
                    Logger.info("✅ Restored \(count) purchases", category: .userPreferences)
                    HapticService.shared.success()

                    // Show success message
                    errorMessage = "Successfully restored \(count) purchase(s)"
                    showError = true

                    // Analytics - restore succeeded
                    AnalyticsService.shared.log(.restorePurchasesSucceeded, parameters: [
                        "count": count
                    ])

                case .noPurchases:
                    Logger.info("No purchases to restore", category: .userPreferences)

                    // Show info message
                    errorMessage = "No previous purchases found"
                    showError = true

                    // Analytics - restore failed (no purchases found)
                    AnalyticsService.shared.log(.restorePurchasesFailed, parameters: [
                        "reason": "no_purchases_found"
                    ])

                case .failure:
                    Logger.error("Failed to restore purchases", category: .userPreferences)
                    HapticService.shared.error()

                    // Show error message
                    errorMessage = "Failed to restore purchases. Please try again."
                    showError = true

                    // Analytics - restore failed
                    AnalyticsService.shared.log(.restorePurchasesFailed, parameters: [
                        "reason": "restore_error"
                    ])
                }
            }
        }
    }

    private func logImpression() {
        Logger.info("Paywall displayed - triggered by: \(triggeredBy ?? "unknown")", category: .userPreferences)

        // Analytics - track paywall impression
        AnalyticsService.shared.log(.paywallViewed, parameters: [
            "source": triggeredBy ?? "unknown",
            "default_plan": selectedPlan.rawValue
        ])
    }

    private func logDismissal() {
        Logger.info("Paywall dismissed without purchase", category: .userPreferences)

        // Analytics - track paywall dismissal
        AnalyticsService.shared.log(.paywallDismissed, parameters: [
            "source": triggeredBy ?? "unknown",
            "selected_plan": selectedPlan.rawValue,
            "converted": "false"
        ])

        // Track experiment outcomes for dismissal
        experimentService.trackOutcome(experiment: .paywallCTA, outcome: .dismissed)
        experimentService.trackOutcome(experiment: .paywallMessaging, outcome: .dismissed)
        experimentService.trackOutcome(experiment: .paywallPricing, outcome: .dismissed)
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Experiment Methods

    private func assignExperiments() {
        // Assign CTA button variant
        ctaVariant = experimentService.getVariant(experiment: .paywallCTA, userId: userId)

        // Assign messaging variant
        messagingVariant = experimentService.getVariant(experiment: .paywallMessaging, userId: userId)

        // Assign pricing variant (affects default plan)
        pricingVariant = experimentService.getVariant(experiment: .paywallPricing, userId: userId)
        selectedPlan = PaywallExperimentVariants.defaultPlan(variant: pricingVariant)

        // Track exposure for all experiments
        experimentService.trackExposure(experiment: .paywallCTA, variant: ctaVariant, metadata: [
            "source": triggeredBy ?? "unknown"
        ])

        experimentService.trackExposure(experiment: .paywallMessaging, variant: messagingVariant, metadata: [
            "source": triggeredBy ?? "unknown"
        ])

        experimentService.trackExposure(experiment: .paywallPricing, variant: pricingVariant, metadata: [
            "source": triggeredBy ?? "unknown",
            "default_plan": selectedPlan.rawValue
        ])

        Logger.info("Experiments assigned - CTA: \(ctaVariant.rawValue), Messaging: \(messagingVariant.rawValue), Pricing: \(pricingVariant.rawValue)", category: .analytics)
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.section) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            Spacer()
        }
    }
}

// MARK: - Pricing Card Component

struct PricingCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignTokens.Spacing.section) {
                // Badge (for yearly)
                if plan == .yearly {
                    HStack {
                        Spacer()
                        Text("BEST VALUE")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .cornerRadius(20)
                    }
                    .offset(y: -8)
                }

                HStack {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                        Text(plan.title)
                            .font(.title3.bold())
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        Text(plan.subtitle)
                            .font(.subheadline)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(plan.price)
                            .font(.title.bold())
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        Text(plan.period)
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }
                }

                // Savings badge (for yearly)
                if plan == .yearly {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.green)
                        Text("Save 40% compared to monthly")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                        Spacer()
                    }
                    .padding(.horizontal, DesignTokens.Spacing.component)
                    .padding(.vertical, DesignTokens.Spacing.inline)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(DesignTokens.Spacing.inline)
                }
            }
            .padding(DesignTokens.Spacing.card)
            .background(
                isSelected ?
                    LinearGradient(
                        colors: [Color.white.opacity(0.25), Color.white.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    :
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .cornerRadius(DesignTokens.Spacing.card)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Spacing.card)
                    .strokeBorder(
                        isSelected ? Color.white.opacity(0.5) : Color.white.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: isSelected ? Color.white.opacity(0.3) : Color.clear, radius: 20, x: 0, y: 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - FAQ Item Component

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
            Button {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
                HapticService.shared.lightImpact()
            } label: {
                HStack {
                    Text(question)
                        .font(.subheadline.bold())
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            if isExpanded {
                Text(answer)
                    .font(.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, DesignTokens.Spacing.inline)
    }
}

// MARK: - Subscription Plan Enum

enum SubscriptionPlan: String {
    case monthly = "monthly"
    case yearly = "yearly"

    var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    var subtitle: String {
        switch self {
        case .monthly: return "Pay as you go"
        case .yearly: return "Best value"
        }
    }

    var price: String {
        switch self {
        case .monthly: return "$4.99"
        case .yearly: return "$2.99"
        }
    }

    var period: String {
        switch self {
        case .monthly: return "per month"
        case .yearly: return "per month"
        }
    }

    var totalPrice: String {
        switch self {
        case .monthly: return "$4.99/month"
        case .yearly: return "$35.88/year"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PremiumPaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumPaywallView(
            isPresented: .constant(true),
            triggeredBy: "sign_form"
        )
    }
}
#endif
