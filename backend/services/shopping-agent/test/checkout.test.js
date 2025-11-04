/**
 * Shopping Agent - Checkout Service Unit Tests
 * Tests merchant deep links, Stripe checkout, and ACP placeholder
 * Mocks Stripe API calls for deterministic testing
 */

const request = require('supertest');
const express = require('express');
const checkoutRouter = require('../routes/checkout');

// Mock Stripe
jest.mock('stripe', () => {
  return jest.fn().mockImplementation(() => ({
    checkout: {
      sessions: {
        create: jest.fn(),
        retrieve: jest.fn()
      }
    }
  }));
});

// Create test app
const app = express();
app.use(express.json());
app.use('/checkout', checkoutRouter);

describe('Shopping Agent - Checkout API', () => {

  beforeEach(() => {
    jest.clearAllMocks();
    // Set Stripe key for tests
    process.env.STRIPE_SECRET_KEY = 'sk_test_fake_key';
  });

  afterEach(() => {
    delete process.env.STRIPE_SECRET_KEY;
  });

  describe('POST /checkout/generate-link', () => {
    it('should generate Amazon deep link', async () => {
      const cartItems = [
        {
          productUrl: 'https://amazon.com/dp/B08N5WRWNW',
          quantity: 1
        }
      ];

      const res = await request(app)
        .post('/checkout/generate-link')
        .send({
          cartItems,
          merchant: 'Amazon'
        })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.checkoutUrl).toBe('https://amazon.com/dp/B08N5WRWNW');
      expect(res.body.merchant).toBe('Amazon');
      expect(res.body.instructions).toBeDefined();
    });

    it('should generate Target deep link', async () => {
      const cartItems = [
        {
          productUrl: 'https://target.com/product-123',
          quantity: 2
        }
      ];

      const res = await request(app)
        .post('/checkout/generate-link')
        .send({
          cartItems,
          merchant: 'Target'
        })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.checkoutUrl).toBe('https://www.target.com/cart');
      expect(res.body.merchant).toBe('Target');
    });

    it('should generate Walmart deep link', async () => {
      const cartItems = [
        {
          productUrl: 'https://walmart.com/ip/123456789',
          quantity: 1
        }
      ];

      const res = await request(app)
        .post('/checkout/generate-link')
        .send({
          cartItems,
          merchant: 'Walmart'
        })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.checkoutUrl).toBe('https://www.walmart.com/cart');
    });

    it('should generate Best Buy deep link', async () => {
      const cartItems = [
        {
          productUrl: 'https://bestbuy.com/site/product/123.p',
          quantity: 1
        }
      ];

      const res = await request(app)
        .post('/checkout/generate-link')
        .send({
          cartItems,
          merchant: 'Best Buy'
        })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.checkoutUrl).toBe('https://www.bestbuy.com/cart');
    });

    it('should handle unsupported merchant', async () => {
      const cartItems = [
        {
          productUrl: 'https://unsupported-store.com/product',
          quantity: 1
        }
      ];

      const res = await request(app)
        .post('/checkout/generate-link')
        .send({
          cartItems,
          merchant: 'Unsupported Store'
        })
        .expect(200);

      expect(res.body.success).toBe(false);
      expect(res.body.message).toMatch(/not yet supported/i);
      expect(res.body.fallbackUrls).toBeDefined();
    });

    it('should fail without cartItems', async () => {
      const res = await request(app)
        .post('/checkout/generate-link')
        .send({ merchant: 'Amazon' })
        .expect(400);

      expect(res.body.message).toMatch(/cartItems.*required/i);
    });

    it('should fail with empty cartItems', async () => {
      const res = await request(app)
        .post('/checkout/generate-link')
        .send({
          cartItems: [],
          merchant: 'Amazon'
        })
        .expect(400);

      expect(res.body.message).toMatch(/must not be empty/i);
    });

    it('should fail with invalid cartItems type', async () => {
      const res = await request(app)
        .post('/checkout/generate-link')
        .send({
          cartItems: 'not-an-array',
          merchant: 'Amazon'
        })
        .expect(400);

      expect(res.body.message).toMatch(/cartItems.*required/i);
    });

    it('should handle multiple items in cart', async () => {
      const cartItems = [
        { productUrl: 'https://amazon.com/dp/ITEM1', quantity: 2 },
        { productUrl: 'https://amazon.com/dp/ITEM2', quantity: 1 },
        { productUrl: 'https://amazon.com/dp/ITEM3', quantity: 3 }
      ];

      const res = await request(app)
        .post('/checkout/generate-link')
        .send({
          cartItems,
          merchant: 'Amazon'
        })
        .expect(200);

      expect(res.body.itemCount).toBe(3);
    });

    it('should handle case-insensitive merchant names', async () => {
      const cartItems = [
        { productUrl: 'https://amazon.com/product', quantity: 1 }
      ];

      const res = await request(app)
        .post('/checkout/generate-link')
        .send({
          cartItems,
          merchant: 'AMAZON'
        })
        .expect(200);

      expect(res.body.success).toBe(true);
    });
  });

  describe('POST /checkout/stripe', () => {
    it('should create Stripe checkout session', async () => {
      // Mock Stripe response
      const stripe = require('stripe');
      const mockCreate = stripe.mock.results[0].value.checkout.sessions.create;

      mockCreate.mockResolvedValueOnce({
        id: 'cs_test_123456',
        url: 'https://checkout.stripe.com/pay/cs_test_123456',
        expires_at: Math.floor(Date.now() / 1000) + 3600
      });

      const cartItems = [
        {
          productName: 'Test Product',
          price: 29.99,
          quantity: 2,
          merchant: 'Test Store',
          productImage: 'https://example.com/image.jpg'
        }
      ];

      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'user-123',
          cartItems,
          successUrl: 'https://app.example.com/success',
          cancelUrl: 'https://app.example.com/cancel'
        })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.sessionId).toBe('cs_test_123456');
      expect(res.body.checkoutUrl).toBe('https://checkout.stripe.com/pay/cs_test_123456');
      expect(res.body.expiresAt).toBeDefined();

      // Verify Stripe API was called correctly
      expect(mockCreate).toHaveBeenCalledWith(
        expect.objectContaining({
          mode: 'payment',
          payment_method_types: ['card'],
          billing_address_collection: 'required'
        })
      );
    });

    it('should handle multiple cart items in Stripe session', async () => {
      const stripe = require('stripe');
      const mockCreate = stripe.mock.results[0].value.checkout.sessions.create;

      mockCreate.mockResolvedValueOnce({
        id: 'cs_test_multi',
        url: 'https://checkout.stripe.com/pay/cs_test_multi',
        expires_at: Math.floor(Date.now() / 1000) + 3600
      });

      const cartItems = [
        { productName: 'Product 1', price: 10.00, quantity: 2, merchant: 'Store A' },
        { productName: 'Product 2', price: 25.50, quantity: 1, merchant: 'Store B' },
        { productName: 'Product 3', price: 99.99, quantity: 3, merchant: 'Store C' }
      ];

      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'user-456',
          cartItems,
          successUrl: 'https://app.example.com/success',
          cancelUrl: 'https://app.example.com/cancel'
        })
        .expect(200);

      expect(res.body.success).toBe(true);

      // Verify line items were created correctly
      const callArgs = mockCreate.mock.calls[0][0];
      expect(callArgs.line_items).toHaveLength(3);
      expect(callArgs.line_items[0]).toMatchObject({
        quantity: 2,
        price_data: {
          currency: 'usd',
          unit_amount: 1000 // $10.00 in cents
        }
      });
    });

    it('should convert prices to cents correctly', async () => {
      const stripe = require('stripe');
      const mockCreate = stripe.mock.results[0].value.checkout.sessions.create;

      mockCreate.mockResolvedValueOnce({
        id: 'cs_test_price',
        url: 'https://checkout.stripe.com/pay/cs_test_price',
        expires_at: Math.floor(Date.now() / 1000) + 3600
      });

      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'user-789',
          cartItems: [
            { productName: 'Product', price: 99.99, quantity: 1, merchant: 'Store' }
          ],
          successUrl: 'https://app.example.com/success',
          cancelUrl: 'https://app.example.com/cancel'
        })
        .expect(200);

      const callArgs = mockCreate.mock.calls[0][0];
      expect(callArgs.line_items[0].price_data.unit_amount).toBe(9999); // 99.99 -> 9999 cents
    });

    it('should include product images in Stripe session', async () => {
      const stripe = require('stripe');
      const mockCreate = stripe.mock.results[0].value.checkout.sessions.create;

      mockCreate.mockResolvedValueOnce({
        id: 'cs_test_image',
        url: 'https://checkout.stripe.com/pay/cs_test_image',
        expires_at: Math.floor(Date.now() / 1000) + 3600
      });

      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'user-999',
          cartItems: [
            {
              productName: 'Product',
              price: 50.00,
              quantity: 1,
              merchant: 'Store',
              productImage: 'https://example.com/product.jpg'
            }
          ],
          successUrl: 'https://app.example.com/success',
          cancelUrl: 'https://app.example.com/cancel'
        })
        .expect(200);

      const callArgs = mockCreate.mock.calls[0][0];
      expect(callArgs.line_items[0].price_data.product_data.images).toContain(
        'https://example.com/product.jpg'
      );
    });

    it('should fail without cartItems', async () => {
      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          successUrl: 'https://app.example.com/success',
          cancelUrl: 'https://app.example.com/cancel'
        })
        .expect(400);

      expect(res.body.message).toMatch(/cartItems.*required/i);
    });

    it('should fail without successUrl', async () => {
      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          cartItems: [{ productName: 'Product', price: 10, quantity: 1, merchant: 'Store' }],
          cancelUrl: 'https://app.example.com/cancel'
        })
        .expect(400);

      expect(res.body.message).toMatch(/successUrl.*required/i);
    });

    it('should fail without cancelUrl', async () => {
      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          cartItems: [{ productName: 'Product', price: 10, quantity: 1, merchant: 'Store' }],
          successUrl: 'https://app.example.com/success'
        })
        .expect(400);

      expect(res.body.message).toMatch(/cancelUrl.*required/i);
    });

    it('should fail with empty cartItems', async () => {
      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          cartItems: [],
          successUrl: 'https://app.example.com/success',
          cancelUrl: 'https://app.example.com/cancel'
        })
        .expect(400);

      expect(res.body.message).toMatch(/must not be empty/i);
    });

    it('should handle Stripe API errors', async () => {
      const stripe = require('stripe');
      const mockCreate = stripe.mock.results[0].value.checkout.sessions.create;

      mockCreate.mockRejectedValueOnce(new Error('Stripe API error'));

      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'user-error',
          cartItems: [{ productName: 'Product', price: 10, quantity: 1, merchant: 'Store' }],
          successUrl: 'https://app.example.com/success',
          cancelUrl: 'https://app.example.com/cancel'
        })
        .expect(500);

      expect(res.body.error).toBe('Internal Server Error');
    });

    it('should fail when Stripe is not configured', async () => {
      // Remove Stripe key
      delete process.env.STRIPE_SECRET_KEY;

      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          cartItems: [{ productName: 'Product', price: 10, quantity: 1, merchant: 'Store' }],
          successUrl: 'https://app.example.com/success',
          cancelUrl: 'https://app.example.com/cancel'
        })
        .expect(503);

      expect(res.body.error).toBe('Service Unavailable');
      expect(res.body.message).toMatch(/Stripe is not configured/i);

      // Restore for other tests
      process.env.STRIPE_SECRET_KEY = 'sk_test_fake_key';
    });
  });

  describe('GET /checkout/stripe/session/:sessionId', () => {
    it('should retrieve Stripe session status', async () => {
      const stripe = require('stripe');
      const mockRetrieve = stripe.mock.results[0].value.checkout.sessions.retrieve;

      mockRetrieve.mockResolvedValueOnce({
        id: 'cs_test_retrieve',
        status: 'complete',
        payment_status: 'paid',
        amount_total: 9999,
        currency: 'usd',
        customer_details: {
          email: 'customer@example.com'
        }
      });

      const res = await request(app)
        .get('/checkout/stripe/session/cs_test_retrieve')
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.session).toMatchObject({
        id: 'cs_test_retrieve',
        status: 'complete',
        paymentStatus: 'paid',
        amountTotal: 99.99,
        currency: 'usd',
        customerEmail: 'customer@example.com'
      });
    });

    it('should handle Stripe retrieval errors', async () => {
      const stripe = require('stripe');
      const mockRetrieve = stripe.mock.results[0].value.checkout.sessions.retrieve;

      mockRetrieve.mockRejectedValueOnce(new Error('Session not found'));

      const res = await request(app)
        .get('/checkout/stripe/session/cs_invalid')
        .expect(500);

      expect(res.body.error).toBe('Internal Server Error');
    });

    it('should fail when Stripe is not configured', async () => {
      delete process.env.STRIPE_SECRET_KEY;

      const res = await request(app)
        .get('/checkout/stripe/session/cs_test_123')
        .expect(503);

      expect(res.body.error).toBe('Service Unavailable');

      process.env.STRIPE_SECRET_KEY = 'sk_test_fake_key';
    });
  });

  describe('POST /checkout/acp', () => {
    it('should return 501 Not Implemented with roadmap', async () => {
      const res = await request(app)
        .post('/checkout/acp')
        .send({
          merchant: 'Etsy',
          cartItems: [
            { productName: 'Handmade Item', price: 25.00, quantity: 1 }
          ],
          buyerInfo: { email: 'buyer@example.com' }
        })
        .expect(501);

      expect(res.body.status).toBe('placeholder');
      expect(res.body.message).toMatch(/planned for future release/i);
      expect(res.body.currentOptions).toBeDefined();
      expect(res.body.roadmap).toBeDefined();
      expect(res.body.roadmap.option).toBe('B');
    });

    it('should include current working alternatives', async () => {
      const res = await request(app)
        .post('/checkout/acp')
        .send({
          merchant: 'Shopify',
          cartItems: [{ productName: 'Product', price: 50, quantity: 1 }]
        })
        .expect(501);

      expect(res.body.currentOptions).toHaveLength(2);
      expect(res.body.currentOptions[0].endpoint).toBe('POST /checkout/generate-link');
      expect(res.body.currentOptions[0].status).toBe('production-ready');
    });

    it('should document ACP limitations', async () => {
      const res = await request(app)
        .post('/checkout/acp')
        .send({
          merchant: 'Test',
          cartItems: []
        })
        .expect(501);

      expect(res.body.notes).toBeDefined();
      expect(res.body.notes.some(note => note.includes('Etsy and Shopify'))).toBe(true);
    });

    it('should include production-ready features', async () => {
      const res = await request(app)
        .post('/checkout/acp')
        .send({})
        .expect(501);

      expect(res.body.productionFeatures).toMatchObject({
        productParsing: expect.stringContaining('WORKING'),
        priceComparison: expect.stringContaining('WORKING'),
        cartManagement: expect.stringContaining('WORKING'),
        stripeCheckout: expect.stringContaining('WORKING')
      });
    });

    it('should include ACP specification link', async () => {
      const res = await request(app)
        .post('/checkout/acp')
        .send({})
        .expect(501);

      expect(res.body.acpSpecification).toMatch(/developers\.openai\.com/);
    });
  });

  describe('Edge Cases and Error Handling', () => {
    it('should handle malformed JSON', async () => {
      const res = await request(app)
        .post('/checkout/generate-link')
        .set('Content-Type', 'application/json')
        .send('{ invalid json }')
        .expect(400);
    });

    it('should handle very large cart items', async () => {
      const stripe = require('stripe');
      const mockCreate = stripe.mock.results[0].value.checkout.sessions.create;

      mockCreate.mockResolvedValueOnce({
        id: 'cs_test_large',
        url: 'https://checkout.stripe.com/pay/cs_test_large',
        expires_at: Math.floor(Date.now() / 1000) + 3600
      });

      const cartItems = Array(100).fill({
        productName: 'Bulk Item',
        price: 1.00,
        quantity: 1,
        merchant: 'Store'
      });

      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'user-bulk',
          cartItems,
          successUrl: 'https://app.example.com/success',
          cancelUrl: 'https://app.example.com/cancel'
        })
        .expect(200);

      expect(res.body.success).toBe(true);
    });

    it('should handle special characters in product names', async () => {
      const stripe = require('stripe');
      const mockCreate = stripe.mock.results[0].value.checkout.sessions.create;

      mockCreate.mockResolvedValueOnce({
        id: 'cs_test_special',
        url: 'https://checkout.stripe.com/pay/cs_test_special',
        expires_at: Math.floor(Date.now() / 1000) + 3600
      });

      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'user-special',
          cartItems: [
            {
              productName: 'Product with "Quotes" & <HTML> Tags',
              price: 10.00,
              quantity: 1,
              merchant: 'Store'
            }
          ],
          successUrl: 'https://app.example.com/success',
          cancelUrl: 'https://app.example.com/cancel'
        })
        .expect(200);

      expect(res.body.success).toBe(true);
    });

    it('should handle very high prices', async () => {
      const stripe = require('stripe');
      const mockCreate = stripe.mock.results[0].value.checkout.sessions.create;

      mockCreate.mockResolvedValueOnce({
        id: 'cs_test_expensive',
        url: 'https://checkout.stripe.com/pay/cs_test_expensive',
        expires_at: Math.floor(Date.now() / 1000) + 3600
      });

      const res = await request(app)
        .post('/checkout/stripe')
        .send({
          userId: 'user-luxury',
          cartItems: [
            {
              productName: 'Luxury Item',
              price: 999999.99,
              quantity: 1,
              merchant: 'Luxury Store'
            }
          ],
          successUrl: 'https://app.example.com/success',
          cancelUrl: 'https://app.example.com/cancel'
        })
        .expect(200);

      const callArgs = mockCreate.mock.calls[0][0];
      expect(callArgs.line_items[0].price_data.unit_amount).toBe(99999999);
    });
  });
});
