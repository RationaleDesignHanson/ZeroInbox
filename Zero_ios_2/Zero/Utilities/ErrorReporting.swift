//
//  ErrorReporting.swift
//  Zero
//
//  Created by Claude Code on 10/26/25.
//

import Foundation

/**
 * ErrorReporting - Protocol for crash and error reporting
 *
 * Purpose:
 * - Abstract interface for error reporting services
 * - Enables easy swap between providers (Sentry, Crashlytics, etc.)
 * - Supports both fatal crashes and non-fatal errors
 * - Allows adding context and breadcrumbs for debugging
 *
 * Usage:
 * errorReporter.reportNonFatal(error, context: ["feature": "email_sync"])
 * errorReporter.addBreadcrumb("User tapped refresh button")
 */

protocol ErrorReporting {
    /// Report a non-fatal error (app continues running)
    func reportNonFatal(error: Error, context: [String: String]?)

    /// Add breadcrumb for debugging context
    func addBreadcrumb(_ message: String, category: String?)

    /// Set user context for error reports
    func setUser(id: String?, email: String?)

    /// Add custom context to all future error reports
    func setContext(_ key: String, value: Any)

    /// Clear user context (e.g., on logout)
    func clearUser()
}

// MARK: - Console Error Reporter (Development)

/**
 * ConsoleErrorReporter - Logs errors to console for development
 *
 * Use in development/testing before integrating real crash reporting
 */
final class ConsoleErrorReporter: ErrorReporting {

    private let logger: Logging
    private var breadcrumbs: [(message: String, category: String?, timestamp: Date)] = []
    private var contextData: [String: Any] = [:]
    private var userId: String?
    private var userEmail: String?

    init(logger: Logging) {
        self.logger = logger
    }

    func reportNonFatal(error: Error, context: [String: String]?) {
        logger.error("🚨 Non-Fatal Error: \(error.localizedDescription)")

        if let context = context {
            logger.error("Context: \(context.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))")
        }

        if !breadcrumbs.isEmpty {
            logger.debug("Recent breadcrumbs:")
            for breadcrumb in breadcrumbs.suffix(5) {
                let category = breadcrumb.category ?? "general"
                logger.debug("  [\(category)] \(breadcrumb.message)")
            }
        }

        if let userId = userId {
            logger.debug("User: \(userId)")
        }
    }

    func addBreadcrumb(_ message: String, category: String? = nil) {
        breadcrumbs.append((message, category, Date()))

        // Keep only last 50 breadcrumbs
        if breadcrumbs.count > 50 {
            breadcrumbs.removeFirst()
        }

        logger.debug("Breadcrumb: [\(category ?? "general")] \(message)")
    }

    func setUser(id: String?, email: String?) {
        userId = id
        userEmail = email
        logger.debug("User context set: \(id ?? "nil")")
    }

    func setContext(_ key: String, value: Any) {
        contextData[key] = value
        logger.debug("Context set: \(key)=\(value)")
    }

    func clearUser() {
        userId = nil
        userEmail = nil
        logger.debug("User context cleared")
    }
}

// MARK: - Sentry Error Reporter (Production - Placeholder)

/**
 * SentryErrorReporter - Integrates with Sentry for production
 *
 * TODO: Uncomment when Sentry SDK is added
 */

/*
import Sentry

final class SentryErrorReporter: ErrorReporting {

    init() {
        // Initialize Sentry
        SentrySDK.start { options in
            options.dsn = AppEnvironment.sentryDSN
            options.debug = false
            options.enableAutoSessionTracking = true
            options.sessionTrackingIntervalMillis = 30_000
        }
    }

    func reportNonFatal(error: Error, context: [String: String]?) {
        let event = Event(error: error)
        event.level = .error

        if let context = context {
            event.extra = context
        }

        SentrySDK.capture(event: event)
    }

    func addBreadcrumb(_ message: String, category: String? = nil) {
        let breadcrumb = Breadcrumb()
        breadcrumb.message = message
        breadcrumb.category = category ?? "general"
        breadcrumb.level = .info
        SentrySDK.addBreadcrumb(breadcrumb)
    }

    func setUser(id: String?, email: String?) {
        let user = User()
        user.userId = id
        user.email = email
        SentrySDK.setUser(user)
    }

    func setContext(_ key: String, value: Any) {
        SentrySDK.configureScope { scope in
            scope.setContext(value: value, key: key)
        }
    }

    func clearUser() {
        SentrySDK.setUser(nil)
    }
}
*/

// MARK: - No-Op Error Reporter (Production Fallback)

/**
 * NoOpErrorReporter - Does nothing (for when error reporting is disabled)
 */
final class NoOpErrorReporter: ErrorReporting {
    func reportNonFatal(error: Error, context: [String: String]?) {}
    func addBreadcrumb(_ message: String, category: String?) {}
    func setUser(id: String?, email: String?) {}
    func setContext(_ key: String, value: Any) {}
    func clearUser() {}
}
