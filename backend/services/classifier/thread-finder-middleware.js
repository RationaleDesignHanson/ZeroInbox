/**
 * Thread Finder Middleware
 * Enriches link-only email classifications with automatically extracted data
 *
 * Integration point between classifier and Thread Finder extraction system.
 * Only processes emails classified as link-only intents (LMS, school portals, sports).
 */

const { processEmailWithLink } = require('../thread-finder/steel-integration');
const logger = require('./shared/config/logger');

// Link-only intents that should trigger Thread Finder
const THREAD_FINDER_INTENTS = [
  'education.lms.link-only',
  'education.school-portal.link-only',
  'youth.sports.link-only',
];

/**
 * Extract primary link from email body or snippet
 * @param {Object} email - Email object with body/snippet
 * @returns {string|null} Extracted link or null
 */
function extractPrimaryLink(email) {
  const text = email.body || email.snippet || '';

  // Match http:// or https:// URLs
  const urlRegex = /(https?:\/\/[^\s<>"]+)/gi;
  const matches = text.match(urlRegex);

  if (!matches || matches.length === 0) {
    return null;
  }

  // Return first link (most prominent)
  return matches[0];
}

/**
 * Check if email body is "link-heavy" (short body with prominent link)
 * @param {Object} email - Email object
 * @returns {boolean} True if email is link-heavy
 */
function isLinkHeavyEmail(email) {
  const body = email.body || email.snippet || '';
  const link = extractPrimaryLink(email);

  // Email is link-heavy if:
  // 1. Body is short (<300 chars)
  // 2. Contains at least one link
  // 3. Not much other content besides the link

  if (!link) {
    return false;
  }

  const bodyLength = body.length;
  const linkLength = link.length;

  // If body is short and has a link, it's likely link-heavy
  if (bodyLength < 300 && link) {
    return true;
  }

  // If link takes up significant portion of body (>30%), it's link-heavy
  if (linkLength / bodyLength > 0.3) {
    return true;
  }

  return false;
}

/**
 * Enrich classification with Thread Finder extraction
 * @param {Object} classification - Initial classification result
 * @param {Object} email - Original email object
 * @returns {Promise<Object>} Enhanced classification with extracted content
 */
async function enrichWithThreadFinder(classification, email) {
  // Only process link-only intents
  if (!THREAD_FINDER_INTENTS.includes(classification.intent)) {
    return classification;
  }

  // Check if email is actually link-heavy
  if (!isLinkHeavyEmail(email)) {
    logger.warn('Intent is link-only but email is not link-heavy, skipping Thread Finder', {
      intent: classification.intent,
      bodyLength: (email.body || '').length,
    });
    return classification;
  }

  // Extract link
  const link = extractPrimaryLink(email);
  if (!link) {
    logger.warn('No link found in link-only email', {
      intent: classification.intent,
    });
    return {
      ...classification,
      requiresManualReview: true,
      manualReviewReason: 'No link found for extraction',
    };
  }

  const startTime = Date.now();

  try {
    logger.info('Thread Finder extraction starting', {
      intent: classification.intent,
      link: link.substring(0, 100), // Log first 100 chars
    });

    // Call Thread Finder extraction
    const extracted = await processEmailWithLink(email, link);

    const processingTime = Date.now() - startTime;

    if (!extracted.requiresManualReview) {
      // Successfully extracted - enhance classification
      logger.info('Thread Finder extraction successful', {
        intent: classification.intent,
        platform: extracted.extractedContent?.metadata?.platform,
        hasContent: !!extracted.extractedContent?.content,
        priority: extracted.priority,
        processingTimeMs: processingTime,
      });

      return {
        ...classification,
        threadFinderProcessed: true,
        extractedContent: extracted.extractedContent,
        summary: extracted.summary,
        priority: extracted.priority,
        hpa: extracted.hpa,
        entities: {
          ...classification.entities,
          link,
          extractedContent: extracted.extractedContent,
          // Merge extracted metadata into entities
          ...extracted.extractedContent.metadata,
        },
      };
    } else {
      // Extraction failed - flag for manual review
      logger.warn('Thread Finder extraction failed, manual review required', {
        intent: classification.intent,
        reason: extracted.summary,
        processingTimeMs: processingTime,
      });

      return {
        ...classification,
        threadFinderProcessed: false,
        requiresManualReview: true,
        manualReviewReason: extracted.summary,
        entities: {
          ...classification.entities,
          link,
        },
      };
    }
  } catch (error) {
    const processingTime = Date.now() - startTime;

    logger.error('Thread Finder enrichment error', {
      error: error.message,
      intent: classification.intent,
      processingTimeMs: processingTime,
      stack: error.stack,
    });

    // On error, return original classification with manual review flag
    return {
      ...classification,
      threadFinderProcessed: false,
      requiresManualReview: true,
      manualReviewReason: `Thread Finder error: ${error.message}`,
      entities: {
        ...classification.entities,
        link,
      },
    };
  }
}

/**
 * Check if Thread Finder is enabled
 * @returns {boolean} True if Thread Finder should be used
 */
function isThreadFinderEnabled() {
  return process.env.USE_THREAD_FINDER !== 'false'; // Default to enabled
}

module.exports = {
  enrichWithThreadFinder,
  extractPrimaryLink,
  isLinkHeavyEmail,
  isThreadFinderEnabled,
  THREAD_FINDER_INTENTS,
};
