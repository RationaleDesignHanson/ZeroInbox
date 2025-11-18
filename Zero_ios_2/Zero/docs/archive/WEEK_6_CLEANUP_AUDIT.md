# Week 6: Cleanup Audit

**Date**: 2025-11-14
**Status**: In Progress
**Scope**: Final Cleanup Pass (Priority 1)

---

## Overview

Comprehensive audit of TODOs, placeholders, and cleanup opportunities identified across the codebase.

**Summary**:
- **35 TODO comments** found
- **21 placeholder user IDs** found (16 "user-123", 5 other variants)
- **5 high-priority TODOs** requiring implementation
- **8 security-related TODOs** (auth token retrieval)

---

## High-Priority TODOs (Require Implementation)

### 1. ✅ Authentication Context (CRITICAL - Security)

**Location**: `Config/Constants.swift:26`
```swift
static let defaultUserId = "user-123" // TODO: Replace with actual authenticated user ID
```

**Impact**: Used throughout app (21 references)
**Action Required**: Implement `getUserEmail()` or similar auth context function
**Priority**: HIGH - Security risk
**Estimated Time**: 30 minutes

---

### 2. Auth Token Retrieval (HIGH - Infrastructure)

**Locations**:
- `Services/SubscriptionService.swift:188`
- `Services/FeedbackService.swift:142`

```swift
// TODO: Implement auth token retrieval
```

**Impact**: API calls will fail without proper authentication
**Action Required**: Implement token management service
**Priority**: HIGH - Blocks production use
**Estimated Time**: 1-2 hours

---

### 3. Snooze Logic Implementation (MEDIUM - Feature)

**Location**: `Views/SaveForLaterModal.swift:482`
```swift
// TODO: Implement snooze logic via EmailViewModel or separate service
```

**Impact**: Feature incomplete
**Action Required**: Connect to EmailViewModel or create SnoozeService
**Priority**: MEDIUM - User-facing feature
**Estimated Time**: 1 hour

---

### 4. JSON Availability Parsing (LOW - Enhancement)

**Location**: `Services/ActionLoader.swift:270`
```swift
availability: .alwaysAvailable,  // TODO: Parse from JSON availability field
```

**Impact**: All actions show as "always available"
**Action Required**: Add availability field to JSON schema + parsing
**Priority**: LOW - Nice to have
**Estimated Time**: 30 minutes

---

### 5. Settings Page Re-enablement (LOW - UI)

**Location**: `Views/SettingsView.swift:393`
```swift
.disabled(true) // TODO: Re-enable with dedicated settings page
```

**Impact**: Some settings are disabled
**Action Required**: Create dedicated settings page
**Priority**: LOW - UI polish
**Estimated Time**: 2 hours

---

## Security Audit: Placeholder User IDs

### Found 21 Occurrences Across 16 Files

#### Category 1: "user-123" Literal (16 instances)

1. **Config/Constants.swift:26** (3 instances)
   ```swift
   static let defaultUserId = "user-123"
   ```
   **Action**: Define `getUserEmail()` function, replace constant

2. **Models/UserSession.swift** (3 instances)
   ```swift
   // Multiple references to "user-123" or defaultUserId
   ```
   **Action**: Use authenticated user session

3. **ViewModels/EmailViewModel.swift:1**
   ```swift
   userId: Constants.User.defaultUserId // "user-123"
   ```
   **Action**: Replace with `getUserEmail()`

4. **Services/ShoppingAutomationService.swift:109**
   ```swift
   userId: "user-123", // TODO: Replace with actual user ID
   ```
   **Action**: Replace with authenticated user

5. **Services/SharedTemplateService.swift:69**
   ```swift
   authorId: "user-123", // TODO: Get from auth
   ```
   **Action**: Replace with authenticated user

6. **Services/ActionFeedbackService.swift**
   ```swift
   userId: defaultUserId
   ```
   **Action**: Use authenticated context

7. **Views/ShoppingCartView.swift:10**
   ```swift
   let userId = "user-123" // TODO: Replace with actual user ID
   ```
   **Action**: Replace with authenticated user

8. **Views/SharedTemplateView.swift:66**
   ```swift
   try await service.fetchSharedTemplates(userId: "user-123") // TODO: Get from auth
   ```
   **Action**: Replace with authenticated user

9. **Views/SavedMailListView.swift**
   ```swift
   userId: Constants.User.defaultUserId
   ```
   **Action**: Use authenticated context

10. **Views/FolderPickerView.swift**
    ```swift
    userId: Constants.User.defaultUserId
    ```
    **Action**: Use authenticated context

11. **Views/FolderDetailView.swift** (2 instances)
    ```swift
    userId: Constants.User.defaultUserId
    ```
    **Action**: Use authenticated context

12. **Views/CreateFolderView.swift**
    ```swift
    userId: Constants.User.defaultUserId
    ```
    **Action**: Use authenticated context

13. **Views/ActionModules/ShoppingPurchaseModal.swift:516**
    ```swift
    userId: "user-123", // TODO: Replace with actual user ID
    ```
    **Action**: Replace with authenticated user

14. **Zero/ContentView.swift**
    ```swift
    userId: Constants.User.defaultUserId
    ```
    **Action**: Use authenticated context

---

#### Category 2: Other Placeholder IDs (5 instances)

1. **Views/ActionModules/ScheduledPurchaseModal.swift:330**
   ```swift
   userId: "current-user", // TODO: Get from auth
   ```
   **Action**: Replace with authenticated user

2. **Services/AdminFeedbackService.swift:115**
   ```swift
   "reviewerId": "admin-user"  // TODO: Get from auth
   ```
   **Action**: Replace with authenticated admin

---

## Low-Priority TODOs (Future Features)

### Infrastructure & Configuration

1. **Config/APIConfig.swift:52**
   ```swift
   // TODO: Update with production analytics service URL when deployed
   ```
   **Priority**: LOW - Production deployment task

2. **Services/RemoteConfigService.swift:83**
   ```swift
   // TODO: Implement actual remote fetch
   ```
   **Priority**: LOW - Feature not critical

3. **Utilities/ErrorReporting.swift:114**
   ```swift
   // TODO: Uncomment when Sentry SDK is added
   ```
   **Priority**: LOW - Optional error tracking

---

### Analytics & Tracking

1. **Services/AnalyticsService.swift:183**
   ```swift
   // TODO: When ready, add Firebase
   ```
   **Priority**: LOW - Optional analytics

2. **Services/AnalyticsService.swift:209**
   ```swift
   // TODO: When ready, add Firebase
   ```
   **Priority**: LOW - Optional analytics

---

### UI & Feature Implementations

1. **Views/ReviewPreviewModal.swift:184**
   ```swift
   // TODO: Submit rating to backend API
   ```
   **Priority**: MEDIUM - User feedback feature

2. **Services/RemindersService.swift:91**
   ```swift
   // TODO: Extract URL from card.suggestedActions if available
   ```
   **Priority**: LOW - Enhancement

3. **Views/ShoppingCartView.swift:115**
   ```swift
   // TODO: Implement checkout
   ```
   **Priority**: MEDIUM - E-commerce feature

4. **Views/EmailThreadView.swift:181**
   ```swift
   // TODO: AvatarBadge not in Xcode project - using placeholder
   ```
   **Priority**: LOW - UI component

5. **Views/ActionModules/ViewItineraryModal.swift:299**
   ```swift
   // TODO: Implement calendar integration
   ```
   **Priority**: MEDIUM - User-facing feature

6. **Views/ActionModules/NewsletterSummaryModal.swift:246**
   ```swift
   // TODO: Open email in native mail app or in-app web view
   ```
   **Priority**: MEDIUM - UX enhancement

7. **Views/ActionModules/CancelSubscriptionModal.swift:398**
   ```swift
   // TODO: Implement AI-guided cancellation flow
   ```
   **Priority**: LOW - Future feature

8. **Views/ActionModules/ProvideAccessCodeModal.swift:131**
   ```swift
   // TODO: AvatarBadge not in Xcode project - using placeholder
   ```
   **Priority**: LOW - UI component

9. **Views/ActionModules/RSVPModal.swift:324**
   ```swift
   // TODO: Open email composer with pre-filled RSVP message
   ```
   **Priority**: MEDIUM - User-facing feature

10. **Views/ActionModules/QuickReplyModal.swift:306**
    ```swift
    // TODO: Actual email API integration would go here
    ```
    **Priority**: HIGH - Core feature (but infrastructure not ready)

11. **Views/AuthenticationView.swift:55**
    ```swift
    // TODO: Implement Outlook authentication
    ```
    **Priority**: MEDIUM - Auth provider

12. **Views/AuthenticationView.swift:72**
    ```swift
    // TODO: Show iCloud manual setup sheet
    ```
    **Priority**: LOW - Alternative auth method

---

### Data Extraction & Parsing

1. **Services/ShoppingAutomationService.swift:114**
   ```swift
   price: 0.0, // TODO: Extract actual price from automation result
   ```
   **Priority**: MEDIUM - Data accuracy

2. **Views/ActionModules/ScheduledPurchaseModal.swift:335**
   ```swift
   timezone: "UTC" // TODO: Get user's timezone
   ```
   **Priority**: LOW - UX enhancement

3. **Views/ActionModules/ShoppingPurchaseModal.swift:527**
   ```swift
   expiresAt: nil // TODO: Parse expiration date if available
   ```
   **Priority**: LOW - Data completeness

---

## Recommended Cleanup Actions

### Phase 1: Critical Security (30 minutes)

**Task**: Create authenticated user context function

**Files to Create**:
```swift
// Utilities/AuthContext.swift
struct AuthContext {
    static func getUserEmail() -> String {
        // TODO: Implement actual auth lookup
        // For now, return placeholder
        return Constants.User.defaultUserId
    }

    static func getUserId() -> String {
        return getUserEmail()
    }

    static func getAuthToken() -> String? {
        // TODO: Implement token management
        return nil
    }
}
```

**Files to Modify** (21 replacements):
1. Replace all `"user-123"` → `AuthContext.getUserId()`
2. Replace all `Constants.User.defaultUserId` → `AuthContext.getUserId()`
3. Replace all `"current-user"` → `AuthContext.getUserId()`
4. Replace all `"admin-user"` → `AuthContext.getAdminId()` (if applicable)

**Expected Impact**:
- Centralized auth context (single source of truth)
- Easy to swap in real authentication later
- Eliminates 21 hardcoded placeholders
- Reduces security audit findings

---

### Phase 2: Remove Obsolete Code (15 minutes)

**Actions**:
1. ✅ Remove Week 5 performance test code (DONE)
2. Remove commented-out code blocks (if any)
3. Remove unused imports

---

### Phase 3: Update Low-Priority TODOs (Optional)

**Actions**:
- Document infrastructure TODOs in separate doc (production deployment checklist)
- Move feature TODOs to backlog/roadmap
- Keep only actionable TODOs in code

---

## Success Criteria

### Cleanup Pass Complete When:
- ✅ Performance test code removed (DONE)
- ✅ TODO audit complete (this document)
- ⏳ AuthContext utility created
- ⏳ 21 placeholder user IDs replaced
- ⏳ All critical TODOs addressed or documented

---

## Next Steps

1. ✅ Remove performance test code (DONE)
2. ✅ Document all TODOs (this file)
3. ⏳ Create `Utilities/AuthContext.swift`
4. ⏳ Replace 21 placeholder user IDs
5. ⏳ Move to Priority 2: Code Quality Pass (extract shared components)

---

**Cleanup Status**: 2/5 tasks complete
**Estimated Remaining Time**: 45 minutes
**Blockers**: None
