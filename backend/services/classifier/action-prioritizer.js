/**
 * Action Prioritizer
 * Phase 3.3: Context-aware action prioritization
 *
 * Purpose: Intelligently re-rank actions based on:
 * - Time of day context (morning vs evening actions)
 * - Urgency signals
 * - Entity availability and confidence
 * - Action type (IN_APP faster than GO_TO)
 */

const logger = require('./shared/config/logger');

/**
 * Time periods for contextual ranking
 */
const TIME_PERIODS = {
  EARLY_MORNING: 'early_morning',   // 5am-9am
  MORNING: 'morning',                 // 9am-12pm
  AFTERNOON: 'afternoon',             // 12pm-5pm
  EVENING: 'evening',                 // 5pm-9pm
  NIGHT: 'night'                      // 9pm-5am
};

/**
 * Get current time period
 */
function getTimePeriod(date = new Date()) {
  const hour = date.getHours();

  if (hour >= 5 && hour < 9) return TIME_PERIODS.EARLY_MORNING;
  if (hour >= 9 && hour < 12) return TIME_PERIODS.MORNING;
  if (hour >= 12 && hour < 17) return TIME_PERIODS.AFTERNOON;
  if (hour >= 17 && hour < 21) return TIME_PERIODS.EVENING;
  return TIME_PERIODS.NIGHT;
}

/**
 * Action affinity by time period
 * Higher score = more relevant at this time
 */
const TIME_AFFINITY = {
  // Booking/scheduling actions - best in morning/afternoon
  'book_appointment': {
    [TIME_PERIODS.EARLY_MORNING]: 0.6,
    [TIME_PERIODS.MORNING]: 1.0,
    [TIME_PERIODS.AFTERNOON]: 0.9,
    [TIME_PERIODS.EVENING]: 0.5,
    [TIME_PERIODS.NIGHT]: 0.3
  },
  'schedule_meeting': {
    [TIME_PERIODS.EARLY_MORNING]: 0.6,
    [TIME_PERIODS.MORNING]: 1.0,
    [TIME_PERIODS.AFTERNOON]: 0.9,
    [TIME_PERIODS.EVENING]: 0.5,
    [TIME_PERIODS.NIGHT]: 0.3
  },

  // Food orders - best around meal times
  'order_food': {
    [TIME_PERIODS.EARLY_MORNING]: 0.8,  // Breakfast
    [TIME_PERIODS.MORNING]: 0.5,
    [TIME_PERIODS.AFTERNOON]: 0.9,      // Lunch
    [TIME_PERIODS.EVENING]: 1.0,        // Dinner
    [TIME_PERIODS.NIGHT]: 0.6
  },

  // Shopping/payments - anytime but prefer daytime
  'pay_invoice': {
    [TIME_PERIODS.EARLY_MORNING]: 0.7,
    [TIME_PERIODS.MORNING]: 1.0,
    [TIME_PERIODS.AFTERNOON]: 1.0,
    [TIME_PERIODS.EVENING]: 0.8,
    [TIME_PERIODS.NIGHT]: 0.5
  },
  'shop_now': {
    [TIME_PERIODS.EARLY_MORNING]: 0.6,
    [TIME_PERIODS.MORNING]: 0.9,
    [TIME_PERIODS.AFTERNOON]: 1.0,
    [TIME_PERIODS.EVENING]: 0.9,
    [TIME_PERIODS.NIGHT]: 0.7
  },

  // Travel actions - prefer daytime
  'check_in_flight': {
    [TIME_PERIODS.EARLY_MORNING]: 1.0,  // Check in early
    [TIME_PERIODS.MORNING]: 0.9,
    [TIME_PERIODS.AFTERNOON]: 0.8,
    [TIME_PERIODS.EVENING]: 0.7,
    [TIME_PERIODS.NIGHT]: 0.5
  },

  // Default: neutral across all times
  '_default': {
    [TIME_PERIODS.EARLY_MORNING]: 0.85,
    [TIME_PERIODS.MORNING]: 0.9,
    [TIME_PERIODS.AFTERNOON]: 0.9,
    [TIME_PERIODS.EVENING]: 0.85,
    [TIME_PERIODS.NIGHT]: 0.8
  }
};

/**
 * Calculate time-based priority boost
 */
function getTimeAffinityBoost(actionId, timePeriod) {
  const affinity = TIME_AFFINITY[actionId] || TIME_AFFINITY._default;
  return affinity[timePeriod] || 0.8;
}

/**
 * Calculate entity readiness score
 * Measures how ready an action is to be executed based on entity availability
 */
function calculateEntityReadiness(action, entityMetadata = {}) {
  const requiredEntities = action.requiredEntities || [];

  if (requiredEntities.length === 0) {
    return {
      score: 1.0,
      ready: true,
      availableCount: 0,
      totalCount: 0
    };
  }

  let availableCount = 0;
  let totalConfidence = 0;

  requiredEntities.forEach(entityName => {
    const meta = entityMetadata[entityName];
    if (meta) {
      availableCount++;
      totalConfidence += meta.confidence || 0;
    }
  });

  const availabilityRate = availableCount / requiredEntities.length;
  const avgConfidence = availableCount > 0 ? totalConfidence / availableCount : 0;

  // Score: 70% availability, 30% confidence
  const score = availabilityRate * 0.7 + avgConfidence * 0.3;

  return {
    score,
    ready: availabilityRate === 1.0,
    availableCount,
    totalCount: requiredEntities.length,
    avgConfidence
  };
}

/**
 * Calculate action type preference
 * IN_APP actions are generally faster/easier than GO_TO
 * BUT for newsletters/ads, GO_TO should be preferred
 */
function getActionTypeBoost(actionType, emailArchetype) {
  // For newsletters and ads, prefer GO_TO (view website) over quick reply
  if (emailArchetype === 'newsletter' || emailArchetype === 'ads') {
    switch (actionType) {
      case 'GO_TO':
        return 1.15;    // 15% boost - newsletters are meant to be clicked
      case 'IN_APP':
        return 1.1;     // 10% boost - stays in app
      case 'QUICK_REPLY':
        return 0.95;    // 5% penalty - not typical for newsletters
      default:
        return 1.0;
    }
  }

  // For other email types, prefer quick/in-app actions
  switch (actionType) {
    case 'IN_APP':
      return 1.1;     // 10% boost - faster, stays in app
    case 'QUICK_REPLY':
      return 1.05;    // 5% boost - very quick
    case 'GO_TO':
      return 1.0;     // Neutral - opens external link
    default:
      return 1.0;
  }
}

/**
 * Calculate urgency boost
 * Urgent emails should have urgent actions prioritized
 */
function getUrgencyBoost(isUrgent) {
  return isUrgent ? 1.15 : 1.0;  // 15% boost for urgent actions
}

/**
 * Prioritize actions based on context
 * @param {Array} actions - Array of action objects
 * @param {Object} context - Contextual information
 * @returns {Array} Re-prioritized actions
 */
function prioritizeActions(actions, context = {}) {
  const startTime = Date.now();

  const {
    entityMetadata = {},
    isUrgent = false,
    timePeriod = getTimePeriod(),
    intent = '',
    emailArchetype = ''
  } = context;

  // Calculate priority scores for each action
  const scoredActions = actions.map(action => {
    // Base score from original priority (lower number = higher priority)
    // Convert to score: priority 1 → 1.0, priority 2 → 0.9, priority 3 → 0.8, etc.
    const basePriority = action.priority || 5;
    let score = Math.max(0.1, 1.0 - (basePriority - 1) * 0.1);

    // Factor 1: Time affinity
    const timeBoost = getTimeAffinityBoost(action.actionId, timePeriod);
    score *= timeBoost;

    // Factor 2: Entity readiness (significant impact on executability)
    const entityReadiness = calculateEntityReadiness(action, entityMetadata);
    score *= (0.5 + entityReadiness.score * 0.5);  // 50% base + 50% readiness

    // Factor 3: Action type preference (archetype-aware)
    const typeBoost = getActionTypeBoost(action.actionType, emailArchetype);
    score *= typeBoost;

    // Factor 4: Urgency
    if (isUrgent) {
      const urgencyBoost = getUrgencyBoost(isUrgent);
      score *= urgencyBoost;
    }

    // Factor 5: Primary action boost
    if (action.isPrimary) {
      score *= 1.2;  // 20% boost for primary action
    }

    return {
      ...action,
      _priorityScore: score,
      _priorityFactors: {
        baseScore: Math.max(0.1, 1.0 - (basePriority - 1) * 0.1),
        timeBoost,
        entityReadiness: entityReadiness.score,
        entityReady: entityReadiness.ready,
        typeBoost,
        urgencyBoost: isUrgent ? getUrgencyBoost(isUrgent) : 1.0,
        primaryBoost: action.isPrimary ? 1.2 : 1.0
      }
    };
  });

  // Sort by priority score (highest first)
  const prioritized = scoredActions.sort((a, b) => b._priorityScore - a._priorityScore);

  // Re-assign isPrimary to highest scoring action
  if (prioritized.length > 0) {
    // Clear all isPrimary flags
    prioritized.forEach(a => { a.isPrimary = false; });
    // Set new primary
    prioritized[0].isPrimary = true;
  }

  // Update priority numbers based on new ranking
  prioritized.forEach((action, index) => {
    action.priority = index + 1;
  });

  const processingTime = Date.now() - startTime;

  logger.info('Actions prioritized', {
    actionCount: actions.length,
    timePeriod,
    isUrgent,
    topAction: prioritized[0]?.actionId,
    topScore: prioritized[0]?._priorityScore.toFixed(3),
    processingTime
  });

  return prioritized;
}

/**
 * Get prioritization explanation for debugging
 */
function explainPrioritization(action) {
  if (!action._priorityFactors) {
    return 'No prioritization data available';
  }

  const factors = action._priorityFactors;
  const explanation = [];

  explanation.push(`Base: ${factors.baseScore.toFixed(2)}`);
  explanation.push(`Time: ${factors.timeBoost.toFixed(2)}x`);
  explanation.push(`Entities: ${factors.entityReadiness.toFixed(2)} (${factors.entityReady ? 'ready' : 'partial'})`);
  explanation.push(`Type: ${factors.typeBoost.toFixed(2)}x`);

  if (factors.urgencyBoost > 1.0) {
    explanation.push(`Urgent: ${factors.urgencyBoost.toFixed(2)}x`);
  }

  if (factors.primaryBoost > 1.0) {
    explanation.push(`Primary: ${factors.primaryBoost.toFixed(2)}x`);
  }

  return explanation.join(' | ');
}

module.exports = {
  prioritizeActions,
  explainPrioritization,
  getTimePeriod,
  TIME_PERIODS,
  calculateEntityReadiness,
  getTimeAffinityBoost,
  getActionTypeBoost,
  getUrgencyBoost
};
