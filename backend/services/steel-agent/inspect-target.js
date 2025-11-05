/**
 * Script to inspect Target page and find Add to Cart button
 */

const steelClient = require('./steel-client');

async function inspectPage() {
  let sessionId = null;

  try {
    // Create session
    console.log('Creating Steel session...');
    const session = await steelClient.createSession();
    sessionId = session.id;
    console.log('Session created:', sessionId);

    // Navigate to Target product page
    console.log('Navigating to Target...');
    await steelClient.navigateToUrl(
      sessionId,
      'https://www.target.com/p/airpods-pro-2nd-generation/-/A-85978622'
    );

    // Wait a moment for page to fully load
    await new Promise(resolve => setTimeout(resolve, 3000));

    // Execute script to find all buttons with "cart" in text or attributes
    console.log('Searching for Add to Cart button...');
    const result = await steelClient.executeScript(sessionId, `(() => {
      const buttons = Array.from(document.querySelectorAll('button, [role="button"], a'));
      const cartButtons = buttons.filter(btn => {
        const text = btn.textContent.toLowerCase();
        const dataTest = btn.getAttribute('data-test') || '';
        const id = btn.id || '';
        const ariaLabel = btn.getAttribute('aria-label') || '';

        return text.includes('cart') ||
               dataTest.includes('cart') ||
               id.includes('cart') ||
               ariaLabel.includes('cart');
      }).map(btn => ({
        tagName: btn.tagName,
        id: btn.id,
        className: btn.className,
        dataTest: btn.getAttribute('data-test'),
        text: btn.textContent.trim().substring(0, 50),
        ariaLabel: btn.getAttribute('aria-label')
      }));

      return cartButtons;
    })()`);

    console.log('\nFound buttons related to cart:');
    console.log(JSON.stringify(result, null, 2));

    // Also check for the main Add to Cart button specifically
    const addToCartButton = await steelClient.executeScript(sessionId, `(() => {
      const button = document.querySelector('[data-test*="addToCart"], [id*="addToCart"]');
      if (button) {
        return {
          tagName: button.tagName,
          id: button.id,
          className: button.className,
          dataTest: button.getAttribute('data-test'),
          text: button.textContent.trim(),
          selector: button.id ? '#' + button.id : '[data-test="' + button.getAttribute('data-test') + '"]'
        };
      }
      return null;
    })()`);

    console.log('\nMain Add to Cart button:');
    console.log(JSON.stringify(addToCartButton, null, 2));

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    if (sessionId) {
      await steelClient.closeSession(sessionId);
      console.log('Session closed');
    }
  }
}

inspectPage();
