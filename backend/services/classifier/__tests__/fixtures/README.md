# Email Test Fixtures

This directory contains realistic email fixtures for testing the shopping agent and unsubscribe agent. Each fixture is a JSON file representing a complete email with headers, body (text + HTML), classification metadata, and test expectations.

## Fixture Categories

### 🔒 Critical/Transactional Emails (NEVER UNSUBSCRIBE)

These emails represent critical communications that should NEVER be automatically unsubscribed. The unsubscribe agent must have safeguards to prevent unsubscribing from these types of emails.

| File | Type | Purpose | Key Tests |
|------|------|---------|-----------|
| `critical-bank-alert.json` | Banking | Security alert from Chase Bank | ❌ Should NOT be unsubscribable<br>✅ Should be marked as critical<br>✅ Should detect security intent |
| `critical-password-reset.json` | Security | Password reset from Google | ❌ Should NOT be unsubscribable<br>✅ Should be marked as critical<br>✅ Should detect authentication intent |
| `critical-medical-appointment.json` | Healthcare | Appointment reminder from medical center | ❌ Should NOT be unsubscribable<br>✅ Should be marked as critical<br>✅ Should extract appointment details |
| `critical-utility-bill.json` | Utility | PG&E bill notification | ❌ Should NOT be unsubscribable<br>✅ Should be marked as critical<br>✅ Should detect payment due date |
| `critical-2fa-code.json` | Security | Two-factor authentication code from Apple | ❌ Should NOT be unsubscribable<br>✅ Should be marked as critical<br>✅ Should detect verification code |

**⚠️ CRITICAL SAFETY REQUIREMENT**: The unsubscribe agent must NEVER automatically unsubscribe from any email in this category. These represent banking, security, medical, utility, and authentication communications that users rely on.

### 🛒 Shopping/Receipt Emails (TRANSACTIONAL)

These emails represent order confirmations, shipment notifications, and other transactional shopping communications. They should be parsed by the shopping agent and should NOT be unsubscribable.

| File | Merchant | Type | Key Entities | Tests |
|------|----------|------|--------------|-------|
| `shopping-amazon-order-confirmation.json` | Amazon | Order Confirmation | Order #112-8426571-3947825<br>2 items ($478.48) | ✅ Extract order number<br>✅ Extract 2 items with prices<br>✅ Extract delivery estimate<br>❌ Should NOT be unsubscribable |
| `shopping-amazon-shipped.json` | Amazon | Shipment Notification | Tracking: TBA123456789<br>Carrier: UPS | ✅ Extract tracking number<br>✅ Extract carrier<br>✅ Extract delivery date<br>✅ Status: "shipped" |
| `shopping-amazon-delivered.json` | Amazon | Delivery Confirmation | Delivered Jan 17, 6:32 PM<br>Location: Front Porch | ✅ Extract delivery timestamp<br>✅ Extract delivery location<br>✅ Status: "delivered" |
| `shopping-target-order.json` | Target | Order Confirmation | Order #4029284756<br>3 items ($79.35) | ✅ Extract order number<br>✅ Extract 3 household items<br>✅ Extract total with tax |
| `shopping-bestbuy-multi-item.json` | Best Buy | Order Confirmation | Order #BBY01-745829163<br>4 electronics ($2,152.13) | ✅ Extract order number<br>✅ Extract 4 items (laptop, mouse, dock, monitor)<br>✅ Test multi-item parsing |
| `shopping-order-cancelled.json` | Best Buy | Order Cancellation | Order #987654321<br>Refund: $1,499.99 | ✅ Extract cancellation reason<br>✅ Extract refund amount<br>✅ Status: "cancelled" |
| `shopping-refund-issued.json` | Target | Refund Notification | Order #4029284756<br>Refund: $19.99 (damaged item) | ✅ Extract refund amount<br>✅ Extract refund reason<br>✅ Status: "refunded" |

**Shopping Agent Tests:**
- Order number extraction
- Item name, quantity, price parsing
- Merchant identification
- Order status detection (ordered, shipped, delivered, cancelled, refunded)
- Delivery estimate extraction
- Tracking number/URL extraction

### 📧 Newsletter/Marketing Emails (SAFE TO UNSUBSCRIBE)

These emails represent newsletters and marketing communications that users CAN safely unsubscribe from. Each has proper unsubscribe mechanisms (List-Unsubscribe headers and/or unsubscribe links).

| File | Sender | Type | Unsubscribe Mechanism | Tests |
|------|--------|------|----------------------|-------|
| `newsletter-substack.json` | Tech Insights Weekly | Newsletter | ✅ List-Unsubscribe header<br>✅ One-Click unsubscribe<br>✅ Unsubscribe link in footer | ✅ Should be unsubscribable<br>✅ Extract List-Unsubscribe header<br>✅ Extract unsubscribe URL |
| `newsletter-techcrunch.json` | TechCrunch | Daily News | ✅ List-Unsubscribe header<br>✅ One-Click unsubscribe<br>✅ Email + URL unsubscribe | ✅ Should be unsubscribable<br>✅ Extract both mailto and HTTP unsubscribe<br>✅ Preference center link |
| `marketing-retail-promo.json` | J.Crew | Promotional | ✅ List-Unsubscribe header<br>✅ Unsubscribe link in footer | ✅ Should be unsubscribable<br>✅ Detect promotional intent<br>✅ Extract unsubscribe URL |
| `marketing-product-recommendations.json` | Spotify | Personalized Recommendations | ✅ List-Unsubscribe header<br>✅ Unsubscribe link in footer<br>✅ Preference center | ✅ Should be unsubscribable<br>✅ Detect recommendation intent<br>✅ Extract preference URL |

**Unsubscribe Agent Tests:**
- Newsletter/marketing detection
- List-Unsubscribe header parsing
- One-Click unsubscribe support detection
- Unsubscribe URL extraction from HTML body
- Preference center URL extraction
- Mock HTTP requests to unsubscribe endpoints

## Fixture Structure

Each fixture JSON file follows this structure:

```json
{
  "id": "unique-identifier",
  "subject": "Email subject line",
  "from": {
    "name": "Sender Name",
    "email": "sender@example.com"
  },
  "to": "user@example.com",
  "date": "2025-01-15T10:00:00Z",
  "headers": {
    "Message-ID": "<unique-id@domain.com>",
    "Content-Type": "text/html; charset=utf-8",
    "List-Unsubscribe": "<unsubscribe-url>" // Optional
  },
  "body": {
    "text": "Plain text version...",
    "html": "<html>HTML version...</html>"
  },
  "classification": {
    "type": "receipt|newsletter|marketing|transactional",
    "category": "shopping|banking|security|etc",
    "intent": "order_confirmation|newsletter|etc",
    "shouldNeverUnsubscribe": true|false,
    "reason": "Explanation"
  },
  "entities": {
    // Shopping-specific entities
    "orderNumber": "123456",
    "merchant": "Amazon",
    "total": 123.45,
    "items": [...],
    // etc
  },
  "unsubscribeMechanism": {
    // Newsletter/marketing-specific
    "hasListUnsubscribeHeader": true|false,
    "unsubscribeUrls": [...],
    // etc
  },
  "testExpectations": {
    "shouldDetectAsReceipt": true|false,
    "shouldDetectAsNewsletter": true|false,
    "shouldBeUnsubscribable": true|false,
    "expectedTags": ["tag1", "tag2"]
  }
}
```

## Usage in Tests

### Loading Fixtures

```javascript
// Node.js / Backend tests
const fs = require('fs');
const path = require('path');

function loadFixture(filename) {
  const fixturePath = path.join(__dirname, 'fixtures', filename);
  return JSON.parse(fs.readFileSync(fixturePath, 'utf-8'));
}

// Example
const amazonOrder = loadFixture('shopping-amazon-order-confirmation.json');
```

```swift
// Swift / iOS tests
func loadFixture(named filename: String) -> [String: Any] {
    let bundle = Bundle(for: type(of: self))
    guard let url = bundle.url(forResource: filename, withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        fatalError("Failed to load fixture: \(filename)")
    }
    return json
}
```

### Example Test Cases

#### Shopping Agent Tests

```javascript
describe('Shopping Agent - Order Parsing', () => {
  it('should extract order details from Amazon confirmation', () => {
    const email = loadFixture('shopping-amazon-order-confirmation.json');
    const parsed = parseOrderEmail(email);

    expect(parsed.orderNumber).toBe('112-8426571-3947825');
    expect(parsed.merchant).toBe('Amazon');
    expect(parsed.total).toBe(478.48);
    expect(parsed.items).toHaveLength(2);
    expect(parsed.items[0].name).toContain('Sony WH-1000XM5');
  });

  it('should detect order status from shipment notification', () => {
    const email = loadFixture('shopping-amazon-shipped.json');
    const parsed = parseOrderEmail(email);

    expect(parsed.status).toBe('shipped');
    expect(parsed.trackingNumber).toBe('TBA123456789');
    expect(parsed.carrier).toBe('UPS');
  });
});
```

#### Unsubscribe Agent Safety Tests

```javascript
describe('Unsubscribe Agent - Safety Guards', () => {
  it('should NEVER mark bank alerts as unsubscribable', () => {
    const email = loadFixture('critical-bank-alert.json');
    const classification = classifyEmail(email);

    expect(classification.shouldBeUnsubscribable).toBe(false);
    expect(classification.isCritical).toBe(true);
    expect(classification.category).toBe('banking');
  });

  it('should NEVER mark medical appointments as unsubscribable', () => {
    const email = loadFixture('critical-medical-appointment.json');
    const classification = classifyEmail(email);

    expect(classification.shouldBeUnsubscribable).toBe(false);
    expect(classification.isCritical).toBe(true);
  });

  it('should correctly identify newsletters as unsubscribable', () => {
    const email = loadFixture('newsletter-substack.json');
    const classification = classifyEmail(email);

    expect(classification.shouldBeUnsubscribable).toBe(true);
    expect(classification.type).toBe('newsletter');
  });
});
```

#### Unsubscribe Parsing Tests

```javascript
describe('Unsubscribe Agent - Link Parsing', () => {
  it('should extract List-Unsubscribe header', () => {
    const email = loadFixture('newsletter-substack.json');
    const mechanism = parseUnsubscribeMechanism(email);

    expect(mechanism.hasListUnsubscribeHeader).toBe(true);
    expect(mechanism.unsubscribeUrls).toContain(
      'https://techinsights.substack.com/unsubscribe?token=abc123xyz'
    );
  });

  it('should extract unsubscribe URL from HTML body', () => {
    const email = loadFixture('marketing-retail-promo.json');
    const mechanism = parseUnsubscribeMechanism(email);

    expect(mechanism.unsubscribeUrls.length).toBeGreaterThan(0);
    expect(mechanism.unsubscribeUrls[0]).toMatch(/unsubscribe/i);
  });
});
```

## Test Coverage Goals

### Shopping Agent Coverage
- ✅ Order confirmation parsing (Amazon, Target, Best Buy)
- ✅ Shipment notification parsing
- ✅ Delivery confirmation parsing
- ✅ Order cancellation handling
- ✅ Refund notification handling
- ✅ Multi-item order parsing
- ✅ Price extraction with tax
- ✅ Tracking number/URL extraction
- ✅ Delivery estimate extraction
- ✅ Order status detection (5 states)

### Unsubscribe Agent Coverage
- ✅ Newsletter classification (2 fixtures)
- ✅ Promotional email classification (2 fixtures)
- ✅ Critical email protection (5 fixtures)
- ✅ List-Unsubscribe header parsing
- ✅ One-Click unsubscribe detection
- ✅ HTML body unsubscribe link extraction
- ✅ Preference center link extraction
- ✅ Safety guard tests (banking, medical, security, utility)

## Adding New Fixtures

When adding new fixtures, follow these guidelines:

1. **Use realistic data**: Base fixtures on real email patterns from major services
2. **Include both text and HTML**: Many parsers need both versions
3. **Add proper headers**: Include Message-ID, Content-Type, and List-Unsubscribe (if applicable)
4. **Document test expectations**: The `testExpectations` object should clearly state what tests should verify
5. **Mark critical emails**: Any email that should NEVER be unsubscribed must have `shouldNeverUnsubscribe: true`
6. **Include unsubscribe mechanisms**: For newsletters/marketing, include proper List-Unsubscribe headers and footer links

## Critical Safety Notes

⚠️ **UNSUBSCRIBE AGENT SAFETY IS CRITICAL**

The unsubscribe agent must NEVER automatically unsubscribe from:
- Banking/financial communications
- Security alerts (password resets, 2FA, login alerts)
- Medical/healthcare communications
- Utility bills and account notifications
- Government/legal notices
- Educational institution communications
- Employment/payroll communications

**Safelist Approach**: Consider implementing a safelist of domains/intents that should NEVER be automatically unsubscribed, even if they technically have unsubscribe links.

**User Consent**: For any automated unsubscribe action, consider requiring explicit user approval or implementing a "preview" mode where the user can review what will be unsubscribed.

**Audit Trail**: Every unsubscribe action should be logged with:
- Email sender
- Unsubscribe method used
- Success/failure status
- Timestamp

## Running Tests

```bash
# Backend tests (Node.js)
cd backend/services/classifier
npm test

# iOS tests (Swift)
cd Zero_ios_2/Zero
xcodebuild test -scheme Zero -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Fixture Statistics

- **Total Fixtures**: 16
- **Critical/Transactional**: 5
- **Shopping/Receipts**: 7
- **Newsletter/Marketing**: 4
- **Merchants Covered**: Amazon (3), Target (2), Best Buy (2)
- **Unsubscribe Mechanisms**: List-Unsubscribe headers (4), Footer links (4), One-Click (2)
