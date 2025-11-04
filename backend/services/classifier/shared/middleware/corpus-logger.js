/**
 * Corpus Logger Middleware
 * Automatically logs classified emails and user actions to corpus analytics database
 * Used across classifier, email, and action services
 */

const axios = require('axios');
const logger = require('../config/logger');

const CORPUS_SERVICE_URL = process.env.CORPUS_SERVICE_URL || 'http://localhost:8090';
const ENABLE_CORPUS_LOGGING = process.env.ENABLE_CORPUS_LOGGING !== 'false'; // Default: enabled

/**
 * Log a classified email to corpus
 * @param {Object} email - Original email data
 * @param {Object} classification - Classification results from classifier service
 * @param {string} userId - User identifier
 * @returns {Promise<void>}
 */
async function logEmailToCorpus(email, classification, userId) {
  if (!ENABLE_CORPUS_LOGGING) {
    logger.debug('Corpus logging disabled, skipping email log');
    return;
  }

  try {
    const corpusData = {
      emailId: email.id || email.messageId,
      userId,
      subject: email.subject,
      fromEmail: email.from,
      fromName: extractNameFromEmail(email.from),
      receivedAt: email.date || email.receivedAt || new Date().toISOString(),
      intent: classification.intent || 'unknown',
      intentConfidence: classification.intentConfidence || classification.confidence || 0,
      category: classification.type || 'mail',
      priority: classification.priority || 'medium',
      entities: classification.entities || {},
      suggestedActions: classification.suggestedActions || [],
      primaryAction: classification.suggestedActions?.[0]?.actionId || null,
      bodySnippet: (email.body || email.snippet || '').substring(0, 1000)
    };

    const response = await axios.post(
      `${CORPUS_SERVICE_URL}/api/corpus/log-email`,
      corpusData,
      {
        timeout: 5000,
        headers: { 'Content-Type': 'application/json' }
      }
    );

    logger.info('Email logged to corpus', {
      corpusId: response.data.corpusId,
      emailId: corpusData.emailId,
      intent: corpusData.intent
    });

    return response.data;

  } catch (error) {
    // Don't fail the main request if corpus logging fails
    logger.warn('Failed to log email to corpus (non-fatal)', {
      error: error.message,
      emailId: email.id
    });
  }
}

/**
 * Log a user action to corpus
 * @param {Object} actionData - Action data
 * @returns {Promise<void>}
 */
async function logActionToCorpus(actionData) {
  if (!ENABLE_CORPUS_LOGGING) {
    logger.debug('Corpus logging disabled, skipping action log');
    return;
  }

  try {
    const {
      userId,
      emailId,
      actionId,
      actionType,
      wasSuggested,
      suggestionRank,
      context,
      success,
      durationMs,
      platform,
      appVersion
    } = actionData;

    const corpusData = {
      userId,
      emailId,
      actionId,
      actionType: actionType || 'IN_APP',
      wasSuggested: wasSuggested !== undefined ? wasSuggested : false,
      suggestionRank: suggestionRank || null,
      context: context || {},
      success: success !== undefined ? success : true,
      durationMs: durationMs || null,
      platform: platform || 'unknown',
      appVersion: appVersion || 'unknown'
    };

    const response = await axios.post(
      `${CORPUS_SERVICE_URL}/api/corpus/log-action`,
      corpusData,
      {
        timeout: 5000,
        headers: { 'Content-Type': 'application/json' }
      }
    );

    logger.info('Action logged to corpus', {
      logId: response.data.logId,
      actionId: corpusData.actionId,
      wasSuggested: corpusData.wasSuggested
    });

    return response.data;

  } catch (error) {
    // Don't fail the main request if corpus logging fails
    logger.warn('Failed to log action to corpus (non-fatal)', {
      error: error.message,
      actionId: actionData.actionId
    });
  }
}

/**
 * Express middleware to automatically log email classifications
 * Use after classification endpoint
 */
function corpusEmailLoggingMiddleware(req, res, next) {
  // Store original json method
  const originalJson = res.json.bind(res);

  // Override res.json to intercept response
  res.json = function(data) {
    // Log to corpus asynchronously (don't block response)
    if (data && data.intent && req.body && req.body.email) {
      const userId = req.user?.id || req.headers['x-user-id'] || 'anonymous';

      logEmailToCorpus(req.body.email, data, userId).catch(err => {
        logger.error('Corpus email logging failed', { error: err.message });
      });
    }

    // Call original json method
    return originalJson(data);
  };

  next();
}

/**
 * Express middleware to automatically log user actions
 * Use on action execution endpoints
 */
function corpusActionLoggingMiddleware(req, res, next) {
  // Store original json method
  const originalJson = res.json.bind(res);

  // Override res.json to intercept response
  res.json = function(data) {
    // Log to corpus asynchronously (don't block response)
    if (data && data.success && req.body) {
      const actionData = {
        userId: req.user?.id || req.headers['x-user-id'] || 'anonymous',
        emailId: req.body.emailId || req.params.emailId,
        actionId: req.body.actionId || req.params.actionId,
        actionType: req.body.actionType || 'IN_APP',
        wasSuggested: req.body.wasSuggested,
        suggestionRank: req.body.suggestionRank,
        context: req.body.context || {},
        success: data.success,
        durationMs: data.durationMs,
        platform: req.headers['x-platform'] || 'unknown',
        appVersion: req.headers['x-app-version'] || 'unknown'
      };

      logActionToCorpus(actionData).catch(err => {
        logger.error('Corpus action logging failed', { error: err.message });
      });
    }

    // Call original json method
    return originalJson(data);
  };

  next();
}

/**
 * Batch log multiple emails to corpus
 * @param {Array<Object>} emails - Array of {email, classification, userId}
 * @returns {Promise<void>}
 */
async function batchLogEmailsToCorpus(emails) {
  if (!ENABLE_CORPUS_LOGGING) {
    logger.debug('Corpus logging disabled, skipping batch email log');
    return;
  }

  // Log in parallel batches of 10
  const BATCH_SIZE = 10;
  for (let i = 0; i < emails.length; i += BATCH_SIZE) {
    const batch = emails.slice(i, i + BATCH_SIZE);
    await Promise.all(
      batch.map(({ email, classification, userId }) =>
        logEmailToCorpus(email, classification, userId)
      )
    );
  }

  logger.info('Batch logged emails to corpus', { count: emails.length });
}

/**
 * Helper: Extract name from email address
 * @param {string} email - Email string like "John Doe <john@example.com>"
 * @returns {string|null} - Extracted name or null
 */
function extractNameFromEmail(email) {
  if (!email) return null;

  const match = email.match(/^([^<]+)</);
  if (match) {
    return match[1].trim().replace(/^["']|["']$/g, '');
  }

  return null;
}

/**
 * Get corpus statistics for a user
 * @param {string} userId - User identifier
 * @param {number} days - Number of days to look back (default: 30)
 * @returns {Promise<Object>} - Corpus statistics
 */
async function getCorpusStatistics(userId, days = 30) {
  try {
    const response = await axios.get(
      `${CORPUS_SERVICE_URL}/api/corpus/statistics`,
      {
        params: { userId, days },
        timeout: 10000
      }
    );

    return response.data;

  } catch (error) {
    logger.error('Failed to fetch corpus statistics', {
      error: error.message,
      userId
    });
    throw error;
  }
}

/**
 * Get top keywords for a category
 * @param {string} category - Keyword category (e.g., "events", "urgency")
 * @param {number} limit - Max keywords to return (default: 20)
 * @returns {Promise<Array>} - Array of keyword objects
 */
async function getTopKeywords(category, limit = 20) {
  try {
    const response = await axios.get(
      `${CORPUS_SERVICE_URL}/api/corpus/keywords`,
      {
        params: { category, limit },
        timeout: 10000
      }
    );

    return response.data.keywords;

  } catch (error) {
    logger.error('Failed to fetch top keywords', {
      error: error.message,
      category
    });
    throw error;
  }
}

module.exports = {
  // Core functions
  logEmailToCorpus,
  logActionToCorpus,
  batchLogEmailsToCorpus,

  // Express middleware
  corpusEmailLoggingMiddleware,
  corpusActionLoggingMiddleware,

  // Helper functions
  getCorpusStatistics,
  getTopKeywords,
  extractNameFromEmail,

  // Configuration
  CORPUS_SERVICE_URL,
  ENABLE_CORPUS_LOGGING
};
