# Zero Inbox Test Data & Infrastructure

This directory contains all test data, utilities, and matrices for comprehensive testing of the Zero Inbox v1.9 system.

## Generated: 2025-11-03

---

## 📦 System Inventory Files

### 1. `system-inventory.json` (209.5 KB)
Complete snapshot of the entire system with all components and relationships.

**Contents**:
- 138 actions with full metadata
- 134 intents with 1,285 trigger phrases
- 9 compound actions
- Intent → Action mappings
- Action → Intent mappings
- Intent → Compound Action mappings

**Usage**:
```javascript
const inventory = require('./system-inventory.json');
console.log(`Total Actions: ${inventory.summary.totalActions}`);
console.log(`Total Intents: ${inventory.summary.totalIntents}`);
```

---

## 📊 Component Lists (CSV)

### 2. `actions-complete-list.csv` (138 rows)
All 138 actions with metadata.

**Columns**: actionId, displayName, actionType, description, requiredEntities, validIntents, priority, urlTemplate, isGeneric, category

**Statistics**:
- GO_TO actions: 96
- IN_APP actions: 42
- Generic actions: 4
- Actions with required entities: 84
- Actions with URL templates: 95

### 3. `intents-complete-list.csv` (134 rows)
All 134 intents with triggers and entity requirements.

**Columns**: intentId, category, subCategory, action, description, triggerCount, triggers, negativePatternCount, negativePatterns, requiredEntities, optionalEntities, confidence

**Statistics**:
- Total trigger phrases: 1,285
- Avg triggers per intent: 9.6
- Intents with required entities: 78
- Intents with optional entities: 129

### 4. `compound-actions-complete-list.csv` (9 rows)
All 9 compound (multi-step) actions.

**Columns**: actionId, displayName, stepCount, steps, endBehaviorType, requiresResponse, isPremium, description, category

**Statistics**:
- Total steps: 20
- Avg steps per action: 2.2
- Premium actions: 6
- Free actions: 3
- Requires email response: 5
- Personal actions: 4

---

## 🎯 Test Matrices (Coverage Tracking)

### 5. `ACTION_COVERAGE_MATRIX.csv` (138 rows)
Tracks test coverage for all 138 actions across all test phases.

**Columns**: actionId, displayName, actionType, category, phase1_classification, phase1_notes, phase2_mock_mode, phase2_ios_integration, phase2_notes, phase3_corpus_testing, phase3_notes, phase4_performance, phase4_analytics, phase4_notes, overall_status, priority

**Usage**: Update status values as tests are executed.

**Status Values**:
- `not_tested` = Not yet tested
- `pass` = Test passed
- `fail` = Test failed (investigate)
- `skip` = Intentionally skipped
- `not_started` = Overall status

### 6. `INTENT_COVERAGE_MATRIX.csv` (134 rows)
Tracks test coverage for all 134 intents.

**Columns**: intentId, category, triggerCount, actionCount, phase1_trigger_validation, phase1_classification_accuracy, phase1_action_routing, phase1_notes, phase3_corpus_sample_count, phase3_accuracy, phase3_notes, overall_status, confidence_threshold

### 7. `COMPOUND_ACTION_MATRIX.csv` (9 rows)
Tracks test coverage for all 9 compound actions.

**Columns**: compoundActionId, displayName, stepCount, steps, requiresResponse, isPremium, phase1_step_validation, phase1_sequencing_test, phase1_notes, phase2_modal_flow_test, phase2_end_behavior_test, phase2_notes, phase3_real_world_test, phase3_notes, overall_status

### 8. `ENTITY_EXTRACTION_MATRIX.csv` (242 rows)
Tracks extraction accuracy for 242 entity types.

**Columns**: entityType, usedByIntentCount, phase1_extraction_test, phase1_format_validation, phase1_notes, phase3_corpus_accuracy, phase3_edge_cases, phase3_notes, overall_status

### 9. `PLATFORM_PARITY_MATRIX.csv` (15 rows)
Tracks parity between authenticated mode and mock mode.

**Columns**: feature, component, type, authenticated_user_test, authenticated_notes, mock_mode_test, mock_notes, parity_status, discrepancies, overall_status

---

## 📧 Email Corpus Tools

### 10. `corpus-parser.js`
Node.js utility to parse Gmail mbox files and extract emails.

**Features**:
- Parse 41GB email corpus (mbox format)
- Extract email metadata (subject, from, body, date)
- Stratified sampling
- Generate corpus statistics
- Save samples to JSON

**Usage**:
```bash
# Sample 1000 emails from corpus
node corpus-parser.js /path/to/corpus 1000 output.json

# Or use programmatically
const CorpusParser = require('./corpus-parser');
const parser = new CorpusParser('/path/to/corpus');
const emails = await parser.sampleEmails({ sampleSize: 1000 });
```

**Corpus Location**: `/Users/matthanson/Downloads/emailsfordeepsampling/Takeout/Mail`

**Corpus Statistics**:
- Total size: 41GB
- Format: Gmail mbox (Gmail Takeout)
- Files:
  - Inbox-002.mbox: 26GB
  - Sent-003.mbox: 4.2GB
  - Inbox-001.mbox: 2.8GB
  - Opened2/3.mbox: 1.8GB each
  - Plus 28,108 individual email files

### 11. `test-email-templates.json`
20 curated test email templates covering key scenarios.

**Templates Include**:
- E-commerce (shipping, orders)
- Healthcare (appointments, prescriptions)
- Billing (invoices, subscriptions)
- Travel (flight check-in, reservations)
- Education (permission forms, assignments)
- Marketing (promotions, newsletters)
- Compound actions (multi-step flows)
- Edge cases (HTML-only, no subject, special chars)

**Usage**:
```javascript
const templates = require('./test-email-templates.json');
const email = templates.templates.healthcare_appointment_reminder;
console.log(email.expectedIntent); // healthcare.appointment.reminder
console.log(email.expectedPrimaryAction); // calendar_with_reminder
```

---

## 🧪 Test Infrastructure

### 12. `jest.config.js` (in backend root)
Jest configuration with coverage thresholds.

**Coverage Targets**:
- Global: 60% statements, 55% branches
- Classifier service: 75% statements, 70% branches
- Rules engine: 80% statements, 75% branches
- Action catalog: 65% statements
- Intent taxonomy: 70% statements

**Run Tests**:
```bash
npm test                    # Run all tests
npm test -- --coverage      # Run with coverage report
npm test -- --watch         # Watch mode
npm test classifier         # Run specific test suite
```

### 13. `test-utils/jest.setup.js`
Jest setup file with custom matchers and helpers.

**Custom Matchers**:
- `toBeValidIntent(intentId)` - Check if intent exists
- `toBeValidAction(actionId)` - Check if action exists
- `toHaveEntities(expected)` - Validate entity extraction
- `toBeValidClassification()` - Validate classification result

**Global Helpers**:
- `testHelpers.createMockEmail(overrides)` - Generate mock email
- `testHelpers.loadEmailTemplate(name)` - Load template
- `testHelpers.wait(ms)` - Async wait utility

**Usage**:
```javascript
test('intent should be valid', () => {
  expect('healthcare.appointment.reminder').toBeValidIntent();
});

test('classification should be valid', () => {
  const result = classifyIntent(email);
  expect(result).toBeValidClassification();
  expect(result.entities).toHaveEntities(['provider', 'appointmentDate']);
});
```

### 14. `test-utils/test-data-generator.js`
Programmatic test data generation utilities.

**Features**:
- Generate emails for specific intents
- Generate classification results
- Generate test batches
- Generate edge cases

**Usage**:
```javascript
const TestDataGenerator = require('./test-data-generator');

// Generate email for specific intent
const email = TestDataGenerator.generateEmailForIntent('healthcare.appointment.reminder');

// Generate batch of test emails
const batch = TestDataGenerator.generateTestBatch({
  intentCount: 10,
  emailsPerIntent: 2
});

// Generate edge cases
const edgeCases = TestDataGenerator.generateEdgeCases();
```

---

## 📁 Extraction Scripts

All scripts in this directory are executable and can be run individually:

```bash
# Extract actions (regenerate CSV)
node extract-actions.js

# Extract intents (regenerate CSV)
node extract-intents.js

# Extract compound actions (regenerate CSV)
node extract-compound-actions.js

# Regenerate system inventory JSON
node create-system-inventory.js

# Regenerate all test matrices
node create-test-matrices.js
```

---

## 🚀 Quick Start Guide

### 1. Run Existing Tests
```bash
cd backend
npm test
```

### 2. Generate Coverage Report
```bash
npm test -- --coverage
open coverage/index.html
```

### 3. Sample Email Corpus
```bash
cd test-data
node corpus-parser.js
```

### 4. Use Test Templates in Tests
```javascript
const templates = require('./test-data/test-email-templates.json');
const { classifyIntent } = require('./services/classifier/intent-classifier');

test('should classify appointment reminder', () => {
  const email = templates.templates.healthcare_appointment_reminder;
  const result = classifyIntent(email);
  expect(result.intent).toBe(email.expectedIntent);
  expect(result.actions[0].actionId).toBe(email.expectedPrimaryAction);
});
```

### 5. Track Test Progress
Open and update the test matrices as you execute tests:
- `ACTION_COVERAGE_MATRIX.csv` - Update action test status
- `INTENT_COVERAGE_MATRIX.csv` - Update intent test status
- `COMPOUND_ACTION_MATRIX.csv` - Update compound action test status

---

## 📈 Test Execution Phases

### Phase 1: Core Classification Testing (5-6 days)
**Matrices**: `INTENT_COVERAGE_MATRIX.csv`, `ACTION_COVERAGE_MATRIX.csv`, `ENTITY_EXTRACTION_MATRIX.csv`

1. Test all 134 intents with trigger validation
2. Test all 138 actions with routing validation
3. Test all 242 entity types with extraction accuracy
4. Test all 9 compound actions with sequencing

### Phase 2: Platform Parity & Mock Mode (4-5 days)
**Matrices**: `PLATFORM_PARITY_MATRIX.csv`, `ACTION_COVERAGE_MATRIX.csv`

1. Test all 138 actions in mock mode
2. Test iOS integration (calendar, notes, wallet)
3. Validate authenticated vs mock parity

### Phase 3: Corpus Processing & Real-World Testing (6-7 days)
**Tool**: `corpus-parser.js`
**Matrices**: All matrices (accuracy updates)

1. Process 41GB email corpus
2. Measure classification accuracy on real emails
3. Identify edge cases and failures

### Phase 4: Performance, Analytics & Final Validation (4-5 days)
**Matrices**: `ACTION_COVERAGE_MATRIX.csv`

1. Performance testing (latency, throughput)
2. Analytics validation
3. Final integration testing

---

## 📊 System Statistics Summary

```
Total Actions: 138
├── GO_TO: 96
└── IN_APP: 42

Total Intents: 134
├── Total Triggers: 1,285
└── Avg Triggers/Intent: 9.6

Total Compound Actions: 9
├── Premium: 6
└── Free: 3

Total Entity Types: 242

Email Corpus: 41GB
├── Format: Gmail mbox
└── Files: 6 mbox files + 28,108 individual emails
```

---

## 🔗 Related Documentation

- Test plan: `/Users/matthanson/Desktop/completeendtoendtest.txt`
- Dashboard: https://zero-dashboard-hqdlmnyzrq-uc.a.run.app/
- Backend: `/Users/matthanson/Zer0_Inbox/backend/`
- Classifier: `/Users/matthanson/Zer0_Inbox/backend/services/classifier/`
- Actions: `/Users/matthanson/Zer0_Inbox/backend/services/actions/`

---

## ✅ Deliverables Checklist

- [x] 138 actions extracted to CSV
- [x] 134 intents extracted to CSV
- [x] 9 compound actions extracted to CSV
- [x] System inventory JSON (209.5 KB)
- [x] 5 test matrices generated
- [x] Corpus parser utility created
- [x] 20 test email templates created
- [x] Jest configuration with coverage thresholds
- [x] Jest setup with custom matchers
- [x] Test data generator utility
- [ ] Web tools documented (pending)
- [ ] Phase 1 tests executed (pending)
- [ ] Phase 2 tests executed (pending)
- [ ] Phase 3 corpus processing (pending)
- [ ] Phase 4 performance testing (pending)

---

Generated: 2025-11-03T01:24:00Z
Version: 1.9.0
