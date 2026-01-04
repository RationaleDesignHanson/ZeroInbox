# Zero Inbox Unified Modal System: Architecture & Component Specification

**Generated:** 2025-12-20
**Purpose:** Define target architecture, unified component system, and migration strategy for modal unification

**Based on:**
- `docs/action-audit.md` (current system inventory)
- `docs/action-modal-gaps.md` (issues and opportunities)

---

## Executive Summary

### Current State
- **3 conflicting modal patterns:** JSON-driven, custom SwiftUI, hardcoded
- **46 modal files** (~11,000 lines) with inconsistent patterns
- **20+ JSON configs** (30% coverage)
- **Technical debt:** Unused coordinator, bloated router, duplicate logic

### Recommended Architecture
**Hybrid Approach: JSON-First with SwiftUI Fallback**
- **80% of actions:** JSON-driven generic modals (simple display, forms, confirmations)
- **15% of actions:** Custom SwiftUI modals (complex interactions requiring native code)
- **5% of actions:** Inline/shared modals (very simple confirmations, copy actions)
- **Shared component library** used by all patterns

### Migration Strategy
- **Wave 1:** High-fidelity premium actions (validate hybrid approach)
- **Wave 2:** Standard mail actions (prove scalability)
- **Wave 3:** Compound flows (multi-step consistency)
- **Wave 4:** Remaining actions (complete migration)

### Success Metrics
- **Single modal creation path** for 90% of new actions
- **<5,000 lines** of modal code (down from 11,000)
- **100% JSON config** coverage for eligible actions
- **Routing logic** moved to ActionModalCoordinator
- **Test harness** validates all modals

---

## 1. Architectural Analysis

### 1.1 Pattern Comparison

| Criteria | JSON-Driven | Custom SwiftUI | Hardcoded in Router | **Hybrid (Recommended)** |
|----------|-------------|----------------|---------------------|--------------------------|
| **Flexibility** | Medium (limited to 24 field types) | High (full SwiftUI) | Low (simple only) | **High** (best of both) |
| **Maintainability** | High (data-driven) | Medium (46 files) | Low (bloats router) | **High** (clear boundaries) |
| **Designer Access** | High (edit JSON) | Low (need developer) | None | **High** (JSON for most) |
| **Type Safety** | Medium (runtime validation) | High (compile-time) | Low | **High** (both available) |
| **Debugging** | Medium (logic in renderer) | High (straightforward) | Low (hard to find) | **High** (clear patterns) |
| **Code Volume** | Low (~200 lines renderer) | High (11,000 lines) | Medium | **Low** (5,000 lines target) |
| **Performance** | High (shared renderer) | Medium (46 views) | High | **High** (optimized rendering) |
| **Testing** | Medium (need test configs) | High (per-modal tests) | Low | **High** (both testable) |
| **Extensibility** | Medium (add field types) | High (unlimited) | Low | **High** (extend either side) |
| **Learning Curve** | Low (JSON syntax) | Medium (SwiftUI + patterns) | Low | **Medium** (clear guidelines) |

### 1.2 Current System Statistics

| Pattern | Current Usage | Target Usage | Change |
|---------|---------------|--------------|--------|
| JSON-Driven Generic | 20 actions (30%) | ~53 actions (80%) | +33 actions |
| Custom SwiftUI | 46 files (100% of IN_APP) | ~10 files (15%) | -36 files |
| Hardcoded in Router | ~5 actions (8%) | ~3 actions (5%) | -2 actions |

---

## 2. Recommended Architecture: Hybrid JSON-First

### 2.1 Decision Rationale

**Choose JSON-Driven when:**
✅ Display-only modals (tracking, reservations, itineraries)
✅ Simple forms (add reminder, schedule meeting, save contact)
✅ Confirmations (RSVP, cancel subscription, unsubscribe)
✅ Status views (delivery status, account verification progress)
✅ Action requires no complex business logic
✅ UI can be described declaratively
✅ Designer needs to iterate on UI without developer

**Choose Custom SwiftUI when:**
❌ Complex interactions (signature capture, map annotations, drag/drop)
❌ Native iOS integrations (PassKit, MessageUI, EventKit with custom UI)
❌ Real-time state updates (payment processing, file uploads)
❌ Custom animations or transitions
❌ Performance-critical rendering (large lists, heavy computation)
❌ Proprietary UI patterns not achievable via JSON

**Choose Inline/Shared when:**
⚡️ Very simple confirmation (1-2 buttons, short message)
⚡️ Reusable across multiple actions (generic alert, copy toast)
⚡️ No custom UI needed (system alert sufficient)

### 2.2 Target Distribution

**Total 66 IN_APP actions:**

| Pattern | Actions | Percentage | Examples |
|---------|---------|------------|----------|
| **JSON-Driven** | ~53 | 80% | track_package, add_to_calendar, quick_reply, browse_shopping, rsvp, view_details, schedule_meeting, add_reminder, save_contact, newsletter_summary, etc. |
| **Custom SwiftUI** | ~10 | 15% | sign_form (signature), pay_invoice (Stripe SDK), check_in_flight (PassKit), update_payment (secure forms), shopping_automation (price tracking), document_viewer (PDF rendering) |
| **Inline/Shared** | ~3 | 5% | copy_promo_code, simple_confirm, generic_alert |

---

## 3. Unified Component System

### 3.1 Component Hierarchy

```
ActionModal (Protocol)
├── JSONDrivenModal (80% of actions)
│   ├── GenericModalView (renderer)
│   └── ModalConfig (data)
├── CustomSwiftUIModal (15% of actions)
│   ├── SignFormModal
│   ├── PayInvoiceModal
│   ├── CheckInFlightModal
│   └── [7 more custom modals]
└── InlineModal (5% of actions)
    ├── SimpleConfirmationModal
    ├── CopySuccessToast
    └── GenericAlertModal

Shared Components (used by all)
├── ModalHeader
├── ModalSection
├── ModalButtonFooter
├── StatusBadge
├── CopyableField
├── FormField
├── InfoRow
└── LoadingState
```

### 3.2 Base Modal Protocol

**File:** `Zero_ios_2/Zero/Views/ActionModules/ActionModalProtocol.swift` (new)

```swift
protocol ActionModalView: View {
    /// Email card this modal acts upon
    var card: EmailCard { get }

    /// Type-safe context wrapper with all action data
    var context: ActionContext { get }

    /// Action configuration from registry
    var actionConfig: ActionConfig { get }

    /// Dismiss handler
    var dismiss: DismissAction { get }

    /// Primary action handler (execute, confirm, save, etc.)
    func performPrimaryAction()

    /// Secondary action handler (cancel, skip, etc.)
    func performSecondaryAction()

    /// Analytics tracking
    func trackModalEvent(_ event: ModalEvent)
}

extension ActionModalView {
    // Default implementations
    func performSecondaryAction() {
        trackModalEvent(.dismissed)
        dismiss()
    }

    func trackModalEvent(_ event: ModalEvent) {
        AnalyticsService.shared.track(
            event: event.rawValue,
            properties: [
                "action_id": actionConfig.actionId,
                "card_id": card.id,
                "mode": card.mode.rawValue
            ]
        )
    }
}
```

### 3.3 JSON-Driven Modal System (80% of actions)

#### Enhanced ModalConfig Structure

**File:** `Zero_ios_2/Zero/Core/ActionSystem/ModalConfig.swift` (extend existing)

```swift
struct ModalConfig: Codable, Identifiable {
    let id: String
    let version: String = "2.4"  // Schema version

    // Header
    let title: String
    let subtitle: String?
    let icon: IconConfig?

    // Content
    let sections: [ModalSection]
    let layout: ModalLayout  // standard, form, detail, timeline, wizard

    // Actions
    let primaryButton: ButtonConfig
    let secondaryButton: ButtonConfig?
    let tertiaryButton: ButtonConfig?  // NEW: For 3-button modals

    // Behavior
    let dismissible: Bool = true
    let confirmationRequired: Bool = false  // Show "Are you sure?" before primary action
    let hapticFeedback: HapticStyle = .medium
    let presentationStyle: PresentationStyle = .sheet  // sheet, fullScreen, popover

    // Validation
    let requiredFields: [String]?  // Field IDs that must be filled
    let validationRules: [ValidationRule]?

    // Analytics
    let trackingEvents: TrackingConfig?
}

struct ModalSection: Codable, Identifiable {
    let id: String
    let title: String?
    let subtitle: String?
    let fields: [FieldConfig]
    let layout: SectionLayout  // vertical, horizontal, grid, list
    let background: BackgroundStyle?  // glass, card, plain, none
    let collapsible: Bool = false  // NEW: Can section be collapsed?
    let defaultExpanded: Bool = true
}

struct FieldConfig: Codable, Identifiable {
    let id: String
    let label: String?
    let placeholder: String?  // NEW: For input fields
    let type: FieldType
    let contextKey: String  // Maps to ActionContext

    // Display options
    let required: Bool = false
    let copyable: Bool = false
    let tappable: Bool = false  // NEW: Can tap to open URL/action
    let editable: Bool = false  // NEW: Can user edit this field?

    // Formatting
    let formatting: FormattingRule?  // date, currency, phone, etc.
    let colorMapping: [String: String]?  // For status badges
    let icon: IconConfig?

    // Validation
    let validation: ValidationRule?
    let errorMessage: String?

    // Conditional display
    let showIf: ConditionalRule?  // NEW: Only show if condition met
}
```

#### Supported Field Types (Expanded)

```swift
enum FieldType: String, Codable {
    // Display-only (Phase 1)
    case text               // Plain text
    case textMultiline      // Multi-line text block
    case badge              // Small colored badge
    case statusBadge        // Status with color mapping
    case date               // Formatted date
    case dateTime           // Formatted date + time
    case currency           // Formatted money
    case link               // Tappable URL
    case button             // Action button within content
    case image              // Inline image
    case divider            // Visual separator
    case spacer             // Vertical spacing

    // Interactive input (Phase 2)
    case textInput          // Single-line text input
    case textInputMultiline // Multi-line text input
    case datePicker         // Date picker
    case timePicker         // Time picker
    case dateTimePicker     // Combined date + time picker
    case toggle             // On/off switch
    case picker             // Dropdown picker
    case slider             // Numeric slider
    case checkbox           // Single checkbox

    // Advanced (Phase 2.2)
    case segmentedControl   // Tab-like selector
    case stepper            // +/- numeric stepper
    case rating             // Star rating

    // Custom (Phase 3)
    case signature          // Signature capture (fallback to SwiftUI)
    case map                // Map view (fallback to SwiftUI)
    case richText           // Formatted text editor (fallback to SwiftUI)
}
```

#### Example JSON Config (Enhanced)

**File:** `Zero_ios_2/Zero/Config/ModalConfigs/add_to_calendar_enhanced.json`

```json
{
  "id": "add_to_calendar",
  "version": "2.4",
  "title": "Add to Calendar",
  "subtitle": "Save this event to your calendar",
  "icon": {
    "systemName": "calendar.badge.plus",
    "staticColor": "blue",
    "size": "large"
  },
  "layout": "form",
  "presentationStyle": "sheet",
  "dismissible": true,
  "sections": [
    {
      "id": "event_details",
      "title": "Event Details",
      "layout": "vertical",
      "background": "glass",
      "fields": [
        {
          "id": "event_title",
          "label": "Event",
          "type": "textInput",
          "contextKey": "eventTitle",
          "required": true,
          "placeholder": "Enter event name",
          "validation": {
            "type": "minLength",
            "value": 3
          },
          "errorMessage": "Event name must be at least 3 characters"
        },
        {
          "id": "event_date",
          "label": "Date",
          "type": "datePicker",
          "contextKey": "eventDate",
          "required": true
        },
        {
          "id": "event_time",
          "label": "Time",
          "type": "timePicker",
          "contextKey": "eventTime",
          "required": false
        },
        {
          "id": "event_location",
          "label": "Location",
          "type": "textInput",
          "contextKey": "eventLocation",
          "required": false,
          "placeholder": "Enter location",
          "icon": {
            "systemName": "mappin.circle.fill",
            "staticColor": "red"
          }
        },
        {
          "id": "add_reminder",
          "label": "Remind me 1 hour before",
          "type": "toggle",
          "contextKey": "addReminder",
          "required": false
        }
      ]
    }
  ],
  "primaryButton": {
    "title": "Add to Calendar",
    "style": "primary",
    "haptic": "success",
    "action": {
      "type": "serviceCall",
      "service": "CalendarService",
      "method": "addEvent",
      "parameters": {
        "title": "{{ eventTitle }}",
        "date": "{{ eventDate }}",
        "time": "{{ eventTime }}",
        "location": "{{ eventLocation }}",
        "reminder": "{{ addReminder }}"
      }
    }
  },
  "secondaryButton": {
    "title": "Cancel",
    "style": "secondary",
    "action": {
      "type": "dismiss"
    }
  },
  "trackingEvents": {
    "modalShown": "modal_shown_add_to_calendar",
    "primaryAction": "calendar_event_added",
    "dismissed": "modal_dismissed_add_to_calendar"
  }
}
```

#### Generic Modal Renderer

**File:** `Zero_ios_2/Zero/Views/ActionModules/GenericModalView.swift` (enhance existing)

```swift
struct GenericModalView: View, ActionModalView {
    let config: ModalConfig
    let context: ActionContext
    let card: EmailCard
    let actionConfig: ActionConfig
    @Environment(\.dismiss) var dismiss

    @State private var formData: [String: Any] = [:]
    @State private var showingConfirmation = false
    @State private var validationErrors: [String: String] = [:]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    if let icon = config.icon {
                        ModalHeader(
                            title: config.title,
                            subtitle: config.subtitle,
                            icon: icon
                        )
                    }

                    // Sections
                    ForEach(config.sections) { section in
                        renderSection(section)
                    }

                    Spacer(minLength: 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if config.dismissible {
                        Button("Close") {
                            trackModalEvent(.dismissed)
                            dismiss()
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Button footer
                ModalButtonFooter(
                    primaryButton: config.primaryButton,
                    secondaryButton: config.secondaryButton,
                    onPrimary: handlePrimaryAction,
                    onSecondary: performSecondaryAction
                )
            }
        }
        .onAppear {
            trackModalEvent(.shown)
            prepopulateFormData()
        }
    }

    private func renderSection(_ section: ModalSection) -> some View {
        ModalSection(
            title: section.title,
            subtitle: section.subtitle,
            background: section.background ?? .glass,
            collapsible: section.collapsible
        ) {
            ForEach(section.fields) { field in
                if shouldShowField(field) {
                    renderField(field)
                }
            }
        }
    }

    private func renderField(_ field: FieldConfig) -> some View {
        FieldRenderer.render(
            field: field,
            context: context,
            formData: $formData,
            validationError: validationErrors[field.id]
        )
    }

    private func shouldShowField(_ field: FieldConfig) -> Bool {
        guard let condition = field.showIf else { return true }
        return condition.evaluate(context: context, formData: formData)
    }

    func performPrimaryAction() {
        // Validate required fields
        let errors = validateForm()
        guard errors.isEmpty else {
            validationErrors = errors
            return
        }

        // Show confirmation if required
        if config.confirmationRequired {
            showingConfirmation = true
            return
        }

        // Execute action
        executeAction()
    }

    private func executeAction() {
        guard let action = config.primaryButton.action else { return }

        switch action.type {
        case .serviceCall:
            // Execute via ServiceCallExecutor
            ServiceCallExecutor.execute(
                service: action.service,
                method: action.method,
                parameters: interpolateParameters(action.parameters),
                context: context
            )
            trackModalEvent(.completed)
            dismiss()

        case .openURL:
            // Open URL
            if let urlString = context.string(for: action.contextKey ?? "url"),
               let url = URL(string: urlString) {
                UIApplication.shared.open(url)
                trackModalEvent(.completed)
                dismiss()
            }

        case .dismiss:
            // Just dismiss
            trackModalEvent(.completed)
            dismiss()
        }
    }
}
```

---

### 3.4 Custom SwiftUI Modal Pattern (15% of actions)

For actions requiring complex interactions not achievable via JSON:

#### Base Custom Modal Template

**File:** `Zero_ios_2/Zero/Views/ActionModules/CustomModalTemplate.swift` (new)

```swift
/// Template for custom SwiftUI modals
/// Use this as starting point for complex modals
struct CustomModalTemplate: View, ActionModalView {
    // MARK: - ActionModalView Requirements
    let card: EmailCard
    let context: ActionContext
    let actionConfig: ActionConfig
    @Environment(\.dismiss) var dismiss

    // MARK: - Custom State
    @State private var isLoading = false
    @State private var errorMessage: String?

    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Use shared header component
                    ModalHeader(
                        title: actionConfig.displayName,
                        subtitle: card.description,
                        icon: IconConfig(systemName: "star.fill", staticColor: "yellow")
                    )

                    // Custom content sections
                    customContent()

                    Spacer(minLength: 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        performSecondaryAction()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Use shared button footer
                ModalButtonFooter(
                    primaryTitle: "Complete Action",
                    secondaryTitle: "Cancel",
                    onPrimary: performPrimaryAction,
                    onSecondary: performSecondaryAction,
                    isLoading: isLoading
                )
            }
            .overlay {
                if isLoading {
                    LoadingState()
                }
            }
        }
        .onAppear {
            trackModalEvent(.shown)
        }
    }

    // MARK: - Custom Content
    @ViewBuilder
    private func customContent() -> some View {
        // Implement custom UI here
        // Use shared components where possible:
        // - ModalSection for grouped content
        // - InfoRow for label/value pairs
        // - StatusBadge for status indicators
        // - CopyableField for copyable text

        ModalSection(title: "Details", background: .glass) {
            InfoRow(label: "Example", value: "Custom UI")
        }
    }

    // MARK: - Actions
    func performPrimaryAction() {
        isLoading = true
        trackModalEvent(.primaryAction)

        // Perform custom action logic
        Task {
            do {
                try await performCustomAction()
                trackModalEvent(.completed)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func performCustomAction() async throws {
        // Custom business logic here
    }
}
```

#### When to Create Custom Modal

**Decision Tree:**

```
Does action require...?
├─ Signature capture? ────────────→ Custom Modal (SignFormModal)
├─ Payment SDK integration? ──────→ Custom Modal (PayInvoiceModal)
├─ PassKit / Wallet API? ─────────→ Custom Modal (CheckInFlightModal)
├─ Complex map interactions? ─────→ Custom Modal (PickupDetailsModal)
├─ Real-time data updates? ───────→ Custom Modal (TrackingLiveModal)
├─ Heavy PDF rendering? ──────────→ Custom Modal (DocumentViewerModal)
├─ Custom animations/gestures? ───→ Custom Modal
├─ Performance-critical UI? ──────→ Custom Modal
└─ Everything else? ──────────────→ JSON-Driven Modal
```

### 3.5 Shared Component Library

All modals (JSON and custom) use these shared components:

#### Component Catalog

**Location:** `Zero_ios_2/Zero/Views/Components/Modals/`

| Component | Purpose | Usage | Status |
|-----------|---------|-------|--------|
| `ModalHeader` | Icon, title, subtitle, close button | All modals | ✅ Exists |
| `ModalSection` | Glass card with title and content | Group related fields | ✅ Exists |
| `ModalButtonFooter` | Primary + secondary button layout | All modals | 🆕 Create |
| `InfoRow` | Label + value row | Display key-value pairs | 🆕 Create |
| `StatusBadge` | Color-coded status indicators | Tracking, statuses | ✅ Exists (StatusBanner) |
| `CopyableField` | Text with copy button | Tracking numbers, codes | 🆕 Create |
| `FormField` | Input field with validation | Forms | ✅ Exists |
| `LoadingState` | Loading overlay | Async actions | 🆕 Create |
| `ErrorBanner` | Error message display | Validation errors | 🆕 Create |
| `EmptyState` | Empty data placeholder | No content states | 🆕 Create |
| `FieldRenderer` | JSON field → SwiftUI view | Generic modal system | 🆕 Create |

#### Component Implementation: ModalButtonFooter

**File:** `Zero_ios_2/Zero/Views/Components/Modals/ModalButtonFooter.swift` (new)

```swift
struct ModalButtonFooter: View {
    let primaryTitle: String
    let secondaryTitle: String?
    let onPrimary: () -> Void
    let onSecondary: (() -> Void)?
    var isLoading: Bool = false
    var primaryDisabled: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            // Primary button
            Button(action: onPrimary) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(primaryTitle)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(primaryDisabled ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading || primaryDisabled)

            // Secondary button (if provided)
            if let secondaryTitle = secondaryTitle,
               let onSecondary = onSecondary {
                Button(action: onSecondary) {
                    Text(secondaryTitle)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
                .disabled(isLoading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
}
```

#### Component Implementation: InfoRow

**File:** `Zero_ios_2/Zero/Views/Components/Modals/InfoRow.swift` (new)

```swift
struct InfoRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    var copyable: Bool = false

    @State private var showCopiedToast = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon (optional)
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
            }

            // Label
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            // Value
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)

            // Copy button (if copyable)
            if copyable {
                Button {
                    UIPasteboard.general.string = value
                    showCopiedToast = true
                    HapticManager.impact(.light)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 8)
        .toast(isPresented: $showCopiedToast, message: "Copied to clipboard")
    }
}
```

---

## 4. Migration Strategy

### 4.1 Migration Waves

#### Wave 1: High-Fidelity Premium Actions (6 actions)
**Goal:** Validate hybrid approach with most complex actions

| Action | Current | Target Pattern | Reason | Estimated Effort |
|--------|---------|---------------|--------|------------------|
| track_package | Custom + JSON | **Keep Custom** (enhance with shared components) | Complex live tracking UI | 4 hours |
| pay_invoice | Custom + JSON | **Keep Custom** (Stripe SDK integration) | Payment processing | 6 hours |
| check_in_flight | Custom + JSON | **Keep Custom** (PassKit API) | Boarding pass generation | 4 hours |
| write_review | Custom + JSON | **Migrate to JSON** (simple form) | No complex interactions | 2 hours |
| contact_driver | Custom + JSON | **Migrate to JSON** (call/SMS actions) | Native phone/message intents | 2 hours |
| view_pickup_details | Custom + JSON | **Keep Custom** (map integration) | MapKit annotations | 3 hours |

**Wave 1 Deliverables:**
- 3 custom modals refactored to use shared components
- 3 custom modals migrated to JSON
- Validate JSON system handles forms and actions
- Establish migration patterns for Wave 2

**Timeline:** 1-2 weeks

---

#### Wave 2: Standard Mail Actions (20 actions)
**Goal:** Prove scalability of JSON-driven approach

**Candidates for JSON migration:**
- quick_reply (email composer)
- add_to_calendar (EventKit)
- schedule_meeting (calendar form)
- add_reminder (reminder form)
- rsvp_yes / rsvp_no (confirmation)
- save_contact_native (ContactUI)
- send_message (MessageUI)
- add_to_notes (notes integration)
- snooze (time picker)
- share (share sheet)
- view_reservation (display card)
- view_document (PDF viewer or JSON if simple)
- view_spreadsheet (Excel viewer or JSON if simple)
- download_attachment (file preview or JSON)
- view_itinerary (display card)
- review_security (security alert card)

**Keep as custom (if complex):**
- sign_form (signature capture)
- add_to_wallet (PassKit)
- document_viewer (PDF rendering)
- spreadsheet_viewer (Excel rendering)

**Wave 2 Deliverables:**
- ~16 modals migrated to JSON
- ~4 modals refactored to use shared components
- Create JSON templates for common patterns
- Document JSON migration guide

**Timeline:** 2-3 weeks

---

#### Wave 3: Compound Flows (10 actions)
**Goal:** Multi-step consistency using unified components

**Refactor CompoundActionFlow.swift to:**
1. Use GenericModalView for each step (if JSON config exists)
2. Use custom modal for complex steps
3. Shared wizard navigation component
4. Consistent progress indicators
5. Replace "under development" UI with proper placeholders or implement missing steps

**Wave 3 Deliverables:**
- CompoundActionFlow uses unified modal system
- All 10 compound actions functional (no dead-ends)
- Wizard component shared across all multi-step flows

**Timeline:** 1-2 weeks

---

#### Wave 4: Remaining Actions (30 actions)
**Goal:** Complete migration to unified system

**Focus areas:**
- Ads mode actions (browse_shopping, schedule_purchase, etc.)
- Shared actions (provide_access_code, update_payment, etc.)
- Low-priority actions (view_details, open_app, etc.)

**Wave 4 Deliverables:**
- All 66 IN_APP actions use target architecture
- Delete orphaned modal files
- Zero hardcoded modals in ActionRouter
- 100% JSON config coverage for eligible actions

**Timeline:** 2-3 weeks

---

### 4.2 Migration Checklist (Per Action)

**For JSON Migration:**
- [ ] Create JSON config in `Config/ModalConfigs/`
- [ ] Validate JSON against schema
- [ ] Test with empty context (placeholder mode)
- [ ] Test with populated context
- [ ] Add to Action Modal Gallery
- [ ] Update ActionRegistry (add `modalConfigJSON` property)
- [ ] Test in real app flow
- [ ] Delete custom modal file
- [ ] Update documentation
- [ ] Track analytics

**For Custom Modal Refactor:**
- [ ] Replace custom header with ModalHeader component
- [ ] Replace custom sections with ModalSection component
- [ ] Replace custom buttons with ModalButtonFooter component
- [ ] Use InfoRow for label/value pairs
- [ ] Use StatusBadge for status indicators
- [ ] Use CopyableField for copyable text
- [ ] Implement ActionModalView protocol
- [ ] Add proper analytics tracking
- [ ] Test in Action Modal Gallery
- [ ] Update documentation

---

### 4.3 Rollout Plan

**Phase 4 (Weeks 1-2): Build Infrastructure**
- Implement ActionModalGalleryView (test harness)
- Create missing shared components (ModalButtonFooter, InfoRow, etc.)
- Implement ActionModalView protocol
- Extend ModalConfig with new fields
- Extend ServiceCallExecutor with missing services
- Set up JSON schema validation

**Phase 5a (Weeks 3-4): Wave 1 - Premium Actions**
- Migrate/refactor 6 high-fidelity actions
- Validate hybrid approach
- Document patterns learned

**Phase 5b (Weeks 5-7): Wave 2 - Standard Actions**
- Migrate 20 standard mail actions
- Create JSON templates
- Document JSON migration guide

**Phase 5c (Weeks 8-9): Wave 3 - Compound Flows**
- Refactor CompoundActionFlow
- Implement wizard component
- Complete all multi-step flows

**Phase 5d (Weeks 10-12): Wave 4 - Remaining Actions**
- Migrate remaining 30 actions
- Clean up orphaned files
- Final testing and documentation

**Phase 6 (Week 13): Cleanup & Polish**
- Move routing to ActionModalCoordinator
- Remove ActionType/ZeroActionType inconsistency
- Standardize context key naming
- Performance optimization
- Final QA pass

---

## 5. Implementation Details

### 5.1 ServiceCallExecutor Extensions

**Add support for missing services:**

```swift
// File: Zero_ios_2/Zero/Core/ActionSystem/ServiceCallExecutor.swift

extension ServiceCallExecutor {
    // Add Payment Service
    static func executePaymentService(method: String, params: [String: Any]) async throws {
        switch method {
        case "processPayment":
            try await PaymentService.shared.processPayment(
                amount: params["amount"] as? String,
                merchant: params["merchant"] as? String,
                invoiceId: params["invoiceId"] as? String
            )
        case "schedulePayment":
            // ... implementation
        default:
            throw ServiceExecutorError.methodNotFound(method)
        }
    }

    // Add Wallet Service
    static func executeWalletService(method: String, params: [String: Any]) async throws {
        switch method {
        case "addPass":
            try await WalletService.shared.addPass(
                passData: params["passData"] as? Data
            )
        default:
            throw ServiceExecutorError.methodNotFound(method)
        }
    }

    // Add 5 more services (Auth, Storage, Messaging, Shopping, Navigation)
}
```

### 5.2 JSON Schema Validation

**Create validation schema:**

**File:** `Zero_ios_2/Zero/Config/ModalConfigs/schema.json` (new)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ModalConfig Schema",
  "type": "object",
  "required": ["id", "title", "sections", "primaryButton"],
  "properties": {
    "id": {
      "type": "string",
      "pattern": "^[a-z_]+$"
    },
    "title": {
      "type": "string",
      "minLength": 1,
      "maxLength": 60
    },
    "sections": {
      "type": "array",
      "minItems": 1,
      "items": {
        "$ref": "#/definitions/section"
      }
    }
  },
  "definitions": {
    "section": {
      "type": "object",
      "required": ["id", "fields"],
      "properties": {
        "id": { "type": "string" },
        "fields": {
          "type": "array",
          "items": { "$ref": "#/definitions/field" }
        }
      }
    },
    "field": {
      "type": "object",
      "required": ["id", "type", "contextKey"],
      "properties": {
        "id": { "type": "string" },
        "type": {
          "enum": ["text", "textMultiline", "badge", "statusBadge", "date", "dateTime", "currency", "link", "button", "image", "divider", "textInput", "datePicker", "timePicker", "toggle", "picker", "slider", "checkbox"]
        },
        "contextKey": { "type": "string" }
      }
    }
  }
}
```

**Add build-time validation:**

```bash
# File: Zero_ios_2/Scripts/validate_modal_configs.sh (new)

#!/bin/bash
set -e

SCHEMA="Zero/Config/ModalConfigs/schema.json"
CONFIGS_DIR="Zero/Config/ModalConfigs"

echo "Validating modal configs..."

for config in "$CONFIGS_DIR"/*.json; do
  if [ "$config" != "$SCHEMA" ]; then
    echo "Validating $config"
    jsonlint "$config" --schema "$SCHEMA"
  fi
done

echo "✅ All modal configs valid"
```

### 5.3 ActionModalCoordinator Implementation

**File:** `Zero_ios_2/Zero/Coordinators/ActionModalCoordinator.swift` (implement)

```swift
@MainActor
class ActionModalCoordinator: ObservableObject {
    @Published var activeModal: ActionModal?
    @Published var modalStack: [ActionModal] = []  // For nested modals

    private let actionRouter: ActionRouter
    private let actionRegistry: ActionRegistry

    init(actionRouter: ActionRouter, actionRegistry: ActionRegistry) {
        self.actionRouter = actionRouter
        self.actionRegistry = actionRegistry
    }

    // MARK: - Public API

    func present(action: EmailAction, card: EmailCard) {
        // Validate action
        guard actionRegistry.canExecute(action, for: card) else {
            // Show error
            return
        }

        // Build modal
        let modal = actionRouter.buildModalForAction(action, card: card)

        // Present
        activeModal = modal
        modalStack.append(modal)

        // Track analytics
        AnalyticsService.shared.track(event: "modal_presented", properties: [
            "action_id": action.actionId,
            "modal_type": modal.type
        ])
    }

    func dismiss() {
        guard !modalStack.isEmpty else { return }

        // Remove from stack
        let dismissed = modalStack.removeLast()

        // Update active modal
        activeModal = modalStack.last

        // Track analytics
        AnalyticsService.shared.track(event: "modal_dismissed", properties: [
            "modal_type": dismissed.type
        ])
    }

    func dismissAll() {
        modalStack.removeAll()
        activeModal = nil
    }
}
```

---

## 6. Success Metrics & Validation

### 6.1 Quantitative Metrics

| Metric | Current | Target | Validation Method |
|--------|---------|--------|-------------------|
| Modal code lines | ~11,000 | <5,000 | Count lines in ActionModules/ |
| Modal files | 46 | ~10 custom + 1 renderer | Count .swift files |
| JSON config coverage | 30% (20/66) | 80% (53/66) | Count JSON configs |
| Routing logic lines | 1,340 (ContentView) | <500 (ContentView) + 300 (Coordinator) | Measure LOC |
| Action type enums | 2 | 1 | Search for ActionType/ZeroActionType |
| Orphaned files | 3 | 0 | Verify all files mapped |
| Test coverage | 0% | 80% | Run test suite |

### 6.2 Qualitative Metrics

**Developer Experience:**
- [ ] Clear guidelines for adding new actions
- [ ] Single modal creation path for 90% of actions
- [ ] Test harness allows rapid iteration
- [ ] Shared components eliminate duplicate code
- [ ] Documentation explains when to use each pattern

**Designer Experience:**
- [ ] Can modify most modal UIs via JSON (no developer needed)
- [ ] Test harness allows validating changes in isolation
- [ ] Component library provides consistent patterns

**User Experience:**
- [ ] Consistent modal UI across all actions
- [ ] No "under development" dead-ends
- [ ] Smooth animations and transitions
- [ ] Proper loading and error states

### 6.3 Testing Strategy

**Unit Tests:**
- ActionRegistry validation logic
- ActionRouter modal building
- Context extraction and fallbacks
- Compound action orchestration
- JSON config parsing
- ServiceCallExecutor methods

**Integration Tests:**
- Modal presentation flow (action → modal → dismiss)
- Compound flows (multi-step completion)
- JSON-driven modal rendering
- Custom modal interactions

**UI Tests:**
- All modals render correctly in test harness
- Primary/secondary actions work
- Form validation works
- Error states display properly

**Manual QA:**
- Test all 66 actions in real app flow
- Verify analytics tracking
- Check accessibility (VoiceOver, Dynamic Type)
- Test on various devices (iPhone, iPad)

---

## 7. Documentation Plan

### 7.1 Developer Documentation

**Create:** `docs/action-system-guide.md`

**Content:**
- Architecture overview (hybrid JSON-first)
- Adding new actions (step-by-step)
  - When to use JSON
  - When to use custom SwiftUI
  - When to use inline
- JSON config tutorial
  - Field types reference
  - Button action types
  - Service call examples
- Custom modal tutorial
  - Using ActionModalView protocol
  - Shared components reference
  - Best practices
- Context key naming guide
- Priority assignment rules
- Testing checklist
- Troubleshooting FAQ

### 7.2 Component Library Documentation

**Create:** `docs/modal-component-library.md`

**Content:**
- Component catalog with screenshots
- Props and parameters reference
- Usage examples
- When to use guidelines
- Styling customization
- Accessibility considerations

### 7.3 JSON Field Type Reference

**Create:** `docs/json-field-types.md`

**Content:**
- All 24 field types with examples
- Props reference for each type
- Validation rules
- Conditional display
- Interactive examples

---

## 8. Risks & Mitigations

### Risk 1: JSON System Limitations
**Risk:** JSON configs can't handle all use cases, forcing more custom modals
**Mitigation:**
- Start with simple actions in Wave 1-2
- Extend JSON system based on needs
- Allow hybrid approach (JSON structure + custom fields)
- Keep custom fallback option

### Risk 2: Performance Regression
**Risk:** Generic renderer slower than custom views
**Mitigation:**
- Profile modal rendering performance
- Optimize generic renderer (view caching, lazy loading)
- Use custom modals for performance-critical actions

### Risk 3: Migration Effort Underestimated
**Risk:** 66 actions takes longer than 12 weeks
**Mitigation:**
- Focus on high-priority actions first
- Run waves in parallel if possible
- Allow iterative deployment
- Keep old modals functional during migration

### Risk 4: Breaking Changes
**Risk:** Refactoring breaks existing functionality
**Mitigation:**
- Write comprehensive tests before refactoring
- Keep old code paths until new system validated
- Feature flags for gradual rollout
- Extensive QA testing

### Risk 5: Designer Adoption
**Risk:** Designers still ask developers for JSON changes
**Mitigation:**
- Provide JSON authoring tools
- Create JSON templates library
- Thorough documentation with examples
- Test harness for immediate validation

---

## 9. Timeline Summary

**Total Duration:** 13 weeks (3 months)

| Phase | Duration | Focus |
|-------|----------|-------|
| Phase 4 | 2 weeks | Infrastructure (test harness, components, extensions) |
| Phase 5a | 2 weeks | Wave 1 - Premium actions (6 actions) |
| Phase 5b | 3 weeks | Wave 2 - Standard actions (20 actions) |
| Phase 5c | 2 weeks | Wave 3 - Compound flows (10 actions) |
| Phase 5d | 3 weeks | Wave 4 - Remaining actions (30 actions) |
| Phase 6 | 1 week | Cleanup, polish, final QA |

**Parallel Work Opportunities:**
- Shared component development during Phases 5a-5d
- Documentation during implementation
- Testing infrastructure throughout

---

## 10. Next Steps

### Immediate Actions (This Week)
1. ✅ **Phase 1-3 Complete:** Audit, gap analysis, and architecture spec
2. **Review & approval:** Present this spec to team for feedback
3. **Prioritize feedback:** Incorporate any changes

### Next Week
4. **Begin Phase 4:** Start implementing test harness and infrastructure
5. **Create shared components:** ModalButtonFooter, InfoRow, LoadingState
6. **Extend ServiceCallExecutor:** Add missing services

### Weeks 3-4 (Phase 5a)
7. **Wave 1 migration:** Start with high-fidelity premium actions
8. **Validate approach:** Confirm hybrid pattern works
9. **Iterate on learnings:** Adjust spec based on findings

---

## Conclusion

This specification defines a **clear path forward** for unifying Zero Inbox's modal system:

**Target Architecture:** Hybrid JSON-First
- 80% JSON-driven for simplicity and designer access
- 15% Custom SwiftUI for complex interactions
- 5% Inline for very simple cases

**Key Benefits:**
- **Reduced code:** 11,000 → 5,000 lines (55% reduction)
- **Faster iteration:** Designers can modify JSON without developers
- **Consistency:** Shared components ensure uniform UX
- **Testability:** Test harness validates all modals
- **Maintainability:** Clear patterns and documentation

**Success depends on:**
- Thorough testing at each wave
- Gradual migration with validation
- Clear documentation and guidelines
- Team buy-in on architecture

**Ready to proceed with Phase 4!**

---

**Document Generated:** 2025-12-20
**Status:** Ready for implementation
**Next Step:** Begin Phase 4 (Test Harness & Infrastructure)
