/**
 * Test Script: eBay - Nintendo Switch Console
 * Tests shopping automation for adding eBay product to cart
 *
 * Product: Nintendo Switch Console (Buy It Now listing)
 * URL: https://www.ebay.com/itm/256405028664
 */

const { automateAddToCart } = require('./shopping-automation');

async function testEbay() {
  console.log('='.repeat(80));
  console.log('TEST: eBay - Nintendo Switch Console');
  console.log('='.repeat(80));

  const productUrl = 'https://www.ebay.com/itm/256405028664';
  const productName = 'Nintendo Switch Console with Neon Blue and Red Joy-Con';
  const userSessionId = `test-ebay-${Date.now()}`;

  try {
    console.log(`\n🚀 Starting automation for: ${productName}`);
    console.log(`📍 URL: ${productUrl}`);
    console.log(`👤 User Session: ${userSessionId}\n`);

    const result = await automateAddToCart(productUrl, productName, userSessionId);

    console.log('\n' + '='.repeat(80));
    console.log('TEST RESULTS');
    console.log('='.repeat(80));
    console.log(`✅ Success: ${result.success}`);
    console.log(`🔗 Session ID: ${result.sessionId}`);
    console.log(`👁️  Session Viewer: ${result.sessionViewerUrl}`);
    console.log(`🛒 Cart URL: ${result.cartUrl}`);
    console.log(`💳 Checkout URL: ${result.checkoutUrl}`);
    console.log(`📸 Screenshots: ${result.screenshots.length}`);
    console.log(`📝 Steps: ${result.steps.length}`);

    if (result.error) {
      console.log(`❌ Error: ${result.error}`);
    }

    console.log('\n📋 Step Details:');
    result.steps.forEach((step, index) => {
      console.log(`  ${index + 1}. ${step.step}: ${step.success ? '✅' : '❌'}`);
      if (step.selector) {
        console.log(`     Selector: ${step.selector}`);
      }
      if (step.attemptedSelectors) {
        console.log(`     Attempts: ${step.attemptedSelectors}`);
      }
      if (step.error) {
        console.log(`     Error: ${step.error}`);
      }
      if (step.note) {
        console.log(`     Note: ${step.note}`);
      }
    });

    console.log('\n📝 Notes:');
    console.log('  - eBay has both "Buy It Now" and auction listings');
    console.log('  - This test uses a "Buy It Now" listing for cart testing');
    console.log('  - Auction items may only support "Add to Watchlist"');

    console.log('\n' + '='.repeat(80));
    console.log(`TEST ${result.success ? 'PASSED ✅' : 'FAILED ❌'}`);
    console.log('='.repeat(80));

    // Exit with appropriate code
    process.exit(result.success ? 0 : 1);

  } catch (error) {
    console.error('\n❌ Test failed with exception:', error);
    console.error(error.stack);
    console.log('\n' + '='.repeat(80));
    console.log('TEST FAILED ❌');
    console.log('='.repeat(80));
    process.exit(1);
  }
}

// Run test
testEbay();
