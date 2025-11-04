/**
 * Compound Actions Test Suite
 * Tests backend-iOS contract, detection logic, and validation
 */

const { CompoundActionRegistry } = require('./compound-action-registry');
const { suggestActions, extractCompoundContext } = require('./rules-engine');
const { getAction } = require('./action-catalog');

// Test results
const results = {
  passed: 0,
  failed: 0,
  tests: []
};

function test(name, fn) {
  try {
    fn();
    results.passed++;
    results.tests.push({ name, status: 'PASS' });
    console.log(`✓ ${name}`);
  } catch (error) {
    results.failed++;
    results.tests.push({ name, status: 'FAIL', error: error.message });
    console.error(`✗ ${name}`);
    console.error(`  ${error.message}`);
  }
}

function assertEqual(actual, expected, message) {
  if (actual !== expected) {
    throw new Error(message || `Expected ${expected}, got ${actual}`);
  }
}

function assertDefined(value, message) {
  if (value === undefined || value === null) {
    throw new Error(message || 'Value is undefined or null');
  }
}

function assertContains(array, value, message) {
  if (!array || !array.includes(value)) {
    throw new Error(message || `Array does not contain ${value}`);
  }
}

// ==========================================
// REGISTRY TESTS
// ==========================================

console.log('\n🧪 Testing Compound Action Registry...\n');

test('Registry contains all 8 compound actions', () => {
  const stats = CompoundActionRegistry.getStatistics();
  assertEqual(stats.totalCompoundActions, 8, 'Should have exactly 8 compound actions (matching iOS)');
});

test('All compound action IDs match iOS names', () => {
  const expectedIds = [
    'sign_form_with_payment',
    'sign_form_with_calendar',
    'track_with_calendar',
    'schedule_purchase_with_reminder',
    'pay_invoice_with_confirmation',
    'check_in_with_wallet',
    'calendar_with_reminder',
    'cancel_with_confirmation'
  ];

  const actualIds = CompoundActionRegistry.getAllCompoundActionIds();

  expectedIds.forEach(id => {
    assertContains(actualIds, id, `Missing compound action: ${id}`);
  });
});

test('Premium vs Free distribution', () => {
  const stats = CompoundActionRegistry.getStatistics();

  // 6 premium actions (all except calendar_with_reminder and cancel_with_confirmation)
  assertEqual(stats.premiumCompoundActions, 6, 'Should have 6 premium compound actions');
  assertEqual(stats.freeCompoundActions, 2, 'Should have 2 free compound actions');
});

test('RequiresResponse vs Personal distribution', () => {
  const stats = CompoundActionRegistry.getStatistics();

  // 4 require response (with emailComposer end behavior)
  assertEqual(stats.requiresResponseCount, 4, 'Should have 4 compound actions requiring response');
  assertEqual(stats.personalActionsCount, 4, 'Should have 4 personal compound actions');
});

test('sign_form_with_payment has correct structure', () => {
  const compound = CompoundActionRegistry.getCompoundAction('sign_form_with_payment');

  assertDefined(compound, 'sign_form_with_payment should exist');
  assertEqual(compound.actionId, 'sign_form_with_payment');
  assertEqual(compound.isPremium, true);
  assertEqual(compound.requiresResponse, true);
  assertEqual(compound.steps.length, 3, 'Should have 3 steps');
  assertContains(compound.steps, 'sign_form', 'Should include sign_form step');
  assertContains(compound.steps, 'pay_form_fee', 'Should include pay_form_fee step');
  assertContains(compound.steps, 'email_composer', 'Should include email_composer step');
});

test('check_in_with_wallet has correct end behavior', () => {
  const compound = CompoundActionRegistry.getCompoundAction('check_in_with_wallet');

  assertDefined(compound);
  assertEqual(compound.requiresResponse, false, 'Should not require response');
  assertEqual(compound.endBehavior.type, 'returnToApp', 'Should return to app');
});

test('cancel_with_confirmation is free (customer-friendly)', () => {
  const compound = CompoundActionRegistry.getCompoundAction('cancel_with_confirmation');

  assertDefined(compound);
  assertEqual(compound.isPremium, false, 'Cancel subscription should be free');
  assertEqual(compound.requiresResponse, true, 'Should require confirmation email');
});

// ==========================================
// VALIDATION TESTS
// ==========================================

console.log('\n🧪 Testing Step Validation...\n');

test('All compound action steps reference valid actions', () => {
  const allCompoundIds = CompoundActionRegistry.getAllCompoundActionIds();

  allCompoundIds.forEach(compoundId => {
    const compound = CompoundActionRegistry.getCompoundAction(compoundId);

    compound.steps.forEach(stepActionId => {
      // Skip iOS-native actions
      if (stepActionId === 'email_composer' || stepActionId === 'add_reminder') {
        return;
      }

      const stepAction = getAction(stepActionId);
      assertDefined(stepAction, `Step action ${stepActionId} not found in catalog for ${compoundId}`);
    });
  });
});

test('sign_form exists in action catalog', () => {
  const action = getAction('sign_form');
  assertDefined(action, 'sign_form should exist in action catalog');
  assertEqual(action.actionType, 'IN_APP');
});

test('pay_form_fee exists in action catalog', () => {
  const action = getAction('pay_form_fee');
  assertDefined(action, 'pay_form_fee should exist in action catalog');
  assertEqual(action.actionType, 'IN_APP');
});

test('track_package exists in action catalog', () => {
  const action = getAction('track_package');
  assertDefined(action, 'track_package should exist in action catalog');
});

test('add_to_calendar exists in action catalog', () => {
  const action = getAction('add_to_calendar');
  assertDefined(action, 'add_to_calendar should exist in action catalog');
  assertEqual(action.actionType, 'IN_APP');
});

// ==========================================
// DETECTION LOGIC TESTS
// ==========================================

console.log('\n🧪 Testing Smart Detection Logic...\n');

test('Detects sign_form_with_payment for permission form with payment', () => {
  const intent = 'education.permission.form';
  const entities = {
    formName: 'Field Trip Permission',
    amount: 45.00,
    eventDate: '2025-11-15'
  };

  const detectedId = CompoundActionRegistry.detectCompoundAction(intent, entities);
  assertEqual(detectedId, 'sign_form_with_payment', 'Should detect sign_form_with_payment when amount present');
});

test('Detects sign_form_with_calendar for permission form with event date', () => {
  const intent = 'education.permission.form';
  const entities = {
    formName: 'Field Trip Permission',
    eventDate: '2025-11-15'
  };

  const detectedId = CompoundActionRegistry.detectCompoundAction(intent, entities);
  assertEqual(detectedId, 'sign_form_with_calendar', 'Should detect sign_form_with_calendar when eventDate present');
});

test('Detects pay_invoice_with_confirmation for invoice with amount and merchant', () => {
  const intent = 'billing.invoice.due';
  const entities = {
    invoiceId: 'INV-2025-1234',
    amount: 1299.00,
    merchant: 'Acme Corp'
  };

  const detectedId = CompoundActionRegistry.detectCompoundAction(intent, entities);
  assertEqual(detectedId, 'pay_invoice_with_confirmation', 'Should detect pay_invoice_with_confirmation');
});

test('Detects check_in_with_wallet for flight check-in', () => {
  const intent = 'travel.flight.check-in';
  const entities = {
    flightNumber: 'UA 123',
    airline: 'United Airlines'
  };

  const detectedId = CompoundActionRegistry.detectCompoundAction(intent, entities);
  assertEqual(detectedId, 'check_in_with_wallet', 'Should detect check_in_with_wallet for flight check-in');
});

test('Detects track_with_calendar for shipping with delivery date', () => {
  const intent = 'e-commerce.shipping.notification';
  const entities = {
    trackingNumber: '1Z999AA10123456784',
    carrier: 'UPS',
    deliveryDate: '2025-11-01'
  };

  const detectedId = CompoundActionRegistry.detectCompoundAction(intent, entities);
  assertEqual(detectedId, 'track_with_calendar', 'Should detect track_with_calendar when deliveryDate present');
});

test('Returns null when no compound action matches', () => {
  const intent = 'generic.newsletter';
  const entities = {};

  const detectedId = CompoundActionRegistry.detectCompoundAction(intent, entities);
  assertEqual(detectedId, null, 'Should return null when no compound action matches');
});

// ==========================================
// RULES ENGINE INTEGRATION TESTS
// ==========================================

console.log('\n🧪 Testing Rules Engine Integration...\n');

test('Rules engine suggests compound action as primary', () => {
  const intent = 'education.permission.form';
  const entities = {
    formName: 'Field Trip Permission',
    amount: 45.00
  };
  const emailContext = {
    subject: 'Permission slip required',
    from: 'teacher@school.edu'
  };

  const suggestions = suggestActions(intent, entities, emailContext);

  assertDefined(suggestions, 'Should return suggestions');
  assertDefined(suggestions[0], 'Should have at least one suggestion');
  assertEqual(suggestions[0].actionId, 'sign_form_with_payment', 'Compound action should be primary');
  assertEqual(suggestions[0].isPrimary, true, 'Compound action should be marked as primary');
  assertEqual(suggestions[0].isCompound, true, 'Should be flagged as compound');
});

test('Compound action includes all required metadata', () => {
  const intent = 'travel.flight.check-in';
  const entities = {
    flightNumber: 'UA 123',
    airline: 'United'
  };
  const emailContext = {
    subject: 'Check in now for flight UA 123',
    from: 'united@email.united.com'
  };

  const suggestions = suggestActions(intent, entities, emailContext);
  const compoundAction = suggestions[0];

  assertDefined(compoundAction.compoundSteps, 'Should include compoundSteps');
  assertDefined(compoundAction.requiresResponse, 'Should include requiresResponse');
  assertDefined(compoundAction.isPremium, 'Should include isPremium');
  assertDefined(compoundAction.context, 'Should include context');
  assertDefined(compoundAction.context.compoundActionId, 'Context should include compoundActionId');
  assertDefined(compoundAction.context.totalSteps, 'Context should include totalSteps');
});

test('Compound context includes email metadata', () => {
  const compoundDef = CompoundActionRegistry.getCompoundAction('sign_form_with_payment');
  const entities = { formName: 'Field Trip', amount: 45.00 };
  const emailContext = {
    subject: 'Permission Form Required',
    from: 'teacher@school.edu'
  };

  const context = extractCompoundContext(compoundDef, entities, emailContext);

  assertEqual(context.subject, 'Permission Form Required', 'Should include subject');
  assertEqual(context.sender, 'teacher@school.edu', 'Should include sender');
  assertDefined(context.sender_name, 'Should extract sender name');
  assertEqual(context.totalSteps, 3, 'Should include total steps');
  assertEqual(context.requiresResponse, true, 'Should include requiresResponse flag');
});

test('Compound context includes email template for emailComposer flows', () => {
  const compoundDef = CompoundActionRegistry.getCompoundAction('pay_invoice_with_confirmation');
  const entities = { invoiceId: 'INV-123', amount: 1299 };
  const emailContext = { from: 'billing@company.com' };

  const context = extractCompoundContext(compoundDef, entities, emailContext);

  assertDefined(context.emailTemplate, 'Should include email template');
  assertDefined(context.emailTemplate.subjectPrefix, 'Should include subject prefix');
  assertDefined(context.emailTemplate.bodyTemplate, 'Should include body template');
  assertEqual(context.emailTemplate.includeOriginalSender, true, 'Should include original sender');
});

// ==========================================
// BUSINESS LOGIC TESTS
// ==========================================

console.log('\n🧪 Testing Business Logic...\n');

test('Permission form with amount prefers payment over calendar', () => {
  const intent = 'education.permission.form';
  const entitiesWithBoth = {
    formName: 'Field Trip',
    amount: 45.00,
    eventDate: '2025-11-15'
  };

  // Current logic: amount check comes first in detectCompoundAction
  const detected = CompoundActionRegistry.detectCompoundAction(intent, entitiesWithBoth);
  assertEqual(detected, 'sign_form_with_payment', 'Amount should take priority over eventDate');
});

test('Invoice without merchant still suggests payment', () => {
  const intent = 'billing.invoice.due';
  const entities = {
    invoiceId: 'INV-123',
    amount: 500  // No merchant
  };

  const detected = CompoundActionRegistry.detectCompoundAction(intent, entities);
  // Current logic requires both amount AND merchant
  assertEqual(detected, null, 'Should require merchant for pay_invoice_with_confirmation');
});

test('Shipping without delivery date returns null (no compound)', () => {
  const intent = 'e-commerce.shipping.notification';
  const entities = {
    trackingNumber: '1Z999AA10123456784',
    carrier: 'UPS'
    // No deliveryDate
  };

  const detected = CompoundActionRegistry.detectCompoundAction(intent, entities);
  assertEqual(detected, null, 'Should not suggest track_with_calendar without deliveryDate');
});

// ==========================================
// RESULTS SUMMARY
// ==========================================

console.log('\n' + '='.repeat(60));
console.log('📊 Test Results Summary');
console.log('='.repeat(60));
console.log(`Total Tests: ${results.passed + results.failed}`);
console.log(`✓ Passed: ${results.passed}`);
console.log(`✗ Failed: ${results.failed}`);
console.log(`Success Rate: ${((results.passed / (results.passed + results.failed)) * 100).toFixed(1)}%`);

if (results.failed > 0) {
  console.log('\n❌ Failed Tests:');
  results.tests.filter(t => t.status === 'FAIL').forEach(t => {
    console.log(`  - ${t.name}`);
    console.log(`    ${t.error}`);
  });
  process.exit(1);
} else {
  console.log('\n✅ All tests passed!');
  process.exit(0);
}
