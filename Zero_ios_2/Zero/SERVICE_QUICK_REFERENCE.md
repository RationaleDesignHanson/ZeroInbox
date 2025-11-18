# Zero iOS Service Quick Reference

**Updated**: 2025-11-14  
**57 Total Services Documented**

---

## Core Services (5)

| Service | File | Type | Purpose |
|---------|------|------|---------|
| **ActionRouter** | `/Services/ActionRouter.swift` | Observable Singleton | Route actions to modals/URLs |
| **ActionRegistry** | `/Services/ActionRegistry.swift` | Singleton | Define 100+ actions (Mail/Ads) |
| **ActionLoader** | `/Services/ActionLoader.swift` | Singleton | Load actions from JSON config |
| **EmailAPIService** | `/Services/EmailAPIService.swift` | Singleton | Email backend API communication |
| **DataGenerator** | `/Services/DataGenerator.swift` | Static Utility | Generate mock email data |

---

## Admin Services (3)

| Service | File | Type | Purpose |
|---------|------|------|---------|
| **ActionFeedbackService** | `/Services/ActionFeedbackService.swift` | Singleton | Admin action approval workflow |
| **AdminFeedbackService** | `/Services/AdminFeedbackService.swift` | Singleton | Classification review feedback |
| **ModelTuningRewardsService** | `/Services/ModelTuningRewardsService.swift` | Singleton | Track contributor rewards |

---

## Integration Services (7)

| Service | File | Framework | Purpose |
|---------|------|-----------|---------|
| **CalendarService** | `/Services/CalendarService.swift` | EventKit | Create calendar events |
| **ContactsService** | `/Services/ContactsService.swift` | Contacts | Save/manage contacts |
| **RemindersService** | `/Services/RemindersService.swift` | EventKit | Create reminders |
| **MessagesService** | `/Services/MessagesService.swift` | MessageUI | Send SMS/iMessage |
| **WalletService** | `/Services/WalletService.swift` | PassKit | Add passes to Wallet |
| **ShoppingCartService** | `/Services/ShoppingCartService.swift` | – | Manage shopping cart |
| **NotesIntegrationService** | `/Services/NotesIntegrationService.swift` | EventKit | Create/link notes |

---

## Data Services (5)

| Service | File | Type | Purpose |
|---------|------|------|---------|
| **EmailData** | `/Services/EmailData.swift` | Extension | Extended email examples (20+) |
| **EmailPersistenceService** | `/Services/EmailPersistenceService.swift` | Singleton | Persist emails to disk |
| **CardManagementService** | `/Services/CardManagementService.swift` | Observable | Manage card state & filtering |
| **SavedMailService** | `/Services/SavedMailService.swift` | Observable (@MainActor) | User-created folders |
| **ContextualActionService** | `/Services/ContextualActionService.swift` | Singleton | Smart action suggestions |

---

## Utility Services (5)

| Service | File | Type | Purpose |
|---------|------|------|---------|
| **AnalyticsService** | `/Services/AnalyticsService.swift` | Singleton | Event tracking + backend sync |
| **NetworkMonitor** | `/Services/NetworkMonitor.swift` | Observable (@MainActor) | Network connectivity tracking |
| **HapticService** | `/Services/HapticService.swift` | Singleton | Haptic feedback patterns |
| **AppStateManager** | `/Services/AppStateManager.swift` | Observable | Global app state + loading |
| **UserPreferencesService** | `/Services/UserPreferencesService.swift` | Observable | User settings management |

---

## Specialized Services (27+)

### Email Operations
- **SmartReplyService** - AI reply suggestions
- **SummarizationService** - Email summarization
- **EmailSendingService** - Compose/send emails
- **DraftComposerService** - Draft handling

### Shopping & E-Commerce
- **ShoppingAutomationService** - Automated shopping workflows

### Communication & Messaging
- **TemplateManager** - Reply templates (ObservableObject)
- **SharedTemplateService** - Shared templates (ObservableObject)

### Notifications & UI
- **UndoToastManager** - Undo UI management (ObservableObject)
- **SnoozeService** - Email snooze functionality
- **LiveActivityManager** - Live activity updates

### Configuration & Experimentation
- **RemoteConfigService** - Feature flags (ObservableObject)
- **ExperimentService** - A/B testing (ObservableObject)
- **UserPermissions** - Capabilities & permissions (ObservableObject)

### Onboarding & Lifecycle
- **AppLifecycleObserver** - App launch/background (ObservableObject)

### Media & Documents
- **AttachmentService** - Email attachment handling
- **SignedDocumentGenerator** - Generate signed PDFs
- **SiriShortcutsService** - Siri integration

### Data Integrity & Threading
- **DataIntegrityService** - Data validation
- **ThreadingService** - Email thread management

### Classification & Insights
- **ClassificationService** - Email classification
- **VIPManager** - Important contact tracking

### Subscriptions & Billing
- **SubscriptionService** - In-app purchases
- **StoreKitService** - StoreKit integration (ObservableObject)

### Utility & Unsubscribe
- **UnsubscribeService** - Newsletter unsubscribe
- **ActionPlaceholders** - Context field extraction

---

## Service Dependencies

### Primary Dependencies
```
ActionRouter → ActionRegistry → ActionLoader
ActionRouter → ActionPlaceholders
ActionRouter → AnalyticsService

ViewModels → EmailAPIService
ViewModels → EmailPersistenceService
ViewModels → CardManagementService

Action Modals → CalendarService, ContactsService, etc.

Admin Views → ActionFeedbackService, AdminFeedbackService
```

### Data Flow
```
Backend (EmailAPIService)
  ↓
EmailPersistenceService (cache)
  ↓
CardManagementService (state)
  ↓
Views (display)
```

### Action Execution Flow
```
User Swipe
  ↓
ActionRouter.executeAction()
  ↓
ActionRegistry.getAction()
  ↓
ActionLoader.loadAction() → JSON or Swift
  ↓
Action validation & context placeholder
  ↓
Modal displayed or URL opened
  ↓
AnalyticsService.trackAction()
```

---

## Observable Services (15)

**Services that trigger SwiftUI re-renders on @Published changes**:

1. ActionRouter
2. AppStateManager
3. CardManagementService
4. SavedMailService
5. NetworkMonitor
6. UserPreferencesService
7. AppLifecycleObserver
8. TemplateManager
9. SharedTemplateService
10. RemoteConfigService
11. ExperimentService
12. StoreKitService
13. UserPermissions
14. RemoteConfigService
15. UndoToastManager

---

## DI & Instantiation Patterns

### Singleton Pattern
```swift
class ActionRouter: ObservableObject {
    static let shared = ActionRouter()
    private init() {}
}
```

### Dependency Injection via ServiceContainer
```swift
class ServiceContainer: ObservableObject {
    let emailService: EmailServiceProtocol
    let shoppingCartService: ShoppingCartServiceProtocol
    
    init(emailService: EmailServiceProtocol? = nil, ...) {
        self.emailService = emailService ?? EmailAPIService.shared
    }
}
```

### Protocol-Based Abstraction
```swift
protocol EmailServiceProtocol {
    func fetchEmails(...) async throws -> [EmailCard]
}

// Real implementation
class EmailAPIService: EmailServiceProtocol { ... }

// Mock for testing
class MockEmailService: EmailServiceProtocol { ... }
```

---

## Usage Locations

### Core Services
- **ActionRouter** → ContentView, ActionFeedbackView
- **ActionRegistry** → ActionRouter, ActionPlaceholders
- **EmailAPIService** → ViewModels, SplashView
- **DataGenerator** → CardStackView, MockDataLoader

### Admin Services
- **ActionFeedbackService** → ActionFeedbackView, ModelTuningView
- **AdminFeedbackService** → AdminFeedbackView, ModelTuningView
- **ModelTuningRewardsService** → ModelTuningView

### Integration Services
- **CalendarService** → AddReminderModal, ViewActivityModal, etc. (5 modals)
- **ContactsService** → SaveContactModal
- **RemindersService** → AddReminderModal, PickupDetailsModal
- **MessagesService** → SendMessageModal
- **WalletService** → AddToWalletModal

### Data Services
- **EmailPersistenceService** → EmailViewModel, AppStateManager
- **CardManagementService** → CardStackView, EmailViewModel
- **SavedMailService** → SaveForLaterModal, FolderDetailView

### Utility Services
- **AnalyticsService** → ActionRouter, ContentView, ViewModels
- **NetworkMonitor** → API services, Views
- **HapticService** → CardStackView, Action modals
- **AppStateManager** → SplashView, Feed views

---

## Actions by Mode

### Mail Mode (78 actions)
- **Shipping**: track_package, view_pickup_details, etc.
- **Payment**: pay_invoice, update_payment, etc.
- **Communication**: quick_reply, schedule_meeting, etc.
- **Document**: view_document, sign_form, etc.

### Ads Mode (8 actions)
- Specialized ad interactions
- Ad-specific flows

### Both Modes (14 actions)
- Cross-mode operations

---

## Key Statistics

| Metric | Count |
|--------|-------|
| Total Services | 57 |
| Observable Services | 15 |
| Singleton Services | 35+ |
| Action Modals | 46 |
| Total Actions | 100+ |
| Mail-only Actions | 78 |
| Ads-only Actions | 8 |
| Cross-mode Actions | 14 |
| Lines of Code (Service Inventory) | 1,965 |

---

## Quick Links

- **Full Documentation**: `/SERVICE_INVENTORY.md`
- **Routing Architecture**: `/ROUTING_ARCHITECTURE.md`
- **Action Registry**: `/Services/ActionRegistry.swift`
- **Action Router**: `/Services/ActionRouter.swift`
- **Email API**: `/Services/EmailAPIService.swift`

---

**Version**: 1.0  
**Created**: 2025-11-14  
**Format**: Quick reference table format
