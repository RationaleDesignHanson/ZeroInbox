/**
 * Test Script: Amazon Basics Expandable Hardside Luggage
 * Tests shopping automation for adding Amazon product to cart
 *
 * Product: Amazon Basics Expandable Hardside Scratch-Resistant Luggage
 * URL: https://www.amazon.com/Amazon-Basics-Expandable-Hardside-Scratch-Resistant/dp/B071VG57FP/
 */

const { automateAddToCart } = require('./shopping-automation');

async function testAmazonLuggage() {
  console.log('='.repeat(80));
  console.log('TEST: Amazon Basics Expandable Hardside Luggage');
  console.log('='.repeat(80));

  const productUrl = 'https://www.amazon.com/Amazon-Basics-Expandable-Hardside-Scratch-Resistant/dp/B071VG57FP/ref=hw_25_a_dag_fh_a47d?pf_rd_p=6cce2c03-03bf-4741-a1f0-fa8fce489dbc&pf_rd_r=WTTG0CCMTXG3WHNKRRCZ&sr=1-10-9f939889-605c-4811-ad2b-cc2695a8891a';
  const productName = 'Amazon Basics Expandable Hardside Scratch-Resistant Luggage';
  const userSessionId = `test-amazon-${Date.now()}`;

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
testAmazonLuggage();
