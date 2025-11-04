/**
 * Jest Setup File
 * Runs before all tests
 */

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.USE_ACTION_FIRST = 'true';
process.env.LOG_LEVEL = 'error'; // Reduce log noise during tests

// Mock external services (optional - uncomment if needed)
// jest.mock('../services/email/gmail-client');
// jest.mock('../services/email/outlook-client');

// Global test timeout
jest.setTimeout(30000); // 30 seconds

// Custom matchers
expect.extend({
  /**
   * Check if an intent is valid
   * @param {string} received - Intent ID
   */
  toBeValidIntent(received) {
    const { IntentTaxonomy } = require('../shared/models/Intent');
    const pass = received in IntentTaxonomy;

    return {
      pass,
      message: () =>
        pass
          ? `expected ${received} not to be a valid intent`
          : `expected ${received} to be a valid intent`
    };
  },

  /**
   * Check if an action is valid
   * @param {string} received - Action ID
   */
  toBeValidAction(received) {
    const { ActionCatalog } = require('../services/actions/action-catalog');
    const pass = received in ActionCatalog;

    return {
      pass,
      message: () =>
        pass
          ? `expected ${received} not to be a valid action`
          : `expected ${received} to be a valid action`
    };
  },

  /**
   * Check if entities match expected structure
   * @param {Object} received - Entities object
   * @param {Array} expected - Expected entity keys
   */
  toHaveEntities(received, expected) {
    const receivedKeys = Object.keys(received || {});
    const hasAll = expected.every(key => receivedKeys.includes(key));

    return {
      pass: hasAll,
      message: () =>
        hasAll
          ? `expected entities not to have all of [${expected.join(', ')}]`
          : `expected entities to have all of [${expected.join(', ')}], but found only [${receivedKeys.join(', ')}]`
    };
  },

  /**
   * Check if classification result is valid
   * @param {Object} received - Classification result
   */
  toBeValidClassification(received) {
    const hasRequiredFields =
      received &&
      typeof received.intent === 'string' &&
      typeof received.confidence === 'number' &&
      Array.isArray(received.actions) &&
      typeof received.category === 'string';

    return {
      pass: hasRequiredFields,
      message: () =>
        hasRequiredFields
          ? 'expected classification result not to be valid'
          : 'expected classification result to have intent, confidence, actions, and category fields'
    };
  }
});

// Global test helpers
global.testHelpers = {
  /**
   * Create mock email for testing
   * @param {Object} overrides - Fields to override
   * @returns {Object} Mock email
   */
  createMockEmail(overrides = {}) {
    return {
      subject: 'Test Subject',
      from: 'sender@example.com',
      to: 'recipient@example.com',
      body: 'Test email body content',
      date: new Date().toISOString(),
      snippet: 'Test email body content',
      ...overrides
    };
  },

  /**
   * Load test email template
   * @param {string} templateName - Template name from test-email-templates.json
   * @returns {Object} Email template
   */
  loadEmailTemplate(templateName) {
    const fs = require('fs');
    const path = require('path');
    const templatesPath = path.join(__dirname, '../test-data/test-email-templates.json');
    const templates = JSON.parse(fs.readFileSync(templatesPath, 'utf8'));
    return templates.templates[templateName];
  },

  /**
   * Wait for async operation
   * @param {number} ms - Milliseconds to wait
   * @returns {Promise}
   */
  wait(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
};

// Suppress console warnings in tests (optional)
// global.console = {
//   ...console,
//   warn: jest.fn(),
//   error: jest.fn(),
// };

console.log('✅ Jest setup complete');
