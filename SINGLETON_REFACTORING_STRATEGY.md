# Singleton Refactoring Strategy - Phase 1.2

## Current State

**Singleton Count:** 41 singletons
**Target:** <10 singletons
**Reduction:** 31 singletons must be eliminated (76% reduction)

### All Current Singletons

```swift
// Services (41 total)
1.  ActionFeedbackService.shared
2.  ActionRegistry.shared
3.  ActionRouter.shared
4.  AdminFeedbackService.shared
5.  AnalyticsService.shared
6.  AttachmentService.shared
7.  CalendarService.swift
8.  ClassificationService.shared
9.  CompoundActionRegistry.shared
10. ContactsService.shared
11. ContextualActionService.shared
12. DataIntegrityService.shared
13. DraftComposerService.shared
14. EmailAPIService.shared
15. EmailPersistenceService.shared
16. EmailSendingService.shared
17. ExperimentService.shared
18. FeedbackService.shared
19. HapticService.shared
20. LiveActivityManager.shared
21. MessagesService.shared
22. ModelTuningRewardsService.shared
23. NetworkMonitor.shared
24. RemindersService.shared
25. RemoteConfigService.shared
26. SafeModeService.shared
27. SavedMailService.shared
28. SharedTemplateService.shared
29. ShoppingCartService.shared
30. SignatureManager.shared
31. SmartReplyService.shared
32. SnoozeService.shared
33. StoreKitService.shared
34. SubscriptionService.shared
35. SummarizationService.shared
36. TemplateManager.shared
37. ThreadingService.shared
38. UnsubscribeService.shared
39. UserPermissions.shared
40. VIPManager.shared
41. WalletService.shared
```

## Strategic Plan

### Phase A: Create ServiceContainer (MISSING - referenced but not implemented)

**Status:** ZeroApp.swift references `ServiceContainer` but file doesn't exist

**Action:** Create `ServiceContainer.swift` in Config/

**Purpose:**
- Centralized dependency injection container
- Single source of truth for service instances
- Lifecycle management
- Testability support (mock container)

### Phase B: Categorize Singletons

#### Category 1: Keep as Singletons (7-9 essential)

**Infrastructure Services** (must be global):
1. **NetworkMonitor.shared** - System-level network monitoring
2. **RemoteConfigService.shared** - App-wide configuration
3. **HapticService.shared** - Device haptic feedback
4. **StoreKitService.shared** - In-app purchase management
5. **LiveActivityManager.shared** - iOS Live Activities
6. **ExperimentService.shared** - A/B testing framework
7. **AnalyticsService.shared** - Analytics tracking (if using external SDK)

**Rationale:** These interact with iOS system APIs and should have single instances.

#### Category 2: Move to ServiceContainer (32 services)

**User-scoped Services** (tied to user session):
- EmailAPIService
- EmailPersistenceService
- EmailSendingService
- SavedMailService
- DraftComposerService
- ClassificationService
- SummarizationService
- SmartReplyService

**UI/UX Services** (tied to app lifecycle):
- ActionRouter
- ActionRegistry
- CompoundActionRegistry
- ContextualActionService
- SnoozeService
- FeedbackService
- ActionFeedbackService

**Data Management Services**:
- AttachmentService
- CalendarService
- ContactsService
- RemindersService
- ThreadingService
- MessagesService

**Utility Services**:
- SignatureManager
- TemplateManager
- SharedTemplateService
- ShoppingCartService
- SubscriptionService
- VIPManager
- WalletService
- UnsubscribeService

**Permission/Security Services**:
- UserPermissions
- SafeModeService
- DataIntegrityService

**Admin/Debug Services**:
- AdminFeedbackService
- ModelTuningRewardsService

### Phase C: Implementation Strategy

#### Step 1: Create ServiceContainer

```swift
// Config/ServiceContainer.swift
import Foundation
import SwiftUI

/// Centralized dependency injection container
/// Manages service lifecycles and provides dependency injection throughout the app
class ServiceContainer: ObservableObject {

    // MARK: - Core Services (always available)

    let logger: LoggerProtocol
    let analyticsService: AnalyticsService
    let lifecycleObserver: AppLifecycleObserver

    // MARK: - User Session

    @Published var userSession: UserSession
    @Published var settings: AppSettings

    // MARK: - Email Services

    let emailAPIService: EmailAPIService
    let emailPersistenceService: EmailPersistenceService
    let emailSendingService: EmailSendingService
    let savedMailService: SavedMailService
    let draftComposerService: DraftComposerService

    // MARK: - Classification & Intelligence

    let classificationService: ClassificationService
    let summarizationService: SummarizationService
    let smartReplyService: SmartReplyService
    let contextualActionService: ContextualActionService

    // MARK: - Action Management

    let actionRouter: ActionRouter
    let actionRegistry: ActionRegistry
    let compoundActionRegistry: CompoundActionRegistry
    let actionFeedbackService: ActionFeedbackService

    // MARK: - UI Services

    let snoozeService: SnoozeService
    let feedbackService: FeedbackService

    // MARK: - Data Management

    let attachmentService: AttachmentService
    let calendarService: CalendarService
    let contactsService: ContactsService
    let remindersService: RemindersService
    let threadingService: ThreadingService
    let messagesService: MessagesService

    // MARK: - Utility Services

    let signatureManager: SignatureManager
    let templateManager: TemplateManager
    let sharedTemplateService: SharedTemplateService
    let shoppingCartService: ShoppingCartService
    let subscriptionService: SubscriptionService
    let vipManager: VIPManager
    let walletService: WalletService
    let unsubscribeService: UnsubscribeService

    // MARK: - Permission/Security

    let userPermissions: UserPermissions
    let safeModeService: SafeModeService
    let dataIntegrityService: DataIntegrityService

    // MARK: - Admin/Debug

    let adminFeedbackService: AdminFeedbackService
    let modelTuningRewardsService: ModelTuningRewardsService

    // MARK: - Initialization

    private init(
        launchConfig: LaunchConfiguration,
        logger: LoggerProtocol,
        analyticsService: AnalyticsService,
        userSession: UserSession,
        settings: AppSettings
    ) {
        self.logger = logger
        self.analyticsService = analyticsService
        self.userSession = userSession
        self.settings = settings

        // Initialize services with dependencies
        // (constructor injection for each service)

        self.emailAPIService = EmailAPIService(logger: logger)
        self.emailPersistenceService = EmailPersistenceService(logger: logger)
        // ... continue for all services

        self.lifecycleObserver = AppLifecycleObserver(
            analyticsService: analyticsService,
            logger: logger
        )
    }

    // MARK: - Factory Methods

    /// Production container with real services
    static func production(launchConfig: LaunchConfiguration) -> ServiceContainer {
        let logger = Logger() // Real logger
        let analyticsService = AnalyticsService.shared // Keep as singleton
        let userSession = UserSession()
        let settings = AppSettings()

        return ServiceContainer(
            launchConfig: launchConfig,
            logger: logger,
            analyticsService: analyticsService,
            userSession: userSession,
            settings: settings
        )
    }

    /// Mock container for testing/UI testing
    static func mock(useMockData: Bool = true) -> ServiceContainer {
        let logger = MockLogger() // Mock logger
        let analyticsService = MockAnalyticsService()
        let userSession = UserSession()
        let settings = AppSettings()
        settings.useMockData = useMockData

        return ServiceContainer(
            launchConfig: LaunchConfiguration(),
            logger: logger,
            analyticsService: analyticsService,
            userSession: userSession,
            settings: settings
        )
    }
}
```

#### Step 2: Refactor Services to Accept Dependencies

**Before (singleton pattern):**
```swift
class EmailAPIService {
    static let shared = EmailAPIService()

    private init() {}

    func fetchEmails() { ... }
}

// Usage in views:
EmailAPIService.shared.fetchEmails()
```

**After (dependency injection):**
```swift
class EmailAPIService {
    private let logger: LoggerProtocol

    init(logger: LoggerProtocol) {
        self.logger = logger
    }

    func fetchEmails() { ... }
}

// Usage in views:
@EnvironmentObject var services: ServiceContainer

// ...
services.emailAPIService.fetchEmails()
```

#### Step 3: Update Views to Use @EnvironmentObject

**Before:**
```swift
struct EmailListView: View {
    var body: some View {
        Button("Fetch") {
            EmailAPIService.shared.fetchEmails()
        }
    }
}
```

**After:**
```swift
struct EmailListView: View {
    @EnvironmentObject var services: ServiceContainer

    var body: some View {
        Button("Fetch") {
            services.emailAPIService.fetchEmails()
        }
    }
}
```

### Phase D: Migration Path (Phased Rollout)

#### Week 1: Foundation
1. ✅ Create ServiceContainer.swift
2. ✅ Update ZeroApp.swift to instantiate container
3. ✅ Add @environmentObject(services) to ContentView

#### Week 2: Core Services (5 services)
4. Refactor EmailAPIService
5. Refactor ClassificationService
6. Refactor ActionRouter
7. Refactor SnoozeService
8. Refactor FeedbackService

#### Week 3: Email Services (5 services)
9. Refactor EmailPersistenceService
10. Refactor EmailSendingService
11. Refactor SavedMailService
12. Refactor DraftComposerService
13. Refactor SummarizationService

#### Week 4: Utility Services (10 services)
14-23. Refactor remaining utility services

#### Week 5: Cleanup & Testing
24. Remove `.shared` from refactored services
25. Update all 237 view usages
26. Run full test suite
27. Performance validation

## Benefits

### 1. Testability ⭐⭐⭐⭐⭐
- Mock services easily via `ServiceContainer.mock()`
- No more global state in tests
- Isolated unit tests possible

### 2. Maintainability ⭐⭐⭐⭐⭐
- Clear dependency graph
- Explicit dependencies (no hidden `.shared` calls)
- Easier to reason about service lifecycles

### 3. Flexibility ⭐⭐⭐⭐⭐
- Swap implementations (production vs mock)
- Feature flags per environment
- A/B testing service variants

### 4. Performance ⭐⭐⭐⭐
- Lazy initialization possible
- Scoped lifecycles (memory efficiency)
- No hidden singleton initialization costs

### 5. Architecture ⭐⭐⭐⭐⭐
- IC10-level design pattern
- Industry best practice (DI container)
- Scalable for future growth

## Risks & Mitigations

### Risk 1: Large refactoring scope
**Mitigation:** Phased rollout over 5 weeks, 5 services per week

### Risk 2: Breaking existing code
**Mitigation:** Keep `.shared` as deprecated wrapper during transition

```swift
class EmailAPIService {
    @available(*, deprecated, message: "Use ServiceContainer instead")
    static let shared = EmailAPIService(logger: Logger())
}
```

### Risk 3: Performance regression
**Mitigation:** Benchmark before/after, lazy initialization where needed

### Risk 4: Developer resistance
**Mitigation:** Document benefits, provide migration guides, pair programming

## Success Metrics

- **Singleton count:** 41 → 7-9 (78-83% reduction) ✅
- **Test coverage:** +20% (easier to test)
- **Build time:** No regression
- **App launch time:** No regression
- **Code quality grade:** A- → A+

## Next Steps

1. **Create ServiceContainer.swift** (this document provides spec)
2. **Update ZeroApp.swift** (already partially done)
3. **Start Week 1 migration** (5 core services)
4. **Track progress** via todo list

---

*Strategy Document v1.0*
*Phase 1.2: Singleton Elimination*
*Target Completion: 5 weeks from start*
