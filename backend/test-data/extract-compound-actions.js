#!/usr/bin/env node
/**
 * Extract all compound actions from compound-action-registry.js to CSV
 * Generates comprehensive compound action inventory for test planning
 */

const fs = require('fs');
const path = require('path');

// Load compound action registry
const { COMPOUND_ACTIONS } = require('../services/actions/compound-action-registry.js');

// CSV header
const csvHeader = [
  'actionId',
  'displayName',
  'stepCount',
  'steps',
  'endBehaviorType',
  'requiresResponse',
  'isPremium',
  'description',
  'category'
].join(',');

// Helper: Escape CSV field
function escapeCSV(value) {
  if (value === null || value === undefined) return '';
  const str = String(value);
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

// Helper: Determine category from action name
function determineCategory(actionId) {
  if (actionId.includes('sign_form')) return 'education';
  if (actionId.includes('track') || actionId.includes('schedule_purchase')) return 'shopping';
  if (actionId.includes('pay_invoice')) return 'payment';
  if (actionId.includes('check_in')) return 'travel';
  if (actionId.includes('calendar')) return 'calendar';
  if (actionId.includes('cancel')) return 'subscription';
  return 'other';
}

// Extract all compound actions
const compoundActions = [];
const actionIds = Object.keys(COMPOUND_ACTIONS);

console.log(`\n📊 Extracting ${actionIds.length} compound actions from registry...\n`);

actionIds.forEach(actionId => {
  const action = COMPOUND_ACTIONS[actionId];

  const row = {
    actionId: action.actionId,
    displayName: action.displayName,
    stepCount: Array.isArray(action.steps) ? action.steps.length : 0,
    steps: Array.isArray(action.steps) ? action.steps.join(';') : '',
    endBehaviorType: action.endBehavior?.type || '',
    requiresResponse: action.requiresResponse ? 'yes' : 'no',
    isPremium: action.isPremium ? 'yes' : 'no',
    description: action.description,
    category: determineCategory(action.actionId)
  };

  compoundActions.push(row);
});

// Sort by category then name
compoundActions.sort((a, b) => {
  if (a.category !== b.category) {
    return a.category.localeCompare(b.category);
  }
  return a.actionId.localeCompare(b.actionId);
});

// Generate CSV
const csvLines = [csvHeader];
compoundActions.forEach(action => {
  const line = [
    escapeCSV(action.actionId),
    escapeCSV(action.displayName),
    escapeCSV(action.stepCount),
    escapeCSV(action.steps),
    escapeCSV(action.endBehaviorType),
    escapeCSV(action.requiresResponse),
    escapeCSV(action.isPremium),
    escapeCSV(action.description),
    escapeCSV(action.category)
  ].join(',');
  csvLines.push(line);
});

const csvContent = csvLines.join('\n');

// Write to file
const outputDir = path.join(__dirname);
const outputPath = path.join(outputDir, 'compound-actions-complete-list.csv');
fs.writeFileSync(outputPath, csvContent);

console.log(`✅ Extracted ${compoundActions.length} compound actions`);
console.log(`📁 Saved to: ${outputPath}`);

// Generate summary statistics
const stats = {
  total: compoundActions.length,
  premium: compoundActions.filter(a => a.isPremium === 'yes').length,
  free: compoundActions.filter(a => a.isPremium === 'no').length,
  requiresResponse: compoundActions.filter(a => a.requiresResponse === 'yes').length,
  personalActions: compoundActions.filter(a => a.requiresResponse === 'no').length,
  byCategory: {},
  byEndBehavior: {},
  totalSteps: 0,
  avgStepsPerAction: 0
};

compoundActions.forEach(action => {
  stats.byCategory[action.category] = (stats.byCategory[action.category] || 0) + 1;
  stats.byEndBehavior[action.endBehaviorType] = (stats.byEndBehavior[action.endBehaviorType] || 0) + 1;
  stats.totalSteps += parseInt(action.stepCount);
});

stats.avgStepsPerAction = (stats.totalSteps / stats.total).toFixed(1);

console.log('\n📈 Summary Statistics:');
console.log(`   Total Compound Actions: ${stats.total}`);
console.log(`   Premium: ${stats.premium}`);
console.log(`   Free: ${stats.free}`);
console.log(`   Requires Email Response: ${stats.requiresResponse}`);
console.log(`   Personal Actions (no response): ${stats.personalActions}`);
console.log(`   Total Steps: ${stats.totalSteps}`);
console.log(`   Avg Steps per Action: ${stats.avgStepsPerAction}`);
console.log('\n   By Category:');
Object.entries(stats.byCategory).sort((a, b) => b[1] - a[1]).forEach(([cat, count]) => {
  console.log(`      ${cat}: ${count}`);
});
console.log('\n   By End Behavior:');
Object.entries(stats.byEndBehavior).sort((a, b) => b[1] - a[1]).forEach(([behavior, count]) => {
  console.log(`      ${behavior}: ${count}`);
});

// List all actions
console.log('\n   All Compound Actions:');
compoundActions.forEach(action => {
  console.log(`      ${action.actionId} (${action.stepCount} steps, ${action.isPremium === 'yes' ? 'premium' : 'free'}, ${action.requiresResponse === 'yes' ? 'requires response' : 'personal'})`);
});

console.log('\n✨ Done!\n');
