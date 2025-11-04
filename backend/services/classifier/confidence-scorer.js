/**
 * Confidence Scorer
 * Phase 3.2: Advanced confidence scoring that combines intent + entity + action confidence
 *
 * Purpose: Provide holistic confidence scores for iOS to make smart UI decisions
 * (e.g., show confirmation dialogs for low confidence, auto-execute for high confidence)
 */

const logger = require('./shared/config/logger');

/**
 * Confidence levels for UI decision making
 */
const CONFIDENCE_LEVELS = {
  VERY_HIGH: 'VERY_HIGH',  // 0.90+ - Auto-execute safe
  HIGH: 'HIGH',            // 0.75-0.89 - Show with confidence
  MEDIUM: 'MEDIUM',        // 0.60-0.74 - Show with caution
  LOW: 'LOW',              // 0.40-0.59 - Suggest as option
  VERY_LOW: 'VERY_LOW'     // <0.40 - Hide or show at bottom
};

/**
 * Determine confidence level from score
 */
function getConfidenceLevel(score) {
  if (score >= 0.90) return CONFIDENCE_LEVELS.VERY_HIGH;
  if (score >= 0.75) return CONFIDENCE_LEVELS.HIGH;
  if (score >= 0.60) return CONFIDENCE_LEVELS.MEDIUM;
  if (score >= 0.40) return CONFIDENCE_LEVELS.LOW;
  return CONFIDENCE_LEVELS.VERY_LOW;
}

/**
 * Calculate entity quality score from entity metadata
 * @param {Object} entityMetadata - Entity metadata from enhanced extractor
 * @param {Object} entityStats - Entity stats from enhanced extractor
 * @returns {Object} Entity quality assessment
 */
function assessEntityQuality(entityMetadata = {}, entityStats = {}) {
  const entityKeys = Object.keys(entityMetadata);

  if (entityKeys.length === 0) {
    return {
      score: 0.5,  // Neutral - no entities extracted
      quality: 'none',
      validatedCount: 0,
      totalCount: 0,
      avgConfidence: 0
    };
  }

  let validatedCount = 0;
  let highConfidenceCount = 0;
  const totalCount = entityKeys.length;

  entityKeys.forEach(key => {
    const meta = entityMetadata[key];
    if (meta.validated) validatedCount++;
    if (meta.confidence >= 0.8) highConfidenceCount++;
  });

  const validationRate = validatedCount / totalCount;
  const highConfidenceRate = highConfidenceCount / totalCount;
  const avgConfidence = entityStats.avgConfidence || 0;

  // Calculate entity quality score (weighted)
  const score = (
    avgConfidence * 0.5 +           // 50% weight on average confidence
    validationRate * 0.3 +           // 30% weight on validation rate
    highConfidenceRate * 0.2         // 20% weight on high confidence rate
  );

  let quality = 'low';
  if (score >= 0.75) quality = 'high';
  else if (score >= 0.55) quality = 'medium';

  return {
    score,
    quality,
    validatedCount,
    totalCount,
    avgConfidence,
    validationRate,
    highConfidenceRate
  };
}

/**
 * Calculate action confidence based on action availability and quality
 * @param {Array} suggestedActions - Suggested actions from rules engine
 * @returns {Object} Action confidence assessment
 */
function assessActionConfidence(suggestedActions = []) {
  if (!suggestedActions || suggestedActions.length === 0) {
    return {
      score: 0.5,  // Neutral - no actions available
      hasPrimaryAction: false,
      hasValidUrls: false,
      actionCount: 0
    };
  }

  const primaryAction = suggestedActions.find(a => a.isPrimary);
  const hasPrimaryAction = !!primaryAction;

  // Check if actions have valid URLs (not placeholder templates)
  const hasValidUrls = suggestedActions.some(action => {
    if (!action.url) return false;
    // Check if URL is a placeholder template like {orderUrl}
    return !action.url.includes('{') && !action.url.includes('}');
  });

  const actionCount = suggestedActions.length;

  // Calculate action confidence
  let score = 0.6; // Base score for having actions
  if (hasPrimaryAction) score += 0.2;
  if (hasValidUrls) score += 0.15;
  if (actionCount >= 2) score += 0.05;

  return {
    score: Math.min(score, 1.0),
    hasPrimaryAction,
    hasValidUrls,
    actionCount
  };
}

/**
 * Calculate overall classification confidence
 * Combines intent confidence, entity quality, and action confidence
 *
 * @param {Object} classification - Complete classification result
 * @returns {Object} Enhanced confidence assessment
 */
function calculateOverallConfidence(classification) {
  const startTime = Date.now();

  // Extract components
  const intentConfidence = classification.intentConfidence || 0.5;
  const entityMetadata = classification.entityMetadata || {};
  const entityStats = classification.entityStats || {};
  const suggestedActions = classification.suggestedActions || [];
  const source = classification._classificationSource || 'unknown';

  // Assess each component
  const entityQuality = assessEntityQuality(entityMetadata, entityStats);
  const actionQuality = assessActionConfidence(suggestedActions);

  // Calculate overall confidence (weighted combination)
  const weights = {
    intent: 0.50,    // 50% - Intent is most important
    entity: 0.30,    // 30% - Entity quality matters for action execution
    action: 0.20     // 20% - Action availability affects user experience
  };

  let overallConfidence = (
    intentConfidence * weights.intent +
    entityQuality.score * weights.entity +
    actionQuality.score * weights.action
  );

  // Build confidence factors explanation
  const confidenceFactors = [];

  // Factor 1: Intent confidence
  if (intentConfidence >= 0.8) {
    confidenceFactors.push({
      factor: 'intent_match',
      contribution: intentConfidence * weights.intent,
      description: `Strong ${source} match`,
      positive: true
    });
  } else if (intentConfidence < 0.5) {
    confidenceFactors.push({
      factor: 'intent_match',
      contribution: intentConfidence * weights.intent,
      description: `Weak intent confidence (${(intentConfidence * 100).toFixed(0)}%)`,
      positive: false
    });
  }

  // Factor 2: Entity validation
  if (entityQuality.validatedCount > 0) {
    confidenceFactors.push({
      factor: 'entity_validation',
      contribution: entityQuality.score * weights.entity,
      description: `${entityQuality.validatedCount}/${entityQuality.totalCount} entities validated`,
      positive: true
    });
  } else if (entityQuality.totalCount > 0) {
    confidenceFactors.push({
      factor: 'entity_validation',
      contribution: entityQuality.score * weights.entity,
      description: 'No entities validated',
      positive: false
    });
  }

  // Factor 3: Action availability
  if (actionQuality.hasPrimaryAction) {
    confidenceFactors.push({
      factor: 'action_availability',
      contribution: actionQuality.score * weights.action,
      description: 'Primary action available',
      positive: true
    });
  }

  if (actionQuality.hasValidUrls) {
    confidenceFactors.push({
      factor: 'action_urls',
      contribution: 0.05,
      description: 'Action URLs ready',
      positive: true
    });
  }

  // Factor 4: Source reliability (apply boost/penalty to overall confidence)
  const sourceBoosts = {
    'pattern_matching': 0.05,
    'schema_org': 0.10,
    'known_retailer_domain': 0.05,
    'hybrid': 0.02,
    'fallback': -0.10
  };

  const sourceBoost = sourceBoosts[source] || 0;
  if (sourceBoost !== 0) {
    overallConfidence += sourceBoost; // Apply boost/penalty to final score
    confidenceFactors.push({
      factor: 'classification_source',
      contribution: sourceBoost,
      description: `Source: ${source}`,
      positive: sourceBoost > 0
    });
  }

  // Determine confidence level (after applying source boost)
  const level = getConfidenceLevel(overallConfidence);

  // Determine if confirmation should be shown
  const shouldShowConfirmation = level === CONFIDENCE_LEVELS.LOW ||
                                  level === CONFIDENCE_LEVELS.VERY_LOW ||
                                  (level === CONFIDENCE_LEVELS.MEDIUM && !entityQuality.validatedCount);

  const processingTime = Date.now() - startTime;

  const result = {
    overallConfidence: Math.min(Math.max(overallConfidence, 0), 1), // Clamp to [0, 1]
    level,
    shouldShowConfirmation,
    breakdown: {
      intentConfidence,
      entityQuality: {
        score: entityQuality.score,
        quality: entityQuality.quality,
        validatedCount: entityQuality.validatedCount,
        totalCount: entityQuality.totalCount,
        avgConfidence: entityQuality.avgConfidence
      },
      actionQuality: {
        score: actionQuality.score,
        hasPrimaryAction: actionQuality.hasPrimaryAction,
        hasValidUrls: actionQuality.hasValidUrls,
        actionCount: actionQuality.actionCount
      },
      weights
    },
    confidenceFactors,
    processingTime
  };

  logger.info('Overall confidence calculated', {
    overallConfidence: result.overallConfidence.toFixed(3),
    level,
    intentConf: intentConfidence.toFixed(3),
    entityQuality: entityQuality.quality,
    actionCount: actionQuality.actionCount,
    processingTime
  });

  return result;
}

/**
 * Get confidence-based UI recommendations
 * @param {Object} confidenceResult - Result from calculateOverallConfidence
 * @returns {Object} UI recommendations
 */
function getUIRecommendations(confidenceResult) {
  const { level, overallConfidence, shouldShowConfirmation } = confidenceResult;

  const recommendations = {
    level,
    overallConfidence,
    shouldShowConfirmation,
    uiHints: {}
  };

  switch (level) {
    case CONFIDENCE_LEVELS.VERY_HIGH:
      recommendations.uiHints = {
        actionStyle: 'primary',
        showConfidenceBadge: false,
        enableAutoExecution: true,
        suggestionText: null,
        iconStyle: 'bold'
      };
      break;

    case CONFIDENCE_LEVELS.HIGH:
      recommendations.uiHints = {
        actionStyle: 'primary',
        showConfidenceBadge: false,
        enableAutoExecution: false,
        suggestionText: null,
        iconStyle: 'regular'
      };
      break;

    case CONFIDENCE_LEVELS.MEDIUM:
      recommendations.uiHints = {
        actionStyle: 'secondary',
        showConfidenceBadge: true,
        confidenceBadgeText: 'Suggested',
        enableAutoExecution: false,
        suggestionText: 'Review before executing',
        iconStyle: 'regular'
      };
      break;

    case CONFIDENCE_LEVELS.LOW:
      recommendations.uiHints = {
        actionStyle: 'tertiary',
        showConfidenceBadge: true,
        confidenceBadgeText: 'Possible action',
        enableAutoExecution: false,
        suggestionText: 'Double-check details',
        iconStyle: 'light'
      };
      break;

    case CONFIDENCE_LEVELS.VERY_LOW:
      recommendations.uiHints = {
        actionStyle: 'minimal',
        showConfidenceBadge: true,
        confidenceBadgeText: 'Uncertain',
        enableAutoExecution: false,
        suggestionText: 'Verify before proceeding',
        iconStyle: 'light',
        collapseByDefault: true
      };
      break;
  }

  return recommendations;
}

module.exports = {
  calculateOverallConfidence,
  assessEntityQuality,
  assessActionConfidence,
  getUIRecommendations,
  getConfidenceLevel,
  CONFIDENCE_LEVELS
};
