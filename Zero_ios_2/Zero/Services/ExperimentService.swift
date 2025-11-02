//
//  ExperimentService.swift
//  Zero
//
//  Created by Claude Code on 10/26/25.
//

import Foundation

/**
 * ExperimentService - A/B Testing Framework
 *
 * Purpose:
 * - Manage experiment variants and user assignments
 * - Consistent variant assignment (sticky sessions)
 * - Analytics integration for experiment tracking
 * - Support for multiple concurrent experiments
 *
 * Key Features:
 * - Deterministic user assignment (based on user ID)
 * - Persistent variant storage
 * - Experiment exposure tracking
 * - Outcome measurement
 * - Easy integration with analytics
 *
 * Example Usage:
 * ```swift
 * // Get assigned variant for an experiment
 * let variant = ExperimentService.shared.getVariant(
 *     experiment: .paywallCTA,
 *     userId: "user123"
 * )
 *
 * // Use variant in UI
 * switch variant {
 * case .control:
 *     buttonText = "Start Free Trial"
 * case .variantA:
 *     buttonText = "Try Premium Free"
 * case .variantB:
 *     buttonText = "Get Started Free"
 * }
 * ```
 */
class ExperimentService: ObservableObject {

    // MARK: - Singleton
    static let shared = ExperimentService()

    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let analytics = AnalyticsService.shared

    // MARK: - Keys
    private enum Keys {
        static let assignmentsPrefix = "experiment_assignment_"
        static let exposuresPrefix = "experiment_exposure_"
    }

    // MARK: - Initialization
    private init() {
        Logger.info("ExperimentService initialized", category: .analytics)
    }

    // MARK: - Public API

    /// Get the assigned variant for a user in an experiment
    /// Returns consistent variant for same user/experiment combination
    func getVariant(experiment: Experiment, userId: String) -> ExperimentVariant {
        // Check if user already has an assignment
        if let existingVariant = getStoredAssignment(experiment: experiment) {
            return existingVariant
        }

        // Assign new variant deterministically
        let variant = assignVariant(experiment: experiment, userId: userId)

        // Store assignment for consistency
        storeAssignment(experiment: experiment, variant: variant)

        Logger.info("Assigned variant \(variant.rawValue) for experiment \(experiment.rawValue)", category: .analytics)

        return variant
    }

    /// Track that user was exposed to an experiment variant
    /// Call this when the variant is actually shown to the user
    func trackExposure(experiment: Experiment, variant: ExperimentVariant, metadata: [String: Any] = [:]) {
        // Only track exposure once per experiment
        let exposureKey = Keys.exposuresPrefix + experiment.rawValue
        if userDefaults.bool(forKey: exposureKey) {
            return // Already tracked exposure for this experiment
        }

        // Mark as exposed
        userDefaults.set(true, forKey: exposureKey)

        // Track analytics event
        var parameters: [String: Any] = [
            "experiment_id": experiment.rawValue,
            "experiment_name": experiment.displayName,
            "variant": variant.rawValue
        ]

        // Merge additional metadata
        parameters.merge(metadata) { (_, new) in new }

        analytics.log("experiment_exposure", properties: parameters)

        Logger.info("Tracked exposure: \(experiment.rawValue) - \(variant.rawValue)", category: .analytics)
    }

    /// Track an outcome for an experiment (e.g., conversion, click, etc.)
    func trackOutcome(experiment: Experiment, outcome: ExperimentOutcome, value: Any? = nil) {
        // Get user's assigned variant
        guard let variant = getStoredAssignment(experiment: experiment) else {
            Logger.warning("Attempted to track outcome for unassigned experiment: \(experiment.rawValue)", category: .analytics)
            return
        }

        var parameters: [String: Any] = [
            "experiment_id": experiment.rawValue,
            "experiment_name": experiment.displayName,
            "variant": variant.rawValue,
            "outcome": outcome.rawValue
        ]

        if let value = value {
            parameters["value"] = value
        }

        analytics.log("experiment_outcome", properties: parameters)

        Logger.info("Tracked outcome: \(experiment.rawValue) - \(variant.rawValue) - \(outcome.rawValue)", category: .analytics)
    }

    /// Reset experiment assignment (for testing)
    func resetExperiment(_ experiment: Experiment) {
        let assignmentKey = Keys.assignmentsPrefix + experiment.rawValue
        let exposureKey = Keys.exposuresPrefix + experiment.rawValue
        userDefaults.removeObject(forKey: assignmentKey)
        userDefaults.removeObject(forKey: exposureKey)
        Logger.info("Reset experiment: \(experiment.rawValue)", category: .analytics)
    }

    /// Reset all experiments (for testing)
    func resetAllExperiments() {
        for experiment in Experiment.allCases {
            resetExperiment(experiment)
        }
        Logger.info("Reset all experiments", category: .analytics)
    }

    // MARK: - Private Methods

    /// Deterministically assign a variant based on user ID
    /// Uses hash-based assignment for consistent results
    private func assignVariant(experiment: Experiment, userId: String) -> ExperimentVariant {
        // Create deterministic seed from user ID + experiment ID
        let seed = "\(userId)_\(experiment.rawValue)"
        let hash = seed.hash

        // Get available variants and their weights
        let variants = experiment.variants
        let totalWeight = variants.reduce(0) { $0 + $1.weight }

        // Convert hash to 0-100 range
        let position = abs(hash % totalWeight)

        // Assign variant based on weighted distribution
        var cumulativeWeight = 0
        for (variant, weight) in variants {
            cumulativeWeight += weight
            if position < cumulativeWeight {
                return variant
            }
        }

        // Fallback to control (should never reach here)
        return .control
    }

    /// Get stored variant assignment for experiment
    private func getStoredAssignment(experiment: Experiment) -> ExperimentVariant? {
        let key = Keys.assignmentsPrefix + experiment.rawValue
        guard let variantString = userDefaults.string(forKey: key),
              let variant = ExperimentVariant(rawValue: variantString) else {
            return nil
        }
        return variant
    }

    /// Store variant assignment for experiment
    private func storeAssignment(experiment: Experiment, variant: ExperimentVariant) {
        let key = Keys.assignmentsPrefix + experiment.rawValue
        userDefaults.set(variant.rawValue, forKey: key)
    }
}

// MARK: - Experiment Definitions

/// Available experiments in the app
enum Experiment: String, CaseIterable {
    case paywallCTA = "paywall_cta"
    case paywallPricing = "paywall_pricing"
    case paywallMessaging = "paywall_messaging"

    var displayName: String {
        switch self {
        case .paywallCTA:
            return "Paywall CTA Button Text"
        case .paywallPricing:
            return "Paywall Pricing Display"
        case .paywallMessaging:
            return "Paywall Hero Messaging"
        }
    }

    /// Variant distribution (variant: weight)
    /// Weights should add up to 100 for even distribution
    var variants: [(ExperimentVariant, weight: Int)] {
        switch self {
        case .paywallCTA:
            return [
                (.control, weight: 50),    // "Start Free Trial"
                (.variantA, weight: 25),   // "Try Premium Free"
                (.variantB, weight: 25)    // "Get Started Free"
            ]

        case .paywallPricing:
            return [
                (.control, weight: 50),    // Yearly selected by default
                (.variantA, weight: 50)    // Monthly selected by default
            ]

        case .paywallMessaging:
            return [
                (.control, weight: 50),    // "Unlock all premium actions"
                (.variantA, weight: 50)    // "Get more done with premium"
            ]
        }
    }
}

// MARK: - Experiment Variants

/// Generic variant labels (can be reused across experiments)
enum ExperimentVariant: String, CaseIterable {
    case control = "control"
    case variantA = "variant_a"
    case variantB = "variant_b"
    case variantC = "variant_c"
}

// MARK: - Experiment Outcomes

/// Trackable outcomes for experiments
enum ExperimentOutcome: String {
    // Conversion funnel
    case viewed = "viewed"
    case clicked = "clicked"
    case subscribed = "subscribed"
    case dismissed = "dismissed"

    // Engagement
    case planSwitched = "plan_switched"
    case faqExpanded = "faq_expanded"
    case restoreAttempted = "restore_attempted"

    // Long-term
    case retained7Days = "retained_7_days"
    case retained30Days = "retained_30_days"
}

// MARK: - Paywall Experiment Variants

/// Specific variants for paywall experiments
struct PaywallExperimentVariants {

    // MARK: - CTA Button Text

    static func ctaButtonText(variant: ExperimentVariant) -> String {
        switch variant {
        case .control:
            return "Start Free Trial"
        case .variantA:
            return "Try Premium Free"
        case .variantB:
            return "Get Started Free"
        case .variantC:
            return "Unlock Premium"
        }
    }

    // MARK: - Hero Messaging

    static func heroTitle(variant: ExperimentVariant) -> String {
        switch variant {
        case .control:
            return "Upgrade to Premium"
        case .variantA:
            return "Get More Done"
        case .variantB:
            return "Unlock Your Potential"
        case .variantC:
            return "Premium Features Await"
        }
    }

    static func heroSubtitle(variant: ExperimentVariant) -> String {
        switch variant {
        case .control:
            return "Unlock all premium actions and features"
        case .variantA:
            return "Get more done with premium features"
        case .variantB:
            return "Access powerful tools to boost productivity"
        case .variantC:
            return "Everything you need to work smarter"
        }
    }

    // MARK: - Pricing Display

    static func defaultPlan(variant: ExperimentVariant) -> SubscriptionPlan {
        switch variant {
        case .control, .variantB, .variantC:
            return .yearly  // Control: yearly by default
        case .variantA:
            return .monthly // Variant A: monthly by default
        }
    }

    // MARK: - Social Proof

    static func socialProofMessage(variant: ExperimentVariant) -> String {
        switch variant {
        case .control:
            return "\"This app has completely changed how I handle my emails. The premium features are worth every penny!\""
        case .variantA:
            return "\"I'm saving 2+ hours per day with premium. Best investment I've made!\""
        case .variantB:
            return "\"The AI-powered features alone are worth the subscription. Highly recommend!\""
        case .variantC:
            return "\"Premium is a game-changer. I can't imagine going back to the free version.\""
        }
    }
}
