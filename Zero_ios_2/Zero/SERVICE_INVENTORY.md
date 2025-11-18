# Zero iOS Service Inventory

**Last Updated**: 2025-11-14  
**Status**: Comprehensive service architecture analysis  
**Coverage**: 57 services across 6 categories

---

## Table of Contents

1. [Core Services](#core-services) - Action routing and email operations
2. [Admin Services](#admin-services) - Feedback and model tuning
3. [Integration Services](#integration-services) - Device framework integrations
4. [Data Services](#data-services) - Persistence and state management
5. [Utility Services](#utility-services) - Cross-cutting concerns
6. [Specialized Services](#specialized-services) - Feature-specific implementations
7. [Architecture Patterns](#architecture-patterns)
8. [Dependency Graph](#dependency-graph)

---

## Core Services

### Service Category: Action Routing & Execution

**Responsibility**: Route user actions to appropriate modals/URLs, manage action registry, load action configurations.

#### 1. ActionRouter (906 lines)

**File**: `/Services/ActionRouter.swift`

**Type**: Observable Service (ObservableObject)

**Purpose**: Single routing system for all modal navigation and action execution

**Key Responsibilities**:
- Execute actions based on action ID and type (GO_TO or IN_APP)
- Validate actions against ActionRegistry
- Apply placeholder context for missing fields
- Track action analytics
- Manage modal state (@Published)

**Published Properties**:
```swift
@Published var activeModal: ActionModal?
@Published var showingModal: Bool = false
@Published var showingPreviewModal: ActionPreviewModal?
@Published var errorMessage: String?
@Published var showingError: Bool = false
@Published var currentMode: CardType = .mail  // Mail vs Ads mode
```

**Key Methods**:
- `executeAction(_:card:from:)` - Execute action with validation
- `handleGoToAction(action:context:)` - Open external URLs
- `handleInAppAction(action:card:context:)` - Show in-app modals
- `validateAction(actionId:context:)` - Validate action prerequisites

**Dependencies**:
- ActionRegistry (for action definitions)
- AnalyticsService (for tracking)
- ActionPlaceholders (for context fallbacks)

**Usage Patterns**:
```swift
// From Views/ActionModules/
ActionRouter.shared.executeAction(action, card: card)

// From ContentView.swift
if let action = card.suggestedActions?.first(where: { $0.isPrimary }) {
    ActionRouter.shared.executeAction(action, card: card)
}
```

**Admin Usage**: Via ActionFeedbackView for testing action execution

---

#### 2. ActionRegistry (3,163 lines)

**File**: `/Services/ActionRegistry.swift`

**Type**: Singleton Registry

**Purpose**: Single source of truth for all action definitions across Mail and Ads modes

**Key Responsibilities**:
- Define all 100+ actions (track_package, pay_invoice, etc.)
- Provide action lookup by ID
- Validate actions for current mode (Mail vs Ads)
- Define context requirements (required/optional fields)
- Support hybrid Swift + JSON action definitions

**Action Organization**:
```
Total Actions: 100+
├── Mail-only: 78 actions
├── Ads-only: 8 actions
└── Both modes: 14 actions

By Priority:
├── Premium (90-100): track_package, pay_invoice, check_in_flight, sign_form
├── High (70-89): contact_driver, quick_reply, view_pickup_details
└── Standard (0-69): view_document, add_reminder, acknowledge
```

**Core Structures**:
```swift
struct ActionConfig {
    let actionId: String
    let displayName: String
    let modalComponent: String       // Modal class name
    let actionType: ActionType       // IN_APP or GO_TO
    let modes: [String]              // ["mail"], ["ads"], or ["mail", "ads"]
    let priority: Int                // 0-100
    let requiredContext: [String]    // e.g., ["trackingNumber", "carrier"]
    let optionalContext: [String]
    let category: String?            // "shipping", "payment", etc.
}

enum ZeroMode: String, Codable {
    case mail = "mail"
    case ads = "ads"
    case both = "both"
}

enum ZeroActionType: String, Codable {
    case goTo = "GO_TO"              // External URL
    case inApp = "IN_APP"            // In-app modal
}
```

**Key Methods**:
- `getAction(id:)` - Lookup action by ID
- `isActionValidForMode(id:currentMode:)` - Check mode compatibility
- `validateAction(actionId:context:)` - Validate required context
- `getActionsForMode(mode:)` - Filter actions by mode

**Hybrid System** (Phase 3.1):
```swift
func getAction(id: String) -> ActionConfig? {
    // 1. Try JSON files first (via ActionLoader)
    if let jsonAction = ActionLoader.shared.loadAction(id: id) {
        return jsonAction
    }
    // 2. Fall back to hardcoded Swift actions
    return swiftActions[id]
}
```

**Dependencies**:
- ActionLoader (for JSON configuration)
- ZeroMode, ZeroActionType enums
- ActionPlaceholders (for context validation)

**Usage Patterns**:
```swift
// Lookup action
if let config = ActionRegistry.shared.getAction(action.actionId) { ... }

// Validate for mode
if !ActionRegistry.shared.isActionValidForMode(actionId, currentMode: .mail) { ... }

// Validate context
let result = ActionRegistry.shared.validateAction("track_package", context: [...])
```

---

#### 3. ActionLoader (379 lines) - Phase 3.1

**File**: `/Services/ActionLoader.swift`

**Type**: Singleton Configuration Loader

**Purpose**: Load action definitions from JSON configuration files for dynamic action updates

**Key Responsibilities**:
- Load JSON action definitions from Config/Actions/ directory
- Parse and validate JSON schemas
- Cache loaded actions in memory
- Provide fallback mechanism for hardcoded actions

**JSON Configuration**:
```
Config/Actions/
├── action-schema.json (schema definition)
├── mail-actions.json (15 Mail mode actions)
└── ads-actions.json (Ads mode actions)
```

**Supported Actions (JSON)** (15 currently):
- track_package
- pay_invoice
- check_in_flight
- sign_form
- quick_reply
- add_to_calendar
- add_reminder
- view_details
- save_for_later
- browse_shopping
- contact_driver
- view_pickup_details
- schedule_delivery_time
- update_payment
- cancel_subscription

**Key Methods**:
- `loadAction(id:)` - Load single action from JSON
- `loadAllActions()` - Load all actions from files
- `validateActionSchema(action:)` - Validate JSON structure

**Dependencies**:
- FileManager (for file I/O)
- JSONDecoder (for parsing)

**Usage Pattern**:
```swift
// Transparent integration with ActionRegistry
let action = ActionRegistry.shared.getAction("track_package")
// Internally calls ActionLoader first, then falls back to Swift
```

**Advantages**:
- Hot-reload actions without app recompilation
- Server can push action updates
- Gradual migration from Swift to JSON (85 Swift actions → JSON)

---

#### 4. EmailAPIService (27 KB)

**File**: `/Services/EmailAPIService.swift`

**Type**: Singleton Service (implements EmailServiceProtocol)

**Purpose**: Backend API communication for email operations

**Key Responsibilities**:
- Authenticate users (Demo, Gmail OAuth, Microsoft OAuth)
- Fetch emails with metadata and actions
- Fetch individual email threads
- Search emails by query/sender
- Perform basic email operations (archive, delete, mark read)
- Generate AI smart replies
- Fetch smart reply suggestions

**Authentication Flows**:
1. **Demo Auth**: `POST /auth/demo` with password "123456"
2. **Gmail OAuth**: ASWebAuthenticationSession flow
3. **Microsoft OAuth**: ASWebAuthenticationSession flow

**API Endpoints**:
```
POST /auth/demo                 - Demo authentication
POST /auth/gmail                - Gmail OAuth callback
POST /auth/microsoft            - Microsoft OAuth callback
GET /emails?maxResults=N        - Fetch emails
GET /emails/{id}                - Fetch single email
GET /emails/{id}/thread         - Fetch thread
POST /emails/{id}/action        - Perform action
GET /search?q=...               - Search emails
GET /emails/{id}/replies        - Smart reply suggestions
POST /emails/{id}/reply         - Generate reply
```

**Environment Support**:
```swift
enum AppEnvironment {
    case development    // localhost:3000
    case staging        // staging API
    case production      // production API
}
```

**Error Handling**:
```swift
enum APIError: LocalizedError {
    case invalidPassword
    case requestFailed
    case decodingError
    case networkError
    case authenticationRequired
}
```

**Key Methods**:
- `authenticateDemo(password:)` - Demo login
- `authenticateGmail(presentationAnchor:)` - Gmail OAuth
- `authenticateMicrosoft(presentationAnchor:)` - Microsoft OAuth
- `fetchEmails(maxResults:timeRange:)` - Fetch email list
- `fetchThread(emailId:)` - Fetch email thread
- `performAction(emailId:action:)` - Execute basic action
- `generateReply(emailId:)` - AI reply generation

**Dependencies**:
- URLSession (for HTTP requests)
- AuthenticationServices (for OAuth)
- CodableEmail models

**Usage Patterns**:
```swift
// From DI/ServiceContainer.swift
let emailService: EmailServiceProtocol = EmailAPIService.shared

// From ViewModels
async let emails = emailService.fetchEmails(maxResults: 20, timeRange: .twoWeeks)
```

**Integration Points**:
- Views/AuthenticationView.swift (OAuth flows)
- Views/SmartReplyView.swift (reply generation)
- ViewModels/EmailViewModel.swift (email fetching)

---

#### 5. DataGenerator (242 KB)

**File**: `/Services/DataGenerator.swift`

**Type**: Utility Service (static methods, no instance)

**Purpose**: Generate comprehensive mock email data for UI testing and demo mode

**Key Responsibilities**:
- Generate mock EmailCard arrays for all archetypes
- Provide fallback when JSON fixtures unavailable
- Create realistic test data with full action sets
- Support both basic and extended email sets

**Mock Data Strategy** (Hybrid):
1. **Try JSON fixtures first** (MockDataLoader)
2. **Fall back to hardcoded data** if JSON unavailable
3. **Always provide complete action sets** per archetype

**Supported Archetypes** (20+ emails):
```
Personal:
├── Field Trip Permission (Sign & Send)
├── Assignment Past Due (Acknowledge)
├── Science Fair (Add to Calendar)
└── Report Card (View Document)

E-Commerce:
├── Order Tracking (Track Package)
├── Delivery Notification (View Pickup Details)
├── Payment Failure (Update Payment)
└── Subscription Renewal (Cancel Subscription)

Travel:
├── Flight Confirmation (Check In Flight)
├── Hotel Reservation (View Itinerary)
├── Rental Car (Add Reminder)
└── Travel Insurance (View Document)

Financial:
├── Invoice (Pay Invoice)
├── Bank Alert (Acknowledge)
├── Loan Application (Sign Form)
└── Bill Payment (Quick Reply)
```

**Key Methods**:
- `generateSarahChenEmails()` - Comprehensive test set
- `generateBasicEmails()` - Basic email set
- `generateComprehensiveMockData()` - All emails with actions
- `generateExtendedEmails()` - 20+ emails per archetype

**Dependencies**:
- MockDataLoader (loads JSON fixtures)
- EmailCard models
- ActionRegistry (for action definitions)

**Usage Patterns**:
```swift
// From Views/Feed/CardStackView.swift (mock mode)
if appSettings.useMockData {
    let cards = DataGenerator.generateSarahChenEmails()
    cardManagement.cards = cards
}

// From ServiceContainer.mock()
appSettings.useMockData = true  // Enable mock data
```

**Integration Points**:
- AppSettings.useMockData flag
- CardStackView.swift (mock data loading)
- ServiceContainer.mock() factory

---

## Admin Services

### Service Category: Feedback & Model Tuning

**Responsibility**: Collect admin feedback on actions, classification, and model performance.

#### 1. ActionFeedbackService (25 KB)

**File**: `/Services/ActionFeedbackService.swift`

**Type**: Singleton Service (no ObservableObject)

**Purpose**: Manage admin feedback on suggested email actions

**API Endpoints**:
```
https://emailshortform-classifier-514014482017.us-central1.run.app/api

GET /admin/next-action-review              - Fetch next email for review
POST /admin/actions/feedback               - Submit action feedback
GET /admin/corpus/comprehensive            - Load comprehensive corpus
POST /admin/actions/generate-sample        - Generate sample email with actions
```

**Key Responsibilities**:
- Fetch emails with suggested actions for admin review
- Accept/reject individual actions
- Rate action confidence
- Submit feedback to training backend
- Generate sample emails for testing

**Data Structures**:
```swift
struct CorpusEmail: Codable {
    let subject: String
    let from: String
    let body: String
    let intent: String
    let generated: Bool
}

struct ClassifiedEmailWithActions: Codable {
    let emailId: String
    let subject: String
    let actions: [SuggestedActionWithConfidence]
    let intentConfidence: Double
}

struct ActionFeedback: Codable {
    let emailId: String
    let actionId: String
    let approved: Bool
    let confidence: Double
    let notes: String?
}
```

**Key Methods**:
- `fetchNextEmailWithActions()` - Get next email for review
- `submitFeedback(feedback:)` - Submit action feedback
- `generateSampleEmailWithActions()` - Create test email
- `generateFeedbackSummary()` - Statistics on feedback
- `loadComprehensiveCorpus()` - Load training corpus

**Dependencies**:
- URLSession (HTTP requests)
- Cloud Run backend (feedback storage)

**Usage Patterns**:
```swift
// From Views/Admin/ActionFeedbackView.swift
let email = try await ActionFeedbackService.shared.fetchNextEmailWithActions()
// User reviews and approves/rejects actions
try await ActionFeedbackService.shared.submitFeedback(feedback)
```

**Integration Points**:
- Views/Admin/ActionFeedbackView.swift (primary UI)
- Views/Admin/ModelTuningView.swift (combined feedback)

---

#### 2. AdminFeedbackService (10 KB)

**File**: `/Services/AdminFeedbackService.swift`

**Type**: Singleton Service

**Purpose**: Collect admin feedback on email classification (intent, category)

**API Endpoints**:
```
https://emailshortform-classifier-514014482017.us-central1.run.app/api

GET /admin/next-email                      - Fetch next email for review
POST /admin/feedback                       - Submit classification feedback
POST /admin/generate-sample                - Generate sample email
```

**Key Responsibilities**:
- Fetch unreviewed emails for classification feedback
- Accept/reject intent classifications
- Submit category feedback
- Generate sample emails for testing
- Track feedback statistics

**Data Structures**:
```swift
struct ClassifiedEmail: Codable {
    let emailId: String
    let subject: String
    let body: String
    let intent: String
    let intentConfidence: Double
    let category: String?
}

struct CategoryFeedback: Codable {
    let emailId: String
    let correctIntent: String?
    let correctCategory: String?
    let notes: String?
}
```

**Key Methods**:
- `fetchNextEmail()` - Get next email for classification review
- `submitFeedback(feedback:)` - Submit classification feedback
- `generateSampleEmail()` - Create test email
- `generateFeedbackSummary()` - Feedback statistics

**Usage Patterns**:
```swift
// From Views/Admin/AdminFeedbackView.swift
let email = try await AdminFeedbackService.shared.fetchNextEmail()
// User corrects classification
try await AdminFeedbackService.shared.submitFeedback(categoryFeedback)
```

---

#### 3. ModelTuningRewardsService (6 KB)

**File**: `/Services/ModelTuningRewardsService.swift`

**Type**: Singleton Service

**Purpose**: Track and reward admin feedback contributions for model tuning

**Key Responsibilities**:
- Track feedback submission count
- Calculate reward points
- Monitor feedback quality
- Generate contributor statistics
- Award badges/achievements

**Data Structures**:
```swift
struct RewardStats: Codable {
    let totalFeedback: Int
    let rewardPoints: Int
    let level: String  // "Bronze", "Silver", "Gold"
    let nextMilestone: Int
    let badges: [String]
}
```

**Key Methods**:
- `recordFeedback(count:)` - Record feedback submission
- `calculateRewards()` - Compute reward points
- `getRewardStats()` - Fetch contributor statistics
- `awardBadge(name:)` - Award achievement badge

**Usage Patterns**:
```swift
// From Views/Admin/ModelTuningView.swift
await ModelTuningRewardsService.shared.recordFeedback(count: feedbackArray.count)
let stats = await ModelTuningRewardsService.shared.getRewardStats()
```

**Integration Points**:
- Views/Admin/ModelTuningView.swift (reward display)
- ActionFeedbackService (feedback tracking)
- AdminFeedbackService (feedback tracking)

---

## Integration Services

### Service Category: Device Framework Integrations

**Responsibility**: Provide access to native iOS frameworks (Contacts, Calendar, Reminders, Messages, PassKit, etc.)

#### 1. CalendarService (11 KB)

**File**: `/Services/CalendarService.swift`

**Type**: Singleton Service

**Framework Integration**: EventKit

**Purpose**: Create and manage calendar events from emails

**Key Responsibilities**:
- Request calendar access
- Create events with date/time
- Handle permissions (iOS 16/17+ new API)
- Add event location, notes, attendees
- Error handling (no calendars available, etc.)

**Permissions**:
- iOS 17+: `requestFullAccessToEvents()`
- iOS <17: `requestAccess(for: .events)`

**Event Creation Data**:
```swift
struct EventParams {
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let notes: String?
    let attendees: [String]?
}
```

**Key Methods**:
- `requestAccess()` - Request calendar permissions
- `addEvent(title:startDate:endDate:...)` - Create event
- `addEventWithAttendees(...)` - Create event with attendees
- `updateEvent(...)` - Modify existing event

**Error Handling**:
```swift
enum CalendarError: LocalizedError {
    case permissionDenied
    case eventCreationFailed
    case noCalendarsAvailable
    case invalidEventData
}
```

**Usage Patterns**:
```swift
// From Views/ActionModules/AddReminderModal.swift
CalendarService.shared.addEvent(
    title: "Flight Check-In",
    startDate: checkInDate,
    endDate: checkInDate,
    location: "Airport",
    notes: "Check in via app or web"
)

// From Views/ActionModules/ViewActivityModal.swift
CalendarService.shared.addEvent(...)
```

**Integration Points**:
- Views/ActionModules/AddReminderModal.swift
- Views/ActionModules/ViewActivityModal.swift
- Views/ActionModules/ViewActivityDetailsModal.swift
- Views/ActionModules/PrepareForOutageModal.swift
- Views/ActionModules/ViewOutageDetailsModal.swift

---

#### 2. RemindersService (12 KB)

**File**: `/Services/RemindersService.swift`

**Type**: Singleton Service

**Framework Integration**: EventKit

**Purpose**: Create reminders and detect reminder opportunities

**Key Responsibilities**:
- Request reminders access
- Create reminders with priority/due date
- Extract reminder opportunities from email content
- Convert email data to reminder format

**Reminder Priorities**:
```
Priority levels: 0-9
├── 0 = No priority
├── 1-4 = High priority
├── 5 = Medium priority
└── 6-9 = Low priority
```

**Key Methods**:
- `requestAccess()` - Request reminders permissions
- `createReminder(title:notes:dueDate:priority:...)` - Create reminder
- `detectReminderOpportunity(in:)` - Extract from email content
- `suggestReminderTime(for:)` - Suggest due date

**Usage Patterns**:
```swift
// From Views/ActionModules/AddReminderModal.swift
if let opportunity = RemindersService.shared.detectReminderOpportunity(in: card) {
    // Use suggested date/priority
}

RemindersService.shared.createReminder(
    title: "Follow up on package",
    dueDate: deliveryDate,
    priority: 3,
    completion: { result in
        // Handle success/error
    }
)

// From Views/ActionModules/PickupDetailsModal.swift
RemindersService.shared.createReminder(...)
```

**Integration Points**:
- Views/ActionModules/AddReminderModal.swift (primary)
- Views/ActionModules/PickupDetailsModal.swift

---

#### 3. ContactsService (10 KB)

**File**: `/Services/ContactsService.swift`

**Type**: Singleton Service

**Framework Integration**: Contacts, ContactsUI

**Purpose**: Save and manage contacts from email senders

**Key Responsibilities**:
- Request contacts access
- Save new contacts from email data
- Update existing contacts
- Check if contact exists
- Extract phone numbers and emails
- Format contact information

**Contact Data**:
```swift
struct ContactData {
    let name: String
    let email: String
    let phoneNumber: String?
    let organization: String?
    let notes: String?
}
```

**Key Methods**:
- `requestAccess(completion:)` - Request contacts permissions
- `saveContact(from:phoneNumber:...)` - Save new contact
- `contactExists(email:completion:)` - Check if contact exists
- `updateContact(...)` - Update existing contact
- `extractPhoneNumbers(from:)` - Parse phone numbers
- `extractEmail(from:)` - Parse email addresses

**Error Handling**:
```swift
enum ContactsError: LocalizedError {
    case accessDenied
    case contactNotFound
    case saveFailed
    case invalidData
}
```

**Usage Patterns**:
```swift
// From Views/ActionModules/SaveContactModal.swift
ContactsService.shared.contactExists(email: senderEmail) { exists, existing in
    if !exists {
        ContactsService.shared.saveContact(
            from: senderInfo,
            phoneNumber: extractedPhone,
            organization: "Company Name",
            notes: "Contact context"
        )
    }
}

let phones = ContactsService.shared.extractPhoneNumbers(from: emailBody)
```

**Integration Points**:
- Views/ActionModules/SaveContactModal.swift (primary)

---

#### 4. MessagesService (7 KB)

**File**: `/Services/MessagesService.swift`

**Type**: Singleton Service (NSObject base for delegates)

**Framework Integration**: MessageUI, UIKit

**Purpose**: Send SMS/iMessage from email context

**Key Responsibilities**:
- Check device SMS capability
- Send text messages
- Handle message compose UI
- Delegate callback handling

**Key Methods**:
- `canSendMessages()` - Check SMS availability
- `sendMessage(to:body:presentingViewController:completion:)` - Send SMS/iMessage
- `handleMessageCompletion(result:)` - Process send result

**Error Handling**:
```swift
enum MessagesError: LocalizedError {
    case deviceCannotSendMessages
    case messageSendFailed
    case cancelled
}
```

**Usage Patterns**:
```swift
// From Views/ActionModules/SendMessageModal.swift
if MessagesService.canSendMessages() {
    MessagesService.shared.sendMessage(
        to: [phoneNumber],
        body: messageContent,
        presentingViewController: viewController
    ) { result in
        // Handle success/error
    }
}
```

**Integration Points**:
- Views/ActionModules/SendMessageModal.swift

---

#### 5. WalletService (8 KB)

**File**: `/Services/WalletService.swift`

**Type**: Singleton Service

**Framework Integration**: PassKit, UIKit

**Purpose**: Add passes and tickets to Apple Wallet

**Key Responsibilities**:
- Add passes (.pkpass files) to Wallet
- Handle pass addition UI
- Error handling (pass format, permissions)

**Supported Pass Types**:
- Boarding passes (flights, trains, buses)
- Event tickets
- Movie tickets
- Store cards
- Generic passes

**Key Methods**:
- `addPassToWallet(passData:presentingViewController:completion:)` - Add pass
- `canAddPasses()` - Check capability

**Error Handling**:
```swift
enum WalletError: LocalizedError {
    case cannotAddPasses
    case failedToCreateViewController
    case invalidPassData
    case userCancelled
}
```

**Usage Patterns**:
```swift
// From Views/ActionModules/AddToWalletModal.swift
if let passData = try? Data(contentsOf: passFileURL) {
    WalletService.shared.addPassToWallet(
        passData: passData,
        presentingViewController: viewController
    ) { result in
        // Handle success/error
    }
}
```

**Integration Points**:
- Views/ActionModules/AddToWalletModal.swift

---

#### 6. ShoppingCartService (varies)

**File**: `/Services/ShoppingCartService.swift`

**Type**: Singleton Service (implements ShoppingCartServiceProtocol)

**Purpose**: Manage shopping cart operations and e-commerce integration

**Key Responsibilities**:
- Track cart items
- Sync cart with backend
- Calculate totals and savings
- Group items by merchant
- Identify expiring items

**Data Models**:
```swift
struct CartItem: Codable {
    let id: String
    let userId: String
    let emailId: String?
    let productUrl: String?
    let productName: String
    let price: Double
    let originalPrice: Double?
    let quantity: Int
    let merchant: String?
    let expiresAt: String?
    let isExpired: Bool
}

struct CartSummary: Codable {
    let itemCount: Int
    let subtotal: Double
    let totalSavings: Double
    let merchantGroups: [MerchantGroup]
    let expiringItems: [ExpiringItem]
}
```

**Key Methods**:
- `getCart()` - Fetch current cart
- `addItem(...)` - Add item to cart
- `removeItem(id:)` - Remove item
- `updateQuantity(id:quantity:)` - Change quantity
- `getCartSummary()` - Calculate totals
- `clearCart()` - Empty cart

**Usage Patterns**:
```swift
// From ServiceContainer.swift
let shoppingCartService: ShoppingCartServiceProtocol

// From Views/ShoppingCartView.swift
let cartSummary = await shoppingCartService.getCartSummary()
```

**Integration Points**:
- Views/ShoppingCartView.swift
- Views/ActionModules/ShoppingPurchaseModal.swift
- DI/ServiceContainer.swift

---

#### 7. NotesIntegrationService (8 KB)

**File**: `/Services/NotesIntegrationService.swift`

**Type**: Singleton Service

**Framework Integration**: EventKit (Notes via reminders)

**Purpose**: Create and link notes related to emails

**Key Responsibilities**:
- Create notes from email content
- Link notes to reminders
- Sync with Notes app
- Format note content

**Usage Patterns**:
```swift
// Create note for email
NotesIntegrationService.shared.createNote(
    title: emailTitle,
    content: emailSummary,
    attachmentUrl: documentURL
)
```

---

## Data Services

### Service Category: Persistence & State Management

**Responsibility**: Persist emails, manage card state, handle data integrity.

#### 1. EmailData (66 KB)

**File**: `/Services/EmailData.swift`

**Type**: Extension on DataGenerator

**Purpose**: Extended email dataset with 20+ comprehensive examples

**Key Responsibilities**:
- Provide realistic email examples for each archetype
- Include full action sets per email
- Support different user modes (Parent, School, Shopping, etc.)
- Generate test data for UI development

**Email Archetypes Provided**:
```
Personal (8 emails):
├── Field Trip Permission
├── Assignment Past Due
├── Science Fair
└── Report Card (x2), Parent Newsletter, etc.

E-Commerce (12+ emails):
├── Order Tracking
├── Delivery Notification  
├── Payment Failure
└── Subscription emails, etc.

Travel (8+ emails):
├── Flight Check-in
├── Hotel Booking
├── Rental Car
└── Travel Insurance

Financial (6+ emails):
├── Invoice Payment
├── Bank Alert
├── Loan Application
└── Bill Payment
```

**Integration Points**:
- DataGenerator.swift (generates data)
- MockDataLoader.swift (loads from JSON)
- CardStackView.swift (displays in feed)

---

#### 2. EmailPersistenceService (6 KB)

**File**: `/Services/EmailPersistenceService.swift`

**Type**: Singleton Service

**Purpose**: Persist email cards to local storage to prevent data loss

**Key Responsibilities**:
- Save email cards to local JSON files
- Load persisted emails on app startup
- Manage expiration (24-hour default)
- Deduplicate emails (merge new + persisted)
- Error recovery (corrupt data cleanup)

**Data Storage**:
```
Documents/EmailCache/
└── emails.json        (persisted cards)
UserDefaults:
└── persisted_email_timestamp  (expiry tracking)
```

**Expiration Strategy**:
- Default: 24 hours
- Automatic cleanup of old data
- Manual clear option

**Key Methods**:
- `saveEmails(_:)` - Persist cards to disk
- `loadEmails()` -> [EmailCard]? - Load from disk
- `mergeWithPersistedEmails(newCards:)` - Deduplicate
- `clearPersistedEmails()` - Manual cleanup
- `isDataExpired()` - Check if stale
- `getDataAgeInHours()` - Get age

**Usage Patterns**:
```swift
// From ViewModels/EmailViewModel.swift
let persisted = EmailPersistenceService.shared.loadEmails()
let merged = EmailPersistenceService.shared.mergeWithPersistedEmails(
    newCards: freshCards
)

// Save after fetch
EmailPersistenceService.shared.saveEmails(cards)
```

**Deduplication Logic**:
```swift
// Create dict by ID for quick lookup
var emailsById = Dictionary(uniqueKeysWithValues: persisted.map { ($0.id, $0) })

// Add/update with new cards (overwrites duplicates)
for card in newCards {
    emailsById[card.id] = card  // Newer data wins
}

// Result: Merged + deduplicated array
```

**Integration Points**:
- ViewModels/EmailViewModel.swift
- AppStateManager (loading state)

---

#### 3. CardManagementService (varies)

**File**: `/Services/CardManagementService.swift`

**Type**: Observable Service (ObservableObject)

**Purpose**: Manage card collection, filtering, and state transitions

**Published Properties**:
```swift
@Published var cards: [EmailCard] = []
@Published var currentIndex: Int = 0
```

**Key Responsibilities**:
- Store all email cards
- Filter cards by archetype and state
- Track current card position
- Handle card state transitions (unseen → seen → archived)
- Support celebration effects
- Manage swipe navigation

**Key Methods**:
- `filteredCards(for:selectedArchetypes:)` - Get filtered cards
- `dismissCurrentCard()` - Mark as seen/archived
- `undoLastDismissal()` - Restore card
- `getCelebrationType(for:)` - Determine celebration effect
- `updateCardState(_:newState:)` - Change card state

**Card Filtering Logic**:
```swift
func filteredCards(for archetype: CardType, selectedArchetypes: [CardType]) -> [EmailCard] {
    let effective = selectedArchetypes.isEmpty ? [archetype] : selectedArchetypes
    return cards.filter { card in
        effective.contains(card.type) &&
        card.type == archetype &&
        card.state == .unseen
    }
}
```

**Dependencies Injected From**:
- ServiceContainer.cardManagement

**Integration Points**:
- Views/Feed/CardStackView.swift (card display)
- ViewModels/EmailViewModel.swift (state management)
- Services/AppStateManager.swift (app state)

---

#### 4. SavedMailService (15 KB)

**File**: `/Services/SavedMailService.swift`

**Type**: Observable Service (@MainActor, ObservableObject)

**Purpose**: Manage user-created email folders for saving important emails

**API Endpoints**:
```
GET /saved-mail/folders                    - List folders
POST /saved-mail/folders                   - Create folder
PUT /saved-mail/folders/{id}               - Update folder
DELETE /saved-mail/folders/{id}            - Delete folder
POST /saved-mail/emails                    - Save email to folder
```

**Published Properties**:
```swift
@Published var folders: [SavedMailFolder] = []
@Published var isLoading = false
@Published var error: String?
```

**Data Models**:
```swift
struct SavedMailFolder: Codable, Identifiable {
    let id: String
    let name: String
    let color: String?
    let description: String?
    let emailCount: Int
    let createdAt: Date
    let updatedAt: Date
}
```

**Key Methods**:
- `loadFolders()` - Fetch folders from API
- `createFolder(name:color:description:)` - Create folder
- `updateFolder(id:name:...)` - Modify folder
- `deleteFolder(id:)` - Remove folder
- `saveEmail(emailId:folderId:)` - Save email

**Caching Strategy**:
- Load folders from cache on init
- Sync with backend asynchronously
- Update local cache on changes

**Usage Patterns**:
```swift
// From Views/SaveForLaterModal.swift
SavedMailService.shared.saveEmail(emailId: card.id, folderId: selectedFolder.id)

// From Views/FolderDetailView.swift
let folders = SavedMailService.shared.folders
```

**Integration Points**:
- Views/SaveForLaterModal.swift (save dialog)
- Views/SavedMailListView.swift (list display)
- Views/FolderDetailView.swift (folder contents)
- Views/CreateFolderView.swift (folder creation)

---

#### 5. ContextualActionService (25 KB)

**File**: `/Services/ContextualActionService.swift`

**Type**: Singleton Service

**Purpose**: Provide context-aware action suggestions based on email content

**Key Responsibilities**:
- Analyze email content for action opportunities
- Suggest actions based on email intent
- Extract context data (dates, amounts, references)
- Score action relevance
- Handle compound multi-step actions

**Smart Detection**:
```
Email Type Detection:
├── Shipping: Extract tracking number, carrier, date
├── Payment: Extract amount, merchant, due date
├── Travel: Extract dates, confirmation numbers
├── Event: Extract time, location, RSVP info
└── Document: Extract document type, deadline
```

**Key Methods**:
- `suggestActions(for:)` - Get action recommendations
- `extractContext(from:for:)` - Parse email data
- `scoreActionRelevance(action:email:)` - Rank actions
- `detectCompoundOpportunity(in:)` - Multi-step flows

**Integration Points**:
- Views/ActionModules/* (modal-specific context)
- ActionRegistry (action definitions)

---

## Utility Services

### Service Category: Cross-Cutting Concerns

**Responsibility**: Provide application-wide utilities and observability.

#### 1. AnalyticsService (9 KB)

**File**: `/Services/AnalyticsService.swift`

**Type**: Singleton Service (implements Analytics protocol)

**Purpose**: Track user interactions and app events with backend sync

**Key Responsibilities**:
- Log app events (action execution, navigation, etc.)
- Batch and sync events to backend
- Handle offline scenarios
- Exponential backoff retry logic
- Separate "mock" vs "real" data streams

**Event Batching**:
- Max batch size: 10 events
- Flush interval: 30 seconds
- Retry strategy: 3 attempts with exponential backoff

**Key Methods**:
- `log(event:properties:)` - Track event
- `trackAction(actionId:cardType:...)` - Track action execution
- `flushEvents()` - Force sync to backend
- `setDataMode(mode:)` - Switch data stream

**Backend Sync**:
```
POST localhost:8090/api/events/batch
{
    "events": [
        {
            "eventType": "action_executed",
            "actionId": "track_package",
            "cardType": "mail",
            "timestamp": "2025-11-14T..."
        }
    ]
}
```

**Data Mode Separation**:
```swift
// Mock mode: useMockData = true
analytics.dataMode = "mock"

// Real mode: useMockData = false
analytics.dataMode = "real"
// Helps distinguish test signal from production
```

**Fallback Strategy**:
- If backend unavailable, logs to console
- Persists events for retry on next sync
- Never blocks UI thread

**Usage Patterns**:
```swift
// From ActionRouter.swift
AnalyticsService.shared.log("action_executed", properties: [
    "action_id": action.actionId,
    "card_type": card.type.rawValue,
    "user_selected": wasUserSelected
])

// From Views
container.analyticsService.log(.appSessionStart)
```

**Integration Points**:
- ActionRouter.swift (action tracking)
- ContentView.swift (navigation tracking)
- ViewModels/EmailViewModel.swift (email operations)
- DI/ServiceContainer.swift (dependency injection)

---

#### 2. NetworkMonitor (10 KB)

**File**: `/Services/NetworkMonitor.swift`

**Type**: Observable Singleton Service (ObservableObject, @MainActor)

**Framework Integration**: Network framework

**Purpose**: Monitor real-time network connectivity

**Published Properties**:
```swift
@Published var isConnected = true
@Published var connectionType: ConnectionType = .unknown
@Published var isExpensive = false
```

**Connection Types**:
```swift
enum ConnectionType {
    case wifi
    case cellular
    case wired
    case loopback
    case unknown
}
```

**Key Methods**:
- `startMonitoring()` - Begin network monitoring
- `stopMonitoring()` - Stop monitoring
- `checkConnectivity()` - Manual check

**Reactive Monitoring**:
```swift
NetworkMonitor.shared.$isConnected
    .sink { isConnected in
        if !isConnected {
            // Show offline indicator
        }
    }
```

**Usage Patterns**:
```swift
// From API services
if NetworkMonitor.shared.isConnected {
    // Proceed with network request
}

// From Views
@StateObject var networkMonitor = NetworkMonitor.shared

if networkMonitor.isConnected {
    // Show online content
} else {
    // Show offline UI
}
```

**Integration Points**:
- EmailAPIService (connection checks)
- Views (offline indicators)
- NetworkMonitor.swift tests

---

#### 3. HapticService (5 KB)

**File**: `/Services/HapticService.swift`

**Type**: Singleton Service

**Framework Integration**: UIKit (UIFeedbackGenerator)

**Purpose**: Provide consistent haptic feedback across app

**Haptic Patterns**:
```swift
// Impact feedback (interaction intensity)
.lightImpact()      // Selection, toggles
.mediumImpact()     // Button taps, swipe threshold
.heavyImpact()      // Card dismissed, major action
.rigidImpact()      // Error boundaries, limits
.softImpact()       // Gentle UI changes

// Notification feedback (outcome)
.success()          // Action completed
.warning()          // Validation warning
.error()            // Failed action

// Selection feedback
.selectionChanged() // Picker scrolling, tab switch

// Complex patterns
.celebration()      // Triple tap success
.doubleTap()       // Confirmation
```

**Prepared Generators** (Low-latency):
```swift
HapticService.shared.prepareImpact(style: .medium)
// ... wait for interaction ...
HapticService.shared.triggerPreparedImpact()
```

**Key Methods**:
- `lightImpact()`, `mediumImpact()`, etc.
- `success()`, `warning()`, `error()`
- `selectionChanged()`
- `celebration()`, `doubleTap()`
- `prepareImpact(style:)`
- `triggerPreparedImpact()`

**Usage Patterns**:
```swift
// From Views (swipe detection)
.onSwipe { direction in
    HapticService.shared.mediumImpact()
    handleSwipe(direction)
}

// From modals (action completion)
.onSuccess {
    HapticService.shared.celebration()
}

// From ActionRouter (error)
.onError {
    HapticService.shared.error()
}
```

**Integration Points**:
- Views/Feed/CardStackView.swift (swipe feedback)
- Views/ActionModules/* (action completion)
- ActionRouter.swift (error feedback)

---

#### 4. AppStateManager (varies)

**File**: `/Services/AppStateManager.swift`

**Type**: Observable Service (ObservableObject)

**Purpose**: Manage global application state and loading indicators

**Published Properties**:
```swift
@Published var appState: AppState = .splash
@Published var isLoadingRealEmails: Bool = false
@Published var isClassifying: Bool = false
@Published var loadingProgress: Double = 0.0
@Published var loadingMessage: String = ""
@Published var realEmailError: String? = nil
@Published var lastAction: (card: EmailCard, previousState: CardState)? = nil
```

**App States**:
```swift
enum AppState: String, Codable {
    case splash         // Initial app launch
    case onboarding     // Auth/setup flow
    case feed           // Main email feed
    case error          // Error state
}
```

**State Transitions**:
```swift
func transitionToOnboarding()  // splash → onboarding
func transitionToFeed()        // any → feed
func transitionToSplash()      // any → splash
```

**Loading States**:
```swift
func startLoadingRealEmails()
func finishLoadingRealEmails(success:)
func updateLoadingProgress(_:message:)
func startClassifying()
func finishClassifying(success:)
```

**Undo Support**:
```swift
func recordAction(card:previousState:)
func clearLastAction()
```

**Key Methods**:
- State transitions: `transitionTo*()`
- Loading control: `start*()`, `finish*()`
- Error handling: `setRealEmailError()`, `clearRealEmailError()`
- Undo: `recordAction()`, `clearLastAction()`

**Computed Properties**:
```swift
var isLoading: Bool { isLoadingRealEmails || isClassifying }
var hasError: Bool { realEmailError != nil }
```

**Usage Patterns**:
```swift
// From Views/SplashView.swift
appState.startLoadingRealEmails()
// ... fetch emails ...
appState.updateLoadingProgress(0.5, message: "Analyzing...")
appState.finishLoadingRealEmails(success: true)

// From ViewModels
@StateObject var appState: AppStateManager
.onChange(of: appState.appState) { state in
    // React to state changes
}
```

**Integration Points**:
- Views/SplashView.swift (loading UI)
- Views/Feed/CardStackView.swift (state display)
- ViewModels/EmailViewModel.swift (state updates)
- ServiceContainer (dependency injection)

---

#### 5. UserPreferencesService

**File**: `/Services/UserPreferencesService.swift`

**Type**: Observable Service (ObservableObject)

**Purpose**: Manage user settings and preferences

**Key Features**:
- Save/load user preferences
- Email time range settings
- UI preferences (theme, layout)
- Action preferences
- Notification settings

**Integration Points**:
- Views/Settings/* (settings UI)
- ServiceContainer (DI)

---

## Specialized Services

### Additional Service Implementations

**Email Operations**:
- EmailSendingService - Compose and send emails
- SmartReplyService - AI reply suggestions
- SummarizationService - Email summarization

**Shopping & E-Commerce**:
- ShoppingAutomationService - Automated shopping workflows
- ShoppingCartService - Cart management

**Onboarding & Lifecycle**:
- AppLifecycleObserver - App launch/background events
- UserPermissions - Feature flags and capabilities

**Configuration & Experimentation**:
- RemoteConfigService - Remote feature flags
- ExperimentService - A/B testing

**Utility**:
- TemplateManager - Reply templates
- SharedTemplateService - Shared template library
- UndoToastManager - Undo UI management
- SnoozeService - Email snooze functionality
- UnsubscribeService - Newsletter unsubscribe

**Subscription & Billing**:
- SubscriptionService - In-app purchases
- StoreKitService - StoreKit integration

**Media & Documents**:
- AttachmentService - Handle email attachments
- SignedDocumentGenerator - Generate signed PDFs
- SiriShortcutsService - Siri integration

**Data Integrity**:
- DataIntegrityService - Data validation
- DraftComposerService - Draft email handling
- ThreadingService - Email thread management

**Classification & Insights**:
- ClassificationService - Email classification
- VIPManager - Important contact tracking

---

## Architecture Patterns

### 1. Singleton Pattern

**Used by**: ActionRouter, ActionRegistry, ActionLoader, EmailAPIService, CalendarService, etc.

```swift
class ActionRouter: ObservableObject {
    static let shared = ActionRouter()
    private init() {}
}
```

**Advantages**:
- Single instance guarantees consistency
- Global access point
- State management simplicity

**Disadvantage**:
- Hard to test (need mocking infrastructure)

---

### 2. Observable Pattern (SwiftUI)

**Used by**: ActionRouter, AppStateManager, CardManagementService, SavedMailService, etc.

```swift
class AppStateManager: ObservableObject {
    @Published var appState: AppState = .splash
    @Published var isLoading: Bool = false
}
```

**Usage in Views**:
```swift
@StateObject var appState: AppStateManager
@ObservedObject var router: ActionRouter

var body: some View {
    // Changes to @Published properties trigger re-render
}
```

---

### 3. Protocol-Based DI

**Used by**: EmailServiceProtocol, ShoppingCartServiceProtocol, etc.

```swift
protocol EmailServiceProtocol {
    func fetchEmails(...) async throws -> [EmailCard]
    func authenticateDemo(password:) async throws -> String
}

class EmailAPIService: EmailServiceProtocol { ... }
class MockEmailService: EmailServiceProtocol { ... }
```

**Benefits**:
- Easy to swap implementations
- Testable with mocks
- Clear API contracts

**Usage in DI Container**:
```swift
class ServiceContainer {
    let emailService: EmailServiceProtocol
    
    init(emailService: EmailServiceProtocol = EmailAPIService.shared) {
        self.emailService = emailService
    }
}
```

---

### 4. Hybrid Configuration (Swift + JSON)

**Used by**: ActionRegistry + ActionLoader

```
Phase 3.1 Architecture:
┌──────────────────┐
│ ActionRegistry   │
│    (Swift)       │
├──────────────────┤
│ Try JSON first   │ → ActionLoader → Config/Actions/*.json
│ (via ActionLoader)
├──────────────────┤
│ Fall back to     │ → 100+ Swift actions
│ hardcoded Swift  │
└──────────────────┘
```

**Benefits**:
- Gradual migration path (JSON replaces Swift)
- Hot-reload without recompilation
- Server can push updates
- Type safety with Swift fallback

---

### 5. Context Placeholder Pattern

**Used by**: ActionRouter + ActionPlaceholders

```swift
// Validation
let result = ActionRegistry.shared.validateAction(
    actionId: "track_package",
    context: action.context ?? [:]
)

// If missing required fields, apply placeholders
if !result.isValid {
    finalContext = ActionPlaceholders.applyPlaceholders(
        to: action.context ?? [:],
        for: actionId,
        using: card  // Extract from EmailCard
    )
}

// Modal receives complete context
TrackPackageModal(
    trackingNumber: finalContext["trackingNumber"],
    carrier: finalContext["carrier"]
)
```

**Extraction Strategy**:
1. Use backend-provided context first
2. Extract from EmailCard fields (company, sender, etc.)
3. Use sensible defaults ("Unknown", "N/A")
4. Better partial data than no modal

---

### 6. MainActor Isolation (Concurrency)

**Used by**: NetworkMonitor, SavedMailService

```swift
@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    
    func startMonitoring() { ... }  // Always on main thread
}

@MainActor
class SavedMailService: ObservableObject {
    @Published var folders: [SavedMailFolder] = []
}
```

**Benefits**:
- Thread-safe UI state updates
- Compiler enforces main thread access
- Clear intent (UI-related)

---

### 7. Batch + Retry Pattern

**Used by**: AnalyticsService

```swift
// Event Collection
pendingEvents: [[String: Any]] = []
maxBatchSize = 10
batchInterval: TimeInterval = 30.0

// Retry Strategy
retryCount = 0
maxRetries = 3
// Exponential backoff: 2s, 4s, 8s
```

**Flow**:
```
Event → Queue → Batch (10 or 30s) → Sync → Retry (3x) → Fallback (console)
```

---

## Dependency Graph

### Service Dependencies (Inbound)

```
ContentView
├── ActionRouter
│   ├── ActionRegistry
│   │   └── ActionLoader
│   ├── ActionPlaceholders
│   └── AnalyticsService
├── CardManagementService
├── AppStateManager
└── UserPreferencesService

ViewModels/EmailViewModel
├── EmailAPIService
├── EmailPersistenceService
├── CardManagementService
└── AppStateManager

Action Modals (46 total)
├── CalendarService
├── ContactsService
├── RemindersService
├── MessagesService
├── WalletService
└── HapticService

Admin Views
├── ActionFeedbackService
├── AdminFeedbackService
├── ModelTuningRewardsService
└── AnalyticsService
```

### Admin vs User-Facing Separation

**Admin Services** (Views/Admin/):
- ActionFeedbackService - Action approval workflow
- AdminFeedbackService - Classification review
- ModelTuningRewardsService - Contributor rewards
- DeadEndActionDashboard - Failed action tracking

**Integration Services** (Views/ActionModules/):
- CalendarService - Add events
- ContactsService - Save contacts
- RemindersService - Create reminders
- MessagesService - Send SMS
- WalletService - Add passes

**Data Services** (State Management):
- CardManagementService - Card state
- AppStateManager - App state
- SavedMailService - Saved folders
- EmailPersistenceService - Local cache

---

## Service Inventory Summary

### By Category

| Category | Count | Key Services |
|----------|-------|--------------|
| Core Services | 5 | ActionRouter, ActionRegistry, ActionLoader, EmailAPIService, DataGenerator |
| Admin Services | 3 | ActionFeedbackService, AdminFeedbackService, ModelTuningRewardsService |
| Integration Services | 7 | CalendarService, ContactsService, RemindersService, MessagesService, WalletService, ShoppingCartService, NotesIntegrationService |
| Data Services | 5 | EmailData, EmailPersistenceService, CardManagementService, SavedMailService, ContextualActionService |
| Utility Services | 5 | AnalyticsService, NetworkMonitor, HapticService, AppStateManager, UserPreferencesService |
| Specialized Services | 27+ | See Specialized Services section |

### By ObservableObject Status

**Observable** (SwiftUI @Published):
- ActionRouter
- AppStateManager
- CardManagementService
- SavedMailService
- NetworkMonitor
- UserPreferencesService
- AppLifecycleObserver
- TemplateManager
- SharedTemplateService
- RemoteConfigService
- ExperimentService
- StoreKitService

**Non-Observable** (Static methods or singletons):
- ActionRegistry
- ActionLoader
- EmailAPIService
- DataGenerator
- ActionFeedbackService
- AdminFeedbackService
- CalendarService
- ContactsService
- RemindersService
- MessagesService
- WalletService
- ShoppingCartService
- AnalyticsService
- HapticService

---

## Integration Points by Feature

### Email Operations
- EmailAPIService - Backend communication
- EmailPersistenceService - Local caching
- SmartReplyService - Reply suggestions

### Action Execution
- ActionRouter - Route to modal/URL
- ActionRegistry - Define actions
- ActionLoader - Load from JSON
- ContextualActionService - Suggest actions

### Shopping
- ShoppingCartService - Cart management
- ShoppingAutomationService - Automated flows
- CardManagementService - Card state

### Communication
- CalendarService - Event creation
- RemindersService - Reminder creation
- ContactsService - Contact saving
- MessagesService - SMS sending

### Admin
- ActionFeedbackService - Action review
- AdminFeedbackService - Classification review
- ModelTuningRewardsService - Reward tracking

### App Lifecycle
- AppStateManager - State transitions
- AppLifecycleObserver - Background/foreground
- NetworkMonitor - Connectivity tracking

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-14  
**Maintained By**: Engineering Team
