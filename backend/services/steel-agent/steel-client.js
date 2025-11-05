/**
 * Steel.dev AI Agent Client (Puppeteer Version)
 * Browser automation using Puppeteer over WebSocket
 * Documentation: https://docs.steel.dev
 */

require('dotenv').config({ path: '../../.env' });
const puppeteer = require('puppeteer');
const logger = require('../../shared/config/logger');

const STEEL_API_KEY = process.env.STEEL_API_KEY;
const STEEL_API_BASE = 'https://api.steel.dev/v1';

/**
 * Create a new browser session
 * @param {Object} options - Session options
 * @returns {Promise<Object>} Session details with sessionId
 */
async function createSession(options = {}) {
  if (!STEEL_API_KEY) {
    throw new Error('STEEL_API_KEY not configured');
  }

  const response = await fetch(`${STEEL_API_BASE}/sessions`, {
    method: 'POST',
    headers: {
      'Steel-Api-Key': STEEL_API_KEY,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      ...options,
      useProxy: true,
      solveCaptchas: true
    })
  });

  if (!response.ok) {
    const error = await response.text();
    logger.error('Steel.dev session creation failed', {
      status: response.status,
      error
    });
    throw new Error(`Failed to create session: ${response.statusText}`);
  }

  const data = await response.json();
  logger.info('Steel.dev session created', {
    sessionId: data.id
  });

  return data;
}

/**
 * Connect to Steel session via Puppeteer
 * @param {string} sessionId - Session ID
 * @returns {Promise<{browser: Browser, page: Page}>} Connected browser and page
 */
async function connectToSession(sessionId) {
  if (!STEEL_API_KEY) {
    throw new Error('STEEL_API_KEY not configured');
  }

  const wsEndpoint = `wss://connect.steel.dev?apiKey=${STEEL_API_KEY}&sessionId=${sessionId}`;

  logger.info('Connecting to Steel session via WebSocket', { sessionId });

  const browser = await puppeteer.connect({
    browserWSEndpoint: wsEndpoint
  });

  const pages = await browser.pages();
  const page = pages.length > 0 ? pages[0] : await browser.newPage();

  logger.info('Connected to Steel browser session', { sessionId });

  return { browser, page };
}

/**
 * Navigate browser to URL
 * @param {string} sessionId - Active session ID
 * @param {string} url - URL to navigate to
 * @returns {Promise<Object>} Navigation result
 */
async function navigateToUrl(sessionId, url) {
  let browser, page;

  try {
    ({ browser, page } = await connectToSession(sessionId));

    await page.goto(url, {
      waitUntil: 'domcontentloaded',
      timeout: 60000
    });

    // Wait a bit more for dynamic content to load
    await new Promise(resolve => setTimeout(resolve, 2000));

    const title = await page.title();

    logger.info('Steel.dev navigation successful', {
      sessionId,
      url,
      title
    });

    await browser.disconnect();

    return { success: true, title, url };
  } catch (error) {
    if (browser) await browser.disconnect();

    logger.error('Steel.dev navigation failed', {
      sessionId,
      url,
      error: error.message
    });
    throw new Error(`Failed to navigate: ${error.message}`);
  }
}

/**
 * Click element using CSS selector or text
 * @param {string} sessionId - Active session ID
 * @param {string} selector - CSS selector or text to click
 * @returns {Promise<Object>} Click result
 */
async function clickElement(sessionId, selector) {
  let browser, page;

  try {
    ({ browser, page } = await connectToSession(sessionId));

    // Try as CSS selector first
    try {
      await page.waitForSelector(selector, { timeout: 5000 });
      await page.click(selector);
    } catch {
      // If CSS fails, try as text content using XPath
      const clicked = await page.evaluate((text) => {
        const xpath = `//*[contains(text(), '${text}') or @aria-label='${text}' or @title='${text}']`;
        const result = document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
        if (result.singleNodeValue) {
          result.singleNodeValue.click();
          return true;
        }
        return false;
      }, selector);

      if (!clicked) {
        throw new Error(`Element not found: ${selector}`);
      }
    }

    logger.info('Steel.dev element clicked', {
      sessionId,
      selector,
      success: true
    });

    await browser.disconnect();

    return { success: true };
  } catch (error) {
    if (browser) await browser.disconnect();

    logger.error('Steel.dev click failed', {
      sessionId,
      selector,
      error: error.message
    });
    throw new Error(`Failed to click element: ${error.message}`);
  }
}

/**
 * Take screenshot of current page
 * @param {string} sessionId - Active session ID
 * @returns {Promise<string>} Screenshot as base64
 */
async function takeScreenshot(sessionId) {
  let browser, page;

  try {
    ({ browser, page } = await connectToSession(sessionId));

    const screenshot = await page.screenshot({
      encoding: 'base64',
      fullPage: false
    });

    logger.info('Steel.dev screenshot captured', { sessionId });

    await browser.disconnect();

    return screenshot;
  } catch (error) {
    if (browser) await browser.disconnect();

    logger.error('Steel.dev screenshot failed', {
      sessionId,
      error: error.message
    });
    throw new Error(`Failed to take screenshot: ${error.message}`);
  }
}

/**
 * Execute JavaScript in the browser context
 * @param {string} sessionId - Active session ID
 * @param {string} code - JavaScript code to execute
 * @returns {Promise<any>} Execution result
 */
async function executeScript(sessionId, code) {
  let browser, page;

  try {
    ({ browser, page } = await connectToSession(sessionId));

    const result = await page.evaluate(code);

    logger.info('Steel.dev script executed', {
      sessionId,
      success: true
    });

    await browser.disconnect();

    return result;
  } catch (error) {
    if (browser) await browser.disconnect();

    logger.error('Steel.dev script execution failed', {
      sessionId,
      error: error.message
    });
    throw new Error(`Failed to execute script: ${error.message}`);
  }
}

/**
 * Get current URL
 * @param {string} sessionId - Active session ID
 * @returns {Promise<string>} Current URL
 */
async function getCurrentUrl(sessionId) {
  let browser, page;

  try {
    ({ browser, page } = await connectToSession(sessionId));

    const url = await page.url();

    await browser.disconnect();

    return url;
  } catch (error) {
    if (browser) await browser.disconnect();
    throw new Error(`Failed to get current URL: ${error.message}`);
  }
}

/**
 * Close browser session
 * @param {string} sessionId - Session ID to close
 * @returns {Promise<void>}
 */
async function closeSession(sessionId) {
  if (!STEEL_API_KEY) {
    throw new Error('STEEL_API_KEY not configured');
  }

  const response = await fetch(`${STEEL_API_BASE}/sessions/${sessionId}`, {
    method: 'DELETE',
    headers: {
      'Steel-Api-Key': STEEL_API_KEY
    }
  });

  if (!response.ok) {
    logger.warn('Failed to close Steel.dev session', {
      sessionId,
      status: response.status
    });
  } else {
    logger.info('Steel.dev session closed', { sessionId });
  }
}

module.exports = {
  createSession,
  connectToSession,
  navigateToUrl,
  clickElement,
  takeScreenshot,
  executeScript,
  getCurrentUrl,
  closeSession
};
