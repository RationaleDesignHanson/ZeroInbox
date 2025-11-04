#!/usr/bin/env node
/**
 * Action Coverage Validation Test
 *
 * Validates that all actions from action-catalog.js are properly mapped in:
 * 1. iOS ContentView.swift switch statement
 * 2. app-demo.html MODAL_FLOWS
 * 3. zero-sequence-live.html MODAL_FLOWS
 *
 * Run: node validate-action-coverage.js
 */

const fs = require('fs');
const path = require('path');

// Colors for terminal output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  bold: '\x1b[1m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// Extract all action IDs from action-catalog.js
function getActionCatalogIds() {
  const catalogPath = path.join(__dirname, '../services/actions/action-catalog.js');
  const content = fs.readFileSync(catalogPath, 'utf-8');

  // Match action definitions like "  track_package: {"
  const actionPattern = /^\s+([a-z_]+):\s*{$/gm;
  const matches = [...content.matchAll(actionPattern)];

  const actionIds = matches
    .map(match => match[1])
    .filter(id => !['getAction', 'getActionsForIntent', 'canExecuteAction', 'getAllActionIds'].includes(id));

  return actionIds;
}

// Check iOS ContentView.swift coverage
function checkIOSCoverage(actionIds) {
  const contentViewPath = path.join(__dirname, '../../Zero_ios_2/Zero/Zero/ContentView.swift');

  if (!fs.existsSync(contentViewPath)) {
    log('⚠ Warning: ContentView.swift not found at expected path', 'yellow');
    return { missing: [], present: [], coverage: 0 };
  }

  const content = fs.readFileSync(contentViewPath, 'utf-8');

  const missing = [];
  const present = [];

  for (const actionId of actionIds) {
    // Check if action is in a case statement
    // Handles:
    // 1. case "action_id":
    // 2. case "action_id", "other_id":
    // 3. case "other_id", "action_id":
    // 4. case "other_id", "action_id", "another_id":
    const patterns = [
      new RegExp(`case\\s+"${actionId}"\\s*:`, 'g'),           // case "action_id":
      new RegExp(`case\\s+"${actionId}"\\s*,`, 'g'),           // case "action_id",
      new RegExp(`,\\s*"${actionId}"\\s*:`, 'g'),              // , "action_id":
      new RegExp(`,\\s*"${actionId}"\\s*,`, 'g')               // , "action_id",
    ];

    const found = patterns.some(pattern => pattern.test(content));

    if (found) {
      present.push(actionId);
    } else {
      missing.push(actionId);
    }
  }

  return {
    missing,
    present,
    coverage: (present.length / actionIds.length) * 100
  };
}

// Check website HTML file coverage
function checkWebsiteCoverage(filePath, actionIds) {
  if (!fs.existsSync(filePath)) {
    log(`⚠ Warning: ${path.basename(filePath)} not found`, 'yellow');
    return { missing: [], present: [], coverage: 0 };
  }

  const content = fs.readFileSync(filePath, 'utf-8');

  const missing = [];
  const present = [];

  for (const actionId of actionIds) {
    // Check if action exists anywhere in the file (MODAL_FLOWS, executeSwipeAction, etc.)
    if (content.includes(`'${actionId}':`) || content.includes(`"${actionId}":`)) {
      present.push(actionId);
    } else {
      missing.push(actionId);
    }
  }

  return {
    missing,
    present,
    coverage: (present.length / actionIds.length) * 100
  };
}

// Main validation
function validateCoverage() {
  log('\n=== Action Coverage Validation Test ===\n', 'bold');

  // Get all action IDs from catalog
  const actionIds = getActionCatalogIds();
  log(`📋 Total actions in catalog: ${actionIds.length}`, 'blue');

  let allTestsPassed = true;
  const results = {};

  // Test 1: iOS ContentView.swift
  log('\n1️⃣  Checking iOS ContentView.swift...', 'bold');
  const iosResult = checkIOSCoverage(actionIds);
  results.ios = iosResult;

  if (iosResult.coverage === 100) {
    log(`   ✓ All ${actionIds.length} actions mapped (100%)`, 'green');
  } else {
    log(`   ✗ Missing ${iosResult.missing.length} actions (${iosResult.coverage.toFixed(1)}%)`, 'red');
    log(`   Missing: ${iosResult.missing.slice(0, 10).join(', ')}${iosResult.missing.length > 10 ? '...' : ''}`, 'yellow');
    allTestsPassed = false;
  }

  // Test 2: app-demo.html
  log('\n2️⃣  Checking app-demo.html...', 'bold');
  const appDemoPath = path.join(__dirname, '../dashboard/app-demo.html');
  const appDemoResult = checkWebsiteCoverage(appDemoPath, actionIds);
  results.appDemo = appDemoResult;

  if (appDemoResult.coverage === 100) {
    log(`   ✓ All ${actionIds.length} actions present (100%)`, 'green');
  } else {
    log(`   ✗ Missing ${appDemoResult.missing.length} actions (${appDemoResult.coverage.toFixed(1)}%)`, 'red');
    log(`   Missing: ${appDemoResult.missing.slice(0, 10).join(', ')}${appDemoResult.missing.length > 10 ? '...' : ''}`, 'yellow');
    allTestsPassed = false;
  }

  // Test 3: zero-sequence-live.html
  log('\n3️⃣  Checking zero-sequence-live.html...', 'bold');
  const zeroSeqPath = path.join(__dirname, '../dashboard/zero-sequence-live.html');
  const zeroSeqResult = checkWebsiteCoverage(zeroSeqPath, actionIds);
  results.zeroSeq = zeroSeqResult;

  if (zeroSeqResult.coverage === 100) {
    log(`   ✓ All ${actionIds.length} actions present (100%)`, 'green');
  } else {
    log(`   ✗ Missing ${zeroSeqResult.missing.length} actions (${zeroSeqResult.coverage.toFixed(1)}%)`, 'red');
    log(`   Missing: ${zeroSeqResult.missing.slice(0, 10).join(', ')}${zeroSeqResult.missing.length > 10 ? '...' : ''}`, 'yellow');
    allTestsPassed = false;
  }

  // Summary
  log('\n' + '='.repeat(50), 'bold');
  log('📊 Coverage Summary:', 'bold');
  log(`   iOS ContentView:          ${iosResult.present.length}/${actionIds.length} (${iosResult.coverage.toFixed(1)}%)`,
      iosResult.coverage === 100 ? 'green' : 'red');
  log(`   app-demo.html:            ${appDemoResult.present.length}/${actionIds.length} (${appDemoResult.coverage.toFixed(1)}%)`,
      appDemoResult.coverage === 100 ? 'green' : 'red');
  log(`   zero-sequence-live.html:  ${zeroSeqResult.present.length}/${actionIds.length} (${zeroSeqResult.coverage.toFixed(1)}%)`,
      zeroSeqResult.coverage === 100 ? 'green' : 'red');

  log('\n' + '='.repeat(50) + '\n', 'bold');

  if (allTestsPassed) {
    log('✅ ALL TESTS PASSED! Complete action coverage across all systems.', 'green');
    return 0;
  } else {
    log('❌ TESTS FAILED! Some actions are not properly mapped.', 'red');
    log('\n💡 Tip: Run this test after modifying action-catalog.js to ensure coverage.', 'yellow');
    return 1;
  }
}

// Run validation
const exitCode = validateCoverage();
process.exit(exitCode);
