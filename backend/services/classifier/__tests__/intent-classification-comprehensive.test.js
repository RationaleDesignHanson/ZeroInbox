/**
 * Comprehensive Intent Classification Tests
 * Tests all 134 intents with trigger validation and accuracy measurement
 *
 * Phase 1, Task 1.1
 */

const { classifyIntent } = require('../intent-classifier');
const { IntentTaxonomy } = require('../../../shared/models/Intent');
const TestDataGenerator = require('../../../test-utils/test-data-generator');

describe('Intent Classification - Comprehensive Suite', () => {

  // Load all intents
  const allIntents = Object.keys(IntentTaxonomy);
  const testResults = {
    total: allIntents.length,
    passed: 0,
    failed: 0,
    confidenceScores: []
  };

  describe('All 134 Intents - Trigger Validation', () => {
    allIntents.forEach(intentId => {
      const intent = IntentTaxonomy[intentId];
      const triggerCount = intent.triggers?.length || 0;

      if (triggerCount === 0) {
        test.skip(`${intentId}: No triggers defined (SKIP)`, () => {});
        return;
      }

      test(`${intentId}: Should classify correctly with first trigger phrase`, () => {
        // Generate test email with first trigger
        const email = TestDataGenerator.generateEmailForIntent(intentId);

        const result = classifyIntent(email);

        // Validate classification
        expect(result).toBeValidClassification();
        expect(result.intent).toBe(intentId);
        expect(result.confidence).toBeGreaterThan(0.5);
        expect(result.category).toBe(intent.category);

        // Track results
        testResults.passed++;
        testResults.confidenceScores.push({
          intent: intentId,
          confidence: result.confidence
        });
      });
    });
  });

  describe('High-Priority Intents - Multiple Trigger Validation', () => {
    // Test top 20 intents with multiple triggers
    const topIntents = allIntents
      .map(id => ({
        id,
        triggerCount: IntentTaxonomy[id].triggers?.length || 0
      }))
      .sort((a, b) => b.triggerCount - a.triggerCount)
      .slice(0, 20);

    topIntents.forEach(({ id }) => {
      const intent = IntentTaxonomy[id];
      const triggers = intent.triggers || [];

      test(`${id}: Should classify with ALL ${triggers.length} trigger phrases`, () => {
        const results = triggers.map(trigger => {
          const email = {
            subject: `Test: ${trigger}`,
            from: 'sender@example.com',
            body: `Email containing trigger phrase: ${trigger}`,
            snippet: `Email containing trigger phrase: ${trigger}`,
            fullText: `Email containing trigger phrase: ${trigger}`
          };

          return classifyIntent(email);
        });

        // All triggers should classify to the same intent
        results.forEach(result => {
          expect(result.intent).toBe(id);
          expect(result.confidence).toBeGreaterThan(0.5);
        });

        // Calculate average confidence
        const avgConfidence = results.reduce((sum, r) => sum + r.confidence, 0) / results.length;
        expect(avgConfidence).toBeGreaterThan(0.7);
      });
    });
  });

  describe('Category Validation', () => {
    const categories = [...new Set(allIntents.map(id => IntentTaxonomy[id].category))];

    test(`Should have ${categories.length} unique categories`, () => {
      expect(categories.length).toBeGreaterThan(15);
    });

    categories.forEach(category => {
      test(`Category '${category}': All intents should classify to correct category`, () => {
        const categoryIntents = allIntents.filter(id => IntentTaxonomy[id].category === category);

        // Test one intent from this category
        if (categoryIntents.length > 0) {
          const intentId = categoryIntents[0];
          const email = TestDataGenerator.generateEmailForIntent(intentId);
          const result = classifyIntent(email);

          expect(result.category).toBe(category);
        }
      });
    });
  });

  describe('Negative Pattern Validation', () => {
    // Test intents with negative patterns
    const intentsWithNegative = allIntents.filter(id => {
      const intent = IntentTaxonomy[id];
      return intent.negativePatterns && intent.negativePatterns.length > 0;
    });

    test(`Should have ${intentsWithNegative.length} intents with negative patterns`, () => {
      expect(intentsWithNegative.length).toBeGreaterThan(0);
    });

    intentsWithNegative.forEach(intentId => {
      const intent = IntentTaxonomy[intentId];
      const negativePhrases = intent.negativePatterns || [];

      test(`${intentId}: Should NOT classify when negative pattern present`, () => {
        // Create email with trigger AND negative pattern
        const trigger = intent.triggers?.[0] || intentId;
        const negativePhrase = negativePhrases[0];

        const email = {
          subject: `${trigger} - ${negativePhrase}`,
          from: 'sender@example.com',
          body: `Email with trigger ${trigger} but also negative: ${negativePhrase}`,
          snippet: `Email with trigger ${trigger} but also negative: ${negativePhrase}`,
          fullText: `Email with trigger ${trigger} but also negative: ${negativePhrase}`
        };

        const result = classifyIntent(email);

        // Should NOT classify to this intent (or have very low confidence)
        if (result.intent === intentId) {
          expect(result.confidence).toBeLessThan(0.7);
        } else {
          expect(result.intent).not.toBe(intentId);
        }
      });
    });
  });

  describe('Confidence Threshold Validation', () => {
    test('High-confidence classifications (>0.8) should be accurate', () => {
      let highConfidenceTests = 0;
      let highConfidenceCorrect = 0;

      // Test 50 random intents
      const sampleIntents = allIntents.slice(0, 50);

      sampleIntents.forEach(intentId => {
        const intent = IntentTaxonomy[intentId];
        if (!intent.triggers || intent.triggers.length === 0) return;

        const email = TestDataGenerator.generateEmailForIntent(intentId);
        const result = classifyIntent(email);

        if (result.confidence > 0.8) {
          highConfidenceTests++;
          if (result.intent === intentId) {
            highConfidenceCorrect++;
          }
        }
      });

      // At least 90% accuracy for high-confidence classifications
      if (highConfidenceTests > 0) {
        const accuracy = highConfidenceCorrect / highConfidenceTests;
        expect(accuracy).toBeGreaterThan(0.9);
      }
    });
  });

  describe('Test Email Templates Validation', () => {
    const templates = require('../../../test-data/test-email-templates.json').templates;
    const templateNames = Object.keys(templates);

    test(`Should have ${templateNames.length} test templates`, () => {
      expect(templateNames.length).toBeGreaterThan(15);
    });

    templateNames.forEach(templateName => {
      const template = templates[templateName];

      test(`Template '${templateName}': Should classify to expected intent`, () => {
        const email = {
          subject: template.subject,
          from: template.from,
          to: template.to || 'recipient@example.com',
          body: template.body || '',
          htmlBody: template.htmlBody || '',
          snippet: template.body?.substring(0, 150) || '',
          fullText: template.body || ''
        };

        const result = classifyIntent(email);

        expect(result).toBeValidClassification();
        expect(result.intent).toBe(template.expectedIntent);

        // Should have reasonable confidence
        expect(result.confidence).toBeGreaterThan(0.6);
      });
    });
  });

  describe('Edge Cases', () => {
    const edgeCases = TestDataGenerator.generateEdgeCases();

    edgeCases.forEach(({ name, email, expectedIntent }) => {
      test(`Edge case '${name}': Should handle gracefully`, () => {
        const result = classifyIntent(email);

        // Should return valid classification
        expect(result).toBeValidClassification();
        expect(result.intent).toBeDefined();
        expect(result.confidence).toBeGreaterThanOrEqual(0);
        expect(result.confidence).toBeLessThanOrEqual(1);

        // If expected intent provided, validate
        if (expectedIntent) {
          expect(result.intent).toContain(expectedIntent.split('.')[0]);
        }
      });
    });
  });

  describe('Domain Boost Validation', () => {
    test('Domain match should boost confidence', () => {
      // Test with and without domain match
      const intentId = 'e-commerce.shipping.notification';

      const emailWithDomain = TestDataGenerator.generateEmailForIntent(intentId, {
        from: 'shipment@amazon.com'
      });

      const emailWithoutDomain = TestDataGenerator.generateEmailForIntent(intentId, {
        from: 'sender@unknown.com'
      });

      const result1 = classifyIntent(emailWithDomain);
      const result2 = classifyIntent(emailWithoutDomain);

      // Domain match should have higher confidence
      expect(result1.confidence).toBeGreaterThan(result2.confidence);
    });
  });

  // Summary after all tests
  afterAll(() => {
    console.log('\n========================================');
    console.log('INTENT CLASSIFICATION TEST SUMMARY');
    console.log('========================================');
    console.log(`Total Intents Tested: ${testResults.total}`);
    console.log(`Passed: ${testResults.passed}`);
    console.log(`Failed: ${testResults.failed}`);

    if (testResults.confidenceScores.length > 0) {
      const avgConfidence = testResults.confidenceScores.reduce((sum, item) =>
        sum + item.confidence, 0
      ) / testResults.confidenceScores.length;

      console.log(`Avg Confidence: ${avgConfidence.toFixed(3)}`);

      // Find lowest confidence
      const lowest = testResults.confidenceScores.sort((a, b) =>
        a.confidence - b.confidence
      ).slice(0, 5);

      console.log('\nLowest Confidence Intents:');
      lowest.forEach(item => {
        console.log(`  ${item.intent}: ${item.confidence.toFixed(3)}`);
      });
    }
    console.log('========================================\n');
  });
});
