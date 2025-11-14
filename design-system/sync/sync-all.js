#!/usr/bin/env node

/**
 * Master Sync Script - Figma to iOS + Web
 * Runs the complete token sync workflow:
 * 1. Export from Figma → design-tokens.json
 * 2. Generate Swift → DesignTokens.swift
 * 3. Generate Web → design-tokens.css + design-tokens.js
 *
 * Usage: node sync-all.js
 */

const { exportTokens } = require('./export-from-figma');
const { generateSwift } = require('./generate-swift');
const { generateWeb } = require('./generate-web');

async function syncAll() {
  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║  Design Token Sync: Figma → iOS + Web           ║');
  console.log('╚══════════════════════════════════════════════════╝\n');

  try {
    // Step 1: Export from Figma
    console.log('📥 Step 1/3: Exporting from Figma...');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    await exportTokens();

    // Step 2: Generate Swift
    console.log('\n🍎 Step 2/3: Generating Swift tokens...');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    generateSwift();

    // Step 3: Generate Web
    console.log('\n🌐 Step 3/3: Generating Web tokens...');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    generateWeb();

    console.log('\n╔══════════════════════════════════════════════════╗');
    console.log('║  ✅ Sync Complete!                               ║');
    console.log('╚══════════════════════════════════════════════════╝\n');

    console.log('📦 Generated Files:');
    console.log('   📄 design-tokens.json       (source JSON)');
    console.log('   🍎 DesignTokens.swift       (iOS)');
    console.log('   🌐 design-tokens.css        (Web CSS variables)');
    console.log('   🌐 design-tokens.js         (Web JS module)\n');

    console.log('💡 Next Steps:');
    console.log('   1. Copy DesignTokens.swift to your iOS project');
    console.log('   2. Import design-tokens.css in your web project');
    console.log('   3. Commit the generated files to version control\n');

  } catch (error) {
    console.error('\n❌ Sync failed:', error.message);
    process.exit(1);
  }
}

// Run
syncAll();
