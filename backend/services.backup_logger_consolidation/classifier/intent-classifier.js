/**
 * Intent Classifier
 * Classifies emails into specific intents using multi-signal analysis
 * Rule-based initially, with ML-ready architecture for future enhancement
 */

const { IntentTaxonomy, getAllIntentIds } = require('../../shared/models/Intent');
const logger = require('../../shared/config/logger');
const { PATTERN_WEIGHTS, CATEGORY_BOOSTS, CONFIDENCE } = require('../../shared/config/classification-weights');
const schoolPlatformDetector = require('../../shared/utils/school-platform-detector');

/**
 * Classify email intent using pattern matching and keyword analysis
 * Returns intent ID and confidence score
 * @param {Object} email - Email object with subject, body, from fields
 * @returns {Object} Classification result with intent, confidence, source
 */
function classifyIntent(email) {
  // Validate input
  if (!email || typeof email !== 'object') {
    logger.error('Invalid email object provided to classifyIntent', {
      emailType: typeof email
    });
    return {
      intent: 'generic.transactional',
      confidence: 0.3,
      source: 'validation_error'
    };
  }

  if (!email.subject && !email.body) {
    logger.warn('Email has no subject or body, using generic intent', {
      from: email.from || 'unknown'
    });
    return {
      intent: 'generic.transactional',
      confidence: 0.4,
      source: 'insufficient_content'
    };
  }

  const subject = (email.subject || '').toLowerCase();
  const body = (email.body || '').toLowerCase();
  const from = (email.from || '').toLowerCase();
  const snippet = (email.snippet || body).substring(0, 500).toLowerCase();
  const fullText = `${subject} ${snippet}`;

  // PRIORITY CHECK 1: Thread replies (catches 35% of fallbacks)
  // Check for reply/forward patterns early to avoid false positives on other intents
  if (subject.startsWith('re:') || subject.startsWith('fwd:') || subject.startsWith('fw:') ||
      body.includes('---------- forwarded message') || body.includes('on ') && body.includes(' wrote:') ||
      body.includes('from:') && body.includes('sent:') && body.includes('subject:')) {

    // Still run classification but strongly boost thread.reply intent
    logger.info('Thread reply pattern detected in subject/body', {
      subject: subject.substring(0, 60),
      pattern: subject.startsWith('re:') ? 're:' : subject.startsWith('fwd:') ? 'fwd:' : 'body_pattern'
    });

    // Don't return early - let normal classification run with strong boost for thread.reply
    // This allows us to still detect more specific intents within thread replies
  }

  // Try each intent pattern
  const intentScores = {};

  for (const intentId of getAllIntentIds()) {
    const intent = IntentTaxonomy[intentId];
    let score = calculateIntentScore(intent, { subject, body, from, snippet, fullText });

    if (score > 0) {
      intentScores[intentId] = score;
    }
  }

  // Apply entity-based disambiguation boosts
  // This helps differentiate between similar intents (e.g., billing vs e-commerce)
  applyEntityBasedBoosts(intentScores, { subject, body, snippet });

  // Find highest scoring intent, preferring specific intents over generic ones
  let maxScore = 0;
  let detectedIntent = 'generic.transactional'; // Default fallback

  for (const [intentId, score] of Object.entries(intentScores)) {
    const isGeneric = intentId.startsWith('generic.');
    const currentIsGeneric = detectedIntent.startsWith('generic.');

    // Prefer this intent if:
    // 1. It has a higher score, OR
    // 2. It has the same score but is more specific (not generic)
    if (score > maxScore || (score === maxScore && !isGeneric && currentIsGeneric)) {
      maxScore = score;
      detectedIntent = intentId;
    }
  }

  // Normalize confidence score (0-1)
  const confidence = Math.min(maxScore / CONFIDENCE.MAX_SCORE, 1.0);

  // If confidence is too low, use generic intent
  if (confidence < CONFIDENCE.MIN_THRESHOLD) {
    detectedIntent = inferGenericIntent({ subject, body, from, snippet });
    logger.info('Low confidence, using generic intent', {
      originalIntent: detectedIntent,
      confidence,
      threshold: CONFIDENCE.MIN_THRESHOLD
    });
    return {
      intent: detectedIntent,
      confidence: 0.5,
      source: 'fallback'
    };
  }

  return {
    intent: detectedIntent,
    confidence,
    source: 'pattern_matching',
    allScores: intentScores
  };
}

/**
 * Calculate score for a specific intent based on triggers and patterns
 * Now includes negative pattern matching to reduce false positives
 */
function calculateIntentScore(intent, { subject, body, from, snippet, fullText }) {
  let score = 0;

  // Check trigger keywords
  if (intent.triggers && intent.triggers.length > 0) {
    for (const trigger of intent.triggers) {
      const triggerLower = trigger.toLowerCase();

      // Subject match (highest weight)
      if (subject.includes(triggerLower)) {
        score += PATTERN_WEIGHTS.SUBJECT_MATCH;
      }

      // Snippet match (medium weight)
      if (snippet.includes(triggerLower)) {
        score += PATTERN_WEIGHTS.SNIPPET_MATCH;
      }

      // Body match (lower weight, but still relevant)
      if (body.includes(triggerLower)) {
        score += PATTERN_WEIGHTS.BODY_MATCH;
      }
    }
  }

  // Apply negative patterns to penalize false matches
  if (intent.negativePatterns && intent.negativePatterns.length > 0) {
    for (const negPattern of intent.negativePatterns) {
      const negPatternLower = negPattern.toLowerCase();

      // Penalty for negative pattern match (strong penalty)
      if (subject.includes(negPatternLower)) {
        score -= PATTERN_WEIGHTS.SUBJECT_MATCH * 1.5; // Stronger penalty than boost
      }

      if (snippet.includes(negPatternLower)) {
        score -= PATTERN_WEIGHTS.SNIPPET_MATCH * 1.5;
      }

      if (body.includes(negPatternLower)) {
        score -= PATTERN_WEIGHTS.BODY_MATCH * 1.5;
      }
    }
  }

  // Category-specific boosting
  score += applyCategoryBoosts(intent, { subject, body, from, snippet });

  return score;
}

/**
 * Apply category-specific score boosts based on sender, domain, etc.
 */
function applyCategoryBoosts(intent, { subject, body, from, snippet }) {
  let boost = 0;

  // PRIORITY: Thread reply detection (catches 35% of fallbacks)
  if (intent.category === 'communication' && intent.subCategory === 'thread') {
    // Strong boost for thread reply patterns
    if (subject.startsWith('re:') || subject.startsWith('fwd:') || subject.startsWith('fw:')) {
      boost += 100; // Very strong boost to catch thread replies early
      logger.info('Thread reply boost applied', { intent: 'communication.thread.reply', boost: 100 });
    }
    if (body.includes('---------- forwarded message') ||
        (body.includes('from:') && body.includes('sent:') && body.includes('subject:'))) {
      boost += 90; // Strong boost for forwarded message body patterns
    }
    if (body.includes('on ') && body.includes(' wrote:')) {
      boost += 80; // Strong boost for reply quote patterns
    }
  }

  switch (intent.category) {
    case 'e-commerce':
      // E-commerce domains
      if (from.includes('amazon') || from.includes('shop') || from.includes('store')) {
        boost += CATEGORY_BOOSTS.E_COMMERCE.DOMAIN_MATCH;
      }
      // Order-related keywords
      if (subject.includes('order') || subject.includes('shipment')) {
        boost += CATEGORY_BOOSTS.E_COMMERCE.ORDER_KEYWORD;
      }
      // Tracking numbers
      if (/\b\d{10,}\b/.test(snippet) || /\b1z[a-z0-9]{16}\b/i.test(snippet)) {
        boost += CATEGORY_BOOSTS.E_COMMERCE.TRACKING_NUMBER;
      }
      break;

    case 'billing':
      // Payment/billing domains
      if (from.includes('billing') || from.includes('payment') || from.includes('invoice')) {
        boost += CATEGORY_BOOSTS.BILLING.DOMAIN_MATCH;
      }
      if (from.includes('stripe') || from.includes('paypal') || from.includes('square')) {
        boost += CATEGORY_BOOSTS.BILLING.PAYMENT_PLATFORM;
      }
      // Money amounts
      if (/\$[\d,]+\.?\d{0,2}/.test(subject) || /\$[\d,]+\.?\d{0,2}/.test(snippet)) {
        boost += CATEGORY_BOOSTS.BILLING.MONEY_AMOUNT;
      }
      break;

    case 'event':
      // Calendar/meeting platforms
      if (from.includes('calendar') || from.includes('zoom') || from.includes('meet') || from.includes('teams')) {
        boost += CATEGORY_BOOSTS.EVENT.CALENDAR_PLATFORM;
      }
      // Meeting URLs
      if (snippet.includes('zoom.us') || snippet.includes('meet.google') || snippet.includes('teams.microsoft')) {
        boost += CATEGORY_BOOSTS.EVENT.MEETING_URL;
      }
      // Date/time patterns
      if (/\d{1,2}:\d{2}\s*(am|pm)/i.test(snippet)) {
        boost += CATEGORY_BOOSTS.EVENT.DATETIME_PATTERN;
      }

      // Work meeting indicators (helps distinguish from personal events)
      if (/\b(q[1-4]|quarter|quarterly|planning|strategy|review|sync|standup|kickoff|retrospective|sprint|scrum)\b/i.test(snippet)) {
        boost += 40;  // Strong boost for work meeting keywords
        logger.info('Work meeting pattern detected', { snippet: snippet.substring(0, 100) });
      }

      // Personal/entertainment event indicators
      if (/\b(concert|festival|show|performance|theater|theatre|movie|party|celebration|gathering)\b/i.test(snippet)) {
        boost += 35;  // Boost for entertainment/personal event keywords
        logger.info('Personal event pattern detected', { snippet: snippet.substring(0, 100) });
      }
      break;

    case 'account':
      // Security/account domains
      if (from.includes('security') || from.includes('noreply') || from.includes('no-reply')) {
        boost += CATEGORY_BOOSTS.ACCOUNT.SECURITY_DOMAIN;
      }
      if (from.includes('github') || from.includes('google') || from.includes('microsoft')) {
        boost += CATEGORY_BOOSTS.ACCOUNT.TRUSTED_SENDER;
      }
      break;

    case 'education':
      // Use school platform detector for automated platform detection
      const platformDetection = schoolPlatformDetector.detectSchoolPlatform({ from, subject, body: snippet });
      if (platformDetection.detected) {
        // Strong boost for detected school platform (normalized confidence 0-1 → 30-60 points)
        const platformBoost = Math.floor(platformDetection.confidence * 60);
        boost += platformBoost;
        logger.info('School platform detected', {
          platform: platformDetection.platformName,
          category: platformDetection.category,
          confidence: platformDetection.confidence,
          boost: platformBoost
        });
      }

      // School domains
      if (from.includes('.edu') || from.includes('school') || from.includes('canvas') || from.includes('schoology')) {
        boost += CATEGORY_BOOSTS.EDUCATION.EDU_DOMAIN;
      }
      // Teacher patterns
      if (from.includes('teacher') || from.includes('principal')) {
        boost += CATEGORY_BOOSTS.EDUCATION.TEACHER_PATTERN;
      }
      // Check if from school domain
      if (schoolPlatformDetector.isSchoolDomain(from)) {
        boost += CATEGORY_BOOSTS.EDUCATION.EDU_DOMAIN;
      }
      // Check if from teacher email
      if (schoolPlatformDetector.isTeacherEmail(from)) {
        boost += CATEGORY_BOOSTS.EDUCATION.TEACHER_PATTERN;
      }
      break;

    case 'youth':
      // Use school platform detector for youth sports platforms
      const sportsDetection = schoolPlatformDetector.detectSchoolPlatform({ from, subject, body: snippet });
      if (sportsDetection.detected && sportsDetection.category === 'sports') {
        // Strong boost for detected sports platform (normalized confidence 0-1 → 30-60 points)
        const sportsBoost = Math.floor(sportsDetection.confidence * 60);
        boost += sportsBoost;
        logger.info('Youth sports platform detected', {
          platform: sportsDetection.platformName,
          category: sportsDetection.category,
          confidence: sportsDetection.confidence,
          boost: sportsBoost
        });
      }
      // Youth sports keywords
      if (from.includes('sportsengine') || from.includes('teamsnap') || from.includes('leagueapps')) {
        boost += 40;
      }
      // Recreation department patterns
      if (from.includes('recreation') || from.includes('parks') || from.includes('communitypass')) {
        boost += 35;
      }
      break;

    case 'travel':
      // Airlines and travel companies
      if (from.includes('united') || from.includes('delta') || from.includes('marriott') || 
          from.includes('hilton') || from.includes('airline') || from.includes('flight')) {
        boost += CATEGORY_BOOSTS.TRAVEL.AIRLINE_DOMAIN;
      }
      // Confirmation codes
      if (/\b[A-Z0-9]{6}\b/.test(snippet)) {
        boost += CATEGORY_BOOSTS.TRAVEL.CONFIRMATION_CODE;
      }
      break;

    case 'feedback':
      // Review requests
      if (subject.includes('review') || subject.includes('feedback') || subject.includes('rating')) {
        boost += CATEGORY_BOOSTS.FEEDBACK.REVIEW_KEYWORD;
      }
      break;

    case 'marketing':
      // Marketing indicators
      if (subject.includes('%') || subject.includes('off') || subject.includes('sale')) {
        boost += CATEGORY_BOOSTS.MARKETING.DISCOUNT_SYMBOL;
      }
      // Urgency
      if (subject.includes('today') || subject.includes('limited') || subject.includes('expires')) {
        boost += CATEGORY_BOOSTS.MARKETING.URGENCY_KEYWORD;
      }
      break;

    case 'support':
      // Support domains
      if (from.includes('support') || from.includes('help') || from.includes('service')) {
        boost += CATEGORY_BOOSTS.SUPPORT.SUPPORT_DOMAIN;
      }
      // Ticket numbers
      if (/\b(case|ticket)[\s#:]*\d+/i.test(snippet)) {
        boost += CATEGORY_BOOSTS.SUPPORT.TICKET_NUMBER;
      }
      break;

    case 'shopping':
      // Future date patterns (e.g., "launching Oct 31", "available October 31")
      if (/\b(launching|available|releasing|dropping|goes on sale|releases on)\s+(on\s+)?([a-z]+\s+\d{1,2})/i.test(snippet)) {
        boost += CATEGORY_BOOSTS.SHOPPING.FUTURE_DATE;
      }
      // Time specifications (e.g., "5pm UK time", "17:00")
      if (/\d{1,2}(:\d{2})?\s*(am|pm|UK|EST|PST|GMT)/i.test(snippet)) {
        boost += CATEGORY_BOOSTS.SHOPPING.TIME_SPEC;
      }
      // Limited edition keywords
      if (subject.includes('limited') || subject.includes('exclusive') ||
          snippet.includes('limited edition') || snippet.includes('one week only')) {
        boost += CATEGORY_BOOSTS.SHOPPING.LIMITED_EDITION;
      }
      // Product URL patterns
      if (/https?:\/\/[^\s]+\/(releases|products|collections|shop)/i.test(snippet)) {
        boost += CATEGORY_BOOSTS.SHOPPING.PRODUCT_URL;
      }
      // Countdown or pre-sale language
      if (subject.includes('coming soon') || subject.includes('pre-sale') ||
          snippet.includes('countdown') || snippet.includes('available for')) {
        boost += CATEGORY_BOOSTS.SHOPPING.COUNTDOWN;
      }
      break;

    case 'project':
      // Project management platforms
      if (from.includes('jira') || from.includes('asana') || from.includes('trello') ||
          from.includes('github') || from.includes('gitlab')) {
        boost += CATEGORY_BOOSTS.PROJECT.PM_PLATFORM;
      }
      // Fantasy sports (project coordinator archetype)
      if (from.includes('fantasy') || from.includes('espn') || from.includes('yahoo sports')) {
        boost += CATEGORY_BOOSTS.PROJECT.FANTASY_SPORTS;
      }
      break;

    case 'healthcare':
      // Healthcare domains
      if (from.includes('health') || from.includes('hospital') || from.includes('clinic') ||
          from.includes('medical') || from.includes('care.org') || from.includes('stanford')) {
        boost += CATEGORY_BOOSTS.HEALTHCARE.HEALTHCARE_DOMAIN;
      }
      // Doctor patterns
      if (snippet.includes('dr.') || snippet.includes('doctor') || snippet.includes('physician')) {
        boost += CATEGORY_BOOSTS.HEALTHCARE.DOCTOR_PATTERN;
      }
      // Pharmacy
      if (from.includes('cvs') || from.includes('walgreens') || from.includes('pharmacy') ||
          from.includes('rx')) {
        boost += CATEGORY_BOOSTS.HEALTHCARE.PHARMACY_DOMAIN;
      }
      break;

    case 'dining':
      // Restaurant platforms
      if (from.includes('opentable') || from.includes('resy')) {
        boost += CATEGORY_BOOSTS.DINING.RESTAURANT_PLATFORM;
      }
      // Party size pattern
      if (/party of \d+/i.test(snippet)) {
        boost += CATEGORY_BOOSTS.DINING.PARTY_SIZE;
      }
      // Table keywords
      if (snippet.includes('your table') || snippet.includes('reservation at')) {
        boost += CATEGORY_BOOSTS.DINING.TABLE_KEYWORD;
      }
      break;

    case 'delivery':
      // Delivery platforms
      if (from.includes('doordash') || from.includes('ubereats') || from.includes('uber eats') ||
          from.includes('instacart') || from.includes('grubhub')) {
        boost += CATEGORY_BOOSTS.DELIVERY.DELIVERY_PLATFORM;
      }
      // Driver keywords
      if (snippet.includes('dasher') || snippet.includes('courier') || snippet.includes('driver is')) {
        boost += CATEGORY_BOOSTS.DELIVERY.DRIVER_KEYWORD;
      }
      // ETA patterns
      if (/\d+\s+minutes away/i.test(snippet) || snippet.includes('arriving soon')) {
        boost += CATEGORY_BOOSTS.DELIVERY.ETA_PATTERN;
      }
      break;

    case 'civic':
      // Government domains
      if (from.includes('.gov') || from.includes('dmv') || from.includes('court') ||
          from.includes('registrar') || from.includes('elections')) {
        boost += CATEGORY_BOOSTS.CIVIC.GOVERNMENT_DOMAIN;
      }
      // Civic keywords
      if (snippet.includes('jury') || snippet.includes('voter') || snippet.includes('summons')) {
        boost += CATEGORY_BOOSTS.CIVIC.CIVIC_KEYWORD;
      }
      break;

    case 'content':
      // Content/newsletter category - detect known publishers
      // Sports newsletters
      if (from.includes('athletic') || from.includes('espn') || from.includes('bleacher') ||
          from.includes('sports illustrated') || subject.includes('breaking news') && (snippet.includes('game') || snippet.includes('season'))) {
        boost += 60;  // Strong boost for sports publishers
        logger.info('Sports newsletter publisher detected', { from: from.substring(0, 50) });
      }
      // Tech/business newsletters
      if (from.includes('techcrunch') || from.includes('verge') || from.includes('hacker news') ||
          from.includes('wired') || from.includes('ars technica') || from.includes('the information')) {
        boost += 55;  // Boost for tech publishers
        logger.info('Tech newsletter publisher detected', { from: from.substring(0, 50) });
      }
      // LinkedIn (professional/career newsletters)
      if (from.includes('linkedin') && (subject.includes('news') || snippet.includes('posted') || snippet.includes('shared'))) {
        boost += 50;  // LinkedIn news digest
        logger.info('LinkedIn news digest detected', { subject: subject.substring(0, 50) });
      }
      // Lifestyle/tips newsletters
      if (from.includes('living simply') || from.includes('lifehacker') || from.includes('apartment therapy') ||
          from.includes('wirecutter') || from.includes('cup of jo')) {
        boost += 50;  // Lifestyle publisher boost
        logger.info('Lifestyle newsletter publisher detected', { from: from.substring(0, 50) });
      }
      // History/culture newsletters
      if (from.includes('history facts') || from.includes('smithsonian') || from.includes('atlas obscura')) {
        boost += 50;  // Culture/history publisher boost
        logger.info('History/culture newsletter detected', { from: from.substring(0, 50) });
      }
      // General newsletter indicators
      if (subject.includes('newsletter') || subject.includes('digest') ||
          subject.includes('weekly roundup') || subject.includes('curated') ||
          subject.includes('briefing') || subject.includes('this week')) {
        boost += 45;  // Boost for newsletter keywords in subject
      }
      // Newsletter sender patterns
      if (from.includes('newsletter') || from.includes('news@') ||
          from.includes('digest@') || from.includes('hello@') || from.includes('hi@')) {
        boost += 35;  // Boost for newsletter-style sender
      }
      // Newsletter structural indicators
      if (/issue\s*#?\d+|edition\s*#?\d+|vol\.\s*\d+/i.test(snippet)) {
        boost += 40;  // Boost for issue/edition numbering
        logger.info('Newsletter issue number detected', { snippet: snippet.substring(0, 100) });
      }
      break;

    case 'career':
      // Career/recruiting patterns
      if (from.includes('recruiter') || from.includes('talent') || from.includes('hiring') ||
          from.includes('careers') || from.includes('jobs@')) {
        boost += CATEGORY_BOOSTS.CAREER?.RECRUITER_DOMAIN || 40;
      }
      // Company career pages
      if (from.includes('@') && (subject.includes('interview') || subject.includes('application') ||
          subject.includes('offer') || subject.includes('position'))) {
        boost += CATEGORY_BOOSTS.CAREER?.CAREER_KEYWORD || 35;
      }
      // Recruiting platforms
      if (from.includes('greenhouse') || from.includes('lever') || from.includes('workday') ||
          from.includes('linkedin') || from.includes('indeed') || from.includes('glassdoor')) {
        boost += CATEGORY_BOOSTS.CAREER?.RECRUITING_PLATFORM || 45;
      }
      break;

    case 'generic':
      // Generic fallback - minimal boost
      if (subject.includes('newsletter') || subject.includes('digest')) {
        boost += 30;  // Lower boost than specific content category
      }
      break;
  }

  return boost;
}

/**
 * Infer generic intent type when specific intent can't be determined
 */
function inferGenericIntent({ subject, body, from, snippet }) {
  const text = `${subject} ${snippet}`.toLowerCase();

  // Newsletter indicators - expanded detection
  if (subject.includes('newsletter') || subject.includes('digest') ||
      subject.includes('weekly') || subject.includes('daily') || subject.includes('monthly') ||
      subject.includes('roundup') || subject.includes('briefing') || subject.includes('curated') ||
      subject.includes('this week') || subject.includes('wrap-up') || subject.includes('recap') ||
      from.includes('newsletter') || from.includes('news@') || from.includes('digest@') ||
      /issue\s*#?\d+|edition\s*#?\d+|vol\.\s*\d+/i.test(text)) {
    logger.info('Generic fallback: detected newsletter', {
      subject: subject.substring(0, 80),
      from: from.substring(0, 50)
    });
    return 'generic.newsletter';
  }

  // Default to transactional
  return 'generic.transactional';
}

/**
 * Extract intent from schema.org markup (if present)
 * This bypasses pattern matching for structured emails
 */
function extractIntentFromSchema(schemaAction) {
  const { mapSchemaOrgAction } = require('../../shared/models/Intent');

  if (schemaAction && schemaAction['@type']) {
    const intentId = mapSchemaOrgAction(schemaAction['@type']);
    if (intentId) {
      return {
        intent: intentId,
        confidence: 1.0, // Schema.org is definitive
        source: 'schema.org',
        schemaAction
      };
    }
  }

  return null;
}

/**
 * Apply entity-based disambiguation boosts to intent scores
 * This helps differentiate between similar intents based on presence of specific entities
 * Following the framework's recommendation for entity-aware classification
 */
function applyEntityBasedBoosts(intentScores, { subject, body, snippet }) {
  const text = `${subject} ${snippet}`.toLowerCase();

  // BILLING vs E-COMMERCE disambiguation
  // If we see "invoice #" or "INV-" pattern, strongly boost billing.invoice.due
  if (/invoice\s*#|inv-\d+/i.test(text)) {
    if (intentScores['billing.invoice.due']) {
      intentScores['billing.invoice.due'] += 40; // Strong boost
    }
    // Penalize e-commerce receipt if it's clearly an invoice
    if (intentScores['e-commerce.order.receipt'] && /amount due|pay by|due date/i.test(text)) {
      intentScores['e-commerce.order.receipt'] -= 30;
    }
  }

  // If we see "order #" pattern, boost e-commerce
  if (/order\s*#|order number/i.test(text)) {
    if (intentScores['e-commerce.order.confirmation'] || intentScores['e-commerce.order.receipt']) {
      const intent = intentScores['e-commerce.order.confirmation'] ? 'e-commerce.order.confirmation' : 'e-commerce.order.receipt';
      intentScores[intent] += 35;
    }
  }

  // MARKETING disambiguation - if we see discount percentage patterns
  if (/\d+%\s*off|\d+\s*percent off/i.test(text)) {
    if (intentScores['marketing.promotion.discount']) {
      intentScores['marketing.promotion.discount'] += 30;
    }
  }

  // Promo code presence boosts marketing
  if (/promo code|coupon code|use code/i.test(text)) {
    if (intentScores['marketing.promotion.discount']) {
      intentScores['marketing.promotion.discount'] += 25;
    }
  }

  // Tracking number pattern boosts shipping
  if (/\b1z[a-z0-9]{16}\b|\btracking.*number/i.test(text)) {
    if (intentScores['e-commerce.shipping.notification']) {
      intentScores['e-commerce.shipping.notification'] += 35;
    }
  }

  // Sender-based boosts
  // Billing senders
  if (/billing@|invoices@|finance@|payments@/i.test(subject)) {
    if (intentScores['billing.invoice.due']) {
      intentScores['billing.invoice.due'] += 25;
    }
  }

  // Marketing senders
  if (/marketing@|newsletter@|deals@|offers@/i.test(subject)) {
    for (const intentId in intentScores) {
      if (intentId.startsWith('marketing.')) {
        intentScores[intentId] += 20;
      }
    }
  }

  return intentScores;
}

module.exports = {
  classifyIntent,
  calculateIntentScore,
  extractIntentFromSchema,
  applyEntityBasedBoosts
};

