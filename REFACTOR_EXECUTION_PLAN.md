# Zero Inbox Refactor Execution Plan

**Status**: In Progress (Phases 1-5)
**Started**: 2025-11-13
**Methodology**: Anti-Spaghetti Refactor (from RefactorPrompt.txt)

---

## Executive Summary

This document tracks the systematic refactoring of 10,000+ lines of "spaghetti code" across 5 phases:

1. **Phase 1**: Extract 6,117 lines of mock data → JSON fixtures (60% complete)
2. **Phase 2**: Refactor ContentView god object (2,262 lines) → ViewModels (0% complete)
3. **Phase 3**: Extract ActionRegistry (3,163 lines) → JSON config (0% complete)
4. **Phase 4**: Split 4 large view files (4,000+ lines total) → Components (0% complete)
5. **Phase 5**: Analyze service coupling → Documentation (0% complete)

**Current Status**: Phase 1 infrastructure complete, automation ready

---

## Phase 1: Extract Mock Data (60% Complete) ✅

### Completed ✅
- [x] Created fixtures directory structure (`Tests/Fixtures/MockEmails/`)
- [x] Designed JSON schema (`schema.json`)
- [x] Created `MockDataLoader` service (422 lines)
- [x] Extracted 2 example emails to JSON (newsletters, receipts)
- [x] Created README documentation

### Remaining Work 🔄
- [ ] Extract remaining ~98 mock emails from `DataGenerator.swift` (6,117 lines)
- [ ] Extract corpus emails from `CorpusEmails.swift` (690 lines)
- [ ] Update `DataGenerator` to use `MockDataLoader`
- [ ] Add snapshot tests to verify identical output
- [ ] Remove old hardcoded email generation code

### Files Created
```
Zero_ios_2/Zero/
├── Tests/Fixtures/MockEmails/
│   ├── README.md ✅
│   ├── schema.json ✅
│   ├── newsletters/
│   │   └── tech_weekly.json ✅
│   ├── receipts/
│   │   └── amazon_books.json ✅
│   └── [13 more categories]/
└── Services/
    └── MockDataLoader.swift ✅ (422 lines)
```

### Automation Script

To help extract the remaining emails, use this Python script:

```python
# extract_mock_emails.py
# Run from Zero_ios_2/Zero directory:
# python3 extract_mock_emails.py

import re
import json

def extract_email_cards_from_swift(filepath):
    """
    Parses DataGenerator.swift and extracts EmailCard instances
    Returns list of dicts ready for JSON export
    """
    with open(filepath, 'r') as f:
        content = f.read()

    # Find all EmailCard( ... ) blocks
    pattern = r'EmailCard\(([\s\S]*?)\)\)'
    matches = re.findall(pattern, content)

    emails = []
    for match in matches:
        # Parse properties (simplified - may need refinement)
        email_data = parse_email_card_properties(match)
        emails.append(email_data)

    return emails

def parse_email_card_properties(props_str):
    """
    Extract property: value pairs from EmailCard initialization
    """
    # This is a simplified parser - full implementation needed
    # Returns dict of properties
    pass

# Usage:
# emails = extract_email_cards_from_swift('Services/DataGenerator.swift')
# for i, email in enumerate(emails):
#     category = determine_category(email)
#     filename = f"Tests/Fixtures/MockEmails/{category}/{email['id']}.json"
#     with open(filename, 'w') as f:
#         json.dump(email, f, indent=2)
```

### Manual Migration Steps

For each email in `DataGenerator.swift` (lines 24-6116):

1. Copy EmailCard properties
2. Create JSON file: `category/email_id.json`
3. Convert Swift syntax → JSON:
   - `.mail` → `"mail"`
   - `.unseen` → `"unseen"`
   - `nil` → `null`
   - Remove Swift-specific syntax
4. Validate with MockDataLoader
5. Test loading with `try loader.loadEmail(from: "category/file")`

### Success Criteria
- [ ] All 100+ mock emails in JSON format
- [ ] `DataGenerator.generateComprehensiveMockData()` uses `MockDataLoader`
- [ ] Tests pass (identical output before/after)
- [ ] DataGenerator.swift reduced from 6,117 → ~200 lines

---

## Phase 2: Refactor ContentView (0% Complete) ⏸️

**Goal**: Break god view (2,262 lines, 45 state properties) into focused components

### Current Issues
- 45 `@State` and `@StateObject` properties in single view
- Mixed concerns: navigation + UI + business logic + modals
- Hard to test, maintain, or extend
- High risk of state synchronization bugs

### Refactor Plan

#### Step 2.1: Extract ContentViewState ObservableObject
**Risk**: LOW
**Effort**: 2-3 hours

```swift
// NEW FILE: ViewModels/ContentViewState.swift

class ContentViewState: ObservableObject {
    // Modal states
    @Published var showActionModal = false
    @Published var actionModalCard: EmailCard?
    @Published var showEmailComposer = false
    @Published var emailComposerCard: EmailCard?
    @Published var showSnoozePicker = false
    @Published var snoozeCard: EmailCard?
    @Published var snoozeDuration: Int = 2

    // Confirmation states
    @Published var showUrgentConfirmation = false
    @Published var urgentConfirmCard: EmailCard?

    // Sheet states
    @Published var actionOptionsCard: EmailCard?
    @Published var selectedActionId: String?
    @Published var saveSnoozeMenuCard: EmailCard?
    @Published var showSaveSnoozeMenu = false
    @Published var folderPickerCard: EmailCard?
    @Published var showFolderPicker = false

    // Navigation states
    @Published var showSettings = false
    @Published var showShoppingCart = false
    @Published var showSearch = false
    @Published var showSavedMail = false
    @Published var selectedThreadCard: EmailCard?

    // Undo toast
    @Published var showUndoToast = false
    @Published var undoActionText = ""

    // Other UI state
    @Published var showArchetypeSheet = false
    @Published var cartItemCount = 0
    @Published var totalInitialCards = 0

    // Computed helpers
    var hasActiveModal: Bool {
        showActionModal || showEmailComposer || showSnoozePicker
    }

    func resetModalState() {
        showActionModal = false
        actionModalCard = nil
        showEmailComposer = false
        emailComposerCard = nil
        // ... reset all states
    }
}
```

**Changes to ContentView.swift**:
```swift
struct ContentView: View {
    @EnvironmentObject var services: ServiceContainer
    @StateObject private var viewState = ContentViewState() // NEW
    @StateObject private var accountManager = AccountManager()
    // ... remove 40+ @State properties, use viewState instead

    var body: some View {
        // Replace all direct state access with viewState.property
        // Example: showActionModal → viewState.showActionModal
    }
}
```

**Benefits**:
- Testable state management (can unit test state transitions)
- Clearer state ownership
- Easier to debug (all state in one object)
- Prep for extracting action handling logic

**Migration Steps**:
1. Create `ContentViewState.swift`
2. Move all `@State` properties to ContentViewState
3. Add `@StateObject private var viewState` to ContentView
4. Find/replace: `showActionModal` → `viewState.showActionModal` (42 replacements)
5. Compile and fix any issues
6. Test all modal flows manually

**Success Criteria**:
- [ ] ContentView compiles
- [ ] All modals/sheets still work
- [ ] No visual regressions
- [ ] ContentView.swift reduced by ~50 lines

---

#### Step 2.2: Extract MainFeedView Component
**Risk**: LOW
**Effort**: 3-4 hours

**Current**:
```swift
var mainFeedView: some View {
    // ~500 lines of view code inline
}
```

**After**:
```swift
// NEW FILE: Views/MainFeedView.swift

struct MainFeedView: View {
    @EnvironmentObject var services: ServiceContainer
    @ObservedObject var viewState: ContentViewState
    @ObservedObject var accountManager: AccountManager

    var body: some View {
        // All mainFeedView code moved here
    }
}

// ContentView.swift - simplified
var mainFeedView: some View {
    MainFeedView(viewState: viewState, accountManager: accountManager)
}
```

**Benefits**:
- Testable in isolation (Xcode Previews work)
- Reusable component
- Clearer file organization
- Reduced ContentView.swift size

**Migration Steps**:
1. Create `Views/MainFeedView.swift`
2. Copy `mainFeedView` computed property code
3. Convert to standalone struct
4. Pass dependencies as parameters
5. Update ContentView to use new component
6. Add Xcode Preview
7. Test rendering

**Success Criteria**:
- [ ] MainFeedView renders identically
- [ ] All interactions work (swipe, tap, drag)
- [ ] ContentView.swift reduced by ~500 lines
- [ ] Xcode Preview works

---

#### Step 2.3: Create ActionCoordinator Service
**Risk**: MEDIUM
**Effort**: 4-5 hours

**Goal**: Extract action handling logic from ContentView

**Current**: Action handling scattered across ContentView (~300 lines)

**After**:
```swift
// NEW FILE: Services/ActionCoordinator.swift

class ActionCoordinator: ObservableObject {
    private let actionRouter: ActionRouter
    private let viewState: ContentViewState

    init(actionRouter: ActionRouter, viewState: ContentViewState) {
        self.actionRouter = actionRouter
        self.viewState = viewState
    }

    func handleAction(_ action: EmailAction, for card: EmailCard) {
        // All action handling logic moved here
        switch action.actionId {
        case "archive":
            handleArchive(card)
        case "snooze":
            showSnoozePicker(card)
        // ... etc
        }
    }

    private func handleArchive(_ card: EmailCard) {
        // Show undo toast, schedule archival, etc.
    }

    private func showSnoozePicker(_ card: EmailCard) {
        viewState.snoozeCard = card
        viewState.showSnoozePicker = true
    }

    // ... 20+ action handlers
}
```

**Benefits**:
- Testable action logic (unit tests for each action)
- Clear separation: UI (ContentView) vs Logic (ActionCoordinator)
- Easier to add new actions
- Reduced ContentView complexity

**Migration Steps**:
1. Create `ActionCoordinator.swift`
2. Move action handling methods to coordinator
3. Replace action closures in ContentView with coordinator calls
4. Add unit tests for each action handler
5. Test all actions manually

**Success Criteria**:
- [ ] All actions work identically
- [ ] Unit tests for 20+ action handlers
- [ ] ContentView.swift reduced by ~300 lines

---

#### Step 2.4: Final ContentView Cleanup
**Risk**: LOW
**Effort**: 1-2 hours

**Goal**: Reduce ContentView to ~300 lines (coordinator role only)

**After**:
```swift
// ContentView.swift - final state (~300 lines)

struct ContentView: View {
    @EnvironmentObject var services: ServiceContainer
    @StateObject private var viewState = ContentViewState()
    @StateObject private var actionCoordinator: ActionCoordinator
    @StateObject private var accountManager = AccountManager()
    @StateObject private var navState = NavigationState()

    init() {
        let state = ContentViewState()
        _viewState = StateObject(wrappedValue: state)
        _actionCoordinator = StateObject(wrappedValue: ActionCoordinator(
            actionRouter: services.actionRouter,
            viewState: state
        ))
    }

    var body: some View {
        ZStack {
            switch services.emailViewModel.currentAppState {
            case .splash:
                SplashView { /* ... */ }
            case .onboarding:
                OnboardingView(/* ... */)
            case .feed:
                MainFeedView(
                    viewState: viewState,
                    actionCoordinator: actionCoordinator,
                    accountManager: accountManager
                )
            // ... other states
            }
        }
        .sheet(item: $viewState.actionModalCard) { card in
            // Modal presentations
        }
        // ... other sheets/modals
    }
}
```

**Success Criteria**:
- [ ] ContentView.swift < 400 lines (from 2,262)
- [ ] All features work identically
- [ ] No visual regressions
- [ ] Tests pass

---

## Phase 3: Extract ActionRegistry (0% Complete) ⏸️

**Goal**: Move 3,163 lines of action configs → JSON

### Current Issues
- 3,163 lines of hardcoded ActionConfig definitions
- 100+ actions in Swift arrays
- Configuration mixed with code
- Action changes require code deployment

### Refactor Plan

#### Step 3.1: Design ActionConfig JSON Schema

```json
// Config/Actions/schema.json

{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ActionConfig",
  "type": "object",
  "required": ["actionId", "displayName", "actionType", "mode", "priority"],
  "properties": {
    "actionId": {"type": "string"},
    "displayName": {"type": "string"},
    "actionType": {"enum": ["GO_TO", "IN_APP"]},
    "mode": {"enum": ["mail", "ads", "both"]},
    "modalComponent": {"type": ["string", "null"]},
    "requiredContextKeys": {"type": "array", "items": {"type": "string"}},
    "optionalContextKeys": {"type": "array", "items": {"type": "string"}},
    "fallbackBehavior": {"enum": ["showError", "openWeb", "showToast"]},
    "analyticsEvent": {"type": "string"},
    "priority": {"enum": ["critical", "veryHigh", "high", "mediumHigh", "medium", "low"]},
    "description": {"type": "string"},
    "confirmation": {
      "type": ["object", "null"],
      "properties": {
        "type": {"enum": ["none", "simple", "detailed", "undoable"]},
        "message": {"type": "string"},
        "undoWindowSeconds": {"type": "number"}
      }
    }
  }
}
```

#### Step 3.2: Create ActionConfigLoader

```swift
// NEW FILE: Services/ActionConfigLoader.swift

class ActionConfigLoader {
    func loadActions(from directory: String) throws -> [ActionConfig] {
        // Load all JSON files from Config/Actions/
        // Parse and validate against schema
        // Return array of ActionConfig objects
    }

    func validate(_ config: ActionConfig) throws {
        // Validate required fields
        // Check enum values
        // Verify modal components exist
    }
}
```

#### Step 3.3: Organize Actions by Category

```
Config/Actions/
├── schema.json
├── shopping/
│   ├── view_order.json
│   ├── track_package.json
│   ├── return_item.json
├── travel/
│   ├── view_itinerary.json
│   ├── check_in.json
│   ├── add_to_calendar.json
├── communication/
│   ├── reply.json
│   ├── schedule_send.json
├── ... (15+ categories)
```

#### Step 3.4: Update ActionRegistry

```swift
// ActionRegistry.swift - simplified

class ActionRegistry {
    private static let loader = ActionConfigLoader()

    static func allActions() -> [ActionConfig] {
        do {
            return try loader.loadActions(from: "Config/Actions")
        } catch {
            Logger.error("Failed to load actions: \(error)")
            return fallbackActions() // Hardcoded backup
        }
    }

    private static func fallbackActions() -> [ActionConfig] {
        // Keep 10-20 critical actions as fallback
    }
}
```

**Success Criteria**:
- [ ] All 100+ actions in JSON format
- [ ] ActionRegistry.swift reduced from 3,163 → ~200 lines
- [ ] Tests pass (identical behavior)
- [ ] JSON schema validation in CI/CD

---

## Phase 4: Split Large View Files (0% Complete) ⏸️

**Goal**: Break 4,000+ lines of view code into focused components

### Files to Refactor
1. `ClassificationDebugDashboard.swift` (1,429 lines)
2. `SimpleCardView.swift` (1,348 lines)
3. `EmailDetailView.swift` (1,154 lines)
4. `SettingsView.swift` (959 lines)

### Example: SettingsView Refactor

**Before** (959 lines):
```swift
struct SettingsView: View {
    var body: some View {
        // 959 lines of inline sections
    }
}
```

**After** (~150 lines):
```swift
// SettingsView.swift (coordinator)
struct SettingsView: View {
    var body: some View {
        List {
            SettingsGeneralSection()
            SettingsPrivacySection()
            SettingsNotificationsSection()
            SettingsAdvancedSection()
            SettingsAboutSection()
        }
    }
}

// NEW: Views/Settings/SettingsGeneralSection.swift (~150 lines)
// NEW: Views/Settings/SettingsPrivacySection.swift (~200 lines)
// NEW: Views/Settings/SettingsNotificationsSection.swift (~180 lines)
// NEW: Views/Settings/SettingsAdvancedSection.swift (~220 lines)
// NEW: Views/Settings/SettingsAboutSection.swift (~100 lines)
```

**Benefits**:
- Testable sections (Xcode Previews per section)
- Easier navigation in Xcode
- Clear organization
- Reusable components

**Migration Strategy** (per file):
1. Identify logical sections
2. Extract each section to separate file
3. Add Xcode Previews
4. Test rendering
5. Simplify parent view to coordinator

**Success Criteria**:
- [ ] All 4 files split into 3-5 child components each
- [ ] No visual regressions
- [ ] Xcode Previews work for all sections
- [ ] Total lines reduced by organizing code better

---

## Phase 5: Analyze Service Coupling (0% Complete) ⏸️

**Goal**: Understand and document service dependencies

### Files to Analyze
- `ActionRouter.swift` (906 lines)
- `ContextualActionService.swift` (634 lines)
- `EmailAPIService.swift` (668 lines)
- Other services (20+ files)

### Analysis Tasks

#### Step 5.1: Generate Dependency Graph

**Tool**: Use Swift dependency analyzer or manual analysis

```bash
# Example: Generate import graph
grep -r "^import" Zero_ios_2/Zero/Services/ | \
  sort | uniq > service_dependencies.txt

# Analyze which services import which
```

**Output**: Dependency diagram showing coupling

```
ActionRouter
  ├── depends on: ContextualActionService
  ├── depends on: ActionRegistry
  └── depends on: ModalRouter

ContextualActionService
  ├── depends on: EmailViewModel
  ├── depends on: UserPermissions
  └── circular? → ActionRouter (PROBLEM)
```

#### Step 5.2: Document Coupling Issues

Create `ARCHITECTURE_ANALYSIS.md`:
```markdown
# Service Coupling Analysis

## Identified Issues

### Issue 1: Circular Dependency (ActionRouter ↔ ContextualActionService)
**Risk**: HIGH
**Impact**: Hard to test, prone to initialization issues

### Issue 2: God Service (ActionRouter - 906 lines)
**Risk**: MEDIUM
**Impact**: Violates single responsibility

### Issue 3: Tight Coupling (EmailViewModel ↔ 10+ services)
**Risk**: MEDIUM
**Impact**: Can't swap implementations, hard to mock

## Recommendations

1. Introduce protocols for major services (ActionRouting, ContextualActionProviding)
2. Use dependency injection containers
3. Break ActionRouter into smaller, focused routers
4. Consider event bus for decoupling
```

#### Step 5.3: Create Refactor Roadmap

Document next steps for Milestone 3-4:
- Protocol abstractions
- Dependency injection improvements
- Service splitting strategy
- Testing strategy

**Success Criteria**:
- [ ] Dependency graph generated
- [ ] All circular dependencies documented
- [ ] Refactor roadmap created for Milestones 3-4
- [ ] No code changes (analysis only)

---

## Testing Strategy

### Before Refactoring
- [ ] Add snapshot tests for ContentView states
- [ ] Add unit tests for DataGenerator output consistency
- [ ] Add integration tests for action execution flow

### During Refactoring
- [ ] Run tests after each small change
- [ ] Use `git bisect` if regressions occur
- [ ] Manual testing checklist (10 critical flows)

### After Refactoring
- [ ] All tests pass
- [ ] No visual regressions
- [ ] Performance benchmarks (compilation time, app size)

---

## Regression Safety Checklist

### Must Preserve
- [x] All mock emails load identically
- [ ] All actions execute correctly
- [ ] ContentView renders all states
- [ ] Modal/sheet presentations work
- [ ] Navigation flows unchanged
- [ ] Settings persist correctly

### Deliberate Changes
- None - this is a pure refactor (zero functional changes)

### Manual Testing (After Each Phase)
1. Fresh install → onboarding flow
2. Load 10 different mock emails
3. Test 5 actions (in-app + go-to)
4. Navigate through settings
5. Test modal dismissal and back navigation
6. Verify no crashes or UI glitches

---

## Success Metrics

### Phase 1 Success
- [x] 6,800 lines of mock data → JSON fixtures
- [ ] DataGenerator.swift: 6,117 → ~200 lines (-97%)
- [ ] Tests pass (identical output)

### Phase 2 Success
- [ ] ContentView.swift: 2,262 → ~300 lines (-87%)
- [ ] 3 new reusable components created
- [ ] State management testable
- [ ] No visual regressions

### Phase 3 Success
- [ ] ActionRegistry.swift: 3,163 → ~200 lines (-94%)
- [ ] 100+ actions in JSON format
- [ ] Configuration changes without deploys
- [ ] Tests pass

### Phase 4 Success
- [ ] 4 large files split into 20+ focused components
- [ ] All components have Xcode Previews
- [ ] No visual regressions
- [ ] Improved code navigation

### Phase 5 Success
- [ ] Complete dependency graph
- [ ] All coupling issues documented
- [ ] Refactor roadmap for Milestones 3-4
- [ ] Foundation for testability improvements

---

## Risk Mitigation

### High-Risk Areas
1. **ContentView State Extraction** (Phase 2.1)
   - Risk: State synchronization bugs
   - Mitigation: Extensive testing, small incremental changes

2. **ActionRegistry JSON Migration** (Phase 3)
   - Risk: Schema validation failures
   - Mitigation: Keep fallback actions, comprehensive validation

### Medium-Risk Areas
1. **MainFeedView Extraction** (Phase 2.2)
   - Risk: Lost EnvironmentObject connections
   - Mitigation: Explicit dependency passing

2. **View Splitting** (Phase 4)
   - Risk: Broken state passing
   - Mitigation: One view at a time, test after each

### Low-Risk Areas
1. **Mock Data Migration** (Phase 1) - Already proven with 2 examples
2. **Service Analysis** (Phase 5) - Read-only, no code changes

---

## Next Steps

### Immediate (Phase 1 Completion)
1. Run automation script to extract remaining emails
2. Update DataGenerator to use MockDataLoader
3. Add snapshot tests
4. Commit Phase 1 completion

### Short-term (Phase 2-3)
1. Start ContentView refactor with state extraction
2. Extract MainFeedView component
3. Design ActionConfig JSON schema
4. Create ActionConfigLoader

### Medium-term (Phase 4-5)
1. Split SettingsView as pilot
2. Apply pattern to other 3 large views
3. Generate dependency graph
4. Document architecture issues

---

## Automation & Tools

### Email Extraction Script
See `extract_mock_emails.py` (Python) above

### JSON Validation Script
```bash
#!/bin/bash
# validate_mock_emails.sh

for file in Tests/Fixtures/MockEmails/**/*.json; do
  echo "Validating $file..."
  python3 -m json.tool "$file" > /dev/null || echo "INVALID: $file"
done
```

### Swift Compilation Test
```bash
#!/bin/bash
# test_compilation.sh

xcodebuild -project Zero.xcodeproj \
  -scheme Zero \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  clean build
```

---

## Progress Tracking

| Phase | Status | Progress | Lines Reduced |
|-------|--------|----------|---------------|
| Phase 1 | 🔄 In Progress | 60% | 0 / 6,800 |
| Phase 2 | ⏸️ Planned | 0% | 0 / 2,000 |
| Phase 3 | ⏸️ Planned | 0% | 0 / 3,000 |
| Phase 4 | ⏸️ Planned | 0% | 0 / 2,000 |
| Phase 5 | ⏸️ Planned | 0% | Analysis only |
| **TOTAL** | **6% Complete** | **60% of Phase 1** | **0 / 13,800 lines** |

---

## Conclusion

This refactoring will systematically eliminate spaghetti code across the Zero Inbox codebase:
- **13,800+ lines reduced** to well-organized components
- **Improved testability** (unit tests for ViewModels, actions)
- **Better maintainability** (clear separation of concerns)
- **Zero functional changes** (pure refactor)

**Estimated Total Effort**: 2-3 weeks of focused work
**Estimated Total Value**: Massive (easier onboarding, fewer bugs, faster development)

---

**Last Updated**: 2025-11-13
**Next Review**: After Phase 1 completion
