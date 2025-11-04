/**
 * Diagnostic script to identify mock template issues
 */

const { getAllTemplateIds, getTemplateById, classifyEmailMock } = require('./mock-classifier');
const { IntentTaxonomy } = require('./shared/models/Intent');

const templateIds = getAllTemplateIds();

console.log(`\n=== DIAGNOSTIC REPORT ===\n`);
console.log(`Total templates: ${templateIds.length}\n`);

// Issue 1: Find intents not in taxonomy
console.log('1. INTENTS NOT IN TAXONOMY:');
const missingIntents = new Set();

templateIds.forEach(templateId => {
  const template = getTemplateById(templateId);
  const intent = template.expectedIntent;

  if (!IntentTaxonomy[intent]) {
    missingIntents.add(intent);
    console.log(`   ❌ ${intent} (template: ${templateId})`);
  }
});

if (missingIntents.size === 0) {
  console.log('   ✅ All intents exist in taxonomy');
}

// Issue 2: Check template ID matching
console.log('\n2. TEMPLATE ID MISMATCHES:');
let mismatchCount = 0;

templateIds.forEach(templateId => {
  const template = getTemplateById(templateId);
  const email = {
    subject: template.subject,
    from: template.from,
    body: template.body
  };

  const classification = classifyEmailMock(email);

  if (classification.mockTemplateId !== templateId) {
    mismatchCount++;
    console.log(`   ⚠️  Template ${templateId} matched as ${classification.mockTemplateId}`);
  }
});

console.log(`   ${mismatchCount} templates matched to different template ID`);

// Issue 3: Missing entities
console.log('\n3. MISSING ENTITIES:');
let entityIssueCount = 0;

templateIds.forEach(templateId => {
  const template = getTemplateById(templateId);

  if (!template.expectedEntities || template.expectedEntities.length === 0) {
    return;
  }

  const email = {
    subject: template.subject,
    from: template.from,
    body: template.body
  };

  const classification = classifyEmailMock(email);
  const missingEntities = [];

  template.expectedEntities.forEach(entityName => {
    if (!classification.entities[entityName]) {
      missingEntities.push(entityName);
    }
  });

  if (missingEntities.length > 0) {
    entityIssueCount++;
    console.log(`   ❌ ${templateId}: missing [${missingEntities.join(', ')}]`);
  }
});

if (entityIssueCount === 0) {
  console.log('   ✅ All entities generated correctly');
}

console.log('\n=== END DIAGNOSTIC REPORT ===\n');
