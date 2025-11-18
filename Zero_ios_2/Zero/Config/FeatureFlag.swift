//
//  FeatureFlag.swift
//  Zero
//
//  Created by Claude Code on 10/26/25.
//

import Foundation

/**
 * FeatureFlag - Type-safe feature toggle system
 *
 * Benefits:
 * - Roll out features gradually without app updates
 * - Kill-switch for problematic features
 * - A/B test new experiences
 * - Environment-specific features (debug overlays)
 *
 * Usage:
 * if services.featureGating.isEnabled(.newComposer) {
 *     // Show new composer
 * } else {
 *     // Show legacy composer
 * }
 */

enum FeatureFlag: String, CaseIterable {
    // MARK: - UI Features

    /// New email composer with rich formatting
    case newComposer = "new_composer"

    /// Fast swipe gestures (reduced animation)
    case fastSwipe = "fast_swipe"

    /// Debug overlays (card count, state info)
    case debugOverlays = "debug_overlays"

    /// Show shopping cart badge
    case shoppingCart = "shopping_cart"

    /// AI-powered smart replies
    case smartReplies = "smart_replies"

    /// Advanced search with filters
    case advancedSearch = "advanced_search"

    /// Model tuning for training AI classifications
    case modelTuning = "model_tuning"

    // MARK: - Backend Features

    /// Real email integration (vs mock data)
    case realEmails = "real_emails"

    /// Cloud sync for user preferences
    case cloudSync = "cloud_sync"

    /// Background email refresh
    case backgroundRefresh = "background_refresh"

    // MARK: - Experimental

    /// AI-powered email summarization
    case aiSummarization = "ai_summarization"

    /// Voice commands
    case voiceCommands = "voice_commands"

    /// Dark mode override
    case darkModeOverride = "dark_mode_override"

    // MARK: - Properties

    /// Default value (used when no config is available)
    var defaultValue: Bool {
        switch self {
        case .debugOverlays:
            // Debug overlays default to OFF in production
            #if DEBUG
            return true
            #else
            return false
            #endif

        case .newComposer, .fastSwipe, .smartReplies, .advancedSearch, .modelTuning:
            // UI improvements default to ON
            return true

        case .shoppingCart:
            // Shopping features default to ON
            return true

        case .realEmails, .cloudSync, .backgroundRefresh:
            // Backend features default to ON
            return true

        case .aiSummarization, .voiceCommands, .darkModeOverride:
            // Experimental features default to OFF
            return false
        }
    }

    /// Human-readable description for admin UI
    var description: String {
        switch self {
        case .newComposer:
            return "New email composer with rich formatting"
        case .fastSwipe:
            return "Fast swipe gestures (reduced animation)"
        case .debugOverlays:
            return "Show debug overlays with card count and state"
        case .shoppingCart:
            return "Show shopping cart badge and features"
        case .smartReplies:
            return "AI-powered smart reply suggestions"
        case .advancedSearch:
            return "Advanced search with filters and operators"
        case .modelTuning:
            return "Model tuning for training AI classifications and action recommendations"
        case .realEmails:
            return "Real email integration (vs mock data)"
        case .cloudSync:
            return "Cloud sync for user preferences"
        case .backgroundRefresh:
            return "Background email refresh"
        case .aiSummarization:
            return "AI-powered email summarization"
        case .voiceCommands:
            return "Voice command support"
        case .darkModeOverride:
            return "Dark mode override (force dark mode)"
        }
    }
}

// MARK: - FeatureGating Protocol

/**
 * FeatureGating - Protocol for feature flag evaluation
 *
 * Allows easy mocking in tests and swapping implementations
 */
protocol FeatureGating {
    /// Check if a feature is enabled
    func isEnabled(_ flag: FeatureFlag) -> Bool

    /// Force-enable a feature (for testing/debugging)
    func enable(_ flag: FeatureFlag)

    /// Force-disable a feature (kill-switch)
    func disable(_ flag: FeatureFlag)

    /// Reset to default values
    func reset()

    /// Get all flags with their current state
    func getAllFlags() -> [FeatureFlag: Bool]
}

// MARK: - LocalFeatureGating Implementation

/**
 * LocalFeatureGating - Local implementation backed by UserDefaults + optional JSON config
 *
 * Features:
 * - Persists overrides in UserDefaults
 * - Supports optional featureflags.json for defaults
 * - Environment variable overrides (ENABLE_FEATURE_X=1)
 * - Crash-safe: if flag causes crash, auto-disable on next launch
 */
final class LocalFeatureGating: FeatureGating {

    private let defaults: UserDefaults
    private let logger: Logging

    // MARK: - UserDefaults Keys

    private enum Key {
        static let prefix = "feature_flag_"
        static let crashedFlags = "crashed_feature_flags"

        static func key(for flag: FeatureFlag) -> String {
            return prefix + flag.rawValue
        }
    }

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard, logger: Logging) {
        self.defaults = defaults
        self.logger = logger

        // Load config from JSON if available
        loadConfigFile()

        // Apply environment variable overrides
        applyEnvironmentOverrides()

        logger.info("FeatureGating initialized")
    }

    // MARK: - FeatureGating Protocol

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        // 1. Check if flag crashed in previous session (kill-switch)
        if isCrashed(flag) {
            logger.warning("Feature \(flag.rawValue) is disabled due to previous crash")
            return false
        }

        // 2. Check UserDefaults for override
        let key = Key.key(for: flag)
        if defaults.object(forKey: key) != nil {
            let value = defaults.bool(forKey: key)
            logger.debug("Feature \(flag.rawValue): \(value) (override)")
            return value
        }

        // 3. Fall back to default
        let value = flag.defaultValue
        logger.debug("Feature \(flag.rawValue): \(value) (default)")
        return value
    }

    func enable(_ flag: FeatureFlag) {
        let key = Key.key(for: flag)
        defaults.set(true, forKey: key)
        logger.info("Feature \(flag.rawValue) force-enabled")
    }

    func disable(_ flag: FeatureFlag) {
        let key = Key.key(for: flag)
        defaults.set(false, forKey: key)
        logger.info("Feature \(flag.rawValue) force-disabled")
    }

    func reset() {
        // Remove all feature flag overrides
        for flag in FeatureFlag.allCases {
            let key = Key.key(for: flag)
            defaults.removeObject(forKey: key)
        }

        // Clear crashed flags
        defaults.removeObject(forKey: Key.crashedFlags)

        logger.info("All feature flags reset to defaults")
    }

    func getAllFlags() -> [FeatureFlag: Bool] {
        var result: [FeatureFlag: Bool] = [:]
        for flag in FeatureFlag.allCases {
            result[flag] = isEnabled(flag)
        }
        return result
    }

    // MARK: - Crash Detection

    /// Mark a feature as crashed (kill-switch)
    func markAsCrashed(_ flag: FeatureFlag) {
        var crashedFlags = getCrashedFlags()
        crashedFlags.insert(flag.rawValue)
        defaults.set(Array(crashedFlags), forKey: Key.crashedFlags)

        logger.error("Feature \(flag.rawValue) marked as crashed and disabled")
    }

    private func isCrashed(_ flag: FeatureFlag) -> Bool {
        let crashedFlags = getCrashedFlags()
        return crashedFlags.contains(flag.rawValue)
    }

    private func getCrashedFlags() -> Set<String> {
        let array = defaults.stringArray(forKey: Key.crashedFlags) ?? []
        return Set(array)
    }

    // MARK: - Config File Loading

    private func loadConfigFile() {
        // Look for featureflags.json in bundle
        guard let url = Bundle.main.url(forResource: "featureflags", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Bool] else {
            logger.debug("No featureflags.json found, using defaults")
            return
        }

        // Apply config from JSON
        for (key, value) in json {
            if let flag = FeatureFlag.allCases.first(where: { $0.rawValue == key }) {
                let defaultsKey = Key.key(for: flag)
                // Only set if not already overridden
                if defaults.object(forKey: defaultsKey) == nil {
                    defaults.set(value, forKey: defaultsKey)
                    logger.info("Feature \(flag.rawValue) set to \(value) from config file")
                }
            }
        }
    }

    // MARK: - Environment Variable Overrides

    private func applyEnvironmentOverrides() {
        let env = ProcessInfo.processInfo.environment

        for flag in FeatureFlag.allCases {
            // Check for ENABLE_FEATURE_X=1 or DISABLE_FEATURE_X=1
            let enableKey = "ENABLE_FEATURE_\(flag.rawValue.uppercased())"
            let disableKey = "DISABLE_FEATURE_\(flag.rawValue.uppercased())"

            if env[enableKey] == "1" {
                enable(flag)
                logger.info("Feature \(flag.rawValue) enabled via environment variable")
            } else if env[disableKey] == "1" {
                disable(flag)
                logger.info("Feature \(flag.rawValue) disabled via environment variable")
            }
        }
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
final class MockFeatureGating: FeatureGating {
    private var flags: [FeatureFlag: Bool] = [:]

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        return flags[flag] ?? flag.defaultValue
    }

    func enable(_ flag: FeatureFlag) {
        flags[flag] = true
    }

    func disable(_ flag: FeatureFlag) {
        flags[flag] = false
    }

    func reset() {
        flags.removeAll()
    }

    func getAllFlags() -> [FeatureFlag: Bool] {
        var result: [FeatureFlag: Bool] = [:]
        for flag in FeatureFlag.allCases {
            result[flag] = isEnabled(flag)
        }
        return result
    }
}
#endif
