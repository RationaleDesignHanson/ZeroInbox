/**
 * Jest Configuration for Zero Inbox Backend
 * Coverage targets based on service criticality
 */

module.exports = {
  // Test environment
  testEnvironment: 'node',

  // Test match patterns
  testMatch: [
    '**/__tests__/**/*.test.js',
    '**/*.test.js'
  ],

  // Coverage collection
  collectCoverageFrom: [
    'services/**/*.js',
    'shared/**/*.js',
    '!**/node_modules/**',
    '!**/coverage/**',
    '!**/__tests__/**',
    '!**/test-*.js'
  ],

  // Coverage thresholds (failing if below these)
  coverageThreshold: {
    global: {
      statements: 60,
      branches: 55,
      functions: 60,
      lines: 60
    },
    // Critical services need higher coverage
    './services/classifier/**/*.js': {
      statements: 75,
      branches: 70,
      functions: 75,
      lines: 75
    },
    './services/actions/rules-engine.js': {
      statements: 80,
      branches: 75,
      functions: 80,
      lines: 80
    },
    './services/actions/action-catalog.js': {
      statements: 65,
      branches: 60,
      functions: 65,
      lines: 65
    },
    './shared/models/Intent.js': {
      statements: 70,
      branches: 65,
      functions: 70,
      lines: 70
    }
  },

  // Coverage reporters
  coverageReporters: [
    'text',
    'text-summary',
    'html',
    'lcov',
    'json'
  ],

  // Setup files
  // setupFilesAfterEnv: ['<rootDir>/test-utils/jest.setup.js'],

  // Module paths
  moduleDirectories: ['node_modules', 'test-utils'],

  // Test timeout (2 minutes for corpus processing tests)
  testTimeout: 120000,

  // Verbose output
  verbose: true,

  // Clear mocks between tests
  clearMocks: true,

  // Restore mocks after each test
  restoreMocks: true,

  // Reset mocks after each test
  resetMocks: true,

  // Max workers (parallel test execution)
  maxWorkers: '50%',

  // Transform (if needed for ES6 modules)
  transform: {},

  // Global setup/teardown
  // globalSetup: '<rootDir>/test-utils/global-setup.js',
  // globalTeardown: '<rootDir>/test-utils/global-teardown.js',

  // Ignore patterns
  testPathIgnorePatterns: [
    '/node_modules/',
    '/coverage/',
    '/services.backup_logger_consolidation/'
  ],

  // Coverage directory
  coverageDirectory: '<rootDir>/coverage',

  // Reporter options for better test output
  reporters: [
    'default'
    // Uncomment when jest-junit is installed:
    // ['jest-junit', { outputDirectory: './test-results', outputName: 'junit.xml' }]
  ],

  // Test result processor
  // testResultsProcessor: '<rootDir>/test-utils/test-results-processor.js'
};
