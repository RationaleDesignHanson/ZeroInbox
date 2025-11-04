/**
 * Phase 1 Task 1.1: Intent Validation Test Suite
 * Streamlined test suite for validating all 134 intents
 */

const { classifyIntent } = require('../intent-classifier');
const { IntentTaxonomy } = require('../../../shared/models/Intent');
const fs = require('fs');
const path = require('path');

describe('Phase 1: Intent Validation', () => {
  const allIntents = Object.keys(IntentTaxonomy);
  const results = {
    total: 0,
    passed: 0,
    failed: 0,
    skipped: 0,
    byCategory: {},
    failedIntents: []
  };

  describe(`All ${allIntents.length} Intents - Basic Classification`, () => {
    allIntents.forEach(intentId => {
      const intent = IntentTaxonomy[intentId];
      const triggers = intent.triggers || [];

      if (triggers.length === 0) {
        test.skip(`[SKIP] ${intentId}: No triggers defined`, () => {});
        results.skipped++;
        return;
      }

      test(`${intentId}: Classifies correctly`, () => {
        results.total++;

        // Create test email with first trigger
        const trigger = triggers[0];
        const email = {
          subject: `Test: ${trigger}`,
          from: 'test@example.com',
          body: `Email body with trigger: ${trigger}. Testing classification.`,
          snippet: `Email body with trigger: ${trigger}`,
          fullText: `Email body with trigger: ${trigger}. Testing classification.`
        };

        const result = classifyIntent(email);

        // Track by category
        const category = intent.category;
        if (!results.byCategory[category]) {
          results.byCategory[category] = { total: 0, passed: 0, failed: 0 };
        }
        results.byCategory[category].total++;

        try {
          // Validate classification
          expect(result).toBeDefined();
          expect(result.intent).toBe(intentId);
          expect(result.confidence).toBeGreaterThan(0.5);
          expect(result.source).toBeDefined();

          results.passed++;
          results.byCategory[category].passed++;
        } catch (error) {
          results.failed++;
          results.byCategory[category].failed++;
          results.failedIntents.push({
            intentId,
            trigger,
            actualIntent: result.intent,
            confidence: result.confidence,
            error: error.message
          });
          throw error;
        }
      });
    });
  });

  describe('Test Email Templates', () => {
    const templatesPath = path.join(__dirname, '../../../test-data/test-email-templates.json');
    const templates = JSON.parse(fs.readFileSync(templatesPath, 'utf8')).templates;

    Object.entries(templates).forEach(([templateName, template]) => {
      test(`Template '${templateName}': ${template.expectedIntent}`, () => {
        const email = {
          subject: template.subject,
          from: template.from,
          to: template.to || 'test@example.com',
          body: template.body || '',
          htmlBody: template.htmlBody || '',
          snippet: (template.body || '').substring(0, 150),
          fullText: template.body || ''
        };

        const result = classifyIntent(email);

        expect(result.intent).toBe(template.expectedIntent);
        expect(result.confidence).toBeGreaterThanOrEqual(0.6);
      });
    });
  });

  describe('Category Coverage', () => {
    const categories = [...new Set(allIntents.map(id => IntentTaxonomy[id].category))];

    test(`Should cover ${categories.length} categories`, () => {
      expect(categories.length).toBeGreaterThan(20);
    });

    categories.forEach(category => {
      test(`Category '${category}': Has working intents`, () => {
        const categoryIntents = allIntents.filter(id => IntentTaxonomy[id].category === category);
        const intentsWithTriggers = categoryIntents.filter(id => IntentTaxonomy[id].triggers?.length > 0);

        expect(intentsWithTriggers.length).toBeGreaterThan(0);

        // Test first intent from this category
        const intentId = intentsWithTriggers[0];
        const intent = IntentTaxonomy[intentId];
        const trigger = intent.triggers[0];

        const email = {
          subject: trigger,
          from: 'test@example.com',
          body: trigger,
          snippet: trigger,
          fullText: trigger
        };

        const result = classifyIntent(email);
        const resultIntent = IntentTaxonomy[result.intent];
        expect(resultIntent.category).toBe(category);
      });
    });
  });

  afterAll(() => {
    // Generate summary report
    console.log('\n' + '='.repeat(60));
    console.log('PHASE 1 TASK 1.1: INTENT VALIDATION RESULTS');
    console.log('='.repeat(60));
    console.log(`Total Intents: ${allIntents.length}`);
    console.log(`Tested: ${results.total}`);
    console.log(`Passed: ${results.passed} (${(results.passed/results.total*100).toFixed(1)}%)`);
    console.log(`Failed: ${results.failed} (${(results.failed/results.total*100).toFixed(1)}%)`);
    console.log(`Skipped: ${results.skipped}`);

    console.log('\nBy Category:');
    Object.entries(results.byCategory)
      .sort((a, b) => b[1].total - a[1].total)
      .slice(0, 10)
      .forEach(([category, stats]) => {
        const passRate = (stats.passed / stats.total * 100).toFixed(0);
        console.log(`  ${category}: ${stats.passed}/${stats.total} (${passRate}%)`);
      });

    if (results.failedIntents.length > 0) {
      console.log('\nFailed Intents:');
      results.failedIntents.slice(0, 10).forEach(failure => {
        console.log(`  ${failure.intentId}`);
        console.log(`    Trigger: "${failure.trigger}"`);
        console.log(`    Got: ${failure.actualIntent} (confidence: ${failure.confidence})`);
      });
    }

    console.log('='.repeat(60) + '\n');

    // Save results to file
    const resultsPath = path.join(__dirname, '../../../test-data/phase1-intent-results.json');
    fs.writeFileSync(resultsPath, JSON.stringify(results, null, 2));
    console.log(`Results saved to: ${resultsPath}\n`);
  });
});
