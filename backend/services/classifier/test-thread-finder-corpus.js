/**
 * Test Thread Finder Detection on Real Email Corpus
 * Validates that link-only intents are properly detected
 *
 * Tests two scenarios:
 * 1. Real corpus email with content (should NOT be link-only)
 * 2. Mock link-only templates (should trigger Thread Finder)
 */

const fs = require('fs');
const path = require('path');
const { classifyEmailActionFirst } = require('./action-first-classifier');
const { enrichWithThreadFinder, isLinkHeavyEmail } = require('./thread-finder-middleware');

// Read real Canvas email from corpus
const corpusPath = '/Users/matthanson/Downloads/emailsfordeepsampling/Takeout/Mail/opened_emails/email_00021.eml';
const rawEmail = fs.readFileSync(corpusPath, 'utf8');

// Load mock templates
const mockTemplatesPath = path.join(__dirname, '../../test-data/mock-email-templates.json');
const mockTemplates = JSON.parse(fs.readFileSync(mockTemplatesPath, 'utf8'));

// Parse EML format (simple extraction)
function parseEML(emlContent) {
  const lines = emlContent.split('\n');
  let subject = '';
  let from = '';
  let body = '';
  let inBody = false;

  for (const line of lines) {
    if (line.startsWith('Subject: ')) {
      subject = line.substring('Subject: '.length).trim();
    } else if (line.startsWith('From: ')) {
      from = line.substring('From: '.length).trim();
    } else if (line === '' && !inBody) {
      inBody = true;
    } else if (inBody && !line.startsWith('--') && !line.startsWith('Content-')) {
      body += line + '\n';
    }
  }

  // Extract plain text from multipart email
  const plainTextMatch = body.match(/Content-Type: text\/plain;[\s\S]*?\n\n([\s\S]*?)(?=\n\n----|$)/);
  if (plainTextMatch) {
    body = plainTextMatch[1].trim();
  }

  return { subject, from, body };
}

async function testCorpusEmail() {
  console.log('\n=== Test 1: Real Corpus Email (Should NOT be link-only) ===\n');

  const email = parseEML(rawEmail);

  console.log('📧 Real Email from Corpus:');
  console.log(`Subject: ${email.subject}`);
  console.log(`From: ${email.from}`);
  console.log(`Body length: ${email.body.length} chars`);
  console.log(`Is link-heavy: ${isLinkHeavyEmail(email)}\n`);

  // Classify email
  console.log('⚙️  Classifying email...');
  const classification = await classifyEmailActionFirst(email);
  console.log(`✅ Intent: ${classification.intent}`);
  console.log(`   Confidence: ${classification.intentConfidence}`);
  console.log(`   Is link-only: ${classification.intent?.includes('link-only')}\n`);

  // This email has substantial content, so it should NOT be link-only
  const passed = !classification.intent?.includes('link-only');
  console.log(passed
    ? '✅ PASSED: Email correctly NOT classified as link-only (has content)'
    : '❌ FAILED: Email incorrectly classified as link-only');

  return passed;
}

async function testMockLinkOnlyEmail() {
  console.log('\n=== Test 2: Mock Link-Only Template (Should BE link-only) ===\n');

  // Use canvas_link_only_01 template
  const template = mockTemplates.templates.canvas_link_only_01;
  const email = {
    subject: template.subject,
    from: template.from,
    body: template.body,
    snippet: template.body.substring(0, 500)
  };

  console.log('📧 Mock Link-Only Email:');
  console.log(`Subject: ${email.subject}`);
  console.log(`From: ${email.from}`);
  console.log(`Body length: ${email.body.length} chars`);
  console.log(`Is link-heavy: ${isLinkHeavyEmail(email)}`);
  console.log(`Expected intent: ${template.expectedIntent}\n`);

  // Classify email
  console.log('⚙️  Classifying email...');
  const classification = await classifyEmailActionFirst(email);
  console.log(`✅ Intent: ${classification.intent}`);
  console.log(`   Confidence: ${classification.intentConfidence}`);
  console.log(`   Is link-only: ${classification.intent?.includes('link-only')}\n`);

  // Check if Thread Finder would process
  if (classification.intent?.includes('link-only')) {
    console.log('✅ Thread Finder would be triggered');
    console.log('   - Link-only intent detected');
    console.log('   - Would extract from Canvas API\n');

    // Check suggested actions
    if (classification.suggestedActions && classification.suggestedActions.length > 0) {
      console.log('✅ Suggested actions:');
      classification.suggestedActions.slice(0, 3).forEach((action, i) => {
        console.log(`   ${i + 1}. ${action.displayName} (${action.actionType})`);
      });
    }
  } else {
    console.log('❌ Thread Finder would NOT be triggered');
    console.log(`   Intent "${classification.intent}" is not a link-only intent`);
  }

  const passed = classification.intent?.includes('link-only');
  console.log(`\n${passed ? '✅ PASSED' : '❌ FAILED'}: Mock template ${passed ? 'correctly' : 'incorrectly'} classified as link-only`);

  return passed;
}

async function testThreadFinderDetection() {
  console.log('\n=== Thread Finder Detection Validation ===');
  console.log('Testing classifier accuracy on content-rich vs link-only emails\n');

  const test1Passed = await testCorpusEmail();
  const test2Passed = await testMockLinkOnlyEmail();

  console.log('\n=== Test Summary ===\n');
  console.log(`Test 1 (Corpus Email): ${test1Passed ? '✅ PASSED' : '❌ FAILED'}`);
  console.log(`Test 2 (Mock Link-Only): ${test2Passed ? '✅ PASSED' : '❌ FAILED'}`);

  const allPassed = test1Passed && test2Passed;
  console.log(`\n${allPassed ? '✅ ALL TESTS PASSED' : '❌ SOME TESTS FAILED'}\n`);

  return allPassed;
}

// Run test
testThreadFinderDetection()
  .then(passed => {
    process.exit(passed ? 0 : 1);
  })
  .catch(error => {
    console.error('❌ Test failed with error:', error.message);
    console.error(error.stack);
    process.exit(1);
  });
