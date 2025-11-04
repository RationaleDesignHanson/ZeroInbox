/**
 * Entity Extractor Unit Tests
 * Tests for entity extraction patterns
 *
 * Run with: npm test
 */

const {
  extractAllEntities,
  extractOrderEntities,
  extractTrackingEntities,
  extractPaymentEntities,
  extractMeetingEntities
} = require('../entity-extractor');

describe('Entity Extractor', () => {
  describe('extractTrackingEntities', () => {
    test('should extract UPS tracking number', () => {
      const text = 'Your order has shipped. Tracking: 1Z999AA10123456784. Carrier: UPS.';
      const entities = extractTrackingEntities(text);
      
      expect(entities.trackingNumber).toBe('1Z999AA10123456784');
      expect(entities.carrier).toBe('UPS');
    });

    test('should extract FedEx tracking number', () => {
      const text = 'FedEx tracking number: 123456789012. Estimated delivery: Oct 25.';
      const entities = extractTrackingEntities(text);
      
      expect(entities.trackingNumber).toBe('123456789012');
      expect(entities.carrier).toBe('FedEx');
    });

    test('should handle missing carrier', () => {
      const text = 'Tracking number: ABC123XYZ456';
      const entities = extractTrackingEntities(text);
      
      expect(entities.trackingNumber).toBeDefined();
      expect(entities.carrier).toBeUndefined();
    });
  });

  describe('extractOrderEntities', () => {
    test('should extract order number', () => {
      const text = 'Order #112-7654321-1234567 has been confirmed.';
      const entities = extractOrderEntities(text);
      
      expect(entities.orderNumber).toBe('112-7654321-1234567');
    });

    test('should extract confirmation code', () => {
      const text = 'Confirmation #ABC123 for your purchase.';
      const entities = extractOrderEntities(text);
      
      expect(entities.orderNumber).toBeDefined();
      expect(entities.orderNumber).toContain('ABC123');
    });
  });

  describe('extractPaymentEntities', () => {
    test('should extract invoice ID and amount due', () => {
      const text = 'Invoice #INV-2025-1234 due on Oct 30. Amount due: $599.00.';
      const entities = extractPaymentEntities(text);
      
      expect(entities.invoiceId).toBe('INV-2025-1234');
      expect(entities.amountDue).toBe(599.00);
      expect(entities.dueDate).toContain('Oct 30');
    });

    test('should extract payment amount received', () => {
      const text = 'Payment received: $1,250.50. Thank you for your payment.';
      const entities = extractPaymentEntities(text);
      
      expect(entities.paymentAmount).toBe(1250.50);
    });
  });

  describe('extractMeetingEntities', () => {
    test('should extract Zoom meeting URL', () => {
      const email = {
        subject: 'Meeting invitation',
        body: 'Join us: https://zoom.us/j/123456789'
      };
      const text = email.subject + ' ' + email.body;
      const entities = extractMeetingEntities(email, text);
      
      expect(entities.meetingUrl).toContain('zoom.us');
      expect(entities.meetingUrl).toContain('123456789');
    });

    test('should extract Google Meet URL', () => {
      const email = {
        subject: 'Team meeting',
        body: 'Join: https://meet.google.com/abc-defg-hij'
      };
      const text = email.subject + ' ' + email.body;
      const entities = extractMeetingEntities(email, text);
      
      expect(entities.meetingUrl).toContain('meet.google.com');
    });

    test('should extract event date and time', () => {
      const email = {
        subject: 'Meeting scheduled',
        body: 'Scheduled for Monday, March 18 at 2:00 PM'
      };
      const text = email.subject + ' ' + email.body;
      const entities = extractMeetingEntities(email, text);
      
      expect(entities.eventDate).toContain('March 18');
      expect(entities.eventTime).toContain('2:00');
    });
  });

  describe('extractAllEntities - integration', () => {
    test('should extract all relevant entities from shipping email', () => {
      const email = {
        subject: 'Your Amazon order #123-456 has shipped',
        from: 'Amazon <shipment@amazon.com>',
        body: 'Order #123-456 shipped via UPS. Tracking: 1Z999AA10123456784. Delivery: Oct 25.'
      };
      
      const fullText = email.subject + ' ' + email.body;
      const entities = extractAllEntities(email, fullText, 'e-commerce.shipping.notification');
      
      expect(entities.orderNumber).toBeDefined();
      expect(entities.trackingNumber).toBe('1Z999AA10123456784');
      expect(entities.carrier).toBe('UPS');
      expect(entities.companies).toContain('Amazon');
    });

    test('should handle invalid inputs gracefully', () => {
      const entities1 = extractAllEntities(null, 'text');
      const entities2 = extractAllEntities({}, 123);
      const entities3 = extractAllEntities({}, 'text', {});
      
      expect(entities1).toEqual({});
      expect(entities2).toEqual({});
      expect(entities3).toBeDefined(); // Should log warning but continue
    });
  });
});

// Regex Pattern Tests (Critical!)
describe('Regex Patterns', () => {
  test('UPS tracking number pattern', () => {
    const validUPS = ['1Z999AA10123456784', '1Z123ABC9876543210'];
    const invalidUPS = ['1Z123', 'ABC123', '1Z999AA101234567840000'];
    
    const pattern = /\b(1Z[A-Z0-9]{16})\b/i;
    
    validUPS.forEach(num => {
      expect(pattern.test(num)).toBe(true);
    });
    
    invalidUPS.forEach(num => {
      expect(pattern.test(num)).toBe(false);
    });
  });

  test('Invoice ID pattern', () => {
    const validInvoices = ['INV-2025-1234', 'Invoice #ABC123', 'Bill #XYZ-789'];
    
    validInvoices.forEach(text => {
      const match = text.match(/invoice\s*#?\s*:?\s*([A-Z0-9-]{6,})/i);
      expect(match).toBeTruthy();
    });
  });
});

/* 
 * Test Coverage Goals:
 * - Intent detection: Test all 32 intents
 * - Edge cases: Empty emails, non-English, special characters
 * - Regex patterns: All tracking, invoice, confirmation code patterns
 * - Confidence scoring: Verify weights are correct
 * 
 * Current Coverage: 0% (tests not run)
 * Target Coverage: 70%+
 * 
 * To achieve target:
 * 1. Run: npm test -- --coverage
 * 2. Review coverage report
 * 3. Add tests for uncovered branches
 * 4. Iterate until >70%
 */

