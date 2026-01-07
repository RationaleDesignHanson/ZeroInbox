//
//  WatchModels.swift
//  Zero
//
//  Created by Claude Code on 2025-12-12.
//  Shared models for iPhone ↔ Apple Watch communication
//
//  These models are lightweight, optimized for WatchConnectivity transfer.
//  Add this file to both iOS and watchOS targets in Xcode.
//

import Foundation
import SwiftUI

// MARK: - WatchEmail

/// Lightweight email representation for Apple Watch
/// ~1KB per email vs ~10KB for full EmailCard
struct WatchEmail: Codable, Identifiable, Hashable {
    let id: String
    let title: String              // Email subject
    let sender: String             // Sender name or email
    let senderInitial: String      // For avatar display (e.g., "SC")
    let timeAgo: String            // Relative time (e.g., "2h ago")
    let priority: Priority
    let archetype: String          // "work", "shopping", "social", etc.
    let hpa: String                // High-priority action
    let isUnread: Bool
    let isUrgent: Bool

    enum Priority: String, Codable {
        case high
        case medium
        case low
    }

    // MARK: - UI Helpers

    /// Accent color based on archetype
    var accentColor: Color {
        switch archetype.lowercased() {
        case "work":
            return .blue
        case "shopping":
            return .orange
        case "social":
            return .purple
        case "finance":
            return .green
        case "travel":
            return .cyan
        case "personal":
            return .pink
        default:
            return .gray
        }
    }

    /// SF Symbol icon for archetype
    var icon: String {
        switch archetype.lowercased() {
        case "work":
            return "briefcase.fill"
        case "shopping":
            return "cart.fill"
        case "social":
            return "person.2.fill"
        case "finance":
            return "dollarsign.circle.fill"
        case "travel":
            return "airplane"
        case "personal":
            return "envelope.fill"
        default:
            return "envelope"
        }
    }

    /// Priority badge text
    var priorityBadge: String? {
        switch priority {
        case .high:
            return "!"
        case .medium:
            return nil
        case .low:
            return nil
        }
    }
}

// MARK: - WatchInboxState

/// Complete inbox state for Apple Watch
/// Sent via updateApplicationContext (replaces previous state)
struct WatchInboxState: Codable {
    let unreadCount: Int
    let urgentCount: Int
    let emails: [WatchEmail]       // Top 50 emails
    let lastSync: Date
    let syncedWithIPhone: Bool     // Was iPhone reachable during sync?

    // Metadata
    let version: Int = 1           // For future schema migrations

    // MARK: - Helpers

    /// Is this data stale? (older than 24 hours)
    var isStale: Bool {
        Date().timeIntervalSince(lastSync) > 86400  // 24 hours
    }

    /// Human-readable sync status
    var syncStatus: String {
        if isStale {
            return "Updated \(lastSync.formatted(.relative(presentation: .named)))"
        } else {
            return "Updated \(lastSync.formatted(.relative(presentation: .numeric)))"
        }
    }
}

// MARK: - WatchAction

/// Actions that can be performed on Apple Watch
enum WatchAction: String, Codable, CaseIterable {
    case archive
    case flag
    case unflag
    case delete
    case markRead
    case markUnread

    /// Does this action require user confirmation?
    var requiresConfirmation: Bool {
        switch self {
        case .delete:
            return true
        case .archive, .flag, .unflag, .markRead, .markUnread:
            return false
        }
    }

    /// User-facing label
    var label: String {
        switch self {
        case .archive:
            return "Archive"
        case .flag:
            return "Flag"
        case .unflag:
            return "Unflag"
        case .delete:
            return "Delete"
        case .markRead:
            return "Mark Read"
        case .markUnread:
            return "Mark Unread"
        }
    }

    /// SF Symbol icon
    var icon: String {
        switch self {
        case .archive:
            return "archivebox"
        case .flag:
            return "flag.fill"
        case .unflag:
            return "flag.slash"
        case .delete:
            return "trash"
        case .markRead:
            return "envelope.open"
        case .markUnread:
            return "envelope.badge"
        }
    }
}

// MARK: - WatchActionMessage

/// Action message from Apple Watch to iPhone
/// Sent via sendMessage (requires reachability)
struct WatchActionMessage: Codable {
    let action: WatchAction
    let emailId: String
    let timestamp: Date
    let requestId: String          // For tracking async responses

    init(action: WatchAction, emailId: String) {
        self.action = action
        self.emailId = emailId
        self.timestamp = Date()
        self.requestId = UUID().uuidString
    }
}

// MARK: - WatchActionResponse

/// Response from iPhone after executing action
/// Sent as reply to action message
struct WatchActionResponse: Codable {
    let requestId: String
    let success: Bool
    let error: String?
    let updatedState: WatchInboxState?  // Optional: full updated inbox

    init(requestId: String, success: Bool, error: String? = nil, updatedState: WatchInboxState? = nil) {
        self.requestId = requestId
        self.success = success
        self.error = error
        self.updatedState = updatedState
    }
}

// MARK: - QueuedAction

/// Action queued locally on watch (when iPhone unreachable)
/// Stored in UserDefaults, retried when connection restored
struct QueuedAction: Codable, Identifiable {
    let id: String
    let action: WatchActionMessage
    let queuedAt: Date
    var retryCount: Int

    init(action: WatchActionMessage) {
        self.id = UUID().uuidString
        self.action = action
        self.queuedAt = Date()
        self.retryCount = 0
    }

    /// Should this action be retried?
    var shouldRetry: Bool {
        retryCount < 5  // Max 5 retries
    }

    /// Next retry delay (exponential backoff)
    var nextRetryDelay: TimeInterval {
        let base: TimeInterval = 1.0  // Start at 1 second
        return base * pow(2.0, Double(retryCount))  // 1s, 2s, 4s, 8s, 16s
    }
}

// MARK: - WatchError

/// Errors specific to watch connectivity
enum WatchError: LocalizedError {
    case iPhoneNotReachable
    case sessionNotActivated
    case actionFailed(String)
    case syncFailed
    case outdatedCache
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .iPhoneNotReachable:
            return "iPhone is not reachable. Action will sync when connection is restored."
        case .sessionNotActivated:
            return "Watch connection not activated. Please restart the app."
        case .actionFailed(let reason):
            return "Action failed: \(reason)"
        case .syncFailed:
            return "Sync failed. Using cached data."
        case .outdatedCache:
            return "Data may be outdated. Move closer to iPhone to sync."
        case .encodingFailed:
            return "Failed to encode data for watch."
        case .decodingFailed:
            return "Failed to decode data from iPhone."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .iPhoneNotReachable:
            return "Move closer to your iPhone or check that it's unlocked."
        case .sessionNotActivated:
            return "Restart both the iPhone and watch apps."
        case .actionFailed:
            return "Try again or perform the action on your iPhone."
        case .syncFailed:
            return "Check your iPhone connection and try again."
        case .outdatedCache:
            return "Sync with iPhone to get the latest emails."
        case .encodingFailed, .decodingFailed:
            return "This is a technical issue. Please report if it persists."
        }
    }
}
