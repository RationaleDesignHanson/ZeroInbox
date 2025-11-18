# Zero Backend Services

Backend services for Zero inbox automation: shopping agent and classifier service.

## Quick Start

### Run All Tests

```bash
./test-all.sh
```

### Test Individual Services

```bash
# Classifier (unsubscribe safety)
cd services/classifier && npm test

# Shopping Agent (receipt parsing)
cd services/shopping-agent && npm test
```

## Services

### Classifier Service (Port 8080)

Email classification and unsubscribe management with 6-layer safety protection.

**Tests:** 82 tests (50 safety + 32 parsing)
- ❌ Blocks: Banking, medical, security, utility, receipt emails
- ✅ Allows: Newsletters, marketing emails

**Key Files:**
- `safelist.js` - 60+ critical domains, intent patterns
- `unsubscribe-service.js` - Safe unsubscribe workflow
- `__tests__/unsubscribe-safety.test.js` - Critical safety tests
- `__tests__/unsubscribe-parsing.test.js` - Parsing tests

### Shopping Agent Service (Port 8084)

Receipt parsing and shopping cart management.

**Tests:** 40 tests
- Receipt parsing from Amazon, Target, Best Buy
- Order status detection (ordered, shipped, delivered, cancelled, refunded)
- Batch processing (up to 100 receipts)

**Key Files:**
- `lib/receiptParser.js` - Parse order emails
- `routes/receipts.js` - Receipt API endpoints
- `test/receipt-parsing.test.js` - Receipt tests

## Test Fixtures

**Location:** `services/classifier/__tests__/fixtures/`

**16 Fixtures:**
- 7 Shopping/Receipt emails (Amazon, Target, Best Buy)
- 4 Newsletter/Marketing emails (Substack, TechCrunch, etc.)
- 5 Critical/Protected emails (Banking, medical, security)

## Coverage

Both services enforce **80% minimum coverage**:
- Statements: 80%
- Branches: 80%
- Functions: 80%
- Lines: 80%

View coverage reports:
```bash
cd services/classifier && npm test && open coverage/lcov-report/index.html
cd services/shopping-agent && npm test && open coverage/lcov-report/index.html
```

## Documentation

See [TESTING.md](./TESTING.md) for complete testing guide.

## Architecture

```
backend/
├── test-all.sh                    # Unified test runner
├── TESTING.md                     # Complete testing guide
├── services/
│   ├── classifier/
│   │   ├── safelist.js           # 6-layer protection
│   │   ├── unsubscribe-service.js
│   │   └── __tests__/
│   │       ├── fixtures/         # 16 email fixtures
│   │       ├── unsubscribe-safety.test.js
│   │       └── unsubscribe-parsing.test.js
│   └── shopping-agent/
│       ├── lib/
│       │   └── receiptParser.js
│       ├── routes/
│       │   └── receipts.js
│       └── test/
│           └── receipt-parsing.test.js
```

## Status

✅ **All 122 backend tests passing**
- Classifier: 82/82 ✓
- Shopping Agent: 40/40 ✓

## Safety Guarantees

**NEVER allows unsubscribe from:**
- Banking (Chase, Wells Fargo, PayPal, etc.)
- Security (Password reset, 2FA codes)
- Medical (Appointments, prescriptions)
- Utility (PG&E, electric, internet bills)
- Government (IRS, Social Security, USPS)
- Educational (.edu domains)
- Receipts (Order confirmations, shipping, refunds)

**Allows unsubscribe from:**
- Newsletters (Substack, TechCrunch, etc.)
- Marketing (Retail promos, product recommendations)
