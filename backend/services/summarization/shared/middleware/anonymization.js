/**
 * Anonymization Middleware
 *
 * Automatically anonymizes responses containing email data during beta testing.
 * Controlled by BETA_MODE environment variable.
 */

const anonymizer = require('../services/data-anonymizer');
const logger = require('../config/logger');

/**
 * Check if beta mode is enabled
 */
const isBetaMode = () => {
  return process.env.BETA_MODE === 'true' || process.env.NODE_ENV === 'beta';
};

/**
 * Middleware to anonymize email responses
 * Wraps res.json() to automatically anonymize data before sending
 */
const anonymizeResponse = (req, res, next) => {
  // Only apply in beta mode
  if (!isBetaMode()) {
    return next();
  }

  // Store original json method
  const originalJson = res.json.bind(res);

  // Override json method
  res.json = function(data) {
    try {
      let anonymized Data = data;

      // Anonymize based on data structure
      if (data) {
        // Single email object
        if (data.id && (data.from || data.subject)) {
          anonymizedData = anonymizer.anonymizeEmailObject(data);
        }
        // Array of emails
        else if (Array.isArray(data)) {
          anonymizedData = anonymizer.anonymizeEmailList(data);
        }
        // Response with emails array
        else if (data.emails && Array.isArray(data.emails)) {
          anonymizedData = {
            ...data,
            emails: anonymizer.anonymizeEmailList(data.emails)
          };
        }
        // Response with single email
        else if (data.email && data.email.from) {
          anonymizedData = {
            ...data,
            email: anonymizer.anonymizeEmailObject(data.email)
          };
        }
      }

      // Add beta mode header
      res.setHeader('X-Beta-Mode', 'anonymized');

      return originalJson(anonymizedData);
    } catch (error) {
      logger.error('Anonymization middleware error', { error: error.message });
      // Fall back to original json if anonymization fails
      return originalJson(data);
    }
  };

  next();
};

/**
 * Middleware to anonymize request bodies (for POST/PUT requests)
 */
const anonymizeRequestBody = (req, res, next) => {
  if (!isBetaMode()) {
    return next();
  }

  try {
    if (req.body && typeof req.body === 'object') {
      // Scrub PII from any text fields
      Object.keys(req.body).forEach(key => {
        if (typeof req.body[key] === 'string') {
          req.body[key] = anonymizer.scrubPII(req.body[key]);
        }
      });
    }
  } catch (error) {
    logger.error('Request body anonymization error', { error: error.message });
  }

  next();
};

/**
 * Express middleware to log beta mode status
 */
const logBetaMode = (req, res, next) => {
  if (isBetaMode()) {
    logger.info('Beta mode active - data will be anonymized', {
      path: req.path,
      method: req.method
    });
  }
  next();
};

module.exports = {
  anonymizeResponse,
  anonymizeRequestBody,
  logBetaMode,
  isBetaMode
};
