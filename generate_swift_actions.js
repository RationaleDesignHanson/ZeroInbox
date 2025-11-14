/**
 * Generate Swift ActionConfig code for all missing actions
 */

const { ActionCatalog } = require('./backend/dashboard/action-catalog.js');
const fs = require('fs');
const path = require('path');

// Read iOS ActionRegistry.swift
const iosRegistryPath = path.join(__dirname, 'Zero_ios_2/Zero/Services/ActionRegistry.swift');
const iosRegistryContent = fs.readFileSync(iosRegistryPath, 'utf8');

// Extract action IDs from iOS registry
const iosActionIdMatches = iosRegistryContent.matchAll(/actionId:\s*"([^"]+)"/g);
const iosActionIds = new Set(Array.from(iosActionIdMatches, m => m[1]));

// Find missing actions
const missingActions = Object.keys(ActionCatalog)
    .filter(id => !iosActionIds.has(id))
    .map(id => ActionCatalog[id]);

// Helper to determine mode
function getMode(action) {
    if (!action.validIntents || action.validIntents.length === 0) return '.both';

    const intents = action.validIntents.join(',');
    if (intents.includes('education') || intents.includes('youth') || intents.includes('healthcare')) {
        return '.mail';
    }
    return '.both';
}

// Helper to get priority
function getPriority(backendPriority) {
    if (backendPriority === 1) return 90;
    if (backendPriority === 2) return 85;
    if (backendPriority === 3) return 75;
    return 70;
}

// Helper to determine if IN_APP action should go to mailModeActions, adsModeActions, or sharedActions
function getArrayLocation(action) {
    if (action.actionType !== 'IN_APP') return 'goToActions';

    const mode = getMode(action);
    if (mode === '.mail') return 'mailModeActions';
    if (mode === '.ads') return 'adsModeActions';
    return 'sharedActions';
}

// Generate Swift code
function generateSwiftAction(action) {
    const actionType = action.actionType === 'GO_TO' ? '.goTo' : '.inApp';
    const mode = getMode(action);
    const modalComponent = action.actionType === 'IN_APP'
        ? `"${action.displayName.replace(/\s+/g, '')}Modal"`
        : 'nil';

    // Build required context keys
    let requiredKeys = [];
    if (action.actionType === 'GO_TO') {
        requiredKeys.push('"url"');
    }
    if (action.requiredEntities && action.requiredEntities.length > 0) {
        requiredKeys.push(...action.requiredEntities.map(e => `"${e}"`));
    }

    const requiredKeysStr = requiredKeys.length > 0
        ? `[${requiredKeys.join(', ')}]`
        : '[]';

    const priority = getPriority(action.priority);

    return `
            // ${action.displayName}
            ActionConfig(
                actionId: "${action.actionId}",
                displayName: "${action.displayName}",
                actionType: ${actionType},
                mode: ${mode},
                modalComponent: ${modalComponent},
                requiredContextKeys: ${requiredKeysStr},
                optionalContextKeys: [],
                fallbackBehavior: .showError,
                analyticsEvent: "action_${action.actionId}",
                priority: ${priority},
                description: "${action.description}"
            ),`;
}

// Group by array location
const grouped = {
    mailModeActions: [],
    adsModeActions: [],
    sharedActions: [],
    goToActions: []
};

missingActions.forEach(action => {
    const location = getArrayLocation(action);
    grouped[location].push(action);
});

// Output
console.log('═══════════════════════════════════════════════════════');
console.log('SWIFT CODE FOR MISSING ACTIONS');
console.log('═══════════════════════════════════════════════════════\n');

Object.keys(grouped).forEach(arrayName => {
    if (grouped[arrayName].length === 0) return;

    console.log(`\n\n// ===================================================================`);
    console.log(`// ADD TO: ${arrayName} array`);
    console.log(`// Count: ${grouped[arrayName].length} actions`);
    console.log(`// ===================================================================\n`);

    grouped[arrayName].forEach(action => {
        console.log(generateSwiftAction(action));
    });
});

console.log('\n\n═══════════════════════════════════════════════════════');
console.log('SUMMARY');
console.log('═══════════════════════════════════════════════════════\n');
console.log(`Total missing: ${missingActions.length}`);
console.log(`  - mailModeActions: ${grouped.mailModeActions.length}`);
console.log(`  - adsModeActions: ${grouped.adsModeActions.length}`);
console.log(`  - sharedActions: ${grouped.sharedActions.length}`);
console.log(`  - goToActions: ${grouped.goToActions.length}`);
console.log('');
