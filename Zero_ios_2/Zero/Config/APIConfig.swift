//
//  APIConfig.swift
//  Zero
//
//  Created by Matt Hanson with Claude Code on 10/26/25.
//

import Foundation

/**
 * APIConfig - Central API configuration
 *
 * Provides base URL for all backend API requests
 */
struct APIConfig {
    /// Base URL for backend API (localhost for development, Cloud Run for production)
    static let baseURL: String = {
        // Check for override from launch argument or environment
        if ProcessInfo.processInfo.environment["USE_PRODUCTION_API"] == "true" {
            return "https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api"
        }

        #if DEBUG
        // Development: Cloud Run for testing OAuth (change to localhost if running local backend)
        return "https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api"
        #else
        // Production: Cloud Run gateway
        return "https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api"
        #endif
    }()

    /// Steel Agent service URL (subscription cancellation)
    static let steelAgentURL = "\(baseURL)/api/subscription"

    /// Feedback service URL
    static let feedbackURL = "\(baseURL)/api/feedback"

    /// Classification service URL
    static let classificationURL = "\(baseURL)/api/classify"

    /// Smart Replies service URL
    static let smartRepliesURL = "\(baseURL)/api/smart-replies"

    /// Analytics service URL (localhost for development)
    /// AnalyticsService uses this for batch event sync
    /// Backend: /backend/services/analytics (port 8090)
    /// Dashboard: http://localhost:8090/analytics-dashboard.html
    static let analyticsURL: String = {
        #if DEBUG
        return "http://localhost:8090"
        #else
        // TODO: Update with production analytics service URL when deployed
        return "https://emailshortform-analytics-hqdlmnyzrq-uc.a.run.app"
        #endif
    }()
}
