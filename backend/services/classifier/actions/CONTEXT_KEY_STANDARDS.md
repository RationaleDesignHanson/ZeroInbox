# Action Context Key Standardization Guide

**Version**: 1.0
**Last Updated**: October 31, 2025
**Purpose**: Establish naming conventions for action context keys to ensure consistency across the action catalog

## Naming Principles

1. **Use camelCase** for all keys (e.g., `trackingNumber`, not `tracking_number`)
2. **Be descriptive** but concise (e.g., `flightNumber` not `fn` or `flightIdentificationNumber`)
3. **Follow established patterns** documented below
4. **Avoid abbreviations** except for well-known ones (e.g., `url` is OK, `rx` is OK for prescription)

## Standard Context Key Patterns

### 1. URL Keys

**Pattern**: `{purpose}Url`

Examples:
- `trackingUrl` - URL to track package
- `paymentUrl` - URL for payment page
- `checkInUrl` - URL for check-in
- `resultsUrl` - URL to view results
- `assignmentUrl` - URL for assignment
- `productUrl` - URL for product page
- `cartUrl` - URL for shopping cart
- `meetingUrl` - URL to join meeting
- `ticketUrl` - URL to view support ticket
- `unsubscribeUrl` - URL to unsubscribe

**Avoid**: `link` suffix (use `Url` instead)

### 2. ID/Number Keys

**Pattern**: `{entity}Id` for internal IDs, `{entity}Number` for external/human-readable numbers

**IDs (internal identifiers)**:
- `invoiceId` - Internal invoice identifier
- `accountId` - Account identifier
- `ticketId` - Support ticket ID
- `messageId` - Email message ID

**Numbers (external/human-readable)**:
- `orderNumber` - Order confirmation number
- `trackingNumber` - Package tracking number
- `flightNumber` - Flight number (e.g., "AA123")
- `confirmationCode` - Reservation confirmation code
- `rxNumber` - Prescription number
- `claimNumber` - Insurance claim number

**Rule of Thumb**: If shown to users in marketing materials or confirmations, use `Number`. If it's an internal database ID, use `Id`.

### 3. Date/Time Keys

**Pattern**: `{purpose}Date` for dates, `dateTime` for date+time

**Date + Time**:
- `dateTime` - Generic date and time (ISO 8601 format)

**Date Only**:
- `dueDate` - Payment or task due date
- `saleDate` - Sale start date
- `expirationDate` - Expiration date
- `electionDate` - Election date
- `deadline` - Generic deadline

**Format**: Always use ISO 8601 format (`YYYY-MM-DDTHH:mm:ss`)

### 4. Amount/Money Keys

**Pattern**: `amount` for primary amounts, `{purpose}Amount` for specific amounts

**Standard Keys**:
- `amount` - Primary payment amount (include currency symbol: "$50.00")
- `amountDue` - Amount owed/due (prefer `amount` when unambiguous)
- `refundAmount` - Refund amount

**Deprecated**: `amountDue` should be migrated to `amount` where possible

### 5. Entity Name Keys

**Pattern**: `{entityType}Name` or just `{entityType}` for primary entities

**Examples**:
- `productName` - Product name
- `serviceName` - Service/subscription name
- `merchant` - Merchant/vendor name
- `carrier` - Shipping carrier name
- `airline` - Airline name
- `company` - Company name
- `position` - Job position name
- `sport` - Sport type
- `medication` - Medication name

### 6. Location Keys

**Pattern**: `location` for addresses, `{purpose}Location` for specific locations

**Examples**:
- `location` - Generic address/location
- `pharmacy` - Pharmacy name/location
- `destination` - Travel destination

### 7. People Keys

**Pattern**: `{role}` for person names, `{role}Email` for emails

**Examples**:
- `driver` - Driver name
- `teacher` - Teacher name
- `introducedPerson` - Person being introduced
- `recipientEmail` - Email recipient
- `sender` - Email sender

## Common Entity Patterns

| Entity Type | ID Key | Name Key | Number Key | URL Key |
|------------|---------|----------|------------|---------|
| Order | - | - | `orderNumber` | `orderUrl` |
| Invoice | `invoiceId` | - | - | `invoiceUrl` |
| Package | - | - | `trackingNumber` | `trackingUrl` |
| Flight | - | - | `flightNumber` | `checkInUrl` |
| Reservation | - | - | `confirmationCode` | `reservationUrl` |
| Product | - | `productName` | - | `productUrl` |
| Ticket | `ticketId` | - | - | `ticketUrl` |
| Account | `accountId` | - | - | - |

## Migration Guide

### Deprecated Keys → Standard Keys

| Deprecated | Standard | Migration Status |
|-----------|----------|------------------|
| `reviewLink` | `reviewUrl` | ⏳ Pending (1 action) |
| `amountDue` | `amount` | ⏳ Pending (2 actions) |

## Validation Rules

When adding new actions, validate:

1. **Required vs Optional**: Only mark truly essential keys as `requiredEntities`
2. **URL Keys**: Must end with `Url` (not `Link` or `URI`)
3. **ID Keys**: Use `Id` suffix for internal IDs, `Number` for external numbers
4. **Date Keys**: Use ISO 8601 format, prefer `dateTime` for datetime, `{purpose}Date` for date-only
5. **Money Keys**: Use `amount` as primary, include currency symbol in value

## Backend Implementation

Context keys are defined in:
- **Action Catalog**: `/backend/services/actions/action-catalog.js`
- **Transformer**: `/backend/services/actions/server.js` (transformActionForAPI)
- **Optional Keys**: `/backend/services/actions/server.js:518` (getOptionalContextKeys)

## iOS Implementation

Context keys are consumed in:
- **Action Router**: `/ios-app/Zero/Services/ActionRouter.swift`
  - Lines 107-272: GO_TO action URL generation
  - Lines 331-510: IN_APP modal construction
- **Validation**: ActionRegistry validates required keys before execution

## Testing Context Keys

When testing actions:

```javascript
// Backend test
const action = ActionCatalog.track_package;
assert.deepEqual(action.requiredEntities, ['trackingNumber', 'carrier']);

// iOS test
let context = ["trackingNumber": "1Z999AA10123456784", "carrier": "UPS"];
let valid = registry.validateAction("track_package", context: context);
assert.isTrue(valid.isValid);
```

## Future Improvements

1. **Schema Validation**: Add JSON Schema validation for context keys
2. **Type Safety**: Generate TypeScript types from action catalog
3. **Automatic Migration**: Script to rename deprecated keys across codebase
4. **Context Builder**: Helper class to build valid context objects

## Questions?

For questions or to propose new standards, contact the backend team or open an issue.
