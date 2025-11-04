/**
 * Rules Engine
 * Maps Intent + Entities → Suggested Actions
 * Evaluates business rules to determine which actions are valid and their priority
 */

const { getAction, getActionsForIntent, canExecuteAction } = require('./action-catalog');
const { getIntent, getAllIntentIds } = require('../../shared/models/Intent');
const logger = require('../../shared/config/logger');
const { CompoundActionRegistry } = require('./compound-action-registry');

/**
 * Main rule evaluation function
 * Returns array of suggested actions with context
 */
function suggestActions(intentId, entities, emailContext = {}) {
  // Validate inputs
  if (!intentId || typeof intentId !== 'string') {
    logger.error('Invalid intent ID provided to suggestActions', { 
      intentId: String(intentId),
      type: typeof intentId
    });
    return getDefaultActions();
  }

  const intent = getIntent(intentId);
  if (!intent) {
    logger.warn('Unknown intent detected, using default actions', { 
      intentId,
      availableIntents: getAllIntentIds().length,
      emailSubject: emailContext.subject || 'unknown'
    });
    
    // Return default with metadata about fallback
    const actions = getDefaultActions();
    return actions.map(action => ({
      ...action,
      _fallbackReason: 'unknown_intent',
      _originalIntent: intentId
    }));
  }

  // Get all potential actions for this intent
  const potentialActions = getActionsForIntent(intentId);
  
  // Filter actions based on available entities
  const validActions = potentialActions.filter(action =>
    canExecuteAction(action, entities)
  );

  // SMART COMPOUND ACTION DETECTION
  // Detect if a compound action is appropriate based on intent + entity richness
  const detectedCompoundActionId = CompoundActionRegistry.detectCompoundAction(intentId, entities);

  if (detectedCompoundActionId) {
    const compoundDef = CompoundActionRegistry.getCompoundAction(detectedCompoundActionId);

    if (compoundDef) {
      logger.info('🔗 Compound action detected', {
        intentId,
        compoundActionId: detectedCompoundActionId,
        displayName: compoundDef.displayName,
        steps: compoundDef.steps,
        requiresResponse: compoundDef.requiresResponse,
        isPremium: compoundDef.isPremium
      });

      // Build compound action suggestion
      const compoundSuggestion = {
        actionId: compoundDef.actionId,
        displayName: compoundDef.displayName,
        actionType: 'IN_APP',  // All compound actions are IN_APP
        isPrimary: true,  // Compound actions should be primary when detected
        priority: 0,  // Highest priority
        isCompound: true,
        compoundSteps: compoundDef.steps,
        requiresResponse: compoundDef.requiresResponse,
        isPremium: compoundDef.isPremium,
        context: extractCompoundContext(compoundDef, entities, emailContext)
      };

      // Add compound action as primary, followed by individual step actions
      const suggestions = [compoundSuggestion];

      // Add individual actions as alternatives
      validActions.forEach(action => {
        const suggestion = buildActionSuggestion(action, entities, emailContext);
        suggestion.isPrimary = false;  // Not primary since compound is primary
        suggestions.push(suggestion);
      });

      return suggestions.slice(0, 5);  // Limit to top 5
    }
  }

  // Build action suggestions with context (no compound action detected)
  const suggestions = validActions.map(action =>
    buildActionSuggestion(action, entities, emailContext)
  );

  // Sort by priority (lower number = higher priority)
  suggestions.sort((a, b) => a.priority - b.priority);

  // SPECIAL CASE: For generic/unclear intents, boost view_details to first position
  // This makes sense because when intent is unclear, viewing details is most useful
  if (intentId.startsWith('generic.') && suggestions.length > 0) {
    const viewDetailsIndex = suggestions.findIndex(s => s.actionId === 'view_details');
    if (viewDetailsIndex > 0) {
      // Move view_details to front
      const viewDetailsAction = suggestions.splice(viewDetailsIndex, 1)[0];
      suggestions.unshift(viewDetailsAction);
      logger.info('Boosted view_details to first position for generic intent', { intentId });
    }
  }

  // If no valid actions found, try to extract a primary URL as fallback
  if (suggestions.length === 0) {
    const primaryUrl = extractPrimaryUrl(entities, emailContext);

    if (primaryUrl) {
      // Return "Open Link" action with extracted URL
      logger.info('No valid actions, but found primary URL - suggesting Open Link', {
        intentId,
        url: primaryUrl.substring(0, 50) + '...'
      });

      return [{
        actionId: 'open_link',
        displayName: 'Open Link',
        actionType: 'GO_TO',
        isPrimary: true,
        priority: 1,
        context: { url: primaryUrl },
        _fallbackReason: 'primary_url_extracted'
      }];
    }

    // No URL found either, use generic actions
    logger.info('No valid actions or URLs found, using default actions', { intentId });
    return getDefaultActions();
  }

  // Mark the first valid action as primary
  if (suggestions.length > 0) {
    suggestions[0].isPrimary = true;
  }

  // Limit to top 5 actions
  return suggestions.slice(0, 5);
}

/**
 * Extract primary URL from email when no specific actions can execute
 * Looks for the most relevant URL in order of preference
 * @param {Object} entities - Extracted entities
 * @param {Object} emailContext - Email context (subject, body)
 * @returns {string|null} Primary URL or null
 */
function extractPrimaryUrl(entities, emailContext) {
  // Priority 1: Already extracted URLs from entities
  const urlPriority = [
    'trackingUrl',
    'orderUrl',
    'paymentUrl',
    'subscriptionUrl',
    'checkInUrl',
    'reservationUrl',
    'resultsUrl',
    'itineraryUrl',
    'assignmentUrl',
    'ticketUrl',
    'surveyLink',
    'reviewLink',
    'registrationLink'
  ];

  for (const urlKey of urlPriority) {
    if (entities[urlKey] && typeof entities[urlKey] === 'string') {
      logger.info(`Found primary URL from entity: ${urlKey}`, { url: entities[urlKey].substring(0, 50) });
      return entities[urlKey];
    }
  }

  // Priority 2: Extract from email body/subject if provided
  if (emailContext.body || emailContext.subject) {
    const text = `${emailContext.subject || ''} ${emailContext.body || ''}`;

    // Look for prominent URLs (https links)
    const urlMatch = text.match(/https?:\/\/[^\s<>"]+/i);
    if (urlMatch) {
      logger.info('Extracted URL from email text', { url: urlMatch[0].substring(0, 50) });
      return urlMatch[0];
    }
  }

  return null;
}

/**
 * Build action suggestion with entity context
 * @param {Object} action - Action object from catalog
 * @param {Object} entities - Extracted entities from email
 * @param {Object} emailContext - Additional email context (subject, from)
 * @returns {Object} Action suggestion with populated context
 * @property {string} actionId - Action identifier
 * @property {string} displayName - Human-readable name
 * @property {string} actionType - 'GO_TO' or 'IN_APP'
 * @property {boolean} isPrimary - Whether this is the primary action
 * @property {number} priority - Action priority
 * @property {Object} context - Entity values for this action
 */
function buildActionSuggestion(action, entities, emailContext) {
  const context = {};

  // Extract relevant entity values for this action
  if (action.requiredEntities) {
    for (const entityName of action.requiredEntities) {
      if (entities[entityName] !== undefined) {
        context[entityName] = entities[entityName];
      }
    }
  }

  // CRITICAL: Enforce URL schema for GO_TO actions and IN_APP payment actions
  // iOS requires a "url" key for all GO_TO actions to open Safari correctly
  // IN_APP payment actions also need URLs for payment links
  // PRIORITY 1: Check if explicit semantic URL exists (trackingUrl, invoiceUrl, paymentLink, etc.)
  // PRIORITY 2: Generate URL if no explicit URL found
  const needsUrl = (action.actionType === 'GO_TO') ||
                   (action.actionType === 'IN_APP' && ['pay_invoice', 'pay_form_fee'].includes(action.actionId));

  if (needsUrl && !context.url) {
    const urlKeys = [
      'trackingUrl', 'invoiceUrl', 'paymentLink', 'checkInUrl', 'productUrl',
      'proposalUrl', 'meetingUrl', 'reservationUrl', 'itineraryUrl',
      'taskUrl', 'incidentUrl', 'registrationUrl', 'surveyUrl',
      'resetUrl', 'verifyUrl', 'securityUrl', 'revokeUrl',
      'resultsUrl', 'supportUrl', 'ticketUrl', 'bookingUrl', 'cartUrl',
      'comparisonUrl', 'dealsUrl', 'schedulingUrl', 'contactUrl', 'mapsUrl',
      'orderUrl', 'paymentUrl', 'returnUrl'
    ];

    // Find first semantic URL key in BOTH context and entities, copy to "url" for iOS compatibility
    for (const urlKey of urlKeys) {
      // Check context first
      if (context[urlKey] && typeof context[urlKey] === 'string' && context[urlKey].trim()) {
        context.url = context[urlKey];
        logger.info(`Enforced URL schema: copied ${urlKey} → url for action ${action.actionId}`, {
          actionId: action.actionId,
          sourceKey: urlKey,
          url: context.url.substring(0, 50) + '...'
        });
        break;
      }
      // Check entities as fallback (might not be in requiredEntities)
      if (entities[urlKey] && typeof entities[urlKey] === 'string' && entities[urlKey].trim()) {
        context.url = entities[urlKey];
        context[urlKey] = entities[urlKey];  // Also copy the semantic key
        logger.info(`Enforced URL schema: copied entities.${urlKey} → url for action ${action.actionId}`, {
          actionId: action.actionId,
          sourceKey: urlKey,
          url: context.url.substring(0, 50) + '...'
        });
        break;
      }
    }

    // PRIORITY 3: If still no URL found, try generating from template/action logic
    if (!context.url && action.urlTemplate) {
      context.url = generateActionUrl(action, entities, emailContext);
      logger.info(`Generated URL from action template/logic for ${action.actionId}`, {
        actionId: action.actionId,
        hasUrlTemplate: !!action.urlTemplate,
        url: context.url ? context.url.substring(0, 50) + '...' : 'none'
      });
    }

    // If still no URL after all attempts, log warning
    if (!context.url) {
      logger.warn(`GO_TO action missing URL after all URL resolution attempts`, {
        actionId: action.actionId,
        contextKeys: Object.keys(context),
        entityKeys: Object.keys(entities),
        actionType: action.actionType,
        hadUrlTemplate: !!action.urlTemplate
      });
    }
  }

  return {
    actionId: action.actionId,
    displayName: action.displayName,
    actionType: action.actionType,
    isPrimary: false, // Set by caller
    priority: action.priority,
    context,
    isCompound: action.isCompound || false,
    compoundSteps: action.compoundSteps || null
  };
}

/**
 * Generate action URL from template and entities
 * @param {Object} action - Action object with urlTemplate
 * @param {Object} entities - Extracted entities for substitution
 * @param {Object} emailContext - Additional email context
 * @returns {string} Generated URL with entities substituted
 */
function generateActionUrl(action, entities, emailContext) {
  let url = action.urlTemplate;

  // Handle special URL generators
  if (action.actionId === 'track_package') {
    return generateTrackingUrl(entities.carrier, entities.trackingNumber);
  }

  // Simple template replacement
  for (const [key, value] of Object.entries(entities)) {
    const placeholder = `{${key}}`;
    if (url && url.includes(placeholder) && value) {
      url = url.replace(placeholder, encodeURIComponent(value));
    }
  }

  return url;
}

/**
 * Generate carrier-specific tracking URL
 * Uses centralized carrier configuration
 * @param {string} carrier - Carrier name (e.g., 'UPS', 'FedEx')
 * @param {string} trackingNumber - Tracking number
 * @returns {string} Tracking URL
 */
function generateTrackingUrl(carrier, trackingNumber) {
  // Use centralized carrier configuration
  const carriersConfig = require('../../shared/config/carriers');
  return carriersConfig.getTrackingUrl(carrier || '', trackingNumber);
}

/**
 * Get default actions when no specific actions can be suggested
 * These are generic actions that work for any email
 * @returns {Array<Object>} Array of default actions (view, reply, save)
 */
function getDefaultActions() {
  return [
    {
      actionId: 'view_details',
      displayName: 'View Details',
      actionType: 'IN_APP',
      isPrimary: true,
      priority: 1,
      context: {}
    },
    {
      actionId: 'quick_reply',
      displayName: 'Quick Reply',
      actionType: 'IN_APP',
      isPrimary: false,
      priority: 2,
      context: {}
    },
    {
      actionId: 'save_for_later',
      displayName: 'Save for Later',
      actionType: 'IN_APP',
      isPrimary: false,
      priority: 3,
      context: {}
    }
  ];
}

/**
 * Evaluate compound action requirements
 * Returns true if all steps of compound action can be executed
 * @param {Object} action - Action object (potentially compound)
 * @param {Object} entities - Extracted entities
 * @returns {boolean} True if all compound steps can execute
 */
function canExecuteCompoundAction(action, entities) {
  if (!action.isCompound || !action.compoundSteps) {
    return canExecuteAction(action, entities);
  }

  // Check if all steps can be executed
  for (const stepActionId of action.compoundSteps) {
    const stepAction = getAction(stepActionId);
    if (!stepAction || !canExecuteAction(stepAction, entities)) {
      return false;
    }
  }

  return true;
}

/**
 * Get actions by category for batch processing
 */
function getActionsByCategory(category) {
  const { ActionCatalog } = require('./action-catalog');
  const { getIntentsByCategory } = require('../../shared/models/Intent');
  
  const categoryIntents = Object.keys(getIntentsByCategory(category));
  const actions = new Set();

  for (const intentId of categoryIntents) {
    const intentActions = getActionsForIntent(intentId);
    intentActions.forEach(action => actions.add(action.actionId));
  }

  return Array.from(actions).map(actionId => getAction(actionId));
}

/**
 * Extract compound action context from entities and email context
 * Gathers all relevant entities needed for compound action steps
 * @param {Object} compoundDef - Compound action definition
 * @param {Object} entities - Extracted entities from email
 * @param {Object} emailContext - Email context (subject, from, body)
 * @returns {Object} Context object with all relevant entities
 */
function extractCompoundContext(compoundDef, entities, emailContext) {
  const context = { ...entities };  // Start with all entities

  // Add email metadata
  if (emailContext.subject) {
    context.subject = emailContext.subject;
  }
  if (emailContext.from) {
    context.sender = emailContext.from;
    context.sender_name = emailContext.from.split('@')[0] || emailContext.from;
  }

  // Add compound-specific metadata
  context.compoundActionId = compoundDef.actionId;
  context.totalSteps = compoundDef.steps.length;
  context.requiresResponse = compoundDef.requiresResponse;

  // Add end behavior information for iOS
  if (compoundDef.endBehavior) {
    context.endBehaviorType = compoundDef.endBehavior.type;

    // If email composer, include template information
    if (compoundDef.endBehavior.template) {
      context.emailTemplate = {
        subjectPrefix: compoundDef.endBehavior.template.subjectPrefix,
        bodyTemplate: compoundDef.endBehavior.template.bodyTemplate,
        includeOriginalSender: compoundDef.endBehavior.template.includeOriginalSender
      };
    }
  }

  // CRITICAL: Enforce URL schema for compound actions with GO_TO steps
  // If compound action includes a GO_TO step (like track_with_calendar),
  // ensure we have a generic "url" key for iOS
  if (!context.url) {
    const urlKeys = [
      'trackingUrl', 'invoiceUrl', 'paymentLink', 'checkInUrl', 'productUrl',
      'proposalUrl', 'meetingUrl', 'reservationUrl', 'itineraryUrl',
      'taskUrl', 'incidentUrl', 'registrationUrl', 'surveyUrl',
      'resetUrl', 'verifyUrl', 'securityUrl', 'revokeUrl',
      'resultsUrl', 'supportUrl', 'ticketUrl', 'bookingUrl', 'cartUrl',
      'comparisonUrl', 'dealsUrl', 'schedulingUrl', 'contactUrl', 'mapsUrl',
      'orderUrl', 'paymentUrl', 'returnUrl'
    ];

    for (const urlKey of urlKeys) {
      if (context[urlKey] && typeof context[urlKey] === 'string' && context[urlKey].trim()) {
        context.url = context[urlKey];
        logger.info(`Enforced URL schema for compound action: copied ${urlKey} → url`, {
          compoundActionId: compoundDef.actionId,
          sourceKey: urlKey
        });
        break;
      }
    }

    // If still no URL, try generating one for compound actions with GO_TO steps
    if (!context.url && compoundDef.steps.length > 0) {
      const firstStep = compoundDef.steps[0];
      const firstStepAction = getAction(firstStep);

      if (firstStepAction && firstStepAction.actionType === 'GO_TO') {
        // Generate URL for the first GO_TO step
        if (firstStep === 'track_package' && context.carrier && context.trackingNumber) {
          context.url = generateTrackingUrl(context.carrier, context.trackingNumber);
          context.trackingUrl = context.url; // Also set trackingUrl for consistency
          logger.info(`Generated tracking URL for compound action`, {
            compoundActionId: compoundDef.actionId,
            carrier: context.carrier,
            trackingNumber: context.trackingNumber
          });
        } else if (firstStep === 'pay_invoice' && context.paymentLink) {
          context.url = context.paymentLink;
          logger.info(`Used paymentLink as URL for compound action`, {
            compoundActionId: compoundDef.actionId
          });
        }
        // Add more step-specific URL generation as needed
      }
    }
  }

  return context;
}

/**
 * Rule-based action ranking (can be enhanced with ML later)
 * Adjusts action priority based on context and user behavior
 * @param {Array<Object>} actions - Array of action suggestions
 * @param {Object} userPreferences - User preferences for personalization (future)
 * @returns {Array<Object>} Ranked actions (sorted by priority)
 */
function rankActions(actions, userPreferences = {}) {
  // Clone array to avoid mutations
  const rankedActions = [...actions];

  // Sort by priority (lower number = higher priority)
  rankedActions.sort((a, b) => a.priority - b.priority);

  // Apply user preference boosting (future enhancement)
  // if (userPreferences.preferredActions) {
  //   // Boost actions user frequently uses
  // }

  return rankedActions;
}

module.exports = {
  suggestActions,
  buildActionSuggestion,
  generateActionUrl,
  generateTrackingUrl,
  extractPrimaryUrl,
  extractCompoundContext,
  canExecuteCompoundAction,
  getActionsByCategory,
  rankActions,
  getDefaultActions,
  CompoundActionRegistry  // Export for testing and external use
};

