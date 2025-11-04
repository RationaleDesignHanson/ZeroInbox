# Phase 2: iOS-Backend Contract Violations
## Identified Issues Requiring Resolution

**Date**: 2025-11-03
**Test Suite**: `phase2-contract-validation.test.js`
**Pass Rate**: 43.8% (7/16 tests passing)
**Status**: 🚨 **9 VIOLATIONS FOUND**

---

## Summary

Contract validation tests revealed 9 violations between backend responses and iOS model expectations. These must be fixed to prevent runtime failures on iOS.

### Test Results by Category

| Category | Pass Rate | Status |
|----------|-----------|--------|
| Email Action | 20% (1/5) | 🚨 Critical |
| Compound Action | 25% (1/4) | 🚨 Critical |
| Entity Context | 100% (3/3) | ✅ Pass |
| Intent Classification | 67% (2/3) | ⚠️ Warning |
| Integration | 0% (0/1) | 🚨 Critical |

---

## Violation 1: Missing `type` Field in Actions

### Issue
Backend actions use `actionType` field, but tests expect `type` field.

### Impact
**Critical** - iOS expects `action.type` to determine how to execute the action.

### Backend Code
File: `/backend/services/actions/action-catalog.js`
```javascript
{
  actionId: 'track_package',
  displayName: 'Track Package',
  actionType: 'GO_TO',  // ❌ iOS expects 'type'
  priority: 1
}
```

### iOS Contract
```swift
struct EmailAction {
  let actionType: ActionType  // 'GO_TO' or 'IN_APP'
}
```

### Fix Required
Rename `actionType` to `type` in ActionCatalog, OR update test to use `actionType`.

**Recommendation**: Keep backend as `actionType` (clearer naming), update test expectations.

---

## Violation 2: Display Name "RSVP" is All Caps

### Issue
Display name "RSVP" violates user-friendly naming convention (all caps not allowed).

### Impact
**Low** - Functional but inconsistent UX.

### Backend Code
File: `/backend/services/actions/action-catalog.js`
```javascript
{
  actionId: 'rsvp_event',
  displayName: 'RSVP',  // ❌ All caps
  ...
}
```

### Fix Required
Change to "RSVP to Event" or "Respond to RSVP".

**Recommendation**: `displayName: 'RSVP to Event'`

---

## Violation 3: Priority Values Exceed Range

### Issue
Some actions have `priority: 6`, which exceeds iOS contract range of 1-5.

### Impact
**Medium** - iOS may not handle priority 6 correctly.

### Backend Code
File: `/backend/services/actions/action-catalog.js`
```javascript
{
  actionId: 'some_action',
  priority: 6  // ❌ Exceeds range
}
```

### iOS Contract
```swift
let priority: Int  // 1-5 only
```

### Fix Required
Clamp all priorities to 1-5 range.

**Recommendation**: Run `grep -r 'priority: 6' services/actions/` to find and fix all instances.

---

## Violation 4: Compound Action End Behavior Case Mismatch

### Issue
Backend uses "emailComposer" but iOS expects "EMAIL_COMPOSER".

### Impact
**Critical** - iOS won't recognize end behavior type.

### Backend Code
File: `/backend/services/actions/compound-action-registry.js`
```javascript
endBehavior: {
  type: 'emailComposer'  // ❌ Wrong case
}
```

### iOS Contract
```typescript
enum EndBehavior {
  EMAIL_COMPOSER = "EMAIL_COMPOSER",
  RETURN_TO_APP = "RETURN_TO_APP"
}
```

### Fix Required
Change all endBehavior.type values to uppercase with underscores.

**Recommendation**: Use constants for end behavior types.

---

## Violation 5: Invalid Compound Action Steps

### Issue
Compound action `calendar_with_reminder` has step "add_reminder" which doesn't exist in ActionCatalog.

### Impact
**Critical** - iOS won't be able to execute this step.

### Backend Code
File: `/backend/services/actions/compound-action-registry.js`
```javascript
calendar_with_reminder: {
  steps: ['add_to_calendar', 'add_reminder'],  // ❌ 'add_reminder' not in catalog
  ...
}
```

### Valid Action IDs
138 actions in ActionCatalog - "add_reminder" is NOT one of them.

### Fix Required
Either:
1. Add "add_reminder" action to ActionCatalog, OR
2. Remove this compound action, OR
3. Replace "add_reminder" with valid actionId

**Recommendation**: Add `add_reminder` IN_APP action to ActionCatalog.

---

## Violation 6: End Behavior Inconsistency

### Issue
Some compound actions have `requiresResponse: true` but `endBehavior.type: 'RETURN_TO_APP'`, which is contradictory.

### Impact
**Medium** - Confusing behavior, but iOS may handle gracefully.

### Backend Code
File: `/backend/services/actions/compound-action-registry.js`
```javascript
{
  requiresResponse: true,  // ❌ Says needs response
  endBehavior: {
    type: 'RETURN_TO_APP'  // ❌ But returns to app without email
  }
}
```

### iOS Contract
EMAIL_COMPOSER end behavior should have `requiresResponse: true`
RETURN_TO_APP end behavior should have `requiresResponse: false`

### Fix Required
Audit all 9 compound actions and ensure consistency.

**Recommendation**: Auto-derive `requiresResponse` from `endBehavior.type`.

---

## Violation 7: Intent Format Exception

### Issue
Intent "subscription.anniversary" has only 2 parts, violating "category.subcategory.action" format.

### Impact
**Low** - Single edge case.

### Backend Code
File: `/backend/shared/models/Intent.js`
```javascript
'subscription.anniversary': {  // ❌ Only 2 parts
  ...
}
```

### iOS Contract
```typescript
// Format: category.subcategory.action
intent.split('.').length >= 3
```

### Fix Required
Rename to `subscription.renewal.anniversary` or `subscription.notification.anniversary`.

**Recommendation**: `subscription.notification.anniversary`

---

## Violation 8: Integration Test Undefined Action Type

### Issue
Integration test failing because `action.type` is undefined (related to Violation 1).

### Impact
**Critical** - Full classification response isn't iOS-compatible.

### Fix Required
Same as Violation 1 - ensure all actions have valid `type` field.

---

## Violation 9: Missing Email Composer Step in ActionCatalog

### Issue
Compound actions reference special step "email_composer" which isn't in ActionCatalog.

### Impact
**Medium** - Test assumes "email_composer" is special case, but should be documented.

### Backend Code
```javascript
steps: ['sign_form', 'pay_form_fee', 'email_composer']
```

### Fix Required
Either:
1. Add "email_composer" as special action in ActionCatalog, OR
2. Document that "email_composer" is special final step, OR
3. Update test to skip "email_composer" validation

**Recommendation**: Document as special step (no fix needed).

---

## Priority Fix List

### P0 - Must Fix (Breaks iOS)
1. ✅ Fix action `type` field (Violation 1, 8)
2. ✅ Fix compound action end behavior case (Violation 4)
3. ✅ Fix invalid compound action step "add_reminder" (Violation 5)

### P1 - Should Fix (Inconsistencies)
4. ⚠️ Fix priority range violations (Violation 3)
5. ⚠️ Fix end behavior consistency (Violation 6)
6. ⚠️ Fix intent format exception (Violation 7)

### P2 - Nice to Fix (UX)
7. 📝 Fix "RSVP" display name (Violation 2)
8. 📝 Document "email_composer" special step (Violation 9)

---

## Recommended Action Plan

### Option A: Fix Now (30 min)
Fix all P0 violations immediately to unblock iOS development.

**Steps**:
1. Update action-catalog.js field name consistency
2. Fix compound-action-registry.js end behavior types
3. Add missing "add_reminder" action OR remove compound action
4. Re-run tests to verify 100% pass rate

### Option B: Fix Later
Document violations and continue with Task 2.2 (Mock Mode), fix during integration testing.

**Pros**: Keep momentum on Phase 2
**Cons**: iOS developers may encounter issues

### Option C: Hybrid Approach
Fix P0 violations now (10 min), defer P1/P2 fixes.

**Recommendation**: **Option C** - Quick P0 fixes, continue with Phase 2.

---

## Test Command

```bash
npm test -- services/actions/__tests__/phase2-contract-validation.test.js
```

---

**Report Generated**: 2025-11-03
**Status**: 🚨 **ACTION REQUIRED**
*9 violations identified - 3 P0, 3 P1, 2 P2*
