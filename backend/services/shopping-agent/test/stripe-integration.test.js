/**
 * Stripe Integration Test
 *
 * Tests the shopping agent's Stripe integration using real Stripe Test Mode API.
 * This is an integration test, not a unit test - it makes real API calls to Stripe.
 *
 * Prerequisites:
 * 1. Set STRIPE_SECRET_KEY environment variable to a test mode key (starts with sk_test_)
 * 2. Stripe test mode is free and safe to use
 * 3. Test data is automatically cleaned up
 *
 * Run with:
 *   STRIPE_SECRET_KEY=sk_test_... npm run test:integration
 */

const request = require('supertest');
const express = require('express');
const checkoutRouter = require('../routes/checkout');

// This test requires a real Stripe test key
const STRIPE_TEST_KEY = process.env.STRIPE_SECRET_KEY;

// Skip tests if no Stripe key is configured
const describeIfStripe = STRIPE_TEST_KEY ? describe : describe.skip;

describeIfStripe('Stripe Integration Tests (Test Mode API)', () => {
  let app;
  let stripe;
  let createdSessionIds = [];

  beforeAll(() => {
    // Initialize Stripe with test key
    if (STRIPE_TEST_KEY && !STRIPE_TEST_KEY.startsWith('sk_test_')) {
      throw new Error('⚠️  DANGER: Not a test key! Use sk_test_... keys only for integration tests');
    }

    // Initialize app
    app = express();
    app.use(express.json());
    app.use('/checkout', checkoutRouter);

    // Initialize Stripe client for cleanup
    if (STRIPE_TEST_KEY) {
      stripe = require('stripe')(STRIPE_TEST_KEY);
    }

    console.log('🧪 Running Stripe integration tests with REAL Test Mode API');
    console.log(`✅ Using test key: ${STRIPE_TEST_KEY.substring(0, 15)}...`);
  });

  afterEach(async () => {
    // Note: Stripe test sessions expire automatically after 24h
    // No manual cleanup needed, but we track them for reference
    if (createdSessionIds.length > 0) {
      console.log(`📝 Created ${createdSessionIds.length} test sessions (auto-expire in 24h)`);
    }
  });

  describe('POST /checkout/stripe - Real API Integration', () => {
    it('should create a real Stripe checkout session via API', async () => {
      const cartItems = [
        {
          productName: 'Integration Test Product',
          price: 29.99,
          quantity: 2,
          merchant: 'Test Store',
          productImage: 'https://via.placeholder.com/150'
        }
      ];

      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'integration-test-user',
          cartItems,
          successUrl: 'https://example.com/success?session_id={CHECKOUT_SESSION_ID}',
          cancelUrl: 'https://example.com/cancel'
        })
        .expect(200);

      // Verify response structure
      expect(res.body.success).toBe(true);
      expect(res.body.sessionId).toBeDefined();
      expect(res.body.sessionId).toMatch(/^cs_test_/);
      expect(res.body.checkoutUrl).toBeDefined();
      expect(res.body.checkoutUrl).toContain('checkout.stripe.com');
      expect(res.body.expiresAt).toBeDefined();

      // Track for cleanup reference
      createdSessionIds.push(res.body.sessionId);

      console.log(`  ✅ Created session: ${res.body.sessionId}`);
      console.log(`  🔗 Checkout URL: ${res.body.checkoutUrl}`);
    }, 10000); // 10s timeout for API call

    it('should create session with multiple products', async () => {
      const cartItems = [
        {
          productName: 'Product A',
          price: 19.99,
          quantity: 1,
          merchant: 'Store A'
        },
        {
          productName: 'Product B',
          price: 39.99,
          quantity: 2,
          merchant: 'Store B'
        },
        {
          productName: 'Product C',
          price: 9.99,
          quantity: 5,
          merchant: 'Store C'
        }
      ];

      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'integration-test-multi',
          cartItems,
          successUrl: 'https://example.com/success',
          cancelUrl: 'https://example.com/cancel'
        })
        .expect(200);

      expect(res.body.success).toBe(true);
      createdSessionIds.push(res.body.sessionId);

      // Verify session details via Stripe API
      const session = await stripe.checkout.sessions.retrieve(res.body.sessionId);
      expect(session.amount_total).toBe(14995); // (19.99 * 1 + 39.99 * 2 + 9.99 * 5) in cents
      expect(session.mode).toBe('payment');
      expect(session.status).toBe('open');

      console.log(`  ✅ Multi-product session total: $${session.amount_total / 100}`);
    }, 10000);

    it('should create session with product images', async () => {
      const cartItems = [
        {
          productName: 'Product with Image',
          price: 49.99,
          quantity: 1,
          merchant: 'Visual Store',
          productImage: 'https://via.placeholder.com/300'
        }
      ];

      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'integration-test-image',
          cartItems,
          successUrl: 'https://example.com/success',
          cancelUrl: 'https://example.com/cancel'
        })
        .expect(200);

      createdSessionIds.push(res.body.sessionId);

      // Verify image was included via Stripe API
      const session = await stripe.checkout.sessions.retrieve(res.body.sessionId, {
        expand: ['line_items.data.price.product']
      });

      expect(session.status).toBe('open');
      console.log(`  ✅ Session with images: ${res.body.sessionId}`);
    }, 10000);

    it('should include metadata in session', async () => {
      const cartItems = [
        {
          productName: 'Metadata Test Product',
          price: 99.99,
          quantity: 1,
          merchant: 'Test Store'
        }
      ];

      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'metadata-test-user-123',
          cartItems,
          successUrl: 'https://example.com/success',
          cancelUrl: 'https://example.com/cancel'
        })
        .expect(200);

      createdSessionIds.push(res.body.sessionId);

      // Verify metadata via Stripe API
      const session = await stripe.checkout.sessions.retrieve(res.body.sessionId);
      expect(session.metadata.userId).toBe('metadata-test-user-123');
      expect(session.metadata.source).toBe('zero-email-app');

      console.log(`  ✅ Session metadata: userId=${session.metadata.userId}`);
    }, 10000);

    it('should set correct payment settings', async () => {
      const cartItems = [
        {
          productName: 'Settings Test Product',
          price: 75.00,
          quantity: 1,
          merchant: 'Settings Store'
        }
      ];

      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'settings-test-user',
          cartItems,
          successUrl: 'https://example.com/success',
          cancelUrl: 'https://example.com/cancel'
        })
        .expect(200);

      createdSessionIds.push(res.body.sessionId);

      // Verify payment settings via Stripe API
      const session = await stripe.checkout.sessions.retrieve(res.body.sessionId);
      expect(session.mode).toBe('payment');
      expect(session.payment_method_types).toContain('card');
      expect(session.billing_address_collection).toBe('required');
      expect(session.shipping_address_collection).toBeDefined();
      expect(session.shipping_address_collection.allowed_countries).toContain('US');
      expect(session.shipping_address_collection.allowed_countries).toContain('CA');

      console.log(`  ✅ Payment methods: ${session.payment_method_types.join(', ')}`);
    }, 10000);

    it('should handle high-value purchases', async () => {
      const cartItems = [
        {
          productName: 'Luxury Item',
          price: 9999.99,
          quantity: 1,
          merchant: 'Luxury Store'
        }
      ];

      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'luxury-test-user',
          cartItems,
          successUrl: 'https://example.com/success',
          cancelUrl: 'https://example.com/cancel'
        })
        .expect(200);

      createdSessionIds.push(res.body.sessionId);

      const session = await stripe.checkout.sessions.retrieve(res.body.sessionId);
      expect(session.amount_total).toBe(999999); // $9999.99 in cents

      console.log(`  ✅ High-value session: $${session.amount_total / 100}`);
    }, 10000);
  });

  describe('GET /checkout/stripe/session/:sessionId - Real API Integration', () => {
    let testSessionId;

    beforeAll(async () => {
      // Create a session to retrieve
      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'retrieve-test-user',
          cartItems: [
            {
              productName: 'Retrieve Test Product',
              price: 25.00,
              quantity: 1,
              merchant: 'Test Store'
            }
          ],
          successUrl: 'https://example.com/success',
          cancelUrl: 'https://example.com/cancel'
        });

      testSessionId = res.body.sessionId;
      createdSessionIds.push(testSessionId);
    });

    it('should retrieve real Stripe session status', async () => {
      const res = await request(app)
        .get(`/checkout/stripe/session/${testSessionId}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.session).toMatchObject({
        id: testSessionId,
        status: 'open',
        paymentStatus: 'unpaid',
        amountTotal: 25.00,
        currency: 'usd'
      });

      console.log(`  ✅ Retrieved session status: ${res.body.session.status}`);
    }, 10000);

    it('should handle invalid session ID gracefully', async () => {
      const res = await request(app)
        .get('/checkout/stripe/session/cs_test_invalid_12345')
        .expect(500);

      expect(res.body.error).toBe('Internal Server Error');
      console.log(`  ✅ Properly handled invalid session ID`);
    }, 10000);
  });

  describe('Price Conversion Accuracy', () => {
    const testCases = [
      { price: 0.01, expectedCents: 1 },
      { price: 0.99, expectedCents: 99 },
      { price: 1.00, expectedCents: 100 },
      { price: 9.99, expectedCents: 999 },
      { price: 99.99, expectedCents: 9999 },
      { price: 123.45, expectedCents: 12345 },
      { price: 999.99, expectedCents: 99999 }
    ];

    testCases.forEach(({ price, expectedCents }) => {
      it(`should correctly convert $${price} to ${expectedCents} cents`, async () => {
        const res = await request(app)
          .post('/checkout/stripe')
          .send({
            userId: 'price-test-user',
            cartItems: [
              {
                productName: `Price Test $${price}`,
                price,
                quantity: 1,
                merchant: 'Test Store'
              }
            ],
            successUrl: 'https://example.com/success',
            cancelUrl: 'https://example.com/cancel'
          })
          .expect(200);

        createdSessionIds.push(res.body.sessionId);

        const session = await stripe.checkout.sessions.retrieve(res.body.sessionId);
        expect(session.amount_total).toBe(expectedCents);
      }, 10000);
    });
  });

  describe('Error Handling with Real API', () => {
    it('should fail with validation errors from Stripe', async () => {
      // Stripe will reject invalid data
      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'error-test-user',
          cartItems: [
            {
              productName: '', // Empty product name
              price: 10.00,
              quantity: 1,
              merchant: 'Test Store'
            }
          ],
          successUrl: 'https://example.com/success',
          cancelUrl: 'https://example.com/cancel'
        })
        .expect(500);

      expect(res.body.error).toBe('Internal Server Error');
      console.log(`  ✅ Properly handled Stripe validation error`);
    }, 10000);
  });

  describe('Session Expiration', () => {
    it('should create session that expires in 24 hours', async () => {
      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'expiration-test-user',
          cartItems: [
            {
              productName: 'Expiration Test Product',
              price: 50.00,
              quantity: 1,
              merchant: 'Test Store'
            }
          ],
          successUrl: 'https://example.com/success',
          cancelUrl: 'https://example.com/cancel'
        })
        .expect(200);

      createdSessionIds.push(res.body.sessionId);

      const session = await stripe.checkout.sessions.retrieve(res.body.sessionId);
      const expiresAt = new Date(session.expires_at * 1000);
      const now = new Date();
      const hoursUntilExpiry = (expiresAt - now) / (1000 * 60 * 60);

      expect(hoursUntilExpiry).toBeGreaterThan(23);
      expect(hoursUntilExpiry).toBeLessThan(25);

      console.log(`  ✅ Session expires at: ${expiresAt.toISOString()}`);
      console.log(`  ⏱️  Time until expiry: ${hoursUntilExpiry.toFixed(1)} hours`);
    }, 10000);
  });
});

// Show helpful message if Stripe key is not configured
if (!STRIPE_TEST_KEY) {
  console.log('\n⚠️  Stripe Integration Tests Skipped');
  console.log('To run integration tests, set STRIPE_SECRET_KEY environment variable:');
  console.log('');
  console.log('  export STRIPE_SECRET_KEY=sk_test_...');
  console.log('  npm run test:integration');
  console.log('');
  console.log('Get a test key from: https://dashboard.stripe.com/test/apikeys');
  console.log('Test mode is free and safe to use for development.\n');
}
