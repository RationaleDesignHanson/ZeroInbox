# Routing Architecture - Zero iOS

**Last Updated**: 2025-11-14 (Post-Week 2 Cleanup)
**Status**: Single routing system (ActionRouter v1.2 only)

---

## Executive Summary

Zero iOS uses a **single routing system** based on ActionRouter (v1.2) for all modal navigation. The legacy ModalRouter (v1.0) was removed in Week 2 cleanup after confirming it was dead code.

**Current Flow**:
```
User triggers action → ActionRouter → ActionRegistry → Modal displayed
```

**Key Files**:
- `Services/ActionRouter.swift` (906 lines) - Main routing service
- `Services/ActionRegistry.swift` (3,163 lines) - Action definitions
- `Services/ActionLoader.swift` (379 lines) - JSON action configuration
- `Zero/ContentView.swift` - Modal presentation logic

---

## Architecture Overview

### Routing Decision (ContentView.swift:170-187)

```swift
@ViewBuilder
func getActionModalView(for card: EmailCard) -> some View {
    // ROUTING STRATEGY:
    // 1. Check if user manually selected an action (via swipe up menu)
    // 2. Use ActionRouter (v1.2) for all cards with suggestedActions
    // Note: ALL cards now have suggestedActions - legacy ModalRouter (v1.0) path removed in Week 2 cleanup

    if let suggestedActions = card.suggestedActions, !suggestedActions.isEmpty {
        // Determine which action to execute and log routing decision
        let (actionToExecute, wasUserSelected) = determineActionToExecute(
            suggestedActions: suggestedActions,
            card: card
        )

        // Modern card with v1.2 action-first architecture
        actionRouterModalView(for: actionToExecute, card: card)
            .onAppear {
                Logger.info("🔍 Modal routing: executing=\(actionToExecute.actionId), type=\(actionToExecute.actionType == .goTo ? "GO_TO" : "IN_APP"), userSelected=\(wasUserSelected), count=\(suggestedActions.count)", category: .action)
            }
    }
}
```

**Key Points**:
- ALL cards have `suggestedActions` array populated
- No conditional branching - single routing path
- Legacy ModalRouter removed (Week 2: deleted 1,587 lines)

---

## ActionRouter Flow

### Step 1: User Triggers Action

**Entry Points**:
1. **Swipe right** → Execute primary action
2. **Swipe up** → Show action menu → User selects action
3. **Direct tap** → Execute specific action

**Code** (ContentView.swift):
```swift
// Swipe handler
func handleSwipe(direction: SwipeDirection, card: EmailCard) {
    if direction == .right {
        // Execute primary action from suggestedActions
        if let primaryAction = card.suggestedActions?.first(where: { $0.isPrimary }) {
            ActionRouter.shared.executeAction(primaryAction, card: card)
        }
    }
}
```

---

### Step 2: ActionRouter.executeAction()

**File**: `Services/ActionRouter.swift`

```swift
func executeAction(_ action: EmailAction, card: EmailCard, from viewController: UIViewController? = nil) {
    // STEP 1: Registry lookup
    guard let actionConfig = ActionRegistry.shared.getAction(action.actionId) else {
        Logger.error("Action '\(action.actionId)' not found in registry", category: .action)
        showError("Action not available")
        return
    }

    // STEP 2: Mode validation (Mail vs Ads mode)
    if !ActionRegistry.shared.isActionValidForMode(action.actionId, currentMode: currentMode) {
        Logger.warning("Action '\(action.actionId)' not valid for \(currentMode.rawValue) mode", category: .action)
        showError("Not available in \(currentMode.rawValue) mode")
        return
    }

    // STEP 3: Context validation with placeholder fallback
    let validationResult = ActionRegistry.shared.validateAction(
        actionId: action.actionId,
        context: action.context ?? [:]
    )

    var finalContext = action.context ?? [:]
    if !validationResult.isValid {
        // Apply placeholders for missing required fields
        finalContext = ActionPlaceholders.applyPlaceholders(
            to: finalContext,
            for: action.actionId,
            using: card
        )
    }

    // STEP 4: Execute based on action type
    if action.actionType == .goTo {
        // External URL navigation
        handleGoToAction(action: action, context: finalContext)
    } else {
        // In-app modal
        handleInAppAction(action: action, card: card, context: finalContext)
    }

    // STEP 5: Analytics tracking
    AnalyticsService.shared.trackAction(
        actionId: action.actionId,
        cardType: card.type,
        wasUserSelected: wasUserSelected
    )
}
```

---

### Step 3: ActionRegistry Lookup

**File**: `Services/ActionRegistry.swift`

**Hybrid System** (Phase 3 Integration):
```swift
func getAction(id: String) -> ActionConfig? {
    // 1. Check JSON files first (via ActionLoader)
    if let jsonAction = ActionLoader.shared.loadAction(id: id) {
        return jsonAction
    }

    // 2. Fall back to hardcoded Swift registry
    return swiftActions[id]
}
```

**Why Hybrid**:
- JSON actions: Easy to modify without recompilation (15 actions in mail-actions.json)
- Swift actions: Full type safety, compiled performance (~85 actions)
- Gradual migration path from Swift → JSON

**JSON Actions** (Config/Actions/mail-actions.json):
```json
{
  "track_package": {
    "displayName": "Track Package",
    "modalComponent": "TrackPackageModal",
    "actionType": "IN_APP",
    "priority": 90,
    "modes": ["mail"],
    "requiredContext": ["trackingNumber", "carrier"]
  }
}
```

---

### Step 4: Modal Construction

**File**: `Zero/ContentView.swift` (actionRouterModalView function)

```swift
@ViewBuilder
private func actionRouterModalView(for action: EmailAction, card: EmailCard) -> some View {
    let modalType = ActionRouter.shared.getModalType(for: action, card: card)

    switch modalType {
    case .trackPackage(let card, let trackingNumber, let carrier, let trackingUrl, let context):
        TrackPackageModal(
            card: card,
            trackingNumber: trackingNumber,
            carrier: carrier,
            trackingUrl: trackingUrl,
            context: context,
            isPresented: $viewState.showActionModal
        )

    case .payInvoice(let card, let invoiceId, let amount, let merchant, let context):
        PayInvoiceModal(
            card: card,
            invoiceId: invoiceId,
            amount: amount,
            merchant: merchant,
            context: context,
            isPresented: $viewState.showActionModal
        )

    // ... 44 more modal cases
    }
}
```

**Modal Count**: 46 action modals (Views/ActionModules/)

---

## Action Models

### EmailCard (Models/EmailCard.swift)

```swift
struct EmailCard: Identifiable, Codable {
    let id: String
    let type: CardType  // .mail or .ads
    let hpa: String     // Legacy field (v1.0) - kept for backward compatibility
    let suggestedActions: [EmailAction]?  // Modern field (v1.1+)

    // Computed property for backward compatibility
    var suggestedAction: String {
        return suggestedActions?.first(where: { $0.isPrimary })?.actionId ?? "view_document"
    }
}
```

**Backward Compatibility Strategy**:
- `hpa` field retained but unused in routing
- Backend returns both fields
- Frontend only uses `suggestedActions`

---

### EmailAction (Models/EmailCard.swift)

```swift
struct EmailAction: Codable, Identifiable, Equatable {
    let actionId: String           // e.g., "track_package"
    let displayName: String        // e.g., "Track Package"
    let actionType: ActionType     // .inApp or .goTo
    let isPrimary: Bool           // Primary action shown on right swipe
    let priority: Int             // 0-100, affects ordering
    var context: [String: String]? // Context data for modal
}

enum ActionType: String, Codable {
    case inApp = "IN_APP"  // Opens modal in app
    case goTo = "GO_TO"    // Opens external URL (Safari)
}
```

**Primary Action Selection**:
- Each card has 1-5 suggested actions
- Exactly ONE action has `isPrimary = true`
- Primary action executes on right swipe
- Other actions available in swipe-up menu

---

## Action Registry Structure

### ActionConfig (Services/ActionRegistry.swift)

```swift
struct ActionConfig {
    let actionId: String
    let displayName: String
    let modalComponent: String          // Modal class name
    let actionType: ActionType          // IN_APP or GO_TO
    let urlTemplate: String?           // For GO_TO actions
    let modes: [String]                // ["mail"] or ["ads"] or ["mail", "ads"]
    let priority: Int                  // 0-100
    let requiredContext: [String]      // Required context keys
    let optionalContext: [String]      // Optional context keys
    let category: String?              // "shipping", "payment", etc.
    let confirmationRequired: Bool     // Show confirmation before action
    let undoToastMessage: String?      // Toast message after completion
}
```

### Registry Organization

**By Priority** (High → Low):
```
Premium Actions (90-100):
- track_package (90)
- pay_invoice (100)
- check_in_flight (100)
- sign_form (95)

High Priority (70-89):
- contact_driver (85)
- quick_reply (85)
- view_pickup_details (80)
- schedule_meeting (75)

Standard (0-69):
- view_document (50)
- add_reminder (50)
- acknowledge (30)
```

**By Mode**:
```
Mail-only: 78 actions
Ads-only: 8 actions
Both: 14 actions
Total: 100 actions
```

**By Category**:
```
shipping: 12 actions (track_package, view_pickup_details, etc.)
payment: 8 actions (pay_invoice, update_payment, etc.)
communication: 15 actions (quick_reply, schedule_meeting, etc.)
document: 10 actions (view_document, sign_form, etc.)
shopping: 6 actions (browse_shopping, automated_add_to_cart, etc.)
```

---

## Context & Placeholders

### Context Flow

```swift
// 1. Backend provides context
EmailAction(
    actionId: "track_package",
    context: [
        "trackingNumber": "1Z999AA10123456784",
        "carrier": "UPS",
        "trackingUrl": "https://ups.com/track?id=..."
    ]
)

// 2. ActionRouter validates context
let validationResult = ActionRegistry.shared.validateAction(
    actionId: "track_package",
    context: action.context ?? [:]
)

// 3. If missing required fields, apply placeholders
if !validationResult.isValid {
    finalContext = ActionPlaceholders.applyPlaceholders(
        to: action.context,
        for: "track_package",
        using: card  // Extract from EmailCard fields
    )
}

// 4. Modal receives complete context
TrackPackageModal(
    trackingNumber: finalContext["trackingNumber"],
    carrier: finalContext["carrier"],
    trackingUrl: finalContext["trackingUrl"]
)
```

### ActionPlaceholders (Services/ActionPlaceholders.swift)

```swift
static func applyPlaceholders(
    to context: [String: String],
    for actionId: String,
    using card: EmailCard
) -> [String: String] {
    var result = context

    // Extract from card fields
    if actionId == "track_package" && context["trackingNumber"] == nil {
        result["trackingNumber"] = extractTrackingNumber(from: card)
    }

    if context["carrier"] == nil {
        result["carrier"] = card.company?.name ?? "Unknown Carrier"
    }

    return result
}
```

**Fallback Strategy**:
1. Use backend-provided context
2. Extract from EmailCard fields (company, sender, etc.)
3. Use sensible defaults ("Unknown", "N/A")
4. Display modal with partial data (better than no modal)

---

## Modal Types

### ActionModal Enum (Services/ActionRouter.swift)

```swift
enum ActionModal: Identifiable {
    // Premium Actions
    case trackPackage(card: EmailCard, trackingNumber: String, carrier: String, trackingUrl: String, context: [String: Any])
    case payInvoice(card: EmailCard, invoiceId: String, amount: String, merchant: String, context: [String: Any])
    case checkInFlight(card: EmailCard, flightNumber: String, airline: String, checkInUrl: String, context: [String: Any])
    case signForm(card: EmailCard, context: [String: String])

    // Communication
    case quickReply(card: EmailCard, recipientEmail: String, subject: String, context: [String: Any])
    case scheduleMeeting(card: EmailCard, context: [String: Any])
    case contactDriver(card: EmailCard, driverInfo: [String: Any])

    // Document Actions
    case viewDetails(card: EmailCard, context: [String: Any])
    case addReminder(card: EmailCard, context: [String: Any])

    // ... 37 more cases (46 total)

    var id: String {
        switch self {
        case .trackPackage: return "track_package"
        case .payInvoice: return "pay_invoice"
        // ... generate unique IDs
        }
    }
}
```

**Total Modals**: 46 in `/Views/ActionModules/`

---

## GO_TO vs IN_APP Actions

### GO_TO Actions (External URLs)

**Handler** (ActionRouter.swift):
```swift
private func handleGoToAction(action: EmailAction, context: [String: String]) {
    // Resolve URL template with context
    guard let urlString = resolveURLTemplate(for: action.actionId, context: context),
          let url = URL(string: urlString) else {
        Logger.error("Invalid URL for action: \(action.actionId)", category: .action)
        return
    }

    // Open in Safari
    if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url)
        Logger.info("Opened external URL: \(url)", category: .action)
    }
}
```

**Examples**:
- `open_tracking_url` → Opens UPS/FedEx website
- `open_invoice_portal` → Opens payment portal
- `open_reservation_link` → Opens hotel/restaurant site

**URL Templates**:
```swift
"open_tracking_url": "https://www.ups.com/track?tracknum={trackingNumber}"
"open_invoice_portal": "{invoiceUrl}"  // From context
```

---

### IN_APP Actions (Modals)

**Handler** (ActionRouter.swift):
```swift
private func handleInAppAction(action: EmailAction, card: EmailCard, context: [String: String]) {
    // Get modal component name from registry
    guard let actionConfig = ActionRegistry.shared.getAction(action.actionId) else { return }

    // Build modal enum case
    let modalType = buildModalType(
        component: actionConfig.modalComponent,
        action: action,
        card: card,
        context: context
    )

    // Trigger modal presentation (via ContentView state)
    NotificationCenter.default.post(
        name: Notification.Name("ShowActionModal"),
        object: nil,
        userInfo: ["modalType": modalType, "card": card]
    )
}
```

**Examples**:
- `track_package` → `TrackPackageModal`
- `pay_invoice` → `PayInvoiceModal`
- `sign_form` → `SignFormModal`

---

## Analytics & Tracking

### Action Execution Tracking

```swift
// ActionRouter.swift
AnalyticsService.shared.trackAction(
    actionId: action.actionId,
    cardType: card.type,
    wasUserSelected: wasUserSelected,
    executionTime: Date(),
    context: finalContext
)
```

**Tracked Metrics**:
- Action frequency (which actions are most used)
- User-selected vs AI-suggested (primary action usage)
- Success rate (completed vs abandoned)
- Context completeness (placeholders used or not)
- Mode-specific usage (Mail vs Ads)

**Analytics Schema** (Services/AnalyticsSchema.swift):
```swift
struct ActionExecutionEvent {
    let actionId: String
    let cardType: CardType
    let wasUserSelected: Bool
    let hadCompleteContext: Bool
    let timestamp: Date
}
```

---

## Error Handling

### Validation Errors

```swift
enum ActionValidationError: Error {
    case actionNotFound(String)
    case modeNotSupported(String, CardType)
    case missingRequiredContext([String])
    case invalidContext(String)
}
```

### User-Facing Errors

```swift
// ActionRouter.swift
private func showError(_ message: String) {
    DispatchQueue.main.async {
        // Show toast notification
        NotificationCenter.default.post(
            name: Notification.Name("ShowErrorToast"),
            object: nil,
            userInfo: ["message": message]
        )
    }
}
```

**Error Messages**:
- "Action not available" - Action not in registry
- "Not available in Ads mode" - Mode validation failed
- "Unable to open URL" - GO_TO action URL invalid
- "Missing required information" - Context validation failed (with placeholders exhausted)

---

## Testing Strategy

### Unit Tests (Recommended)

```swift
// Test action registry lookup
func testActionRegistryLookup() {
    let action = ActionRegistry.shared.getAction("track_package")
    XCTAssertNotNil(action)
    XCTAssertEqual(action?.displayName, "Track Package")
}

// Test mode validation
func testModeValidation() {
    let isValid = ActionRegistry.shared.isActionValidForMode(
        "track_package",
        currentMode: .mail
    )
    XCTAssertTrue(isValid)
}

// Test context placeholders
func testPlaceholderApplication() {
    let context = ActionPlaceholders.applyPlaceholders(
        to: [:],
        for: "track_package",
        using: mockCard
    )
    XCTAssertNotNil(context["trackingNumber"])
}
```

### Integration Tests (Manual)

**Test Flow**:
1. Create test email card with suggestedActions
2. Swipe right → Verify primary action executes
3. Swipe up → Verify action menu shows all actions
4. Select action → Verify correct modal appears
5. Check analytics → Verify event logged

---

## Migration History

### v1.0 → v1.2 Migration (Week 2 Cleanup)

**v1.0 (Legacy - DELETED)**:
- ModalRouter.swift (669 lines)
- String-matching routing logic
- 50+ hardcoded modal cases
- Used `hpa` field (string-based)

**v1.2 (Current)**:
- ActionRouter.swift (906 lines)
- Registry-based routing
- 46 typed modal cases
- Uses `suggestedActions` array

**Migration** (Oct 2024 - Nov 2024):
1. Phase 1: Add `suggestedActions` to EmailCard (backward compatible)
2. Phase 2: Update backend to return both `hpa` and `suggestedActions`
3. Phase 3: Add ActionRouter alongside ModalRouter (dual routing)
4. Phase 4: Verify 100% of cards have `suggestedActions`
5. Phase 5: Remove ModalRouter conditional branch (Week 2 cleanup)
6. Phase 6: Delete ModalRouter.swift (Week 2 cleanup)

**Result**: Single routing system, -1,587 lines of code

---

## Future Improvements

### Short Term (Next 3 Months)

1. **Complete JSON Migration**:
   - Move remaining 85 Swift actions to JSON
   - Target: 100% JSON-configured actions
   - Benefit: Update actions without recompilation

2. **Action Analytics Dashboard**:
   - Which actions are most/least used
   - Success/abandonment rates
   - Context completeness metrics

3. **Smart Context Extraction**:
   - ML-based tracking number extraction
   - Better placeholder algorithms
   - Reduce manual context entry

### Long Term (Next 6 Months)

1. **Deep Linking**:
   - Open specific action from push notification
   - URL scheme: `zero://action/track_package?id=...`

2. **Action Shortcuts**:
   - Siri shortcuts for common actions
   - "Track my package" → Opens tracking modal

3. **Compound Actions**:
   - Multi-step flows (already started with CompoundActionRegistry)
   - Example: "Schedule meeting → Add to calendar → Send confirmation"

4. **Contextual Actions**:
   - Time-based actions (morning vs evening)
   - Location-based actions
   - User preference-based suggestions

---

## Key Files Reference

### Core Routing
- `Services/ActionRouter.swift` (906 lines) - Main router
- `Services/ActionRegistry.swift` (3,163 lines) - Action definitions
- `Services/ActionLoader.swift` (379 lines) - JSON loader
- `Zero/ContentView.swift` (1,529 lines) - Modal presentation

### Configuration
- `Config/Actions/action-schema.json` (161 lines) - JSON schema
- `Config/Actions/mail-actions.json` (303 lines) - 15 JSON actions

### Models
- `Models/EmailCard.swift` - Card + Action models
- `Services/ActionPlaceholders.swift` - Context fallbacks

### Modals (46 total)
- `Views/ActionModules/TrackPackageModal.swift`
- `Views/ActionModules/PayInvoiceModal.swift`
- `Views/ActionModules/SignFormModal.swift`
- ... (43 more)

---

**Last Updated**: 2025-11-14
**Next Review**: After Phase 4 (JSON migration complete)
**Maintained By**: Engineering team
