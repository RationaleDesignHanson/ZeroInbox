/**
 * Intent Classifier Unit Tests
 * Tests for intent detection accuracy
 *
 * Run with: npm test
 */

const { classifyIntent, calculateIntentScore } = require('../intent-classifier');
const { IntentTaxonomy } = require('../../../shared/models/Intent');

describe('Intent Classifier', () => {
  describe('classifyIntent', () => {
    test('should detect shipping notification intent', () => {
      const email = {
        subject: 'Your Amazon order has shipped',
        from: 'shipment-tracking@amazon.com',
        body: 'Your order #112-7654321 has shipped. Tracking number: 1Z999AA10123456784. Carrier: UPS.'
      };
      
      const result = classifyIntent(email);
      
      expect(result.intent).toBe('e-commerce.shipping.notification');
      expect(result.confidence).toBeGreaterThan(0.7);
      expect(result.source).toBe('pattern_matching');
    });

    test('should detect education permission form intent', () => {
      const email = {
        subject: 'Field Trip Permission Form - Please Sign',
        from: 'teacher@school.edu',
        body: 'Please sign the attached permission form for the field trip. Return by Wednesday.'
      };
      
      const result = classifyIntent(email);
      
      expect(result.intent).toBe('education.permission.form');
      expect(result.confidence).toBeGreaterThan(0.8);
    });

    test('should detect flight check-in intent', () => {
      const email = {
        subject: 'Check in for flight UA 123',
        from: 'United Airlines <noreply@united.com>',
        body: 'Flight UA 123 departs tomorrow. Check in now: https://united.com/checkin/ABC123'
      };
      
      const result = classifyIntent(email);
      
      expect(result.intent).toBe('travel.flight.check-in');
      expect(result.confidence).toBeGreaterThan(0.7);
    });

    test('should detect invoice due intent', () => {
      const email = {
        subject: 'Invoice #INV-2025-1234 Due',
        from: 'billing@company.com',
        body: 'Invoice INV-2025-1234 due Oct 30. Amount: $599.00. Pay: https://pay.com/INV-2025-1234'
      };
      
      const result = classifyIntent(email);
      
      expect(result.intent).toBe('billing.invoice.due');
      expect(result.confidence).toBeGreaterThan(0.75);
    });

    test('should fall back to generic intent for ambiguous emails', () => {
      const email = {
        subject: 'Hello',
        from: 'test@example.com',
        body: 'This is a test email with no clear intent.'
      };
      
      const result = classifyIntent(email);
      
      expect(result.intent).toContain('generic');
      expect(result.confidence).toBeLessThan(0.6);
    });

    test('should handle invalid email object', () => {
      const result1 = classifyIntent(null);
      const result2 = classifyIntent(undefined);
      const result3 = classifyIntent({ subject: '', body: '' });
      
      expect(result1.intent).toBe('generic.transactional');
      expect(result1.source).toBe('validation_error');
      
      expect(result3.intent).toBe('generic.transactional');
      expect(result3.source).toBe('insufficient_content');
    });

    test('should boost confidence when domain matches category', () => {
      const emailWithDomain = {
        subject: 'Your order has shipped',
        from: 'shipment@amazon.com',
        body: 'Tracking number: 1Z999AA10123456784'
      };
      
      const emailWithoutDomain = {
        subject: 'Your order has shipped',
        from: 'sender@example.com',
        body: 'Tracking number: 1Z999AA10123456784'
      };
      
      const result1 = classifyIntent(emailWithDomain);
      const result2 = classifyIntent(emailWithoutDomain);
      
      // Domain match should boost confidence
      expect(result1.confidence).toBeGreaterThan(result2.confidence);
    });
  });

  describe('calculateIntentScore', () => {
    test('should score higher for subject matches than body matches', () => {
      const intent = IntentTaxonomy['e-commerce.shipping.notification'];
      
      const subjectMatch = calculateIntentScore(intent, {
        subject: 'your package has shipped',
        body: '',
        from: '',
        snippet: '',
        fullText: 'your package has shipped'
      });
      
      const bodyMatch = calculateIntentScore(intent, {
        subject: '',
        body: 'your package has shipped',
        from: '',
        snippet: 'your package has shipped',
        fullText: ' your package has shipped'
      });
      
      expect(subjectMatch).toBeGreaterThan(bodyMatch);
    });
  });
});

// Test Data Sets for Edge Cases
const edgeCaseEmails = [
  {
    name: 'HTML-only email',
    email: { subject: 'Newsletter', from: 'news@example.com', htmlBody: '<html>...</html>', body: '' },
    expectedIntent: 'generic.newsletter'
  },
  {
    name: 'Email with special characters',
    email: { subject: '🎉 Sale! 50% off 🎉', from: 'deals@store.com', body: 'Limited time offer' },
    expectedIntent: 'marketing.promotion.flash-sale'
  },
  {
    name: 'Multi-language email',
    email: { subject: 'Votre colis a été expédié', from: 'amazon.fr', body: 'Numéro de suivi: ABC123' },
    expectedIntent: 'e-commerce.shipping.notification' // Should work with French keywords if patterns updated
  }
];

describe('Edge Cases', () => {
  test.each(edgeCaseEmails)('should handle $name', ({ email, expectedIntent }) => {
    const result = classifyIntent(email);
    expect(result.intent).toContain(expectedIntent.split('.')[0]); // At least get category right
  });
});

/* 
 * To run these tests:
 * 
 * 1. Install Jest:
 *    cd backend
 *    npm install --save-dev jest
 * 
 * 2. Add test script to package.json:
 *    "scripts": {
 *      "test": "jest",
 *      "test:watch": "jest --watch"
 *    }
 * 
 * 3. Run tests:
 *    npm test
 * 
 * 4. Run with coverage:
 *    npm test -- --coverage
 *
 * Expected coverage targets:
 * - rules-engine.js: >80%
 * - intent-classifier.js: >70%
 * - action-catalog.js: >60%
 */

