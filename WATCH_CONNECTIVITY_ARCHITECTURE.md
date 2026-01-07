# WatchConnectivityManager Architecture
## Bidirectional iPhone ↔ Apple Watch Communication

**Version**: 1.0
**Date**: 2025-12-12
**Status**: Architecture Complete, Ready for Implementation
**Implementation**: Week 3-4

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Principles](#architecture-principles)
3. [Communication Patterns](#communication-patterns)
4. [Data Models](#data-models)
5. [iOS Implementation](#ios-implementation)
6. [watchOS Implementation](#watchos-implementation)
7. [Message Protocol](#message-protocol)
8. [Offline & Caching Strategy](#offline--caching-strategy)
9. [Error Handling](#error-handling)
10. [Testing Strategy](#testing-strategy)

---

## Overview

### Purpose

Enable seamless, bidirectional communication between Zer0 Inbox on iPhone and Apple Watch for:
- **iPhone → Watch**: Push inbox updates, new email notifications
- **Watch → iPhone**: Execute actions (archive, flag, delete)
- **Bidirectional**: Request/response patterns for on-demand data

### Key Requirements

| Requirement | Priority | Status |
|-------------|----------|--------|
| **Real-time sync** | High | Week 3 |
| **Offline resilience** | High | Week 3 |
| **Battery efficient** | High | Week 4 |
| **Message queuing** | Medium | Week 3 |
| **Background updates** | Medium | Week 4 |
| **Watch independence** | Low | Week 5 |

---

## Architecture Principles

### 1. **Resilient by Default**
- All messages queued if connectivity unavailable
- Automatic retry with exponential backoff
- Graceful degradation (watch uses cached data)

### 2. **Battery Conscious**
- Minimize message frequency (coalesce updates)
- Use updateApplicationContext for non-urgent updates
- sendMessage only for immediate actions

### 3. **Data Minimization**
- Only send essential data to watch
- Lightweight models (WatchEmail vs. full EmailCard)
- Compression for large payloads

### 4. **State Synchronization**
- Watch maintains local state (cached emails)
- iPhone is source of truth
- Periodic reconciliation to fix drift

---

## Communication Patterns

### Pattern 1: Context Updates (Non-Urgent)

**Use Case**: Inbox count changed, new emails arrived

**Method**: `updateApplicationContext(_:)`

**Characteristics**:
- Replaces previous context (only latest matters)
- Delivered when watch wakes up
- No delivery guarantee
- Most battery efficient

**Example**:
```swift
// iPhone sends
let context = [
    "unreadCount": 15,
    "urgentCount": 3,
    "lastUpdate": Date().timeIntervalSince1970
]
try session.updateApplicationContext(context)
```

---

### Pattern 2: Immediate Messages (Urgent)

**Use Case**: User archived email on watch, needs immediate sync

**Method**: `sendMessage(_:replyHandler:errorHandler:)`

**Characteristics**:
- Requires both devices reachable
- Immediate delivery (or error)
- Can request reply
- Higher battery cost

**Example**:
```swift
// Watch sends
let message = ["action": "archive", "emailId": "123"]
session.sendMessage(message, replyHandler: { response in
    // Got confirmation from iPhone
}, errorHandler: { error in
    // Queue for later
})
```

---

### Pattern 3: User Info Transfer (Large Data)

**Use Case**: Send multiple emails to watch for offline browsing

**Method**: `transferUserInfo(_:)`

**Characteristics**:
- Background transfer (delivered eventually)
- No guarantee when delivered
- Survives app termination
- Good for bulk data

**Example**:
```swift
// iPhone sends
let emails = encodeEmailsForWatch(topEmails)
session.transferUserInfo(["emails": emails])
```

---

### Pattern 4: File Transfer (Very Large Data)

**Use Case**: Attachments, images (not needed for MVP)

**Method**: `transferFile(_:metadata:)`

**Status**: Future enhancement

---

## Data Models

### WatchEmail (Lightweight)

**Purpose**: Minimal email representation for watch display

```swift
/// Lightweight email model for watch
/// ~1KB per email vs ~10KB for full EmailCard
struct WatchEmail: Codable, Identifiable, Hashable {
    let id: String
    let title: String              // Subject
    let sender: String             // Sender name or email
    let senderInitial: String      // For avatar (e.g., "SC")
    let timeAgo: String            // "2h ago"
    let priority: Priority         // high, medium, low
    let archetype: String          // "work", "shopping", etc.
    let hpa: String                // High-priority action
    let isUnread: Bool
    let isUrgent: Bool

    // Computed
    var accentColor: Color {
        switch archetype {
        case "work": return .blue
        case "shopping": return .orange
        case "social": return .purple
        default: return .gray
        }
    }

    enum Priority: String, Codable {
        case high, medium, low
    }
}
```

**Size**: ~1KB per email
**Watch Capacity**: Store 50-100 emails comfortably

---

### WatchInboxState

**Purpose**: Complete inbox state for watch

```swift
/// Complete inbox state for watch
struct WatchInboxState: Codable {
    let unreadCount: Int
    let urgentCount: Int
    let emails: [WatchEmail]       // Top 50
    let lastSync: Date
    let syncedWithIPhone: Bool     // iPhone reachable during last sync

    // Metadata
    let version: Int = 1           // For future migration
}
```

**Size**: ~50KB for 50 emails

---

### WatchAction

**Purpose**: Actions initiated on watch, sent to iPhone

```swift
/// Actions that can be performed on watch
enum WatchAction: String, Codable {
    case archive
    case flag
    case unflag
    case delete
    case markRead
    case markUnread

    var requiresConfirmation: Bool {
        switch self {
        case .delete:
            return true
        default:
            return false
        }
    }
}

/// Action message from watch to iPhone
struct WatchActionMessage: Codable {
    let action: WatchAction
    let emailId: String
    let timestamp: Date
    let requestId: String          // For tracking async responses
}
```

---

### WatchActionResponse

**Purpose**: Response from iPhone after executing action

```swift
/// Response to action message
struct WatchActionResponse: Codable {
    let requestId: String
    let success: Bool
    let error: String?
    let updatedState: WatchInboxState?  // Optional: send updated inbox
}
```

---

## iOS Implementation

### WatchConnectivityManager (iOS)

**File**: `Services/WatchConnectivityManager.swift` (iOS target only)

```swift
import WatchConnectivity
import Combine

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    // MARK: - Published State

    @Published var isWatchPaired: Bool = false
    @Published var isWatchReachable: Bool = false
    @Published var lastSyncDate: Date?
    @Published var pendingActions: [WatchActionMessage] = []

    // MARK: - Private

    private var session: WCSession?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // Action queue (for offline)
    private var actionQueue: [WatchActionMessage] = []

    // Callbacks to production app
    var onActionReceived: ((WatchAction, String) async -> Bool)?
    var inboxDataProvider: (() -> (Int, Int, [EmailCard]))?

    // MARK: - Initialization

    override init() {
        super.init()

        #if os(iOS)
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        #endif
    }

    // MARK: - Public API

    /// Send inbox update to watch
    func pushInboxUpdate() {
        guard let session = session,
              session.activationState == .activated else {
            return
        }

        // Get data from production app
        guard let (unreadCount, urgentCount, emails) = inboxDataProvider?() else {
            return
        }

        // Convert to watch models
        let watchEmails = emails.prefix(50).map { convertToWatchEmail($0) }

        let state = WatchInboxState(
            unreadCount: unreadCount,
            urgentCount: urgentCount,
            emails: watchEmails,
            lastSync: Date(),
            syncedWithIPhone: session.isReachable
        )

        // Send via context update (non-urgent)
        if let data = try? encoder.encode(state),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            try? session.updateApplicationContext(dict)
        }

        lastSyncDate = Date()
    }

    /// Handle action from watch
    private func handleAction(_ action: WatchActionMessage) async {
        guard let onActionReceived = onActionReceived else {
            return
        }

        let success = await onActionReceived(action.action, action.emailId)

        // Send response
        let response = WatchActionResponse(
            requestId: action.requestId,
            success: success,
            error: success ? nil : "Action failed",
            updatedState: success ? getCurrentInboxState() : nil
        )

        sendResponse(response)
    }

    // MARK: - Helpers

    private func convertToWatchEmail(_ email: EmailCard) -> WatchEmail {
        WatchEmail(
            id: email.id,
            title: email.title,
            sender: email.sender?.name ?? "Unknown",
            senderInitial: email.sender?.initial ?? "?",
            timeAgo: email.timeAgo,
            priority: convertPriority(email.priority),
            archetype: email.type.rawValue,
            hpa: email.hpa,
            isUnread: email.state != .read,
            isUrgent: email.urgent ?? false
        )
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isWatchPaired = session.isPaired
            isWatchReachable = session.isReachable
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Handle action from watch
        Task { @MainActor in
            if let data = try? JSONSerialization.data(withJSONObject: message),
               let action = try? decoder.decode(WatchActionMessage.self, from: data) {
                await handleAction(action)
            }
        }
    }

    // Other delegate methods...
}
```

---

## watchOS Implementation

### WatchConnectivityManager (watchOS)

**File**: `Zer0Watch/Services/WatchConnectivityManager.swift` (watchOS target only)

```swift
import WatchConnectivity
import Combine

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    // MARK: - Published State

    @Published var inboxState: WatchInboxState?
    @Published var isIPhoneReachable: Bool = false
    @Published var lastSyncDate: Date?

    // MARK: - Private

    private var session: WCSession?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Initialization

    override init() {
        super.init()

        #if os(watchOS)
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        #endif

        // Load cached state
        loadCachedState()
    }

    // MARK: - Public API

    /// Execute action (archive, flag, etc.)
    func executeAction(_ action: WatchAction, emailId: String) async -> Bool {
        let message = WatchActionMessage(
            action: action,
            emailId: emailId,
            timestamp: Date(),
            requestId: UUID().uuidString
        )

        guard let session = session,
              session.isReachable else {
            // Queue for later
            queueAction(message)
            return false
        }

        // Send immediately
        guard let data = try? encoder.encode(message),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }

        return await withCheckedContinuation { continuation in
            session.sendMessage(dict, replyHandler: { response in
                continuation.resume(returning: true)
            }, errorHandler: { error in
                continuation.resume(returning: false)
            })
        }
    }

    /// Request fresh data from iPhone
    func requestInboxUpdate() {
        guard let session = session, session.isReachable else {
            return
        }

        let message = ["action": "requestInbox"]
        session.sendMessage(message, replyHandler: { _ in })
    }

    // MARK: - Caching

    private func loadCachedState() {
        if let data = UserDefaults.standard.data(forKey: "cachedInboxState"),
           let state = try? decoder.decode(WatchInboxState.self, from: data) {
            inboxState = state
        }
    }

    private func cacheState(_ state: WatchInboxState) {
        if let data = try? encoder.encode(state) {
            UserDefaults.standard.set(data, forKey: "cachedInboxState")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isIPhoneReachable = session.isReachable
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // Received inbox update from iPhone
        Task { @MainActor in
            if let data = try? JSONSerialization.data(withJSONObject: applicationContext),
               let state = try? decoder.decode(WatchInboxState.self, from: data) {
                inboxState = state
                cacheState(state)
                lastSyncDate = Date()
            }
        }
    }
}
```

---

## Message Protocol

### Message Types

| Type | Direction | Method | Urgency | Use Case |
|------|-----------|--------|---------|----------|
| **InboxUpdate** | iPhone → Watch | updateApplicationContext | Low | Periodic inbox sync |
| **ActionRequest** | Watch → iPhone | sendMessage | High | Archive, flag, etc. |
| **ActionResponse** | iPhone → Watch | replyHandler | High | Confirm action |
| **BulkSync** | iPhone → Watch | transferUserInfo | Low | Initial sync (50+ emails) |

### Message Schemas

#### 1. InboxUpdate (Context)
```json
{
  "unreadCount": 15,
  "urgentCount": 3,
  "emails": [
    {
      "id": "email-123",
      "title": "Quarterly Review",
      "sender": "Sarah Chen",
      "senderInitial": "SC",
      "timeAgo": "2h ago",
      "priority": "high",
      "archetype": "work",
      "hpa": "Schedule Meeting",
      "isUnread": true,
      "isUrgent": true
    }
  ],
  "lastSync": 1702345678.0,
  "syncedWithIPhone": true
}
```

#### 2. ActionRequest (Message)
```json
{
  "action": "archive",
  "emailId": "email-123",
  "timestamp": 1702345678.0,
  "requestId": "uuid-456"
}
```

#### 3. ActionResponse (Reply)
```json
{
  "requestId": "uuid-456",
  "success": true,
  "error": null,
  "updatedState": { /* InboxUpdate */ }
}
```

---

## Offline & Caching Strategy

### Watch Cache

**What to Cache**:
- Last 50 emails (WatchEmail models)
- Inbox counts (unread, urgent)
- Last sync timestamp

**Storage**: UserDefaults (fast access, ~50KB)

**Cache Invalidation**:
- After 24 hours (show "stale data" indicator)
- When new context received from iPhone
- On manual refresh

**Offline UX**:
```
┌────────────────────────┐
│  Inbox (Offline)       │
│  ⚠️ Updated 2h ago     │
│                        │
│  📧 Email 1            │
│  📧 Email 2            │
└────────────────────────┘
```

### Action Queue

**Watch → iPhone Actions (Offline)**:

When watch is offline, queue actions locally:

```swift
struct QueuedAction: Codable {
    let action: WatchActionMessage
    let queuedAt: Date
    let retryCount: Int
}
```

**Retry Strategy**:
1. iPhone becomes reachable → flush queue
2. Retry with exponential backoff (1s, 2s, 4s, 8s, 16s)
3. Max 5 retries, then show error

**User Feedback**:
```
┌────────────────────────┐
│  Email Archived        │
│  ⏳ Syncing with iPhone│
└────────────────────────┘
```

---

## Error Handling

### Error Categories

| Error | Cause | Handling |
|-------|-------|----------|
| **Not Reachable** | iPhone out of range | Queue action, retry later |
| **Session Inactive** | WCSession not activated | Show error, prompt restart |
| **Action Failed** | Server error, network | Show error, allow retry |
| **Timeout** | No response in 5s | Queue action, retry |
| **Invalid Data** | Corrupted message | Log error, skip |

### User-Facing Errors

```swift
enum WatchError: LocalizedError {
    case iPhoneNotReachable
    case actionFailed(String)
    case syncFailed
    case outdatedCache

    var errorDescription: String? {
        switch self {
        case .iPhoneNotReachable:
            return "iPhone is not reachable. Action will sync later."
        case .actionFailed(let reason):
            return "Action failed: \(reason)"
        case .syncFailed:
            return "Sync failed. Using cached data."
        case .outdatedCache:
            return "Data may be outdated. Sync with iPhone to refresh."
        }
    }
}
```

---

## Testing Strategy

### Unit Tests

**iOS Side**:
- [ ] Message encoding/decoding
- [ ] EmailCard → WatchEmail conversion
- [ ] Action queue management
- [ ] Error handling

**watchOS Side**:
- [ ] Cache save/load
- [ ] Action queuing
- [ ] State updates

### Integration Tests

**Paired Simulators**:
- [ ] Send inbox update (iPhone → Watch)
- [ ] Archive email (Watch → iPhone)
- [ ] Verify bidirectional sync
- [ ] Test offline behavior (unpair devices)
- [ ] Test reconnection (repair devices)

**Test Scenarios**:

| Scenario | Steps | Expected Result |
|----------|-------|-----------------|
| **Happy Path** | 1. iPhone sends inbox<br>2. Watch receives<br>3. Watch archives email<br>4. iPhone confirms | ✅ Email archived on both |
| **Offline Archive** | 1. Disconnect watch<br>2. Archive email<br>3. Reconnect | ✅ Action queued, then synced |
| **Stale Cache** | 1. Disconnect for 24h<br>2. Open watch app | ✅ Shows "outdated" indicator |
| **Concurrent Actions** | 1. Archive on iPhone<br>2. Archive different email on watch | ✅ Both succeed, no conflict |

---

## Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Message latency** | < 500ms | Time from sendMessage to reply |
| **Sync latency** | < 5 seconds | Archive on watch → iPhone updates |
| **Battery impact (iPhone)** | < 1% per hour | With watch paired, active sync |
| **Battery impact (Watch)** | < 3% per hour | With active complications |
| **Memory (iOS)** | < 10MB | WatchConnectivity overhead |
| **Memory (watchOS)** | < 20MB | Cached emails + app |
| **Cache size** | < 100KB | 50 emails cached |

---

## Implementation Checklist

### Week 3: Core Implementation
- [ ] Create WatchConnectivityManager (iOS)
- [ ] Create WatchConnectivityManager (watchOS)
- [ ] Define data models (WatchEmail, WatchInboxState, etc.)
- [ ] Implement message sending (iPhone → Watch)
- [ ] Implement action handling (Watch → iPhone)
- [ ] Add caching (watch side)
- [ ] Add action queue (watch side)

### Week 4: Polish & Testing
- [ ] Error handling
- [ ] Offline behavior
- [ ] Retry logic
- [ ] Integration tests (paired simulators)
- [ ] Performance profiling
- [ ] Battery impact measurement

---

## Dependencies

**Requires Before Implementation**:
- ✅ WatchEmail model defined
- ✅ Message protocol documented
- ⚪ watchOS app target created (Week 3, Day 1)
- ⚪ Production app integration points identified

**Requires Before Integration (Week 7)**:
- InboxViewModel provides data via callback
- EmailService handles watch actions
- AppLifecycleObserver initializes WatchConnectivity

---

## Future Enhancements (Post-MVP)

### Phase 2 (Week 9+)
- [ ] File transfer (attachments)
- [ ] Watch independence (sync via CloudKit)
- [ ] Rich notifications (interactive)
- [ ] Siri on watch (voice commands)

### Phase 3 (Week 12+)
- [ ] Conflict resolution (offline edits)
- [ ] Multi-watch support
- [ ] Cellular watch support (no iPhone nearby)

---

## References

- [WatchConnectivity Framework](https://developer.apple.com/documentation/watchconnectivity)
- [Building a watchOS App](https://developer.apple.com/documentation/watchos-apps)
- [App Group Sharing](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)

---

**Status**: ✅ Architecture Complete
**Next Step**: Implement WatchConnectivityManager (iOS + watchOS)
**ETA**: Week 3-4
