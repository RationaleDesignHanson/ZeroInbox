/**
 * Zero Sequence Engine E2E Tests
 * Tests the complete flow: Email → Intent → Entities → Actions → URL Enforcement
 *
 * This test suite validates the entire zero sequence engine pipeline
 * to ensure backend and iOS work correctly together.
 *
 * Run with: npm test -- zero-sequence-e2e.test.js
 */

const { classifyIntent } = require('../classifier/intent-classifier');
const { extractEntities } = require('../classifier/entity-extractor');
const { suggestActions } = require('../actions/rules-engine');
const { CompoundActionRegistry } = require('../actions/compound-action-registry');

/**
 * Helper: Full classification pipeline
 */
function classifyAndExtract(email) {
  const intentResult = classifyIntent(email);
  const entities = extractEntities(email, intentResult.intent);

  return {
    intent: intentResult.intent,
    intentConfidence: intentResult.confidence,
    entities
  };
}

describe('Zero Sequence Engine E2E Tests', () => {

  // ==========================================
  // SHIPPING NOTIFICATION FLOW
  // ==========================================

  describe('Shipping Notification → Track with Calendar', () => {
    test('Full flow: Email with delivery date → compound action', () => {
      // Given: Shipping email with tracking and delivery date
      const email = {
        subject: 'Your package is arriving tomorrow',
        from: 'shipping-tracking@amazon.com',
        body: 'Your order #112-7654321 will arrive Nov 5. Tracking: 1Z999AA10123456784. Carrier: UPS.'
      };

      // When: Run full classification pipeline
      const { intent, entities } = classifyAndExtract(email);
      const actions = suggestActions(intent, entities, email);

      // Then: Verify zero sequence
      expect(intent).toBe('e-commerce.shipping.notification');
      expect(entities.trackingNumber).toBe('1Z999AA10123456784');
      expect(entities.carrier).toContain('UPS');
      expect(entities.deliveryDate).toBeDefined();

      // Verify compound action detection
      expect(actions[0].actionId).toBe('track_with_calendar');
      expect(actions[0].isPrimary).toBe(true);
      expect(actions[0].isCompound).toBe(true);
      expect(actions[0].compoundSteps).toContain('track_package');
      expect(actions[0].compoundSteps).toContain('add_to_calendar');

      // CRITICAL: Verify URL schema enforcement
      expect(actions[0].context.url).toBeDefined();
      expect(actions[0].context.url).toContain('ups.com');
    });

    test('Shipping without delivery date → regular track action', () => {
      const email = {
        subject: 'Shipped',
        from: 'amazon.com',
        body: 'Tracking: 1Z999AA10123456784. Carrier: UPS.'
      };

      const { intent, entities } = classifyAndExtract(email);
      const actions = suggestActions(intent, entities, email);

      // Should NOT suggest compound action (no delivery date)
      expect(actions[0].actionId).not.toBe('track_with_calendar');
      expect(actions[0].actionId).toBe('track_package');
      expect(actions[0].isCompound).toBeFalsy();
    });
  });

  // ==========================================
  // PERMISSION FORM FLOW
  // ==========================================

  describe('Education Permission Form → Sign & Pay', () => {
    test('Full flow: Permission form with fee → compound action', () => {
      // Given: Education email with form and payment
      const email = {
        subject: 'Field Trip Permission Form Required',
        from: 'teacher@school.edu',
        body: 'Please sign the attached form and submit $45 payment by Wednesday.'
      };

      // When: Run full pipeline
      const { intent, entities } = classifyAndExtract(email);
      const actions = suggestActions(intent, entities, email);

      // Then: Verify zero sequence
      expect(intent).toBe('education.permission.form');
      expect(entities.amount).toBe("45");

      // Verify compound action
      expect(actions[0].actionId).toBe('sign_form_with_payment');
      expect(actions[0].isPrimary).toBe(true);
      expect(actions[0].isCompound).toBe(true);
      expect(actions[0].requiresResponse).toBe(true);

      // Verify email template context
      expect(actions[0].context.emailTemplate).toBeDefined();
      expect(actions[0].context.emailTemplate.subjectPrefix).toContain('Signed & Paid');
    });

    test('Permission form with event date → sign with calendar', () => {
      const email = {
        subject: 'Field Trip Form',
        from: 'teacher@school.edu',
        body: 'Sign form for Nov 15 field trip'
      };

      const { intent, entities } = classifyAndExtract(email);
      const actions = suggestActions(intent, entities, email);

      expect(actions[0].actionId).toBe('sign_form_with_calendar');
      expect(actions[0].compoundSteps).toContain('add_to_calendar');
    });
  });

  // ==========================================
  // INVOICE FLOW
  // ==========================================

  describe('Invoice Due → Pay with Confirmation', () => {
    test('Full flow: Invoice with payment link → compound action', () => {
      const email = {
        subject: 'Invoice #INV-2025-1234 Due',
        from: 'billing@company.com',
        body: 'Invoice INV-2025-1234 due Oct 30. Amount: $599.00. Pay here: https://pay.company.com/INV-2025-1234'
      };

      const { intent, entities } = classifyAndExtract(email);
      const actions = suggestActions(intent, entities, email);

      expect(intent).toBe('billing.invoice.due');
      expect(entities.invoiceId).toBe('INV-2025-1234');
      expect(entities.amount).toBe("599.00");

      // Verify compound action
      expect(actions[0].actionId).toBe('pay_invoice_with_confirmation');
      expect(actions[0].requiresResponse).toBe(true);

      // CRITICAL: Verify URL enforcement
      expect(actions[0].context.url).toBe('https://pay.company.com/INV-2025-1234');
    });
  });

  // ==========================================
  // FLIGHT CHECK-IN FLOW
  // ==========================================

  describe('Flight Check-In → Check-In with Wallet', () => {
    test('Full flow: Flight check-in → compound action', () => {
      const email = {
        subject: 'Check in for flight UA 123',
        from: 'United Airlines <noreply@united.com>',
        body: 'Flight UA 123 departs tomorrow. Check in: https://united.com/checkin/ABC123'
      };

      const { intent, entities } = classifyAndExtract(email);
      const actions = suggestActions(intent, entities, email);

      expect(intent).toBe('travel.flight.check-in');
      expect(entities.flightNumber).toBeDefined();

      expect(actions[0].actionId).toBe('check_in_with_wallet');
      expect(actions[0].isCompound).toBe(true);
      expect(actions[0].requiresResponse).toBe(false); // Personal action

      // Verify URL
      expect(actions[0].context.url).toBe('https://united.com/checkin/ABC123');
    });
  });

  // ==========================================
  // PRIMARY ACTION SELECTION
  // ==========================================

  describe('Primary Action Selection Logic', () => {
    test('First action is always marked as primary', () => {
      const email = {
        subject: 'Your package shipped',
        from: 'amazon.com',
        body: 'Tracking: 1Z999AA. Carrier: UPS.'
      };

      const { intent, entities } = classifyAndExtract(email);
      const actions = suggestActions(intent, entities, email);

      // First action should be primary
      expect(actions[0].isPrimary).toBe(true);

      // Other actions should not be primary
      if (actions.length > 1) {
        expect(actions[1].isPrimary).toBe(false);
      }
    });

    test('Compound action becomes primary when detected', () => {
      const email = {
        subject: 'Package arriving Nov 5',
        from: 'amazon.com',
        body: 'Tracking: 1Z999AA. Delivery: Nov 5. Carrier: UPS.'
      };

      const { intent, entities } = classifyAndExtract(email);
      const actions = suggestActions(intent, entities, email);

      // Compound action should be first and primary
      const primaryAction = actions.find(a => a.isPrimary);
      expect(primaryAction.isCompound).toBe(true);
      expect(primaryAction.actionId).toBe('track_with_calendar');
    });
  });

  // ==========================================
  // URL SCHEMA ENFORCEMENT
  // ==========================================

  describe('URL Schema Enforcement (Critical for iOS)', () => {
    test('GO_TO actions always have generic "url" key', () => {
      const email = {
        subject: 'Track your package',
        from: 'shipping@ups.com',
        body: 'Tracking: 1Z999AA. Carrier: UPS.'
      };

      const { intent, entities } = classifyAndExtract(email);
      const actions = suggestActions(intent, entities, email);

      // Find GO_TO action
      const goToAction = actions.find(a => a.actionType === 'GO_TO');

      if (goToAction) {
        // CRITICAL: Must have "url" key for iOS
        expect(goToAction.context.url).toBeDefined();
        expect(typeof goToAction.context.url).toBe('string');
        expect(goToAction.context.url.length).toBeGreaterThan(0);
      }
    });

    test('Semantic URL keys are copied to generic "url"', () => {
      const actions = suggestActions('e-commerce.shipping.notification', {
        trackingNumber: '1Z999AA',
        carrier: 'UPS',
        trackingUrl: 'https://ups.com/track?num=1Z999AA'
      });

      // Backend should copy trackingUrl → url
      expect(actions[0].context.url).toBe('https://ups.com/track?num=1Z999AA');
      expect(actions[0].context.trackingUrl).toBe('https://ups.com/track?num=1Z999AA');
    });

    test('Invoice paymentLink → url', () => {
      const actions = suggestActions('billing.invoice.due', {
        invoiceId: 'INV-123',
        amount: 500,
        merchant: 'Acme Corp',
        paymentLink: 'https://pay.acme.com/INV-123'
      });

      expect(actions[0].context.url).toBe('https://pay.acme.com/INV-123');
    });

    test('Check-in checkInUrl → url', () => {
      const actions = suggestActions('travel.flight.check-in', {
        flightNumber: 'UA 123',
        checkInUrl: 'https://united.com/checkin'
      });

      expect(actions[0].context.url).toBe('https://united.com/checkin');
    });
  });

  // ==========================================
  // FALLBACK & ERROR HANDLING
  // ==========================================

  describe('Fallback & Error Handling', () => {
    test('Unknown intent returns default actions', () => {
      const email = {
        subject: 'Random subject',
        from: 'test@example.com',
        body: 'No clear intent here'
      };

      const { intent } = classifyAndExtract(email);
      const actions = suggestActions(intent, {}, email);

      // Should return default actions
      expect(actions.length).toBeGreaterThan(0);
      expect(actions[0].actionId).toBe('view_details');
    });

    test('Missing entities returns fallback actions', () => {
      const actions = suggestActions('e-commerce.shipping.notification', {
        // Missing trackingNumber and carrier
      });

      // Should still return actions
      expect(actions.length).toBeGreaterThan(0);
    });

    test('Invalid intent handled gracefully', () => {
      const actions1 = suggestActions(null, {});
      const actions2 = suggestActions(undefined, {});
      const actions3 = suggestActions('', {});

      expect(actions1.length).toBeGreaterThan(0);
      expect(actions2.length).toBeGreaterThan(0);
      expect(actions3.length).toBeGreaterThan(0);
    });
  });

  // ==========================================
  // PERFORMANCE BENCHMARKS
  // ==========================================

  describe('Performance Benchmarks', () => {
    test('Full zero sequence completes in < 100ms', () => {
      const email = {
        subject: 'Package shipped',
        from: 'amazon.com',
        body: 'Tracking: 1Z999AA. Carrier: UPS. Delivery: Nov 5.'
      };

      const startTime = Date.now();

      const { intent, entities } = classifyAndExtract(email);
      const actions = suggestActions(intent, entities, email);

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(duration).toBeLessThan(100); // Must be fast!
      expect(actions.length).toBeGreaterThan(0);
    });
  });
});

/**
 * Test execution instructions:
 *
 * 1. Run all E2E tests:
 *    npm test -- zero-sequence-e2e.test.js
 *
 * 2. Run with coverage:
 *    npm test -- --coverage zero-sequence-e2e.test.js
 *
 * 3. Run in watch mode:
 *    npm test -- --watch zero-sequence-e2e.test.js
 *
 * Expected coverage:
 * - intent-classifier.js: >70%
 * - entity-extractor.js: >60%
 * - rules-engine.js: >80%
 */
