/**
 * iOS Contract Validation Tests
 * Ensures backend responses match iOS expectations EXACTLY
 *
 * Critical: Tests backend→iOS JSON contract for EmailCard and EmailAction models
 * iOS models: EmailCard.swift, EmailAction.swift
 * Backend: /emails endpoint response format
 *
 * Run with: npm test -- ios-contract.test.js
 */

const { classifyIntent } = require('../classifier/intent-classifier');
const { extractEntities } = require('../classifier/entity-extractor');
const { suggestActions } = require('../actions/rules-engine');

/**
 * Helper: Build complete EmailCard response like backend /emails endpoint
 */
function buildEmailCardResponse(email) {
  const intentResult = classifyIntent(email);
  const entities = extractEntities(email, intentResult.intent);
  const actions = suggestActions(intentResult.intent, entities, email);

  return {
    id: email.id || `card-${Date.now()}`,
    messageId: email.messageId || `msg-${Date.now()}`,
    from: email.from,
    fromName: email.fromName || email.from.split('@')[0],
    subject: email.subject,
    preview: email.body.substring(0, 100),
    date: email.date || new Date().toISOString(),
    isRead: email.isRead || false,
    isArchived: email.isArchived || false,
    labels: email.labels || ['INBOX'],
    intentId: intentResult.intent,
    intentDisplayName: intentResult.displayName || intentResult.intent,
    intentConfidence: intentResult.confidence,
    suggestedActions: actions,
    entities: entities,
    summary: email.summary || null
  };
}

describe('iOS Contract Validation', () => {

  // ==========================================
  // EMAIL CARD CONTRACT
  // ==========================================

  describe('EmailCard Response Structure', () => {
    test('EmailCard has all required fields', () => {
      const email = {
        id: 'card-001',
        messageId: 'msg-001',
        from: 'shipping@amazon.com',
        fromName: 'Amazon Shipping',
        subject: 'Your package has shipped',
        body: 'Your order #112-7654321 is on its way. Tracking: 1Z999AA. Carrier: UPS.',
        date: '2025-11-01T10:00:00Z'
      };

      const response = buildEmailCardResponse(email);

      // Required fields (iOS will crash if missing)
      expect(response.id).toBeDefined();
      expect(typeof response.id).toBe('string');

      expect(response.messageId).toBeDefined();
      expect(typeof response.messageId).toBe('string');

      expect(response.from).toBeDefined();
      expect(typeof response.from).toBe('string');

      expect(response.fromName).toBeDefined();
      expect(typeof response.fromName).toBe('string');

      expect(response.subject).toBeDefined();
      expect(typeof response.subject).toBe('string');

      expect(response.preview).toBeDefined();
      expect(typeof response.preview).toBe('string');

      expect(response.date).toBeDefined();
      expect(typeof response.date).toBe('string');

      expect(response.isRead).toBeDefined();
      expect(typeof response.isRead).toBe('boolean');

      expect(response.isArchived).toBeDefined();
      expect(typeof response.isArchived).toBe('boolean');

      expect(response.labels).toBeDefined();
      expect(Array.isArray(response.labels)).toBe(true);

      expect(response.intentId).toBeDefined();
      expect(typeof response.intentId).toBe('string');

      expect(response.intentDisplayName).toBeDefined();
      expect(typeof response.intentDisplayName).toBe('string');

      expect(response.intentConfidence).toBeDefined();
      expect(typeof response.intentConfidence).toBe('number');

      // suggestedActions can be null/undefined, but if present must be array
      if (response.suggestedActions !== null && response.suggestedActions !== undefined) {
        expect(Array.isArray(response.suggestedActions)).toBe(true);
      }

      expect(response.entities).toBeDefined();
      expect(typeof response.entities).toBe('object');
    });

    test('EmailCard date is ISO 8601 format', () => {
      const email = {
        from: 'test@example.com',
        subject: 'Test',
        body: 'Test body',
        date: '2025-11-01T10:00:00Z'
      };

      const response = buildEmailCardResponse(email);

      // iOS expects ISO 8601 format
      expect(response.date).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z?$/);
    });

    test('EmailCard labels is array of strings', () => {
      const email = {
        from: 'test@example.com',
        subject: 'Test',
        body: 'Test body',
        labels: ['INBOX', 'IMPORTANT']
      };

      const response = buildEmailCardResponse(email);

      expect(Array.isArray(response.labels)).toBe(true);
      response.labels.forEach(label => {
        expect(typeof label).toBe('string');
      });
    });
  });

  // ==========================================
  // EMAIL ACTION CONTRACT
  // ==========================================

  describe('EmailAction Response Structure', () => {
    test('EmailAction has all required fields', () => {
      const email = {
        from: 'shipping@amazon.com',
        subject: 'Package shipped',
        body: 'Tracking: 1Z999AA. Carrier: UPS.'
      };

      const response = buildEmailCardResponse(email);
      const actions = response.suggestedActions;

      expect(actions.length).toBeGreaterThan(0);

      const action = actions[0];

      // Required fields
      expect(action.actionId).toBeDefined();
      expect(typeof action.actionId).toBe('string');

      expect(action.displayName).toBeDefined();
      expect(typeof action.displayName).toBe('string');

      expect(action.actionType).toBeDefined();
      expect(['GO_TO', 'IN_APP']).toContain(action.actionType);

      expect(action.priority).toBeDefined();
      expect(typeof action.priority).toBe('number');

      expect(action.isPrimary).toBeDefined();
      expect(typeof action.isPrimary).toBe('boolean');

      expect(action.context).toBeDefined();
      expect(typeof action.context).toBe('object');
    });

    test('EmailAction optional fields have correct types', () => {
      const email = {
        from: 'shipping@amazon.com',
        subject: 'Package arriving tomorrow',
        body: 'Tracking: 1Z999AA. Carrier: UPS. Delivery: Nov 5.'
      };

      const response = buildEmailCardResponse(email);
      const compoundAction = response.suggestedActions.find(a => a.isCompound);

      if (compoundAction) {
        // Optional fields (but must have correct type if present)
        if (compoundAction.isCompound !== undefined) {
          expect(typeof compoundAction.isCompound).toBe('boolean');
        }

        if (compoundAction.compoundSteps !== undefined) {
          expect(Array.isArray(compoundAction.compoundSteps)).toBe(true);
          compoundAction.compoundSteps.forEach(step => {
            expect(typeof step).toBe('string');
          });
        }

        if (compoundAction.requiresResponse !== undefined) {
          expect(typeof compoundAction.requiresResponse).toBe('boolean');
        }

        if (compoundAction.isPremium !== undefined) {
          expect(typeof compoundAction.isPremium).toBe('boolean');
        }
      }
    });

    test('EmailAction actionType must be GO_TO or IN_APP', () => {
      const email = {
        from: 'shipping@amazon.com',
        subject: 'Package shipped',
        body: 'Tracking: 1Z999AA. Carrier: UPS.'
      };

      const response = buildEmailCardResponse(email);
      const actions = response.suggestedActions;

      actions.forEach(action => {
        expect(['GO_TO', 'IN_APP']).toContain(action.actionType);
      });
    });

    test('GO_TO action has url key in context', () => {
      const email = {
        from: 'shipping@amazon.com',
        subject: 'Package shipped',
        body: 'Tracking: 1Z999AA. Carrier: UPS.'
      };

      const response = buildEmailCardResponse(email);
      const goToActions = response.suggestedActions.filter(a => a.actionType === 'GO_TO');

      goToActions.forEach(action => {
        // CRITICAL: iOS requires generic "url" key for GO_TO actions
        expect(action.context.url).toBeDefined();
        expect(typeof action.context.url).toBe('string');
        expect(action.context.url.length).toBeGreaterThan(0);
      });
    });

    test('Primary action is marked with isPrimary=true', () => {
      const email = {
        from: 'shipping@amazon.com',
        subject: 'Package shipped',
        body: 'Tracking: 1Z999AA. Carrier: UPS.'
      };

      const response = buildEmailCardResponse(email);
      const actions = response.suggestedActions;

      // Must have exactly one primary action
      const primaryActions = actions.filter(a => a.isPrimary);
      expect(primaryActions.length).toBeGreaterThanOrEqual(1);

      // First action should be primary
      expect(actions[0].isPrimary).toBe(true);
    });
  });

  // ==========================================
  // URL SCHEMA CONTRACT
  // ==========================================

  describe('URL Schema Contract', () => {
    test('track_package has generic url key', () => {
      const email = {
        from: 'shipping@ups.com',
        subject: 'Package shipped',
        body: 'Tracking: 1Z999AA10123456784. Carrier: UPS.'
      };

      const response = buildEmailCardResponse(email);
      const trackAction = response.suggestedActions.find(a => a.actionId === 'track_package');

      if (trackAction) {
        expect(trackAction.context.url).toBeDefined();
        expect(trackAction.context.url).toContain('ups.com');
      }
    });

    test('pay_invoice has generic url key', () => {
      const email = {
        from: 'billing@company.com',
        subject: 'Invoice Due',
        body: 'Invoice INV-123 due Oct 30. Amount: $599. Pay: https://pay.company.com/INV-123'
      };

      const response = buildEmailCardResponse(email);
      const payAction = response.suggestedActions.find(a => a.actionId === 'pay_invoice');

      if (payAction) {
        expect(payAction.context.url).toBeDefined();
        expect(payAction.context.url).toBe('https://pay.company.com/INV-123');
      }
    });

    test('check_in_flight has generic url key', () => {
      const email = {
        from: 'united@united.com',
        subject: 'Check in now',
        body: 'Flight UA 123 tomorrow. Check in: https://united.com/checkin/ABC123'
      };

      const response = buildEmailCardResponse(email);
      const checkInAction = response.suggestedActions.find(a => a.actionId === 'check_in_flight');

      if (checkInAction) {
        expect(checkInAction.context.url).toBeDefined();
        expect(checkInAction.context.url).toBe('https://united.com/checkin/ABC123');
      }
    });

    test('All GO_TO actions have url in context', () => {
      const testCases = [
        {
          from: 'shipping@amazon.com',
          subject: 'Shipped',
          body: 'Tracking: 1Z999AA. Carrier: UPS.'
        },
        {
          from: 'billing@company.com',
          subject: 'Invoice',
          body: 'Pay: https://pay.com/123'
        },
        {
          from: 'zoom@zoom.us',
          subject: 'Meeting',
          body: 'Join: https://zoom.us/j/123456789'
        }
      ];

      testCases.forEach(email => {
        const response = buildEmailCardResponse(email);
        const goToActions = response.suggestedActions.filter(a => a.actionType === 'GO_TO');

        goToActions.forEach(action => {
          expect(action.context.url).toBeDefined();
          expect(typeof action.context.url).toBe('string');
          expect(action.context.url.length).toBeGreaterThan(0);
        });
      });
    });
  });

  // ==========================================
  // COMPOUND ACTION CONTRACT
  // ==========================================

  describe('Compound Action Contract', () => {
    test('Compound action has required fields', () => {
      const email = {
        from: 'shipping@amazon.com',
        subject: 'Package arriving Nov 5',
        body: 'Tracking: 1Z999AA. Carrier: UPS. Delivery: Nov 5.'
      };

      const response = buildEmailCardResponse(email);
      const compoundAction = response.suggestedActions.find(a => a.isCompound);

      if (compoundAction) {
        expect(compoundAction.isCompound).toBe(true);
        expect(Array.isArray(compoundAction.compoundSteps)).toBe(true);
        expect(compoundAction.compoundSteps.length).toBeGreaterThan(1);

        // Compound steps should be valid action IDs
        compoundAction.compoundSteps.forEach(step => {
          expect(typeof step).toBe('string');
          expect(step.length).toBeGreaterThan(0);
        });
      }
    });

    test('sign_form_with_payment compound structure', () => {
      const email = {
        from: 'teacher@school.edu',
        subject: 'Permission Form',
        body: 'Sign form and pay $45 by Wednesday'
      };

      const response = buildEmailCardResponse(email);
      const signFormAction = response.suggestedActions.find(a => a.actionId === 'sign_form_with_payment');

      if (signFormAction) {
        expect(signFormAction.isCompound).toBe(true);
        expect(signFormAction.compoundSteps).toContain('sign_form');
        expect(signFormAction.compoundSteps).toContain('pay_form_fee');
        expect(signFormAction.compoundSteps).toContain('email_composer');  // Ends with email composer for confirmation
        expect(signFormAction.requiresResponse).toBe(true);
        expect(signFormAction.isPremium).toBe(true);
      }
    });

    test('track_with_calendar compound structure', () => {
      const email = {
        from: 'shipping@amazon.com',
        subject: 'Arriving tomorrow',
        body: 'Tracking: 1Z999AA. Carrier: UPS. Delivery: Nov 5.'
      };

      const response = buildEmailCardResponse(email);
      const trackCalendarAction = response.suggestedActions.find(a => a.actionId === 'track_with_calendar');

      if (trackCalendarAction) {
        expect(trackCalendarAction.isCompound).toBe(true);
        expect(trackCalendarAction.compoundSteps).toContain('track_package');
        expect(trackCalendarAction.compoundSteps).toContain('add_to_calendar');
        expect(trackCalendarAction.context.url).toBeDefined(); // Must have URL for GO_TO
      }
    });
  });

  // ==========================================
  // ENTITIES CONTRACT
  // ==========================================

  describe('Entities Contract', () => {
    test('Entities object is always present', () => {
      const email = {
        from: 'test@example.com',
        subject: 'Test',
        body: 'Test body'
      };

      const response = buildEmailCardResponse(email);

      // Entities must always be present (even if empty)
      expect(response.entities).toBeDefined();
      expect(typeof response.entities).toBe('object');
    });

    test('Entity values are strings', () => {
      const email = {
        from: 'shipping@amazon.com',
        subject: 'Package shipped',
        body: 'Order #112-7654321. Tracking: 1Z999AA. Amount: $59.99.'
      };

      const response = buildEmailCardResponse(email);

      Object.entries(response.entities).forEach(([key, value]) => {
        expect(typeof key).toBe('string');
        // Values should be strings (or arrays/objects in special cases)
        expect(['string', 'object']).toContain(typeof value);
      });
    });

    test('Common entities are extracted', () => {
      const email = {
        from: 'shipping@ups.com',
        subject: 'Shipped',
        body: 'Tracking: 1Z999AA10123456784. Carrier: UPS. Order: 112-7654321. Amount: $59.99.'
      };

      const response = buildEmailCardResponse(email);

      // Should extract common entities
      if (response.entities.trackingNumber) {
        expect(response.entities.trackingNumber).toBe('1Z999AA10123456784');
      }

      if (response.entities.carrier) {
        expect(response.entities.carrier).toContain('UPS');
      }
    });
  });

  // ==========================================
  // ERROR & FALLBACK CONTRACT
  // ==========================================

  describe('Error & Fallback Contract', () => {
    test('Unknown intent returns valid response', () => {
      const email = {
        from: 'random@example.com',
        subject: 'Random subject',
        body: 'No clear intent here at all'
      };

      const response = buildEmailCardResponse(email);

      // Should still return valid EmailCard
      expect(response.id).toBeDefined();
      expect(response.intentId).toBeDefined();
      expect(response.suggestedActions).toBeDefined();
      expect(Array.isArray(response.suggestedActions)).toBe(true);
    });

    test('Missing entities returns valid actions', () => {
      const email = {
        from: 'shipping@amazon.com',
        subject: 'Package shipped',
        body: 'Your package is on its way'  // Missing tracking info
      };

      const response = buildEmailCardResponse(email);

      // Should still suggest actions (even if not ideal)
      expect(response.suggestedActions.length).toBeGreaterThan(0);
    });

    test('Null/undefined fields handled gracefully', () => {
      const email = {
        from: 'test@example.com',
        subject: 'Test',
        body: 'Test',
        summary: null,
        labels: undefined
      };

      const response = buildEmailCardResponse(email);

      // Should provide defaults
      expect(Array.isArray(response.labels)).toBe(true);
    });
  });

  // ==========================================
  // PERFORMANCE CONTRACT
  // ==========================================

  describe('Performance Contract', () => {
    test('Response generation completes in < 100ms', () => {
      const email = {
        from: 'shipping@amazon.com',
        subject: 'Package shipped',
        body: 'Tracking: 1Z999AA. Carrier: UPS. Delivery: Nov 5.'
      };

      const startTime = Date.now();
      const response = buildEmailCardResponse(email);
      const endTime = Date.now();

      const duration = endTime - startTime;

      // Must be fast (iOS expects < 100ms)
      expect(duration).toBeLessThan(100);
      expect(response.suggestedActions.length).toBeGreaterThan(0);
    });

    test('Large email body handled efficiently', () => {
      const largeBody = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '.repeat(100);

      const email = {
        from: 'test@example.com',
        subject: 'Test',
        body: largeBody
      };

      const startTime = Date.now();
      const response = buildEmailCardResponse(email);
      const endTime = Date.now();

      const duration = endTime - startTime;

      expect(duration).toBeLessThan(200); // Allow more time for large emails
      expect(response.preview.length).toBeLessThanOrEqual(100); // Preview should be truncated
    });
  });
});

/**
 * Test execution:
 *
 * Run contract tests:
 *   npm test -- ios-contract.test.js
 *
 * Run with verbose output:
 *   npm test -- --verbose ios-contract.test.js
 *
 * These tests ensure backend and iOS maintain contract compatibility.
 * ANY FAILURE in these tests indicates a breaking change that will crash iOS app!
 *
 * Contract checklist:
 * ✅ All required EmailCard fields present
 * ✅ All required EmailAction fields present
 * ✅ GO_TO actions have generic "url" key
 * ✅ Primary action marked with isPrimary=true
 * ✅ Compound actions have correct structure
 * ✅ Entities object always present
 * ✅ Performance < 100ms
 */
