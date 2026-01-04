//
//  WatchConnectivityManager_watchOS.swift
//  Zer0Watch (watchOS)
//
//  Created by Claude Code on 2025-12-12.
//  Part of Wearables Implementation (Week 3-4: Watch App)
//
//  Purpose: Manage communication between Apple Watch and iPhone.
//  Receives inbox updates, sends actions, handles offline queuing.
//
//  NOTE: Add this file to the watchOS target ONLY (not iOS target).
//  Use #if os(watchOS) to ensure watchOS-only compilation.
//

import Foundation
import WatchConnectivity
import Combine

#if os(watchOS)

/// Manager for Apple Watch ↔ iPhone communication (watchOS side)
/// Receives inbox updates from iPhone, sends actions to iPhone
@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    // MARK: - Published State

    @Published var isPhoneReachable: Bool = false
    @Published var inboxState: WatchInboxState?
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var isPendingAction: Bool = false

    // MARK: - Private Properties

    private var session: WCSession?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // Offline action queue
    private var actionQueue: [QueuedAction] = []
    private let queueKey = "com.zero.watch.actionQueue"

    // Action retry state
    private var isProcessingQueue: Bool = false

    // MARK: - Initialization

    override init() {
        super.init()

        // Initialize encoder/decoder with date strategy
        encoder.dateEncodingStrategy = .secondsSince1970
        decoder.dateDecodingStrategy = .secondsSince1970

        // Load persisted action queue
        loadActionQueue()

        // Setup WatchConnectivity
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()

            Logger.info("⌚️ WatchConnectivity initialized", category: .watch)
        } else {
            Logger.warning("⚠️ WatchConnectivity not supported on this device", category: .watch)
        }
    }

    // MARK: - Public API

    /// Execute action on email (archive, flag, delete, etc.)
    /// If iPhone is reachable, sends immediately. Otherwise queues for later.
    func executeAction(_ action: WatchAction, on emailId: String) async throws {
        let message = WatchActionMessage(action: action, emailId: emailId)

        guard let session = session, session.activationState == .activated else {
            throw WatchError.sessionNotActivated
        }

        // Try to send immediately if reachable
        if session.isReachable {
            try await sendActionToPhone(message)
        } else {
            // Queue for later
            queueAction(message)
            throw WatchError.iPhoneNotReachable
        }
    }

    /// Request fresh inbox data from iPhone
    func requestInboxUpdate() {
        guard let session = session, session.isReachable else {
            Logger.debug("⚠️ iPhone not reachable, cannot request update", category: .watch)
            syncError = "iPhone not reachable"
            return
        }

        session.sendMessage(["action": "requestInbox"], replyHandler: nil) { error in
            Logger.error("❌ Failed to request inbox update: \(error)", category: .watch)
            Task { @MainActor in
                self.syncError = error.localizedDescription
            }
        }
    }

    /// Retry queued actions (called when iPhone becomes reachable)
    func retryQueuedActions() async {
        guard !isProcessingQueue else {
            Logger.debug("Already processing queue", category: .watch)
            return
        }

        isProcessingQueue = true
        isPendingAction = true

        Logger.info("⏳ Retrying \(actionQueue.count) queued actions", category: .watch)

        var successfulActions: [String] = []

        for queuedAction in actionQueue {
            do {
                try await sendActionToPhone(queuedAction.action)
                successfulActions.append(queuedAction.id)
                Logger.debug("✓ Queued action succeeded: \(queuedAction.action.action.rawValue)", category: .watch)

            } catch {
                Logger.warning("⚠️ Queued action failed: \(error)", category: .watch)

                // Increment retry count
                if var updatedAction = actionQueue.first(where: { $0.id == queuedAction.id }) {
                    updatedAction.retryCount += 1

                    if !updatedAction.shouldRetry {
                        Logger.warning("⚠️ Max retries reached, removing action", category: .watch)
                        successfulActions.append(queuedAction.id)
                    }
                }
            }
        }

        // Remove successful actions from queue
        actionQueue.removeAll { successfulActions.contains($0.id) }
        saveActionQueue()

        isProcessingQueue = false
        isPendingAction = !actionQueue.isEmpty

        Logger.info("✓ Queue processing complete. \(actionQueue.count) actions remaining", category: .watch)
    }

    // MARK: - Action Sending

    /// Send action to iPhone via WatchConnectivity
    private func sendActionToPhone(_ message: WatchActionMessage) async throws {
        guard let session = session, session.isReachable else {
            throw WatchError.iPhoneNotReachable
        }

        return try await withCheckedThrowingContinuation { continuation in
            do {
                let data = try encoder.encode(message)
                guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw WatchError.encodingFailed
                }

                session.sendMessage(dict, replyHandler: { response in
                    Logger.debug("✓ iPhone acknowledged action", category: .watch)

                    // Parse response
                    do {
                        let responseData = try JSONSerialization.data(withJSONObject: response)
                        let actionResponse = try self.decoder.decode(WatchActionResponse.self, from: responseData)

                        Task { @MainActor in
                            if let updatedState = actionResponse.updatedState {
                                self.inboxState = updatedState
                                self.lastSyncDate = Date()
                            }
                        }

                        continuation.resume()

                    } catch {
                        Logger.error("❌ Failed to parse action response: \(error)", category: .watch)
                        continuation.resume(throwing: WatchError.decodingFailed)
                    }

                }, errorHandler: { error in
                    Logger.error("❌ Action send failed: \(error)", category: .watch)
                    continuation.resume(throwing: WatchError.actionFailed(error.localizedDescription))
                })

            } catch {
                Logger.error("❌ Failed to encode action: \(error)", category: .watch)
                continuation.resume(throwing: WatchError.encodingFailed)
            }
        }
    }

    // MARK: - Action Queue (Offline Support)

    /// Queue action for retry when iPhone is reachable
    private func queueAction(_ message: WatchActionMessage) {
        let queuedAction = QueuedAction(action: message)
        actionQueue.append(queuedAction)
        saveActionQueue()

        isPendingAction = true

        Logger.info("⏸ Action queued for retry: \(message.action.rawValue) on \(message.emailId)", category: .watch)
    }

    /// Load action queue from UserDefaults
    private func loadActionQueue() {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else {
            return
        }

        do {
            actionQueue = try decoder.decode([QueuedAction].self, from: data)
            isPendingAction = !actionQueue.isEmpty
            Logger.info("✓ Loaded \(actionQueue.count) queued actions", category: .watch)
        } catch {
            Logger.error("❌ Failed to load action queue: \(error)", category: .watch)
        }
    }

    /// Save action queue to UserDefaults
    private func saveActionQueue() {
        do {
            let data = try encoder.encode(actionQueue)
            UserDefaults.standard.set(data, forKey: queueKey)
        } catch {
            Logger.error("❌ Failed to save action queue: \(error)", category: .watch)
        }
    }

    // MARK: - Inbox State Management

    /// Update local inbox state (received from iPhone)
    private func updateInboxState(from context: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: context)
            let state = try decoder.decode(WatchInboxState.self, from: data)

            self.inboxState = state
            self.lastSyncDate = state.lastSync
            self.syncError = nil

            Logger.info("✓ Inbox updated: \(state.unreadCount) unread, \(state.emails.count) emails", category: .watch)

        } catch {
            Logger.error("❌ Failed to decode inbox state: \(error)", category: .watch)
            self.syncError = "Failed to sync inbox"
        }
    }

    // MARK: - Testing Helpers

    /// Force request inbox update (for testing)
    func _testRequestInbox() {
        requestInboxUpdate()
    }

    /// Get current queue count (for testing)
    func _testGetQueueCount() -> Int {
        return actionQueue.count
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            switch activationState {
            case .activated:
                Logger.info("✓ WCSession activated", category: .watch)
                isPhoneReachable = session.isReachable

                // Retry queued actions if iPhone reachable
                if session.isReachable && !actionQueue.isEmpty {
                    await retryQueuedActions()
                }

            case .inactive:
                Logger.debug("⌚️ WCSession inactive", category: .watch)

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
            isPhoneReachable = session.isReachable
            Logger.debug("⌚️ iPhone reachability changed: \(session.isReachable ? "reachable" : "not reachable")", category: .watch)

            // Retry queued actions when iPhone becomes reachable
            if session.isReachable && !actionQueue.isEmpty {
                await retryQueuedActions()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // iPhone sent updated inbox state via context
        Task { @MainActor in
            Logger.debug("⌚️ Received application context from iPhone", category: .watch)
            updateInboxState(from: applicationContext)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // iPhone sent immediate message (e.g., action confirmation)
        Task { @MainActor in
            Logger.debug("⌚️ Received message from iPhone: \(message)", category: .watch)

            // Check for updated inbox state
            if message.keys.contains("unreadCount") {
                updateInboxState(from: message)
            }
        }
    }
}

#endif
