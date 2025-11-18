/**
 * Unsubscribe Service
 *
 * Manages safe unsubscribe operations with comprehensive safety checks.
 * Integrates with safelist to prevent dangerous unsubscribes.
 *
 * SAFETY FIRST: This service will NEVER unsubscribe from banking, medical,
 * security, utility, or government emails.
 */

const safelist = require('./safelist');

/**
 * Parse List-Unsubscribe header (RFC 2369 / RFC 8058)
 * Example: List-Unsubscribe: <mailto:unsub@example.com>, <https://example.com/unsub>
 * @param {string} header - The List-Unsubscribe header value
 * @returns {object} - { mailto: string|null, urls: string[], oneClick: boolean }
 */
function parseListUnsubscribeHeader(header) {
  if (!header) {
    return { mailto: null, urls: [], oneClick: false };
  }

  const mailto = [];
  const urls = [];

  // Parse comma-separated list of <url> or <mailto:address>
  const items = header.split(',').map(s => s.trim());

  for (const item of items) {
    // Extract URL/mailto from angle brackets
    const match = item.match(/<([^>]+)>/);
    if (match) {
      const value = match[1];
      if (value.startsWith('mailto:')) {
        mailto.push(value);
      } else if (value.startsWith('http://') || value.startsWith('https://')) {
        urls.push(value);
      }
    }
  }

  return {
    mailto: mailto.length > 0 ? mailto[0] : null,
    urls,
    oneClick: false  // Will be set by checkOneClickSupport()
  };
}

/**
 * Check if email supports One-Click unsubscribe (RFC 8058)
 * Requires both List-Unsubscribe and List-Unsubscribe-Post headers
 * @param {object} headers - Email headers object
 * @returns {boolean} - True if One-Click unsubscribe is supported
 */
function checkOneClickSupport(headers) {
  if (!headers) return false;

  const hasListUnsubscribe = 'List-Unsubscribe' in headers || 'list-unsubscribe' in headers;
  const hasListUnsubscribePost = 'List-Unsubscribe-Post' in headers || 'list-unsubscribe-post' in headers;

  return hasListUnsubscribe && hasListUnsubscribePost;
}

/**
 * Extract unsubscribe URLs from HTML body
 * Looks for common patterns like "unsubscribe", "opt-out", "preferences"
 * @param {string} htmlBody - Email HTML body
 * @returns {string[]} - Array of unsubscribe URLs found
 */
function extractUnsubscribeURLs(htmlBody) {
  if (!htmlBody) return [];

  const urls = [];
  const urlPatterns = [
    // href="https://example.com/unsubscribe..."
    /href=["']([^"']*(?:unsubscribe|opt[-_]?out|preferences|email[-_]?settings)[^"']*)["']/gi,
    // <a ...>https://example.com/unsubscribe...</a>
    />([^<]*(?:unsubscribe|opt[-_]?out|preferences)[^<]*)</gi
  ];

  for (const pattern of urlPatterns) {
    let match;
    while ((match = pattern.exec(htmlBody)) !== null) {
      const url = match[1];
      // Only include valid HTTP(S) URLs
      if (url && (url.startsWith('http://') || url.startsWith('https://')) && !urls.includes(url)) {
        urls.push(url);
      }
    }
  }

  return urls;
}

/**
 * Parse all unsubscribe mechanisms from an email
 * @param {object} email - Email object with headers and body
 * @returns {object} - Unsubscribe mechanisms found
 */
function parseUnsubscribeMechanism(email) {
  if (!email) {
    return {
      hasListUnsubscribe: false,
      hasOneClick: false,
      mailto: null,
      headerUrls: [],
      bodyUrls: [],
      allUrls: [],
      preferredMethod: null
    };
  }

  const { headers = {}, body = {} } = email;

  // Parse List-Unsubscribe header
  const listUnsubHeader = headers['List-Unsubscribe'] || headers['list-unsubscribe'] || null;
  const headerParsed = parseListUnsubscribeHeader(listUnsubHeader);

  // Check One-Click support
  const hasOneClick = checkOneClickSupport(headers);
  if (hasOneClick) {
    headerParsed.oneClick = true;
  }

  // Extract URLs from HTML body
  const bodyUrls = extractUnsubscribeURLs(body.html || '');

  // Combine all URLs
  const allUrls = [...new Set([...headerParsed.urls, ...bodyUrls])];

  // Determine preferred method (priority: One-Click > Header URL > Body URL > Mailto)
  let preferredMethod = null;
  if (hasOneClick && headerParsed.urls.length > 0) {
    preferredMethod = { type: 'one-click', url: headerParsed.urls[0] };
  } else if (headerParsed.urls.length > 0) {
    preferredMethod = { type: 'url', url: headerParsed.urls[0] };
  } else if (bodyUrls.length > 0) {
    preferredMethod = { type: 'url', url: bodyUrls[0] };
  } else if (headerParsed.mailto) {
    preferredMethod = { type: 'mailto', address: headerParsed.mailto };
  }

  return {
    hasListUnsubscribe: !!listUnsubHeader,
    hasOneClick,
    mailto: headerParsed.mailto,
    headerUrls: headerParsed.urls,
    bodyUrls,
    allUrls,
    preferredMethod
  };
}

/**
 * Check if an email can be safely unsubscribed
 * Combines safelist checks with unsubscribe mechanism detection
 * @param {object} email - Email object
 * @returns {object} - { canUnsubscribe: boolean, reason: string, mechanism: object }
 */
function canUnsubscribe(email) {
  if (!email) {
    return {
      canUnsubscribe: false,
      reason: 'Invalid email object',
      mechanism: null
    };
  }

  // Safety check #1: Safelist protection
  const safetyCheck = safelist.isSafeToUnsubscribe(email);
  if (!safetyCheck.safe) {
    return {
      canUnsubscribe: false,
      reason: safetyCheck.reason,
      mechanism: null,
      blocked: 'safelist'
    };
  }

  // Check #2: Unsubscribe mechanism exists
  const mechanism = parseUnsubscribeMechanism(email);
  if (!mechanism.preferredMethod) {
    return {
      canUnsubscribe: false,
      reason: 'No unsubscribe mechanism found in email (no List-Unsubscribe header or unsubscribe links)',
      mechanism,
      blocked: 'no_mechanism'
    };
  }

  // Passed all checks
  return {
    canUnsubscribe: true,
    reason: 'Email can be safely unsubscribed',
    mechanism
  };
}

/**
 * Execute unsubscribe action (MOCK for testing)
 * In production, this would send HTTP request or compose email
 * @param {object} mechanism - Unsubscribe mechanism from parseUnsubscribeMechanism()
 * @param {object} options - { dryRun: boolean, mock: boolean }
 * @returns {Promise<object>} - { success: boolean, method: string, details: string }
 */
async function executeUnsubscribe(mechanism, options = {}) {
  const { dryRun = false, mock = true } = options;

  if (!mechanism || !mechanism.preferredMethod) {
    return {
      success: false,
      method: null,
      details: 'No unsubscribe mechanism provided'
    };
  }

  const { preferredMethod } = mechanism;

  // Dry run - don't actually unsubscribe
  if (dryRun) {
    return {
      success: true,
      method: preferredMethod.type,
      details: `[DRY RUN] Would unsubscribe using ${preferredMethod.type}: ${JSON.stringify(preferredMethod)}`,
      dryRun: true
    };
  }

  // Mock mode - simulate unsubscribe without real HTTP/email
  if (mock) {
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 100));

    return {
      success: true,
      method: preferredMethod.type,
      details: `[MOCK] Simulated unsubscribe via ${preferredMethod.type}`,
      mock: true,
      timestamp: new Date().toISOString()
    };
  }

  // Production mode - actual HTTP/email (not implemented for safety)
  throw new Error('Production unsubscribe not implemented - use mock mode for testing');
}

/**
 * Audit log for unsubscribe attempts
 * In production, this would write to database or logging service
 * @param {object} email - Email that was (attempted to be) unsubscribed
 * @param {object} result - Result from canUnsubscribe() or executeUnsubscribe()
 * @param {object} options - Additional context
 */
function auditLog(email, result, options = {}) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    emailFrom: email?.from || 'unknown',
    emailSubject: email?.subject || 'unknown',
    classification: email?.classification || {},
    action: options.action || 'check',
    result: result.success || result.canUnsubscribe || false,
    reason: result.reason || result.details || 'unknown',
    blocked: result.blocked || null,
    method: result.method || null,
    userId: options.userId || 'test',
    ...options
  };

  // In production, write to database/logging service
  // For now, just return the log entry for testing
  return logEntry;
}

/**
 * Main workflow: Check and execute unsubscribe (if safe)
 * @param {object} email - Email object
 * @param {object} options - { dryRun: boolean, mock: boolean, userId: string }
 * @returns {Promise<object>} - Complete result with audit log
 */
async function unsubscribeWorkflow(email, options = {}) {
  // Step 1: Check if email can be unsubscribed
  const checkResult = canUnsubscribe(email);

  // Audit the check
  const checkLog = auditLog(email, checkResult, { ...options, action: 'check' });

  if (!checkResult.canUnsubscribe) {
    return {
      success: false,
      step: 'check',
      ...checkResult,
      auditLog: checkLog
    };
  }

  // Step 2: Execute unsubscribe
  const executeResult = await executeUnsubscribe(checkResult.mechanism, options);

  // Audit the execution
  const executeLog = auditLog(email, executeResult, { ...options, action: 'execute' });

  return {
    success: executeResult.success,
    step: 'execute',
    mechanism: checkResult.mechanism,
    execution: executeResult,
    auditLog: [checkLog, executeLog]
  };
}

module.exports = {
  parseListUnsubscribeHeader,
  checkOneClickSupport,
  extractUnsubscribeURLs,
  parseUnsubscribeMechanism,
  canUnsubscribe,
  executeUnsubscribe,
  auditLog,
  unsubscribeWorkflow
};
