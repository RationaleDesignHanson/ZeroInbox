# iOS-Backend API Contract Documentation
## Zero Inbox v1.9 - Platform Parity Validation

**Created**: 2025-11-03
**Version**: 1.0
**Status**: 📋 **DOCUMENTED**

---

## Overview

This document defines the complete API contract between the iOS app and backend services. All backend responses must conform to these TypeScript-style interface definitions to ensure zero runtime failures due to schema mismatches.

---

## 1. Email Classification Response

### Endpoint
```
POST /api/classify
```

### iOS Model: `EmailCard`
Location: `/Zero_ios_2/Zero/Models/EmailCard.swift:4`

### Contract

```typescript
interface ClassificationResponse {
  // Core email metadata
  id: string;
  type: "mail" | "ads" | "newsletter";
  state: "unread" | "read" | "archived";
  priority: "critical" | "high" | "medium" | "low";
  hpa: string;  // Human-readable time
  timeAgo: string;
  title: string;
  summary: string;
  aiGeneratedSummary?: string;
  body?: string;
  htmlBody?: string;
  metaCTA: string;

  // Thread metadata
  threadLength?: number;
  threadData?: ThreadData;

  // ACTION-FIRST MODEL (v1.1) - PRIMARY CONTRACT
  intent?: string;  // Intent ID (e.g., 'e-commerce.shipping.notification')
  intentConfidence?: number;  // 0-1 confidence score
  suggestedActions?: EmailAction[];  // Array of suggested actions

  // Sender information
  sender?: SenderInfo;
  recipientEmail?: string;

  // Context entities
  kid?: KidInfo;
  company?: CompanyInfo;
  store?: string;
  airline?: string;
  productImageUrl?: string;
  brandName?: string;
  originalPrice?: number;
  salePrice?: number;
  discount?: number;
  urgent?: boolean;
  expiresIn?: string;
  requiresSignature?: boolean;
  paymentAmount?: number;
  paymentDescription?: string;
  value?: string;
  probability?: number;
  score?: number;

  // Mode-specific fields
  isSchoolEmail?: boolean;
  isVIP?: boolean;
  deadline?: DeadlineInfo;
  teacher?: string;
  school?: string;
  isNewsletter?: boolean;
  unsubscribeUrl?: string;
  keyLinks?: NewsletterLink[];
  keyTopics?: string[];
  isShoppingEmail?: boolean;
  trackingNumber?: string;
  orderNumber?: string;
  isSubscription?: boolean;
  subscriptionAmount?: number;
  subscriptionFrequency?: "monthly" | "annual";
  cancellationUrl?: string;

  // Calendar & Attachments
  calendarInvite?: CalendarInvite;
  hasAttachments?: boolean;
  attachments?: EmailAttachment[];
}
```

---

## 2. Email Action Model

### iOS Model: `EmailAction`
Location: `/Zero_ios_2/Zero/Models/EmailCard.swift:276`

### Contract

```typescript
interface EmailAction {
  id: string;  // Same as actionId for Identifiable conformance
  actionId: string;  // Action identifier (e.g., 'track_package')
  displayName: string;  // User-facing action name
  actionType: "GO_TO" | "IN_APP";  // Execution type
  isPrimary: boolean;  // Is this the primary suggested action?
  priority?: number;  // Action priority (higher = more important)
  context?: Record<string, string>;  // Entity values (trackingNumber, etc.)
  isCompound?: boolean;  // Is this a multi-step compound action?
  compoundSteps?: string[];  // Array of step actionIds if compound
}
```

### Backend Source
- **Action Catalog**: `/backend/services/actions/action-catalog.js`
- **Compound Actions**: `/backend/services/actions/compound-action-registry.js`

### Validation Rules

1. **actionId**: Must match one of 138 actions in ActionCatalog
2. **displayName**: Must be user-friendly, sentence case
3. **actionType**: Must be exactly "GO_TO" or "IN_APP" (case-sensitive)
4. **isPrimary**: Exactly one action must be primary per email
5. **priority**: If present, must be 1-5 (1 = highest)
6. **context**: Keys must match requiredContextKeys or optionalContextKeys
7. **isCompound**: If true, compoundSteps must be present and non-empty
8. **compoundSteps**: Must be valid actionIds in correct sequence

---

## 3. Dynamic Action Registry Response

### Endpoint
```
GET /api/registry/{userId}?days=30&mode=mail
```

### iOS Model: `DynamicActionRegistryResponse`
Location: `/Zero_ios_2/Zero/Services/DynamicActionRegistry.swift:16`

### Contract

```typescript
interface DynamicActionRegistryResponse {
  actions: DynamicAction[];
  metadata: RegistryMetadata;
  fromCache?: boolean;
  cacheHit?: boolean;
}

interface DynamicAction {
  actionId: string;
  displayName: string;
  actionType: "GO_TO" | "IN_APP";
  mode: "mail" | "ads" | "both";
  modalComponent?: string;  // Modal name if IN_APP
  requiredContextKeys: string[];
  optionalContextKeys: string[];
  fallbackBehavior: string;
  analyticsEvent: string;
  priority: number;
  description: string;
  requiredPermission: string;
  userStats?: UserActionStats;
}

interface UserActionStats {
  frequency: number;  // 0-1 usage frequency
  lastUsed?: string;  // ISO 8601 timestamp
  timesUsed: number;
  timesSuggested: number;
  executionRate: number;  // 0-1 (timesUsed / timesSuggested)
  avgTimeToAction: number;  // seconds
}

interface RegistryMetadata {
  userId: string;
  corpusSize: number;  // Number of emails analyzed
  days: number;  // Lookback period
  lastUpdated: string;  // ISO 8601 timestamp
  actionsReturned: number;
  actionsFiltered: number;
  personalizationApplied: boolean;
}
```

### Backend Source
- **Action Registry Service**: Port 8085
- **File**: `/backend/services/actions/action-registry-service.js`

### Validation Rules

1. **actions**: Array of 1-138 actions (never empty)
2. **actionId**: Must be unique within response
3. **actionType**: Must be "GO_TO" or "IN_APP"
4. **mode**: Must be "mail", "ads", or "both"
5. **requiredContextKeys**: Array of entity keys this action needs
6. **priority**: 1-5 (1 = highest priority)
7. **executionRate**: Must be between 0 and 1
8. **metadata.lastUpdated**: Must be valid ISO 8601 timestamp

---

## 4. Compound Action Model

### iOS Model: `EmailAction` (with isCompound = true)
Location: `/Zero_ios_2/Zero/Models/EmailCard.swift:276`

### Contract

```typescript
interface CompoundAction extends EmailAction {
  isCompound: true;
  compoundSteps: string[];  // e.g., ['sign_form', 'pay_form_fee', 'email_composer']
  endBehavior?: {
    type: "EMAIL_COMPOSER" | "RETURN_TO_APP";
    template?: {
      subjectPrefix: string;
      bodyTemplate: string;
    };
  };
}
```

### Backend Source
- **File**: `/backend/services/actions/compound-action-registry.js`
- **9 Total Compound Actions**

### All Compound Actions

| actionId | Steps | End Behavior | Premium |
|----------|-------|--------------|---------|
| sign_form_with_payment | 3 | EMAIL_COMPOSER | ✓ |
| sign_form_with_calendar | 3 | EMAIL_COMPOSER | ✓ |
| sign_and_send | 2 | EMAIL_COMPOSER | - |
| track_with_calendar | 2 | RETURN_TO_APP | ✓ |
| schedule_purchase_with_reminder | 2 | RETURN_TO_APP | ✓ |
| pay_invoice_with_confirmation | 2 | EMAIL_COMPOSER | ✓ |
| check_in_with_wallet | 2 | RETURN_TO_APP | ✓ |
| calendar_with_reminder | 2 | RETURN_TO_APP | - |
| cancel_with_confirmation | 2 | EMAIL_COMPOSER | - |

### Validation Rules

1. **compoundSteps**: Must contain 2-3 valid actionIds
2. **Step order**: Must match exact sequence in registry
3. **End behavior**: Must match registry definition
4. **Email templates**: Required if end behavior is EMAIL_COMPOSER
5. **Entity passing**: Each step must have required entities available

---

## 5. Entity Context Model

### iOS Model: `context: [String: String]?` in EmailAction
Location: `/Zero_ios_2/Zero/Models/EmailCard.swift:283`

### Contract

```typescript
interface EntityContext {
  // Order entities
  orderNumber?: string;
  orderUrl?: string;

  // Tracking entities
  trackingNumber?: string;
  carrier?: string;
  trackingUrl?: string;

  // Payment entities
  invoiceId?: string;
  amount?: string;  // iOS prefers string values
  amountDue?: string;
  paymentAmount?: string;
  dueDate?: string;
  paymentLink?: string;
  deliveryDate?: string;
  merchant?: string;

  // Meeting entities
  meetingUrl?: string;
  eventDate?: string;
  eventTime?: string;
  eventTitle?: string;
  registrationLink?: string;
  organizer?: string;

  // Account entities
  unsubscribeUrl?: string;
  resetLink?: string;
  verificationLink?: string;
  username?: string;
  device?: string;
  ipAddress?: string;
  secretType?: string;

  // Travel entities
  flightNumber?: string;
  confirmationCode?: string;
  checkInUrl?: string;
  itineraryUrl?: string;
  departureDate?: string;

  // Healthcare entities
  provider?: string;
  specialty?: string;
  appointmentDate?: string;
  appointmentTime?: string;
  dateTime?: string;
  schedulingUrl?: string;
  rxNumber?: string;
  medication?: string;
  resultsUrl?: string;
  confirmationUrl?: string;
  resultType?: string;
  pickupDeadline?: string;
  location?: string;

  // Education entities
  assignmentName?: string;
  studentName?: string;
  grade?: string;
  formName?: string;
  eventDate?: string;
  assignmentUrl?: string;
  gradeUrl?: string;

  // Dining entities
  restaurant?: string;
  partySize?: string;  // iOS expects string representation
  reservationUrl?: string;
  confirmationCode?: string;
  reservationTime?: string;

  // Shopping entities
  saleDate?: string;
  saleDateShort?: string;
  saleTime?: string;
  timezone?: string;
  productUrl?: string;
  productName?: string;
  variantCount?: string;
  limitedEdition?: string;
  availabilityDuration?: string;

  // Subscription entities
  subscriptionUrl?: string;
  paymentUrl?: string;
  serviceName?: string;
  renewalDate?: string;

  // Civic entities
  appointmentType?: string;
  jurorNumber?: string;
  location?: string;
  appointmentUrl?: string;

  // Delivery entities
  driver?: string;
  eta?: string;
  restaurant?: string;
  trackingUrl?: string;
}
```

### Backend Source
- **File**: `/backend/services/classifier/entity-extractor.js`
- **Test Coverage**: 40/40 tests passing (100%)

### Validation Rules

1. **All values are strings**: iOS expects string representation, even for numbers
2. **Keys match requiredContextKeys**: Action must have all required entities
3. **Optional keys**: Can be present based on optionalContextKeys
4. **URL format**: URLs must be valid HTTP/HTTPS
5. **Date format**: Flexible (human-readable or ISO 8601)
6. **Number format**: String representation without commas (e.g., "125.50" not "$125.50")

---

## 6. Intent Classification Model

### iOS Model: `intent?: String` in EmailCard
Location: `/Zero_ios_2/Zero/Models/EmailCard.swift:23`

### Contract

```typescript
interface IntentClassification {
  intent: string;  // Intent ID in "category.subcategory.action" format
  intentConfidence: number;  // 0-1 confidence score
}
```

### All Valid Intents (134 total)

**Format**: `category.subcategory.action`

**Examples**:
- `e-commerce.order.confirmation`
- `e-commerce.shipping.notification`
- `billing.invoice.due`
- `healthcare.appointment.reminder`
- `education.permission.form`
- `travel.flight.check-in`

### Backend Source
- **File**: `/backend/shared/models/Intent.js`
- **Test Coverage**: 122/133 passing (91.7%)

### Validation Rules

1. **intent**: Must be one of 134 valid intent IDs
2. **intentConfidence**: Must be between 0 and 1
3. **Format**: Must follow `category.subcategory.action` pattern
4. **Case**: All lowercase with dots as separators

---

## 7. Action Type Enum

### iOS Model: `ActionType` in EmailAction
Location: `/Zero_ios_2/Zero/Models/EmailCard.swift:288`

### Contract

```typescript
enum ActionType {
  GO_TO = "GO_TO",    // Opens external URL in Safari
  IN_APP = "IN_APP"   // Opens modal within app
}
```

### Backend Source
- **File**: `/backend/services/actions/action-catalog.js`
- **Type field**: `type` property in action objects

### Validation Rules

1. **Exact match**: Must be exactly "GO_TO" or "IN_APP" (case-sensitive)
2. **GO_TO actions**: Must have URL template
3. **IN_APP actions**: Must have modal component reference
4. **No other values**: Any other string is invalid

---

## 8. Sender Information Model

### iOS Model: `SenderInfo` in EmailCard
Location: `/Zero_ios_2/Zero/Models/EmailCard.swift:192`

### Contract

```typescript
interface SenderInfo {
  email: string;
  name?: string;
  domain?: string;
  isKnown?: boolean;
}
```

---

## 9. Thread Data Model

### iOS Model: `ThreadData` in EmailCard
Location: `/Zero_ios_2/Zero/Models/EmailCard.swift:205`

### Contract

```typescript
interface ThreadData {
  context: ThreadContext;
  summary: string;
  keyMessages: KeyMessage[];
}

interface ThreadContext {
  people: Person[];
  companies: Company[];
  products: Product[];
  dates: DateInfo[];
  upcomingEvents: Event[];
  recentPurchases: Purchase[];
}
```

---

## 10. Error Response Model

### Contract

```typescript
interface ErrorResponse {
  error: string;
  message: string;
  statusCode: number;
  requestId?: string;
}
```

### Validation Rules

1. **error**: Short error code (e.g., "INVALID_EMAIL")
2. **message**: Human-readable error description
3. **statusCode**: HTTP status code (400, 500, etc.)
4. **requestId**: UUID for tracing

---

## Contract Validation Checklist

### For Every API Response

- [ ] All required fields present
- [ ] Field types match contract
- [ ] Enum values are exact matches (case-sensitive)
- [ ] Arrays are never null (empty array if no data)
- [ ] Numbers as strings where iOS expects strings
- [ ] URLs are valid HTTP/HTTPS
- [ ] Timestamps are ISO 8601 format
- [ ] actionType is "GO_TO" or "IN_APP" exactly
- [ ] Primary action is marked isPrimary=true
- [ ] Context entities match requiredContextKeys
- [ ] Intent ID is valid from taxonomy
- [ ] Confidence is between 0 and 1

---

## Backend Services Mapping

| iOS Endpoint | Backend Service | Port |
|-------------|-----------------|------|
| `/api/classify` | classifier-service | 8082 |
| `/api/registry/{userId}` | actions-service | 8085 |
| `/api/summarize` | summarization-service | 8086 |
| `/api/analytics` | analytics-service | 8090 |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-11-03 | Initial contract documentation |

---

*Contract Documentation Created: 2025-11-03*
*Last Updated: 2025-11-03*
