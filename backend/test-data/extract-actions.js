#!/usr/bin/env node
/**
 * Extract all actions from action-catalog.js to CSV
 * Generates comprehensive action inventory for test planning
 */

const fs = require('fs');
const path = require('path');

// Load action catalog
const { ActionCatalog } = require('../services/actions/action-catalog.js');

// CSV header
const csvHeader = [
  'actionId',
  'displayName',
  'actionType',
  'description',
  'requiredEntities',
  'validIntents',
  'priority',
  'urlTemplate',
  'isGeneric',
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

// Helper: Determine category from validIntents
function determineCategory(validIntents) {
  if (!validIntents || validIntents.length === 0) return 'generic';
  const firstIntent = validIntents[0];
  return firstIntent.split('.')[0] || 'unknown';
}

// Extract all actions
const actions = [];
const actionIds = Object.keys(ActionCatalog);

console.log(`\n📊 Extracting ${actionIds.length} actions from catalog...\n`);

actionIds.forEach(actionId => {
  const action = ActionCatalog[actionId];

  const row = {
    actionId: action.actionId,
    displayName: action.displayName,
    actionType: action.actionType,
    description: action.description,
    requiredEntities: Array.isArray(action.requiredEntities) ? action.requiredEntities.join(';') : '',
    validIntents: Array.isArray(action.validIntents) ? action.validIntents.join(';') : '',
    priority: action.priority,
    urlTemplate: action.urlTemplate || '',
    isGeneric: action.validIntents.length === 0 ? 'yes' : 'no',
    category: determineCategory(action.validIntents)
  };

  actions.push(row);
});

// Sort by category then priority
actions.sort((a, b) => {
  if (a.category !== b.category) {
    return a.category.localeCompare(b.category);
  }
  return a.priority - b.priority;
});

// Generate CSV
const csvLines = [csvHeader];
actions.forEach(action => {
  const line = [
    escapeCSV(action.actionId),
    escapeCSV(action.displayName),
    escapeCSV(action.actionType),
    escapeCSV(action.description),
    escapeCSV(action.requiredEntities),
    escapeCSV(action.validIntents),
    escapeCSV(action.priority),
    escapeCSV(action.urlTemplate),
    escapeCSV(action.isGeneric),
    escapeCSV(action.category)
  ].join(',');
  csvLines.push(line);
});

const csvContent = csvLines.join('\n');

// Write to file
const outputDir = path.join(__dirname);
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

const outputPath = path.join(outputDir, 'actions-complete-list.csv');
fs.writeFileSync(outputPath, csvContent);

console.log(`✅ Extracted ${actions.length} actions`);
console.log(`📁 Saved to: ${outputPath}`);

// Generate summary statistics
const stats = {
  total: actions.length,
  byType: {},
  byCategory: {},
  generic: actions.filter(a => a.isGeneric === 'yes').length,
  withRequiredEntities: actions.filter(a => a.requiredEntities !== '').length,
  withUrlTemplate: actions.filter(a => a.urlTemplate !== '').length
};

actions.forEach(action => {
  stats.byType[action.actionType] = (stats.byType[action.actionType] || 0) + 1;
  stats.byCategory[action.category] = (stats.byCategory[action.category] || 0) + 1;
});

console.log('\n📈 Summary Statistics:');
console.log(`   Total Actions: ${stats.total}`);
console.log(`   Generic Actions: ${stats.generic}`);
console.log(`   With Required Entities: ${stats.withRequiredEntities}`);
console.log(`   With URL Templates: ${stats.withUrlTemplate}`);
console.log('\n   By Type:');
Object.entries(stats.byType).sort((a, b) => b[1] - a[1]).forEach(([type, count]) => {
  console.log(`      ${type}: ${count}`);
});
console.log('\n   By Category (top 10):');
Object.entries(stats.byCategory).sort((a, b) => b[1] - a[1]).slice(0, 10).forEach(([cat, count]) => {
  console.log(`      ${cat}: ${count}`);
});

console.log('\n✨ Done!\n');
