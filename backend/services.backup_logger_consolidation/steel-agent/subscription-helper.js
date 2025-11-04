/**
 * Subscription Helper Service
 * Provides subscription cancellation information and AI agent integration
 */

const cancellationData = require('./cancellation-urls.json');
const logger = require('./logger');

/**
 * Find subscription service by name or alias
 * @param {string} serviceName - Service name to search for
 * @returns {Object|null} Service cancellation information
 */
function findService(serviceName) {
  if (!serviceName || typeof serviceName !== 'string') {
    return null;
  }

  const searchTerm = serviceName.toLowerCase().trim();

  // Find service by exact name or alias match
  const service = cancellationData.services.find(s => {
    if (s.name.toLowerCase() === searchTerm) return true;
    return s.aliases.some(alias => alias.toLowerCase() === searchTerm);
  });

  if (service) {
    logger.info('Found cancellation info for service', {
      searchTerm,
      serviceName: service.name
    });
    return service;
  }

  // Fuzzy match - check if service name contains search term or vice versa
  const fuzzyMatch = cancellationData.services.find(s => {
    const nameMatch = s.name.toLowerCase().includes(searchTerm) ||
                     searchTerm.includes(s.name.toLowerCase());
    if (nameMatch) return true;

    return s.aliases.some(alias =>
      alias.toLowerCase().includes(searchTerm) ||
      searchTerm.includes(alias.toLowerCase())
    );
  });

  if (fuzzyMatch) {
    logger.info('Found fuzzy match for service', {
      searchTerm,
      serviceName: fuzzyMatch.name
    });
    return fuzzyMatch;
  }

  logger.warn('No cancellation info found for service', { searchTerm });
  return null;
}

/**
 * Extract service name from email sender or subject
 * @param {Object} email - Email object with from, subject
 * @returns {string|null} Detected service name
 */
function detectServiceFromEmail(email) {
  if (!email) return null;

  const from = (email.from || '').toLowerCase();
  const subject = (email.subject || '').toLowerCase();
  const text = `${from} ${subject}`;

  // Try each service's aliases
  for (const service of cancellationData.services) {
    for (const alias of service.aliases) {
      if (text.includes(alias.toLowerCase())) {
        logger.info('Detected service from email', {
          service: service.name,
          alias,
          from: email.from,
          subject: email.subject
        });
        return service.name;
      }
    }
  }

  logger.info('Could not detect service from email', {
    from: email.from,
    subject: email.subject
  });
  return null;
}

/**
 * Get all available subscription services
 * @returns {Array<Object>} List of all services with cancellation info
 */
function getAllServices() {
  return cancellationData.services.map(s => ({
    name: s.name,
    hasDirectLink: !!s.cancellationUrl,
    requiresInPerson: s.note?.includes('in-person') || false
  }));
}

/**
 * Check if service supports AI-assisted cancellation
 * AI assistance is recommended for services that require login and multiple steps
 * @param {Object} service - Service object from cancellation data
 * @returns {boolean} True if AI assistance would be helpful
 */
function supportsAIAssistance(service) {
  if (!service) return false;

  // AI assistance is most helpful for:
  // 1. Services requiring login
  // 2. Services with multiple cancellation steps
  // 3. Services without direct cancellation URL
  return service.requiresLogin &&
         service.cancellationSteps &&
         service.cancellationSteps.length > 1;
}

module.exports = {
  findService,
  detectServiceFromEmail,
  getAllServices,
  supportsAIAssistance
};
