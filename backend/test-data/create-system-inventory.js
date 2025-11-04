#!/usr/bin/env node
/**
 * Create comprehensive system inventory snapshot
 * Combines all system components into single JSON for test planning
 */

const fs = require('fs');
const path = require('path');

// Load all system components
const { ActionCatalog, getAllActionIds } = require('../services/actions/action-catalog.js');
const { IntentTaxonomy } = require('../shared/models/Intent.js');
const { COMPOUND_ACTIONS } = require('../services/actions/compound-action-registry.js');

console.log('\n📦 Creating system inventory snapshot...\n');

// Get all action IDs and intents
const actionIds = getAllActionIds();
const intentIds = Object.keys(IntentTaxonomy);
const compoundActionIds = Object.keys(COMPOUND_ACTIONS);

// Build comprehensive inventory
const inventory = {
  metadata: {
    generatedAt: new Date().toISOString(),
    version: '1.9.0',
    description: 'Complete Zero Inbox system inventory for test planning'
  },

  summary: {
    totalActions: actionIds.length,
    totalIntents: intentIds.length,
    totalCompoundActions: compoundActionIds.length,
    totalTriggerPhrases: Object.values(IntentTaxonomy).reduce((sum, intent) =>
      sum + (intent.triggers?.length || 0), 0
    ),
    genericActions: actionIds.filter(id => ActionCatalog[id].validIntents.length === 0).length
  },

  actions: {
    count: actionIds.length,
    byType: {},
    byCategory: {},
    allActionIds: actionIds.sort(),
    actions: {}
  },

  intents: {
    count: intentIds.length,
    byCategory: {},
    allIntentIds: intentIds.sort(),
    intents: {}
  },

  compoundActions: {
    count: compoundActionIds.length,
    allCompoundActionIds: compoundActionIds.sort(),
    actions: {}
  },

  relationships: {
    intentToActions: {},
    actionToIntents: {},
    intentToCompoundActions: {}
  }
};

// Process actions
console.log('   Processing 138 actions...');
actionIds.forEach(actionId => {
  const action = ActionCatalog[actionId];

  // Count by type
  inventory.actions.byType[action.actionType] = (inventory.actions.byType[action.actionType] || 0) + 1;

  // Determine category
  const category = action.validIntents.length > 0
    ? action.validIntents[0].split('.')[0]
    : 'generic';
  inventory.actions.byCategory[category] = (inventory.actions.byCategory[category] || 0) + 1;

  // Store action details
  inventory.actions.actions[actionId] = {
    actionId: action.actionId,
    displayName: action.displayName,
    actionType: action.actionType,
    description: action.description,
    requiredEntities: action.requiredEntities,
    validIntents: action.validIntents,
    priority: action.priority,
    urlTemplate: action.urlTemplate,
    isGeneric: action.validIntents.length === 0
  };

  // Build action → intents relationship
  inventory.relationships.actionToIntents[actionId] = action.validIntents;
});

// Process intents
console.log('   Processing 134 intents...');
intentIds.forEach(intentId => {
  const intent = IntentTaxonomy[intentId];

  // Count by category
  const category = intent.category || 'unknown';
  inventory.intents.byCategory[category] = (inventory.intents.byCategory[category] || 0) + 1;

  // Store intent details
  inventory.intents.intents[intentId] = {
    intentId: intentId,
    category: intent.category,
    subCategory: intent.subCategory,
    action: intent.action,
    description: intent.description,
    triggers: intent.triggers,
    triggerCount: intent.triggers?.length || 0,
    negativePatterns: intent.negativePatterns,
    requiredEntities: intent.requiredEntities,
    optionalEntities: intent.optionalEntities
  };

  // Build intent → actions relationship
  const actionsForIntent = actionIds.filter(actionId => {
    const action = ActionCatalog[actionId];
    return action.validIntents.includes(intentId) || action.validIntents.length === 0;
  });
  inventory.relationships.intentToActions[intentId] = actionsForIntent;
});

// Process compound actions
console.log('   Processing 9 compound actions...');
compoundActionIds.forEach(actionId => {
  const action = COMPOUND_ACTIONS[actionId];

  inventory.compoundActions.actions[actionId] = {
    actionId: action.actionId,
    displayName: action.displayName,
    steps: action.steps,
    stepCount: action.steps.length,
    endBehaviorType: action.endBehavior?.type,
    requiresResponse: action.requiresResponse,
    isPremium: action.isPremium,
    description: action.description
  };
});

// Build intent → compound actions relationship
console.log('   Building relationships...');
const intentCompoundMapping = {
  'education.permission.form': ['sign_form_with_payment', 'sign_form_with_calendar', 'sign_and_send'],
  'e-commerce.shipping.notification': ['track_with_calendar'],
  'e-commerce.promotion': ['schedule_purchase_with_reminder'],
  'billing.invoice.due': ['pay_invoice_with_confirmation'],
  'travel.flight.check-in': ['check_in_with_wallet'],
  'subscription.cancellation': ['cancel_with_confirmation']
};

intentIds.forEach(intentId => {
  const compoundActions = intentCompoundMapping[intentId] || [];

  // Also add calendar_with_reminder for any appointment/event intents
  if (intentId.includes('appointment') || intentId.includes('event')) {
    if (!compoundActions.includes('calendar_with_reminder')) {
      compoundActions.push('calendar_with_reminder');
    }
  }

  inventory.relationships.intentToCompoundActions[intentId] = compoundActions;
});

// Write inventory to file
const outputPath = path.join(__dirname, 'system-inventory.json');
fs.writeFileSync(outputPath, JSON.stringify(inventory, null, 2));

console.log(`\n✅ System inventory created`);
console.log(`📁 Saved to: ${outputPath}`);
console.log(`📊 File size: ${(fs.statSync(outputPath).size / 1024).toFixed(1)} KB`);

// Print summary
console.log('\n📈 System Inventory Summary:');
console.log(`   Total Actions: ${inventory.summary.totalActions}`);
console.log(`   Total Intents: ${inventory.summary.totalIntents}`);
console.log(`   Total Compound Actions: ${inventory.summary.totalCompoundActions}`);
console.log(`   Total Trigger Phrases: ${inventory.summary.totalTriggerPhrases}`);
console.log(`   Generic Actions: ${inventory.summary.genericActions}`);

console.log('\n   Actions by Type:');
Object.entries(inventory.actions.byType).forEach(([type, count]) => {
  console.log(`      ${type}: ${count}`);
});

console.log('\n   Intents by Category (top 10):');
Object.entries(inventory.intents.byCategory)
  .sort((a, b) => b[1] - a[1])
  .slice(0, 10)
  .forEach(([cat, count]) => {
    console.log(`      ${cat}: ${count}`);
  });

console.log('\n   Relationships:');
console.log(`      Intent → Actions mappings: ${Object.keys(inventory.relationships.intentToActions).length}`);
console.log(`      Action → Intents mappings: ${Object.keys(inventory.relationships.actionToIntents).length}`);
console.log(`      Intent → Compound Actions: ${Object.values(inventory.relationships.intentToCompoundActions).filter(v => v.length > 0).length} intents have compound actions`);

console.log('\n✨ Done!\n');
