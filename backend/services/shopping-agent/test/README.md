# Shopping Agent Service - Unit Tests

Comprehensive test suite for the shopping agent service covering cart management, product intelligence, and checkout workflows.

## Test Coverage

### 1. Cart Tests (`cart.test.js`)
Tests all cart API endpoints with success cases, validation, and edge cases:

- **POST /cart/add** - Add items to cart
  - ✅ Add single item successfully
  - ✅ Add multiple items
  - ✅ Add with optional fields (productUrl, imageUrl, variant)
  - ❌ Validation: missing userId, productName, price
  - ❌ Validation: invalid price (negative)
  - ❌ Validation: invalid quantity (0 or negative)
  - ✅ Default quantity to 1 if not provided

- **GET /cart/:userId** - Get user's cart
  - ✅ Return empty cart for new user
  - ✅ Return cart with items
  - ✅ Isolate carts by userId

- **PATCH /cart/:userId/:itemId** - Update item quantity
  - ✅ Update quantity successfully
  - ❌ Validation: quantity < 1
  - ❌ Item not found

- **DELETE /cart/:userId/:itemId** - Remove item
  - ✅ Remove item successfully
  - ❌ Item not found
  - ✅ Only remove specified item

- **DELETE /cart/:userId** - Clear entire cart
  - ✅ Clear cart successfully
  - ✅ Succeed even if cart already empty

- **GET /cart/:userId/summary** - Get cart summary
  - ✅ Return empty summary for empty cart
  - ✅ Calculate correct totals (items, price)
  - ✅ Round prices correctly

- **Edge Cases**
  - ✅ Very large quantities (1000+)
  - ✅ Very high prices ($999,999.99)
  - ✅ Special characters in product names
  - ✅ Malformed JSON
  - ✅ Missing Content-Type header

### 2. Products Tests (`products.test.js`)
Tests AI-powered product intelligence endpoints (mocks OpenAI API):

- **POST /products/resolve** - Extract product from email
  - ✅ Extract product details from email content
  - ✅ Scrape product page if URL provided
  - ✅ Handle scraping failures gracefully
  - ❌ Validation: missing emailContent
  - ❌ Handle OpenAI API errors
  - ✅ Extract sale pricing (originalPrice, promoCode, expiresAt)

- **POST /products/compare** - AI price comparison
  - ✅ Compare multiple products
  - ✅ Return bestDeal recommendation
  - ❌ Validation: requires at least 2 products
  - ❌ Validation: products must be array
  - ❌ Handle OpenAI API errors

- **POST /products/analyze** - GPT-4 deal analysis
  - ✅ Analyze deal quality
  - ✅ Return recommendations (shouldBuy, urgency)
  - ✅ Analyze poor quality deals
  - ❌ Validation: missing product object
  - ❌ Validation: missing productName
  - ❌ Handle OpenAI API errors

- **Confidence Calculation**
  - ✅ High confidence (1.0) with all fields
  - ✅ Lower confidence with missing fields

### 3. Checkout Tests (`checkout.test.js`)
Tests merchant deep links and Stripe checkout (mocks Stripe API):

- **POST /checkout/generate-link** - Merchant deep links
  - ✅ Generate Amazon deep link
  - ✅ Generate Target deep link
  - ✅ Generate Walmart deep link
  - ✅ Generate Best Buy deep link
  - ✅ Handle unsupported merchant
  - ❌ Validation: missing cartItems
  - ❌ Validation: empty cartItems
  - ✅ Handle multiple items
  - ✅ Case-insensitive merchant names

- **POST /checkout/stripe** - Stripe checkout session
  - ✅ Create Stripe checkout session
  - ✅ Handle multiple cart items
  - ✅ Convert prices to cents correctly
  - ✅ Include product images
  - ❌ Validation: missing cartItems, successUrl, cancelUrl
  - ❌ Stripe API errors
  - ❌ Stripe not configured (503)

- **GET /checkout/stripe/session/:sessionId** - Retrieve session
  - ✅ Retrieve session status
  - ❌ Handle retrieval errors
  - ❌ Stripe not configured

- **POST /checkout/acp** - ACP placeholder
  - ✅ Return 501 Not Implemented with roadmap
  - ✅ Include current working alternatives
  - ✅ Document ACP limitations
  - ✅ Include production-ready features
  - ✅ Include ACP specification link

- **Edge Cases**
  - ✅ Malformed JSON
  - ✅ Very large cart (100+ items)
  - ✅ Special characters in product names
  - ✅ Very high prices

## Running Tests

### Install Dependencies
```bash
cd /Users/matthanson/Zer0_Inbox/backend/services/shopping-agent
npm install
```

### Run All Tests
```bash
npm test
```

### Run Tests in Watch Mode
```bash
npm run test:watch
```

### Run Specific Test File
```bash
npx jest test/cart.test.js
npx jest test/products.test.js
npx jest test/checkout.test.js
```

### Run with Verbose Output
```bash
npx jest --verbose
```

## Test Configuration

Tests use **Jest** as the test framework with the following configuration:
- **Test Environment**: Node.js
- **Test Pattern**: `**/test/**/*.test.js`
- **Coverage**: Enabled by default with `npm test`

## Mocking

### OpenAI API (products.test.js)
All OpenAI API calls are mocked to return deterministic responses. No actual API calls are made during testing.

### Stripe API (checkout.test.js)
All Stripe API calls are mocked. Tests verify correct API usage without making real Stripe requests.

### Axios (products.test.js)
Web scraping via axios is mocked to test both successful scraping and failure scenarios.

## Environment Variables

Tests set temporary environment variables:
- `STRIPE_SECRET_KEY` - Set to `sk_test_fake_key` during Stripe tests
- All env vars are cleaned up after each test

## Test Output

Expected output:
```
PASS  test/cart.test.js
PASS  test/products.test.js
PASS  test/checkout.test.js

Test Suites: 3 passed, 3 total
Tests:       XX passed, XX total
Snapshots:   0 total
Time:        X.XXXs
```

## Coverage Report

Coverage report is generated in `coverage/` directory:
```bash
open coverage/lcov-report/index.html
```

## Continuous Integration

To add to CI/CD pipeline:
```yaml
# GitHub Actions example
- name: Run Shopping Agent Tests
  run: |
    cd backend/services/shopping-agent
    npm install
    npm test
```

## Troubleshooting

### "Cannot find module 'openai'"
```bash
npm install openai --save
```

### "Cannot find module 'jest'"
```bash
npm install jest supertest --save-dev
```

### Tests timing out
Increase Jest timeout in test file:
```javascript
jest.setTimeout(10000); // 10 seconds
```

## Next Steps

For integration testing, see:
- **Item #11**: Stripe integration test with test mode (live API testing)
- **Item #12**: shopping-agent-test.html test harness (manual UI testing)
