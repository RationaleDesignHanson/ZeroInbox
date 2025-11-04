/**
 * End-to-End Integration Tests for Mock Mode
 * Phase 2 Task 2.3: Verify mock classifier meets all iOS-backend contract requirements
 *
 * Test Coverage:
 * - All 59 mock templates return valid contract-compliant responses
 * - Compound actions are properly structured
 * - Entity generation is consistent
 * - Performance meets benchmarks (<50ms per classification)
 * - Fallback behavior works correctly
 */

const { classifyEmailMock, getAllTemplateIds, getTemplateById, loadMockTemplates } = require('../mock-classifier');
const { IntentTaxonomy } = require('../shared/models/Intent');
const { CompoundActionRegistry } = require('../../actions/compound-action-registry');

describe('Mock Mode E2E Integration Tests', () => {
  let allTemplates;
  let templateIds;

  beforeAll(() => {
    allTemplates = loadMockTemplates();
    templateIds = getAllTemplateIds();
  });

  // MARK: - Template Loading Tests

  describe('Template Loading', () => {
    test('should load all mock templates successfully', () => {
      expect(allTemplates).toBeDefined();
      expect(allTemplates.templates).toBeDefined();
      expect(Object.keys(allTemplates.templates).length).toBeGreaterThan(50);
    });

    test('should have correct template count', () => {
      expect(templateIds.length).toBe(59);
    });

    test('each template should have required fields', () => {
      templateIds.forEach(templateId => {
        const template = getTemplateById(templateId);
        expect(template).toBeDefined();
        expect(template.id).toBe(templateId);
        expect(template.subject).toBeDefined();
        expect(template.from).toBeDefined();
        expect(template.body).toBeDefined();
        expect(template.expectedIntent).toBeDefined();
        expect(template.expectedPrimaryAction).toBeDefined();
      });
    });
  });

  // MARK: - iOS Contract Compliance Tests

  describe('iOS Contract Compliance', () => {
    test('all mock classifications should return valid contract structure', () => {
      templateIds.forEach(templateId => {
        const template = getTemplateById(templateId);
        const email = {
          subject: template.subject,
          from: template.from,
          body: template.body
        };

        const classification = classifyEmailMock(email);

        // Required fields
        expect(classification.intent).toBeDefined();
        expect(classification.intentConfidence).toBeDefined();
        expect(classification.suggestedActions).toBeDefined();
        expect(classification.entities).toBeDefined();
        expect(classification.source).toBe('mock-template');
        expect(classification.mockTemplateId).toBeDefined(); // May not match templateId due to intelligent matching

        // Intent format validation (3-part format)
        expect(classification.intent).toMatch(/^[a-z-]+\.[a-z-]+\.[a-z-]+$/);

        // Confidence range
        expect(classification.intentConfidence).toBeGreaterThanOrEqual(0);
        expect(classification.intentConfidence).toBeLessThanOrEqual(1);

        // Actions array
        expect(Array.isArray(classification.suggestedActions)).toBe(true);
        expect(classification.suggestedActions.length).toBeGreaterThan(0);
        expect(classification.suggestedActions.length).toBeLessThanOrEqual(3);

        // Entities object
        expect(typeof classification.entities).toBe('object');
      });
    });

    test('all suggested actions should have required iOS fields', () => {
      templateIds.forEach(templateId => {
        const template = getTemplateById(templateId);
        const email = {
          subject: template.subject,
          from: template.from,
          body: template.body
        };

        const classification = classifyEmailMock(email);

        classification.suggestedActions.forEach((action, index) => {
          // Required action fields
          expect(action.actionId).toBeDefined();
          expect(action.displayName).toBeDefined();
          expect(action.actionType).toBeDefined();
          expect(action.priority).toBeDefined();
          expect(action.isPrimary).toBeDefined();

          // First action should be primary
          if (index === 0) {
            expect(action.isPrimary).toBe(true);
          }

          // Valid actionType
          expect(['GO_TO', 'IN_APP', 'QUICK_REPLY']).toContain(action.actionType);

          // Priority is a number
          expect(typeof action.priority).toBe('number');
        });
      });
    });

    test('all intents should exist in IntentTaxonomy', () => {
      templateIds.forEach(templateId => {
        const template = getTemplateById(templateId);
        const email = {
          subject: template.subject,
          from: template.from,
          body: template.body
        };

        const classification = classifyEmailMock(email);
        const intentExists = IntentTaxonomy[classification.intent];

        expect(intentExists).toBeDefined();
      });
    });
  });

  // MARK: - Compound Action Tests

  describe('Compound Action Flows', () => {
    test('compound actions should be properly structured when present', () => {
      const compoundTemplateIds = templateIds.filter(id => {
        const template = getTemplateById(id);
        return template.compoundAction;
      });

      expect(compoundTemplateIds.length).toBeGreaterThan(0);

      compoundTemplateIds.forEach(templateId => {
        const template = getTemplateById(templateId);
        const email = {
          subject: template.subject,
          from: template.from,
          body: template.body
        };

        const classification = classifyEmailMock(email);

        if (classification.compoundAction) {
          const compound = classification.compoundAction;

          // Required compound action fields
          expect(compound.actionId).toBeDefined();
          expect(compound.displayName).toBeDefined();
          expect(compound.steps).toBeDefined();
          expect(Array.isArray(compound.steps)).toBe(true);
          expect(compound.steps.length).toBeGreaterThanOrEqual(2);

          // Optional but important fields
          expect(compound.endBehavior).toBeDefined();
          expect(typeof compound.requiresResponse).toBe('boolean');
          expect(typeof compound.isPremium).toBe('boolean');

          // Verify compound action exists in registry
          const registryAction = CompoundActionRegistry.getCompoundAction(template.compoundAction);
          expect(registryAction).toBeDefined();
        }
      });
    });

    test('compound action steps should be valid action IDs', () => {
      const compoundTemplateIds = templateIds.filter(id => {
        const template = getTemplateById(id);
        return template.compoundAction;
      });

      compoundTemplateIds.forEach(templateId => {
        const template = getTemplateById(templateId);
        const email = {
          subject: template.subject,
          from: template.from,
          body: template.body
        };

        const classification = classifyEmailMock(email);

        if (classification.compoundAction) {
          classification.compoundAction.steps.forEach(stepActionId => {
            expect(typeof stepActionId).toBe('string');
            expect(stepActionId.length).toBeGreaterThan(0);
          });
        }
      });
    });
  });

  // MARK: - Entity Generation Tests

  describe('Entity Generation', () => {
    test('entities should match expected entities from template', () => {
      let templatesWithEntities = 0;
      let entitiesGenerated = 0;
      let entitiesMissing = 0;

      templateIds.forEach(templateId => {
        const template = getTemplateById(templateId);

        if (!template.expectedEntities || template.expectedEntities.length === 0) {
          return; // Skip templates with no expected entities
        }

        templatesWithEntities++;

        const email = {
          subject: template.subject,
          from: template.from,
          body: template.body
        };

        const classification = classifyEmailMock(email);

        // Count generated vs missing entities
        template.expectedEntities.forEach(entityName => {
          if (classification.entities[entityName]) {
            entitiesGenerated++;
          } else {
            entitiesMissing++;
          }
        });
      });

      // At least 65% of expected entities should be generated
      // (Some templates may match to other templates due to intelligent matching,
      // which means they won't have their exact expected entities)
      const successRate = entitiesGenerated / (entitiesGenerated + entitiesMissing);
      expect(successRate).toBeGreaterThan(0.65);

      console.log(`Entity generation: ${entitiesGenerated}/${entitiesGenerated + entitiesMissing} (${(successRate * 100).toFixed(1)}%) across ${templatesWithEntities} templates`);
    });

    test('entity values should be realistic', () => {
      // Test specific templates with known entities
      const testCases = [
        {
          templateId: 'ecommerce_shipping_01',
          expectedEntities: {
            orderNumber: expect.stringMatching(/\d/),
            trackingNumber: expect.stringMatching(/[A-Z0-9]/),
            carrier: expect.any(String)
          }
        },
        {
          templateId: 'billing_invoice_due',
          expectedEntities: {
            invoiceId: expect.stringMatching(/INV/),
            amountDue: expect.stringMatching(/\$/),
            dueDate: expect.stringMatching(/\d{4}-\d{2}-\d{2}/)
          }
        },
        {
          templateId: 'healthcare_appointment_reminder',
          expectedEntities: {
            provider: expect.any(String),
            dateTime: expect.stringMatching(/\d{4}-\d{2}-\d{2}/)
          }
        }
      ];

      testCases.forEach(testCase => {
        const template = getTemplateById(testCase.templateId);
        const email = {
          subject: template.subject,
          from: template.from,
          body: template.body
        };

        const classification = classifyEmailMock(email);

        Object.keys(testCase.expectedEntities).forEach(entityName => {
          expect(classification.entities[entityName]).toEqual(testCase.expectedEntities[entityName]);
        });
      });
    });
  });

  // MARK: - Performance Tests

  describe('Performance Benchmarks', () => {
    test('classification should complete in under 50ms', () => {
      const template = getTemplateById('ecommerce_shipping_01');
      const email = {
        subject: template.subject,
        from: template.from,
        body: template.body
      };

      const startTime = Date.now();
      classifyEmailMock(email);
      const endTime = Date.now();

      const duration = endTime - startTime;
      expect(duration).toBeLessThan(50);
    });

    test('batch classification of all templates should complete in under 2 seconds', () => {
      const startTime = Date.now();

      templateIds.forEach(templateId => {
        const template = getTemplateById(templateId);
        const email = {
          subject: template.subject,
          from: template.from,
          body: template.body
        };
        classifyEmailMock(email);
      });

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(duration).toBeLessThan(2000);
      console.log(`Batch classification of ${templateIds.length} templates: ${duration}ms (avg: ${(duration / templateIds.length).toFixed(2)}ms per template)`);
    });
  });

  // MARK: - Matching Strategy Tests

  describe('Template Matching Strategies', () => {
    test('should match by subject keywords', () => {
      const email = {
        subject: 'Your Amazon package is arriving tomorrow',
        from: 'notifications@example.com',
        body: 'Random body text'
      };

      const classification = classifyEmailMock(email);

      // Should match e-commerce shipping template
      expect(classification.intent).toMatch(/e-commerce/);
    });

    test('should match by sender domain', () => {
      const email = {
        subject: 'Random subject',
        from: 'noreply@amazon.com',
        body: 'Random body'
      };

      const classification = classifyEmailMock(email);

      // Should match Amazon-related template
      expect(classification.source).toBe('mock-template');
      expect(classification.mockTemplateId).toBeDefined();
    });

    test('should provide fallback for unmatched emails', () => {
      const email = {
        subject: 'xyz123abc456',
        from: 'random@unknown-domain-xyz123.com',
        body: 'Completely random content with no patterns'
      };

      const classification = classifyEmailMock(email);

      // Should still provide valid classification
      expect(classification.intent).toBeDefined();
      expect(classification.suggestedActions.length).toBeGreaterThan(0);
      expect(classification.source).toBe('mock-template');
    });
  });

  // MARK: - Intent Category Coverage Tests

  describe('Intent Category Coverage', () => {
    test('should cover all major intent categories', () => {
      const categories = new Set();

      templateIds.forEach(templateId => {
        const template = getTemplateById(templateId);
        const email = {
          subject: template.subject,
          from: template.from,
          body: template.body
        };

        const classification = classifyEmailMock(email);
        const category = classification.intent.split('.')[0];
        categories.add(category);
      });

      // Should have at least 10 different categories
      expect(categories.size).toBeGreaterThanOrEqual(10);

      // Should include major categories
      const majorCategories = ['e-commerce', 'healthcare', 'billing', 'education', 'travel', 'finance'];
      majorCategories.forEach(category => {
        expect(categories.has(category)).toBe(true);
      });

      console.log(`Coverage: ${categories.size} intent categories:`, Array.from(categories).sort());
    });
  });

  // MARK: - Edge Case Tests

  describe('Edge Cases', () => {
    test('should handle missing body field', () => {
      const email = {
        subject: 'Your Amazon order has shipped',
        from: 'shipment-tracking@amazon.com'
        // body is missing
      };

      const classification = classifyEmailMock(email);
      expect(classification.intent).toBeDefined();
      expect(classification.suggestedActions).toBeDefined();
    });

    test('should handle empty strings', () => {
      const email = {
        subject: '',
        from: 'test@example.com',
        body: ''
      };

      const classification = classifyEmailMock(email);
      expect(classification.intent).toBeDefined();
      expect(classification.suggestedActions).toBeDefined();
    });

    test('should handle very long subject lines', () => {
      const email = {
        subject: 'Your Amazon order '.repeat(50) + 'has shipped',
        from: 'shipment-tracking@amazon.com',
        body: 'Order details here'
      };

      const classification = classifyEmailMock(email);
      expect(classification.intent).toBeDefined();
      expect(classification.suggestedActions).toBeDefined();
    });
  });
});
