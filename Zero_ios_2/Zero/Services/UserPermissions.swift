import Foundation

/// Manages user permissions and feature flags for action availability
/// Integrates with ActionRegistry to determine which actions user can access
class UserPermissions: ObservableObject {

    // MARK: - Singleton
    static let shared = UserPermissions()

    // MARK: - Published Properties
    @Published var isPremium: Bool = false
    @Published var isBeta: Bool = false
    @Published var isAdmin: Bool = false
    @Published var featureFlags: [String: Bool] = [:]
    @Published var customData: [String: Any] = [:]

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard

    // MARK: - Keys
    private enum Keys {
        static let isPremium = "user_is_premium"
        static let isBeta = "user_is_beta"
        static let isAdmin = "user_is_admin"
        static let featureFlags = "user_feature_flags"
    }

    // MARK: - Initialization
    private init() {
        loadFromUserDefaults()
    }

    // MARK: - User Context

    /// Generate UserContext for ActionRegistry validation
    func getUserContext(userId: String? = nil) -> UserContext {
        return UserContext(
            isPremium: isPremium,
            isBeta: isBeta,
            isAdmin: isAdmin,
            userId: userId ?? getUserId(),
            featureFlags: featureFlags,
            customData: customData
        )
    }

    // MARK: - Permission Management

    /// Update premium status
    func setPremium(_ value: Bool) {
        isPremium = value
        userDefaults.set(value, forKey: Keys.isPremium)
        Logger.info("User premium status updated: \(value)", category: .userPreferences)
    }

    /// Update beta tester status
    func setBeta(_ value: Bool) {
        isBeta = value
        userDefaults.set(value, forKey: Keys.isBeta)
        Logger.info("User beta status updated: \(value)", category: .userPreferences)
    }

    /// Update admin status
    func setAdmin(_ value: Bool) {
        isAdmin = value
        userDefaults.set(value, forKey: Keys.isAdmin)
        Logger.info("User admin status updated: \(value)", category: .userPreferences)
    }

    // MARK: - Feature Flags

    /// Enable a feature flag
    func enableFeatureFlag(_ key: String) {
        featureFlags[key] = true
        saveFeatureFlags()
        Logger.info("Feature flag enabled: \(key)", category: .userPreferences)
    }

    /// Disable a feature flag
    func disableFeatureFlag(_ key: String) {
        featureFlags[key] = false
        saveFeatureFlags()
        Logger.info("Feature flag disabled: \(key)", category: .userPreferences)
    }

    /// Check if feature flag is enabled
    func isFeatureEnabled(_ key: String) -> Bool {
        return featureFlags[key] ?? false
    }

    /// Set multiple feature flags at once
    func setFeatureFlags(_ flags: [String: Bool]) {
        featureFlags = flags
        saveFeatureFlags()
        Logger.info("Feature flags updated: \(flags.count) flags set", category: .userPreferences)
    }

    // MARK: - Custom Data

    /// Set custom user data (for complex availability rules)
    func setCustomData(key: String, value: Any) {
        customData[key] = value
        Logger.info("Custom data set: \(key)", category: .userPreferences)
    }

    /// Get custom user data
    func getCustomData(key: String) -> Any? {
        return customData[key]
    }

    // MARK: - Persistence

    private func loadFromUserDefaults() {
        isPremium = userDefaults.bool(forKey: Keys.isPremium)
        isBeta = userDefaults.bool(forKey: Keys.isBeta)
        isAdmin = userDefaults.bool(forKey: Keys.isAdmin)

        if let flagsData = userDefaults.dictionary(forKey: Keys.featureFlags) as? [String: Bool] {
            featureFlags = flagsData
        }

        Logger.info("User permissions loaded: premium=\(isPremium), beta=\(isBeta), admin=\(isAdmin), flags=\(featureFlags.count)", category: .userPreferences)
    }

    private func saveFeatureFlags() {
        userDefaults.set(featureFlags, forKey: Keys.featureFlags)
    }

    // MARK: - User ID

    private func getUserId() -> String {
        // Try to get from keychain first
        if let email = getEmailFromKeychain() {
            return email
        }

        // Fallback to device-specific ID
        if let deviceId = userDefaults.string(forKey: "device_user_id") {
            return deviceId
        }

        // Generate new device ID
        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: "device_user_id")
        return newId
    }

    private func getEmailFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "EmailShortForm",
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let attributes = result as? [String: Any],
           let email = attributes[kSecAttrAccount as String] as? String {
            return email
        }

        return nil
    }

    // MARK: - Quick Access Helpers

    /// Check if user has access to a specific permission level
    func hasPermission(_ permission: ActionPermission) -> Bool {
        return getUserContext().hasPermission(permission)
    }

    /// Reset all permissions (for testing/demo purposes)
    func resetToFree() {
        setPremium(false)
        setBeta(false)
        setAdmin(false)
        featureFlags = [:]
        customData = [:]
        Logger.info("User permissions reset to free tier", category: .userPreferences)
    }

    /// Upgrade to premium
    func upgradeToPremium() {
        setPremium(true)
        Logger.info("User upgraded to premium", category: .userPreferences)
    }

    /// Grant beta access
    func grantBetaAccess() {
        setBeta(true)
        Logger.info("Beta access granted", category: .userPreferences)
    }
}
