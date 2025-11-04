/**
 * Enhanced Entity Extractor
 * Phase 3.1: Advanced entity extraction with confidence scoring, validation, and relationships
 *
 * Enhancements over base entity-extractor.js:
 * - Confidence scores per entity (0.0 to 1.0)
 * - Entity validation and correction
 * - Entity relationship detection
 * - Type-aware extraction (dates, money, URLs, etc.)
 * - Fallback strategies for failed extractions
 *
 * @author Claude Code
 * @version 3.1.0
 */

const logger = require('./shared/config/logger');
const { extractAllEntities } = require('./entity-extractor');

/**
 * Confidence levels for entity extraction
 */
const CONFIDENCE = {
  HIGH: 0.9,      // Exact pattern match with validation
  MEDIUM: 0.7,    // Pattern match without validation
  LOW: 0.5,       // Heuristic/fallback extraction
  VERY_LOW: 0.3   // Guessed from context
};

/**
 * Entity types for validation
 */
const ENTITY_TYPES = {
  DATE: 'date',
  MONEY: 'money',
  URL: 'url',
  EMAIL: 'email',
  PHONE: 'phone',
  ID: 'id',
  NUMBER: 'number',
  TEXT: 'text'
};

/**
 * Enhanced entity extraction with confidence scoring
 * @param {Object} email - Email object
 * @param {string} intentId - Intent ID for context
 * @returns {Object} Enhanced entities with confidence scores
 */
function extractEntitiesEnhanced(email, intentId = null) {
  const startTime = Date.now();

  // Get base entities from existing extractor
  const fullText = `${email.subject || ''} ${email.body || ''}`;
  const baseEntities = extractAllEntities(email, fullText, intentId);

  // Enhance each entity with confidence score and metadata
  const enhancedEntities = {};
  const entityMetadata = {};

  for (const [key, value] of Object.entries(baseEntities)) {
    if (!value || (Array.isArray(value) && value.length === 0)) {
      continue; // Skip empty values
    }

    // Extract with confidence
    const enhanced = enhanceEntity(key, value, fullText, intentId);

    if (enhanced) {
      enhancedEntities[key] = enhanced.value;
      entityMetadata[key] = {
        confidence: enhanced.confidence,
        type: enhanced.type,
        source: enhanced.source,
        validated: enhanced.validated,
        corrected: enhanced.corrected
      };
    }
  }

  // Detect entity relationships
  const relationships = detectEntityRelationships(enhancedEntities, entityMetadata);

  // Apply relationship-based confidence boosts
  applyRelationshipBoosts(enhancedEntities, entityMetadata, relationships);

  const processingTime = Date.now() - startTime;

  logger.info('Enhanced entity extraction complete', {
    entityCount: Object.keys(enhancedEntities).length,
    avgConfidence: calculateAverageConfidence(entityMetadata),
    relationshipCount: relationships.length,
    processingTime
  });

  return {
    entities: enhancedEntities,
    metadata: entityMetadata,
    relationships,
    stats: {
      totalEntities: Object.keys(enhancedEntities).length,
      avgConfidence: calculateAverageConfidence(entityMetadata),
      highConfidenceCount: countByConfidence(entityMetadata, 0.8),
      processingTime
    }
  };
}

/**
 * Enhance individual entity with confidence and metadata
 * @param {string} key - Entity key name
 * @param {any} value - Entity value
 * @param {string} fullText - Full email text
 * @param {string} intentId - Intent ID
 * @returns {Object} Enhanced entity
 */
function enhanceEntity(key, value, fullText, intentId) {
  // Determine entity type
  const type = detectEntityType(key, value);

  // Calculate confidence score
  let confidence = CONFIDENCE.MEDIUM; // Default
  let validated = false;
  let corrected = false;
  let source = 'pattern_match';

  // Type-specific validation and confidence adjustment
  switch (type) {
    case ENTITY_TYPES.DATE:
      const dateValidation = validateDate(value);
      validated = dateValidation.valid;
      confidence = dateValidation.valid ? CONFIDENCE.HIGH : CONFIDENCE.LOW;
      if (dateValidation.corrected) {
        value = dateValidation.corrected;
        corrected = true;
      }
      break;

    case ENTITY_TYPES.MONEY:
      const moneyValidation = validateMoney(value);
      validated = moneyValidation.valid;
      confidence = moneyValidation.valid ? CONFIDENCE.HIGH : CONFIDENCE.MEDIUM;
      if (moneyValidation.normalized) {
        value = moneyValidation.normalized;
        corrected = true;
      }
      break;

    case ENTITY_TYPES.URL:
      const urlValidation = validateURL(value);
      validated = urlValidation.valid;
      confidence = urlValidation.valid ? CONFIDENCE.HIGH : CONFIDENCE.LOW;
      break;

    case ENTITY_TYPES.EMAIL:
      const emailValidation = validateEmail(value);
      validated = emailValidation.valid;
      confidence = emailValidation.valid ? CONFIDENCE.HIGH : CONFIDENCE.LOW;
      break;

    case ENTITY_TYPES.ID:
      // IDs are high confidence if they match expected formats
      confidence = validateID(key, value) ? CONFIDENCE.HIGH : CONFIDENCE.MEDIUM;
      validated = true;
      break;

    case ENTITY_TYPES.NUMBER:
      const numberValidation = validateNumber(value);
      validated = numberValidation.valid;
      confidence = numberValidation.valid ? CONFIDENCE.HIGH : CONFIDENCE.MEDIUM;
      break;

    case ENTITY_TYPES.TEXT:
      // Text entities have lower confidence unless specifically validated
      confidence = value.length > 3 ? CONFIDENCE.MEDIUM : CONFIDENCE.LOW;
      validated = false;
      break;
  }

  // Context-based confidence boost
  if (intentId) {
    const contextBoost = getContextConfidenceBoost(key, intentId);
    confidence = Math.min(1.0, confidence + contextBoost);
  }

  return {
    value,
    confidence,
    type,
    source,
    validated,
    corrected
  };
}

/**
 * Detect entity type from key and value
 * @param {string} key - Entity key
 * @param {any} value - Entity value
 * @returns {string} Entity type
 */
function detectEntityType(key, value) {
  const keyLower = key.toLowerCase();

  // URL detection
  if (keyLower.includes('url') || keyLower.includes('link')) {
    return ENTITY_TYPES.URL;
  }

  // Date detection
  if (keyLower.includes('date') || keyLower.includes('time') ||
      keyLower.includes('deadline') || keyLower.includes('eta') ||
      keyLower.includes('departure') || keyLower.includes('arrival')) {
    return ENTITY_TYPES.DATE;
  }

  // Money detection
  if (keyLower.includes('amount') || keyLower.includes('price') ||
      keyLower.includes('cost') || keyLower.includes('fee') ||
      keyLower.includes('payment') || keyLower.includes('total')) {
    return ENTITY_TYPES.MONEY;
  }

  // Email detection
  if (keyLower.includes('email') || (typeof value === 'string' && value.includes('@'))) {
    return ENTITY_TYPES.EMAIL;
  }

  // Phone detection
  if (keyLower.includes('phone')) {
    return ENTITY_TYPES.PHONE;
  }

  // ID detection
  if (keyLower.includes('id') || keyLower.includes('number') ||
      keyLower.includes('code') || keyLower.includes('confirmation')) {
    return ENTITY_TYPES.ID;
  }

  // Number detection
  if (typeof value === 'number' || (typeof value === 'string' && /^\d+$/.test(value))) {
    return ENTITY_TYPES.NUMBER;
  }

  return ENTITY_TYPES.TEXT;
}

/**
 * Validate date entity
 * @param {string} value - Date value
 * @returns {Object} Validation result
 */
function validateDate(value) {
  if (!value) return { valid: false };

  // Try parsing various date formats
  const dateFormats = [
    // "January 15, 2025"
    /^(january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2},?\s+\d{4}$/i,
    // "Jan 15, 2025"
    /^(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2},?\s+\d{4}$/i,
    // "12/15/2025"
    /^\d{1,2}\/\d{1,2}\/\d{2,4}$/,
    // "2025-01-15"
    /^\d{4}-\d{2}-\d{2}$/,
    // ISO 8601
    /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z?$/,
    // Relative dates
    /^(today|tomorrow|yesterday)$/i
  ];

  const valid = dateFormats.some(format => format.test(value));

  // Try to parse and validate
  if (valid && !value.match(/^(today|tomorrow|yesterday)$/i)) {
    const parsed = new Date(value);
    if (isNaN(parsed.getTime())) {
      return { valid: false };
    }

    // Check if date is reasonable (not too far in past or future)
    const now = new Date();
    const tenYearsAgo = new Date(now.getFullYear() - 10, 0, 1);
    const tenYearsFromNow = new Date(now.getFullYear() + 10, 11, 31);

    if (parsed < tenYearsAgo || parsed > tenYearsFromNow) {
      return { valid: false };
    }
  }

  return { valid };
}

/**
 * Validate money entity
 * @param {string} value - Money value
 * @returns {Object} Validation result
 */
function validateMoney(value) {
  if (!value) return { valid: false };

  const valueStr = String(value);

  // Money patterns
  const moneyPattern = /^\$?[\d,]+\.?\d{0,2}$/;
  const valid = moneyPattern.test(valueStr);

  if (valid) {
    // Normalize format
    const normalized = valueStr.replace(/[$,]/g, '');
    const amount = parseFloat(normalized);

    // Validate reasonable range ($0.01 to $1,000,000)
    if (amount >= 0.01 && amount <= 1000000) {
      return { valid: true, normalized };
    }
  }

  return { valid: false };
}

/**
 * Validate URL entity
 * @param {string} value - URL value
 * @returns {Object} Validation result
 */
function validateURL(value) {
  if (!value) return { valid: false };

  try {
    const url = new URL(value);
    const valid = url.protocol === 'http:' || url.protocol === 'https:';
    return { valid };
  } catch (e) {
    return { valid: false };
  }
}

/**
 * Validate email entity
 * @param {string} value - Email value
 * @returns {Object} Validation result
 */
function validateEmail(value) {
  if (!value) return { valid: false };

  const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  const valid = emailPattern.test(value);

  return { valid };
}

/**
 * Validate ID entity (tracking numbers, order IDs, etc.)
 * @param {string} key - Entity key
 * @param {string} value - ID value
 * @returns {boolean} Is valid
 */
function validateID(key, value) {
  if (!value) return false;

  const valueStr = String(value);

  // Tracking numbers
  if (key === 'trackingNumber') {
    // UPS: 1Z + 16 chars
    if (/^1Z[A-Z0-9]{16}$/i.test(valueStr)) return true;
    // FedEx: 12-14 digits
    if (/^\d{12,14}$/.test(valueStr)) return true;
    // USPS: 20-22 digits
    if (/^\d{20,22}$/.test(valueStr)) return true;
    // Generic tracking: 5+ alphanumeric
    if (/^[A-Z0-9]{5,}$/i.test(valueStr)) return true;
  }

  // Order numbers, invoice IDs: typically 6+ alphanumeric with possible hyphens
  if (key.includes('order') || key.includes('invoice') || key.includes('confirmation')) {
    return /^[A-Z0-9-]{6,}$/i.test(valueStr);
  }

  // Generic ID: at least 4 characters
  return valueStr.length >= 4;
}

/**
 * Validate number entity
 * @param {any} value - Number value
 * @returns {Object} Validation result
 */
function validateNumber(value) {
  const num = typeof value === 'number' ? value : parseFloat(value);
  const valid = !isNaN(num) && isFinite(num);

  return { valid };
}

/**
 * Get confidence boost based on intent context
 * @param {string} entityKey - Entity key
 * @param {string} intentId - Intent ID
 * @returns {number} Confidence boost (0.0 to 0.2)
 */
function getContextConfidenceBoost(entityKey, intentId) {
  // Entity-intent relationships that boost confidence
  const contextRules = {
    'trackingNumber': ['e-commerce.shipping', 'e-commerce.delivery'],
    'orderNumber': ['e-commerce'],
    'invoiceId': ['billing.invoice'],
    'flightNumber': ['travel.flight'],
    'confirmationCode': ['travel', 'dining'],
    'provider': ['healthcare.appointment'],
    'medication': ['healthcare.prescription'],
    'restaurant': ['dining'],
    'amount': ['billing', 'e-commerce.order', 'education.permission']
  };

  for (const [entity, intents] of Object.entries(contextRules)) {
    if (entityKey === entity || entityKey.includes(entity)) {
      for (const intentPrefix of intents) {
        if (intentId.startsWith(intentPrefix)) {
          return 0.1; // +10% confidence boost
        }
      }
    }
  }

  return 0;
}

/**
 * Detect relationships between entities
 * @param {Object} entities - Extracted entities
 * @param {Object} metadata - Entity metadata
 * @returns {Array} Relationships
 */
function detectEntityRelationships(entities, metadata) {
  const relationships = [];

  // Tracking number → Carrier relationship
  if (entities.trackingNumber && !entities.carrier) {
    const carrier = inferCarrierFromTracking(entities.trackingNumber);
    if (carrier) {
      relationships.push({
        type: 'inferred',
        from: 'trackingNumber',
        to: 'carrier',
        value: carrier,
        confidence: CONFIDENCE.HIGH
      });
    }
  }

  // Order number → Order URL relationship (if both exist, they're related)
  if (entities.orderNumber && entities.orderUrl) {
    relationships.push({
      type: 'related',
      entities: ['orderNumber', 'orderUrl'],
      confidence: CONFIDENCE.HIGH
    });
  }

  // Invoice ID → Payment link relationship
  if (entities.invoiceId && entities.paymentLink) {
    relationships.push({
      type: 'related',
      entities: ['invoiceId', 'paymentLink'],
      confidence: CONFIDENCE.HIGH
    });
  }

  // Provider → Healthcare URL relationship
  if (entities.provider && (entities.schedulingUrl || entities.resultsUrl)) {
    relationships.push({
      type: 'related',
      entities: ['provider', entities.schedulingUrl ? 'schedulingUrl' : 'resultsUrl'],
      confidence: CONFIDENCE.MEDIUM
    });
  }

  // Restaurant → Confirmation code relationship
  if (entities.restaurant && entities.confirmationCode) {
    relationships.push({
      type: 'related',
      entities: ['restaurant', 'confirmationCode'],
      confidence: CONFIDENCE.HIGH
    });
  }

  return relationships;
}

/**
 * Infer carrier from tracking number format
 * @param {string} trackingNumber - Tracking number
 * @returns {string|null} Carrier name
 */
function inferCarrierFromTracking(trackingNumber) {
  if (!trackingNumber) return null;

  const tracking = String(trackingNumber).toUpperCase();

  // UPS: Starts with 1Z
  if (/^1Z/.test(tracking)) return 'UPS';

  // FedEx: 12-14 digits
  if (/^\d{12,14}$/.test(tracking)) return 'FedEx';

  // USPS: 20-22 digits
  if (/^\d{20,22}$/.test(tracking)) return 'USPS';

  return null;
}

/**
 * Apply relationship-based confidence boosts
 * @param {Object} entities - Entities object
 * @param {Object} metadata - Metadata object
 * @param {Array} relationships - Relationships array
 */
function applyRelationshipBoosts(entities, metadata, relationships) {
  for (const rel of relationships) {
    if (rel.type === 'inferred') {
      // Add inferred entity with slightly lower confidence
      entities[rel.to] = rel.value;
      metadata[rel.to] = {
        confidence: rel.confidence - 0.1,
        type: ENTITY_TYPES.TEXT,
        source: 'inferred_from_relationship',
        validated: true,
        corrected: false
      };
    } else if (rel.type === 'related') {
      // Boost confidence of related entities
      for (const entityKey of rel.entities) {
        if (metadata[entityKey]) {
          metadata[entityKey].confidence = Math.min(1.0, metadata[entityKey].confidence + 0.05);
        }
      }
    }
  }
}

/**
 * Calculate average confidence across all entities
 * @param {Object} metadata - Entity metadata
 * @returns {number} Average confidence
 */
function calculateAverageConfidence(metadata) {
  const confidences = Object.values(metadata).map(m => m.confidence);
  if (confidences.length === 0) return 0;

  const sum = confidences.reduce((a, b) => a + b, 0);
  return sum / confidences.length;
}

/**
 * Count entities above confidence threshold
 * @param {Object} metadata - Entity metadata
 * @param {number} threshold - Confidence threshold
 * @returns {number} Count
 */
function countByConfidence(metadata, threshold) {
  return Object.values(metadata).filter(m => m.confidence >= threshold).length;
}

/**
 * Backward compatible wrapper (returns just entities)
 * @param {Object} email - Email object
 * @param {string} intentId - Intent ID
 * @returns {Object} Entities only (for backward compatibility)
 */
function extractEntities(email, intentId = null) {
  const result = extractEntitiesEnhanced(email, intentId);
  return result.entities;
}

module.exports = {
  extractEntitiesEnhanced,
  extractEntities,
  CONFIDENCE,
  ENTITY_TYPES
};
