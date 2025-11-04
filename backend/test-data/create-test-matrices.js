#!/usr/bin/env node
/**
 * Create comprehensive test matrices for tracking test execution
 * Generates 5 CSV matrices for different testing aspects
 */

const fs = require('fs');
const path = require('path');

// Load system inventory
const inventory = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'system-inventory.json'), 'utf8')
);

console.log('\n📊 Creating test matrices...\n');

// Helper: Escape CSV field
function escapeCSV(value) {
  if (value === null || value === undefined) return '';
  const str = String(value);
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

// ==========================================
// 1. ACTION COVERAGE MATRIX
// ==========================================
console.log('   Creating ACTION_COVERAGE_MATRIX.csv (138 rows)...');

const actionMatrixHeader = [
  'actionId',
  'displayName',
  'actionType',
  'category',
  'phase1_classification',
  'phase1_notes',
  'phase2_mock_mode',
  'phase2_ios_integration',
  'phase2_notes',
  'phase3_corpus_testing',
  'phase3_notes',
  'phase4_performance',
  'phase4_analytics',
  'phase4_notes',
  'overall_status',
  'priority'
].join(',');

const actionMatrixLines = [actionMatrixHeader];

Object.values(inventory.actions.actions).forEach(action => {
  const line = [
    escapeCSV(action.actionId),
    escapeCSV(action.displayName),
    escapeCSV(action.actionType),
    escapeCSV(action.validIntents.length > 0 ? action.validIntents[0].split('.')[0] : 'generic'),
    'not_tested',  // phase1_classification
    '',  // phase1_notes
    'not_tested',  // phase2_mock_mode
    'not_tested',  // phase2_ios_integration
    '',  // phase2_notes
    'not_tested',  // phase3_corpus_testing
    '',  // phase3_notes
    'not_tested',  // phase4_performance
    'not_tested',  // phase4_analytics
    '',  // phase4_notes
    'not_started',  // overall_status
    action.priority.toString()  // priority
  ].join(',');
  actionMatrixLines.push(line);
});

fs.writeFileSync(
  path.join(__dirname, 'ACTION_COVERAGE_MATRIX.csv'),
  actionMatrixLines.join('\n')
);

// ==========================================
// 2. INTENT COVERAGE MATRIX
// ==========================================
console.log('   Creating INTENT_COVERAGE_MATRIX.csv (134 rows)...');

const intentMatrixHeader = [
  'intentId',
  'category',
  'triggerCount',
  'actionCount',
  'phase1_trigger_validation',
  'phase1_classification_accuracy',
  'phase1_action_routing',
  'phase1_notes',
  'phase3_corpus_sample_count',
  'phase3_accuracy',
  'phase3_notes',
  'overall_status',
  'confidence_threshold'
].join(',');

const intentMatrixLines = [intentMatrixHeader];

Object.values(inventory.intents.intents).forEach(intent => {
  const actionCount = inventory.relationships.intentToActions[intent.intentId]?.length || 0;

  const line = [
    escapeCSV(intent.intentId),
    escapeCSV(intent.category),
    escapeCSV(intent.triggerCount.toString()),
    escapeCSV(actionCount.toString()),
    'not_tested',  // phase1_trigger_validation
    'not_tested',  // phase1_classification_accuracy
    'not_tested',  // phase1_action_routing
    '',  // phase1_notes
    '0',  // phase3_corpus_sample_count
    '0.0',  // phase3_accuracy
    '',  // phase3_notes
    'not_started',  // overall_status
    '0.7'  // confidence_threshold
  ].join(',');
  intentMatrixLines.push(line);
});

fs.writeFileSync(
  path.join(__dirname, 'INTENT_COVERAGE_MATRIX.csv'),
  intentMatrixLines.join('\n')
);

// ==========================================
// 3. COMPOUND ACTION MATRIX
// ==========================================
console.log('   Creating COMPOUND_ACTION_MATRIX.csv (9 rows)...');

const compoundMatrixHeader = [
  'compoundActionId',
  'displayName',
  'stepCount',
  'steps',
  'requiresResponse',
  'isPremium',
  'phase1_step_validation',
  'phase1_sequencing_test',
  'phase1_notes',
  'phase2_modal_flow_test',
  'phase2_end_behavior_test',
  'phase2_notes',
  'phase3_real_world_test',
  'phase3_notes',
  'overall_status'
].join(',');

const compoundMatrixLines = [compoundMatrixHeader];

Object.values(inventory.compoundActions.actions).forEach(action => {
  const line = [
    escapeCSV(action.actionId),
    escapeCSV(action.displayName),
    escapeCSV(action.stepCount.toString()),
    escapeCSV(action.steps.join(';')),
    escapeCSV(action.requiresResponse ? 'yes' : 'no'),
    escapeCSV(action.isPremium ? 'yes' : 'no'),
    'not_tested',  // phase1_step_validation
    'not_tested',  // phase1_sequencing_test
    '',  // phase1_notes
    'not_tested',  // phase2_modal_flow_test
    'not_tested',  // phase2_end_behavior_test
    '',  // phase2_notes
    'not_tested',  // phase3_real_world_test
    '',  // phase3_notes
    'not_started'  // overall_status
  ].join(',');
  compoundMatrixLines.push(line);
});

fs.writeFileSync(
  path.join(__dirname, 'COMPOUND_ACTION_MATRIX.csv'),
  compoundMatrixLines.join('\n')
);

// ==========================================
// 4. ENTITY EXTRACTION MATRIX
// ==========================================
console.log('   Creating ENTITY_EXTRACTION_MATRIX.csv...');

// Collect all unique entity types from intents
const allEntities = new Set();
Object.values(inventory.intents.intents).forEach(intent => {
  (intent.requiredEntities || []).forEach(e => allEntities.add(e));
  (intent.optionalEntities || []).forEach(e => allEntities.add(e));
});

const entityTypes = Array.from(allEntities).sort();

const entityMatrixHeader = [
  'entityType',
  'usedByIntentCount',
  'phase1_extraction_test',
  'phase1_format_validation',
  'phase1_notes',
  'phase3_corpus_accuracy',
  'phase3_edge_cases',
  'phase3_notes',
  'overall_status'
].join(',');

const entityMatrixLines = [entityMatrixHeader];

entityTypes.forEach(entityType => {
  // Count how many intents use this entity
  const intentCount = Object.values(inventory.intents.intents).filter(intent =>
    (intent.requiredEntities || []).includes(entityType) ||
    (intent.optionalEntities || []).includes(entityType)
  ).length;

  const line = [
    escapeCSV(entityType),
    escapeCSV(intentCount.toString()),
    'not_tested',  // phase1_extraction_test
    'not_tested',  // phase1_format_validation
    '',  // phase1_notes
    '0.0',  // phase3_corpus_accuracy
    'not_tested',  // phase3_edge_cases
    '',  // phase3_notes
    'not_started'  // overall_status
  ].join(',');
  entityMatrixLines.push(line);
});

fs.writeFileSync(
  path.join(__dirname, 'ENTITY_EXTRACTION_MATRIX.csv'),
  entityMatrixLines.join('\n')
);

// ==========================================
// 5. PLATFORM PARITY MATRIX
// ==========================================
console.log('   Creating PLATFORM_PARITY_MATRIX.csv...');

// Test categories for platform parity
const parityFeatures = [
  { feature: 'Email List Display', component: 'EmailListView', type: 'UI' },
  { feature: 'Action Button Rendering', component: 'ActionButtonRow', type: 'UI' },
  { feature: 'Modal Presentation', component: 'ModalCoordinator', type: 'UI' },
  { feature: 'Authentication Flow', component: 'UserSession', type: 'Auth' },
  { feature: 'Mock Mode Classification', component: 'ClassifierService', type: 'Backend' },
  { feature: 'Mock Mode Actions', component: 'ActionService', type: 'Backend' },
  { feature: 'Calendar Integration', component: 'CalendarService', type: 'iOS Integration' },
  { feature: 'Notes Integration', component: 'NotesService', type: 'iOS Integration' },
  { feature: 'Wallet Integration', component: 'WalletService', type: 'iOS Integration' },
  { feature: 'URL Handling (GO_TO actions)', component: 'SafariViewController', type: 'iOS Integration' },
  { feature: 'Email Composer', component: 'MFMailComposeViewController', type: 'iOS Integration' },
  { feature: 'Analytics Events', component: 'AnalyticsService', type: 'Backend' },
  { feature: 'Error Handling', component: 'ErrorCoordinator', type: 'UI' },
  { feature: 'Offline Queue', component: 'OfflineActionQueue', type: 'Backend' },
  { feature: 'Action Validation', component: 'CompoundActionContextValidator', type: 'Backend' }
];

const parityMatrixHeader = [
  'feature',
  'component',
  'type',
  'authenticated_user_test',
  'authenticated_notes',
  'mock_mode_test',
  'mock_notes',
  'parity_status',
  'discrepancies',
  'overall_status'
].join(',');

const parityMatrixLines = [parityMatrixHeader];

parityFeatures.forEach(item => {
  const line = [
    escapeCSV(item.feature),
    escapeCSV(item.component),
    escapeCSV(item.type),
    'not_tested',  // authenticated_user_test
    '',  // authenticated_notes
    'not_tested',  // mock_mode_test
    '',  // mock_notes
    'unknown',  // parity_status
    '',  // discrepancies
    'not_started'  // overall_status
  ].join(',');
  parityMatrixLines.push(line);
});

fs.writeFileSync(
  path.join(__dirname, 'PLATFORM_PARITY_MATRIX.csv'),
  parityMatrixLines.join('\n')
);

// ==========================================
// Summary
// ==========================================
console.log('\n✅ All test matrices created');
console.log(`📁 Saved to: ${__dirname}`);

console.log('\n📈 Matrix Summary:');
console.log(`   ACTION_COVERAGE_MATRIX.csv: ${actionMatrixLines.length - 1} actions`);
console.log(`   INTENT_COVERAGE_MATRIX.csv: ${intentMatrixLines.length - 1} intents`);
console.log(`   COMPOUND_ACTION_MATRIX.csv: ${compoundMatrixLines.length - 1} compound actions`);
console.log(`   ENTITY_EXTRACTION_MATRIX.csv: ${entityMatrixLines.length - 1} entity types`);
console.log(`   PLATFORM_PARITY_MATRIX.csv: ${parityMatrixLines.length - 1} features`);

console.log('\n📝 Status Values:');
console.log('   not_started = Test not yet started');
console.log('   not_tested = Individual test case not run');
console.log('   pass = Test passed');
console.log('   fail = Test failed (needs investigation)');
console.log('   skip = Test intentionally skipped');

console.log('\n✨ Done!\n');
