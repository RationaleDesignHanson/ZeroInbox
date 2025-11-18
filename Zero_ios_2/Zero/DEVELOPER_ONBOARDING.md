# Developer Onboarding Guide

**Project**: Zero iOS
**Last Updated**: 2025-11-14
**Build Status**: ✅ BUILD SUCCEEDED
**Target**: iOS 15.0+
**Language**: Swift 5.9

Welcome to the Zero iOS development team! This guide will help you get up to speed quickly.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Quick Start](#quick-start)
3. [Architecture Overview](#architecture-overview)
4. [Project Structure](#project-structure)
5. [Core Systems](#core-systems)
6. [Common Tasks](#common-tasks)
7. [Testing & Debugging](#testing--debugging)
8. [Best Practices](#best-practices)
9. [Resources](#resources)

---

## Project Overview

### What is Zero?

Zero is an **intelligent email management app** for iOS that:
- Transforms emails into swipeable cards (Tinder-style interface)
- Automatically classifies emails as **Mail** (important) or **Ads** (promotional)
- Suggests contextual actions (pay invoice, track package, RSVP, etc.)
- Provides one-tap actions to complete email tasks
- Uses AI/ML for classification and action suggestion

### Tech Stack

- **Language**: Swift 5.9 (100% Swift, no Objective-C)
- **UI Framework**: SwiftUI (modern declarative UI)
- **Architecture**: MVVM + Service Layer
- **Routing**: ActionRouter (v1.2) - Single routing system
- **Backend**: Google Cloud Run (classifier API)
- **Analytics**: PostHog
- **Payment**: StoreKit 2
- **Dependencies**: Minimal external dependencies

### Key Features

1. **Card-Based Interface**: Swipe through emails like Tinder
2. **Smart Classification**: AI categorizes emails (Mail vs Ads)
3. **Action Suggestions**: 100+ contextual actions
4. **Device Integrations**: Calendar, Contacts, Wallet, Reminders
5. **Admin ML Training**: Tools for improving AI accuracy

---

## Quick Start

### Prerequisites

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- iOS Simulator or physical device
- Git

### Setup (5 minutes)

```bash
# 1. Clone the repository
git clone <repository-url>
cd Zero_ios_2/Zero

# 2. Open in Xcode
open Zero.xcodeproj

# 3. Select a simulator
# Xcode > Product > Destination > iPhone 16 (or any iOS 15+ simulator)

# 4. Build and run
# Xcode > Product > Run (⌘R)
```

### First Build

Expected output:
```bash
** BUILD SUCCEEDED **
Files Compiled: 246 Swift files
Warnings: 0
Errors: 0
```

Build time: ~45-60 seconds on modern Mac

### Verify Installation

1. App launches in simulator ✅
2. Swipe through sample emails ✅
3. Tap an action button (Calendar, Pay Invoice, etc.) ✅
4. See modal open with action details ✅

If all 4 work, you're ready to develop!

---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│                   SwiftUI Views                      │
│  (ContentView, CardSwipeView, ActionModals)         │
└────────────────────┬────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────┐
│                  ActionRouter (v1.2)                 │
│  • Validates actions                                 │
│  • Handles context & placeholders                    │
│  • Routes to correct modal                           │
└────────────────────┬────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────┐
│                 ActionRegistry (3,196 lines)         │
│  • 100+ action definitions                           │
│  • Hybrid Swift + JSON configuration                 │
│  • Priority, availability, permissions               │
└────────────────────┬────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────┐
│              Service Layer (57 services)             │
│  • EmailAPIService - Backend API                     │
│  • CalendarService - EventKit integration            │
│  • AnalyticsService - PostHog tracking               │
│  • etc.                                              │
└─────────────────────────────────────────────────────┘
```

### Architecture Principles

1. **MVVM**: Views bind to ObservableObject services
2. **Single Responsibility**: Each service has one clear purpose
3. **Protocol-Based**: Services use protocols for testability
4. **Reactive**: @Published properties drive UI updates
5. **Singleton Services**: Shared state via `.shared`

### Key Architectural Decisions

**Why Single Routing System?** (Week 2 cleanup)
- Previously had 2 routing systems (ModalRouter v1.0 + ActionRouter v1.2)
- Consolidated to ActionRouter v1.2 only
- Deleted 1,587 lines of legacy ModalRouter code
- **See**: `ROUTING_ARCHITECTURE.md` for details

**Why Separate Admin Services?** (Week 3 analysis)
- Admin ML training tools isolated from user-facing features
- Security: Admin endpoints not exposed to regular users
- Maintainability: Changes to admin tools don't affect users
- **See**: `FEEDBACK_SERVICES_ANALYSIS.md` for details

---

## Project Structure

### Top-Level Directory

```
Zero/
├── Zero.xcodeproj/          # Xcode project file
├── Services/                # 57 service files (business logic)
├── Views/                   # SwiftUI views (UI)
│   ├── Admin/               # Admin-only ML training views
│   ├── ActionModals/        # 46 action modal views
│   ├── Components/          # Reusable UI components
│   └── ContentView.swift    # Root view
├── Models/                  # Data models (EmailCard, etc.)
├── Config/                  # Configuration files
│   ├── Actions/             # JSON action definitions
│   └── DesignTokens.swift   # Design system
├── Utils/                   # Utility functions
├── Assets.xcassets/         # Images, colors, icons
└── Documentation/           # Architecture docs (you are here!)
```

### Important Files

| File | Lines | Purpose |
|------|-------|---------|
| `Services/ActionRegistry.swift` | 3,196 | Defines all 100+ actions |
| `Services/ActionRouter.swift` | 906 | Routes actions to modals |
| `Services/EmailAPIService.swift` | 668 | Backend API communication |
| `Services/DataGenerator.swift` | 6,132 | Sample data for development |
| `Views/ContentView.swift` | ~500 | Root view + routing logic |
| `Models/EmailCard.swift` | ~300 | Email card data model |

### Finding Things Quickly

**Use Xcode's Open Quickly** (⌘⇧O):
- Type `ActionRegistry` to find action definitions
- Type `EmailAPIService` to find API calls
- Type `ContentView` to find root view

**Use Xcode's Find Navigator** (⌘⇧F):
- Search for imports: `import CalendarService`
- Search for function calls: `ActionRouter.shared.executeAction`
- Search for properties: `@Published var cards`

---

## Core Systems

### 1. Email Card System

**File**: `Models/EmailCard.swift`

**Structure**:
```swift
struct EmailCard: Identifiable {
    let id: String
    let title: String
    let summary: String
    let sender: EmailSender?
    let type: CardType           // .mail or .ads
    let suggestedActions: [EmailAction]?
    let company: Company?
    let kid: Kid?
    let timeAgo: String
}
```

**Lifecycle**:
1. Fetched from backend via `EmailAPIService.fetchEmails()`
2. Stored in `EmailData.shared.cards` (@Published array)
3. Displayed in `CardSwipeView`
4. Swiped left (action) or right (dismiss)
5. Removed from deck when actioned

**Sample Data**:
- Development uses `DataGenerator.swift` (6,132 lines)
- Generates realistic sample emails with actions
- See `DataGenerator.generateSampleCard(type:)` for examples

### 2. Action System

**Files**:
- `Services/ActionRegistry.swift` (3,196 lines) - Action definitions
- `Services/ActionRouter.swift` (906 lines) - Routing logic
- `Services/ActionLoader.swift` (379 lines) - JSON configuration

**Action Flow**:
```
1. User swipes left on card
   ↓
2. ContentView calls ActionRouter.executeAction()
   ↓
3. ActionRouter validates action via ActionRegistry
   ↓
4. ActionRouter checks context (required data present?)
   ↓
5. ActionRouter opens modal (GO_TO or IN_APP)
   ↓
6. User completes action in modal
   ↓
7. Analytics tracked via AnalyticsService
```

**Action Types**:
- **IN_APP**: Opens modal within app (46 modal types)
- **GO_TO**: Opens external URL (mailto, tel, https)

**Action Configuration**:
```swift
// Swift-based (ActionRegistry.swift)
ActionConfig(
    actionId: "pay_invoice",
    displayName: "Pay Invoice",
    actionType: .IN_APP,
    mode: .mail,
    modalComponent: "payment_flow",
    requiredContextKeys: ["amount", "recipient"],
    priority: .high
)

// JSON-based (Config/Actions/mail-actions.json)
{
    "actionId": "track_package",
    "displayName": "Track Package",
    "actionType": "IN_APP",
    "mode": "mail",
    "priority": 85
}
```

**See**: `ROUTING_ARCHITECTURE.md` for complete action system documentation

### 3. Service Layer

**Files**: `Services/*.swift` (57 services)

**Service Categories**:

1. **Core Services** (5):
   - `ActionRegistry` - Action definitions
   - `ActionRouter` - Action routing
   - `ActionLoader` - JSON action loading
   - `EmailAPIService` - Backend API
   - `DataGenerator` - Sample data

2. **Integration Services** (7):
   - `CalendarService` - EventKit (add events)
   - `ContactsService` - Contacts framework
   - `RemindersService` - EventKit reminders
   - `WalletService` - PassKit (add passes)
   - `ShoppingCartService` - Shopping actions
   - `MessagesService` - MessageUI (compose SMS)
   - `NotesIntegrationService` - Notes app

3. **Admin Services** (3):
   - `ActionFeedbackService` - Admin action AI training
   - `AdminFeedbackService` - Admin classification AI training
   - `ModelTuningRewardsService` - Admin rewards

4. **Data Services** (5):
   - `EmailData` - Email card state
   - `EmailPersistenceService` - Local storage
   - `CardManagementService` - Card lifecycle
   - `SavedMailService` - Saved/bookmarked emails
   - `ContextualActionService` - Action context

5. **Utility Services** (5):
   - `AnalyticsService` - PostHog tracking
   - `NetworkMonitor` - Connection status
   - `HapticService` - Vibration feedback
   - `AppStateManager` - App lifecycle
   - `UserPreferencesService` - User settings

**See**: `SERVICE_INVENTORY.md` for complete service documentation

### 4. Modal System

**File**: `Views/ActionModals/` (46 modal views)

**Modal Types** (examples):
- `CalendarEventModal` - Add to calendar
- `PaymentFlowModal` - Pay invoices
- `SignDocumentModal` - Sign forms
- `TrackingModal` - Track packages
- `RSVPModal` - Event RSVP
- `ShoppingCartModal` - Shopping actions

**Modal Structure**:
```swift
struct CalendarEventModal: View {
    let card: EmailCard
    let action: EmailAction
    @StateObject private var calendarService = CalendarService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            // Modal UI
            Button("Add to Calendar") {
                calendarService.addEvent(from: card)
                dismiss()
            }
        }
    }
}
```

**Opening Modals**:
```swift
// ContentView.swift
.sheet(isPresented: $showActionModal) {
    ActionRouter.shared.getModalView(for: action, card: card)
}
```

---

## Common Tasks

### Task 1: Add a New Action

**Goal**: Create a new action like "Schedule Meeting"

**Steps**:

1. **Define action in ActionRegistry.swift**:
```swift
// Add to ActionRegistry.swift (around line 500)
ActionConfig(
    actionId: "schedule_meeting",
    displayName: "Schedule Meeting",
    actionType: .IN_APP,
    mode: .mail,
    modalComponent: "schedule_meeting_modal",
    requiredContextKeys: ["subject"],
    optionalContextKeys: ["time", "location"],
    priority: .high,
    description: "Schedule a meeting with participants"
)
```

2. **Create modal view**:
```swift
// Create Views/ActionModals/ScheduleMeetingModal.swift
struct ScheduleMeetingModal: View {
    let card: EmailCard
    let action: EmailAction
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text("Schedule Meeting")
            Text(card.title)
            Button("Schedule") {
                // Call CalendarService
                dismiss()
            }
        }
    }
}
```

3. **Add to ActionRouter modal enum**:
```swift
// ActionRouter.swift - Add to ActionModal enum
enum ActionModal {
    // ... existing cases
    case scheduleMeeting
}
```

4. **Add to router switch**:
```swift
// ActionRouter.swift - getModalView()
case "schedule_meeting_modal":
    return .scheduleMeeting
```

5. **Add to ContentView**:
```swift
// ContentView.swift - actionRouterModalView()
case .scheduleMeeting:
    ScheduleMeetingModal(card: card, action: action)
```

6. **Test**:
```bash
# Build and run
xcodebuild -project Zero.xcodeproj -scheme Zero build
# Verify action appears in sample cards
```

**Time**: ~30 minutes for simple action

### Task 2: Add a New Service

**Goal**: Create a new service like "NotificationService"

**Steps**:

1. **Create service file**:
```swift
// Create Services/NotificationService.swift
import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var notificationPermission: Bool = false

    private init() {
        checkPermission()
    }

    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermission = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleNotification(title: String, body: String, date: Date) {
        // Implementation
    }
}
```

2. **Add to Xcode project**:
   - Right-click Services folder
   - "Add Files to Zero"
   - Select NotificationService.swift
   - Ensure "Zero" target is checked

3. **Use in views**:
```swift
struct SomeView: View {
    @StateObject private var notificationService = NotificationService.shared

    var body: some View {
        Button("Enable Notifications") {
            notificationService.requestPermission()
        }
    }
}
```

4. **Document in SERVICE_INVENTORY.md**:
   - Add to utility services section
   - Document methods and usage

**Time**: ~1 hour for basic service

### Task 3: Fix a Bug

**Example**: Fix action not opening modal

**Debugging Steps**:

1. **Check ActionRegistry**:
```swift
// Search for action ID in ActionRegistry.swift
grep "pay_invoice" Services/ActionRegistry.swift
```

2. **Verify action config**:
   - Check `actionId` matches
   - Check `modalComponent` name
   - Check `mode` is correct (.mail or .ads)

3. **Check ActionRouter**:
   - Verify modal enum case exists
   - Verify switch statement has case
   - Check for typos in modal component name

4. **Check ContentView**:
   - Verify modal view is returned in switch
   - Check modal receives correct parameters

5. **Add logging**:
```swift
// ActionRouter.swift - executeAction()
Logger.info("Executing action: \(action.actionId)", category: .action)
Logger.info("Modal component: \(config.modalComponent)", category: .action)
```

6. **Run in debugger**:
   - Set breakpoint in `ActionRouter.executeAction()`
   - Step through routing logic
   - Verify action config is found

7. **Check Console**:
   - Look for error logs
   - Check for warnings about missing context

**Time**: ~30 minutes to 2 hours depending on bug

### Task 4: Update Backend API

**Goal**: Add new API endpoint for fetching email details

**Steps**:

1. **Update EmailAPIService**:
```swift
// Services/EmailAPIService.swift
func fetchEmailDetails(emailId: String) async throws -> EmailDetails {
    guard let url = URL(string: "\(baseURL)/api/emails/\(emailId)") else {
        throw EmailAPIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw EmailAPIError.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
        throw EmailAPIError.httpError(statusCode: httpResponse.statusCode)
    }

    let decoder = JSONDecoder()
    return try decoder.decode(EmailDetails.self, from: data)
}
```

2. **Add model**:
```swift
// Models/EmailDetails.swift
struct EmailDetails: Codable {
    let id: String
    let fullBody: String
    let attachments: [Attachment]
    let metadata: EmailMetadata
}
```

3. **Use in view**:
```swift
struct EmailDetailView: View {
    let emailId: String
    @State private var details: EmailDetails?

    var body: some View {
        VStack {
            if let details = details {
                Text(details.fullBody)
            }
        }
        .task {
            details = try? await EmailAPIService.shared.fetchEmailDetails(emailId: emailId)
        }
    }
}
```

**Time**: ~1-2 hours

### Task 5: Add Analytics Event

**Goal**: Track when users open a specific modal

**Steps**:

1. **Use AnalyticsService**:
```swift
// In modal view's onAppear
.onAppear {
    AnalyticsService.shared.track(
        event: "modal_opened",
        properties: [
            "modal_type": "calendar_event",
            "action_id": action.actionId,
            "card_type": card.type.rawValue
        ]
    )
}
```

2. **Verify in PostHog**:
   - Check PostHog dashboard for event
   - Verify properties are correct

**Time**: ~10 minutes

---

## Testing & Debugging

### Unit Testing

**Location**: `ZeroTests/` directory

**Running Tests**:
```bash
# Command line
xcodebuild test -project Zero.xcodeproj -scheme Zero -destination 'platform=iOS Simulator,name=iPhone 16'

# Xcode
# Product > Test (⌘U)
```

**Writing Tests**:
```swift
// ZeroTests/ActionRegistryTests.swift
import XCTest
@testable import Zero

class ActionRegistryTests: XCTestCase {
    func testActionExists() {
        let action = ActionRegistry.shared.getAction(id: "pay_invoice")
        XCTAssertNotNil(action)
        XCTAssertEqual(action?.displayName, "Pay Invoice")
    }

    func testActionValidation() {
        let action = ActionRegistry.shared.getAction(id: "pay_invoice")
        XCTAssertEqual(action?.requiredContextKeys, ["amount", "recipient"])
    }
}
```

### Debugging Tips

**1. Use Logger**:
```swift
import OSLog

// Add to any file
Logger.info("Card loaded: \(card.id)", category: .action)
Logger.error("Failed to fetch emails: \(error)", category: .network)
```

**2. Check Console**:
- Xcode > View > Debug Area > Show Debug Area
- Filter by category: "action", "network", etc.

**3. Breakpoints**:
- Click line number gutter to add breakpoint
- Run in debugger (⌘R)
- Inspect variables in Variables View

**4. View Hierarchy**:
- Debug > View Debugging > Capture View Hierarchy
- Inspect SwiftUI view tree

**5. Network Debugging**:
```swift
// Add to EmailAPIService for debugging
print("Request URL: \(url)")
print("Response: \(String(data: data, encoding: .utf8) ?? "nil")")
```

### Common Issues

**Issue**: "Build input file cannot be found"
- **Cause**: File deleted but still referenced in project.pbxproj
- **Fix**: Remove file reference from Xcode project

**Issue**: "Cannot find type 'SomeService' in scope"
- **Cause**: File not added to Xcode target
- **Fix**: Select file > File Inspector > Target Membership > Check "Zero"

**Issue**: Modal not opening
- **Cause**: Modal component name mismatch
- **Fix**: Check ActionRegistry `modalComponent` matches ActionRouter switch case

**Issue**: Action not appearing
- **Cause**: Action mode doesn't match card type
- **Fix**: Check ActionConfig `mode` (.mail, .ads, or .both)

---

## Best Practices

### Code Style

**1. Use Descriptive Names**:
```swift
// ✅ Good
func fetchEmailDetails(emailId: String) async throws -> EmailDetails

// ❌ Bad
func getEmail(id: String) async throws -> Email
```

**2. Keep Functions Small**:
```swift
// ✅ Good (single responsibility)
func validateEmail(_ email: String) -> Bool {
    return email.contains("@")
}

func sendEmail(_ email: String) async throws {
    guard validateEmail(email) else {
        throw EmailError.invalidEmail
    }
    // Send logic
}

// ❌ Bad (doing too much)
func sendEmail(_ email: String) async throws {
    // Validation
    // Formatting
    // Sending
    // Analytics
    // Error handling
    // ... 200 lines of code
}
```

**3. Use Swift Concurrency**:
```swift
// ✅ Good (async/await)
func fetchData() async throws -> Data {
    try await URLSession.shared.data(from: url).0
}

// ❌ Bad (completion handlers)
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, error in
        // Complex error handling
    }
}
```

**4. Use @Published for Reactive Updates**:
```swift
// ✅ Good
class EmailData: ObservableObject {
    @Published var cards: [EmailCard] = []
}

// View automatically updates when cards change
```

### Architecture Patterns

**1. Separation of Concerns**:
- Views: UI only, no business logic
- Services: Business logic, no UI
- Models: Data structures only

**2. Single Source of Truth**:
- ActionRegistry: All action definitions
- EmailData: All email card state
- UserPreferencesService: All user settings

**3. Protocol-Based Design**:
```swift
protocol EmailServiceProtocol {
    func fetchEmails() async throws -> [EmailCard]
}

class EmailAPIService: EmailServiceProtocol {
    // Implementation
}

class MockEmailService: EmailServiceProtocol {
    // Mock for testing
}
```

### Performance

**1. Lazy Loading**:
```swift
// Only load when needed
.task {
    if cards.isEmpty {
        await loadCards()
    }
}
```

**2. Caching**:
```swift
// EmailPersistenceService.swift
private var cachedCards: [EmailCard]?
private var cacheTimestamp: Date?

func fetchCachedCards() -> [EmailCard]? {
    guard let timestamp = cacheTimestamp,
          Date().timeIntervalSince(timestamp) < 86400 else {
        return nil  // Cache expired (24 hours)
    }
    return cachedCards
}
```

**3. Avoid Expensive Operations in Views**:
```swift
// ❌ Bad (runs on every render)
var body: some View {
    let processedData = expensiveComputation(data)
    Text(processedData)
}

// ✅ Good (computed once)
var processedData: String {
    expensiveComputation(data)
}

var body: some View {
    Text(processedData)
}
```

### Security

**1. Never Hardcode Secrets**:
```swift
// ❌ Bad
let apiKey = "sk_live_123456789"

// ✅ Good
let apiKey = ProcessInfo.processInfo.environment["API_KEY"] ?? ""
```

**2. Validate User Input**:
```swift
func processEmail(_ email: String) throws {
    guard email.contains("@") else {
        throw ValidationError.invalidEmail
    }
    // Process
}
```

**3. Isolate Admin Features**:
- Admin services: `Views/Admin/` only
- Admin endpoints: `/api/admin/*` only
- Never mix user-facing and admin code

---

## Resources

### Documentation

**Architecture Docs** (in this directory):
- `ROUTING_ARCHITECTURE.md` - Routing system deep dive
- `SERVICE_INVENTORY.md` - All 57 services documented
- `SERVICE_QUICK_REFERENCE.md` - Quick service lookup
- `ARCHITECTURE_ANALYSIS_SUMMARY.md` - High-level overview
- `FEEDBACK_SERVICES_ANALYSIS.md` - Why services are separate
- `CLEANUP_DECISION_LOG.md` - Cleanup decisions (Weeks 1-3)
- `DEVELOPER_ONBOARDING.md` - This guide

### Key Files to Read

**Priority 1** (read first):
1. `ROUTING_ARCHITECTURE.md` - Understand action system
2. `SERVICE_QUICK_REFERENCE.md` - Service lookup
3. `Services/ActionRegistry.swift` - All action definitions
4. `Views/ContentView.swift` - Root view + routing

**Priority 2** (read next):
1. `SERVICE_INVENTORY.md` - Detailed service docs
2. `Services/ActionRouter.swift` - Routing implementation
3. `Services/EmailAPIService.swift` - Backend API
4. `Models/EmailCard.swift` - Core data model

**Priority 3** (read when needed):
1. `ARCHITECTURE_ANALYSIS_SUMMARY.md` - Strategic overview
2. `CLEANUP_DECISION_LOG.md` - Why things were deleted/kept
3. `Services/DataGenerator.swift` - Sample data generation

### External Resources

**Swift & SwiftUI**:
- [Swift.org Documentation](https://swift.org/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

**iOS Frameworks**:
- [EventKit (Calendar)](https://developer.apple.com/documentation/eventkit)
- [Contacts Framework](https://developer.apple.com/documentation/contacts)
- [PassKit (Wallet)](https://developer.apple.com/documentation/passkit)
- [StoreKit 2](https://developer.apple.com/documentation/storekit)

**Architecture**:
- [MVVM Pattern](https://www.hackingwithswift.com/books/ios-swiftui/introducing-mvvm-into-your-swiftui-project)
- [Service Layer Pattern](https://martinfowler.com/eaaCatalog/serviceLayer.html)
- [Registry Pattern](https://martinfowler.com/eaaCatalog/registry.html)

### Getting Help

**Internal**:
1. Check documentation (this directory)
2. Search codebase (⌘⇧F)
3. Ask team lead
4. Code review feedback

**External**:
1. [Stack Overflow](https://stackoverflow.com/questions/tagged/swiftui)
2. [Swift Forums](https://forums.swift.org/)
3. [Apple Developer Forums](https://developer.apple.com/forums/)

---

## Appendix: Quick Reference

### Xcode Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘R | Build and run |
| ⌘B | Build only |
| ⌘U | Run tests |
| ⌘. | Stop running |
| ⌘⇧O | Open quickly |
| ⌘⇧F | Find in project |
| ⌃I | Fix indentation |
| ⌘/ | Comment/uncomment |
| ⌘⇧L | Show library (views, modifiers) |

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/add-schedule-meeting

# Make changes
# ... code changes ...

# Stage and commit
git add .
git commit -m "Add schedule meeting action"

# Push to remote
git push origin feature/add-schedule-meeting

# Create pull request on GitHub/GitLab
```

### Build Commands

```bash
# Clean build folder
xcodebuild -project Zero.xcodeproj -scheme Zero clean

# Build for simulator
xcodebuild -project Zero.xcodeproj -scheme Zero \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild test -project Zero.xcodeproj -scheme Zero \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Common Grep Patterns

```bash
# Find all services using a specific framework
grep -r "import EventKit" Services/

# Find all views using a specific service
grep -r "CalendarService" Views/

# Find action definitions
grep -r "actionId:" Services/ActionRegistry.swift

# Find modal components
grep -r "modalComponent:" Services/ActionRegistry.swift
```

---

## Next Steps

### Your First Week

**Day 1-2**: Environment Setup & Reading
- ✅ Clone repo and build project
- ✅ Read this onboarding guide
- ✅ Read `ROUTING_ARCHITECTURE.md`
- ✅ Read `SERVICE_QUICK_REFERENCE.md`

**Day 3-4**: Code Exploration
- ✅ Trace an action flow from swipe to modal
- ✅ Add logging to ActionRouter
- ✅ Modify DataGenerator to add custom sample card
- ✅ Run app and see your changes

**Day 5**: First Contribution
- ✅ Pick a small bug from issue tracker
- ✅ Fix bug and test
- ✅ Submit pull request
- ✅ Code review with team

### Your First Month

**Week 1**: Onboarding (see above)
**Week 2**: Add a simple action (e.g., "Copy to Clipboard")
**Week 3**: Add a device integration (e.g., save to Photos)
**Week 4**: Add a new modal with service integration

### Beyond

You're now ready to:
- Add complex actions with multiple steps
- Refactor services for better architecture
- Optimize performance bottlenecks
- Contribute to architecture decisions
- Mentor new developers

---

**Welcome to the team!** 🎉

If you have questions about this guide, create an issue or ask your team lead.

**Document Status**: Complete
**Last Updated**: 2025-11-14
**Maintained By**: Development Team
