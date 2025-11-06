/**
 * Test Script: Home Depot - Dewalt Power Drill
 * Tests shopping automation for adding Home Depot product to cart
 *
 * Product: DEWALT 20V MAX Cordless Drill/Driver Kit
 * URL: https://www.homedepot.com/p/DEWALT-20V-MAX-Cordless-Drill-Driver-Kit-DCD771C2/205499432
 */

const { automateAddToCart } = require('./shopping-automation');

async function testHomeDepot() {
  console.log('='.repeat(80));
  console.log('TEST: Home Depot - DEWALT 20V MAX Cordless Drill');
  console.log('='.repeat(80));

  const productUrl = 'https://www.homedepot.com/p/DEWALT-20V-MAX-Cordless-Drill-Driver-Kit-DCD771C2/205499432';
  const productName = 'DEWALT 20V MAX Cordless Drill/Driver Kit';
  const userSessionId = `test-homedepot-${Date.now()}`;

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
    console.log('  - Home Depot may require store selection (similar to Target)');
    console.log('  - Cart URL is /mycart/home (custom path)');
    console.log('  - Some products require delivery ZIP code selection');

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
testHomeDepot();
