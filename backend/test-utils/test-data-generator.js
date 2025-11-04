/**
 * Test Data Generator
 * Utilities for generating test emails, entities, and classifications
 */

const { IntentTaxonomy } = require('../shared/models/Intent');
const { ActionCatalog } = require('../services/actions/action-catalog');

class TestDataGenerator {
  /**
   * Generate test email with specific intent
   * @param {string} intentId - Intent ID to target
   * @param {Object} options - Generation options
   * @returns {Object} Generated email
   */
  static generateEmailForIntent(intentId, options = {}) {
    const intent = IntentTaxonomy[intentId];

    if (!intent) {
      throw new Error(`Unknown intent: ${intentId}`);
    }

    // Pick a random trigger phrase
    const trigger = intent.triggers?.[0] || intentId.replace(/\./g, ' ');

    // Extract domain hint from category
    const domainHints = {
      'e-commerce': 'amazon.com',
      'healthcare': 'healthcare.com',
      'finance': 'bank.com',
      'education': 'school.edu',
      'travel': 'airline.com',
      'billing': 'billing.com'
    };

    const domain = domainHints[intent.category] || 'example.com';

    return {
      subject: options.subject || `Test: ${trigger}`,
      from: options.from || `sender@${domain}`,
      to: options.to || 'test@example.com',
      body: options.body || `Email body containing ${trigger}. ${this.generateEntities(intent)}`,
      date: options.date || new Date().toISOString(),
      snippet: options.snippet || `Email body containing ${trigger}`,
      ...options
    };
  }

  /**
   * Generate entity content based on intent requirements
   * @param {Object} intent - Intent object
   * @returns {string} Entity-rich content
   */
  static generateEntities(intent) {
    const entityGenerators = {
      orderNumber: () => `Order #${Math.random().toString(36).substring(7).toUpperCase()}`,
      trackingNumber: () => `1Z999AA1${Math.floor(Math.random() * 1000000000)}`,
      amount: () => `$${(Math.random() * 1000).toFixed(2)}`,
      dateTime: () => new Date(Date.now() + 86400000).toISOString(),
      url: () => 'https://example.com/action',
      email: () => 'contact@example.com',
      phone: () => '(555) 123-4567'
    };

    const entityContent = [];
    (intent.requiredEntities || []).concat(intent.optionalEntities || []).forEach(entityType => {
      const generator = entityGenerators[entityType];
      if (generator) {
        entityContent.push(generator());
      }
    });

    return entityContent.join(' ');
  }

  /**
   * Generate batch of test emails across all intents
   * @param {Object} options - Generation options
   * @returns {Array} Array of test emails
   */
  static generateTestBatch(options = {}) {
    const {
      intentCount = 10,
      emailsPerIntent = 2
    } = options;

    const intentIds = Object.keys(IntentTaxonomy).slice(0, intentCount);
    const emails = [];

    intentIds.forEach(intentId => {
      for (let i = 0; i < emailsPerIntent; i++) {
        emails.push({
          ...this.generateEmailForIntent(intentId),
          _expectedIntent: intentId,
          _testId: `${intentId}_${i}`
        });
      }
    });

    return emails;
  }

  /**
   * Generate test classification result
   * @param {string} intentId - Intent ID
   * @param {Object} options - Generation options
   * @returns {Object} Classification result
   */
  static generateClassificationResult(intentId, options = {}) {
    const intent = IntentTaxonomy[intentId];

    if (!intent) {
      throw new Error(`Unknown intent: ${intentId}`);
    }

    // Get actions for this intent
    const actions = Object.values(ActionCatalog)
      .filter(action =>
        action.validIntents.includes(intentId) ||
        action.validIntents.length === 0
      )
      .sort((a, b) => a.priority - b.priority)
      .slice(0, 5)
      .map(action => ({
        actionId: action.actionId,
        displayName: action.displayName,
        actionType: action.actionType,
        priority: action.priority
      }));

    return {
      intent: intentId,
      category: intent.category,
      subCategory: intent.subCategory,
      confidence: options.confidence || 0.85,
      source: options.source || 'pattern_matching',
      actions: options.actions || actions,
      entities: options.entities || {},
      ...options
    };
  }

  /**
   * Generate edge case emails for testing
   * @returns {Array} Edge case emails
   */
  static generateEdgeCases() {
    return [
      {
        name: 'empty_subject',
        email: {
          subject: '',
          from: 'sender@example.com',
          body: 'Email with no subject'
        },
        expectedIntent: 'generic.transactional'
      },
      {
        name: 'empty_body',
        email: {
          subject: 'Test',
          from: 'sender@example.com',
          body: ''
        },
        expectedIntent: 'generic.transactional'
      },
      {
        name: 'html_only',
        email: {
          subject: 'Newsletter',
          from: 'news@example.com',
          body: '',
          htmlBody: '<html><body><h1>Newsletter</h1></body></html>'
        },
        expectedIntent: 'generic.newsletter'
      },
      {
        name: 'very_long_subject',
        email: {
          subject: 'A'.repeat(500),
          from: 'sender@example.com',
          body: 'Test body'
        },
        expectedIntent: 'generic.transactional'
      },
      {
        name: 'special_characters',
        email: {
          subject: '🎉 Sale! 50% off 🎉',
          from: 'deals@store.com',
          body: 'Limited time offer!'
        },
        expectedIntent: 'marketing.promotion.flash-sale'
      },
      {
        name: 'multiple_urls',
        email: {
          subject: 'Check these out',
          from: 'sender@example.com',
          body: 'Link 1: https://example.com/1 Link 2: https://example.com/2 Link 3: https://example.com/3'
        },
        expectedIntent: 'generic.transactional'
      },
      {
        name: 'very_short',
        email: {
          subject: 'Hi',
          from: 'friend@example.com',
          body: 'Hi!'
        },
        expectedIntent: 'generic.transactional'
      }
    ];
  }
}

module.exports = TestDataGenerator;
