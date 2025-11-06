/**
 * Test Script: Best Buy - Sony Wireless Headphones
 * Tests shopping automation for adding Best Buy product to cart
 *
 * Product: Sony WH-1000XM5 Wireless Noise-Canceling Headphones
 * URL: https://www.bestbuy.com/site/sony-wh-1000xm5-wireless-noise-canceling-over-the-ear-headphones-black/6505727.p
 */

const { automateAddToCart } = require('./shopping-automation');

async function testBestBuy() {
  console.log('='.repeat(80));
  console.log('TEST: Best Buy - Sony WH-1000XM5 Wireless Headphones');
  console.log('='.repeat(80));

  const productUrl = 'https://www.bestbuy.com/site/sony-wh-1000xm5-wireless-noise-canceling-over-the-ear-headphones-black/6505727.p';
  const productName = 'Sony WH-1000XM5 Wireless Noise-Canceling Headphones';
  const userSessionId = `test-bestbuy-${Date.now()}`;

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
testBestBuy();
