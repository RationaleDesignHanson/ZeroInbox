//
//  AppLifecycleObserver.swift
//  Zero
//
//  Created by Claude Code on 10/26/25.
//

import Foundation
import SwiftUI
import Combine

/**
 * AppLifecycleObserver - Centralized app lifecycle management
 *
 * Purpose:
 * - Single source of truth for app lifecycle events
 * - Coordinates analytics, logging, and session tracking
 * - Handles foreground/background transitions
 * - Manages session state and timers
 *
 * Benefits:
 * - Eliminates scattered lifecycle handling in views
 * - Ensures consistent tracking across app
 * - Makes testing lifecycle events easier
 * - Provides hooks for background tasks
 */

final class AppLifecycleObserver: ObservableObject {

    // MARK: - Dependencies

    private let analytics: Analytics
    private let logger: Logging
    private let errorReporter: ErrorReporting?

    // MARK: - Session State

    @Published private(set) var sessionId: UUID = UUID()
    @Published private(set) var sessionStartTime: Date = Date()
    @Published private(set) var isInForeground: Bool = true
    @Published private(set) var sessionDuration: TimeInterval = 0

    private var backgroundTime: Date?
    private var sessionTimer: Timer?

    // MARK: - Initialization

    init(
        analytics: Analytics,
        logger: Logging,
        errorReporter: ErrorReporting? = nil
    ) {
        self.analytics = analytics
        self.logger = logger
        self.errorReporter = errorReporter

        logger.info("AppLifecycleObserver initialized")
    }

    // MARK: - Lifecycle Events

    /// Call when app launches
    func didLaunch() {
        sessionId = UUID()
        sessionStartTime = Date()
        sessionDuration = 0
        isInForeground = true

        logger.info("App launched - Session: \(sessionId.uuidString)")

        analytics.trackSessionStart()
        analytics.log(.appLaunched, parameters: [
            "session_id": sessionId.uuidString,
            "timestamp": sessionStartTime.timeIntervalSince1970
        ])

        // Start session timer
        startSessionTimer()
    }

    /// Call when app enters foreground
    func didEnterForeground() {
        isInForeground = true

        // Calculate time in background
        if let backgroundTime = backgroundTime {
            let timeInBackground = Date().timeIntervalSince(backgroundTime)
            logger.info("App entered foreground (was in background for \(String(format: "%.1f", timeInBackground))s)")

            analytics.log(.appEnteredForeground, parameters: [
                "session_id": sessionId.uuidString,
                "time_in_background": timeInBackground
            ])

            // If app was in background > 30 minutes, start new session
            if timeInBackground > 1800 {
                logger.info("Background time exceeded 30 min, starting new session")
                didLaunch()
            }
        } else {
            logger.info("App entered foreground")
            analytics.log(.appEnteredForeground)
        }

        backgroundTime = nil
        startSessionTimer()
    }

    /// Call when app enters background
    func didEnterBackground() {
        isInForeground = false
        backgroundTime = Date()

        logger.info("App entered background (session duration: \(String(format: "%.1f", sessionDuration))s)")

        analytics.log(.appEnteredBackground, parameters: [
            "session_id": sessionId.uuidString,
            "session_duration": sessionDuration
        ])

        stopSessionTimer()

        // Schedule background task if needed
        scheduleBackgroundTasks()
    }

    /// Call when app will terminate
    func willTerminate() {
        logger.info("App will terminate (session duration: \(String(format: "%.1f", sessionDuration))s)")

        analytics.log(.appSessionEnd, parameters: [
            "session_id": sessionId.uuidString,
            "session_duration": sessionDuration
        ])

        stopSessionTimer()
    }

    /// Call when app receives memory warning
    func didReceiveMemoryWarning() {
        logger.warning("Memory warning received")

        analytics.log(.memoryWarning, parameters: [
            "session_id": sessionId.uuidString,
            "session_duration": sessionDuration
        ])

        errorReporter?.reportNonFatal(
            error: NSError(
                domain: "Zero.MemoryWarning",
                code: 1,
                userInfo: [
                    "session_id": sessionId.uuidString,
                    "session_duration": sessionDuration
                ]
            ),
            context: [
                "event": "memory_warning",
                "session_duration": "\(sessionDuration)"
            ]
        )
    }

    // MARK: - Scene Phase Handling

    /// Convenience method for SwiftUI scenePhase onChange
    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            didEnterForeground()
        case .background:
            didEnterBackground()
        case .inactive:
            // Transitioning between states, no action needed
            break
        @unknown default:
            logger.warning("Unknown scene phase: \(String(describing: phase))")
        }
    }

    // MARK: - Session Timer

    private func startSessionTimer() {
        stopSessionTimer()

        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.sessionDuration = Date().timeIntervalSince(self.sessionStartTime)
        }
    }

    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }

    // MARK: - Background Tasks

    private func scheduleBackgroundTasks() {
        // Placeholder for background task registration
        // In production, register BGTaskScheduler tasks here:
        // - Email sync
        // - Analytics upload
        // - Cache cleanup

        logger.debug("Background tasks scheduled")
    }

    // MARK: - Cleanup

    deinit {
        stopSessionTimer()
        logger.debug("AppLifecycleObserver deinitialized")
    }
}
