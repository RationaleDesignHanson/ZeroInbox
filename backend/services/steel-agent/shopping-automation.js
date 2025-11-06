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

// Store active sessions with timeouts for cleanup
const activeSessions = new Map();

// Session timeout: 30 minutes
const SESSION_TIMEOUT_MS = 30 * 60 * 1000;

/**
 * Schedule session cleanup after timeout
 * @param {string} sessionId - Session ID to clean up
 */
function scheduleSessionCleanup(sessionId) {
  const timeoutId = setTimeout(async () => {
    try {
      await steelClient.closeSession(sessionId);
      activeSessions.delete(sessionId);
      console.log(`[Shopping Automation] Session ${sessionId} cleaned up after timeout`);
    } catch (error) {
      console.warn(`[Shopping Automation] Error cleaning up session ${sessionId}:`, error);
    }
  }, SESSION_TIMEOUT_MS);

  activeSessions.set(sessionId, {
    timeoutId,
    createdAt: new Date().toISOString()
  });
}

/**
 * Manually close a session before timeout
 * @param {string} sessionId - Session ID to close
 */
async function closeSessionEarly(sessionId) {
  const sessionData = activeSessions.get(sessionId);
  if (sessionData) {
    clearTimeout(sessionData.timeoutId);
    activeSessions.delete(sessionId);
  }

  try {
    await steelClient.closeSession(sessionId);
    console.log(`[Shopping Automation] Session ${sessionId} closed manually`);
  } catch (error) {
    console.warn(`[Shopping Automation] Error closing session ${sessionId}:`, error);
  }
}

/**
 * Platform Detection
 * Identifies e-commerce platform from product URL
 */
const PLATFORMS = {
  AMAZON: {
    name: 'Amazon',
    domains: ['amazon.com', 'amazon.ca', 'amazon.co.uk', 'amazon.de', 'amazon.fr', 'amazon.co.jp'],
    addToCartSelectors: [
      // Modern Amazon selectors (2024+)
      '#add-to-cart-button',
      '#add-to-basket-button',
      'input[name="submit.add-to-cart"]',
      'button[name="submit.add-to-cart"]',
      'span[id="submit.add-to-cart"]',
      // One-click and alternative buttons
      '#buy-now-button',
      'input[name="submit.buy-now"]',
      // Fallback by aria-label
      'button[aria-label*="Add to Cart"]',
      'button[aria-label*="Add to Basket"]',
      'input[aria-label*="Add to Cart"]',
      // Text-based fallbacks
      'Add to Cart',
      'Add to Basket',
      'Add to Shopping Cart'
    ],
    checkoutSelectors: [
      // Cart icon in nav
      '#nav-cart',
      '#nav-cart-count',
      'a[href="/gp/cart/view.html"]',
      'a[href*="/cart"]',
      '[data-csa-c-content-id="nav_cart"]',
      // Proceed to checkout buttons
      'input[name="proceedToCheckout"]',
      'button[name="proceedToCheckout"]',
      'a[href*="/checkout"]',
      // Text-based
      'Proceed to checkout',
      'Go to Cart',
      'View Cart'
    ],
    cartUrl: '/gp/cart/view.html'
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
      // Priority: Ship It button (adds directly to cart, no modal)
      'button[data-test="shipItButton"]',
      'button[data-test="shippingButton"]',
      'button:has-text("Ship it")',
      'Ship it',
      // Legacy direct add to cart buttons
      'button[id^="addToCartButton"]',
      'button[id*="addToCart"]',
      'button[data-test="addToCartButton"]',
      'button[aria-label*="Add to cart"]',
      'button[aria-label*="add to cart"]',
      'Add to cart',
      // Lower priority: Order Pickup (requires modal confirmation)
      'button[data-test="orderPickupButton"]'
    ],
    // Modal confirmation selectors for Order Pickup flow
    modalConfirmSelectors: [
      'button[data-test="orderPickupButton"]', // After selecting store
      'button[data-test="storePickupButton"]',
      'button[data-test="fulfillmentAddToCartButton"]',
      'button:has-text("Add to cart")',
      'Add to cart'
    ],
    checkoutSelectors: [
      // Cart link in header
      'a[data-test="@web/CartLink"]',
      'a[data-test="cart-link"]',
      'a[href="/cart"]',
      'a[href*="/cart"]',
      // Cart icon/count
      '[data-test="@web/CartIcon"]',
      'button[aria-label*="cart"]',
      '[aria-label*="View cart"]',
      // Text-based
      'View cart',
      'View cart & check out',
      'Go to cart'
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
  EBAY: {
    name: 'eBay',
    domains: ['ebay.com'],
    addToCartSelectors: [
      // Modern eBay selectors
      'a[data-testid="ux-call-to-action"]',
      '#atcBtn_btn_1',
      'button[data-test-id="add-to-cart-button"]',
      'a.ux-call-to-action',
      // Legacy selectors
      'a#atcRedesignId_btn',
      'button[data-testid="x-atc-action"]',
      // Text-based
      'Add to cart',
      'Add to watchlist' // Some items only have watchlist
    ],
    checkoutSelectors: [
      // Cart icon/link
      'a[href*="/sh/cart"]',
      'i.gh-eb-Minicart',
      '[data-testid="cart-icon"]',
      '#gh-cart-n',
      // Text-based
      'Go to cart',
      'View in cart'
    ],
    cartUrl: '/sh/cart'
  },
  BESTBUY: {
    name: 'Best Buy',
    domains: ['bestbuy.com'],
    addToCartSelectors: [
      // Modern Best Buy selectors
      'button[data-button-state="ADD_TO_CART"]',
      'button.add-to-cart-button',
      'button[data-track="Add to Cart"]',
      'button.c-button-primary:has-text("Add to Cart")',
      // Legacy selectors
      '.add-to-cart-button',
      'button[type="button"]:has-text("Add to Cart")',
      // Text-based
      'Add to Cart'
    ],
    checkoutSelectors: [
      // Cart icon/link
      'a[href*="/cart"]',
      'a.c-button-cart',
      '[aria-label*="Cart"]',
      'button[aria-label*="Cart"]',
      // Text-based
      'Go to cart',
      'Checkout'
    ],
    cartUrl: '/cart'
  },
  HOMEDEPOT: {
    name: 'Home Depot',
    domains: ['homedepot.com'],
    addToCartSelectors: [
      // Modern Home Depot selectors
      'button[data-testid="add-to-cart"]',
      'button#add-to-cart',
      'button.bttn__primary--large',
      'button[data-automation-id="atc-button"]',
      // Legacy selectors
      '.add-to-cart',
      'button:has-text("Add to Cart")',
      // Text-based
      'Add to Cart'
    ],
    checkoutSelectors: [
      // Cart icon/link
      'a[data-testid="cart-icon"]',
      'a[href*="/mycart"]',
      '#headerMyCart',
      // Text-based
      'View Cart',
      'Checkout'
    ],
    cartUrl: '/mycart/home'
  },
  LOWES: {
    name: "Lowe's",
    domains: ['lowes.com'],
    addToCartSelectors: [
      // Modern Lowe's selectors
      'button[aria-label*="Add to Cart"]',
      'button.btn-primary:has-text("Add to Cart")',
      '#add-to-cart-btn',
      'button[data-selector="add-to-cart"]',
      // Text-based
      'Add to Cart'
    ],
    checkoutSelectors: [
      // Cart icon/link
      'a[href*="/cart"]',
      'a.cart-link',
      '[aria-label*="Cart"]',
      // Text-based
      'View Cart',
      'Proceed to Checkout'
    ],
    cartUrl: '/cart'
  },
  COSTCO: {
    name: 'Costco',
    domains: ['costco.com'],
    addToCartSelectors: [
      // Costco selectors
      'button#add-to-cart-btn',
      'input[name="add-to-cart"]',
      'button.add-to-cart',
      'button[aria-label*="Add to Cart"]',
      // Text-based
      'Add to Cart',
      'Add'
    ],
    checkoutSelectors: [
      // Cart icon/link
      'a[href*="/CheckoutCartView"]',
      '#shopping-cart-link',
      'a.cart-link',
      // Text-based
      'View Cart',
      'Checkout'
    ],
    cartUrl: '/CheckoutCartView'
  },
  WAYFAIR: {
    name: 'Wayfair',
    domains: ['wayfair.com'],
    addToCartSelectors: [
      // Wayfair selectors
      'button[data-enzyme-id="addToCart"]',
      'button.Button--primary:has-text("Add to Cart")',
      '[data-hb-id="AddToCart"]',
      // Text-based
      'Add to Cart'
    ],
    checkoutSelectors: [
      // Cart icon/link
      'a[href*="/v/cart"]',
      'a[data-hb-id="MiniCartLink"]',
      '[aria-label*="Cart"]',
      // Text-based
      'View Cart',
      'Checkout'
    ],
    cartUrl: '/v/cart'
  },
  TEMU: {
    name: 'Temu',
    domains: ['temu.com'],
    addToCartSelectors: [
      // Temu selectors (app-based, may be challenging)
      'button[data-testid="beast-core-button-add-to-cart"]',
      'button:has-text("Add to Cart")',
      '.add-to-cart-btn',
      // Text-based
      'Add to Cart',
      'Add to Bag'
    ],
    checkoutSelectors: [
      // Cart icon/link
      'a[href*="/cart"]',
      '[data-testid="cart-icon"]',
      // Text-based
      'View Cart',
      'Checkout'
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
  let sessionViewerUrl = null;
  const result = {
    success: false,
    checkoutUrl: null,
    cartUrl: null,
    sessionId: null,
    sessionViewerUrl: null,
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
    sessionId = session.id;
    sessionViewerUrl = session.viewerUrl || session.liveViewUrl || `https://app.steel.dev/sessions/${sessionId}`;
    console.log(`[Shopping Automation] Session created: ${sessionId}`);
    console.log(`[Shopping Automation] Session viewer URL: ${sessionViewerUrl}`);
    result.sessionId = sessionId;
    result.sessionViewerUrl = sessionViewerUrl;
    result.steps.push({ step: 'create_session', sessionId, sessionViewerUrl, success: true });

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
    console.log(`[Shopping Automation] Platform: ${platform.name}, trying ${platform.addToCartSelectors.length} selectors`);
    let addToCartSuccess = false;
    let lastError = null;
    let attemptedSelectors = [];

    for (const selector of platform.addToCartSelectors) {
      try {
        console.log(`[Shopping Automation] [${attemptedSelectors.length + 1}/${platform.addToCartSelectors.length}] Trying selector: ${selector}`);
        attemptedSelectors.push(selector);

        const clickResult = await steelClient.clickElement(sessionId, selector);

        if (clickResult && clickResult.success) {
          console.log(`[Shopping Automation] ✅ SUCCESS! Clicked "Add to Cart" using selector: ${selector}`);
          addToCartSuccess = true;
          result.steps.push({
            step: 'click_add_to_cart',
            selector,
            success: true,
            attemptedSelectors: attemptedSelectors.length
          });
          break;
        } else {
          console.log(`[Shopping Automation] ❌ Selector found but click failed: ${selector}`);
        }
      } catch (error) {
        console.warn(`[Shopping Automation] ❌ Selector not found or error: ${selector} - ${error.message}`);
        lastError = error;
      }
    }

    if (!addToCartSuccess) {
      const errorMsg = `Could not find "Add to Cart" button after trying ${attemptedSelectors.length} selectors. Last error: ${lastError?.message || 'Unknown'}`;
      console.error(`[Shopping Automation] ${errorMsg}`);
      console.error(`[Shopping Automation] Attempted selectors: ${attemptedSelectors.join(', ')}`);
      throw new Error(errorMsg);
    }

    // Wait for cart update or modal (3 seconds)
    await new Promise(resolve => setTimeout(resolve, 3000));

    // Step 4.5: Handle modal confirmations (for Target Order Pickup, etc.)
    if (platform.modalConfirmSelectors && platform.modalConfirmSelectors.length > 0) {
      console.log('[Shopping Automation] Checking for modal confirmation dialogs...');
      for (const modalSelector of platform.modalConfirmSelectors) {
        try {
          console.log(`[Shopping Automation] Looking for modal button: ${modalSelector}`);
          const modalClickResult = await steelClient.clickElement(sessionId, modalSelector);
          if (modalClickResult && modalClickResult.success) {
            console.log(`[Shopping Automation] ✅ Clicked modal confirmation: ${modalSelector}`);
            result.steps.push({
              step: 'click_modal_confirm',
              selector: modalSelector,
              success: true
            });
            // Wait for modal action to complete
            await new Promise(resolve => setTimeout(resolve, 2000));
            break;
          }
        } catch (error) {
          // Modal not found, continue
          console.log(`[Shopping Automation] No modal found for: ${modalSelector}`);
        }
      }
    }

    // Take screenshot after adding to cart
    const cartAddedScreenshot = await steelClient.takeScreenshot(sessionId);
    result.screenshots.push({
      step: 'added_to_cart',
      data: cartAddedScreenshot,
      timestamp: new Date().toISOString()
    });

    // Step 5: Find and click checkout/cart button
    console.log('[Shopping Automation] Looking for checkout/cart button...');
    console.log(`[Shopping Automation] Trying ${platform.checkoutSelectors.length} checkout selectors`);
    let checkoutSuccess = false;
    let attemptedCheckoutSelectors = [];

    for (const selector of platform.checkoutSelectors) {
      try {
        console.log(`[Shopping Automation] [${attemptedCheckoutSelectors.length + 1}/${platform.checkoutSelectors.length}] Trying selector: ${selector}`);
        attemptedCheckoutSelectors.push(selector);

        const clickResult = await steelClient.clickElement(sessionId, selector);

        if (clickResult && clickResult.success) {
          console.log(`[Shopping Automation] ✅ SUCCESS! Clicked checkout button using selector: ${selector}`);
          checkoutSuccess = true;
          result.steps.push({
            step: 'click_checkout',
            selector,
            success: true,
            attemptedSelectors: attemptedCheckoutSelectors.length
          });
          break;
        } else {
          console.log(`[Shopping Automation] ❌ Selector found but click failed: ${selector}`);
        }
      } catch (error) {
        console.warn(`[Shopping Automation] ❌ Checkout selector not found or error: ${selector} - ${error.message}`);
      }
    }

    if (!checkoutSuccess) {
      console.warn(`[Shopping Automation] ⚠️ Could not click checkout after ${attemptedCheckoutSelectors.length} attempts`);
      console.warn(`[Shopping Automation] Will try to navigate to cart URL directly`);
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

    // Success if:
    // 1. We clicked checkout/cart button successfully
    // 2. URL contains 'checkout' or 'cart'
    // 3. We added to cart successfully (even if still on product page)
    if (checkoutSuccess || finalUrl.includes('checkout') || finalUrl.includes('cart') || addToCartSuccess) {
      result.success = true;
      // If URL is cart/checkout, use it. Otherwise construct cart URL
      if (finalUrl.includes('cart') || finalUrl.includes('checkout')) {
        result.checkoutUrl = finalUrl;
        result.cartUrl = finalUrl;
      } else {
        // Still on product page but item was added - link to cart
        result.cartUrl = `${baseUrl}${platform.cartUrl}`;
        result.checkoutUrl = result.cartUrl;
      }
      result.steps.push({
        step: 'complete',
        success: true,
        finalUrl,
        note: finalUrl.includes('cart') ? 'Navigated to cart' : 'Item added to cart successfully'
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

    // If automation failed, close session immediately instead of keeping it alive
    if (sessionId) {
      try {
        await steelClient.closeSession(sessionId);
        console.log('[Shopping Automation] Steel session closed due to error');
      } catch (closeError) {
        console.warn('[Shopping Automation] Error closing session:', closeError);
      }
    }
  }

  // Schedule session cleanup after timeout (only if automation succeeded)
  if (result.success && sessionId) {
    scheduleSessionCleanup(sessionId);
    console.log(`[Shopping Automation] Session ${sessionId} will be cleaned up in ${SESSION_TIMEOUT_MS / 60000} minutes`);
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
  closeSessionEarly,
  PLATFORMS
};
