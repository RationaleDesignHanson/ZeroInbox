#!/usr/bin/env node
/**
 * Extract all intents from Intent.js to CSV
 * Generates comprehensive intent inventory for test planning
 */

const fs = require('fs');
const path = require('path');

// Load intent taxonomy
const { IntentTaxonomy } = require('../shared/models/Intent.js');

// CSV header
const csvHeader = [
  'intentId',
  'category',
  'subCategory',
  'action',
  'description',
  'triggerCount',
  'triggers',
  'negativePatternCount',
  'negativePatterns',
  'requiredEntities',
  'optionalEntities',
  'confidence'
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

// Extract all intents
const intents = [];
const intentIds = Object.keys(IntentTaxonomy);

console.log(`\n📊 Extracting ${intentIds.length} intents from taxonomy...\n`);

intentIds.forEach(intentId => {
  const intent = IntentTaxonomy[intentId];

  const row = {
    intentId: intentId,
    category: intent.category || '',
    subCategory: intent.subCategory || '',
    action: intent.action || '',
    description: intent.description || '',
    triggerCount: Array.isArray(intent.triggers) ? intent.triggers.length : 0,
    triggers: Array.isArray(intent.triggers) ? intent.triggers.join(';') : '',
    negativePatternCount: Array.isArray(intent.negativePatterns) ? intent.negativePatterns.length : 0,
    negativePatterns: Array.isArray(intent.negativePatterns) ? intent.negativePatterns.join(';') : '',
    requiredEntities: Array.isArray(intent.requiredEntities) ? intent.requiredEntities.join(';') : '',
    optionalEntities: Array.isArray(intent.optionalEntities) ? intent.optionalEntities.join(';') : '',
    confidence: intent.confidence || ''
  };

  intents.push(row);
});

// Sort by category then subcategory
intents.sort((a, b) => {
  if (a.category !== b.category) {
    return a.category.localeCompare(b.category);
  }
  if (a.subCategory !== b.subCategory) {
    return a.subCategory.localeCompare(b.subCategory);
  }
  return a.action.localeCompare(b.action);
});

// Generate CSV
const csvLines = [csvHeader];
intents.forEach(intent => {
  const line = [
    escapeCSV(intent.intentId),
    escapeCSV(intent.category),
    escapeCSV(intent.subCategory),
    escapeCSV(intent.action),
    escapeCSV(intent.description),
    escapeCSV(intent.triggerCount),
    escapeCSV(intent.triggers),
    escapeCSV(intent.negativePatternCount),
    escapeCSV(intent.negativePatterns),
    escapeCSV(intent.requiredEntities),
    escapeCSV(intent.optionalEntities),
    escapeCSV(intent.confidence)
  ].join(',');
  csvLines.push(line);
});

const csvContent = csvLines.join('\n');

// Write to file
const outputDir = path.join(__dirname);
const outputPath = path.join(outputDir, 'intents-complete-list.csv');
fs.writeFileSync(outputPath, csvContent);

console.log(`✅ Extracted ${intents.length} intents`);
console.log(`📁 Saved to: ${outputPath}`);

// Generate summary statistics
const stats = {
  total: intents.length,
  byCategory: {},
  totalTriggers: 0,
  withNegativePatterns: 0,
  withRequiredEntities: 0,
  withOptionalEntities: 0,
  avgTriggersPerIntent: 0
};

intents.forEach(intent => {
  stats.byCategory[intent.category] = (stats.byCategory[intent.category] || 0) + 1;
  stats.totalTriggers += parseInt(intent.triggerCount);
  if (intent.negativePatternCount > 0) stats.withNegativePatterns++;
  if (intent.requiredEntities !== '') stats.withRequiredEntities++;
  if (intent.optionalEntities !== '') stats.withOptionalEntities++;
});

stats.avgTriggersPerIntent = (stats.totalTriggers / stats.total).toFixed(1);

console.log('\n📈 Summary Statistics:');
console.log(`   Total Intents: ${stats.total}`);
console.log(`   Total Trigger Phrases: ${stats.totalTriggers}`);
console.log(`   Avg Triggers per Intent: ${stats.avgTriggersPerIntent}`);
console.log(`   With Negative Patterns: ${stats.withNegativePatterns}`);
console.log(`   With Required Entities: ${stats.withRequiredEntities}`);
console.log(`   With Optional Entities: ${stats.withOptionalEntities}`);
console.log('\n   By Category:');
Object.entries(stats.byCategory).sort((a, b) => b[1] - a[1]).forEach(([cat, count]) => {
  console.log(`      ${cat}: ${count}`);
});

// Find intents with most triggers
const topTriggers = intents
  .sort((a, b) => b.triggerCount - a.triggerCount)
  .slice(0, 5);

console.log('\n   Top 5 Intents by Trigger Count:');
topTriggers.forEach(intent => {
  console.log(`      ${intent.intentId}: ${intent.triggerCount} triggers`);
});

console.log('\n✨ Done!\n');
