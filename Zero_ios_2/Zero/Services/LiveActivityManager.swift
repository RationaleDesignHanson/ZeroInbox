import ActivityKit
import Foundation

/// Manages Live Activities for package tracking
/// Handles starting, updating, and ending activities on Dynamic Island and Lock Screen
@available(iOS 16.1, *)
class LiveActivityManager {

    static let shared = LiveActivityManager()

    private init() {
        Logger.info("LiveActivityManager initialized", category: .app)
    }

    // MARK: - Active Activities Tracking

    /// Store active activity IDs by tracking number
    private var activeActivities: [String: Activity<PackageTrackingAttributes>] = [:]

    // MARK: - Start Activity

    /// Start a new Live Activity for package tracking
    /// - Parameters:
    ///   - trackingNumber: Package tracking number
    ///   - carrier: Carrier name (UPS, FedEx, etc.)
    ///   - description: Optional package description
    ///   - initialStatus: Initial tracking status
    ///   - estimatedDelivery: Estimated delivery date/time string
    /// - Returns: Activity ID if successful
    @discardableResult
    func startPackageTracking(
        trackingNumber: String,
        carrier: String,
        description: String? = nil,
        initialStatus: TrackingStatus = .shipped,
        currentLocation: String? = nil,
        estimatedDelivery: String
    ) -> String? {

        // Check if ActivityKit is available
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Logger.warning("Live Activities are disabled by user", category: .app)
            return nil
        }

        // Check if activity already exists for this tracking number
        if let existingActivity = activeActivities[trackingNumber] {
            Logger.info("Activity already exists for tracking number: \(trackingNumber)", category: .app)
            return existingActivity.id
        }

        let attributes = PackageTrackingAttributes(
            trackingNumber: trackingNumber,
            carrier: carrier,
            description: description
        )

        let initialState = PackageTrackingAttributes.ContentState(
            status: initialStatus,
            currentLocation: currentLocation,
            estimatedDelivery: estimatedDelivery,
            lastUpdated: Date(),
            progress: progressForStatus(initialStatus)
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            activeActivities[trackingNumber] = activity

            Logger.info("Live Activity started", category: .app, [
                "tracking": trackingNumber,
                "carrier": carrier,
                "activityId": activity.id
            ])

            // Log analytics
            AnalyticsService.shared.log("live_activity_started", properties: [
                "tracking_number": trackingNumber,
                "carrier": carrier,
                "status": initialStatus.rawValue
            ])

            return activity.id

        } catch {
            Logger.error("Failed to start Live Activity", category: .app, error: error)
            return nil
        }
    }

    // MARK: - Update Activity

    /// Update an existing Live Activity with new tracking information
    /// - Parameters:
    ///   - trackingNumber: Package tracking number
    ///   - status: New tracking status
    ///   - location: Current location (optional)
    ///   - estimatedDelivery: Updated delivery estimate (optional)
    func updatePackageTracking(
        trackingNumber: String,
        status: TrackingStatus,
        currentLocation: String? = nil,
        estimatedDelivery: String? = nil
    ) {
        guard let activity = activeActivities[trackingNumber] else {
            Logger.warning("No active Live Activity found for tracking: \(trackingNumber)", category: .app)
            return
        }

        let newState = PackageTrackingAttributes.ContentState(
            status: status,
            currentLocation: currentLocation ?? activity.content.state.currentLocation,
            estimatedDelivery: estimatedDelivery ?? activity.content.state.estimatedDelivery,
            lastUpdated: Date(),
            progress: progressForStatus(status)
        )

        Task {
            await activity.update(.init(state: newState, staleDate: nil))

            Logger.info("Live Activity updated", category: .app, [
                "tracking": trackingNumber,
                "status": status.rawValue,
                "progress": "\(newState.progress)%"
            ])

            // Log analytics
            AnalyticsService.shared.log("live_activity_updated", properties: [
                "tracking_number": trackingNumber,
                "status": status.rawValue,
                "progress": newState.progress
            ])
        }
    }

    // MARK: - End Activity

    /// End a Live Activity (when package is delivered or cancelled)
    /// - Parameters:
    ///   - trackingNumber: Package tracking number
    ///   - finalStatus: Final status to show before dismissal
    ///   - dismissAfter: Seconds to wait before dismissing (default: 5)
    func endPackageTracking(
        trackingNumber: String,
        finalStatus: TrackingStatus = .delivered,
        dismissAfter: TimeInterval = 5.0
    ) {
        guard let activity = activeActivities[trackingNumber] else {
            Logger.warning("No active Live Activity found for tracking: \(trackingNumber)", category: .app)
            return
        }

        let finalState = PackageTrackingAttributes.ContentState(
            status: finalStatus,
            currentLocation: activity.content.state.currentLocation,
            estimatedDelivery: finalStatus == .delivered ? "Delivered" : activity.content.state.estimatedDelivery,
            lastUpdated: Date(),
            progress: 100
        )

        Task {
            // Update to final state
            await activity.update(.init(state: finalState, staleDate: nil))

            // Wait a bit before ending so user sees the final state
            try? await Task.sleep(nanoseconds: UInt64(dismissAfter * 1_000_000_000))

            // End the activity
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .default)

            // Remove from active tracking
            activeActivities.removeValue(forKey: trackingNumber)

            Logger.info("Live Activity ended", category: .app, [
                "tracking": trackingNumber,
                "finalStatus": finalStatus.rawValue
            ])

            // Log analytics
            AnalyticsService.shared.log("live_activity_ended", properties: [
                "tracking_number": trackingNumber,
                "final_status": finalStatus.rawValue
            ])
        }
    }

    // MARK: - Query Activities

    /// Check if a Live Activity is running for a tracking number
    func isActivityActive(trackingNumber: String) -> Bool {
        return activeActivities[trackingNumber] != nil
    }

    /// Get all active tracking numbers
    func getActiveTrackingNumbers() -> [String] {
        return Array(activeActivities.keys)
    }

    /// End all active activities (e.g., on app termination)
    func endAllActivities() {
        Logger.info("Ending all Live Activities", category: .app)

        for (trackingNumber, _) in activeActivities {
            endPackageTracking(trackingNumber: trackingNumber)
        }
    }

    // MARK: - Helper Functions

    /// Calculate progress percentage based on status
    private func progressForStatus(_ status: TrackingStatus) -> Int {
        switch status {
        case .orderPlaced: return 10
        case .shipped: return 30
        case .inTransit: return 60
        case .outForDelivery: return 90
        case .delivered: return 100
        case .exception: return 50 // Unknown, show halfway
        }
    }

    // MARK: - Mock Tracking Updates (for testing)

    /// Simulate package tracking updates for testing
    /// Updates status every few seconds: shipped → in transit → out for delivery → delivered
    func simulateTrackingUpdates(trackingNumber: String) {
        Logger.info("Starting simulated tracking updates", category: .app)

        Task {
            // Wait 5 seconds, then update to "in transit"
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            updatePackageTracking(
                trackingNumber: trackingNumber,
                status: .inTransit,
                currentLocation: "Memphis, TN"
            )

            // Wait 8 seconds, update to "out for delivery"
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            updatePackageTracking(
                trackingNumber: trackingNumber,
                status: .outForDelivery,
                currentLocation: "Your city",
                estimatedDelivery: "Today by 8pm"
            )

            // Wait 10 seconds, mark as "delivered"
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            endPackageTracking(
                trackingNumber: trackingNumber,
                finalStatus: .delivered
            )
        }
    }
}

// MARK: - Helper Extension for Logging

extension Logger {
    static func info(_ message: String, category: Category, _ details: [String: Any]) {
        let detailsString = details.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        info("\(message) | \(detailsString)", category: category)
    }
}
