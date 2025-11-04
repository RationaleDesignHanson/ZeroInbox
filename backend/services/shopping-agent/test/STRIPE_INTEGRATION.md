# Stripe Integration Testing Guide

This guide explains how to run real Stripe integration tests against Stripe's Test Mode API.

## Overview

Unlike unit tests which mock API calls, integration tests make **real API calls** to Stripe's Test Mode to verify the actual integration works correctly. This ensures:

1. ✅ Our Stripe SDK usage is correct
2. ✅ Request/response formats are valid
3. ✅ Price conversions are accurate
4. ✅ Session creation works end-to-end
5. ✅ Metadata and configurations are properly set

## Prerequisites

### 1. Get a Stripe Test Mode API Key

1. Go to [Stripe Dashboard](https://dashboard.stripe.com/test/apikeys)
2. Sign up for a free Stripe account (if you don't have one)
3. Navigate to **Developers → API keys**
4. Switch to **Test mode** (toggle in sidebar)
5. Copy the **Secret key** (starts with `sk_test_`)

⚠️ **IMPORTANT**: Only use test mode keys (`sk_test_...`). Never use live keys for testing!

### 2. Set Environment Variable

**MacOS/Linux:**
```bash
export STRIPE_SECRET_KEY=sk_test_YOUR_KEY_HERE
```

**Windows (PowerShell):**
```powershell
$env:STRIPE_SECRET_KEY="sk_test_YOUR_KEY_HERE"
```

**Or create a `.env` file:**
```bash
# backend/services/shopping-agent/.env
STRIPE_SECRET_KEY=sk_test_YOUR_KEY_HERE
```

## Running Integration Tests

### Basic Run
```bash
cd /Users/matthanson/Zer0_Inbox/backend/services/shopping-agent
npm run test:integration
```

### With Verbose Output
```bash
STRIPE_SECRET_KEY=sk_test_... npx jest test/stripe-integration.test.js --verbose
```

### Single Test
```bash
npx jest test/stripe-integration.test.js -t "should create a real Stripe checkout session"
```

## What Gets Tested

### ✅ Checkout Session Creation
- Creates real Stripe checkout sessions
- Verifies session URLs and IDs
- Tests single and multiple products
- Validates price conversion ($99.99 → 9999 cents)

### ✅ Session Retrieval
- Retrieves session status from Stripe
- Verifies payment status
- Checks total amounts

### ✅ Configuration Validation
- Payment method types (card)
- Billing address collection
- Shipping address collection
- Metadata inclusion

### ✅ Edge Cases
- High-value purchases ($9,999.99)
- Fractional prices ($0.01, $123.45)
- Product images
- Session expiration (24 hours)

### ✅ Error Handling
- Invalid session IDs
- Stripe validation errors
- Missing required fields

## Test Output Example

```
🧪 Running Stripe integration tests with REAL Test Mode API
✅ Using test key: sk_test_51PqR3S...

 PASS  test/stripe-integration.test.js
  Stripe Integration Tests (Test Mode API)
    POST /checkout/stripe - Real API Integration
      ✓ should create a real Stripe checkout session via API (1234ms)
        ✅ Created session: cs_test_a1B2c3D4e5F6
        🔗 Checkout URL: https://checkout.stripe.com/c/pay/cs_test_...
      ✓ should create session with multiple products (987ms)
        ✅ Multi-product session total: $149.95
      ✓ should include metadata in session (876ms)
        ✅ Session metadata: userId=metadata-test-user-123

    GET /checkout/stripe/session/:sessionId - Real API Integration
      ✓ should retrieve real Stripe session status (654ms)
        ✅ Retrieved session status: open

Test Suites: 1 passed, 1 total
Tests:       15 passed, 15 total
Time:        12.345s
```

## Understanding Test Sessions

### What Happens to Test Data?

1. **Sessions auto-expire**: Test checkout sessions expire after 24 hours
2. **No cleanup needed**: Stripe automatically removes expired test data
3. **No charges**: Test mode never processes real payments
4. **Unlimited testing**: Free and unlimited test API calls

### Viewing Test Sessions

1. Go to [Stripe Dashboard](https://dashboard.stripe.com/test/payments)
2. Switch to **Test mode**
3. View **Payments → Checkout sessions**
4. See all sessions created by tests

## Price Conversion Tests

Tests verify accurate conversion from dollars to cents:

| Price | Expected Cents | Status |
|-------|---------------|--------|
| $0.01 | 1 | ✅ |
| $0.99 | 99 | ✅ |
| $1.00 | 100 | ✅ |
| $9.99 | 999 | ✅ |
| $99.99 | 9999 | ✅ |
| $123.45 | 12345 | ✅ |
| $999.99 | 99999 | ✅ |

## Troubleshooting

### Tests are Skipped
```
⚠️  Stripe Integration Tests Skipped
```

**Solution**: Set `STRIPE_SECRET_KEY` environment variable
```bash
export STRIPE_SECRET_KEY=sk_test_YOUR_KEY_HERE
npm run test:integration
```

### Error: "Not a test key"
```
⚠️  DANGER: Not a test key! Use sk_test_... keys only
```

**Solution**: You're using a live key. Get a test key from:
https://dashboard.stripe.com/test/apikeys

### Tests Timeout
```
Timeout - Async callback was not invoked within the 5000 ms timeout
```

**Solution**: Tests have 10s timeout for API calls. If still timing out:
1. Check internet connection
2. Verify Stripe API status: https://status.stripe.com
3. Increase timeout in test file

### API Key Rejected
```
Error: Invalid API Key provided
```

**Solution**:
1. Verify key starts with `sk_test_`
2. Copy the full key (no trailing spaces)
3. Regenerate key if needed in Stripe Dashboard

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Shopping Agent Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install Dependencies
        run: |
          cd backend/services/shopping-agent
          npm install

      - name: Run Unit Tests
        run: |
          cd backend/services/shopping-agent
          npm test

      - name: Run Integration Tests
        env:
          STRIPE_SECRET_KEY: ${{ secrets.STRIPE_TEST_KEY }}
        run: |
          cd backend/services/shopping-agent
          npm run test:integration
```

**Setup**:
1. Go to GitHub repo → Settings → Secrets
2. Add secret: `STRIPE_TEST_KEY` = `sk_test_...`

## Safety Checklist

Before running integration tests:

- [ ] Using test mode key (`sk_test_...`) not live key (`sk_live_...`)
- [ ] Test mode enabled in Stripe Dashboard
- [ ] Not using production database
- [ ] Okay with creating test sessions (they auto-expire)

## Best Practices

### DO ✅
- Run integration tests before deploying
- Use separate test keys for CI/CD
- Run locally before pushing
- Check Stripe Dashboard to view test data
- Verify price conversions are accurate

### DON'T ❌
- Use live API keys for testing
- Commit API keys to git
- Run integration tests in production
- Delete test keys that are in use
- Test payment capture (out of scope)

## Next Steps

After verifying Stripe integration:

1. **Item #12**: Create `shopping-agent-test.html` - Manual UI testing harness
2. Test full checkout flow from iOS app → Backend → Stripe
3. Implement webhook handlers for payment events
4. Add monitoring for failed Stripe calls

## Resources

- [Stripe Test Cards](https://stripe.com/docs/testing)
- [Stripe API Documentation](https://stripe.com/docs/api)
- [Checkout Session API](https://stripe.com/docs/api/checkout/sessions)
- [Stripe Dashboard (Test Mode)](https://dashboard.stripe.com/test)

## Support

If integration tests fail:
1. Check [Stripe API Status](https://status.stripe.com)
2. Review test output for specific error
3. Verify API key in Stripe Dashboard
4. Check test file for recent changes
