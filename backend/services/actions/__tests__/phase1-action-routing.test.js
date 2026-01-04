/**
 * Phase 1 Task 1.2: Action Routing Validation Test Suite
 * Tests all 138 actions for correct routing and priority
 */

const { suggestActions } = require('../rules-engine');
const { ActionCatalog, getAllActionIds, getActionsForIntent } = require('../action-catalog');
const { IntentTaxonomy } = require('../../../shared/models/Intent');
const fs = require('fs');
const path = require('path');

describe('Phase 1: Action Routing Validation', () => {
  const allActions = getAllActionIds();
  const results = {
    total: allActions.length,
    tested: 0,
    passed: 0,
    failed: 0,
    byType: {
      GO_TO: { total: 0, passed: 0, failed: 0 },
      IN_APP: { total: 0, passed: 0, failed: 0 }
    },
    failedActions: []
  };

  describe(`All ${allActions.length} Actions - Basic Validation`, () => {
    allActions.forEach(actionId => {
      const action = ActionCatalog[actionId];

      test(`${actionId} (${action.actionType}): Has valid structure`, () => {
        results.tested++;
        results.byType[action.actionType].total++;

        try {
          // Validate action structure
          expect(action.actionId).toBe(actionId);
          expect(action.displayName).toBeDefined();
          expect(['GO_TO', 'IN_APP']).toContain(action.actionType);
          expect(action.description).toBeDefined();
          expect(Array.isArray(action.requiredEntities)).toBe(true);
          expect(Array.isArray(action.validIntents)).toBe(true);
          expect(typeof action.priority).toBe('number');
          expect(action.priority).toBeGreaterThan(0);

          // GO_TO actions should have urlTemplate (unless generic)
          if (action.actionType === 'GO_TO' && action.validIntents.length > 0) {
            expect(action.urlTemplate).toBeDefined();
          }

          results.passed++;
          results.byType[action.actionType].passed++;
        } catch (error) {
          results.failed++;
          results.byType[action.actionType].failed++;
          results.failedActions.push({
            actionId,
            error: error.message
          });
          throw error;
        }
      });
    });
  });

  describe('Action Routing for Intents', () => {
    const testIntents = [
      'e-commerce.shipping.notification',
      'healthcare.appointment.reminder',
      'billing.invoice.due',
      'travel.flight.check-in',
      'education.permission.form',
      'marketing.promotion.flash-sale'
    ];

    testIntents.forEach(intentId => {
      test(`${intentId}: Returns appropriate actions`, () => {
        const actions = getActionsForIntent(intentId);

        expect(Array.isArray(actions)).toBe(true);
        expect(actions.length).toBeGreaterThan(0);

        // All actions should have valid structure
        actions.forEach(action => {
          expect(action.actionId).toBeDefined();
          expect(['GO_TO', 'IN_APP']).toContain(action.actionType);
        });

        // Actions should be sorted by priority
        for (let i = 1; i < actions.length; i++) {
          expect(actions[i].priority).toBeGreaterThanOrEqual(actions[i-1].priority);
        }
      });
    });
  });

  describe('Generic Actions (Always Available)', () => {
    const genericActions = ['quick_reply', 'save_for_later', 'view_details', 'open_link'];

    genericActions.forEach(actionId => {
      test(`${actionId}: Available for all intents`, () => {
        const action = ActionCatalog[actionId];

        expect(action).toBeDefined();
        expect(action.validIntents).toEqual([]);
      });
    });
  });

  describe('Priority System', () => {
    test('Priority 1 actions are highest priority', () => {
      const priority1Actions = Object.values(ActionCatalog).filter(a => a.priority === 1);

      expect(priority1Actions.length).toBeGreaterThan(0);

      // Priority 1 actions should be specific (not generic)
      priority1Actions.forEach(action => {
        expect(action.validIntents.length).toBeGreaterThan(0);
      });
    });

    test('Generic actions have lower priority', () => {
      const genericActions = Object.values(ActionCatalog).filter(a => a.validIntents.length === 0);

      genericActions.forEach(action => {
        expect(action.priority).toBeGreaterThanOrEqual(3);
      });
    });
  });

  describe('Action Type Distribution', () => {
    test('Should have both GO_TO and IN_APP actions', () => {
      const goToActions = Object.values(ActionCatalog).filter(a => a.actionType === 'GO_TO');
      const inAppActions = Object.values(ActionCatalog).filter(a => a.actionType === 'IN_APP');

      expect(goToActions.length).toBeGreaterThan(50);
      expect(inAppActions.length).toBeGreaterThan(20);
    });
  });

  describe('Rules Engine Integration', () => {
    test('suggestActions returns valid suggestions', () => {
      const testEmail = {
        subject: 'Your order has shipped',
        from: 'shipment@amazon.com',
        body: 'Tracking: 1Z999AA',
        intent: 'e-commerce.shipping.notification',
        entities: {
          trackingNumber: '1Z999AA',
          carrier: 'UPS'
        }
      };

      const suggestions = suggestActions(testEmail);

      expect(Array.isArray(suggestions)).toBe(true);
      expect(suggestions.length).toBeGreaterThan(0);

      suggestions.forEach(suggestion => {
        expect(suggestion.actionId).toBeDefined();
        expect(suggestion.displayName).toBeDefined();
        expect(suggestion.actionType).toBeDefined();
        expect(suggestion.priority).toBeDefined();
      });
    });
  });

  afterAll(() => {
    // Generate summary report
    console.log('\n' + '='.repeat(60));
    console.log('PHASE 1 TASK 1.2: ACTION ROUTING RESULTS');
    console.log('='.repeat(60));
    console.log(`Total Actions: ${results.total}`);
    console.log(`Tested: ${results.tested}`);
    console.log(`Passed: ${results.passed} (${(results.passed/results.tested*100).toFixed(1)}%)`);
    console.log(`Failed: ${results.failed} (${(results.failed/results.tested*100).toFixed(1)}%)`);

    console.log('\nBy Type:');
    Object.entries(results.byType).forEach(([type, stats]) => {
      const passRate = (stats.passed / stats.total * 100).toFixed(0);
      console.log(`  ${type}: ${stats.passed}/${stats.total} (${passRate}%)`);
    });

    if (results.failedActions.length > 0) {
      console.log('\nFailed Actions:');
      results.failedActions.slice(0, 10).forEach(failure => {
        console.log(`  ${failure.actionId}: ${failure.error}`);
      });
    }

    console.log('='.repeat(60) + '\n');

    // Save results to file
    const resultsPath = path.join(__dirname, '../../../test-data/phase1-action-results.json');
    fs.writeFileSync(resultsPath, JSON.stringify(results, null, 2));
    console.log(`Results saved to: ${resultsPath}\n`);
  });
});
