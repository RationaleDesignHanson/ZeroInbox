#!/usr/bin/env node
/**
 * Batch Summary Regeneration Script
 *
 * Fetches all current emails for a user and regenerates AI summaries
 * This script is useful for testing card layouts with real summary data
 *
 * Usage:
 *   node regenerate-summaries.js <user-id> [maxEmails]
 *
 * Example:
 *   node regenerate-summaries.js test-user-123 50
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const axios = require('axios');
const logger = require('../shared/config/logger');

// Service URLs
const GATEWAY_URL = process.env.GATEWAY_URL || 'http://localhost:8080';
const EMAIL_SERVICE_URL = process.env.EMAIL_SERVICE_URL || 'http://localhost:8081';
const CLASSIFIER_SERVICE_URL = process.env.CLASSIFIER_SERVICE_URL || 'http://localhost:8082';
const SUMMARIZATION_SERVICE_URL = process.env.SUMMARIZATION_SERVICE_URL || 'http://localhost:8083';

/**
 * Fetch user's emails from Gmail
 */
async function fetchUserEmails(userId, maxResults = 50) {
  try {
    console.log(`📧 Fetching ${maxResults} emails for user: ${userId}...`);

    // Get user tokens
    const { getUserTokens } = require('../shared/utils/auth');
    const tokens = await getUserTokens(userId, 'gmail');

    if (!tokens) {
      throw new Error(`No tokens found for user ${userId}`);
    }

    const response = await axios.get(
      `${EMAIL_SERVICE_URL}/api/gmail/messages`,
      {
        params: { maxResults },
        headers: {
          'X-User-ID': userId,
          'X-Access-Token': tokens.accessToken,
          'X-Refresh-Token': tokens.refreshToken || '',
          'X-Token-Expiry': tokens.expiresAt || ''
        }
      }
    );

    const emails = response.data.messages || [];
    console.log(`✅ Fetched ${emails.length} emails`);
    return emails;
  } catch (error) {
    console.error('❌ Failed to fetch emails:', error.message);
    throw error;
  }
}

/**
 * Classify email
 */
async function classifyEmail(email) {
  try {
    const response = await axios.post(
      `${CLASSIFIER_SERVICE_URL}/api/classify`,
      { email }
    );
    return response.data;
  } catch (error) {
    logger.error('Classifier error', { error: error.message });
    return {
      type: 'mail',
      priority: 'medium',
      hpa: 'Review',
      metaCTA: 'Swipe Right: Review'
    };
  }
}

/**
 * Generate AI summary for email
 */
async function generateSummary(email, classification) {
  try {
    // Check if this is a newsletter
    const isNewsletter = classification?.intent?.includes('newsletter');

    if (isNewsletter) {
      console.log(`  📰 Newsletter detected, using newsletter summarization`);
      const response = await axios.post(
        `${SUMMARIZATION_SERVICE_URL}/api/summarize/newsletter`,
        {
          emailId: email.id,
          subject: email.subject,
          from: email.from,
          body: email.body || email.snippet,
          snippet: email.snippet
        }
      );

      return {
        summary: response.data.summary,
        keyLinks: response.data.keyLinks || [],
        keyTopics: response.data.keyTopics || [],
        source: 'gemini-newsletter'
      };
    }

    // Regular email summarization
    const response = await axios.post(
      `${SUMMARIZATION_SERVICE_URL}/api/summarize`,
      { email }
    );

    return response.data;
  } catch (error) {
    logger.error('Summarization error', { error: error.message });
    return {
      summary: email.snippet || email.subject,
      source: 'fallback'
    };
  }
}

/**
 * Process and regenerate summary for a single email
 */
async function processEmail(email, index, total) {
  try {
    console.log(`\n[${index + 1}/${total}] Processing: ${email.subject}`);
    console.log(`  From: ${email.from}`);
    console.log(`  Date: ${new Date(email.timestamp).toLocaleString()}`);

    // Step 1: Classify
    console.log(`  🔍 Classifying...`);
    const classification = await classifyEmail(email);
    console.log(`  📊 Type: ${classification.type}, Priority: ${classification.priority}`);
    if (classification.intent) {
      console.log(`  💡 Intent: ${classification.intent}`);
    }

    // Step 2: Generate summary
    console.log(`  🤖 Generating AI summary with Gemini...`);
    const summary = await generateSummary(email, classification);
    console.log(`  ✨ Summary generated (${summary.source})`);

    // Display summary preview
    const summaryPreview = summary.summary.substring(0, 150);
    console.log(`  📝 Preview: ${summaryPreview}${summary.summary.length > 150 ? '...' : ''}`);

    // Display line count for verification
    const lineCount = summary.summary.split('\n').filter(line => line.trim()).length;
    console.log(`  📏 Length: ${lineCount} lines, ${summary.summary.length} characters`);

    return {
      emailId: email.id,
      subject: email.subject,
      classification,
      summary,
      success: true
    };
  } catch (error) {
    console.error(`  ❌ Failed to process email:`, error.message);
    return {
      emailId: email.id,
      subject: email.subject,
      success: false,
      error: error.message
    };
  }
}

/**
 * Main execution
 */
async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error('❌ Usage: node regenerate-summaries.js <user-id> [maxEmails]');
    console.error('   Example: node regenerate-summaries.js test-user-123 50');
    process.exit(1);
  }

  const userId = args[0];
  const maxEmails = parseInt(args[1]) || 50;

  console.log('🚀 Zero Inbox - Summary Regeneration Script');
  console.log('='.repeat(60));
  console.log(`User ID: ${userId}`);
  console.log(`Max Emails: ${maxEmails}`);
  console.log(`Timestamp: ${new Date().toISOString()}`);
  console.log('='.repeat(60));

  try {
    // Step 1: Fetch emails
    const emails = await fetchUserEmails(userId, maxEmails);

    if (emails.length === 0) {
      console.log('\n⚠️  No emails found for this user');
      return;
    }

    // Step 2: Process each email
    console.log(`\n📊 Processing ${emails.length} emails...`);
    const results = [];

    for (let i = 0; i < emails.length; i++) {
      const email = emails[i];
      const result = await processEmail(email, i, emails.length);
      results.push(result);

      // Brief pause to avoid rate limiting
      if (i < emails.length - 1) {
        await new Promise(resolve => setTimeout(resolve, 500));
      }
    }

    // Step 3: Generate summary report
    console.log('\n' + '='.repeat(60));
    console.log('📈 SUMMARY REPORT');
    console.log('='.repeat(60));

    const successful = results.filter(r => r.success);
    const failed = results.filter(r => !r.success);

    console.log(`✅ Successful: ${successful.length}/${emails.length}`);
    console.log(`❌ Failed: ${failed.length}/${emails.length}`);

    if (failed.length > 0) {
      console.log('\n❌ Failed Emails:');
      failed.forEach(result => {
        console.log(`  - ${result.subject}: ${result.error}`);
      });
    }

    // Count summaries by source
    const bySource = {};
    successful.forEach(result => {
      const source = result.summary.source;
      bySource[source] = (bySource[source] || 0) + 1;
    });

    console.log('\n📊 Summary Sources:');
    Object.entries(bySource).forEach(([source, count]) => {
      console.log(`  - ${source}: ${count}`);
    });

    // Display sample summaries
    console.log('\n📝 Sample Summaries (first 3):');
    successful.slice(0, 3).forEach((result, idx) => {
      console.log(`\n${idx + 1}. ${result.subject}`);
      console.log(`   Type: ${result.classification.type}, Intent: ${result.classification.intent || 'N/A'}`);
      console.log(`   Summary:\n${result.summary.summary.split('\n').map(line => `   ${line}`).join('\n')}`);
    });

    console.log('\n' + '='.repeat(60));
    console.log('✨ Summary regeneration complete!');
    console.log('='.repeat(60));
    console.log('\n💡 Next Steps:');
    console.log('   1. The iOS app will receive these fresh summaries on next sync');
    console.log('   2. Now we can fix the card layout to display them properly');
    console.log('   3. Test the cards to verify layout matches web demo\n');

  } catch (error) {
    console.error('\n❌ Fatal error:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// Run the script
main();
