/**
 * Comprehensive Action Validation Script
 * Validates iOS ActionRegistry for consistency, duplicates, and design debt
 */

const { ActionCatalog } = require('./backend/dashboard/action-catalog.js');
const fs = require('fs');
const path = require('path');

// Read iOS ActionRegistry.swift
const iosRegistryPath = path.join(__dirname, 'Zero_ios_2/Zero/Services/ActionRegistry.swift');
const iosRegistryContent = fs.readFileSync(iosRegistryPath, 'utf8');

console.log('═══════════════════════════════════════════════════════');
console.log('COMPREHENSIVE ACTION VALIDATION');
console.log('═══════════════════════════════════════════════════════\n');

// Extract all actions from iOS registry
const actionMatches = [...iosRegistryContent.matchAll(/ActionConfig\s*\(([\s\S]*?)\),\s*\n/g)];
const iosActions = [];

actionMatches.forEach(match => {
    const configText = match[1];
    const actionIdMatch = configText.match(/actionId:\s*"([^"]+)"/);
    const displayNameMatch = configText.match(/displayName:\s*"([^"]+)"/);
    const actionTypeMatch = configText.match(/actionType:\s*\.(\w+)/);
    const modeMatch = configText.match(/mode:\s*\.(\w+)/);
    const modalComponentMatch = configText.match(/modalComponent:\s*"?([^",\n]+)"?/);
    const requiredKeysMatch = configText.match(/requiredContextKeys:\s*\[([^\]]*)\]/);
    const priorityMatch = configText.match(/priority:\s*(\d+)/);

    if (actionIdMatch) {
        iosActions.push({
            actionId: actionIdMatch[1],
            displayName: displayNameMatch ? displayNameMatch[1] : 'MISSING',
            actionType: actionTypeMatch ? actionTypeMatch[1] : 'MISSING',
            mode: modeMatch ? modeMatch[1] : 'MISSING',
            modalComponent: modalComponentMatch ? modalComponentMatch[1].trim() : 'nil',
            requiredKeys: requiredKeysMatch ? requiredKeysMatch[1].split(',').map(k => k.trim().replace(/"/g, '')).filter(k => k) : [],
            priority: priorityMatch ? parseInt(priorityMatch[1]) : 0
        });
    }
});

console.log(`✅ Extracted ${iosActions.length} actions from iOS registry\n`);

// Validation checks
let issues = [];
let warnings = [];

// 1. Check for duplicate action IDs
console.log('🔍 CHECK 1: Duplicate Action IDs');
const actionIdCounts = {};
iosActions.forEach(action => {
    actionIdCounts[action.actionId] = (actionIdCounts[action.actionId] || 0) + 1;
});
const duplicates = Object.entries(actionIdCounts).filter(([id, count]) => count > 1);
if (duplicates.length > 0) {
    duplicates.forEach(([id, count]) => {
        issues.push(`❌ DUPLICATE: "${id}" appears ${count} times`);
    });
} else {
    console.log('   ✅ No duplicate action IDs found\n');
}

// 2. Check for inconsistent naming
console.log('🔍 CHECK 2: Naming Consistency (actionId vs displayName)');
iosActions.forEach(action => {
    const expectedId = action.displayName.toLowerCase().replace(/\s+/g, '_');
    if (action.actionId !== expectedId && !action.displayName.includes('MISSING')) {
        warnings.push(`⚠️  "${action.actionId}" display name "${action.displayName}" doesn't match pattern`);
    }
});
if (warnings.length === 0) {
    console.log('   ✅ All action naming is consistent\n');
}

// 3. Check GO_TO actions have URL in requiredContextKeys
console.log('🔍 CHECK 3: GO_TO Actions Must Have URL');
const goToWithoutUrl = iosActions.filter(action =>
    action.actionType === 'goTo' &&
    !action.requiredKeys.includes('url') &&
    !action.requiredKeys.some(k => k.includes('Url'))
);
if (goToWithoutUrl.length > 0) {
    goToWithoutUrl.forEach(action => {
        issues.push(`❌ GO_TO action "${action.actionId}" missing URL in requiredContextKeys`);
    });
} else {
    console.log('   ✅ All GO_TO actions have proper URL keys\n');
}

// 4. Check IN_APP actions have modal components
console.log('🔍 CHECK 4: IN_APP Actions Must Have Modal Component');
const inAppWithoutModal = iosActions.filter(action =>
    action.actionType === 'inApp' &&
    (action.modalComponent === 'nil' || !action.modalComponent || action.modalComponent === '')
);
if (inAppWithoutModal.length > 0) {
    inAppWithoutModal.forEach(action => {
        issues.push(`❌ IN_APP action "${action.actionId}" missing modalComponent`);
    });
} else {
    console.log('   ✅ All IN_APP actions have modal components\n');
}

// 5. Check priority ranges (should be 60-95)
console.log('🔍 CHECK 5: Priority Ranges (60-95)');
const invalidPriorities = iosActions.filter(action => action.priority < 60 || action.priority > 95);
if (invalidPriorities.length > 0) {
    invalidPriorities.forEach(action => {
        warnings.push(`⚠️  "${action.actionId}" has priority ${action.priority} (should be 60-95)`);
    });
} else {
    console.log('   ✅ All priorities are within valid range\n');
}

// 6. Compare with backend catalog
console.log('🔍 CHECK 6: Backend Consistency');
const backendActionIds = new Set(Object.keys(ActionCatalog));
const iosActionIds = new Set(iosActions.map(a => a.actionId));

iosActions.forEach(action => {
    const backendAction = ActionCatalog[action.actionId];
    if (backendAction) {
        // Check actionType matches
        const expectedType = backendAction.actionType === 'GO_TO' ? 'goTo' : 'inApp';
        if (action.actionType !== expectedType) {
            issues.push(`❌ "${action.actionId}" type mismatch: iOS="${action.actionType}" Backend="${expectedType}"`);
        }

        // Check displayName matches
        if (action.displayName !== backendAction.displayName) {
            warnings.push(`⚠️  "${action.actionId}" displayName mismatch: iOS="${action.displayName}" Backend="${backendAction.displayName}"`);
        }
    }
});
console.log('   ✅ Backend consistency check complete\n');

// 7. Check for MISSING placeholders
console.log('🔍 CHECK 7: Incomplete Action Definitions');
const incomplete = iosActions.filter(action =>
    action.displayName === 'MISSING' ||
    action.actionType === 'MISSING' ||
    action.mode === 'MISSING'
);
if (incomplete.length > 0) {
    incomplete.forEach(action => {
        issues.push(`❌ "${action.actionId}" has incomplete definition`);
    });
} else {
    console.log('   ✅ No incomplete action definitions\n');
}

// Summary
console.log('\n═══════════════════════════════════════════════════════');
console.log('VALIDATION SUMMARY');
console.log('═══════════════════════════════════════════════════════\n');

console.log(`Total Actions: ${iosActions.length}`);
console.log(`Issues Found: ${issues.length}`);
console.log(`Warnings: ${warnings.length}\n`);

if (issues.length > 0) {
    console.log('❌ CRITICAL ISSUES:\n');
    issues.forEach(issue => console.log('   ' + issue));
    console.log('');
}

if (warnings.length > 0) {
    console.log('⚠️  WARNINGS:\n');
    warnings.slice(0, 10).forEach(warning => console.log('   ' + warning));
    if (warnings.length > 10) {
        console.log(`   ... and ${warnings.length - 10} more warnings`);
    }
    console.log('');
}

if (issues.length === 0 && warnings.length === 0) {
    console.log('✅ ALL VALIDATION CHECKS PASSED!\n');
}

// Coverage stats
const missing = Array.from(backendActionIds).filter(id => !iosActionIds.has(id));
console.log('COVERAGE:');
console.log(`  Backend: ${backendActionIds.size} actions`);
console.log(`  iOS: ${iosActionIds.size} actions`);
console.log(`  Missing: ${missing.length} actions`);
console.log(`  Coverage: ${(iosActionIds.size / backendActionIds.size * 100).toFixed(1)}%\n`);

console.log('═══════════════════════════════════════════════════════\n');

// Exit with error code if issues found
process.exit(issues.length > 0 ? 1 : 0);
