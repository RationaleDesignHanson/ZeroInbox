import Foundation
import UIKit

/**
 * AnalyticsService - Lightweight analytics tracking with backend sync
 *
 * Features:
 * - Console logging for TestFlight monitoring
 * - Automatic backend sync to localhost:8090/api/events/batch
 * - Event batching (max 10 events or 30 seconds)
 * - Exponential backoff retry (3 attempts)
 * - Falls back to console if backend unavailable
 * - Thread-safe event queue
 *
 * Usage:
 * container.analyticsService.log(.appSessionStart)
 */

class AnalyticsService: Analytics {
    /// DEPRECATED: Singleton accessor for backwards compatibility
    ///
    /// **Migration Path**: Use dependency injection through ServiceContainer instead
    /// ```swift
    /// // Old (deprecated):
    /// AnalyticsService.shared.log(.appSessionStart)
    ///
    /// // New (preferred):
    /// container.analyticsService.log(.appSessionStart)
    /// ```
    ///
    /// **Status**: Still used in 38 files (81 occurrences) - requires coordinated migration
    /// **Phase 6 Work**: Migrate all usages to DI pattern and remove singleton
    static let shared = AnalyticsService()

    // MARK: - Backend Sync

    private let eventQueue = DispatchQueue(label: "com.zeromail.analytics", qos: .utility)
    private var pendingEvents: [[String: Any]] = []
    private var syncTimer: Timer?
    private let maxBatchSize = 10
    private let batchInterval: TimeInterval = 30.0
    private var retryCount = 0
    private let maxRetries = 3
    private var backendAvailable = true

    /// Data mode: "mock" or "real" - used to separate analytics signals
    /// Set this from AppSettings.useMockData to tag events appropriately
    var dataMode: String = "real"

    init() {
        Logger.info("Analytics service initialized with backend sync", category: .analytics)
        setupSyncTimer()
    }

    deinit {
        syncTimer?.invalidate()
        flushEvents() // Send any remaining events
    }

    private func setupSyncTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.syncTimer = Timer.scheduledTimer(withTimeInterval: self?.batchInterval ?? 30.0, repeats: true) { [weak self] _ in
                self?.flushEvents()
            }
        }
    }

    /// Log an analytics event with optional properties
    func log(_ eventName: String, properties: [String: Any]? = nil) {
        let timestamp = ISO8601DateFormatter().string(from: Date())

        // Format properties for readable console output
        let propertiesString = properties?.map { "\($0): \($1)" }.joined(separator: ", ") ?? "none"

        Logger.info("[\(timestamp)] \(eventName) | \(propertiesString)", category: .analytics)

        // For TestFlight, also log to file for later analysis
        logToFile(eventName: eventName, properties: properties)

        // Queue event for backend sync
        queueEventForBackend(eventName: eventName, properties: properties)
    }

    private func queueEventForBackend(eventName: String, properties: [String: Any]?) {
        eventQueue.async { [weak self] in
            guard let self = self else { return }

            // Get user ID from UserSession if available
            let userId = "user_\(UIDevice.current.identifierForVendor?.uuidString ?? "unknown")"

            // Determine event type from name
            let eventType: String
            if eventName.contains("viewed") {
                eventType = "view"
            } else if eventName.contains("action") || eventName.contains("executed") {
                eventType = "action"
            } else if eventName.contains("swipe") {
                eventType = "swipe"
            } else if eventName.contains("modal") {
                eventType = "modal"
            } else {
                eventType = "event"
            }

            let event: [String: Any] = [
                "userId": userId,
                "eventType": eventType,
                "eventName": eventName,
                "properties": properties ?? [:],
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "environment": self.dataMode  // "mock" or "real"
            ]

            self.pendingEvents.append(event)

            // Flush if batch size reached
            if self.pendingEvents.count >= self.maxBatchSize {
                DispatchQueue.main.async {
                    self.flushEvents()
                }
            }
        }
    }

    private func flushEvents() {
        eventQueue.async { [weak self] in
            guard let self = self, !self.pendingEvents.isEmpty else { return }

            let eventsToSend = self.pendingEvents
            self.pendingEvents.removeAll()

            self.sendEventsToBackend(events: eventsToSend)
        }
    }

    private func sendEventsToBackend(events: [[String: Any]], attempt: Int = 0) {
        // Week 6 Service Layer Cleanup: Using centralized NetworkService
        guard let url = URL(string: "http://localhost:8090/api/events/batch") else {
            Logger.error("Invalid analytics backend URL", category: .analytics)
            return
        }

        struct AnalyticsEventBatch: Codable {
            let events: [[String: AnyCodable]]
        }

        // Convert [[String: Any]] to Codable format
        let codableEvents: [[String: AnyCodable]] = events.map { event in
            event.mapValues { AnyCodable($0) }
        }

        let payload = AnalyticsEventBatch(events: codableEvents)

        Task { [weak self] in
            guard let self = self else { return }

            do {
                try await NetworkService.shared.post(url: url, body: payload)

                // Success
                self.backendAvailable = true
                self.retryCount = 0
                Logger.info("Synced \(events.count) analytics events to backend", category: .analytics)
            } catch {
                // Backend unavailable - use exponential backoff
                if attempt < self.maxRetries {
                    let delay = pow(2.0, Double(attempt)) // 1s, 2s, 4s
                    Logger.warning("Analytics backend unavailable, retrying in \(delay)s (attempt \(attempt + 1)/\(self.maxRetries))", category: .analytics)

                    Task { [weak self] in
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        self?.sendEventsToBackend(events: events, attempt: attempt + 1)
                    }
                } else {
                    // Max retries reached - backend unavailable
                    self.backendAvailable = false
                    Logger.warning("Analytics backend unavailable after \(self.maxRetries) attempts, continuing with console-only logging", category: .analytics)
                }
            }
        }
    }

    // MARK: - Helper Types for Codable Any encoding

    /// Wrapper to make Any values Codable for analytics events
    struct AnyCodable: Codable {
        let value: Any

        init(_ value: Any) {
            self.value = value
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let int = try? container.decode(Int.self) {
                value = int
            } else if let double = try? container.decode(Double.self) {
                value = double
            } else if let string = try? container.decode(String.self) {
                value = string
            } else if let bool = try? container.decode(Bool.self) {
                value = bool
            } else if let array = try? container.decode([AnyCodable].self) {
                value = array.map { $0.value }
            } else if let dictionary = try? container.decode([String: AnyCodable].self) {
                value = dictionary.mapValues { $0.value }
            } else {
                value = NSNull()
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()

            switch value {
            case let int as Int:
                try container.encode(int)
            case let double as Double:
                try container.encode(double)
            case let string as String:
                try container.encode(string)
            case let bool as Bool:
                try container.encode(bool)
            case let array as [Any]:
                try container.encode(array.map { AnyCodable($0) })
            case let dictionary as [String: Any]:
                try container.encode(dictionary.mapValues { AnyCodable($0) })
            default:
                try container.encodeNil()
            }
        }
    }

    // MARK: - Analytics Protocol Conformance

    /// Log user property with typed enum key
    func setUserProperty(_ value: String, forName property: AnalyticsUserProperty) {
        Logger.info("[USER PROPERTY] \(property.rawValue): \(value)", category: .analytics)

        // TODO: When ready, add Firebase:
        // Analytics.setUserProperty(value, forName: property.rawValue)
    }

    /// Log typed analytics event
    func log(_ event: AnalyticsEvent) {
        log(event.rawValue, properties: nil)
    }

    /// Log typed event with parameters
    func log(_ event: AnalyticsEvent, parameters: [String: Any]) {
        log(event.rawValue, properties: parameters)
    }

    /// Log custom event (for backward compatibility)
    func logCustom(_ name: String) {
        log(name, properties: nil)
    }

    // MARK: - Legacy Methods (Deprecated)

    /// Log user properties (e.g., user type, settings)
    /// DEPRECATED: Use setUserProperty(_:forName:) with typed property instead
    func setUserProperty(_ value: String, forName name: String) {
        Logger.info("[USER PROPERTY] \(name): \(value)", category: .analytics)

        // TODO: When ready, add Firebase:
        // Analytics.setUserProperty(value, forName: name)
    }

    /// Track app session start
    func trackSessionStart() {
        log("app_session_start", properties: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    /// Track app session end
    func trackSessionEnd() {
        log("app_session_end", properties: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    // MARK: - File Logging (for TestFlight analysis)

    private func logToFile(eventName: String, properties: [String: Any]?) {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let logFileURL = documentsPath.appendingPathComponent("analytics.log")

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let propertiesJSON = properties?.jsonString ?? "{}"
        let logEntry = "\(timestamp) | \(eventName) | \(propertiesJSON)\n"

        // Append to log file
        if let data = logEntry.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }
}

// MARK: - Helper Extensions

extension Dictionary where Key == String, Value == Any {
    var jsonString: String {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }
        return jsonString
    }
}
