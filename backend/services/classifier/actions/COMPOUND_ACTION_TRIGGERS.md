# Compound Action Triggering Logic

## Overview

Compound actions are multi-step flows that are **automatically detected** by the backend based on email context richness. They are triggered in `rules-engine.js` when calling `suggestActions()`.

---

## ❌ Red X Emoji Meaning

**The red X (❌) is NOT an error indicator** - it's simply a visual icon for "Cancel" or "Decline" actions:

- `cancel_subscription` → ❌ Cancel Subscription
- `rsvp_no` → ❌ Decline Invitation
- `cancel_with_confirmation` → ❌✉️ Cancel Subscription & Confirm

It's part of the action branding, just like ✍️ for signing, 💳 for payment, etc.

---

## How Compound Actions Are Triggered

### 1. Entry Point: `rules-engine.js` → `suggestActions(intentId, entities, emailContext)`

When the backend classifies an email, it calls `suggestActions()` with:
- **intentId**: e.g., `'education.permission.form'`
- **entities**: extracted data like `{ formName: 'Field Trip', amount: 45, eventDate: '2025-11-15' }`
- **emailContext**: `{ subject, from, body }`

### 2. Smart Detection: `compound-action-registry.js` → `detectCompoundAction(intentId, entities)`

The registry checks if a compound action matches based on **intent + entity richness**:

```javascript
// Example: Permission form WITH payment info
if (intent === 'education.permission.form' && entities.amount) {
  return 'sign_form_with_payment';  // ✍️💳 Multi-step: Sign → Pay → Email
}

// Example: Permission form WITH event date
if (intent === 'education.permission.form' && entities.eventDate) {
  return 'sign_form_with_calendar';  // ✍️📅 Multi-step: Sign → Calendar → Email
}
```

### 3. Prioritization Logic

When a compound action is detected, `rules-engine.js`:
1. Sets the compound action as **PRIMARY** (isPrimary: true, priority: 0)
2. Adds individual step actions as **alternatives** (isPrimary: false)

**Example Response:**
```javascript
[
  {
    actionId: 'sign_form_with_payment',  // PRIMARY
    isPrimary: true,
    priority: 0,
    isCompound: true,
    compoundSteps: ['sign_form', 'pay_form_fee', 'email_composer'],
    requiresResponse: true,
    isPremium: true
  },
  {
    actionId: 'sign_form',  // Alternative
    isPrimary: false,
    priority: 1
  },
  {
    actionId: 'pay_form_fee',  // Alternative
    isPrimary: false,
    priority: 2
  }
]
```

---

## All 8 Compound Action Triggers

### Education & Childcare

#### 1. **sign_form_with_payment** (Premium)
- **Trigger:** `education.permission.form` + `entities.amount` exists
- **Flow:** ✍️ Sign Form → 💳 Pay Fee → ✉️ Send Confirmation
- **End Behavior:** Email Composer (requiresResponse: true)
- **Example:** "Permission slip for field trip - $45 fee required"

#### 2. **sign_form_with_calendar** (Premium)
- **Trigger:** `education.permission.form` + `entities.eventDate` exists
- **Flow:** ✍️ Sign Form → 📅 Add to Calendar → ✉️ Send Confirmation
- **End Behavior:** Email Composer (requiresResponse: true)
- **Example:** "Permission slip for Nov 15 field trip"

### Shopping & E-Commerce

#### 3. **track_with_calendar** (Premium)
- **Trigger:** `e-commerce.shipping.notification` + `entities.deliveryDate` exists
- **Flow:** 📦 Track Package → 📅 Schedule Delivery
- **End Behavior:** Return to App (requiresResponse: false)
- **Example:** "Your package delivers Friday at 8pm"

#### 4. **schedule_purchase_with_reminder** (Premium)
- **Trigger:** `e-commerce.promotion` + `entities.saleDate` exists
- **Flow:** 🛒 Schedule Purchase → 📅 Set Reminder
- **End Behavior:** Return to App (requiresResponse: false)
- **Example:** "Black Friday sale starts Nov 24"

### Billing & Payment

#### 5. **pay_invoice_with_confirmation** (Premium)
- **Trigger:** `billing.invoice.due` + `entities.amount` + `entities.merchant` both exist
- **Flow:** 💳 Pay Invoice → ✉️ Send Receipt Confirmation
- **End Behavior:** Email Composer (requiresResponse: true)
- **Example:** "Invoice #INV-123 from Acme Corp - $1,299 due"

### Travel

#### 6. **check_in_with_wallet** (Premium)
- **Trigger:** `travel.flight.check-in` + `entities.flightNumber` exists
- **Flow:** ✈️ Check In → 📲 Add Boarding Pass to Wallet
- **End Behavior:** Return to App (requiresResponse: false)
- **Example:** "Check in now for flight UA 123"

### Calendar & Events

#### 7. **calendar_with_reminder** (FREE)
- **Trigger:** Intent includes `'appointment'` or `'event'` + (`entities.eventDate` OR `entities.appointmentTime`) exists
- **Flow:** 📅 Add to Calendar → ⏰ Set Reminder
- **End Behavior:** Return to App (requiresResponse: false)
- **Example:** "Doctor appointment scheduled for Oct 30 at 2pm"

### Subscriptions

#### 8. **cancel_with_confirmation** (FREE)
- **Trigger:** `subscription.cancellation` OR intent includes `'cancel'`
- **Flow:** ❌ Cancel Subscription → ✉️ Request Confirmation
- **End Behavior:** Email Composer (requiresResponse: true)
- **Example:** "Your subscription renews next week"

---

## Detection Priority Rules

### When Multiple Conditions Match

**Example:** Permission form with BOTH `amount` AND `eventDate`

```javascript
entities = {
  formName: 'Field Trip',
  amount: 45,         // Has payment info
  eventDate: '2025-11-15'  // Has event date
}
```

**Current Logic:** Amount check comes FIRST in `detectCompoundAction()`, so **payment takes priority**:
- Result: `sign_form_with_payment` (not `sign_form_with_calendar`)

### When No Compound Matches

If `detectCompoundAction()` returns `null`, the system falls back to **individual actions only**:

```javascript
// No compound detected → Return regular actions
[
  { actionId: 'sign_form', isPrimary: true },
  { actionId: 'quick_reply', isPrimary: false }
]
```

---

## Where Detection Happens

### Backend Flow

1. **Email arrives** → Classifier service extracts intent + entities
2. **Actions service** → `rules-engine.js` calls `suggestActions(intent, entities, emailContext)`
3. **Smart detection** → `CompoundActionRegistry.detectCompoundAction(intent, entities)` checks conditions
4. **Response built** → If compound detected, it becomes primary; else regular actions returned
5. **iOS receives** → Action list with `isCompound: true` flag and `compoundSteps: [...]` array

### iOS Execution

When iOS sees `isCompound: true`:
1. **ActionRouter** routes to `CompoundActionFlow` modal (wizard-style UI)
2. **CompoundActionFlow** renders steps 1→2→3 with progress tracking
3. **End behavior** executed based on `requiresResponse`:
   - `true` → Opens email composer with pre-filled template
   - `false` → Returns to inbox or dismisses modal

---

## Testing Compound Detection

Run the test suite to verify all triggers:

```bash
cd /Users/matthanson/Zer0_Inbox/backend/services/actions
node test-compound-actions.js
```

Tests include:
- ✅ Registry structure validation
- ✅ Detection logic for all 8 compounds
- ✅ Rules engine integration
- ✅ Business logic edge cases

---

## Adding New Compound Actions

To add a new compound action:

### 1. Define in `compound-action-registry.js`:

```javascript
my_new_compound: {
  actionId: 'my_new_compound',
  displayName: 'My Compound Action',
  steps: ['step1_action', 'step2_action', 'email_composer'],
  endBehavior: {
    type: END_BEHAVIORS.EMAIL_COMPOSER,
    template: {
      subjectPrefix: 'Re: ...',
      bodyTemplate: '...',
      includeOriginalSender: true
    }
  },
  requiresResponse: true,
  isPremium: true,
  description: '...'
}
```

### 2. Add detection logic in `detectCompoundAction()`:

```javascript
if (intent === 'my.new.intent' && entities.myEntity) {
  logger.info('Detected my new compound action', { intent, hasMyEntity: true });
  return 'my_new_compound';
}
```

### 3. Add modal flow visualization in `action-modal-explorer.html`:

```javascript
COMPOUND_FLOWS['my_new_compound'] = {
  title: '🎯 My Compound Action',
  isPremium: true,
  requiresResponse: true,
  endBehavior: 'emailComposer',
  steps: [/* step visualizations */]
}
```

### 4. Update iOS `CompoundActionRegistry.swift` to match

Ensure the `actionId`, `steps`, and `endBehavior` match exactly.

---

## Key Takeaways

✅ **Automatic Detection** - No manual flags needed; backend detects based on context richness
✅ **Primary by Default** - Compound actions are always suggested first when detected
✅ **Backend-iOS Contract** - Both registries must have matching action IDs and steps
✅ **Smart Fallback** - If compound not detected, individual actions still work
✅ **Premium/Free Mix** - 6 premium, 2 free (calendar_with_reminder, cancel_with_confirmation)
✅ **End Behaviors** - 4 require response (email composer), 4 don't (return to app)

❌ **Red X = Cancel Actions** (NOT errors!)
