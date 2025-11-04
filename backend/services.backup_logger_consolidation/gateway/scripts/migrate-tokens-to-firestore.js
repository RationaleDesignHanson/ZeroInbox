#!/usr/bin/env node

/**
 * Migration Script: File-based Token Storage → Firestore
 *
 * This script migrates OAuth tokens from local file storage to Firestore.
 *
 * Usage:
 *   node scripts/migrate-tokens-to-firestore.js
 *
 * Environment Variables:
 *   GOOGLE_CLOUD_PROJECT - Google Cloud project ID
 *   DRY_RUN=true - Preview migration without writing to Firestore
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { storeUserTokens } = require('../shared/utils/tokenStore');

const TOKEN_DIR = path.join(__dirname, '../data/tokens');
const DRY_RUN = process.env.DRY_RUN === 'true';

async function migrateTokens() {
  console.log('🔄 Starting token migration to Firestore...\n');
  console.log(`   Mode: ${DRY_RUN ? 'DRY RUN (preview only)' : 'LIVE MIGRATION'}`);
  console.log(`   Source: ${TOKEN_DIR}`);
  console.log(`   Project: ${process.env.GOOGLE_CLOUD_PROJECT || 'gen-lang-client-0622702687'}\n`);

  // Check if token directory exists
  if (!fs.existsSync(TOKEN_DIR)) {
    console.error(`❌ Token directory not found: ${TOKEN_DIR}`);
    console.log('\nNo tokens to migrate. Exiting.');
    return;
  }

  // Read all token files
  const files = fs.readdirSync(TOKEN_DIR).filter(f => f.endsWith('.json'));

  if (files.length === 0) {
    console.log('✅ No token files found. Nothing to migrate.');
    return;
  }

  console.log(`📦 Found ${files.length} token file(s)\n`);

  let successCount = 0;
  let errorCount = 0;

  // Migrate each token file
  for (const file of files) {
    const filePath = path.join(TOKEN_DIR, file);

    try {
      // Read token file
      const data = fs.readFileSync(filePath, 'utf-8');
      const tokens = JSON.parse(data);

      // Extract userId and provider from filename (format: userId_provider.json)
      const fileBase = path.basename(file, '.json');
      const parts = fileBase.split('_');

      if (parts.length < 2) {
        console.warn(`⚠️  Skipping invalid filename format: ${file}`);
        continue;
      }

      const userId = parts.slice(0, -1).join('_'); // Handle userIds with underscores
      const provider = parts[parts.length - 1];

      console.log(`   Processing: ${userId} (${provider})`);

      // Validate token data
      if (!tokens.accessToken || !tokens.email) {
        console.warn(`   ⚠️  Skipping - missing required fields`);
        continue;
      }

      if (!DRY_RUN) {
        // Store in Firestore
        await storeUserTokens(userId, provider, {
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken || null,
          expiresAt: tokens.expiresAt || null,
          email: tokens.email
        });
        console.log(`   ✅ Migrated successfully`);
      } else {
        console.log(`   📋 Would migrate: ${tokens.email}`);
      }

      successCount++;

    } catch (error) {
      console.error(`   ❌ Error processing ${file}:`, error.message);
      errorCount++;
    }

    console.log('');
  }

  console.log('─'.repeat(50));
  console.log(`\n📊 Migration Summary:`);
  console.log(`   Total files: ${files.length}`);
  console.log(`   Successful: ${successCount}`);
  console.log(`   Errors: ${errorCount}`);

  if (DRY_RUN) {
    console.log(`\n💡 This was a DRY RUN. To perform the actual migration, run:`);
    console.log(`   node scripts/migrate-tokens-to-firestore.js\n`);
  } else {
    console.log(`\n✅ Migration complete!`);
    console.log(`\n⚠️  IMPORTANT: The file-based tokens are still present in ${TOKEN_DIR}`);
    console.log(`   After verifying the migration, you can safely delete them.\n`);
  }
}

// Run migration
migrateTokens()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('\n❌ Migration failed:', error);
    process.exit(1);
  });
