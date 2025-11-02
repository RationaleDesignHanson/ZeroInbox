import Foundation

/// Centralized launch configuration that parses environment variables and command-line arguments
/// for UI testing, mock data, and other app bootstrap settings.
///
/// This eliminates scattered ProcessInfo and UserDefaults access throughout the app,
/// making configuration testable and explicit.
struct LaunchConfiguration {
    /// Whether the app is running in UI testing mode
    let isUITesting: Bool

    /// Whether to use mock data instead of real API calls
    let useMockData: Bool

    /// Whether to skip onboarding flow
    let skipOnboarding: Bool

    /// Default initializer using system ProcessInfo and UserDefaults
    init() {
        self.init(processInfo: .processInfo, userDefaults: .standard)
    }

    /// Testable initializer with injectable dependencies
    ///
    /// - Parameters:
    ///   - processInfo: Process information (environment vars, command-line args)
    ///   - userDefaults: User defaults storage
    init(processInfo: ProcessInfo, userDefaults: UserDefaults) {
        let args = CommandLine.arguments
        self.isUITesting = args.contains("--uitesting")

        // Prefer environment variables first (for UI tests/CI), then fall back to UserDefaults
        let env = processInfo.environment
        let envUseMock = (env["USE_MOCK_DATA"] as NSString?)?.boolValue ?? false
        let envSkip = (env["SKIP_ONBOARDING"] as NSString?)?.boolValue ?? false

        self.useMockData = envUseMock || userDefaults.bool(forKey: "useMockData")
        self.skipOnboarding = envSkip || userDefaults.bool(forKey: "skipOnboarding")
    }
}
