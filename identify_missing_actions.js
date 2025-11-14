/**
 * Identify Missing Actions
 * Compares backend ActionCatalog with iOS ActionRegistry to find gaps
 */

const { ActionCatalog } = require('./backend/dashboard/action-catalog.js');
const fs = require('fs');
const path = require('path');

// Read iOS ActionRegistry.swift
const iosRegistryPath = path.join(__dirname, 'Zero_ios_2/Zero/Services/ActionRegistry.swift');
const iosRegistryContent = fs.readFileSync(iosRegistryPath, 'utf8');

// Extract action IDs from backend catalog
const backendActionIds = Object.keys(ActionCatalog).sort();

// Extract action IDs from iOS registry using regex
const iosActionIdMatches = iosRegistryContent.matchAll(/actionId:\s*"([^"]+)"/g);
const iosActionIds = Array.from(iosActionIdMatches, m => m[1]).sort();

// Find missing actions
const missingActionIds = backendActionIds.filter(id => !iosActionIds.includes(id));

console.log('═══════════════════════════════════════════════════════');
console.log('ACTION REGISTRY GAP ANALYSIS');
console.log('═══════════════════════════════════════════════════════\n');

console.log(`Backend Actions:  ${backendActionIds.length}`);
console.log(`iOS Actions:      ${iosActionIds.length}`);
console.log(`Missing Actions:  ${missingActionIds.length}\n`);

console.log('═══════════════════════════════════════════════════════');
console.log('MISSING ACTIONS (need to add to iOS):');
console.log('═══════════════════════════════════════════════════════\n');

// Group by category
const categorized = {};

missingActionIds.forEach(actionId => {
    const action = ActionCatalog[actionId];

    // Determine category from validIntents
    let category = 'Generic';
    if (action.validIntents && action.validIntents.length > 0) {
        const firstIntent = action.validIntents[0];
        if (firstIntent.startsWith('e-commerce')) category = 'E-Commerce';
        else if (firstIntent.startsWith('billing')) category = 'Billing';
        else if (firstIntent.startsWith('event')) category = 'Events';
        else if (firstIntent.startsWith('account')) category = 'Account';
        else if (firstIntent.startsWith('healthcare')) category = 'Healthcare';
        else if (firstIntent.startsWith('dining')) category = 'Dining';
        else if (firstIntent.startsWith('delivery')) category = 'Delivery';
        else if (firstIntent.startsWith('education')) category = 'Education';
        else if (firstIntent.startsWith('youth')) category = 'Education';
        else if (firstIntent.startsWith('travel')) category = 'Travel';
        else if (firstIntent.startsWith('feedback')) category = 'Feedback';
        else if (firstIntent.startsWith('marketing')) category = 'Shopping';
        else if (firstIntent.startsWith('shopping')) category = 'Shopping';
        else if (firstIntent.startsWith('support')) category = 'Support';
        else if (firstIntent.startsWith('project')) category = 'Project';
        else if (firstIntent.startsWith('finance')) category = 'Finance';
        else if (firstIntent.startsWith('utility')) category = 'Utility';
        else if (firstIntent.startsWith('real-estate')) category = 'Real Estate';
        else if (firstIntent.startsWith('community')) category = 'Community';
        else if (firstIntent.startsWith('civic')) category = 'Civic';
        else if (firstIntent.startsWith('subscription')) category = 'Subscription';
        else if (firstIntent.startsWith('communication')) category = 'Communication';
        else if (firstIntent.startsWith('career')) category = 'Career';
        else if (firstIntent.startsWith('legal')) category = 'Professional';
        else if (firstIntent.startsWith('social')) category = 'Social';
    }

    if (!categorized[category]) {
        categorized[category] = [];
    }

    categorized[category].push({
        actionId,
        displayName: action.displayName,
        actionType: action.actionType,
        priority: action.priority
    });
});

// Print categorized list
Object.keys(categorized).sort().forEach(category => {
    console.log(`\n### ${category} (${categorized[category].length} actions)`);
    categorized[category].forEach(action => {
        console.log(`  - ${action.actionId.padEnd(35)} (${action.actionType}) - ${action.displayName}`);
    });
});

console.log('\n\n═══════════════════════════════════════════════════════');
console.log('SUMMARY');
console.log('═══════════════════════════════════════════════════════\n');

Object.keys(categorized).sort().forEach(category => {
    console.log(`${category.padEnd(20)}: ${categorized[category].length} actions`);
});

console.log('\n');
