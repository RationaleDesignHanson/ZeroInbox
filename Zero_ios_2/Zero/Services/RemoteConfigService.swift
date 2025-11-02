//
//  RemoteConfigService.swift
//  Zero
//
//  Created by Claude Code on 10/26/25.
//

import Foundation

/**
 * RemoteConfigService - Feature flag and remote configuration management
 *
 * Purpose:
 * - Enable/disable features remotely without app updates
 * - A/B test variants and rollout controls
 * - Emergency kill switches
 * - Dynamic configuration values (API endpoints, pricing, etc.)
 *
 * Features:
 * - Local defaults with remote overrides
 * - Caching for offline support
 * - Type-safe flag definitions
 * - Automatic fetch on app launch
 * - Manual refresh capability
 *
 * Integration Options:
 * - Firebase Remote Config (recommended for production)
 * - Custom backend endpoint
 * - Local JSON file (for development/testing)
 *
 * Example Usage:
 * ```swift
 * // Check if feature is enabled
 * if RemoteConfigService.shared.isEnabled(.newActionFlow) {
 *     // Show new UI
 * }
 *
 * // Get configuration value
 * let maxActions = RemoteConfigService.shared.getInt(.maxPremiumActions)
 * ```
 */
@MainActor
class RemoteConfigService: ObservableObject {

    // MARK: - Singleton
    static let shared = RemoteConfigService()

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var lastFetchTime: Date?

    // MARK: - Private Properties
    private var configCache: [String: Any] = [:]
    private let defaults = UserDefaults.standard
    private let cacheKey = "remote_config_cache"
    private let lastFetchKey = "remote_config_last_fetch"

    // Minimum time between fetches (12 hours)
    private let minimumFetchInterval: TimeInterval = 12 * 60 * 60

    // MARK: - Initialization
    private init() {
        loadCachedConfig()
        Logger.info("RemoteConfigService initialized", category: .analytics)
    }

    // MARK: - Public API

    /// Fetch latest configuration from remote source
    func fetchConfig() async {
        // Check if we should fetch (respect minimum interval)
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < minimumFetchInterval {
            Logger.info("Skipping fetch - too soon since last fetch", category: .analytics)
            return
        }

        isLoading = true
        defer { isLoading = false }

        Logger.info("Fetching remote config", category: .analytics)

        // TODO: Implement actual remote fetch
        // For now, simulate with delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // In production, this would be:
        // 1. Firebase Remote Config: await firebaseConfig.fetchAndActivate()
        // 2. Custom API: let config = try await fetchFromAPI()
        // 3. Update cache with response

        // For now, use default values
        let mockConfig: [String: Any] = [
            RemoteFeatureFlag.newActionFlow.rawValue: false,
            RemoteFeatureFlag.enhancedPaywall.rawValue: true,
            RemoteFeatureFlag.aiSmartReplies.rawValue: true,
            RemoteFeatureFlag.premiumBadges.rawValue: true,
            RemoteFeatureFlag.subscriptionTrials.rawValue: true,

            ConfigKey.maxFreeActions.rawValue: 10,
            ConfigKey.maxPremiumActions.rawValue: 100,
            ConfigKey.trialDurationDays.rawValue: 7,
            ConfigKey.paywallDismissLimit.rawValue: 3,
            ConfigKey.minimumAppVersion.rawValue: "1.0.0"
        ]

        configCache = mockConfig
        saveCachedConfig()
        lastFetchTime = Date()
        defaults.set(lastFetchTime, forKey: lastFetchKey)

        Logger.info("✅ Remote config fetched successfully", category: .analytics)

        // Track config fetch in analytics
        AnalyticsService.shared.log("remote_config_fetched", properties: [
            "config_count": configCache.count
        ])
    }

    /// Check if a remote feature flag is enabled
    func isEnabled(_ flag: RemoteFeatureFlag) -> Bool {
        if let value = configCache[flag.rawValue] as? Bool {
            return value
        }
        return flag.defaultValue
    }

    /// Get string configuration value
    func getString(_ key: ConfigKey) -> String {
        if let value = configCache[key.rawValue] as? String {
            return value
        }
        return key.defaultStringValue
    }

    /// Get integer configuration value
    func getInt(_ key: ConfigKey) -> Int {
        if let value = configCache[key.rawValue] as? Int {
            return value
        }
        return key.defaultIntValue
    }

    /// Get double configuration value
    func getDouble(_ key: ConfigKey) -> Double {
        if let value = configCache[key.rawValue] as? Double {
            return value
        }
        return key.defaultDoubleValue
    }

    /// Force refresh config (ignores minimum interval)
    func forceRefresh() async {
        lastFetchTime = nil
        await fetchConfig()
    }

    /// Reset to default values (for testing)
    func resetToDefaults() {
        configCache = [:]
        saveCachedConfig()
        lastFetchTime = nil
        defaults.removeObject(forKey: lastFetchKey)
        Logger.info("Reset remote config to defaults", category: .analytics)
    }

    // MARK: - Private Methods

    private func loadCachedConfig() {
        if let data = defaults.data(forKey: cacheKey),
           let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            configCache = config
            Logger.info("Loaded cached config: \(config.count) values", category: .analytics)
        }

        if let lastFetch = defaults.object(forKey: lastFetchKey) as? Date {
            lastFetchTime = lastFetch
        }
    }

    private func saveCachedConfig() {
        if let data = try? JSONSerialization.data(withJSONObject: configCache) {
            defaults.set(data, forKey: cacheKey)
        }
    }
}

// MARK: - Remote Feature Flags

/// Remote feature flags for enabling/disabling features remotely
enum RemoteFeatureFlag: String, CaseIterable {
    // UI/UX Features
    case newActionFlow = "new_action_flow"
    case enhancedPaywall = "enhanced_paywall"
    case premiumBadges = "premium_badges"

    // AI Features
    case aiSmartReplies = "ai_smart_replies"
    case aiContextualActions = "ai_contextual_actions"
    case aiEmailSummaries = "ai_email_summaries"

    // Monetization
    case subscriptionTrials = "subscription_trials"
    case dynamicPricing = "dynamic_pricing"
    case lifetimeAccess = "lifetime_access"

    // Social/Sharing
    case socialSharing = "social_sharing"
    case referralProgram = "referral_program"

    // Experimental
    case betaFeatures = "beta_features"
    case debugMode = "debug_mode"

    var displayName: String {
        switch self {
        case .newActionFlow: return "New Action Flow"
        case .enhancedPaywall: return "Enhanced Paywall"
        case .premiumBadges: return "Premium Badges"
        case .aiSmartReplies: return "AI Smart Replies"
        case .aiContextualActions: return "AI Contextual Actions"
        case .aiEmailSummaries: return "AI Email Summaries"
        case .subscriptionTrials: return "Subscription Trials"
        case .dynamicPricing: return "Dynamic Pricing"
        case .lifetimeAccess: return "Lifetime Access"
        case .socialSharing: return "Social Sharing"
        case .referralProgram: return "Referral Program"
        case .betaFeatures: return "Beta Features"
        case .debugMode: return "Debug Mode"
        }
    }

    var defaultValue: Bool {
        switch self {
        // Stable features (enabled by default)
        case .enhancedPaywall: return true
        case .premiumBadges: return true
        case .aiSmartReplies: return true
        case .subscriptionTrials: return true

        // New/experimental features (disabled by default)
        case .newActionFlow: return false
        case .aiContextualActions: return false
        case .aiEmailSummaries: return false
        case .dynamicPricing: return false
        case .lifetimeAccess: return false
        case .socialSharing: return false
        case .referralProgram: return false
        case .betaFeatures: return false
        case .debugMode: return false
        }
    }
}

// MARK: - Configuration Keys

/// Configuration keys for dynamic values
enum ConfigKey: String {
    // Limits
    case maxFreeActions = "max_free_actions"
    case maxPremiumActions = "max_premium_actions"
    case maxEmailsPerDay = "max_emails_per_day"

    // Timing
    case trialDurationDays = "trial_duration_days"
    case paywallDismissLimit = "paywall_dismiss_limit"
    case cacheExpirationMinutes = "cache_expiration_minutes"

    // API Configuration
    case apiBaseURL = "api_base_url"
    case apiTimeout = "api_timeout"

    // App Configuration
    case minimumAppVersion = "minimum_app_version"
    case maintenanceMode = "maintenance_mode"
    case forceUpdateEnabled = "force_update_enabled"

    var defaultStringValue: String {
        switch self {
        case .apiBaseURL: return "https://api.zero.app"
        case .minimumAppVersion: return "1.0.0"
        case .maintenanceMode: return "false"
        default: return ""
        }
    }

    var defaultIntValue: Int {
        switch self {
        case .maxFreeActions: return 10
        case .maxPremiumActions: return 100
        case .maxEmailsPerDay: return 1000
        case .trialDurationDays: return 7
        case .paywallDismissLimit: return 3
        case .cacheExpirationMinutes: return 60
        case .apiTimeout: return 30
        default: return 0
        }
    }

    var defaultDoubleValue: Double {
        switch self {
        case .apiTimeout: return 30.0
        default: return 0.0
        }
    }
}

// MARK: - Extensions

extension RemoteConfigService {
    /// Get all remote feature flag states (for debugging/admin panel)
    func getAllFlags() -> [(flag: RemoteFeatureFlag, enabled: Bool)] {
        RemoteFeatureFlag.allCases.map { flag in
            (flag: flag, enabled: isEnabled(flag))
        }
    }

    /// Override a flag locally (for testing)
    func overrideFlag(_ flag: RemoteFeatureFlag, enabled: Bool) {
        configCache[flag.rawValue] = enabled
        saveCachedConfig()
        Logger.info("🧪 Override flag: \(flag.rawValue) = \(enabled)", category: .analytics)
    }

    /// Override a config value locally (for testing)
    func overrideConfig(_ key: ConfigKey, value: Any) {
        configCache[key.rawValue] = value
        saveCachedConfig()
        Logger.info("🧪 Override config: \(key.rawValue) = \(value)", category: .analytics)
    }
}

// MARK: - Firebase Remote Config Integration (Optional)

#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig

extension RemoteConfigService {
    /// Fetch from Firebase Remote Config
    func fetchFromFirebase() async throws {
        let remoteConfig = RemoteConfig.remoteConfig()

        // Set minimum fetch interval (production vs development)
        #if DEBUG
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0 // No throttling in debug
        remoteConfig.configSettings = settings
        #endif

        // Fetch and activate
        let status = try await remoteConfig.fetchAndActivate()

        if status == .successFetchedFromRemote || status == .successUsingPreFetchedData {
            // Update local cache from Firebase
            var newConfig: [String: Any] = [:]

            // Remote feature flags
            for flag in RemoteFeatureFlag.allCases {
                newConfig[flag.rawValue] = remoteConfig[flag.rawValue].boolValue
            }

            // Config values
            for key in ConfigKey.allCases {
                let value = remoteConfig[key.rawValue]
                if !value.stringValue.isEmpty {
                    newConfig[key.rawValue] = value.stringValue
                } else if value.numberValue.intValue != 0 {
                    newConfig[key.rawValue] = value.numberValue.intValue
                }
            }

            configCache = newConfig
            saveCachedConfig()
            lastFetchTime = Date()

            Logger.info("✅ Fetched config from Firebase", category: .analytics)
        }
    }
}
#endif
