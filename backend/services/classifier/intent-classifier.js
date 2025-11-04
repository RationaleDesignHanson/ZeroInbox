/**
 * Intent Classifier
 * Classifies emails into specific intents using multi-signal analysis
 * Rule-based initially, with ML-ready architecture for future enhancement
 */

const { IntentTaxonomy, getAllIntentIds } = require('./shared/models/Intent');
const logger = require('./shared/config/logger');
const { PATTERN_WEIGHTS, CATEGORY_BOOSTS, CONFIDENCE } = require('./shared/config/classification-weights');
const schoolPlatformDetector = require('./shared/utils/school-platform-detector');

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
  const to = (email.to || '').toLowerCase();
  const snippet = (email.snippet || body).substring(0, 500).toLowerCase();
  const fullText = `${subject} ${snippet}`;

  // PRIORITY CHECK 0: Self-sent emails (note to self)
  // Detect if email was sent from user to themselves
  if (from && to && isSelfSent(from, to)) {
    logger.info('Self-sent email detected', {
      from: from.substring(0, 50),
      to: to.substring(0, 50),
      subject: subject.substring(0, 60)
    });
    return {
      intent: 'communication.personal.self-note',
      confidence: 0.95,
      source: 'self_sent_detection'
    };
  }

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
  applyEntityBasedBoosts(intentScores, { subject, body, snippet, from });

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
      // Traditional marketing indicators
      if (subject.includes('%') || subject.includes('off') || subject.includes('sale')) {
        boost += CATEGORY_BOOSTS.MARKETING.DISCOUNT_SYMBOL;
      }
      // Urgency
      if (subject.includes('today') || subject.includes('limited') || subject.includes('expires')) {
        boost += CATEGORY_BOOSTS.MARKETING.URGENCY_KEYWORD;
      }

      // Creative/Emotional marketing language (for vague/storytelling subject lines)
      const emotionalPatterns = [
        // Original patterns
        /\b(spill the tea|waiting for|feel at home|perfect for|ready for)\b/i,
        /\b(you('ll| will)? love|you('ll| will)? want|you need|got you)\b/i,
        /\b(invented|introducing|presenting|featuring|discover|explore)\b/i,
        /\b(original|authentic|handcrafted|curated|exclusive)\b/i,
        /\b(calling all|join us|just for you|designed for)\b/i,
        // ENHANCED: Aspirational/lifestyle patterns
        /\b(elevate|transform|upgrade|reimagine|reinvent)\b/i,
        /\b(deserve|treat yourself|indulge|pamper|reward)\b/i,
        /\b(experience|journey|adventure|escape|getaway)\b/i,
        /\b(dream|imagine|envision|picture|visualize)\b/i,
        // ENHANCED: Curiosity gap patterns
        /\b(secret|hidden|insider|revealed|unlock|unveil)\b/i,
        /\b(guess what|you won't believe|surprising|unexpected)\b/i,
        /\b(something (special|new|exciting|amazing))\b/i,
        /\b(the (secret|key|trick|hack) to)\b/i,
        // ENHANCED: Personalization patterns
        /\b(picked for you|selected for you|made for you|your (style|look|vibe))\b/i,
        /\b(we (thought|think) (of )?you|missing you|where('ve| have) you been)\b/i,
        /\b(come back|welcome back|we('ve| have) missed)\b/i,
        // ENHANCED: Question-based engagement
        /\?$/, // Ends with question mark
        /\b(what if|did you know|have you (seen|tried|heard))\b/i,
        /\b(looking for|searching for|need help|wondering)\b/i,
        // ENHANCED: FOMO (Fear of Missing Out)
        /\b(don't miss|last chance|final (day|hours|call)|ending soon)\b/i,
        /\b(almost gone|selling fast|running low|limited stock)\b/i,
        /\b(before (it's|they're) gone|while (supplies|stock) last)\b/i,
        // ENHANCED: Minimalist/vague creative subjects
        /^(just|simply|only|finally)\s+\w+$/i, // Single word after just/simply/only/finally
        /\b(a (little|few) things?|something for)\b/i,
        /\b(say hello to|meet your (new)?)\b/i,
        /\b(the (one|only) \w+ you need)\b/i
      ];

      let emotionalMatches = 0;
      for (const pattern of emotionalPatterns) {
        if (pattern.test(subject) || pattern.test(snippet)) {
          emotionalMatches++;
        }
      }

      if (emotionalMatches > 0) {
        boost += 30 * emotionalMatches; // Boost for emotional/creative language
        logger.info('Emotional marketing language detected', {
          matches: emotionalMatches,
          subject: subject.substring(0, 60)
        });
      }

      // Brand storytelling patterns
      const storytellingPatterns = [
        /\b(we('re| are) officially|certified|announcement|proud to)\b/i,
        /\b(our (story|greatest hits|mission|values))\b/i,
        /\b(meet the|behind the|introducing our)\b/i,
        /\b(milestone|achievement|celebrating)\b/i,
        /\b(rebels?|innovators?|creators?|dreamers?)\b/i,
        // ENHANCED: Heritage/legacy patterns
        /\b(since \d{4}|est\.? \d{4}|founded in|heritage|legacy)\b/i,
        /\b(tradition|timeless|classic|iconic|legendary)\b/i,
        /\b(craftsmanship|artisan|handmade|small batch)\b/i,
        // ENHANCED: Values-based marketing
        /\b(sustainability|sustainable|eco-friendly|organic|ethical)\b/i,
        /\b(community|give back|support|empower|impact)\b/i,
        /\b(female-founded|minority-owned|local|independent)\b/i
      ];

      for (const pattern of storytellingPatterns) {
        if (pattern.test(subject) || pattern.test(snippet)) {
          boost += 35; // Strong boost for brand storytelling
          logger.info('Brand storytelling detected', {
            subject: subject.substring(0, 60)
          });
          break; // Only apply once
        }
      }

      // Product-focused creative marketing (brand name + product description)
      // Pattern: "Best Value - [Product Name]", "The [Product] your [room] has been waiting for"
      if ((/\b(best value|new|latest|original)\s*[-:]?\s*[A-Z]/i.test(subject)) ||
          (/the\s+\w+\s+(your|you)\s+/i.test(subject))) {
        boost += 25;
        logger.info('Product-focused creative marketing detected', {
          subject: subject.substring(0, 60)
        });
      }

      // Winning/Formula/Collection patterns (common in apparel marketing)
      if (/\b(winning formula|signature|collection|essentials)\b/i.test(subject)) {
        boost += 20;
      }

      // ENHANCED: Emoji-heavy subjects (common in DTC brand marketing)
      const emojiCount = (subject.match(/[\u{1F300}-\u{1F9FF}]/gu) || []).length;
      if (emojiCount >= 2) {
        boost += 15 * Math.min(emojiCount, 4); // Cap at 4 emojis
        logger.info('Emoji-heavy marketing subject detected', {
          emojiCount,
          subject: subject.substring(0, 60)
        });
      }

      // ENHANCED: Seasonal/timely creative marketing
      const seasonalPatterns = [
        /\b(new season|season('s)? (best|favorites)|seasonal (picks|edit))\b/i,
        /\b((spring|summer|fall|winter) (is here|has arrived|vibes|mood))\b/i,
        /\b(perfect for (spring|summer|fall|winter))\b/i,
        /\b(cozy season|sweater weather|sunshine season)\b/i
      ];

      for (const pattern of seasonalPatterns) {
        if (pattern.test(subject) || pattern.test(snippet)) {
          boost += 25;
          logger.info('Seasonal creative marketing detected', {
            subject: subject.substring(0, 60)
          });
          break;
        }
      }

      // ENHANCED: Color/style descriptors (lifestyle brands)
      if (/\b(chic|elegant|luxe|modern|minimalist|bold|vibrant)\b/i.test(subject)) {
        boost += 15;
      }

      // ENHANCED: Lifestyle hooks
      const lifestylePatterns = [
        /\b(for (the|your) (weekend|summer|holiday|vacation))\b/i,
        /\b(outfit (of the day|inspo|inspiration))\b/i,
        /\b(get the look|shop the (look|style|collection))\b/i,
        /\b(your (next|new) (favorite|go-to))\b/i
      ];

      for (const pattern of lifestylePatterns) {
        if (pattern.test(subject) || pattern.test(snippet)) {
          boost += 20;
          break;
        }
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
      // ENHANCED: Financial/Business newsletters
      if (from.includes('morning brew') || from.includes('bloomberg') || from.includes('the hustle') ||
          from.includes('motley fool') || from.includes('finimize') || from.includes('cnbc') ||
          from.includes('financial times') || from.includes('wsj') || from.includes('wall street journal') ||
          from.includes('barron') || from.includes('marketwatch') || from.includes('seeking alpha') ||
          from.includes('yahoo finance') || from.includes('forbes')) {
        boost += 55;  // Boost for financial publishers
        logger.info('Financial newsletter publisher detected', { from: from.substring(0, 50) });
      }
      // ENHANCED: Substack platform (major newsletter platform)
      if (from.includes('substack.com')) {
        boost += 50;  // Strong boost for Substack newsletters
        logger.info('Substack newsletter detected', { from: from.substring(0, 50) });
      }
      // ENHANCED: Political/News newsletters
      if (from.includes('axios') || from.includes('punchbowl') || from.includes('politico') ||
          from.includes('the daily beast') || from.includes('vox') || from.includes('mother jones') ||
          from.includes('the guardian') || from.includes('washington post') || from.includes('nytimes') ||
          from.includes('new york times') || from.includes('npr')) {
        boost += 55;  // Boost for political/news publishers
        logger.info('Political/news newsletter detected', { from: from.substring(0, 50) });
      }
      // ENHANCED: Entertainment/Pop Culture newsletters
      if (from.includes('hollywood reporter') || from.includes('variety') || from.includes('vulture') ||
          from.includes('entertainment weekly') || from.includes('rolling stone') || from.includes('billboard') ||
          from.includes('pitchfork') || from.includes('deadline')) {
        boost += 52;  // Boost for entertainment publishers
        logger.info('Entertainment newsletter detected', { from: from.substring(0, 50) });
      }
      // ENHANCED: Food/Cooking newsletters
      if (from.includes('bon appetit') || from.includes('bonappetit') || from.includes('serious eats') ||
          from.includes('food52') || from.includes('epicurious') || from.includes('nyt cooking') ||
          from.includes('saveur') || from.includes('food network') || from.includes('tasty')) {
        boost += 50;  // Boost for food/cooking publishers
        logger.info('Food/cooking newsletter detected', { from: from.substring(0, 50) });
      }
      // ENHANCED: Design/Creative newsletters
      if (from.includes('dribbble') || from.includes('behance') || from.includes('designer news') ||
          from.includes('colossal') || from.includes('its nice that') || from.includes('creative review') ||
          from.includes('design milk') || from.includes('awwwards')) {
        boost += 50;  // Boost for design/creative publishers
        logger.info('Design/creative newsletter detected', { from: from.substring(0, 50) });
      }
      // ENHANCED: Science/Health newsletters
      if (from.includes('scientific american') || from.includes('nature') || from.includes('new scientist') ||
          from.includes('webmd') || from.includes('healthline') || from.includes('mayo clinic') ||
          from.includes('medscape') || from.includes('nejm')) {
        boost += 52;  // Boost for science/health publishers
        logger.info('Science/health newsletter detected', { from: from.substring(0, 50) });
      }
      // ENHANCED: Marketing/Business newsletters
      if (from.includes('hubspot') || from.includes('mailchimp') || from.includes('marketing brew') ||
          from.includes('adweek') || from.includes('moz') || from.includes('marketing land')) {
        boost += 50;  // Boost for marketing publishers
        logger.info('Marketing/business newsletter detected', { from: from.substring(0, 50) });
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
      // ENHANCED: Newsletter format patterns in subject
      const newsletterFormatPatterns = [
        /\b(your )?(daily|weekly|monthly|sunday|monday|tuesday|wednesday|thursday|friday|saturday)\s+(newsletter|digest|briefing|roundup|update|wrap-up)/i,
        /\b(today in|this week in|this month in)\s+\w+/i,
        /\b(good morning|good afternoon|good evening),?\s+/i,
        /\b(here's what you missed|top stories|must-reads?|recommended reading)\b/i,
        /\b\w+\s+(briefing|dispatch|bulletin|memo)\b/i
      ];

      for (const pattern of newsletterFormatPatterns) {
        if (pattern.test(subject) || pattern.test(snippet)) {
          boost += 40;
          logger.info('Newsletter format pattern detected', {
            subject: subject.substring(0, 60)
          });
          break; // Only apply once
        }
      }

      // ENHANCED: Content curation patterns
      const curationPatterns = [
        /\b(handpicked|hand-picked|carefully selected|curated for you)\b/i,
        /\b(what we're reading|recommended for you|you might like)\b/i,
        /\b(editor'?s? (picks?|choice|selection))\b/i,
        /\b(featured stories|spotlight)\b/i
      ];

      for (const pattern of curationPatterns) {
        if (pattern.test(subject) || pattern.test(snippet)) {
          boost += 35;
          logger.info('Content curation pattern detected', {
            subject: subject.substring(0, 60)
          });
          break; // Only apply once
        }
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
  const { mapSchemaOrgAction } = require('./shared/models/Intent');

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
function applyEntityBasedBoosts(intentScores, { subject, body, snippet, from }) {
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

  // ENHANCED: Detect "invoice due" pattern specifically (for billing)
  if (/invoice\s+(is\s+)?due|invoice.*due/i.test(text)) {
    if (intentScores['billing.invoice.due']) {
      intentScores['billing.invoice.due'] += 50; // Very strong boost
    }
    // Strongly penalize e-commerce.order.receipt for "invoice due"
    if (intentScores['e-commerce.order.receipt']) {
      intentScores['e-commerce.order.receipt'] -= 40;
    }
  }

  // ENHANCED: Detect "payment received" pattern specifically (for billing)
  if (/payment\s+(has\s+been\s+)?received|payment.*received/i.test(text)) {
    if (intentScores['billing.payment.received']) {
      intentScores['billing.payment.received'] += 50; // Very strong boost
    }
    // Penalize e-commerce.order.receipt for "payment received"
    if (intentScores['e-commerce.order.receipt']) {
      intentScores['e-commerce.order.receipt'] -= 40;
    }
  }

  // If we see "order #" pattern, boost e-commerce
  if (/order\s*#|order number/i.test(text)) {
    if (intentScores['e-commerce.order.confirmation'] || intentScores['e-commerce.order.receipt']) {
      const intent = intentScores['e-commerce.order.confirmation'] ? 'e-commerce.order.confirmation' : 'e-commerce.order.receipt';
      intentScores[intent] += 35;
    }
  }

  // HEALTHCARE appointment disambiguation: booking vs reminder
  if (/schedule your|book your|time to schedule|please schedule|schedule now|make an appointment/i.test(text)) {
    if (intentScores['healthcare.appointment.booking_request']) {
      intentScores['healthcare.appointment.booking_request'] += 60; // Very strong boost for scheduling language
    }
    if (intentScores['healthcare.appointment.reminder']) {
      intentScores['healthcare.appointment.reminder'] -= 50; // Strong penalty for reminder
    }
  }

  // HEALTHCARE test disambiguation
  if (/lab test|medical test|blood test|test scheduled|diagnostic test|lab.*scheduled/i.test(text)) {
    if (intentScores['healthcare.test.order']) {
      intentScores['healthcare.test.order'] += 60; // Very strong boost
    }
    if (intentScores['communication.personal']) {
      intentScores['communication.personal'] -= 50; // Strong penalty
    }
  }

  // DINING vs TRAVEL disambiguation
  // Check both text content AND sender domain for dining platforms
  const isDiningContext = /restaurant|table|party of|dinner|dining|menu|cuisine/i.test(text);
  const isDiningPlatform = /opentable|resy|yelp|grubhub|seamless|eat24/i.test(from + ' ' + subject + ' ' + body + ' ' + snippet);

  if (isDiningContext || isDiningPlatform) {
    if (intentScores['dining.reservation.confirmation']) {
      intentScores['dining.reservation.confirmation'] += 60; // Very strong boost
    }
    if (intentScores['travel.reservation.confirmation']) {
      intentScores['travel.reservation.confirmation'] -= 50; // Strong penalty
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

/**
 * Check if an email was sent from user to themselves (self-sent)
 * Detects both exact match and same domain
 * @param {string} from - Sender email address
 * @param {string} to - Recipient email address
 * @returns {boolean} True if email is self-sent
 */
function isSelfSent(from, to) {
  if (!from || !to) {
    return false;
  }

  // Extract email addresses from potential "Name <email>" format
  const extractEmail = (str) => {
    const match = str.match(/<([^>]+)>/);
    return match ? match[1].toLowerCase().trim() : str.toLowerCase().trim();
  };

  const fromEmail = extractEmail(from);
  const toEmail = extractEmail(to);

  // Exact match
  if (fromEmail === toEmail) {
    return true;
  }

  // Same domain match (e.g., user1@company.com to user2@company.com from same user)
  const fromDomain = fromEmail.split('@')[1];
  const toDomain = toEmail.split('@')[1];

  // Only consider same domain if it's the same local part (before @)
  // This prevents false positives like support@company.com → customer@company.com
  const fromLocal = fromEmail.split('@')[0];
  const toLocal = toEmail.split('@')[0];

  return fromDomain && toDomain && fromDomain === toDomain && fromLocal === toLocal;
}

module.exports = {
  classifyIntent,
  calculateIntentScore,
  extractIntentFromSchema,
  applyEntityBasedBoosts,
  isSelfSent
};

