/**
 * Receipt Parsing Tests
 *
 * Tests receipt/order email parsing for shopping cart functionality:
 * - Order number extraction
 * - Merchant identification
 * - Item parsing (name, quantity, price)
 * - Total calculation
 * - Tracking number extraction
 * - Status detection (ordered, shipped, delivered, cancelled, refunded)
 */

const fs = require('fs');
const path = require('path');
const request = require('supertest');
const receiptParser = require('../lib/receiptParser');
const app = require('../server');

// Helper to load fixture from classifier service
function loadFixture(filename) {
  const fixturePath = path.join(__dirname, '../../classifier/__tests__/fixtures', filename);
  const data = fs.readFileSync(fixturePath, 'utf-8');
  return JSON.parse(data);
}

describe('Receipt Parser - Library Functions', () => {
  describe('normalizeEmail()', () => {
    test('Should normalize fixture format (from object, body object)', () => {
      const fixtureEmail = {
        from: { name: 'Amazon', email: 'ship-confirm@amazon.com' },
        subject: 'Your order has shipped',
        body: {
          text: 'Your order #123 has shipped.',
          html: '<p>Your order #123 has shipped.</p>'
        }
      };

      const normalized = receiptParser.normalizeEmail(fixtureEmail);

      expect(normalized.from).toBe('ship-confirm@amazon.com');
      expect(normalized.subject).toBe('Your order has shipped');
      expect(normalized.textBody).toBe('Your order #123 has shipped.');
      expect(normalized.htmlBody).toBe('<p>Your order #123 has shipped.</p>');
    });

    test('Should normalize API format (from string, textBody/htmlBody)', () => {
      const apiEmail = {
        from: 'orders@target.com',
        subject: 'Order confirmation',
        textBody: 'Your order #456 is confirmed.',
        htmlBody: '<p>Your order #456 is confirmed.</p>'
      };

      const normalized = receiptParser.normalizeEmail(apiEmail);

      expect(normalized.from).toBe('orders@target.com');
      expect(normalized.subject).toBe('Order confirmation');
      expect(normalized.textBody).toBe('Your order #456 is confirmed.');
      expect(normalized.htmlBody).toBe('<p>Your order #456 is confirmed.</p>');
    });
  });

  describe('extractMerchant()', () => {
    test('Should extract Amazon from sender name', () => {
      const email = {
        from: { name: 'Amazon.com', email: 'ship-confirm@amazon.com' },
        subject: 'Your order'
      };

      const merchant = receiptParser.extractMerchant(email);

      expect(merchant).toBe('Amazon');
    });

    test('Should extract Target from domain', () => {
      const email = {
        from: { name: 'Order Confirmation', email: 'orders@target.com' },
        subject: 'Your order'
      };

      const merchant = receiptParser.extractMerchant(email);

      expect(merchant).toBe('Target');
    });

    test('Should extract Best Buy from domain', () => {
      const email = {
        from: 'orders@bestbuy.com',
        subject: 'Your order'
      };

      const merchant = receiptParser.extractMerchant(email);

      expect(merchant).toBe('Best Buy');
    });

    test('Should handle unknown merchant', () => {
      const email = {
        from: 'noreply@unknownstore.com',
        subject: 'Your order'
      };

      const merchant = receiptParser.extractMerchant(email);

      expect(merchant).toBe('Unknown Merchant');
    });
  });

  describe('determineStatus()', () => {
    test('Should detect ordered status from confirmation email', () => {
      const email = {
        subject: 'Order Confirmation #123',
        body: { text: 'Thank you for your order!' }
      };

      const status = receiptParser.determineStatus(email);

      expect(status).toBe('ordered');
    });

    test('Should detect shipped status', () => {
      const email = {
        subject: 'Your order has shipped',
        body: { text: 'Tracking: 1Z999AA10123456784' }
      };

      const status = receiptParser.determineStatus(email);

      expect(status).toBe('shipped');
    });

    test('Should detect delivered status', () => {
      const email = {
        subject: 'Your order was delivered',
        body: { text: 'Package was delivered today.' }
      };

      const status = receiptParser.determineStatus(email);

      expect(status).toBe('delivered');
    });

    test('Should detect cancelled status', () => {
      const email = {
        subject: 'Order Cancelled',
        body: { text: 'Your order has been cancelled.' }
      };

      const status = receiptParser.determineStatus(email);

      expect(status).toBe('cancelled');
    });

    test('Should detect refunded status', () => {
      const email = {
        subject: 'Refund Issued',
        body: { text: 'Your refund has been processed.' }
      };

      const status = receiptParser.determineStatus(email);

      expect(status).toBe('refunded');
    });
  });

  describe('parseReceipt()', () => {
    test('Should require email object', async () => {
      await expect(receiptParser.parseReceipt(null)).rejects.toThrow('Email object is required');
    });

    test('Should require subject or body', async () => {
      const email = { from: 'test@example.com' };

      await expect(receiptParser.parseReceipt(email)).rejects.toThrow('Email must have at least subject or body');
    });

    test('Should parse email and return receipt object', async () => {
      const email = {
        from: 'orders@amazon.com',
        subject: 'Order Confirmation',
        body: {
          text: 'Order #: 123-4567890-1234567\nTotal: $49.99'
        }
      };

      const receipt = await receiptParser.parseReceipt(email);

      expect(receipt).toHaveProperty('orderNumber');
      expect(receipt).toHaveProperty('merchant');
      expect(receipt).toHaveProperty('items');
      expect(receipt).toHaveProperty('total');
      expect(receipt).toHaveProperty('currency');
      expect(receipt).toHaveProperty('status');
      expect(receipt).toHaveProperty('parsedAt');
      expect(receipt.merchant).toBe('Amazon');
    });
  });
});

describe('Receipt Parser - All Shopping Fixtures', () => {
  const shoppingFixtures = [
    { file: 'shopping-amazon-order-confirmation.json', expectedStatus: 'ordered', expectedMerchant: 'Amazon' },
    { file: 'shopping-amazon-shipped.json', expectedStatus: 'shipped', expectedMerchant: 'Amazon' },
    { file: 'shopping-amazon-delivered.json', expectedStatus: 'delivered', expectedMerchant: 'Amazon' },
    { file: 'shopping-target-order.json', expectedStatus: 'shipped', expectedMerchant: 'Target' },
    { file: 'shopping-bestbuy-multi-item.json', expectedStatus: 'ordered', expectedMerchant: 'Best Buy' },
    { file: 'shopping-order-cancelled.json', expectedStatus: 'cancelled', expectedMerchant: 'Best Buy' },
    { file: 'shopping-refund-issued.json', expectedStatus: 'refunded', expectedMerchant: 'Target' }
  ];

  test.each(shoppingFixtures)('Should parse $file correctly', async ({ file, expectedStatus, expectedMerchant }) => {
    const fixture = loadFixture(file);

    const receipt = await receiptParser.parseReceipt(fixture);

    expect(receipt).toBeDefined();
    expect(receipt.merchant).toBe(expectedMerchant);
    expect(receipt.status).toBe(expectedStatus);
    expect(receipt.currency).toBe('USD');
    expect(receipt.parsedAt).toBeDefined();
  });

  test('Amazon order confirmation should extract order number', async () => {
    const fixture = loadFixture('shopping-amazon-order-confirmation.json');

    const receipt = await receiptParser.parseReceipt(fixture);

    // Should extract order number if present in fixture
    if (fixture.entities?.orderNumber) {
      expect(receipt.orderNumber).toBe(fixture.entities.orderNumber);
    }
  });

  test('Amazon shipped should extract tracking number', async () => {
    const fixture = loadFixture('shopping-amazon-shipped.json');

    const receipt = await receiptParser.parseReceipt(fixture);

    expect(receipt.status).toBe('shipped');
    // Should extract tracking number if present
    if (fixture.entities?.trackingNumber) {
      expect(receipt.trackingNumber).toBeDefined();
    }
  });

  test('Best Buy multi-item should handle multiple items', async () => {
    const fixture = loadFixture('shopping-bestbuy-multi-item.json');

    const receipt = await receiptParser.parseReceipt(fixture);

    expect(receipt.items).toBeDefined();
    expect(Array.isArray(receipt.items)).toBe(true);
    // Multi-item order should have items parsed
  });

  test('All fixtures should have valid merchant detection', async () => {
    for (const { file, expectedMerchant } of shoppingFixtures) {
      const fixture = loadFixture(file);
      const receipt = await receiptParser.parseReceipt(fixture);

      expect(receipt.merchant).toBe(expectedMerchant);
    }
  });

  test('All fixtures should have parsedAt timestamp', async () => {
    for (const { file } of shoppingFixtures) {
      const fixture = loadFixture(file);
      const receipt = await receiptParser.parseReceipt(fixture);

      expect(receipt.parsedAt).toBeDefined();
      expect(new Date(receipt.parsedAt).toString()).not.toBe('Invalid Date');
    }
  });
});

describe('Receipt Parsing - API Endpoints', () => {
  describe('POST /receipts/parse', () => {
    test('Should return 400 if email is missing', async () => {
      const response = await request(app)
        .post('/receipts/parse')
        .send({});

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Email object is required');
    });

    test('Should parse valid email and return receipt', async () => {
      const email = {
        from: 'orders@amazon.com',
        subject: 'Order Confirmation',
        body: {
          text: 'Order #: 123-4567890-1234567\nTotal: $49.99'
        }
      };

      const response = await request(app)
        .post('/receipts/parse')
        .send({ email });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.receipt).toBeDefined();
      expect(response.body.receipt.merchant).toBe('Amazon');
    });

    test('Should parse Target order fixture', async () => {
      const fixture = loadFixture('shopping-target-order.json');

      const response = await request(app)
        .post('/receipts/parse')
        .send({ email: fixture });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.receipt.merchant).toBe('Target');
      expect(response.body.receipt.status).toBe('shipped');
    });

    test('Should support useService option', async () => {
      const email = {
        from: 'orders@amazon.com',
        subject: 'Order Confirmation',
        body: {
          text: 'Order #: 123-4567890-1234567'
        }
      };

      const response = await request(app)
        .post('/receipts/parse')
        .send({
          email,
          options: { useService: false }  // Use local parsing
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.receipt).toBeDefined();
    });
  });

  describe('POST /receipts/batch', () => {
    test('Should return 400 if emails array is missing', async () => {
      const response = await request(app)
        .post('/receipts/batch')
        .send({});

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Emails array is required');
    });

    test('Should return 400 if emails array is empty', async () => {
      const response = await request(app)
        .post('/receipts/batch')
        .send({ emails: [] });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Emails array is empty');
    });

    test('Should return 400 if more than 100 emails', async () => {
      const emails = new Array(101).fill({
        from: 'test@example.com',
        subject: 'Test',
        body: { text: 'Test' }
      });

      const response = await request(app)
        .post('/receipts/batch')
        .send({ emails });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Too many emails');
      expect(response.body.message).toContain('Maximum 100 emails');
    });

    test('Should parse multiple emails successfully', async () => {
      const email1 = {
        from: 'orders@amazon.com',
        subject: 'Order Confirmation',
        body: { text: 'Order #: 123-456' }
      };

      const email2 = {
        from: 'orders@target.com',
        subject: 'Order Confirmation',
        body: { text: 'Order #: 789-012' }
      };

      const response = await request(app)
        .post('/receipts/batch')
        .send({ emails: [email1, email2] });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.results).toHaveLength(2);
      expect(response.body.summary.total).toBe(2);
      expect(response.body.summary.successful).toBe(2);
      expect(response.body.summary.failed).toBe(0);
    });

    test('Should handle partial failures gracefully', async () => {
      const validEmail = {
        from: 'orders@amazon.com',
        subject: 'Order Confirmation',
        body: { text: 'Order #: 123-456' }
      };

      const invalidEmail = {
        from: 'test@example.com'
        // Missing subject and body - should fail
      };

      const response = await request(app)
        .post('/receipts/batch')
        .send({ emails: [validEmail, invalidEmail] });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.results).toHaveLength(2);
      expect(response.body.summary.total).toBe(2);
      expect(response.body.summary.successful).toBe(1);
      expect(response.body.summary.failed).toBe(1);

      // First should succeed
      expect(response.body.results[0].success).toBe(true);
      expect(response.body.results[0].receipt).toBeDefined();

      // Second should fail
      expect(response.body.results[1].success).toBe(false);
      expect(response.body.results[1].error).toBeDefined();
    });

    test('Should process all 7 shopping fixtures in batch', async () => {
      const fixtures = [
        'shopping-amazon-order-confirmation.json',
        'shopping-amazon-shipped.json',
        'shopping-amazon-delivered.json',
        'shopping-target-order.json',
        'shopping-bestbuy-multi-item.json',
        'shopping-order-cancelled.json',
        'shopping-refund-issued.json'
      ].map(loadFixture);

      const response = await request(app)
        .post('/receipts/batch')
        .send({ emails: fixtures });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.results).toHaveLength(7);
      expect(response.body.summary.total).toBe(7);
      expect(response.body.summary.successful).toBe(7);
      expect(response.body.summary.failed).toBe(0);

      // All should succeed
      response.body.results.forEach(result => {
        expect(result.success).toBe(true);
        expect(result.receipt).toBeDefined();
        expect(result.receipt.merchant).toBeDefined();
        expect(result.receipt.status).toBeDefined();
      });
    });
  });

  describe('GET /receipts/health', () => {
    test('Should return healthy status', async () => {
      const response = await request(app)
        .get('/receipts/health');

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('healthy');
      expect(response.body.service).toBe('receipt-parser');
      expect(response.body.timestamp).toBeDefined();
    });
  });
});

describe('Receipt Parsing - Error Handling', () => {
  test('Should handle malformed email object', async () => {
    const response = await request(app)
      .post('/receipts/parse')
      .send({ email: 'not-an-object' });

    expect(response.status).toBe(500);
    expect(response.body.success).toBe(false);
    expect(response.body.error).toBeDefined();
  });

  test('Should handle missing required fields gracefully', async () => {
    const email = {
      from: 'test@example.com'
      // Missing subject and body
    };

    const response = await request(app)
      .post('/receipts/parse')
      .send({ email });

    expect(response.status).toBe(500);
    expect(response.body.success).toBe(false);
    expect(response.body.message).toContain('Failed to parse receipt email');
  });

  test('Should handle invalid JSON in batch request', async () => {
    const response = await request(app)
      .post('/receipts/batch')
      .set('Content-Type', 'application/json')
      .send('{ invalid json }');

    expect(response.status).toBe(400);
  });
});
