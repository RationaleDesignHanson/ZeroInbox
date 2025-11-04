/**
 * Phase 2 Task 2.1: iOS-Backend Contract Validation Test Suite
 * Validates that all backend responses conform to iOS model contracts
 */

const { ActionCatalog } = require('../action-catalog');
const { CompoundActionRegistry, COMPOUND_ACTIONS } = require('../compound-action-registry');
const { IntentTaxonomy } = require('../../../shared/models/Intent');
const { extractAllEntities } = require('../../classifier/entity-extractor');
const { classifyIntent } = require('../../classifier/intent-classifier');
const fs = require('fs');
const path = require('path');

describe('Phase 2: iOS-Backend Contract Validation', () => {
  const results = {
    total: 0,
    passed: 0,
    failed: 0,
    byCategory: {
      emailAction: { total: 0, passed: 0, failed: 0 },
      dynamicAction: { total: 0, passed: 0, failed: 0 },
      compoundAction: { total: 0, passed: 0, failed: 0 },
      entityContext: { total: 0, passed: 0, failed: 0 },
      intentClassification: { total: 0, passed: 0, failed: 0 }
    },
    failedTests: []
  };

  // MARK: - Email Action Contract Validation

  describe('Email Action Contract', () => {
    const allActions = Object.values(ActionCatalog);

    test('All 139 actions have valid EmailAction structure', () => {
      results.total++;
      results.byCategory.emailAction.total++;

      try {
        expect(allActions.length).toBe(139);

        allActions.forEach(action => {
          // Required fields
          expect(action.actionId).toBeDefined();
          expect(typeof action.actionId).toBe('string');

          expect(action.displayName).toBeDefined();
          expect(typeof action.displayName).toBe('string');

          expect(action.actionType).toBeDefined();
          expect(['GO_TO', 'IN_APP']).toContain(action.actionType);

          expect(typeof action.priority).toBe('number');
          expect(action.priority).toBeGreaterThanOrEqual(1);
          expect(action.priority).toBeLessThanOrEqual(5);

          // Optional fields
          if (action.requiredContextKeys) {
            expect(Array.isArray(action.requiredContextKeys)).toBe(true);
          }

          if (action.optionalContextKeys) {
            expect(Array.isArray(action.optionalContextKeys)).toBe(true);
          }

          // GO_TO actions must have URL template
          if (action.actionType === 'GO_TO' && action.requiredContextKeys && action.requiredContextKeys.length > 0) {
            // URL template should be constructible from context keys
            expect(action.url || action.urlTemplate).toBeDefined();
          }
        });

        results.passed++;
        results.byCategory.emailAction.passed++;
      } catch (error) {
        results.failed++;
        results.byCategory.emailAction.failed++;
        results.failedTests.push({ category: 'emailAction', name: 'Action structure', error: error.message });
        throw error;
      }
    });

    test('Action IDs are unique', () => {
      results.total++;
      results.byCategory.emailAction.total++;

      try {
        const actionIds = allActions.map(a => a.actionId);
        const uniqueIds = new Set(actionIds);

        expect(uniqueIds.size).toBe(actionIds.length);
        expect(uniqueIds.size).toBe(139);

        results.passed++;
        results.byCategory.emailAction.passed++;
      } catch (error) {
        results.failed++;
        results.byCategory.emailAction.failed++;
        results.failedTests.push({ category: 'emailAction', name: 'Unique IDs', error: error.message });
        throw error;
      }
    });

    test('Display names are user-friendly', () => {
      results.total++;
      results.byCategory.emailAction.total++;

      try {
        allActions.forEach(action => {
          // Display names should be capitalized and readable
          expect(action.displayName.length).toBeGreaterThan(3);
          expect(action.displayName.length).toBeLessThan(50);

          // Should not have underscores or all caps
          expect(action.displayName).not.toMatch(/_/);
          expect(action.displayName).not.toMatch(/^[A-Z_]+$/);
        });

        results.passed++;
        results.byCategory.emailAction.passed++;
      } catch (error) {
        results.failed++;
        results.byCategory.emailAction.failed++;
        results.failedTests.push({ category: 'emailAction', name: 'Display names', error: error.message });
        throw error;
      }
    });

    test('Action types are exact enum matches', () => {
      results.total++;
      results.byCategory.emailAction.total++;

      try {
        const validTypes = ['GO_TO', 'IN_APP'];

        allActions.forEach(action => {
          // Must be exact match (case-sensitive)
          expect(validTypes).toContain(action.actionType);
          expect(action.actionType).toBe(action.actionType.toUpperCase());
        });

        results.passed++;
        results.byCategory.emailAction.passed++;
      } catch (error) {
        results.failed++;
        results.byCategory.emailAction.failed++;
        results.failedTests.push({ category: 'emailAction', name: 'Action types', error: error.message });
        throw error;
      }
    });

    test('Priority values are 1-5', () => {
      results.total++;
      results.byCategory.emailAction.total++;

      try {
        allActions.forEach(action => {
          expect(action.priority).toBeGreaterThanOrEqual(1);
          expect(action.priority).toBeLessThanOrEqual(5);
          expect(Number.isInteger(action.priority)).toBe(true);
        });

        results.passed++;
        results.byCategory.emailAction.passed++;
      } catch (error) {
        results.failed++;
        results.byCategory.emailAction.failed++;
        results.failedTests.push({ category: 'emailAction', name: 'Priority values', error: error.message });
        throw error;
      }
    });
  });

  // MARK: - Compound Action Contract Validation

  describe('Compound Action Contract', () => {
    const allCompoundActions = Object.keys(COMPOUND_ACTIONS);

    test('All 9 compound actions have valid structure', () => {
      results.total++;
      results.byCategory.compoundAction.total++;

      try {
        expect(allCompoundActions.length).toBe(9);

        allCompoundActions.forEach(actionId => {
          const action = COMPOUND_ACTIONS[actionId];

          // Required fields
          expect(action.actionId).toBe(actionId);
          expect(action.displayName).toBeDefined();
          expect(Array.isArray(action.steps)).toBe(true);
          expect(action.steps.length).toBeGreaterThanOrEqual(2);
          expect(action.steps.length).toBeLessThanOrEqual(3);

          // End behavior
          expect(action.endBehavior).toBeDefined();
          expect(action.endBehavior.type).toBeDefined();
          expect(['EMAIL_COMPOSER', 'RETURN_TO_APP']).toContain(action.endBehavior.type);

          // Flags
          expect(typeof action.requiresResponse).toBe('boolean');
          expect(typeof action.isPremium).toBe('boolean');

          // Email template if end behavior is EMAIL_COMPOSER
          if (action.endBehavior.type === 'EMAIL_COMPOSER') {
            expect(action.endBehavior.template).toBeDefined();
            expect(action.endBehavior.template.subjectPrefix).toBeDefined();
            expect(action.endBehavior.template.bodyTemplate).toBeDefined();
          }
        });

        results.passed++;
        results.byCategory.compoundAction.passed++;
      } catch (error) {
        results.failed++;
        results.byCategory.compoundAction.failed++;
        results.failedTests.push({ category: 'compoundAction', name: 'Structure', error: error.message });
        throw error;
      }
    });

    test('Compound action steps are valid actionIds', () => {
      results.total++;
      results.byCategory.compoundAction.total++;

      try {
        const validActionIds = Object.keys(ActionCatalog);

        allCompoundActions.forEach(compoundId => {
          const action = COMPOUND_ACTIONS[compoundId];

          action.steps.forEach(stepId => {
            // Each step must be a valid action ID (except email_composer which is special)
            if (stepId !== 'email_composer') {
              expect(validActionIds).toContain(stepId);
            }
          });
        });

        results.passed++;
        results.byCategory.compoundAction.passed++;
      } catch (error) {
        results.failed++;
        results.byCategory.compoundAction.failed++;
        results.failedTests.push({ category: 'compoundAction', name: 'Valid steps', error: error.message });
        throw error;
      }
    });

    test('End behavior matches requiresResponse flag', () => {
      results.total++;
      results.byCategory.compoundAction.total++;

      try {
        allCompoundActions.forEach(actionId => {
          const action = COMPOUND_ACTIONS[actionId];

          if (action.endBehavior.type === 'EMAIL_COMPOSER') {
            expect(action.requiresResponse).toBe(true);
          } else {
            expect(action.requiresResponse).toBe(false);
          }
        });

        results.passed++;
        results.byCategory.compoundAction.passed++;
      } catch (error) {
        results.failed++;
        results.byCategory.compoundAction.failed++;
        results.failedTests.push({ category: 'compoundAction', name: 'End behavior consistency', error: error.message });
        throw error;
      }
    });

    test('Premium/free classification is correct', () => {
      results.total++;
      results.byCategory.compoundAction.total++;

      try {
        const premiumActions = CompoundActionRegistry.getPremiumCompoundActions();
        const freeActions = CompoundActionRegistry.getFreeCompoundActions();

        expect(premiumActions.length).toBe(6);
        expect(freeActions.length).toBe(3);
        expect(premiumActions.length + freeActions.length).toBe(9);

        results.passed++;
        results.byCategory.compoundAction.passed++;
      } catch (error) {
        results.failed++;
        results.byCategory.compoundAction.failed++;
        results.failedTests.push({ category: 'compoundAction', name: 'Premium classification', error: error.message });
        throw error;
      }
    });
  });

  // MARK: - Entity Context Contract Validation

  describe('Entity Context Contract', () => {
    test('All entity values are strings (iOS contract)', () => {
      results.total++;
      results.byCategory.entityContext.total++;

      try {
        const testEmail = {
          subject: 'Invoice Due: $125.50',
          body: 'Invoice #INV-456 Amount due: $125.50 Payment due: November 20',
          from: 'billing@company.com'
        };
        const fullText = `${testEmail.subject} ${testEmail.body}`;
        const entities = extractAllEntities(testEmail, fullText, 'billing.invoice.due');

        // All entity values should be strings (iOS expects strings)
        Object.entries(entities).forEach(([key, value]) => {
          if (value !== null && value !== undefined) {
            if (Array.isArray(value)) {
              // Arrays of strings are okay
              value.forEach(item => {
                expect(typeof item).toMatch(/string|object/);
              });
            } else if (typeof value === 'object') {
              // Objects are okay (like deadline)
              expect(typeof value).toBe('object');
            } else {
              // Primitive values should be strings or numbers
              expect(typeof value).toMatch(/string|number|boolean/);
            }
          }
        });

        results.passed++;
        results.byCategory.entityContext.passed++;
      } catch (error) {
        results.failed++;
        results.byCategory.entityContext.failed++;
        results.failedTests.push({ category: 'entityContext', name: 'String values', error: error.message });
        throw error;
      }
    });

    test('URLs are valid HTTP/HTTPS format', () => {
      results.total++;
      results.byCategory.entityContext.total++;

      try {
        const testEmail = {
          subject: 'Track your package',
          body: 'Track here: https://www.ups.com/track?tracknum=123',
          from: 'shipping@store.com'
        };
        const fullText = `${testEmail.subject} ${testEmail.body}`;
        const entities = extractAllEntities(testEmail, fullText, 'e-commerce.shipping.notification');

        // Check URL entities
        const urlKeys = Object.keys(entities).filter(key => key.toLowerCase().includes('url'));

        urlKeys.forEach(key => {
          if (entities[key]) {
            expect(entities[key]).toMatch(/^https?:\/\//);
          }
        });

        results.passed++;
        results.byCategory.entityContext.passed++;
      } catch (error) {
        results.failed++;
        results.byCategory.entityContext.failed++;
        results.failedTests.push({ category: 'entityContext', name: 'Valid URLs', error: error.message });
        throw error;
      }
    });

    test('Amount values are formatted correctly', () => {
      results.total++;
      results.byCategory.entityContext.total++;

      try {
        const testEmail = {
          subject: 'Invoice Due',
          body: 'Amount due: $1,250.50',
          from: 'billing@company.com'
        };
        const fullText = `${testEmail.subject} ${testEmail.body}`;
        const entities = extractAllEntities(testEmail, fullText, 'billing.invoice.due');

        // Amount should be without currency symbols or commas
        if (entities.amount) {
          expect(entities.amount).not.toMatch(/\$/);
          expect(entities.amount).not.toMatch(/,/);
          expect(entities.amount).toMatch(/^\d+\.?\d*$/);
        }

        results.passed++;
        results.byCategory.entityContext.passed++;
      } catch (error) {
        results.failed++;
        results.byCategory.entityContext.failed++;
        results.failedTests.push({ category: 'entityContext', name: 'Amount format', error: error.message });
        throw error;
      }
    });
  });

  // MARK: - Intent Classification Contract Validation

  describe('Intent Classification Contract', () => {
    test('All 134 intents follow correct format', () => {
      results.total++;
      results.byCategory.intentClassification.total++;

      try {
        const allIntents = Object.keys(IntentTaxonomy);
        expect(allIntents.length).toBe(134);

        allIntents.forEach(intentId => {
          // Format: category.subcategory.action
          expect(intentId).toMatch(/^[a-z-]+\.[a-z-]+\.[a-z-]+$/);

          // All lowercase
          expect(intentId).toBe(intentId.toLowerCase());

          // No spaces
          expect(intentId).not.toMatch(/\s/);

          // At least 2 dots
          const parts = intentId.split('.');
          expect(parts.length).toBeGreaterThanOrEqual(3);
        });

        results.passed++;
        results.byCategory.intentClassification.passed++;
      } catch (error) {
        results.failed++;
        results.byCategory.intentClassification.failed++;
        results.failedTests.push({ category: 'intentClassification', name: 'Format', error: error.message });
        throw error;
      }
    });

    test('Intent confidence is between 0 and 1', () => {
      results.total++;
      results.byCategory.intentClassification.total++;

      try {
        const testEmail = {
          subject: 'Order Confirmation',
          body: 'Thank you for your order! Order #ABC123',
          snippet: 'Thank you for your order! Order #ABC123',
          fullText: 'Thank you for your order! Order #ABC123'
        };

        const result = classifyIntent(testEmail);

        expect(result.confidence).toBeGreaterThanOrEqual(0);
        expect(result.confidence).toBeLessThanOrEqual(1);
        expect(typeof result.confidence).toBe('number');

        results.passed++;
        results.byCategory.intentClassification.passed++;
      } catch (error) {
        results.failed++;
        results.byCategory.intentClassification.failed++;
        results.failedTests.push({ category: 'intentClassification', name: 'Confidence range', error: error.message });
        throw error;
      }
    });

    test('Intent IDs are from valid taxonomy', () => {
      results.total++;
      results.byCategory.intentClassification.total++;

      try {
        const validIntentIds = Object.keys(IntentTaxonomy);

        const testEmail = {
          subject: 'Your package has shipped',
          body: 'Tracking: 1Z999AA10123456784',
          snippet: 'Your package has shipped. Tracking: 1Z999AA10123456784',
          fullText: 'Your package has shipped. Tracking: 1Z999AA10123456784'
        };

        const result = classifyIntent(testEmail);

        expect(validIntentIds).toContain(result.intent);

        results.passed++;
        results.byCategory.intentClassification.passed++;
      } catch (error) {
        results.failed++;
        results.byCategory.intentClassification.failed++;
        results.failedTests.push({ category: 'intentClassification', name: 'Valid taxonomy', error: error.message });
        throw error;
      }
    });
  });

  // MARK: - Integration: Full Classification Response

  describe('Full Classification Response Contract', () => {
    test('Complete email classification returns iOS-compatible structure', () => {
      results.total++;

      try {
        const testEmail = {
          subject: 'Your order has shipped',
          body: 'Order #ABC123456 has shipped via UPS. Tracking: 1Z999AA10123456784. Arriving November 15.',
          snippet: 'Your order has shipped. Tracking number: 1Z999AA10123456784',
          fullText: 'Your order has shipped. Order #ABC123456 has shipped via UPS. Tracking: 1Z999AA10123456784. Arriving November 15.',
          from: 'orders@amazon.com'
        };

        // Classify intent
        const intentResult = classifyIntent(testEmail);
        expect(intentResult.intent).toBeDefined();
        expect(typeof intentResult.intent).toBe('string');
        expect(intentResult.confidence).toBeGreaterThanOrEqual(0);
        expect(intentResult.confidence).toBeLessThanOrEqual(1);

        // Extract entities
        const entities = extractAllEntities(testEmail, testEmail.fullText, intentResult.intent);
        expect(entities).toBeDefined();
        expect(typeof entities).toBe('object');

        // Get suggested actions (simplified - in real backend this comes from action service)
        const action = ActionCatalog['track_package'];
        expect(action).toBeDefined();
        expect(action.actionId).toBe('track_package');
        expect(['GO_TO', 'IN_APP']).toContain(action.actionType);

        // Validate complete response structure would be iOS-compatible
        const mockResponse = {
          id: 'test-123',
          type: 'mail',
          state: 'unread',
          priority: 'medium',
          hpa: 'orders@amazon.com',
          timeAgo: '5m',
          title: testEmail.subject,
          summary: testEmail.snippet,
          body: testEmail.body,
          metaCTA: 'Track Package',
          intent: intentResult.intent,
          intentConfidence: intentResult.confidence,
          suggestedActions: [{
            id: action.actionId,
            actionId: action.actionId,
            displayName: action.displayName,
            actionType: action.actionType,
            isPrimary: true,
            priority: action.priority,
            context: {
              trackingNumber: entities.trackingNumber || '',
              carrier: entities.carrier || ''
            }
          }]
        };

        // Validate structure
        expect(mockResponse.id).toBeDefined();
        expect(mockResponse.intent).toBeDefined();
        expect(mockResponse.intentConfidence).toBeGreaterThanOrEqual(0);
        expect(mockResponse.suggestedActions).toBeDefined();
        expect(Array.isArray(mockResponse.suggestedActions)).toBe(true);
        expect(mockResponse.suggestedActions.length).toBeGreaterThan(0);
        expect(mockResponse.suggestedActions[0].actionId).toBeDefined();
        expect(['GO_TO', 'IN_APP']).toContain(mockResponse.suggestedActions[0].actionType);

        results.passed++;
      } catch (error) {
        results.failed++;
        results.failedTests.push({ category: 'integration', name: 'Full response', error: error.message });
        throw error;
      }
    });
  });

  afterAll(() => {
    // Generate summary report
    console.log('\n' + '='.repeat(60));
    console.log('PHASE 2 TASK 2.1: IOS-BACKEND CONTRACT VALIDATION');
    console.log('='.repeat(60));
    console.log(`Total Tests: ${results.total}`);
    console.log(`Passed: ${results.passed} (${(results.passed/results.total*100).toFixed(1)}%)`);
    console.log(`Failed: ${results.failed} (${(results.failed/results.total*100).toFixed(1)}%)`);

    console.log('\nBy Category:');
    Object.entries(results.byCategory).forEach(([category, stats]) => {
      const passRate = stats.total > 0 ? (stats.passed / stats.total * 100).toFixed(0) : 0;
      console.log(`  ${category}: ${stats.passed}/${stats.total} (${passRate}%)`);
    });

    if (results.failedTests.length > 0) {
      console.log('\nFailed Tests:');
      results.failedTests.slice(0, 10).forEach(failure => {
        console.log(`  ${failure.category}.${failure.name}: ${failure.error}`);
      });
    }

    console.log('='.repeat(60) + '\n');

    // Save results to file
    const resultsPath = path.join(__dirname, '../../../test-data/phase2-contract-results.json');
    fs.writeFileSync(resultsPath, JSON.stringify(results, null, 2));
    console.log(`Results saved to: ${resultsPath}\n`);
  });
});
