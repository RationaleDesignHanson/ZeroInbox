import Foundation

/// Typed analytics user properties to prevent string typos and drift
/// Use these enum cases instead of raw strings for type safety
enum AnalyticsUserProperty: String {
    case dataMode = "data_mode"
    case selectedArchetypes = "selected_archetypes"

    // MARK: - Monetization User Properties
    case subscriptionStatus = "subscription_status"  // "free", "premium", "beta", "admin"
    case subscriptionPlan = "subscription_plan"      // "monthly", "yearly"
    case subscriptionStartDate = "subscription_start_date"
    case lifetimeValue = "lifetime_value"
    case trialsStarted = "trials_started"
}

/// Typed analytics events to ensure consistency across the app
enum AnalyticsEvent: String {
    // MARK: - App Lifecycle
    case appSessionStart = "app_session_start"
    case appLaunched = "app_launched"
    case appSessionEnd = "app_session_end"
    case appEnteredForeground = "app_entered_foreground"
    case appEnteredBackground = "app_entered_background"
    case memoryWarning = "memory_warning"

    // MARK: - User Actions
    case cardSwiped = "card_swiped"
    case actionExecuted = "action_executed"
    case onboardingCompleted = "onboarding_completed"

    // MARK: - Monetization Events
    case paywallViewed = "paywall_viewed"
    case paywallDismissed = "paywall_dismissed"
    case planSelected = "plan_selected"
    case subscriptionInitiated = "subscription_initiated"
    case subscriptionCompleted = "subscription_completed"
    case subscriptionFailed = "subscription_failed"
    case subscriptionCancelled = "subscription_cancelled"
    case restorePurchasesAttempted = "restore_purchases_attempted"
    case restorePurchasesSucceeded = "restore_purchases_succeeded"
    case restorePurchasesFailed = "restore_purchases_failed"
    case trialStarted = "trial_started"
    case trialConverted = "trial_converted"
    case trialExpired = "trial_expired"

    // MARK: - Premium Feature Access
    case premiumActionAttempted = "premium_action_attempted"
    case premiumActionBlocked = "premium_action_blocked"
    case premiumFeatureUsed = "premium_feature_used"
}

/// Protocol defining analytics capabilities
/// Abstraction allows for easy testing with mock implementations
protocol Analytics {
    /// Data mode: "mock" or "real" - used to separate analytics signals
    var dataMode: String { get set }

    /// Track app session start
    func trackSessionStart()

    /// Set a user property with typed key
    /// - Parameters:
    ///   - value: Property value
    ///   - property: Typed property key
    func setUserProperty(_ value: String, forName property: AnalyticsUserProperty)

    /// Log a typed event
    /// - Parameter event: Analytics event to log
    func log(_ event: AnalyticsEvent)

    /// Log a custom event (for legacy/dynamic events)
    /// - Parameter name: Event name string
    func logCustom(_ name: String)

    /// Log an event with additional parameters
    /// - Parameters:
    ///   - event: Analytics event to log
    ///   - parameters: Additional event parameters
    func log(_ event: AnalyticsEvent, parameters: [String: Any])
}

/// Extension to maintain backward compatibility with string-based logging
extension Analytics {
    func log(_ name: String) {
        logCustom(name)
    }
}
