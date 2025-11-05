/**
 * Test Amazon shopping automation
 */

const { automateAddToCart } = require('./shopping-automation');

async function testAmazon() {
  console.log('Testing Amazon product automation...\n');

  const productUrl = 'https://www.amazon.com/Apple-AirPods-Pro-2nd-Generation/dp/B0CHWRXH8B';
  const productName = 'Apple AirPods Pro (2nd Generation)';

  try {
    const result = await automateAddToCart(productUrl, productName, 'test-amazon-session');

    console.log('\n=== AUTOMATION RESULT ===');
    console.log('Success:', result.success);
    console.log('Checkout URL:', result.checkoutUrl);
    console.log('Cart URL:', result.cartUrl);
    console.log('Error:', result.error);
    console.log('\nSteps:');
    result.steps.forEach((step, index) => {
      console.log(`${index + 1}. ${step.step}: ${step.success ? '✅' : '❌'}`);
      if (step.selector) console.log(`   Selector: ${step.selector}`);
      if (step.error) console.log(`   Error: ${step.error}`);
    });
    console.log(`\nScreenshots captured: ${result.screenshots.length}`);

    process.exit(result.success ? 0 : 1);
  } catch (error) {
    console.error('Test failed:', error);
    process.exit(1);
  }
}

testAmazon();
