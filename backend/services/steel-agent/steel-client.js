/**
 * Steel.dev AI Agent Client
 * Browser automation for subscription cancellation assistance
 * Documentation: https://docs.steel.dev
 */

require('dotenv').config();
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
      'Authorization': `Bearer ${STEEL_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      ...options,
      useProxy: true, // Use residential proxy for anti-bot protection
      solveCaptchas: true // Auto-solve CAPTCHAs
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
    sessionId: data.sessionId
  });

  return data;
}

/**
 * Navigate browser to URL and extract page content
 * @param {string} sessionId - Active session ID
 * @param {string} url - URL to navigate to
 * @returns {Promise<Object>} Page content and metadata
 */
async function navigateToUrl(sessionId, url) {
  if (!STEEL_API_KEY) {
    throw new Error('STEEL_API_KEY not configured');
  }

  const response = await fetch(`${STEEL_API_BASE}/sessions/${sessionId}/navigate`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${STEEL_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ url })
  });

  if (!response.ok) {
    const error = await response.text();
    logger.error('Steel.dev navigation failed', {
      sessionId,
      url,
      status: response.status,
      error
    });
    throw new Error(`Failed to navigate: ${response.statusText}`);
  }

  const data = await response.json();
  logger.info('Steel.dev navigation successful', {
    sessionId,
    url,
    title: data.title
  });

  return data;
}

/**
 * Execute JavaScript in the browser context
 * @param {string} sessionId - Active session ID
 * @param {string} code - JavaScript code to execute
 * @returns {Promise<Object>} Execution result
 */
async function executeScript(sessionId, code) {
  if (!STEEL_API_KEY) {
    throw new Error('STEEL_API_KEY not configured');
  }

  const response = await fetch(`${STEEL_API_BASE}/sessions/${sessionId}/execute`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${STEEL_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ code })
  });

  if (!response.ok) {
    const error = await response.text();
    logger.error('Steel.dev script execution failed', {
      sessionId,
      status: response.status,
      error
    });
    throw new Error(`Failed to execute script: ${response.statusText}`);
  }

  const data = await response.json();
  logger.info('Steel.dev script executed', {
    sessionId,
    success: data.success
  });

  return data;
}

/**
 * Take screenshot of current page
 * @param {string} sessionId - Active session ID
 * @returns {Promise<Object>} Screenshot data (base64)
 */
async function takeScreenshot(sessionId) {
  if (!STEEL_API_KEY) {
    throw new Error('STEEL_API_KEY not configured');
  }

  const response = await fetch(`${STEEL_API_BASE}/sessions/${sessionId}/screenshot`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${STEEL_API_KEY}`
    }
  });

  if (!response.ok) {
    const error = await response.text();
    logger.error('Steel.dev screenshot failed', {
      sessionId,
      status: response.status,
      error
    });
    throw new Error(`Failed to take screenshot: ${response.statusText}`);
  }

  const data = await response.json();
  logger.info('Steel.dev screenshot captured', {
    sessionId
  });

  return data;
}

/**
 * Get visible text from page using natural language query
 * @param {string} sessionId - Active session ID
 * @param {string} query - Natural language query (e.g., "Find the cancel button")
 * @returns {Promise<Object>} Query result with element info
 */
async function queryPage(sessionId, query) {
  if (!STEEL_API_KEY) {
    throw new Error('STEEL_API_KEY not configured');
  }

  const response = await fetch(`${STEEL_API_BASE}/sessions/${sessionId}/query`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${STEEL_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ query })
  });

  if (!response.ok) {
    const error = await response.text();
    logger.error('Steel.dev page query failed', {
      sessionId,
      query,
      status: response.status,
      error
    });
    throw new Error(`Failed to query page: ${response.statusText}`);
  }

  const data = await response.json();
  logger.info('Steel.dev page query successful', {
    sessionId,
    query,
    found: data.found
  });

  return data;
}

/**
 * Click element using natural language description
 * @param {string} sessionId - Active session ID
 * @param {string} description - Natural language element description
 * @returns {Promise<Object>} Click result
 */
async function clickElement(sessionId, description) {
  if (!STEEL_API_KEY) {
    throw new Error('STEEL_API_KEY not configured');
  }

  const response = await fetch(`${STEEL_API_BASE}/sessions/${sessionId}/click`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${STEEL_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ description })
  });

  if (!response.ok) {
    const error = await response.text();
    logger.error('Steel.dev click failed', {
      sessionId,
      description,
      status: response.status,
      error
    });
    throw new Error(`Failed to click element: ${response.statusText}`);
  }

  const data = await response.json();
  logger.info('Steel.dev element clicked', {
    sessionId,
    description,
    success: data.success
  });

  return data;
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
      'Authorization': `Bearer ${STEEL_API_KEY}`
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

/**
 * Guided cancellation flow
 * Navigates to cancellation page and provides step-by-step guidance
 * @param {Object} service - Service object with cancellation info
 * @param {string} userSessionId - User's session identifier (for tracking)
 * @returns {Promise<Object>} Cancellation guidance with screenshots
 */
async function guideCancellation(service, userSessionId) {
  if (!service) {
    throw new Error('Service information required');
  }

  logger.info('Starting guided cancellation', {
    userSessionId,
    service: service.name
  });

  let session = null;
  const steps = [];

  try {
    // Create browser session
    session = await createSession({
      sessionName: `cancel-${service.name.replace(/\s+/g, '-').toLowerCase()}-${userSessionId}`
    });

    const { sessionId } = session;

    // Step 1: Navigate to account/cancellation page
    const targetUrl = service.cancellationUrl || service.accountPageUrl;
    const pageData = await navigateToUrl(sessionId, targetUrl);

    steps.push({
      step: 1,
      action: 'navigate',
      description: `Navigate to ${service.name} cancellation page`,
      url: targetUrl,
      pageTitle: pageData.title,
      success: true
    });

    // Step 2: Take screenshot for user reference
    const screenshot = await takeScreenshot(sessionId);
    steps.push({
      step: 2,
      action: 'screenshot',
      description: 'Capture current page state',
      screenshot: screenshot.data, // base64 image
      success: true
    });

    // Step 3: Look for cancellation-related elements
    const cancelQuery = await queryPage(
      sessionId,
      'Find buttons or links related to canceling subscription, membership, or plan'
    );

    steps.push({
      step: 3,
      action: 'detect_elements',
      description: 'Identify cancellation options on page',
      found: cancelQuery.found,
      elements: cancelQuery.elements || [],
      success: true
    });

    // Return guidance to user
    return {
      success: true,
      sessionId, // User can continue in their own browser
      serviceName: service.name,
      steps,
      nextSteps: service.cancellationSteps,
      requiresLogin: service.requiresLogin,
      note: service.note || null
    };

  } catch (error) {
    logger.error('Guided cancellation failed', {
      userSessionId,
      service: service.name,
      error: error.message,
      stack: error.stack
    });

    return {
      success: false,
      error: error.message,
      serviceName: service.name,
      steps,
      fallbackUrl: service.accountPageUrl
    };

  } finally {
    // Always close session to avoid charges
    if (session && session.sessionId) {
      await closeSession(session.sessionId);
    }
  }
}

module.exports = {
  createSession,
  navigateToUrl,
  executeScript,
  takeScreenshot,
  queryPage,
  clickElement,
  closeSession,
  guideCancellation
};
