/**
 * Phase 1 Task 1.4: Compound Actions Validation Test Suite
 * Tests all 9 compound actions for correct structure, sequencing, and behavior
 */

const { CompoundActionRegistry, END_BEHAVIORS, COMPOUND_ACTIONS } = require('../compound-action-registry');
const { ActionCatalog } = require('../action-catalog');
const fs = require('fs');
const path = require('path');

describe('Phase 1: Compound Actions Validation', () => {
  const results = {
    total: 0,
    passed: 0,
    failed: 0,
    byType: {
      structure: { total: 0, passed: 0, failed: 0 },
      sequencing: { total: 0, passed: 0, failed: 0 },
      endBehavior: { total: 0, passed: 0, failed: 0 },
      detection: { total: 0, passed: 0, failed: 0 }
    },
    failedTests: []
  };

  const allCompoundActions = Object.keys(COMPOUND_ACTIONS);

  describe('Structure Validation - All 9 Compound Actions', () => {
    allCompoundActions.forEach(actionId => {
      const action = COMPOUND_ACTIONS[actionId];

      test(`${actionId}: Has valid structure`, () => {
        results.total++;
        results.byType.structure.total++;

        try {
          // Validate required fields
          expect(action.actionId).toBe(actionId);
          expect(action.displayName).toBeDefined();
          expect(action.steps).toBeDefined();
          expect(Array.isArray(action.steps)).toBe(true);
          expect(action.steps.length).toBeGreaterThan(0);
          expect(action.endBehavior).toBeDefined();
          expect(action.endBehavior.type).toBeDefined();
          expect(typeof action.requiresResponse).toBe('boolean');
          expect(typeof action.isPremium).toBe('boolean');
          expect(action.description).toBeDefined();

          results.passed++;
          results.byType.structure.passed++;
        } catch (error) {
          results.failed++;
          results.byType.structure.failed++;
          results.failedTests.push({ category: 'structure', actionId, error: error.message });
          throw error;
        }
      });
    });
  });

  describe('Step Sequencing Validation', () => {
    const sequencingTests = [
      {
        actionId: 'sign_form_with_payment',
        expectedSteps: ['sign_form', 'pay_form_fee', 'email_composer'],
        description: 'Should have sign, pay, then email steps'
      },
      {
        actionId: 'sign_form_with_calendar',
        expectedSteps: ['sign_form', 'add_to_calendar', 'email_composer'],
        description: 'Should have sign, calendar, then email steps'
      },
      {
        actionId: 'sign_and_send',
        expectedSteps: ['sign_form', 'email_composer'],
        description: 'Should have sign then email steps'
      },
      {
        actionId: 'track_with_calendar',
        expectedSteps: ['track_package', 'add_to_calendar'],
        description: 'Should have track then calendar steps'
      },
      {
        actionId: 'schedule_purchase_with_reminder',
        expectedSteps: ['schedule_purchase', 'add_to_calendar'],
        description: 'Should have schedule then calendar steps'
      },
      {
        actionId: 'pay_invoice_with_confirmation',
        expectedSteps: ['pay_invoice', 'email_composer'],
        description: 'Should have pay then email steps'
      },
      {
        actionId: 'check_in_with_wallet',
        expectedSteps: ['check_in_flight', 'add_to_wallet'],
        description: 'Should have check-in then wallet steps'
      },
      {
        actionId: 'calendar_with_reminder',
        expectedSteps: ['add_to_calendar', 'add_reminder'],
        description: 'Should have calendar then reminder steps'
      },
      {
        actionId: 'cancel_with_confirmation',
        expectedSteps: ['cancel_subscription', 'email_composer'],
        description: 'Should have cancel then email steps'
      }
    ];

    sequencingTests.forEach(({ actionId, expectedSteps, description }) => {
      test(`${actionId}: ${description}`, () => {
        results.total++;
        results.byType.sequencing.total++;

        try {
          const action = COMPOUND_ACTIONS[actionId];
          expect(action.steps).toEqual(expectedSteps);

          results.passed++;
          results.byType.sequencing.passed++;
        } catch (error) {
          results.failed++;
          results.byType.sequencing.failed++;
          results.failedTests.push({ category: 'sequencing', actionId, error: error.message });
          throw error;
        }
      });
    });
  });

  describe('End Behavior Validation', () => {
    const endBehaviorTests = [
      {
        actionId: 'sign_form_with_payment',
        expectedBehavior: END_BEHAVIORS.EMAIL_COMPOSER,
        requiresResponse: true,
        shouldHaveTemplate: true
      },
      {
        actionId: 'sign_form_with_calendar',
        expectedBehavior: END_BEHAVIORS.EMAIL_COMPOSER,
        requiresResponse: true,
        shouldHaveTemplate: true
      },
      {
        actionId: 'sign_and_send',
        expectedBehavior: END_BEHAVIORS.EMAIL_COMPOSER,
        requiresResponse: true,
        shouldHaveTemplate: true
      },
      {
        actionId: 'track_with_calendar',
        expectedBehavior: END_BEHAVIORS.RETURN_TO_APP,
        requiresResponse: false,
        shouldHaveTemplate: false
      },
      {
        actionId: 'schedule_purchase_with_reminder',
        expectedBehavior: END_BEHAVIORS.RETURN_TO_APP,
        requiresResponse: false,
        shouldHaveTemplate: false
      },
      {
        actionId: 'pay_invoice_with_confirmation',
        expectedBehavior: END_BEHAVIORS.EMAIL_COMPOSER,
        requiresResponse: true,
        shouldHaveTemplate: true
      },
      {
        actionId: 'check_in_with_wallet',
        expectedBehavior: END_BEHAVIORS.RETURN_TO_APP,
        requiresResponse: false,
        shouldHaveTemplate: false
      },
      {
        actionId: 'calendar_with_reminder',
        expectedBehavior: END_BEHAVIORS.RETURN_TO_APP,
        requiresResponse: false,
        shouldHaveTemplate: false
      },
      {
        actionId: 'cancel_with_confirmation',
        expectedBehavior: END_BEHAVIORS.EMAIL_COMPOSER,
        requiresResponse: true,
        shouldHaveTemplate: true
      }
    ];

    endBehaviorTests.forEach(({ actionId, expectedBehavior, requiresResponse, shouldHaveTemplate }) => {
      test(`${actionId}: Has correct end behavior`, () => {
        results.total++;
        results.byType.endBehavior.total++;

        try {
          const action = COMPOUND_ACTIONS[actionId];

          // Validate end behavior type
          expect(action.endBehavior.type).toBe(expectedBehavior);

          // Validate requiresResponse matches end behavior
          expect(action.requiresResponse).toBe(requiresResponse);

          // Validate email template presence
          if (shouldHaveTemplate) {
            expect(action.endBehavior.template).toBeDefined();
            expect(action.endBehavior.template.subjectPrefix).toBeDefined();
            expect(action.endBehavior.template.bodyTemplate).toBeDefined();
          } else {
            expect(action.endBehavior.template).toBeUndefined();
          }

          results.passed++;
          results.byType.endBehavior.passed++;
        } catch (error) {
          results.failed++;
          results.byType.endBehavior.failed++;
          results.failedTests.push({ category: 'endBehavior', actionId, error: error.message });
          throw error;
        }
      });
    });
  });

  describe('Compound Action Detection Logic', () => {
    const detectionTests = [
      {
        name: 'Education permission form with payment',
        intent: 'education.permission.form',
        entities: { amount: '25.00' },
        expectedAction: 'sign_form_with_payment'
      },
      {
        name: 'Education permission form with event',
        intent: 'education.permission.form',
        entities: { eventDate: 'November 15' },
        expectedAction: 'sign_form_with_calendar'
      },
      {
        name: 'Basic education permission form',
        intent: 'education.permission.form',
        entities: {},
        expectedAction: 'sign_and_send'
      },
      {
        name: 'Shipping with delivery date',
        intent: 'e-commerce.shipping.notification',
        entities: { deliveryDate: 'November 20' },
        expectedAction: 'track_with_calendar'
      },
      {
        name: 'Invoice with payment info',
        intent: 'billing.invoice.due',
        entities: { amount: '125.50', merchant: 'Acme Corp' },
        expectedAction: 'pay_invoice_with_confirmation'
      },
      {
        name: 'Flight check-in',
        intent: 'travel.flight.check-in',
        entities: { flightNumber: 'UA 123' },
        expectedAction: 'check_in_with_wallet'
      }
    ];

    detectionTests.forEach(({ name, intent, entities, expectedAction }) => {
      test(name, () => {
        results.total++;
        results.byType.detection.total++;

        try {
          const detectedAction = CompoundActionRegistry.detectCompoundAction(intent, entities);
          expect(detectedAction).toBe(expectedAction);

          results.passed++;
          results.byType.detection.passed++;
        } catch (error) {
          results.failed++;
          results.byType.detection.failed++;
          results.failedTests.push({ category: 'detection', name, error: error.message });
          throw error;
        }
      });
    });
  });

  describe('Premium vs Free Classification', () => {
    test('Premium compound actions are correctly flagged', () => {
      results.total++;

      try {
        const premiumActions = CompoundActionRegistry.getPremiumCompoundActions();
        const expectedPremiumContains = [
          'sign_form_with_payment',
          'sign_form_with_calendar',
          'track_with_calendar',
          'schedule_purchase_with_reminder',
          'pay_invoice_with_confirmation',
          'check_in_with_wallet'
        ];

        const premiumIds = premiumActions.map(a => a.actionId);
        // Check that all expected premium actions are present (may have more)
        expectedPremiumContains.forEach(id => {
          expect(premiumIds).toContain(id);
        });
        expect(premiumIds.length).toBeGreaterThanOrEqual(expectedPremiumContains.length);

        results.passed++;
      } catch (error) {
        results.failed++;
        results.failedTests.push({ category: 'premium', name: 'Premium actions', error: error.message });
        throw error;
      }
    });

    test('Free compound actions are correctly flagged', () => {
      results.total++;

      try {
        const freeActions = CompoundActionRegistry.getFreeCompoundActions();
        const expectedFree = [
          'sign_and_send',
          'calendar_with_reminder',
          'cancel_with_confirmation'
        ];

        const freeIds = freeActions.map(a => a.actionId).sort();
        expect(freeIds).toEqual(expectedFree.sort());

        results.passed++;
      } catch (error) {
        results.failed++;
        results.failedTests.push({ category: 'premium', name: 'Free actions', error: error.message });
        throw error;
      }
    });
  });

  describe('Registry Statistics', () => {
    test('Compound action count is correct', () => {
      results.total++;

      try {
        const stats = CompoundActionRegistry.getCompoundActionCount();

        expect(stats.total).toBeGreaterThanOrEqual(9);
        expect(stats.premium).toBeGreaterThanOrEqual(6);
        expect(stats.free).toBeGreaterThanOrEqual(3);
        expect(stats.requiresResponse).toBeGreaterThanOrEqual(5);
        expect(stats.premium + stats.free).toBe(stats.total);

        results.passed++;
      } catch (error) {
        results.failed++;
        results.failedTests.push({ category: 'statistics', name: 'Action count', error: error.message });
        throw error;
      }
    });

    test('All compound action IDs are retrievable', () => {
      results.total++;

      try {
        const allIds = CompoundActionRegistry.getAllCompoundActionIds();

        expect(allIds.length).toBeGreaterThanOrEqual(9);
        expect(allIds).toContain('sign_form_with_payment');
        expect(allIds).toContain('cancel_with_confirmation');

        results.passed++;
      } catch (error) {
        results.failed++;
        results.failedTests.push({ category: 'statistics', name: 'All action IDs', error: error.message });
        throw error;
      }
    });
  });

  afterAll(() => {
    // Generate summary report
    console.log('\n' + '='.repeat(60));
    console.log('PHASE 1 TASK 1.4: COMPOUND ACTIONS RESULTS');
    console.log('='.repeat(60));
    console.log(`Total Tests: ${results.total}`);
    console.log(`Passed: ${results.passed} (${(results.passed/results.total*100).toFixed(1)}%)`);
    console.log(`Failed: ${results.failed} (${(results.failed/results.total*100).toFixed(1)}%)`);

    console.log('\nBy Type:');
    Object.entries(results.byType).forEach(([type, stats]) => {
      const passRate = stats.total > 0 ? (stats.passed / stats.total * 100).toFixed(0) : 0;
      console.log(`  ${type}: ${stats.passed}/${stats.total} (${passRate}%)`);
    });

    if (results.failedTests.length > 0) {
      console.log('\nFailed Tests:');
      results.failedTests.slice(0, 10).forEach(failure => {
        console.log(`  ${failure.category}.${failure.actionId || failure.name}: ${failure.error}`);
      });
    }

    console.log('='.repeat(60) + '\n');

    // Save results to file
    const resultsPath = path.join(__dirname, '../../../test-data/phase1-compound-results.json');
    fs.writeFileSync(resultsPath, JSON.stringify(results, null, 2));
    console.log(`Results saved to: ${resultsPath}\n`);
  });
});
