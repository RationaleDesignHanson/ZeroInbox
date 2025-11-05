/**
 * Comprehensive E2E Test: All Shopping Platforms
 *
 * Tests shopping automation across all supported platforms:
 * - Amazon
 * - Target
 * - Walmart
 * - Shopify (simulated)
 * - Best Buy (simulated)
 *
 * Usage:
 *   node test-all-platforms.js
 *
 * Environment Variables:
 *   STEEL_API_KEY - Steel.dev API key (required for live tests)
 *   RUN_LIVE - Set to 'true' to run live automation (default: false, uses simulation)
 */

const { automateAddToCart } = require('./shopping-automation');
const { detectPlatform } = require('./shopping-automation');

// Test products for each platform
const TEST_PRODUCTS = [
  {
    platform: 'Amazon',
    url: 'https://www.amazon.com/Apple-AirPods-Pro-2nd-Generation/dp/B0CHWRXH8B',
    name: 'Apple AirPods Pro (2nd Generation)',
    expectedPrice: '199-249'
  },
  {
    platform: 'Target',
    url: 'https://www.target.com/p/airpods-pro-2nd-generation/-/A-85978622',
    name: 'AirPods Pro (2nd Generation)',
    expectedPrice: '199-249'
  },
  {
    platform: 'Walmart',
    url: 'https://www.walmart.com/ip/Apple-AirPods-Pro-2nd-Generation-with-MagSafe-Case-USB-C/1752657021',
    name: 'Apple AirPods Pro (2nd Generation)',
    expectedPrice: '199-249'
  },
  {
    platform: 'Shopify',
    url: 'https://example.myshopify.com/products/cool-shirt',
    name: 'Cool T-Shirt',
    expectedPrice: '25-50',
    simulationOnly: true
  },
  {
    platform: 'Best Buy',
    url: 'https://www.bestbuy.com/site/airpods-pro-2nd-generation/6447382.p',
    name: 'AirPods Pro (2nd Generation)',
    expectedPrice: '199-249',
    simulationOnly: true
  }
];

const RUN_LIVE = process.env.RUN_LIVE === 'true';
const STEEL_API_KEY = process.env.STEEL_API_KEY;

/**
 * Run test for a single platform
 */
async function testPlatform(product, index, total) {
  console.log('\n' + '='.repeat(80));
  console.log(`\n[Test ${index + 1}/${total}] ${product.platform} - ${product.name}`);
  console.log('URL:', product.url);

  if (product.simulationOnly && RUN_LIVE) {
    console.log('⚠️  SKIPPED - Simulation only (no live test configured)');
    return { platform: product.platform, status: 'skipped', reason: 'simulation-only' };
  }

  const startTime = Date.now();

  try {
    // Step 1: Platform Detection
    console.log('\n1️⃣  Testing Platform Detection...');
    const platformInfo = detectPlatform(product.url);

    if (platformInfo.platform !== product.platform) {
      console.log(`❌ Platform detection failed`);
      console.log(`   Expected: ${product.platform}`);
      console.log(`   Got: ${platformInfo.platform}`);
      return { platform: product.platform, status: 'failed', reason: 'detection-failed' };
    }

    console.log(`✅ Platform detected: ${platformInfo.platform}`);
    console.log(`   Platform ID: ${platformInfo.platformId}`);
    console.log(`   Selectors defined: ${platformInfo.addToCartSelectors.length} add-to-cart, ${platformInfo.checkoutSelectors.length} checkout`);

    // Step 2: Automation Test (if live mode and not simulation-only)
    if (!product.simulationOnly) {
      console.log('\n2️⃣  Testing Shopping Automation...');

      if (!RUN_LIVE) {
        console.log('ℹ️  Dry run mode (set RUN_LIVE=true for live automation)');
        return { platform: product.platform, status: 'dry-run', detectionPassed: true };
      }

      if (!STEEL_API_KEY) {
        console.log('⚠️  SKIPPED - No Steel API key configured');
        return { platform: product.platform, status: 'skipped', reason: 'no-api-key', detectionPassed: true };
      }

      const sessionId = `test-${product.platform.toLowerCase()}-${Date.now()}`;
      const result = await automateAddToCart(product.url, product.name, sessionId);

      const duration = ((Date.now() - startTime) / 1000).toFixed(1);

      if (result.success) {
        console.log(`✅ Automation completed successfully (${duration}s)`);
        console.log(`   Cart URL: ${result.cartUrl || 'N/A'}`);
        console.log(`   Steps completed: ${result.steps.filter(s => s.success).length}/${result.steps.length}`);

        return {
          platform: product.platform,
          status: 'success',
          duration: parseFloat(duration),
          steps: result.steps.length,
          stepsCompleted: result.steps.filter(s => s.success).length,
          screenshots: result.screenshots.length
        };
      } else {
        console.log(`❌ Automation failed (${duration}s)`);
        console.log(`   Error: ${result.error || 'Unknown error'}`);
        console.log(`   Steps completed: ${result.steps.filter(s => s.success).length}/${result.steps.length}`);

        return {
          platform: product.platform,
          status: 'failed',
          duration: parseFloat(duration),
          error: result.error,
          stepsCompleted: result.steps.filter(s => s.success).length
        };
      }
    } else {
      console.log('\n2️⃣  Automation test skipped (simulation only)');
      return { platform: product.platform, status: 'detection-only', detectionPassed: true };
    }

  } catch (error) {
    const duration = ((Date.now() - startTime) / 1000).toFixed(1);
    console.log(`❌ Test error (${duration}s): ${error.message}`);
    return {
      platform: product.platform,
      status: 'error',
      duration: parseFloat(duration),
      error: error.message
    };
  }
}

/**
 * Main test runner
 */
async function runAllTests() {
  console.log('\n🧪 Shopping Automation E2E Test Suite');
  console.log('=' .repeat(80));
  console.log('\nConfiguration:');
  console.log(`  Mode: ${RUN_LIVE ? 'LIVE AUTOMATION' : 'DRY RUN (detection only)'}`);
  console.log(`  Steel API: ${STEEL_API_KEY ? 'Configured' : 'Not configured'}`);
  console.log(`  Total Platforms: ${TEST_PRODUCTS.length}`);
  console.log(`  Live Tests: ${TEST_PRODUCTS.filter(p => !p.simulationOnly).length}`);
  console.log(`  Simulation Tests: ${TEST_PRODUCTS.filter(p => p.simulationOnly).length}`);

  if (RUN_LIVE && !STEEL_API_KEY) {
    console.log('\n⚠️  WARNING: RUN_LIVE=true but no STEEL_API_KEY configured');
    console.log('   Live automation tests will be skipped\n');
  }

  const results = [];

  // Run tests sequentially to avoid overwhelming the service
  for (let i = 0; i < TEST_PRODUCTS.length; i++) {
    const result = await testPlatform(TEST_PRODUCTS[i], i, TEST_PRODUCTS.length);
    results.push(result);

    // Wait between tests to avoid rate limiting
    if (i < TEST_PRODUCTS.length - 1 && RUN_LIVE) {
      console.log('\n⏳ Waiting 3s before next test...');
      await new Promise(resolve => setTimeout(resolve, 3000));
    }
  }

  // Summary Report
  console.log('\n' + '='.repeat(80));
  console.log('\n📊 TEST SUMMARY\n');

  const successful = results.filter(r => r.status === 'success').length;
  const failed = results.filter(r => r.status === 'failed').length;
  const skipped = results.filter(r => r.status === 'skipped').length;
  const dryRun = results.filter(r => r.status === 'dry-run').length;
  const detectionOnly = results.filter(r => r.status === 'detection-only').length;
  const errors = results.filter(r => r.status === 'error').length;

  console.log('Results by Status:');
  if (successful > 0) console.log(`  ✅ Success: ${successful}`);
  if (failed > 0) console.log(`  ❌ Failed: ${failed}`);
  if (skipped > 0) console.log(`  ⏭️  Skipped: ${skipped}`);
  if (dryRun > 0) console.log(`  🔍 Dry Run: ${dryRun}`);
  if (detectionOnly > 0) console.log(`  🔍 Detection Only: ${detectionOnly}`);
  if (errors > 0) console.log(`  ⚠️  Errors: ${errors}`);

  console.log('\nPlatform Details:');
  results.forEach(result => {
    const statusEmoji = {
      'success': '✅',
      'failed': '❌',
      'skipped': '⏭️',
      'dry-run': '🔍',
      'detection-only': '🔍',
      'error': '⚠️'
    }[result.status] || '❓';

    let line = `  ${statusEmoji} ${result.platform.padEnd(15)}`;

    if (result.duration) {
      line += ` ${result.duration.toFixed(1)}s`;
    }

    if (result.stepsCompleted !== undefined) {
      line += ` (${result.stepsCompleted}/${result.steps || '?'} steps)`;
    }

    if (result.reason) {
      line += ` - ${result.reason}`;
    }

    if (result.error) {
      line += ` - ${result.error}`;
    }

    console.log(line);
  });

  // Performance Metrics (for successful tests)
  const successfulResults = results.filter(r => r.status === 'success' && r.duration);
  if (successfulResults.length > 0) {
    const avgDuration = successfulResults.reduce((sum, r) => sum + r.duration, 0) / successfulResults.length;
    const totalDuration = successfulResults.reduce((sum, r) => sum + r.duration, 0);

    console.log('\n⏱️  Performance:');
    console.log(`  Average Duration: ${avgDuration.toFixed(1)}s`);
    console.log(`  Total Duration: ${totalDuration.toFixed(1)}s`);
  }

  // Recommendations
  console.log('\n💡 Recommendations:');
  if (!RUN_LIVE) {
    console.log('  • Run with RUN_LIVE=true to test live automation');
  }
  if (!STEEL_API_KEY) {
    console.log('  • Set STEEL_API_KEY environment variable for live tests');
  }
  if (failed > 0) {
    console.log('  • Review failed platform selectors in shopping-automation.js');
  }
  if (successful === TEST_PRODUCTS.filter(p => !p.simulationOnly).length) {
    console.log('  • All platforms working correctly! 🎉');
  }

  console.log('\n' + '='.repeat(80) + '\n');

  // Exit code
  if (RUN_LIVE) {
    process.exit(failed > 0 || errors > 0 ? 1 : 0);
  } else {
    process.exit(0); // Dry run always succeeds
  }
}

// Run tests
runAllTests().catch(error => {
  console.error('\n❌ Fatal error:', error);
  process.exit(1);
});
