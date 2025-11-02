import Foundation

/// Protocol defining analytics service operations
/// Enables dependency injection and testing with mock implementations
protocol AnalyticsServiceProtocol {

    // MARK: - Configuration

    /// Data mode: "mock" or "real" - used to separate analytics signals
    var dataMode: String { get set }

    // MARK: - Event Logging

    /// Log an analytics event with optional properties
    func log(_ eventName: String, properties: [String: Any]?)

    // MARK: - User Properties

    /// Set user property (e.g., user type, settings)
    func setUserProperty(_ value: String, forName name: String)

    // MARK: - Session Tracking

    /// Track app session start
    func trackSessionStart()

    /// Track app session end
    func trackSessionEnd()
}

// MARK: - Default Implementation for Optional Parameters

extension AnalyticsServiceProtocol {
    func log(_ eventName: String, properties: [String: Any]? = nil) {
        log(eventName, properties: properties)
    }
}

