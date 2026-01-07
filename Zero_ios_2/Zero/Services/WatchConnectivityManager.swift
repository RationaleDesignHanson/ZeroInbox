//
//  WatchConnectivityManager.swift
//  Zero (iOS)
//
//  Created by Claude Code on 2025-12-12.
//  Part of Wearables Implementation (Week 3-4: Watch Integration)
//
//  Purpose: Manage bidirectional communication between iPhone and Apple Watch.
//  Handles inbox syncing, action execution, offline queuing, and error recovery.
//

import Foundation
import WatchConnectivity
import Combine

#if os(iOS)

/// Manager for iPhone ↔ Apple Watch communication
/// Sends inbox updates to watch, receives and executes actions from watch
@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    // MARK: - Published State

    @Published var isWatchPaired: Bool = false
    @Published var isWatchReachable: Bool = false
    @Published var isWatchAppInstalled: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?

    // MARK: - Private Properties

    private var session: WCSession?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // Action queue for failed sends
    private var actionQueue: [WatchActionMessage] = []
    private var retryTimer: Timer?

    // MARK: - Callbacks

    /// Called when watch requests an action (archive, flag, etc.)
    /// Production app should set this to handle actions
    /// Returns true if action succeeded, false otherwise
    var onActionReceived: ((WatchAction, String) async -> Bool)?

    /// Called when watch needs inbox data
    /// Production app should return (unreadCount, urgentCount, emails)
    var inboxDataProvider: (() -> (Int, Int, [EmailCard]))?

    // MARK: - Initialization

    override init() {
        super.init()

        // Initialize encoder/decoder with date strategy
        encoder.dateEncodingStrategy = .secondsSince1970
        decoder.dateDecodingStrategy = .secondsSince1970

        // Setup WatchConnectivity
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()

            Logger.info("📱 WatchConnectivity initialized", category: .watch)
        } else {
            Logger.warning("⚠️ WatchConnectivity not supported on this device", category: .watch)
        }
    }

    // MARK: - Public API

    /// Send inbox update to watch
    /// Uses updateApplicationContext (replaces previous, delivered when watch wakes)
    func pushInboxUpdate() {
        guard let session = session,
              session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled else {
            Logger.debug("⚠️ Cannot push inbox update: watch not ready", category: .watch)
            return
        }

        // Get data from production app
        guard let (unreadCount, urgentCount, emails) = inboxDataProvider?() else {
            Logger.warning("⚠️ Inbox data provider not set", category: .watch)
            return
        }

        // Convert to watch models (top 50 emails)
        let watchEmails = emails.prefix(50).map { convertToWatchEmail($0) }

        let state = WatchInboxState(
            unreadCount: unreadCount,
            urgentCount: urgentCount,
            emails: watchEmails,
            lastSync: Date(),
            syncedWithIPhone: session.isReachable
        )

        // Encode and send
        do {
            let data = try encoder.encode(state)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                Logger.error("❌ Failed to convert state to dictionary", category: .watch)
                return
            }

            try session.updateApplicationContext(dict)
            lastSyncDate = Date()
            syncError = nil

            Logger.info("✓ Pushed inbox update to watch: \(unreadCount) unread, \(watchEmails.count) emails", category: .watch)

        } catch {
            syncError = error.localizedDescription
            Logger.error("❌ Failed to push inbox update: \(error)", category: .watch)
        }
    }

    /// Send immediate message to watch (requires reachability)
    /// Use for urgent updates that can't wait
    func sendImmediateUpdate(message: [String: Any]) {
        guard let session = session, session.isReachable else {
            Logger.debug("⚠️ Watch not reachable for immediate message", category: .watch)
            return
        }

        session.sendMessage(message, replyHandler: { response in
            Logger.debug("✓ Watch acknowledged immediate message", category: .watch)
        }, errorHandler: { error in
            Logger.error("❌ Immediate message failed: \(error)", category: .watch)
        })
    }

    // MARK: - Action Handling

    /// Handle action received from watch
    private func handleAction(_ action: WatchActionMessage) async {
        Logger.info("⚡️ Handling action from watch: \(action.action.rawValue) on \(action.emailId)", category: .watch)

        guard let onActionReceived = onActionReceived else {
            Logger.error("❌ Action callback not set", category: .watch)
            await sendActionResponse(
                requestId: action.requestId,
                success: false,
                error: "Action handler not configured"
            )
            return
        }

        // Execute action
        let success = await onActionReceived(action.action, action.emailId)

        // Send response
        await sendActionResponse(
            requestId: action.requestId,
            success: success,
            error: success ? nil : "Action failed to execute",
            includeUpdatedState: success
        )

        // If successful, push updated inbox
        if success {
            pushInboxUpdate()
        }
    }

    /// Send action response back to watch
    private func sendActionResponse(requestId: String, success: Bool, error: String?, includeUpdatedState: Bool = false) async {
        let response = WatchActionResponse(
            requestId: requestId,
            success: success,
            error: error,
            updatedState: includeUpdatedState ? getCurrentInboxState() : nil
        )

        do {
            let data = try encoder.encode(response)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }

            // Send as message (requires reachability)
            guard let session = session, session.isReachable else {
                Logger.warning("⚠️ Watch not reachable to send action response", category: .watch)
                return
            }

            session.sendMessage(dict, replyHandler: nil)

            Logger.debug("✓ Sent action response to watch", category: .watch)

        } catch {
            Logger.error("❌ Failed to send action response: \(error)", category: .watch)
        }
    }

    // MARK: - Data Conversion

    /// Convert full EmailCard to lightweight WatchEmail
    private func convertToWatchEmail(_ email: EmailCard) -> WatchEmail {
        return WatchEmail(
            id: email.id,
            title: email.title,
            sender: email.sender?.name ?? "Unknown",
            senderInitial: email.sender?.initial ?? "?",
            timeAgo: email.timeAgo,
            priority: convertPriority(email.priority),
            archetype: email.type.rawValue,
            hpa: email.hpa,
            isUnread: email.state != .archived,
            isUrgent: email.urgent ?? false
        )
    }

    /// Convert EmailCard.Priority to WatchEmail.Priority
    private func convertPriority(_ priority: EmailCard.Priority) -> WatchEmail.Priority {
        switch priority {
        case .high:
            return .high
        case .medium:
            return .medium
        case .low:
            return .low
        }
    }

    /// Get current inbox state (for action responses)
    private func getCurrentInboxState() -> WatchInboxState? {
        guard let (unreadCount, urgentCount, emails) = inboxDataProvider?() else {
            return nil
        }

        let watchEmails = emails.prefix(50).map { convertToWatchEmail($0) }

        return WatchInboxState(
            unreadCount: unreadCount,
            urgentCount: urgentCount,
            emails: watchEmails,
            lastSync: Date(),
            syncedWithIPhone: session?.isReachable ?? false
        )
    }

    // MARK: - Testing Helpers

    /// Force a sync (for testing)
    func _testForcePush() {
        pushInboxUpdate()
    }

    /// Get session state (for testing)
    func _testGetSessionState() -> (paired: Bool, reachable: Bool, installed: Bool) {
        guard let session = session else {
            return (false, false, false)
        }
        return (session.isPaired, session.isReachable, session.isWatchAppInstalled)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Logger.debug("📱 WCSession became inactive", category: .watch)
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Logger.debug("📱 WCSession deactivated", category: .watch)
        session.activate()
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            switch activationState {
            case .activated:
                Logger.info("✓ WCSession activated", category: .watch)
                isWatchPaired = session.isPaired
                isWatchReachable = session.isReachable
                isWatchAppInstalled = session.isWatchAppInstalled

                // Push initial data
                if isWatchAppInstalled {
                    pushInboxUpdate()
                }

            case .inactive:
                Logger.debug("📱 WCSession inactive", category: .watch)

            case .notActivated:
                Logger.warning("⚠️ WCSession not activated", category: .watch)

            @unknown default:
                Logger.warning("⚠️ Unknown WCSession activation state", category: .watch)
            }

            if let error = error {
                syncError = error.localizedDescription
                Logger.error("❌ WCSession activation error: \(error)", category: .watch)
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchReachable = session.isReachable
            Logger.debug("📱 Watch reachability changed: \(session.isReachable ? "reachable" : "not reachable")", category: .watch)

            // If watch became reachable, push update
            if session.isReachable {
                pushInboxUpdate()
            }
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchPaired = session.isPaired
            isWatchAppInstalled = session.isWatchAppInstalled
            Logger.debug("📱 Watch state changed: paired=\(session.isPaired), installed=\(session.isWatchAppInstalled)", category: .watch)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Watch sent us a message (action request or data request)
        Task { @MainActor in
            Logger.debug("📱 Received message from watch: \(message)", category: .watch)

            // Check if it's an action request
            do {
                let data = try JSONSerialization.data(withJSONObject: message)
                let action = try decoder.decode(WatchActionMessage.self, from: data)

                await handleAction(action)

                // Reply with acknowledgment
                replyHandler(["acknowledged": true])

            } catch {
                Logger.error("❌ Failed to decode action message: \(error)", category: .watch)
                replyHandler(["error": "Invalid message format"])
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Watch sent message without expecting reply
        Task { @MainActor in
            Logger.debug("📱 Received message (no reply expected): \(message)", category: .watch)

            // Handle special commands
            if let action = message["action"] as? String {
                switch action {
                case "requestInbox":
                    // Watch requesting fresh data
                    pushInboxUpdate()

                default:
                    Logger.debug("Unknown action: \(action)", category: .watch)
                }
            }
        }
    }
}

#endif
