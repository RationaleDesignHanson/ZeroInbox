/**
 * Action-First Classifier (v1.10 - Binary Classification)
 * Simplified classification pipeline: Email → Intent → Actions → Mail/Ads
 *
 * Flow:
 * 1. Parse email
 * 2. Detect if email is promotional (isAd)
 * 3. Check for schema.org markup (fast lane)
 * 4. If no schema → Run intent classifier
 * 5. Extract entities relevant to detected intent
 * 6. Run rules engine: Intent + Entities → Actions
 * 7. Assign category: MAIL (non-promotional) or ADS (promotional)
 * 8. Return enriched EmailCard with actions array
 */

const EmailCard = require('./EmailCard');
const logger = require('./logger');
// Real module imports for action-first classifier
const { classifyIntent } = require('./intent-classifier');
const { extractAllEntities } = require('./entity-extractor');

// Import action suggestion modules
const { suggestActions } = require('../actions/rules-engine');

// Stub functions for schema parsing (not available in classifier service)
const parseEmailSchema = () => null;
const extractIntentFromSchema = () => null;

/**
 * Detect if email is promotional/ad
 * Uses clear signals: unsubscribe links, promotional keywords, marketing patterns
 */
function isAd(email) {
  const subject = (email.subject || '').toLowerCase();
  const body = (email.body || '').toLowerCase();
  const from = (email.from || '').toLowerCase();
  const snippet = (email.snippet || body).substring(0, 500).toLowerCase();
  const htmlBody = email.htmlBody || '';

  // Signal 1: Unsubscribe link (most reliable indicator)
  if (email.headers && email.headers['list-unsubscribe']) {
    logger.info('AD detected: List-Unsubscribe header present');
    return true;
  }

  if (htmlBody.includes('unsubscribe') || body.includes('unsubscribe')) {
    logger.info('AD detected: Unsubscribe link in body');
    return true;
  }

  // Signal 2: Promotional keywords (strong indicators)
  const promoKeywords = [
    // Discounts & Sales
    '% off', 'percent off', 'sale', 'discount', 'deal', 'clearance',
    'limited time', 'expires soon', 'ending soon', 'last chance',
    'save now', 'buy now', 'shop now', 'get yours', 'shop the', 'shop our',

    // Marketing phrases
    'exclusive offer', 'special offer', 'new arrivals', 'just dropped',
    'flash sale', 'hot deals', 'today only', 'free shipping',
    'promo code', 'coupon code', 'redeem now',

    // Product/Brand announcements
    'new collection', 'latest collection', 'just launched', 'now available',
    'coming soon', 'pre-order', 'limited edition', 'exclusive access',
    'early access', 'first look', 'sneak peek',

    // Shopping triggers
    'add to cart', 'view collection', 'discover', 'explore our',
    'trending now', 'best sellers', 'top picks', 'handpicked',

    // Urgency/scarcity
    'while supplies last', 'limited stock', 'almost gone', 'selling fast',
    'hours left', 'ends tonight', 'final hours', 'don\'t miss',

    // Exclusivity
    'members only', 'vip', 'exclusive', 'subscriber exclusive',
    'for you', 'specially selected', 'insider access'
  ];

  let promoMatches = 0;
  for (const keyword of promoKeywords) {
    if (subject.includes(keyword) || snippet.includes(keyword)) {
      promoMatches++;
    }
  }

  if (promoMatches >= 2) {
    logger.info('AD detected: Multiple promotional keywords', { matches: promoMatches });
    return true;
  }

  // Single strong promotional keyword can also indicate ad
  const strongPromoKeywords = [
    'flash sale', 'today only', 'limited time offer', 'exclusive offer',
    'shop now', 'buy now', 'get yours today', 'don\'t miss out'
  ];

  for (const keyword of strongPromoKeywords) {
    if (subject.includes(keyword) || snippet.includes(keyword)) {
      logger.info('AD detected: Strong promotional keyword', { keyword });
      return true;
    }
  }

  // Signal 3: Marketing sender patterns (ONLY promo/deals/offers)
  // Note: newsletters are MAIL (valuable info), not ads
  const marketingSenders = [
    'marketing@', 'promo@', 'deals@', 'offers@'
  ];

  for (const pattern of marketingSenders) {
    if (from.includes(pattern)) {
      logger.info('AD detected: Marketing sender pattern', { pattern });
      return true;
    }
  }

  // Signal 4: Intent-based detection (e-commerce/marketing intents)
  const intent = email._classifiedIntent || '';
  if (intent.startsWith('marketing.') || intent.startsWith('e-commerce.promotion')) {
    logger.info('AD detected: Marketing/promotion intent', { intent });
    return true;
  }

  // Default: Not an ad
  return false;
}

/**
 * Main classification function - BINARY MAIL/ADS MODEL (v1.10)
 */
function classifyEmailActionFirst(email) {
  const subject = (email.subject || '').toLowerCase();
  const body = (email.body || '').toLowerCase();
  const from = (email.from || '').toLowerCase();
  const snippet = (email.snippet || body).substring(0, 500).toLowerCase();
  const fullText = `${subject} ${snippet}`;

  // For entity extraction, preserve original case
  const originalBody = email.body || email.snippet || '';
  const originalSubject = email.subject || '';
  const fullTextOriginal = `${originalSubject} ${originalBody.substring(0, 500)}`;

  // STEP 1: Check for schema.org markup (fast lane)
  let intentResult = null;
  let schemaEntities = {};

  if (email.htmlBody) {
    try {
      const schemaData = parseEmailSchema(email.htmlBody);
      if (schemaData && schemaData.hasSchema && schemaData.actions.length > 0) {
        // Use schema.org data
        intentResult = extractIntentFromSchema(schemaData.actions[0]);
        schemaEntities = schemaData.entities;
        logger.info('Schema.org fast lane detected', { 
          intent: intentResult?.intent,
          entityCount: Object.keys(schemaEntities).length,
          actionCount: schemaData.actions.length
        });
      }
    } catch (error) {
      logger.warn('Schema.org parsing failed', { 
        error: error.message,
        emailId: email.id || 'unknown'
      });
      // Continue with standard classification
    }
  }

  // STEP 2: If no schema, run intent classifier
  if (!intentResult) {
    intentResult = classifyIntent(email);
  }

  const { intent, confidence, source } = intentResult;

  // STEP 3: Extract entities relevant to detected intent (use original case)
  const entities = extractAllEntities(email, fullTextOriginal, intent);
  
  // Merge with schema entities if any
  Object.assign(entities, schemaEntities);

  // STEP 4: Run rules engine to get suggested actions
  const suggestedActions = suggestActions(intent, entities, {
    subject: email.subject,
    from: email.from
  });

  // STEP 5: Detect if email is promotional (MAIL vs ADS)
  // Store intent temporarily for isAd to use
  email._classifiedIntent = intent;
  const category = isAd(email) ? EmailCard.ArchetypeTypes.ADS : EmailCard.ArchetypeTypes.MAIL;

  // STEP 6: Determine priority and meta CTA
  const priority = determinePriority(category, intent, entities, suggestedActions);
  const { hpa, metaCTA } = determineHPAandCTA(suggestedActions, category);

  // STEP 7: Detect urgency
  const urgency = detectUrgency(subject, snippet, entities.deadline);

  // STEP 8: Enrich category data
  const enrichedData = enrichCategoryData(category, entities, email);

  // STEP 9: Log final classification for debugging
  logger.info('📧 Email classified', {
    subject: email.subject?.substring(0, 60),
    intent,
    category,
    primaryAction: suggestedActions?.find(a => a.isPrimary)?.actionId || 'none',
    confidence,
    source
  });

  // STEP 10: Return complete classification
  return {
    type: category,
    intent,
    intentConfidence: confidence,
    suggestedActions,
    priority,
    hpa,
    metaCTA,
    urgent: urgency.isUrgent,
    confidence: Math.max(confidence, 0.7), // Boost overall confidence
    ...enrichedData,
    _classificationSource: source,
    _intentScores: intentResult.allScores
  };
}

// Removed old 4-archetype classification functions (assignArchetypeFromActions, inferArchetypeFromIntent)
// v1.10+ uses simple binary Mail/Ads classification via isAd() function

/**
 * Determine priority based on category, intent, and urgency
 * Simplified for binary Mail/Ads classification
 */
function determinePriority(category, intent, entities, suggestedActions) {
  const deadline = entities.deadline;

  // Critical urgency indicators
  if (deadline && deadline.isUrgent) return EmailCard.Priorities.CRITICAL;
  if (intent === 'account.security.alert') return EmailCard.Priorities.CRITICAL;
  if (intent === 'account.secret.exposed') return EmailCard.Priorities.CRITICAL;
  if (intent === 'project.incident.alert') return EmailCard.Priorities.CRITICAL;

  // High priority intents
  const highPriorityIntents = [
    'billing.invoice.due',
    'education.permission.form',
    'travel.flight.check-in',
    'travel.itinerary.update',
    'account.verification.required'
  ];

  if (highPriorityIntents.includes(intent)) {
    return EmailCard.Priorities.HIGH;
  }

  // Ads are lower priority by default
  if (category === EmailCard.ArchetypeTypes.ADS) {
    return EmailCard.Priorities.LOW;
  }

  // Mail with actions gets higher priority
  if (suggestedActions.length > 0 && suggestedActions[0].priority <= 2) {
    return EmailCard.Priorities.HIGH;
  }

  return EmailCard.Priorities.MEDIUM;
}

/**
 * Determine HPA (Highest Priority Action) and meta CTA from suggested actions
 */
function determineHPAandCTA(suggestedActions, archetype) {
  if (!suggestedActions || suggestedActions.length === 0) {
    return {
      hpa: 'View Details',
      metaCTA: 'Swipe Right: View'
    };
  }

  const primaryAction = suggestedActions.find(a => a.isPrimary) || suggestedActions[0];
  
  const hpa = primaryAction.displayName;
  const metaCTA = `Swipe Right: ${hpa}`;

  return { hpa, metaCTA };
}

/**
 * Detect urgency
 */
function detectUrgency(subject, snippet, deadline) {
  const urgentKeywords = [
    'urgent', 'asap', 'immediately', 'critical', 'action required',
    'attention needed', 'time sensitive', 'expires today', 'due today',
    'today only', 'last chance', 'ending soon', 'limited time'
  ];

  const isUrgent = urgentKeywords.some(keyword =>
    subject.includes(keyword) || snippet.includes(keyword)
  ) || (deadline && deadline.isUrgent);

  return {
    isUrgent,
    keywords: urgentKeywords.filter(k => subject.includes(k) || snippet.includes(k))
  };
}

/**
 * Enrich category data with specific metadata
 * Simplified for binary Mail/Ads classification
 */
function enrichCategoryData(category, entities, email) {
  const enriched = {};

  // Add sender info for all emails
  if (email && email.from) {
    const companyName = extractCompanyFromSender(email.from);
    if (companyName) {
      enriched.sender = {
        name: companyName,
        initial: companyName.charAt(0).toUpperCase()
      };
    }
  }

  // For MAIL: Add entity-specific enrichment
  if (category === EmailCard.ArchetypeTypes.MAIL) {
    // Family/education
    if (entities.children && entities.children.length > 0) {
      enriched.kid = {
        name: entities.children[0],
        initial: entities.children[0].charAt(0)
      };
    }

    // Forms
    if (entities.formName) {
      enriched.requiresSignature = true;
    }

    // Payments/billing
    if (entities.paymentAmount) {
      enriched.paymentAmount = entities.paymentAmount;
      enriched.paymentDescription = 'Payment Received';
    } else if (entities.prices && entities.prices.original) {
      enriched.paymentAmount = entities.prices.original;
      enriched.paymentDescription = 'Invoice';
    }

    // Companies
    if (entities.companies && entities.companies.length > 0) {
      enriched.company = {
        name: entities.companies[0],
        initials: entities.companies[0].split(' ').map(w => w[0]).join('')
      };
    }

    // Calendar invites
    if (entities.meetingUrl) {
      enriched.calendarInvite = {
        meetingUrl: entities.meetingUrl,
        meetingTime: entities.eventTime,
        meetingTitle: entities.eventTitle,
        organizer: entities.organizer
      };
    }

    // Accounts
    if (entities.accounts && entities.accounts.length > 0) {
      enriched.accountType = entities.accounts[0];
    }

    // Deadlines
    if (entities.deadline) {
      enriched.deadline = entities.deadline;
    }
  }

  // For ADS: Add shopping/promotional enrichment
  if (category === EmailCard.ArchetypeTypes.ADS) {
    if (entities.stores && entities.stores.length > 0) {
      enriched.store = entities.stores[0];
    }
    if (entities.prices && entities.prices.original) {
      enriched.originalPrice = entities.prices.original;
      enriched.salePrice = entities.prices.sale;
      enriched.discount = entities.prices.discount;
    }
    if (entities.deadline) {
      enriched.expiresIn = entities.deadline.text;
      enriched.urgent = entities.deadline.isUrgent;
    }
    if (entities.promoCodes && entities.promoCodes.length > 0) {
      enriched.promoCode = entities.promoCodes[0];
    }
  }

  return enriched;
}

/**
 * Extract company name from sender
 */
function extractCompanyFromSender(from) {
  if (!from) return null;

  const displayNameMatch = from.match(/^([^<]+)</);
  if (displayNameMatch) {
    const name = displayNameMatch[1].trim();
    const cleanName = name.replace(/\s+(Team|Support|Inc|LLC|Notifications|Security|Admin)\.?$/i, '').trim();
    if (cleanName && cleanName.length > 2) {
      return cleanName;
    }
  }

  const emailMatch = from.match(/@([a-z0-9-]+)\./i);
  if (emailMatch) {
    const domain = emailMatch[1];
    const genericDomains = ['gmail', 'yahoo', 'outlook', 'hotmail', 'mail', 'email'];
    if (!genericDomains.includes(domain.toLowerCase())) {
      return domain.charAt(0).toUpperCase() + domain.slice(1);
    }
  }

  return null;
}

module.exports = {
  classifyEmailActionFirst,
  isAd,
  determinePriority,
  determineHPAandCTA,
  enrichCategoryData
};

