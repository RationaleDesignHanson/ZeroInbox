/**
 * Shopping Automation Service
 * Uses Steel.dev browser automation to add items to cart and navigate to checkout
 *
 * Supports major e-commerce platforms:
 * - Amazon
 * - Shopify stores
 * - Walmart
 * - Target
 * - Etsy
 * - WooCommerce
 * - And generic e-commerce sites
 */

const steelClient = require('./steel-client');

/**
 * Platform Detection
 * Identifies e-commerce platform from product URL
 */
const PLATFORMS = {
  AMAZON: {
    name: 'Amazon',
    domains: ['amazon.com', 'amazon.ca', 'amazon.co.uk', 'amazon.de', 'amazon.fr', 'amazon.co.jp'],
    addToCartSelectors: [
      '#add-to-cart-button',
      '#add-to-basket-button',
      'input[name="submit.add-to-cart"]',
      'Add to Cart',  // Text fallback
      'Add to Basket'
    ],
    checkoutSelectors: [
      'a[href*="/cart"]',
      '#nav-cart',
      '[data-csa-c-content-id="nav_cart"]',
      'Proceed to checkout',
      'Go to Cart'
    ],
    cartUrl: '/cart'
  },
  SHOPIFY: {
    name: 'Shopify',
    domains: ['myshopify.com'],
    indicators: ['cdn.shopify.com', '/cart/add'],
    addToCartSelectors: [
      'button[name="add"]',
      'button[type="submit"][name="add"]',
      '.product-form__submit',
      'Add to cart',
      'Add to bag'
    ],
    checkoutSelectors: [
      'a[href="/cart"]',
      '.cart-link',
      '[href*="/checkout"]',
      'Checkout',
      'View cart'
    ],
    cartUrl: '/cart'
  },
  WALMART: {
    name: 'Walmart',
    domains: ['walmart.com'],
    addToCartSelectors: [
      'button[data-automation-id="add-to-cart"]',
      'button[aria-label*="Add to cart"]',
      '[data-tl-id="ProductPage-AddToCartButton"]',
      'Add to cart'
    ],
    checkoutSelectors: [
      'a[href*="/cart"]',
      'button[aria-label*="Cart"]',
      '[data-automation-id="view-cart"]',
      'Go to checkout',
      'View cart'
    ],
    cartUrl: '/cart'
  },
  TARGET: {
    name: 'Target',
    domains: ['target.com'],
    addToCartSelectors: [
      'button[id^="addToCartButtonOrTextIdFor"]',
      'button[data-test="orderPickupButton"]',
      'button[aria-label*="Add to cart"]',
      'Add to cart'
    ],
    checkoutSelectors: [
      'a[data-test="@web/CartLink"]',
      'a[href="/cart"]',
      '[aria-label*="cart"]',
      'View cart & check out'
    ],
    cartUrl: '/cart'
  },
  ETSY: {
    name: 'Etsy',
    domains: ['etsy.com'],
    addToCartSelectors: [
      'button[data-buy-box-add-to-cart-button]',
      'button[name="add_to_cart"]',
      '.add-to-cart-button',
      'Add to cart'
    ],
    checkoutSelectors: [
      'a[href*="/cart"]',
      '.cart-link',
      '[data-selector="cart-icon"]',
      'Proceed to checkout'
    ],
    cartUrl: '/cart'
  },
  WOOCOMMERCE: {
    name: 'WooCommerce',
    indicators: ['wp-content', 'woocommerce', '?add-to-cart='],
    addToCartSelectors: [
      'button[name="add-to-cart"]',
      '.single_add_to_cart_button',
      'button.add_to_cart_button',
      'Add to cart'
    ],
    checkoutSelectors: [
      'a.cart-contents',
      'a[href*="/cart"]',
      '.woocommerce-cart-tab',
      'View cart',
      'Proceed to checkout'
    ],
    cartUrl: '/cart'
  },
  GENERIC: {
    name: 'Generic',
    addToCartSelectors: [
      'button[type="submit"]',
      'Add to cart',
      'Add to bag',
      'Add to basket',
      'Buy now'
    ],
    checkoutSelectors: [
      'a[href*="/cart"]',
      'a[href*="/checkout"]',
      '.cart-link',
      'Checkout',
      'View cart'
    ],
    cartUrl: '/cart'
  }
};

/**
 * Detect e-commerce platform from URL
 * @param {string} url - Product URL
 * @returns {Object} Platform configuration object
 */
function detectPlatform(url) {
  const urlObj = new URL(url);
  const hostname = urlObj.hostname.toLowerCase();

  // Check known platforms by domain
  for (const [key, platform] of Object.entries(PLATFORMS)) {
    if (platform.domains) {
      if (platform.domains.some(domain => hostname.includes(domain))) {
        return { id: key, ...platform };
      }
    }
  }

  // Check platforms by page content indicators (requires page load)
  // For now, return GENERIC
  return { id: 'GENERIC', ...PLATFORMS.GENERIC };
}

/**
 * Main function: Automate adding product to cart and navigate to checkout
 * @param {string} productUrl - URL of product page
 * @param {string} productName - Name of product (for error messages)
 * @param {string} userSessionId - User session ID for tracking
 * @returns {Promise<Object>} Result with success status, checkout URL, and screenshots
 */
async function automateAddToCart(productUrl, productName, userSessionId) {
  let sessionId = null;
  const result = {
    success: false,
    checkoutUrl: null,
    cartUrl: null,
    screenshots: [],
    steps: [],
    error: null
  };

  try {
    console.log(`[Shopping Automation] Starting automation for: ${productName}`);
    console.log(`[Shopping Automation] Product URL: ${productUrl}`);

    // Step 1: Detect platform
    const platform = detectPlatform(productUrl);
    console.log(`[Shopping Automation] Detected platform: ${platform.name}`);
    result.steps.push({ step: 'detect_platform', platform: platform.name, success: true });

    // Step 2: Create Steel browser session
    console.log('[Shopping Automation] Creating Steel browser session...');
    const session = await steelClient.createSession({
      userSessionId,
      solveCaptcha: true,
      useProxy: true
    });
    sessionId = session.id;  // Extract just the session ID
    console.log(`[Shopping Automation] Session created: ${sessionId}`);
    result.steps.push({ step: 'create_session', sessionId, success: true });

    // Step 3: Navigate to product page
    console.log(`[Shopping Automation] Navigating to product page...`);
    const pageContent = await steelClient.navigateToUrl(sessionId, productUrl);
    console.log('[Shopping Automation] Product page loaded');
    result.steps.push({ step: 'navigate_to_product', success: true });

    // Take screenshot of product page
    const productScreenshot = await steelClient.takeScreenshot(sessionId);
    result.screenshots.push({
      step: 'product_page',
      data: productScreenshot,
      timestamp: new Date().toISOString()
    });

    // Step 4: Find and click "Add to Cart" button
    console.log('[Shopping Automation] Looking for "Add to Cart" button...');
    let addToCartSuccess = false;
    let lastError = null;

    for (const selector of platform.addToCartSelectors) {
      try {
        console.log(`[Shopping Automation] Trying selector: ${selector}`);
        const clickResult = await steelClient.clickElement(sessionId, selector);

        if (clickResult && clickResult.success) {
          console.log('[Shopping Automation] Successfully clicked "Add to Cart"');
          addToCartSuccess = true;
          result.steps.push({
            step: 'click_add_to_cart',
            selector,
            success: true
          });
          break;
        }
      } catch (error) {
        console.warn(`[Shopping Automation] Selector failed: ${selector}`, error.message);
        lastError = error;
      }
    }

    if (!addToCartSuccess) {
      throw new Error(`Could not find "Add to Cart" button. Last error: ${lastError?.message || 'Unknown'}`);
    }

    // Wait for cart update (2 seconds)
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Take screenshot after adding to cart
    const cartAddedScreenshot = await steelClient.takeScreenshot(sessionId);
    result.screenshots.push({
      step: 'added_to_cart',
      data: cartAddedScreenshot,
      timestamp: new Date().toISOString()
    });

    // Step 5: Find and click checkout/cart button
    console.log('[Shopping Automation] Looking for checkout button...');
    let checkoutSuccess = false;

    for (const selector of platform.checkoutSelectors) {
      try {
        console.log(`[Shopping Automation] Trying selector: ${selector}`);
        const clickResult = await steelClient.clickElement(sessionId, selector);

        if (clickResult && clickResult.success) {
          console.log('[Shopping Automation] Successfully clicked checkout button');
          checkoutSuccess = true;
          result.steps.push({
            step: 'click_checkout',
            selector,
            success: true
          });
          break;
        }
      } catch (error) {
        console.warn(`[Shopping Automation] Selector failed: ${selector}`, error.message);
      }
    }

    // Wait for navigation (2 seconds)
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Step 6: Get final URL (cart or checkout page)
    const finalUrl = await steelClient.getCurrentUrl(sessionId);
    console.log(`[Shopping Automation] Final URL: ${finalUrl}`);

    // Take final screenshot
    const finalScreenshot = await steelClient.takeScreenshot(sessionId);
    result.screenshots.push({
      step: 'checkout_page',
      data: finalScreenshot,
      timestamp: new Date().toISOString()
    });

    // Determine if we reached checkout or cart
    const urlObj = new URL(productUrl);
    const baseUrl = `${urlObj.protocol}//${urlObj.hostname}`;

    if (checkoutSuccess || finalUrl.includes('checkout') || finalUrl.includes('cart')) {
      result.success = true;
      result.checkoutUrl = finalUrl;
      result.cartUrl = finalUrl.includes('cart') ? finalUrl : `${baseUrl}${platform.cartUrl}`;
      result.steps.push({
        step: 'complete',
        success: true,
        finalUrl
      });
    } else {
      // Fallback: construct cart URL
      result.success = true;
      result.cartUrl = `${baseUrl}${platform.cartUrl}`;
      result.checkoutUrl = result.cartUrl;
      result.steps.push({
        step: 'complete_with_fallback',
        success: true,
        constructedUrl: result.cartUrl
      });
    }

    console.log('[Shopping Automation] Automation completed successfully!');
    console.log(`[Shopping Automation] Checkout URL: ${result.checkoutUrl}`);

  } catch (error) {
    console.error('[Shopping Automation] Automation failed:', error);
    result.error = error.message;
    result.steps.push({
      step: 'error',
      error: error.message,
      success: false
    });

    // Take error screenshot if session exists
    if (sessionId) {
      try {
        const errorScreenshot = await steelClient.takeScreenshot(sessionId);
        result.screenshots.push({
          step: 'error',
          data: errorScreenshot,
          timestamp: new Date().toISOString()
        });
      } catch (screenshotError) {
        console.warn('[Shopping Automation] Could not capture error screenshot:', screenshotError);
      }
    }
  } finally {
    // Clean up Steel session
    if (sessionId) {
      try {
        await steelClient.closeSession(sessionId);
        console.log('[Shopping Automation] Steel session closed');
      } catch (closeError) {
        console.warn('[Shopping Automation] Error closing session:', closeError);
      }
    }
  }

  return result;
}

/**
 * Get platform information for a URL (diagnostic endpoint)
 * @param {string} url - Product URL
 * @returns {Object} Platform configuration
 */
function getPlatformInfo(url) {
  const platform = detectPlatform(url);
  return {
    url,
    platform: platform.name,
    platformId: platform.id,
    addToCartSelectors: platform.addToCartSelectors,
    checkoutSelectors: platform.checkoutSelectors
  };
}

module.exports = {
  automateAddToCart,
  getPlatformInfo,
  PLATFORMS
};
