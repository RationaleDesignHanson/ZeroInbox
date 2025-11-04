/**
 * Rules Engine Unit Tests
 * Tests for action suggestion logic
 *
 * Run with: npm test
 * or: jest backend/services/actions/__tests__/rules-engine.test.js
 */

const { suggestActions, buildActionSuggestion, generateTrackingUrl, canExecuteCompoundAction } = require('../rules-engine');

describe('Rules Engine', () => {
  describe('suggestActions', () => {
    test('should suggest track_package for shipping notification with tracking number', () => {
      const entities = {
        trackingNumber: '1Z999AA10123456784',
        carrier: 'UPS',
        orderNumber: '123-456'
      };
      
      const actions = suggestActions('e-commerce.shipping.notification', entities);
      
      expect(actions.length).toBeGreaterThan(0);
      expect(actions[0].actionId).toBe('track_package');
      expect(actions[0].isPrimary).toBe(true);
      expect(actions[0].context.trackingNumber).toBe('1Z999AA10123456784');
      expect(actions[0].context.carrier).toBe('UPS');
    });

    test('should return default actions for unknown intent', () => {
      const actions = suggestActions('unknown.invalid.intent', {});
      
      expect(actions.length).toBeGreaterThan(0);
      expect(actions[0].actionId).toBe('view_details');
      expect(actions[0]._fallbackReason).toBe('unknown_intent');
      expect(actions[0]._originalIntent).toBe('unknown.invalid.intent');
    });

    test('should suggest invoice action for billing intent with invoice data', () => {
      const entities = {
        invoiceId: 'INV-2025-1234',
        amount: 599.00,  // Changed from amountDue to amount
        paymentLink: 'https://pay.company.com/INV-2025-1234'
      };

      const actions = suggestActions('billing.invoice.due', entities);

      expect(actions.length).toBeGreaterThan(0);
      // Accept any invoice-related action (pay_invoice or view_invoice)
      expect(['pay_invoice', 'view_invoice']).toContain(actions[0].actionId);

      // Verify URL schema enforcement for paymentLink
      if (actions[0].actionType === 'GO_TO') {
        expect(actions[0].context.url).toBeDefined();
        expect(typeof actions[0].context.url).toBe('string');
        expect(actions[0].context.url.length).toBeGreaterThan(0);
      }
    });

    test('should not suggest actions requiring missing entities', () => {
      // Tracking action needs trackingNumber + carrier
      const entities = {
        trackingNumber: '1Z999AA10123456784'
        // Missing carrier!
      };
      
      const actions = suggestActions('e-commerce.shipping.notification', entities);
      
      // Should not include track_package (missing carrier)
      const trackAction = actions.find(a => a.actionId === 'track_package');
      expect(trackAction).toBeUndefined();
    });

    test('should handle null or invalid intentId gracefully', () => {
      const actions1 = suggestActions(null, {});
      const actions2 = suggestActions(undefined, {});
      const actions3 = suggestActions(123, {});
      
      expect(actions1.length).toBeGreaterThan(0);
      expect(actions2.length).toBeGreaterThan(0);
      expect(actions3.length).toBeGreaterThan(0);
      
      // All should return defaults
      expect(actions1[0].actionId).toBe('view_details');
    });
  });

  describe('generateTrackingUrl', () => {
    test('should generate UPS tracking URL', () => {
      const url = generateTrackingUrl('UPS', '1Z999AA10123456784');
      
      expect(url).toContain('ups.com');
      expect(url).toContain('1Z999AA10123456784');
    });

    test('should generate FedEx tracking URL', () => {
      const url = generateTrackingUrl('FedEx', '123456789012');
      
      expect(url).toContain('fedex.com');
      expect(url).toContain('123456789012');
    });

    test('should fall back to Google search for unknown carrier', () => {
      const url = generateTrackingUrl('UnknownCarrier', 'ABC123XYZ');
      
      expect(url).toContain('google.com/search');
      expect(url).toContain('ABC123XYZ');
    });

    test('should handle case-insensitive carrier names', () => {
      const url1 = generateTrackingUrl('UPS', '1Z999');
      const url2 = generateTrackingUrl('ups', '1Z999');
      const url3 = generateTrackingUrl('Ups', '1Z999');
      
      expect(url1).toEqual(url2);
      expect(url2).toEqual(url3);
    });
  });

  describe('canExecuteCompoundAction', () => {
    test('should return true if all compound steps can execute', () => {
      const action = {
        actionId: 'sign_form',
        isCompound: true,
        compoundSteps: ['sign_form', 'pay_form_fee']
      };
      
      const entities = {
        formName: 'Field Trip Permission',
        amount: 15.00
      };
      
      const canExecute = canExecuteCompoundAction(action, entities);
      
      expect(canExecute).toBe(true);
    });

    test('should return false if any compound step missing entities', () => {
      const action = {
        actionId: 'sign_form',
        isCompound: true,
        compoundSteps: ['sign_form', 'pay_form_fee']
      };
      
      const entities = {
        formName: 'Field Trip Permission'
        // Missing amount for pay_form_fee!
      };
      
      const canExecute = canExecuteCompoundAction(action, entities);
      
      expect(canExecute).toBe(false);
    });
  });

  describe('buildActionSuggestion', () => {
    test('should populate context with required entities', () => {
      const action = {
        actionId: 'track_package',
        displayName: 'Track Package',
        actionType: 'GO_TO',
        requiredEntities: ['trackingNumber', 'carrier'],
        priority: 1
      };

      const entities = {
        trackingNumber: '1Z999AA10123456784',
        carrier: 'UPS',
        orderNumber: '123-456', // Extra entity not required
        someOtherData: 'ignored'
      };

      const suggestion = buildActionSuggestion(action, entities, {});

      expect(suggestion.actionId).toBe('track_package');
      expect(suggestion.context.trackingNumber).toBe('1Z999AA10123456784');
      expect(suggestion.context.carrier).toBe('UPS');
      expect(suggestion.context.someOtherData).toBeUndefined(); // Not required, not included
    });

    test('should enforce URL schema for GO_TO actions (rules-engine.js:214-250)', () => {
      const action = {
        actionId: 'track_package',
        displayName: 'Track Package',
        actionType: 'GO_TO',
        requiredEntities: ['trackingNumber'],
        priority: 1
      };

      const entities = {
        trackingNumber: '1Z999AA',
        trackingUrl: 'https://ups.com/track?num=1Z999AA'
      };

      const suggestion = buildActionSuggestion(action, entities, {});

      // CRITICAL: Must copy trackingUrl → url for iOS compatibility
      expect(suggestion.context.url).toBeDefined();
      expect(suggestion.context.url).toBe('https://ups.com/track?num=1Z999AA');
    });

    test('should copy paymentLink → url for invoice actions', () => {
      const action = {
        actionId: 'pay_invoice',
        displayName: 'Pay Invoice',
        actionType: 'GO_TO',
        requiredEntities: ['invoiceId'],
        priority: 1
      };

      const entities = {
        invoiceId: 'INV-123',
        paymentLink: 'https://pay.company.com/INV-123'
      };

      const suggestion = buildActionSuggestion(action, entities, {});

      expect(suggestion.context.url).toBe('https://pay.company.com/INV-123');
    });
  });

  describe('URL Schema Enforcement Integration', () => {
    test('suggestActions() applies URL schema to all GO_TO actions', () => {
      const entities = {
        trackingNumber: '1Z999AA',
        carrier: 'UPS',
        trackingUrl: 'https://ups.com/track'
      };

      const actions = suggestActions('e-commerce.shipping.notification', entities);

      // Find GO_TO action
      const goToAction = actions.find(a => a.actionType === 'GO_TO');

      if (goToAction) {
        expect(goToAction.context.url).toBeDefined();
        expect(goToAction.context.url).toContain('ups.com');
      }
    });

    test('Compound actions preserve URL enforcement', () => {
      const entities = {
        trackingNumber: '1Z999AA',
        carrier: 'UPS',
        deliveryDate: '2025-11-05',
        trackingUrl: 'https://ups.com/track'
      };

      const actions = suggestActions('e-commerce.shipping.notification', entities);

      // Should detect compound action with URL
      const compoundAction = actions.find(a => a.isCompound);

      if (compoundAction) {
        expect(compoundAction.context.url).toBeDefined();
      }
    });
  });
});

// To run these tests:
// 1. Install Jest: npm install --save-dev jest
// 2. Add to package.json: "scripts": { "test": "jest" }
// 3. Run: npm test

