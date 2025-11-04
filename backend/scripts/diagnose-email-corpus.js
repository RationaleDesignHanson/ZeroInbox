#!/usr/bin/env node

/**
 * Email Corpus Diagnostic Tool
 *
 * Helps identify emails with missing or invalid data in the corpus
 * that could cause classification errors.
 */

const fs = require('fs');
const path = require('path');

// Configuration
const CORPUS_PATHS = [
  '/Users/matthanson/Downloads/emailsfordeepsampling/Takeout/Mail',
  '/Users/matthanson/Downloads/emailsfordeepsampling/Takeout 2/Mail',
  '/Users/matthanson/Zer0_Inbox/backend/dashboard/data'
];

console.log('📧 Email Corpus Diagnostic Tool\n');
console.log('Checking for emails with missing or invalid data...\n');

// Check JSON corpus files
function checkJSONCorpus(filePath) {
  console.log(`\n📁 Checking JSON corpus: ${filePath}`);

  try {
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));

    if (!Array.isArray(data)) {
      console.log(`  ⚠️  Corpus is not an array`);
      return;
    }

    console.log(`  Total emails: ${data.length}`);

    let issues = {
      missingSubject: 0,
      missingFrom: 0,
      missingBody: 0,
      nullEmail: 0,
      invalidType: 0
    };

    const problematicEmails = [];

    data.forEach((email, index) => {
      if (!email) {
        issues.nullEmail++;
        problematicEmails.push({ index, issue: 'null email object' });
        return;
      }

      if (typeof email !== 'object') {
        issues.invalidType++;
        problematicEmails.push({ index, issue: 'email is not an object', type: typeof email });
        return;
      }

      if (!email.subject) {
        issues.missingSubject++;
        problematicEmails.push({ index, issue: 'missing subject', email });
      }

      if (!email.from) {
        issues.missingFrom++;
        problematicEmails.push({ index, issue: 'missing from', email });
      }

      if (!email.body && !email.snippet) {
        issues.missingBody++;
      }
    });

    console.log(`\n  Issues found:`);
    console.log(`    - Null emails: ${issues.nullEmail}`);
    console.log(`    - Invalid type: ${issues.invalidType}`);
    console.log(`    - Missing subject: ${issues.missingSubject}`);
    console.log(`    - Missing from: ${issues.missingFrom}`);
    console.log(`    - Missing body/snippet: ${issues.missingBody}`);

    if (problematicEmails.length > 0) {
      console.log(`\n  ⚠️  First 5 problematic emails:`);
      problematicEmails.slice(0, 5).forEach(({ index, issue, email, type }) => {
        console.log(`    [${index}] ${issue}`);
        if (type) console.log(`        Type: ${type}`);
        if (email) {
          console.log(`        Subject: ${email.subject || 'MISSING'}`);
          console.log(`        From: ${email.from || 'MISSING'}`);
        }
      });
    } else {
      console.log(`\n  ✅ No problematic emails found!`);
    }

  } catch (error) {
    console.log(`  ❌ Error reading corpus: ${error.message}`);
  }
}

// Check mbox files (basic check)
function checkMboxFiles(dirPath) {
  console.log(`\n📁 Checking mbox files in: ${dirPath}`);

  try {
    const files = fs.readdirSync(dirPath);
    const mboxFiles = files.filter(f => f.endsWith('.mbox'));

    console.log(`  Found ${mboxFiles.length} mbox files`);

    mboxFiles.forEach(file => {
      const filePath = path.join(dirPath, file);
      const stats = fs.statSync(filePath);
      const sizeMB = (stats.size / (1024 * 1024)).toFixed(2);
      console.log(`    - ${file}: ${sizeMB} MB`);
    });

  } catch (error) {
    console.log(`  ❌ Error reading directory: ${error.message}`);
  }
}

// Main execution
console.log('Scanning corpus locations...\n');

CORPUS_PATHS.forEach(corpusPath => {
  if (fs.existsSync(corpusPath)) {
    const stats = fs.statSync(corpusPath);

    if (stats.isDirectory()) {
      // Check for JSON files in directory
      try {
        const files = fs.readdirSync(corpusPath);
        const jsonFiles = files.filter(f => f.endsWith('.json'));

        jsonFiles.forEach(file => {
          checkJSONCorpus(path.join(corpusPath, file));
        });

        // Check for mbox files
        checkMboxFiles(corpusPath);
      } catch (error) {
        console.log(`❌ Error scanning directory: ${error.message}`);
      }
    } else if (corpusPath.endsWith('.json')) {
      checkJSONCorpus(corpusPath);
    }
  } else {
    console.log(`  ⚠️  Path does not exist: ${corpusPath}`);
  }
});

console.log('\n✅ Diagnostic complete!\n');
console.log('💡 Tips to fix issues:');
console.log('  1. Filter out null/invalid emails before processing');
console.log('  2. Ensure all emails have subject and from fields');
console.log('  3. Add validation before sending to classifier');
console.log('  4. Check your email parsing script for bugs\n');
