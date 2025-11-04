/**
 * Shopping Agent - Products Service Unit Tests
 * Tests product resolution, comparison, and analysis endpoints
 * Mocks OpenAI API calls for deterministic testing
 */

const request = require('supertest');
const express = require('express');
const productsRouter = require('../routes/products');

// Mock OpenAI
jest.mock('openai', () => {
  return jest.fn().mockImplementation(() => ({
    chat: {
      completions: {
        create: jest.fn()
      }
    }
  }));
});

// Mock axios for web scraping
jest.mock('axios');
const axios = require('axios');

// Create test app
const app = express();
app.use(express.json());
app.use('/products', productsRouter);

describe('Shopping Agent - Products API', () => {

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /products/resolve', () => {
    it('should extract product details from email content', async () => {
      // Mock OpenAI response
      const OpenAI = require('openai');
      const mockCreate = OpenAI.mock.results[0].value.chat.completions.create;

      mockCreate.mockResolvedValueOnce({
        choices: [{
          message: {
            content: JSON.stringify({
              productName: 'iPhone 15 Pro',
              productUrl: 'https://apple.com/iphone-15-pro',
              price: 999.99,
              originalPrice: null,
              merchant: 'Apple',
              productImage: 'https://apple.com/image.jpg',
              sku: 'IPHONE15PRO',
              category: 'Electronics',
              expiresAt: null,
              description: 'Latest iPhone with titanium design',
              promoCode: null
            })
          }
        }]
      });

      const res = await request(app)
        .post('/products/resolve')
        .send({
          emailContent: 'Check out the new iPhone 15 Pro for $999.99',
          emailId: 'email-123'
        })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.product).toMatchObject({
        productName: 'iPhone 15 Pro',
        price: 999.99,
        merchant: 'Apple'
      });
      expect(res.body.metadata).toHaveProperty('confidence');
      expect(res.body.metadata.emailId).toBe('email-123');
    });

    it('should scrape product page if URL provided', async () => {
      // Mock axios scraping
      axios.get.mockResolvedValueOnce({
        data: `
          <html>
            <head><title>Product Title</title></head>
            <body>
              <h1>Amazing Product</h1>
              <div class="price">$49.99</div>
            </body>
          </html>
        `
      });

      // Mock OpenAI response
      const OpenAI = require('openai');
      const mockCreate = OpenAI.mock.results[0].value.chat.completions.create;

      mockCreate.mockResolvedValueOnce({
        choices: [{
          message: {
            content: JSON.stringify({
              productName: 'Amazing Product',
              price: 49.99,
              merchant: 'Example Store',
              productUrl: 'https://example.com/product',
              originalPrice: null,
              productImage: null,
              sku: null,
              category: 'General',
              expiresAt: null,
              description: 'Amazing product description',
              promoCode: null
            })
          }
        }]
      });

      const res = await request(app)
        .post('/products/resolve')
        .send({
          emailContent: 'Check out this product!',
          productUrl: 'https://example.com/product'
        })
        .expect(200);

      expect(axios.get).toHaveBeenCalledWith(
        'https://example.com/product',
        expect.objectContaining({
          timeout: 5000
        })
      );
      expect(res.body.metadata.scrapedFromWeb).toBe(true);
    });

    it('should handle scraping failure gracefully', async () => {
      // Mock axios failure
      axios.get.mockRejectedValueOnce(new Error('Network error'));

      // Mock OpenAI response
      const OpenAI = require('openai');
      const mockCreate = OpenAI.mock.results[0].value.chat.completions.create;

      mockCreate.mockResolvedValueOnce({
        choices: [{
          message: {
            content: JSON.stringify({
              productName: 'Product from Email',
              price: 29.99,
              merchant: 'Store',
              productUrl: 'https://example.com/product',
              originalPrice: null,
              productImage: null,
              sku: null,
              category: null,
              expiresAt: null,
              description: null,
              promoCode: null
            })
          }
        }]
      });

      const res = await request(app)
        .post('/products/resolve')
        .send({
          emailContent: 'Product info here',
          productUrl: 'https://example.com/product'
        })
        .expect(200);

      // Should still succeed with email data only
      expect(res.body.success).toBe(true);
      expect(res.body.metadata.scrapedFromWeb).toBe(false);
    });

    it('should fail without emailContent', async () => {
      const res = await request(app)
        .post('/products/resolve')
        .send({})
        .expect(400);

      expect(res.body.error).toBe('Bad Request');
      expect(res.body.message).toMatch(/emailContent.*required/i);
    });

    it('should handle OpenAI API errors', async () => {
      // Mock OpenAI failure
      const OpenAI = require('openai');
      const mockCreate = OpenAI.mock.results[0].value.chat.completions.create;
      mockCreate.mockRejectedValueOnce(new Error('OpenAI API error'));

      const res = await request(app)
        .post('/products/resolve')
        .send({
          emailContent: 'Test content'
        })
        .expect(500);

      expect(res.body.error).toBe('Internal Server Error');
    });

    it('should extract product with sale pricing', async () => {
      const OpenAI = require('openai');
      const mockCreate = OpenAI.mock.results[0].value.chat.completions.create;

      mockCreate.mockResolvedValueOnce({
        choices: [{
          message: {
            content: JSON.stringify({
              productName: 'Gaming Laptop',
              price: 799.99,
              originalPrice: 1299.99,
              merchant: 'Best Buy',
              productUrl: 'https://bestbuy.com/laptop',
              productImage: 'https://bestbuy.com/laptop.jpg',
              sku: 'LAPTOP123',
              category: 'Computers',
              expiresAt: '2025-12-31T23:59:59Z',
              description: 'High-performance gaming laptop',
              promoCode: 'SAVE500'
            })
          }
        }]
      });

      const res = await request(app)
        .post('/products/resolve')
        .send({
          emailContent: 'Gaming Laptop on sale! Was $1299.99, now $799.99 with code SAVE500'
        })
        .expect(200);

      expect(res.body.product).toMatchObject({
        price: 799.99,
        originalPrice: 1299.99,
        promoCode: 'SAVE500',
        expiresAt: '2025-12-31T23:59:59Z'
      });
    });
  });

  describe('POST /products/compare', () => {
    it('should compare multiple products', async () => {
      const OpenAI = require('openai');
      const mockCreate = OpenAI.mock.results[0].value.chat.completions.create;

      mockCreate.mockResolvedValueOnce({
        choices: [{
          message: {
            content: JSON.stringify({
              bestDeal: {
                index: 1,
                reason: 'Best value with 30% discount and free shipping'
              },
              recommendations: 'Product 2 offers the best overall value',
              priceComparison: [
                { index: 0, effectivePrice: 99.99, savings: 0, valueScore: 7 },
                { index: 1, effectivePrice: 69.99, savings: 30.00, valueScore: 9 },
                { index: 2, effectivePrice: 89.99, savings: 10.00, valueScore: 8 }
              ],
              warnings: ['Product 2 deal expires in 24 hours']
            })
          }
        }]
      });

      const products = [
        { productName: 'Product A', price: 99.99, merchant: 'Store A' },
        { productName: 'Product B', price: 69.99, originalPrice: 99.99, merchant: 'Store B' },
        { productName: 'Product C', price: 89.99, merchant: 'Store C' }
      ];

      const res = await request(app)
        .post('/products/compare')
        .send({ products })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.comparison.bestDeal.index).toBe(1);
      expect(res.body.comparison.priceComparison).toHaveLength(3);
      expect(res.body.products).toEqual(products);
    });

    it('should fail with less than 2 products', async () => {
      const res = await request(app)
        .post('/products/compare')
        .send({
          products: [{ productName: 'Only One', price: 50 }]
        })
        .expect(400);

      expect(res.body.message).toMatch(/at least 2 products/i);
    });

    it('should fail without products array', async () => {
      const res = await request(app)
        .post('/products/compare')
        .send({})
        .expect(400);

      expect(res.body.message).toMatch(/at least 2 products/i);
    });

    it('should fail with invalid products array', async () => {
      const res = await request(app)
        .post('/products/compare')
        .send({ products: 'not-an-array' })
        .expect(400);

      expect(res.body.message).toMatch(/at least 2 products/i);
    });

    it('should handle OpenAI API errors in comparison', async () => {
      const OpenAI = require('openai');
      const mockCreate = OpenAI.mock.results[0].value.chat.completions.create;
      mockCreate.mockRejectedValueOnce(new Error('OpenAI API error'));

      const res = await request(app)
        .post('/products/compare')
        .send({
          products: [
            { productName: 'Product A', price: 99.99, merchant: 'Store A' },
            { productName: 'Product B', price: 69.99, merchant: 'Store B' }
          ]
        })
        .expect(500);

      expect(res.body.error).toBe('Internal Server Error');
    });
  });

  describe('POST /products/analyze', () => {
    it('should analyze deal quality', async () => {
      const OpenAI = require('openai');
      const mockCreate = OpenAI.mock.results[0].value.chat.completions.create;

      mockCreate.mockResolvedValueOnce({
        choices: [{
          message: {
            content: JSON.stringify({
              dealQuality: 'excellent',
              qualityScore: 9,
              priceAnalysis: 'This is an exceptional deal with 40% off retail price',
              recommendations: {
                shouldBuy: true,
                urgency: 'high',
                reasoning: 'Historic low price with limited stock'
              },
              marketContext: 'Average market price is $129.99, this is significantly below',
              alternativeSuggestions: ['Consider buying multiple', 'Check for bundle deals'],
              warnings: ['Deal expires tonight', 'Limited stock available']
            })
          }
        }]
      });

      const product = {
        productName: 'Wireless Headphones',
        price: 79.99,
        originalPrice: 129.99,
        merchant: 'Amazon',
        expiresAt: '2025-12-01T23:59:59Z',
        promoCode: 'SAVE50'
      };

      const res = await request(app)
        .post('/products/analyze')
        .send({ product })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.analysis).toMatchObject({
        dealQuality: 'excellent',
        qualityScore: 9
      });
      expect(res.body.analysis.recommendations.shouldBuy).toBe(true);
      expect(res.body.product).toEqual(product);
    });

    it('should analyze deal with poor quality', async () => {
      const OpenAI = require('openai');
      const mockCreate = OpenAI.mock.results[0].value.chat.completions.create;

      mockCreate.mockResolvedValueOnce({
        choices: [{
          message: {
            content: JSON.stringify({
              dealQuality: 'poor',
              qualityScore: 3,
              priceAnalysis: 'Price is actually higher than typical retail',
              recommendations: {
                shouldBuy: false,
                urgency: 'low',
                reasoning: 'Better deals available elsewhere'
              },
              marketContext: 'This product regularly sells for less',
              alternativeSuggestions: ['Wait for Black Friday', 'Check competitor prices'],
              warnings: ['Misleading "sale" price', 'Better alternatives exist']
            })
          }
        }]
      });

      const res = await request(app)
        .post('/products/analyze')
        .send({
          product: {
            productName: 'Overpriced Item',
            price: 199.99,
            originalPrice: 199.99,
            merchant: 'Store'
          }
        })
        .expect(200);

      expect(res.body.analysis.dealQuality).toBe('poor');
      expect(res.body.analysis.recommendations.shouldBuy).toBe(false);
    });

    it('should fail without product object', async () => {
      const res = await request(app)
        .post('/products/analyze')
        .send({})
        .expect(400);

      expect(res.body.message).toMatch(/product.*required/i);
    });

    it('should fail without productName', async () => {
      const res = await request(app)
        .post('/products/analyze')
        .send({
          product: { price: 99.99 }
        })
        .expect(400);

      expect(res.body.message).toMatch(/productName.*required/i);
    });

    it('should handle OpenAI API errors in analysis', async () => {
      const OpenAI = require('openai');
      const mockCreate = OpenAI.mock.results[0].value.chat.completions.create;
      mockCreate.mockRejectedValueOnce(new Error('OpenAI API error'));

      const res = await request(app)
        .post('/products/analyze')
        .send({
          product: {
            productName: 'Test Product',
            price: 99.99
          }
        })
        .expect(500);

      expect(res.body.error).toBe('Internal Server Error');
    });
  });

  describe('Confidence Calculation', () => {
    it('should calculate high confidence with all fields', async () => {
      const OpenAI = require('openai');
      const mockCreate = OpenAI.mock.results[0].value.chat.completions.create;

      mockCreate.mockResolvedValueOnce({
        choices: [{
          message: {
            content: JSON.stringify({
              productName: 'Complete Product',
              productUrl: 'https://example.com',
              price: 99.99,
              merchant: 'Store',
              originalPrice: null,
              productImage: null,
              sku: null,
              category: null,
              expiresAt: null,
              description: null,
              promoCode: null
            })
          }
        }]
      });

      const res = await request(app)
        .post('/products/resolve')
        .send({ emailContent: 'Test' })
        .expect(200);

      // All 4 required fields present: productName, price, merchant, productUrl
      expect(res.body.metadata.confidence).toBe(1.0);
    });

    it('should calculate lower confidence with missing fields', async () => {
      const OpenAI = require('openai');
      const mockCreate = OpenAI.mock.results[0].value.chat.completions.create;

      mockCreate.mockResolvedValueOnce({
        choices: [{
          message: {
            content: JSON.stringify({
              productName: 'Product',
              price: 99.99,
              merchant: null, // Missing
              productUrl: null, // Missing
              originalPrice: null,
              productImage: null,
              sku: null,
              category: null,
              expiresAt: null,
              description: null,
              promoCode: null
            })
          }
        }]
      });

      const res = await request(app)
        .post('/products/resolve')
        .send({ emailContent: 'Test' })
        .expect(200);

      // Only 2 of 4 fields present
      expect(res.body.metadata.confidence).toBe(0.5);
    });
  });
});
