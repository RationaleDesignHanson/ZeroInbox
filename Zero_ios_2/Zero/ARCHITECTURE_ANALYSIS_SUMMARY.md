# Zero iOS Architecture Analysis Summary

**Date**: 2025-11-14  
**Analyzer**: Service Inventory Generation System  
**Scope**: Complete Services directory analysis (57 services)

---

## Executive Summary

Zero iOS implements a **layered, protocol-driven architecture** with clear separation of concerns across 6 service categories. The app centers on an **Action-First Model** where emails drive actionable modals/URLs through a unified routing system.

### Key Architectural Achievements

1. **Single Source of Truth**: ActionRegistry defines all actions with hybrid Swift + JSON support
2. **Clean Separation**: Admin services isolated from user-facing integrations
3. **Observable Pattern**: 15 services use SwiftUI @Published for reactive UI
4. **Protocol-Based DI**: EmailServiceProtocol, ShoppingCartServiceProtocol enable testing
5. **Data Persistence**: EmailPersistenceService + CardManagementService maintain state
6. **Cross-Framework Integration**: 7 device integrations (Calendar, Contacts, Reminders, etc.)

---

## Architecture Overview

### The Action Execution Pipeline

```
┌─────────────────────────────────────────────────┐
│ User Interaction (Swipe, Tap, Gesture)          │
└──────────────────┬──────────────────────────────┘
                   │
        ┌──────────▼───────────┐
        │ ActionRouter         │
        │ - Route action       │
        │ - Validate context   │
        │ - Track analytics    │
        └──────────┬────┬──────┘
                   │    │
        ┌──────────▼─┐  └─────────────────────┐
        │ IN_APP     │  GO_TO                  │
        │ Modal      │  External URL (Safari)  │
        └──────────┬─┘  └──────────────────────┘
                   │
        ┌──────────▼──────────────────────┐
        │ Integration Services             │
        │ - CalendarService                │
        │ - ContactsService                │
        │ - RemindersService               │
        │ - MessagesService                │
        │ - WalletService                  │
        └──────────────────────────────────┘
```

### Service Categories by Responsibility

1. **Core Services** (5): Route and execute actions
2. **Admin Services** (3): Feedback collection and model tuning
3. **Integration Services** (7): Device framework wrappers
4. **Data Services** (5): Persistence and state management
5. **Utility Services** (5): Cross-cutting concerns
6. **Specialized Services** (27+): Feature-specific implementations

---

## 1. Core Services: Action Routing

### ActionRouter (906 lines)
- **Type**: Observable singleton
- **Responsibility**: Single routing system for all modals/URLs
- **Key Feature**: Validates actions against registry before execution
- **Published State**: activeModal, showingModal, currentMode (Mail vs Ads)
- **Error Handling**: Shows toast notifications for invalid actions

### ActionRegistry (3,163 lines)
- **Type**: Singleton registry
- **Responsibility**: Define 100+ actions with metadata
- **Action Organization**: By priority (90-100 premium, 0-69 standard)
- **Mode Support**: Mail (78 actions), Ads (8 actions), Both (14 actions)
- **Hybrid System**: Looks up JSON first, falls back to Swift
- **Key Methods**: getAction(), validateAction(), isActionValidForMode()

### ActionLoader (379 lines) - Phase 3.1
- **Type**: JSON configuration loader
- **Responsibility**: Load action definitions from Config/Actions/*.json
- **Currently**: 15 actions in JSON, 85+ in Swift
- **Benefit**: Hot-reload actions without recompilation
- **Format**: Validates against action-schema.json

### EmailAPIService (27 KB)
- **Type**: Singleton implementing EmailServiceProtocol
- **Responsibility**: Backend API communication
- **Auth Methods**: Demo, Gmail OAuth, Microsoft OAuth
- **Key Operations**: fetchEmails, fetchThread, performAction, generateReply
- **Endpoints**: Cloud Run backend at /api prefix

### DataGenerator (242 KB)
- **Type**: Utility with static methods
- **Responsibility**: Generate 20+ mock emails per archetype
- **Strategy**: Try JSON fixtures → Fall back to hardcoded
- **Purpose**: UI testing, demo mode, development

---

## 2. Admin Services: Feedback & Tuning

### Service Trio

Three services form the admin feedback loop:

```
┌──────────────────────┐
│ Admin Dashboard      │
└──────────┬───────────┘
           │
    ┌──────┴──────────────────────────────┐
    │                                      │
┌───▼──────────────┐        ┌──────────────▼────┐
│ ActionFeedback   │        │ AdminFeedback      │
│ Service          │        │ Service            │
│                  │        │                    │
│ - Review actions │        │ - Review intent    │
│ - Approve/reject │        │ - Correct category │
│ - Confidence     │        │ - Notes            │
└──────────────────┘        └────────────────────┘
                                    │
                            ┌───────▼──────────┐
                            │ ModelTuning      │
                            │ RewardsService   │
                            │                  │
                            │ - Track feedback │
                            │ - Reward points  │
                            │ - Badges         │
                            └──────────────────┘
```

### ActionFeedbackService (25 KB)
- **Endpoint**: Cloud Run at emailshortform-classifier
- **Workflow**: Fetch email → Review suggested actions → Submit feedback
- **Comprehensive Corpus**: Load 1000s of training emails
- **Key Methods**: fetchNextEmailWithActions(), submitFeedback()

### AdminFeedbackService (10 KB)
- **Endpoint**: Same Cloud Run backend
- **Workflow**: Fetch email → Correct intent/category → Submit
- **Key Methods**: fetchNextEmail(), submitFeedback()

### ModelTuningRewardsService (6 KB)
- **Purpose**: Gamify admin feedback contribution
- **Tracking**: Reward points, levels, badges, milestones
- **Key Methods**: recordFeedback(), calculateRewards(), getRewardStats()

---

## 3. Integration Services: Device Frameworks

### Seven Framework Integrations

```
Device Frameworks
├── EventKit
│   ├── CalendarService        (Add calendar events)
│   ├── RemindersService       (Create reminders)
│   └── NotesIntegrationService (Create/link notes)
├── Contacts + ContactsUI
│   └── ContactsService        (Save contacts)
├── MessageUI
│   └── MessagesService        (Send SMS/iMessage)
├── PassKit
│   └── WalletService          (Add passes to Wallet)
└── Custom Backend
    └── ShoppingCartService    (E-commerce cart)
```

### Integration Pattern

Each service follows a consistent pattern:

```swift
// 1. Request permissions
CalendarService.shared.requestAccess() // async

// 2. Extract/prepare data from email
let eventDate = extractEventDate(from: card)
let location = extractLocation(from: card)

// 3. Create native iOS resource
CalendarService.shared.addEvent(
    title: eventTitle,
    startDate: eventDate,
    location: location
)

// 4. Handle callback
completion: { result in
    // Show success/error UI
}
```

### Usage Across Action Modals

```
Integration        Used In Modals
─────────────────────────────────────────────
CalendarService → ViewActivityModal
                → ViewActivityDetailsModal
                → PrepareForOutageModal
                → ViewOutageDetailsModal
                → AddReminderModal
                
ContactsService → SaveContactModal

RemindersService → AddReminderModal
                → PickupDetailsModal

MessagesService → SendMessageModal

WalletService → AddToWalletModal
```

---

## 4. Data Services: Persistence & State

### Five-Layer Data Architecture

```
┌─────────────────────────────┐
│ EmailAPIService             │  Backend
│ (fetchEmails)               │
└─────────────┬───────────────┘
              │
┌─────────────▼───────────────┐
│ EmailPersistenceService     │  Local Cache
│ (saveEmails, loadEmails)    │  (24 hours)
└─────────────┬───────────────┘
              │
┌─────────────▼───────────────┐
│ CardManagementService       │  State
│ (manage cards, filter)      │
└─────────────┬───────────────┘
              │
┌─────────────▼───────────────┐
│ SavedMailService            │  User Folders
│ (saved mail folders)        │
└─────────────┬───────────────┘
              │
┌─────────────▼───────────────┐
│ Views                       │  Display
│ (render email cards)        │
└─────────────────────────────┘
```

### CardManagementService (Observable)
- **State**: cards array, currentIndex
- **Filtering**: filteredCards(for:selectedArchetypes:)
- **Transition**: dismissCurrentCard(), undoLastDismissal()
- **Celebration**: getCelebrationType() for animations

### EmailPersistenceService
- **Storage**: Documents/EmailCache/emails.json
- **Expiration**: 24-hour TTL via UserDefaults timestamp
- **Deduplication**: mergeWithPersistedEmails() merges new + cached
- **Recovery**: Auto-cleanup on corrupt data

### SavedMailService (Observable @MainActor)
- **API**: Gateway-based saved-mail endpoints
- **Features**: Create/update/delete folders
- **Caching**: Load from cache, sync in background
- **State**: folders array, isLoading flag

### ContextualActionService
- **Analysis**: Parse email for action opportunities
- **Extraction**: trackingNumber, amount, date, etc.
- **Scoring**: rankActions() by relevance
- **Compound**: detectCompoundOpportunity() for multi-step flows

---

## 5. Utility Services: Cross-Cutting Concerns

### AnalyticsService
- **Pattern**: Batch + exponential backoff
- **Batching**: 10 events max, 30s interval
- **Backend**: POST localhost:8090/api/events/batch
- **Fallback**: Console logging if backend unavailable
- **Data Mode**: Separate "mock" and "real" streams
- **Retries**: 3 attempts with exponential backoff (2s, 4s, 8s)

### NetworkMonitor
- **Type**: @MainActor Observable singleton
- **Framework**: Network framework (low-level networking)
- **Published**: isConnected, connectionType, isExpensive
- **Monitoring**: Continuous network status updates
- **Usage**: API services check before requests

### HapticService
- **Patterns**: Impact (5 styles), Notification (3 types), Selection
- **Complex**: celebration() [triple tap], doubleTap()
- **Prepared**: prepareImpact() for low-latency interactions
- **Usage**: CardStackView swipe feedback, modal actions

### AppStateManager (Observable)
- **States**: splash, onboarding, feed, error
- **Loading**: isLoadingRealEmails, isClassifying with progress
- **Errors**: realEmailError with optional message
- **Undo**: lastAction for restoration
- **Computed**: isLoading, hasError helpers

### UserPreferencesService (Observable)
- **Purpose**: Persist user settings
- **Sync**: Store in UserDefaults or backend
- **Reactivity**: @Published properties for UI binding

---

## 6. Specialized Services (27+)

### By Functional Domain

**Email Operations** (4):
- SmartReplyService - AI-generated replies
- SummarizationService - Email summaries
- EmailSendingService - Compose/send
- DraftComposerService - Draft management

**Shopping** (2):
- ShoppingCartService - Cart management (protocol-based)
- ShoppingAutomationService - Automated flows

**Communication** (3):
- TemplateManager (Observable) - Reply templates
- SharedTemplateService (Observable) - Shared templates
- (MessagesService covered in Integration Services)

**Notifications & UI** (3):
- UndoToastManager (Observable) - Undo UI
- SnoozeService - Delay reminders
- LiveActivityManager - Live activities

**Configuration** (3):
- RemoteConfigService (Observable) - Feature flags
- ExperimentService (Observable) - A/B testing
- UserPermissions (Observable) - Capabilities

**Lifecycle** (1):
- AppLifecycleObserver (Observable) - App events

**Media & Documents** (3):
- AttachmentService - Email attachments
- SignedDocumentGenerator - PDF signing
- SiriShortcutsService - Siri integration

**Data Integrity** (2):
- DataIntegrityService - Validation
- ThreadingService - Email threads

**Classification** (2):
- ClassificationService - Intent classification
- VIPManager - Important contacts

**Subscriptions & Billing** (2):
- SubscriptionService - In-app purchases
- StoreKitService (Observable) - StoreKit integration

**Utility** (2):
- UnsubscribeService - Newsletter unsubscribe
- ActionPlaceholders - Context extraction

---

## Architecture Patterns

### 1. Singleton Pattern

**When Used**: Services with global state (ActionRouter, ActionRegistry, HapticService)

```swift
class ActionRouter: ObservableObject {
    static let shared = ActionRouter()
    private init() {}
}
```

**Pros**: Single instance, global access  
**Cons**: Hard to test (requires mocking)

### 2. ObservableObject + @Published

**When Used**: Services with mutable state (ActionRouter, AppStateManager)

```swift
class AppStateManager: ObservableObject {
    @Published var appState: AppState = .splash
}
```

**Trigger**: SwiftUI re-renders when @Published changes  
**Count**: 15 services use this pattern

### 3. Protocol-Based Dependency Injection

**When Used**: Services that need mock implementations (EmailServiceProtocol)

```swift
protocol EmailServiceProtocol {
    func fetchEmails(...) async throws -> [EmailCard]
}

class EmailAPIService: EmailServiceProtocol { }
class MockEmailService: EmailServiceProtocol { }
```

**Usage**:
```swift
class ServiceContainer {
    let emailService: EmailServiceProtocol
    
    init(emailService: EmailServiceProtocol? = nil) {
        self.emailService = emailService ?? EmailAPIService.shared
    }
}
```

### 4. Hybrid Configuration (Swift + JSON)

**When Used**: ActionRegistry + ActionLoader

```swift
func getAction(id: String) -> ActionConfig? {
    // 1. Try JSON (via ActionLoader)
    if let jsonAction = ActionLoader.shared.loadAction(id: id) {
        return jsonAction
    }
    // 2. Fall back to Swift
    return swiftActions[id]
}
```

**Benefits**: Hot-reload + type safety, gradual migration path

### 5. Context Placeholder Pattern

**When Used**: ActionRouter + ActionPlaceholders

```swift
// Validation fails for missing fields
if !result.isValid {
    // Extract from EmailCard
    finalContext = ActionPlaceholders.applyPlaceholders(...)
}
```

**Strategy**: Backend context → EmailCard fields → Defaults

### 6. MainActor Isolation

**When Used**: NetworkMonitor, SavedMailService

```swift
@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected = true  // Always main thread
}
```

**Benefit**: Compiler enforces main thread for UI updates

### 7. Batch + Exponential Backoff

**When Used**: AnalyticsService

```swift
pendingEvents: [[String: Any]] = []
maxBatchSize = 10          // Events per batch
batchInterval = 30.0       // Seconds
retryCount = 0
maxRetries = 3             // Backoff: 2s, 4s, 8s
```

---

## Dependency Analysis

### Service Coupling Matrix

```
High Coupling:
- ActionRouter ← ActionRegistry ← ActionLoader
- ViewModels ← EmailAPIService ← EmailPersistenceService
- CardStackView ← CardManagementService

Medium Coupling:
- ActionRouter ← AnalyticsService
- Modals ← Integration Services (CalendarService, etc.)

Low Coupling:
- Views ← HapticService (optional feedback)
- Views ← NetworkMonitor (optional offline UI)
```

### Admin vs User Service Separation

**Strictly Admin** (Views/Admin/):
- ActionFeedbackService
- AdminFeedbackService
- ModelTuningRewardsService

**Strictly User-Facing** (Views/ActionModules/):
- CalendarService
- ContactsService
- RemindersService
- MessagesService
- WalletService

**Shared Core** (No separation):
- ActionRouter, ActionRegistry, EmailAPIService, CardManagementService

---

## Key Metrics

| Metric | Value |
|--------|-------|
| Total Services | 57 |
| Observable Services | 15 |
| Singleton Services | 35+ |
| Protocol-Based Services | 2 (EmailServiceProtocol, ShoppingCartServiceProtocol) |
| Action Modals | 46 |
| Total Actions | 100+ |
| Mail-only Actions | 78 |
| Ads-only Actions | 8 |
| Cross-mode Actions | 14 |
| Device Integrations | 7 (Calendar, Contacts, Reminders, Messages, Wallet, Notes, Custom) |
| JSON-Configured Actions | 15 |
| Swift-Defined Actions | 85+ |

---

## Strengths

1. **Clear Separation of Concerns**: Each service has single responsibility
2. **Scalable Action System**: 100+ actions extensible via JSON or Swift
3. **Persistent State**: Doesn't lose data on app close/reopen
4. **Admin Isolation**: Feedback services separate from user flows
5. **Device Integration**: Consistent pattern across all frameworks
6. **Observable Pattern**: Reactive UI updates via @Published
7. **Protocol-Based DI**: Testable with mock implementations
8. **Hybrid Configuration**: Gradual Swift → JSON migration path

---

## Areas for Improvement

1. **ActionLoader Integration**: 85+ actions still in Swift, migrate to JSON
2. **Service Locator Anti-Pattern**: Heavy singleton usage could use more DI
3. **Error Handling**: Could standardize error types across services
4. **Testing**: Some services (ActionRouter, ActionRegistry) hard to unit test
5. **Documentation**: Inline code comments could be more comprehensive
6. **Lifecycle Management**: No explicit service initialization/teardown

---

## Recommendations

### Short Term
1. Migrate 85 Swift actions to JSON (Phase 3.2)
2. Create ServiceContainer factory for all services
3. Add unit tests for ActionRegistry + ActionRouter
4. Document context placeholder extraction logic

### Medium Term
1. Add observability for service performance
2. Implement service health checks
3. Create service dependency resolver
4. Add middleware pattern for analytics/logging

### Long Term
1. Move to service mesh architecture
2. Implement service composition over inheritance
3. Add async/await throughout (already started)
4. Create service registry for dynamic loading

---

## Related Documentation

- **Full Details**: `/SERVICE_INVENTORY.md` (1,965 lines)
- **Quick Reference**: `/SERVICE_QUICK_REFERENCE.md` (table format)
- **Routing System**: `/ROUTING_ARCHITECTURE.md` (action execution)
- **Core Service**: `/Services/ActionRegistry.swift` (3,163 lines)
- **Routing Service**: `/Services/ActionRouter.swift` (906 lines)

---

**Document Version**: 1.0  
**Created**: 2025-11-14  
**Analysis Depth**: Comprehensive (all 57 services)  
**Status**: Complete and ready for team review
