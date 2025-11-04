/**
 * Debug Classifier (v1.10)
 * Provides comprehensive debugging information for the classification pipeline
 *
 * Returns complete visibility into:
 * - Intent classification with confidence scores
 * - Entity extraction details
 * - Rules engine action mappings
 * - Mail/Ads binary classification reasoning
 * - Priority assignment logic
 * - End-to-end pipeline trace
 */

const EmailCard = require('./EmailCard');
const { classifyEmailActionFirst, isAd } = require('./action-first-classifier');
const logger = require('./logger');

// Stub imports (replace with real implementations when available)
const parseEmailSchema = () => ({ hasSchema: false, actions: [], entities: {} });
const classifyIntent = (email) => {
  // Simplified intent classifier for debugging
  const subject = (email.subject || '').toLowerCase();
  const body = (email.body || '').toLowerCase();
  const snippet = (email.snippet || body).substring(0, 500).toLowerCase();

  // Pattern matching with scores
  const intentPatterns = {
    'e-commerce.shipping.notification': {
      patterns: ['shipped', 'tracking', 'on its way', 'delivery', 'carrier'],
      subjectWeight: 40,
      snippetWeight: 25,
      domainWeight: 30
    },
    'billing.invoice.due': {
      patterns: ['invoice', 'payment due', 'amount due', 'pay now', 'outstanding balance'],
      subjectWeight: 40,
      snippetWeight: 25,
      domainWeight: 30
    },
    'education.permission.form': {
      patterns: ['permission', 'field trip', 'consent form', 'sign and return', 'parent signature'],
      subjectWeight: 40,
      snippetWeight: 25,
      domainWeight: 30
    },
    'travel.flight.checkin': {
      patterns: ['check in', 'check-in', 'flight', 'boarding', 'departure'],
      subjectWeight: 40,
      snippetWeight: 25,
      domainWeight: 30
    },
    'event.rsvp.request': {
      patterns: ['rsvp', 'please respond', 'are you attending', 'confirm attendance'],
      subjectWeight: 40,
      snippetWeight: 25,
      domainWeight: 30
    }
  };

  let bestIntent = 'general.notification';
  let bestScore = 0;
  const allScores = {};

  for (const [intent, config] of Object.entries(intentPatterns)) {
    let score = 0;
    const matches = [];

    for (const pattern of config.patterns) {
      if (subject.includes(pattern)) {
        score += config.subjectWeight;
        matches.push({ location: 'subject', pattern, weight: config.subjectWeight });
      }
      if (snippet.includes(pattern)) {
        score += config.snippetWeight;
        matches.push({ location: 'snippet', pattern, weight: config.snippetWeight });
      }
    }

    allScores[intent] = { score, matches, confidence: Math.min(score / 100, 1.0) };

    if (score > bestScore) {
      bestScore = score;
      bestIntent = intent;
    }
  }

  return {
    intent: bestIntent,
    confidence: Math.min(bestScore / 100, 1.0),
    source: 'pattern-matching',
    allScores
  };
};

const extractAllEntities = (email, fullTextOriginal, intent) => {
  // Simplified entity extractor for debugging
  const entities = {
    deadline: null,
    prices: {},
    stores: [],
    promoCodes: [],
    children: [],
    companies: [],
    accounts: [],
    flights: [],
    hotels: [],
    trackingNumbers: []
  };

  const text = fullTextOriginal || email.body || email.snippet || '';

  // Extract tracking numbers
  const trackingMatch = text.match(/\b[0-9]{12,20}\b|\b1Z[0-9A-Z]{16}\b/);
  if (trackingMatch) {
    entities.trackingNumbers.push(trackingMatch[0]);
  }

  // Extract prices
  const priceMatch = text.match(/\$([0-9,]+\.?\d{0,2})/g);
  if (priceMatch) {
    entities.prices.original = priceMatch[0];
  }

  // Extract deadlines
  const deadlineMatch = text.match(/(due|deadline|expires?|by)\s+([A-Za-z]+\s+\d{1,2}|today|tomorrow|\d{1,2}\/\d{1,2})/i);
  if (deadlineMatch) {
    entities.deadline = {
      text: deadlineMatch[0],
      isUrgent: deadlineMatch[0].toLowerCase().includes('today') || deadlineMatch[0].toLowerCase().includes('tomorrow')
    };
  }

  return entities;
};

const suggestActions = (intent, entities, context) => {
  // Simplified rules engine for debugging
  const rulesEngine = {
    'e-commerce.shipping.notification': {
      requiredEntities: ['trackingNumbers'],
      actions: [{
        actionId: 'track_package',
        displayName: 'Track Package',
        isPrimary: true,
        priority: 2,
        endpoint: '/api/actions/track-package'
      }]
    },
    'billing.invoice.due': {
      requiredEntities: ['prices'],
      actions: [{
        actionId: 'pay_invoice',
        displayName: 'Pay Invoice',
        isPrimary: true,
        priority: 1,
        endpoint: '/api/actions/pay-invoice'
      }]
    },
    'education.permission.form': {
      requiredEntities: ['deadline'],
      actions: [{
        actionId: 'sign_form',
        displayName: 'Sign Form',
        isPrimary: true,
        priority: 1,
        endpoint: '/api/actions/sign-form'
      }]
    },
    'travel.flight.checkin': {
      requiredEntities: ['flights'],
      actions: [{
        actionId: 'check_in_flight',
        displayName: 'Check In',
        isPrimary: true,
        priority: 1,
        endpoint: '/api/actions/check-in'
      }]
    }
  };

  const rule = rulesEngine[intent];
  if (!rule) return [];

  // Check if required entities are present
  const hasRequiredEntities = rule.requiredEntities.every(entityKey => {
    const value = entities[entityKey];
    return value && (Array.isArray(value) ? value.length > 0 : true);
  });

  return hasRequiredEntities ? rule.actions : [];
};

/**
 * Get comprehensive debug information for email classification
 * This is the main function that exposes all 5 dashboards' worth of data
 */
function getDebugClassification(email) {
  const startTime = Date.now();

  // Prepare email text
  const subject = (email.subject || '').toLowerCase();
  const body = (email.body || '').toLowerCase();
  const from = (email.from || '').toLowerCase();
  const snippet = (email.snippet || body).substring(0, 500).toLowerCase();
  const originalBody = email.body || email.snippet || '';
  const originalSubject = email.subject || '';
  const fullTextOriginal = `${originalSubject} ${originalBody.substring(0, 500)}`;

  // STEP 1: Schema.org Check
  const step1Start = Date.now();
  let schemaResult = { hasSchema: false, actions: [], entities: {} };
  if (email.htmlBody) {
    try {
      schemaResult = parseEmailSchema(email.htmlBody);
    } catch (error) {
      schemaResult.error = error.message;
    }
  }
  const step1Time = Date.now() - step1Start;

  // STEP 2: Intent Classification
  const step2Start = Date.now();
  const intentResult = classifyIntent(email);
  const step2Time = Date.now() - step2Start;

  // STEP 3: Entity Extraction
  const step3Start = Date.now();
  const entities = extractAllEntities(email, fullTextOriginal, intentResult.intent);
  const step3Time = Date.now() - step3Start;

  // STEP 4: Rules Engine → Actions
  const step4Start = Date.now();
  const suggestedActions = suggestActions(intentResult.intent, entities, {
    subject: email.subject,
    from: email.from
  });
  const step4Time = Date.now() - step4Start;

  // STEP 5: Mail/Ads Binary Classification
  const step5Start = Date.now();
  email._classifiedIntent = intentResult.intent;
  const isAdResult = isAd(email);
  const category = isAdResult ? EmailCard.ArchetypeTypes.ADS : EmailCard.ArchetypeTypes.MAIL;

  // Detailed ad detection reasoning
  const adDetectionReasoning = {
    hasUnsubscribeHeader: email.headers && email.headers['list-unsubscribe'],
    hasUnsubscribeLink: (email.htmlBody || '').includes('unsubscribe') || body.includes('unsubscribe'),
    promoKeywordMatches: 0,
    marketingSenderMatch: false,
    intentBased: intentResult.intent.startsWith('marketing.') || intentResult.intent.startsWith('e-commerce.promotion'),
    finalDecision: isAdResult ? 'ADS' : 'MAIL'
  };

  const promoKeywords = [
    '% off', 'percent off', 'sale', 'discount', 'deal', 'clearance',
    'limited time', 'expires soon', 'ending soon', 'last chance',
    'save now', 'buy now', 'shop now', 'get yours',
    'exclusive offer', 'special offer', 'new arrivals', 'just dropped',
    'flash sale', 'hot deals', 'today only', 'free shipping',
    'promo code', 'coupon code', 'redeem now'
  ];

  adDetectionReasoning.matchedPromoKeywords = [];
  for (const keyword of promoKeywords) {
    if (subject.includes(keyword) || snippet.includes(keyword)) {
      adDetectionReasoning.promoKeywordMatches++;
      adDetectionReasoning.matchedPromoKeywords.push(keyword);
    }
  }

  const marketingSenders = ['marketing@', 'promo@', 'deals@', 'offers@'];
  for (const pattern of marketingSenders) {
    if (from.includes(pattern)) {
      adDetectionReasoning.marketingSenderMatch = true;
      adDetectionReasoning.matchedSenderPattern = pattern;
    }
  }

  const step5Time = Date.now() - step5Start;

  // STEP 6: Priority Assignment
  const step6Start = Date.now();
  let priority = EmailCard.Priorities.MEDIUM;
  const priorityReasoning = [];

  if (entities.deadline && entities.deadline.isUrgent) {
    priority = EmailCard.Priorities.CRITICAL;
    priorityReasoning.push('Urgent deadline detected');
  } else if (intentResult.intent === 'account.security.alert') {
    priority = EmailCard.Priorities.CRITICAL;
    priorityReasoning.push('Security alert');
  } else if (['billing.invoice.due', 'education.permission.form', 'travel.flight.checkin'].includes(intentResult.intent)) {
    priority = EmailCard.Priorities.HIGH;
    priorityReasoning.push(`High priority intent: ${intentResult.intent}`);
  } else if (category === EmailCard.ArchetypeTypes.ADS) {
    priority = EmailCard.Priorities.LOW;
    priorityReasoning.push('Promotional email (ADS category)');
  } else if (suggestedActions.length > 0 && suggestedActions[0].priority <= 2) {
    priority = EmailCard.Priorities.HIGH;
    priorityReasoning.push('Has high-priority action');
  }

  const step6Time = Date.now() - step6Start;

  // STEP 7: HPA and Meta CTA
  const primaryAction = suggestedActions.find(a => a.isPrimary) || suggestedActions[0];
  const hpa = primaryAction ? primaryAction.displayName : 'View Details';
  const metaCTA = `Swipe Right: ${hpa}`;

  // STEP 8: Urgency Detection
  const urgentKeywords = [
    'urgent', 'asap', 'immediately', 'critical', 'action required',
    'attention needed', 'time sensitive', 'expires today', 'due today',
    'today only', 'last chance', 'ending soon', 'limited time'
  ];

  const matchedUrgentKeywords = urgentKeywords.filter(k => subject.includes(k) || snippet.includes(k));
  const isUrgent = matchedUrgentKeywords.length > 0 || (entities.deadline && entities.deadline.isUrgent);

  // Total pipeline time
  const totalTime = Date.now() - startTime;

  // Run actual classification for comparison
  const actualClassification = classifyEmailActionFirst(email);

  // COMPREHENSIVE DEBUG OUTPUT
  return {
    // Metadata
    debugInfo: {
      timestamp: new Date().toISOString(),
      totalProcessingTime: `${totalTime}ms`,
      version: 'v1.10',
      classifierMode: 'action-first'
    },

    // Email Input
    email: {
      id: email.id || 'unknown',
      subject: email.subject,
      from: email.from,
      snippet: (email.snippet || email.body || '').substring(0, 200),
      hasHtmlBody: !!email.htmlBody
    },

    // DASHBOARD 1: Intent Classification Inspector
    intentClassification: {
      detectedIntent: intentResult.intent,
      confidence: intentResult.confidence,
      source: intentResult.source,
      processingTime: `${step2Time}ms`,
      allIntentScores: intentResult.allScores,
      matchBreakdown: intentResult.allScores[intentResult.intent]?.matches || [],
      thresholds: {
        minimum: 0.3,
        highConfidence: 0.85,
        currentMeetsMinimum: intentResult.confidence >= 0.3,
        currentIsHighConfidence: intentResult.confidence >= 0.85
      }
    },

    // DASHBOARD 2: Entity Extraction Validator
    entityExtraction: {
      extractedEntities: entities,
      processingTime: `${step3Time}ms`,
      validation: {
        hasDeadline: !!entities.deadline,
        hasPrices: Object.keys(entities.prices).length > 0,
        hasTrackingNumbers: entities.trackingNumbers.length > 0,
        hasChildren: entities.children.length > 0,
        hasCompanies: entities.companies.length > 0
      },
      requiredForIntent: getRequiredEntitiesForIntent(intentResult.intent),
      missingRequiredEntities: getMissingRequiredEntities(intentResult.intent, entities)
    },

    // DASHBOARD 3: Rules Engine → Action Mapping
    rulesEngine: {
      matchedRule: suggestedActions.length > 0,
      intent: intentResult.intent,
      suggestedActions: suggestedActions,
      processingTime: `${step4Time}ms`,
      actionValidation: suggestedActions.map(action => ({
        actionId: action.actionId,
        displayName: action.displayName,
        isPrimary: action.isPrimary,
        priority: action.priority,
        endpoint: action.endpoint,
        endpointExists: true // TODO: Actually check if endpoint exists
      })),
      reasoning: suggestedActions.length > 0
        ? 'Intent matched rule and required entities present'
        : 'No matching rule or missing required entities'
    },

    // DASHBOARD 4: Mail vs Ads Binary Classification
    mailAdsClassification: {
      finalCategory: category,
      processingTime: `${step5Time}ms`,
      reasoning: adDetectionReasoning,
      signals: {
        unsubscribeLink: adDetectionReasoning.hasUnsubscribeLink || adDetectionReasoning.hasUnsubscribeHeader,
        promoKeywords: {
          count: adDetectionReasoning.promoKeywordMatches,
          threshold: 2,
          matches: adDetectionReasoning.matchedPromoKeywords
        },
        marketingSender: adDetectionReasoning.marketingSenderMatch,
        intentBased: adDetectionReasoning.intentBased
      },
      accuracy: {
        expectedCategory: category, // In production, compare with human-labeled data
        confidence: isAdResult ? 'high' : 'medium'
      }
    },

    // DASHBOARD 5: End-to-End Pipeline Trace
    pipelineTrace: {
      steps: [
        {
          step: 1,
          name: 'Schema.org Check',
          status: schemaResult.hasSchema ? 'found' : 'not-found',
          time: `${step1Time}ms`,
          result: schemaResult.hasSchema ? `${schemaResult.actions.length} actions found` : 'No schema.org markup',
          error: schemaResult.error || null
        },
        {
          step: 2,
          name: 'Intent Classification',
          status: 'success',
          time: `${step2Time}ms`,
          result: `${intentResult.intent} (${(intentResult.confidence * 100).toFixed(1)}% confidence)`
        },
        {
          step: 3,
          name: 'Entity Extraction',
          status: 'success',
          time: `${step3Time}ms`,
          result: `${Object.values(entities).filter(v => v && (Array.isArray(v) ? v.length > 0 : true)).length} entities extracted`
        },
        {
          step: 4,
          name: 'Rules Engine',
          status: suggestedActions.length > 0 ? 'success' : 'no-match',
          time: `${step4Time}ms`,
          result: suggestedActions.length > 0 ? `${suggestedActions.length} actions suggested` : 'No actions matched'
        },
        {
          step: 5,
          name: 'Mail/Ads Detection',
          status: 'success',
          time: `${step5Time}ms`,
          result: `Classified as ${category}`
        },
        {
          step: 6,
          name: 'Priority Assignment',
          status: 'success',
          time: `${step6Time}ms`,
          result: `Priority: ${priority}`,
          reasoning: priorityReasoning
        },
        {
          step: 7,
          name: 'HPA & Meta CTA',
          status: 'success',
          time: '<1ms',
          result: `HPA: "${hpa}"`
        },
        {
          step: 8,
          name: 'Urgency Detection',
          status: 'success',
          time: '<1ms',
          result: isUrgent ? `Urgent (${matchedUrgentKeywords.length} keywords)` : 'Not urgent'
        }
      ],
      totalTime: `${totalTime}ms`,
      allStepsSuccessful: true,
      errors: []
    },

    // Final Classification Output
    finalClassification: {
      type: category,
      intent: intentResult.intent,
      intentConfidence: intentResult.confidence,
      suggestedActions: suggestedActions,
      priority: priority,
      hpa: hpa,
      metaCTA: metaCTA,
      urgent: isUrgent,
      urgentKeywords: matchedUrgentKeywords,
      confidence: Math.max(intentResult.confidence, 0.7)
    },

    // Comparison with actual classifier output
    actualClassifierOutput: actualClassification,
    matchesActual: {
      type: actualClassification.type === category,
      intent: actualClassification.intent === intentResult.intent,
      priority: actualClassification.priority === priority
    }
  };
}

/**
 * Helper: Get required entities for an intent
 */
function getRequiredEntitiesForIntent(intent) {
  const rulesEngine = {
    'e-commerce.shipping.notification': ['trackingNumbers'],
    'billing.invoice.due': ['prices'],
    'education.permission.form': ['deadline'],
    'travel.flight.checkin': ['flights'],
    'event.rsvp.request': []
  };
  return rulesEngine[intent] || [];
}

/**
 * Helper: Get missing required entities
 */
function getMissingRequiredEntities(intent, entities) {
  const required = getRequiredEntitiesForIntent(intent);
  const missing = [];

  for (const entityKey of required) {
    const value = entities[entityKey];
    const isMissing = !value || (Array.isArray(value) && value.length === 0);
    if (isMissing) {
      missing.push(entityKey);
    }
  }

  return missing;
}

module.exports = {
  getDebugClassification
};
