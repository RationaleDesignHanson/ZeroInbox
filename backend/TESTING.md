# Zero Backend Testing Guide

Complete guide for testing the shopping and unsubscribe agents with mock and real data.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Backend Tests](#backend-tests)
3. [iOS Tests](#ios-tests)
4. [Test Fixtures](#test-fixtures)
5. [Coverage Requirements](#coverage-requirements)
6. [CI/CD Integration](#cicd-integration)

---

## Quick Start

### Run All Backend Tests

```bash
cd /Users/matthanson/Zer0_Inbox/backend
./test-all.sh
```

### Run Individual Service Tests

```bash
# Classifier service (unsubscribe safety + parsing)
cd services/classifier
npm test

# Shopping agent (receipt parsing)
cd services/shopping-agent
npm test
```

### Run Specific Test Files

```bash
# Unsubscribe safety tests only
cd services/classifier
npx jest __tests__/unsubscribe-safety.test.js

# Receipt parsing tests only
cd services/shopping-agent
npx jest test/receipt-parsing.test.js
```

---

## Backend Tests

### Test Structure

```
backend/
├── test-all.sh                          # Unified test runner
├── services/
│   ├── classifier/
│   │   ├── __tests__/
│   │   │   ├── fixtures/                # 16 email fixtures
│   │   │   ├── unsubscribe-safety.test.js    # 50 safety tests
│   │   │   └── unsubscribe-parsing.test.js   # 32 parsing tests
│   │   ├── safelist.js                  # 6-layer protection
│   │   └── unsubscribe-service.js       # Unsubscribe workflow
│   └── shopping-agent/
│       ├── test/
│       │   └── receipt-parsing.test.js  # 40 receipt tests
│       ├── lib/
│       │   └── receiptParser.js         # Receipt parsing logic
│       └── routes/
│           └── receipts.js              # Receipt API endpoints
```

### Classifier Service Tests (82 tests)

**Unsubscribe Safety Tests (50 tests):**
- ✅ MUST NOT unsubscribe from banking emails (Chase, Wells Fargo, etc.)
- ✅ MUST NOT unsubscribe from security emails (password reset, 2FA)
- ✅ MUST NOT unsubscribe from medical emails
- ✅ MUST NOT unsubscribe from utility bills
- ✅ MUST NOT unsubscribe from receipt/order emails
- ✅ SHOULD allow unsubscribe from newsletters
- ✅ SHOULD allow unsubscribe from marketing emails

**Unsubscribe Parsing Tests (32 tests):**
- List-Unsubscribe header parsing (RFC 2369)
- One-Click unsubscribe detection (RFC 8058)
- Unsubscribe URL extraction from HTML body
- Preferred method selection
- Mock execution workflow
- Audit logging

**Run classifier tests:**
```bash
cd services/classifier
npm test                                      # All tests with coverage
npm run test:watch                            # Watch mode
npx jest unsubscribe-safety.test.js --verbose # Safety tests only
```

### Shopping Agent Tests (40 tests)

**Receipt Parsing Tests:**
- Library functions (normalizeEmail, extractMerchant, determineStatus)
- All 7 shopping fixtures (Amazon, Target, Best Buy orders)
- API endpoints (POST /receipts/parse, POST /receipts/batch)
- Status detection (ordered, shipped, delivered, cancelled, refunded)
- Error handling
- Batch processing (up to 100 receipts)

**Run shopping agent tests:**
```bash
cd services/shopping-agent
npm test                                    # All tests with coverage
npm run test:watch                          # Watch mode
npx jest receipt-parsing.test.js --verbose  # Receipt tests only
```

---

## iOS Tests

### Test Structure

```
Zero_ios_2/Zero/Tests/
├── FixtureLoader.swift              # Load backend fixtures
├── MockNetworkService.swift         # Mock HTTP requests
├── ShoppingCartServiceTests.swift   # 20+ shopping cart tests
├── UnsubscribeServiceTests.swift    # 30+ unsubscribe tests
└── ActionContextTests.swift         # Existing context tests
```

### Adding Tests to Xcode

1. Open `Zero.xcodeproj` in Xcode
2. Right-click on `Tests` folder in Project Navigator
3. Select "Add Files to Zero..."
4. Add the 4 new test files:
   - FixtureLoader.swift
   - MockNetworkService.swift
   - ShoppingCartServiceTests.swift
   - UnsubscribeServiceTests.swift
5. Ensure "Add to targets" includes the Test target
6. Build: ⌘B
7. Run tests: ⌘U

### Running iOS Tests

**Run all tests:**
```bash
xcodebuild test \
  -project Zero_ios_2/Zero/Zero.xcodeproj \
  -scheme Zero \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  | xcpretty
```

**Run specific test class:**
```bash
xcodebuild test \
  -project Zero_ios_2/Zero/Zero.xcodeproj \
  -scheme Zero \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ZeroTests/UnsubscribeServiceTests \
  | xcpretty
```

### ShoppingCartServiceTests (20+ tests)

- Fixture loading for all 7 shopping fixtures
- Order info extraction (Amazon, Target, Best Buy)
- Cart model tests
- Shopping workflow integration
- Order status detection
- Price and savings calculations
- Merchant grouping

### UnsubscribeServiceTests (30+ tests)

**CRITICAL SAFETY TESTS:**
- ❌ MUST NOT unsubscribe from banking emails
- ❌ MUST NOT unsubscribe from password reset
- ❌ MUST NOT unsubscribe from medical appointments
- ❌ MUST NOT unsubscribe from utility bills
- ❌ MUST NOT unsubscribe from 2FA codes
- ❌ MUST NOT unsubscribe from receipts/orders

**SAFE TO UNSUBSCRIBE:**
- ✅ Newsletters (Substack, TechCrunch)
- ✅ Marketing emails
- ✅ Product recommendations

---

## Test Fixtures

### Fixture Location

All fixtures are stored in:
```
/Users/matthanson/Zer0_Inbox/backend/services/classifier/__tests__/fixtures/
```

### Fixture Categories

**Shopping/Receipt Fixtures (7):**
- `shopping-amazon-order-confirmation.json` - New order placed
- `shopping-amazon-shipped.json` - Order shipped with tracking
- `shopping-amazon-delivered.json` - Order delivered
- `shopping-target-order.json` - Target multi-item order
- `shopping-bestbuy-multi-item.json` - Best Buy electronics
- `shopping-order-cancelled.json` - Cancelled order with refund
- `shopping-refund-issued.json` - Partial refund

**Newsletter/Marketing Fixtures (4):**
- `newsletter-substack.json` - Substack newsletter (One-Click unsubscribe)
- `newsletter-techcrunch.json` - TechCrunch Daily
- `marketing-retail-promo.json` - J.Crew sale email
- `marketing-product-recommendations.json` - Spotify recommendations

**Critical/Protected Fixtures (5):**
- `critical-bank-alert.json` - Chase security alert
- `critical-password-reset.json` - Password reset email
- `critical-medical-appointment.json` - Medical appointment reminder
- `critical-utility-bill.json` - PG&E utility bill
- `critical-2fa-code.json` - Two-factor authentication code

### Fixture Format

All fixtures follow this structure:

```json
{
  "id": "unique-fixture-id",
  "subject": "Email subject line",
  "from": {
    "name": "Sender Name",
    "email": "sender@example.com"
  },
  "to": "user@example.com",
  "date": "2025-01-18T10:00:00Z",
  "headers": {
    "Message-ID": "<unique-id@domain.com>",
    "List-Unsubscribe": "<https://example.com/unsubscribe>",
    "List-Unsubscribe-Post": "List-Unsubscribe=One-Click"
  },
  "body": {
    "text": "Plain text email body...",
    "html": "<html>HTML email body...</html>"
  },
  "classification": {
    "type": "newsletter|marketing|receipt|transactional",
    "category": "shopping|newsletter|critical",
    "intent": "order.confirmation|newsletter.subscription",
    "merchant": "Amazon",
    "shouldNeverUnsubscribe": true
  },
  "entities": {
    "orderNumber": "123-456-789",
    "merchant": "Amazon",
    "total": 99.99,
    "items": [...]
  }
}
```

---

## Coverage Requirements

### Backend Coverage Thresholds

Both services enforce **80% minimum coverage**:

```json
{
  "coverageThreshold": {
    "global": {
      "branches": 80,
      "functions": 80,
      "lines": 80,
      "statements": 80
    }
  }
}
```

### View Coverage Reports

**Classifier Service:**
```bash
cd services/classifier
npm test
open coverage/lcov-report/index.html
```

**Shopping Agent:**
```bash
cd services/shopping-agent
npm test
open coverage/lcov-report/index.html
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Backend Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Run Backend Tests
        run: |
          cd backend
          ./test-all.sh

      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          directory: ./backend/services
```

### Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

echo "Running backend tests..."
cd backend
./test-all.sh --no-coverage

if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
fi
```

---

## Troubleshooting

### Tests Failing

**Check fixture paths:**
```bash
ls -la /Users/matthanson/Zer0_Inbox/backend/services/classifier/__tests__/fixtures/
```

**Reinstall dependencies:**
```bash
cd services/classifier
rm -rf node_modules package-lock.json
npm install
```

### Port Conflicts

If you get "EADDRINUSE" errors, kill background processes:
```bash
lsof -ti:8084 | xargs kill -9  # Shopping agent port
lsof -ti:8080 | xargs kill -9  # Classifier port
```

### iOS Tests Not Found

Ensure test files are added to Xcode project:
1. Files must be in project navigator
2. Check target membership in File Inspector
3. Rebuild project (⌘⇧K then ⌘B)

---

## Test Best Practices

### When Writing New Tests

1. **Use fixtures** - Don't hard-code test data
2. **Test safety first** - For unsubscribe, always test the negative case
3. **Mock network calls** - Never hit real APIs in tests
4. **Test error paths** - Don't just test happy path
5. **Keep tests isolated** - No shared state between tests

### Critical Safety Tests

**NEVER remove or weaken these tests:**
- Banking domain protection
- Security email protection (password reset, 2FA)
- Medical email protection
- Receipt/order email protection

These tests are **deployment blockers** - all must pass before shipping.

---

## Additional Resources

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [RFC 2369 - List-Unsubscribe](https://www.rfc-editor.org/rfc/rfc2369)
- [RFC 8058 - One-Click Unsubscribe](https://www.rfc-editor.org/rfc/rfc8058)

---

## Summary

**Total Test Coverage:**
- Backend: 122 tests (82 unsubscribe + 40 receipt parsing)
- iOS: 50+ tests (shopping cart + unsubscribe safety)
- Fixtures: 16 realistic email fixtures
- Coverage: 80% minimum enforced

**Critical Safety:**
- 6-layer safelist protection
- 50 safety tests ensuring no dangerous unsubscribes
- All tests must pass before deployment
