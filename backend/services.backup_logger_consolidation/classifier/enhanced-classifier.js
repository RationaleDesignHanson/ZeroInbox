/**
 * Enhanced Email Classifier
 * Based on web prototype analysis - provides rich metadata extraction
 *
 * Key improvements over basic classifier:
 * - Entity extraction (children, companies, products, flights)
 * - Deadline/expiration detection
 * - Price and discount parsing
 * - Form field detection
 * - Multi-signal classification with confidence scores
 * - Context-aware action suggestions
 */

const EmailCard = require('./EmailCard');
const logger = require('./logger');
// Import entity extraction functions to avoid duplication
const {
  extractBasicEntities,
  extractOrderEntities,
  extractTrackingEntities,
  extractPaymentEntities,
  extractMeetingEntities
} = require('./entity-extractor');

/**
 * Enhanced email classification with rich metadata
 */
function classifyEmailEnhanced(email) {
  const subject = (email.subject || '').toLowerCase();
  const body = (email.body || '').toLowerCase();
  const from = (email.from || '').toLowerCase();
  const snippet = (email.snippet || body).substring(0, 500).toLowerCase();
  const fullText = `${subject} ${snippet}`;

  // Extract all entities and metadata
  const entities = extractEntities(email, fullText);
  const deadline = extractDeadline(fullText);
  // Use full body for price extraction (receipts have totals at the end)
  // Fall back to snippet if body is empty/minimal
  const textForPrices = (body && body.length > subject.length + 10) ? body : (snippet || fullText);
  const prices = extractPrices(textForPrices);
  const formData = detectFormFields(fullText);
  const calendarInvite = detectCalendarInvite(email, fullText);

  // Classify with multiple signals
  const classification = multiSignalClassification({
    email,
    subject,
    body,
    from,
    snippet,
    fullText,
    entities,
    deadline,
    prices,
    formData,
    calendarInvite
  });

  // Detect urgency
  const urgency = detectUrgency(subject, snippet, deadline);

  // Add rich metadata based on archetype
  const enrichedData = enrichArchetypeData(classification, {
    entities,
    deadline,
    prices,
    formData,
    email,
    urgency,
    calendarInvite
  });

  return {
    ...classification,
    ...enrichedData,
    urgent: urgency.isUrgent,
    confidence: calculateConfidence(classification, entities, deadline),
    suggestedActions: generateActions(classification.type, {
      deadline,
      formData,
      prices,
      entities
    })
  };
}

/**
 * Detect urgency in email
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
 * Multi-signal classification using binary mail/ads system (v2.0)
 */
function multiSignalClassification({ email, subject, body, from, snippet, fullText, entities, deadline, prices, formData, calendarInvite }) {
  // Binary classification scoring (v2.0)
  const scores = {
    mail: 0,   // All non-promotional emails (personal, work, transactional)
    ads: 0     // Marketing, promotions, shopping deals
  };

  // === MAIL SIGNALS (All non-promotional emails) ===

  // Family, Kids, Education
  if (from.includes('school') || from.includes('.edu')) scores.mail += 30;
  if (from.includes('teacher') || from.includes('principal')) scores.mail += 25;
  if (entities.children.length > 0) scores.mail += 40;
  if (subject.includes('field trip') || subject.includes('permission')) scores.mail += 35;
  if (subject.includes('parent') || subject.includes('conference')) scores.mail += 30;
  if (subject.includes('rsvp') && (subject.includes('party') || subject.includes('birthday'))) scores.mail += 25;
  if (formData.requiresSignature) scores.mail += 20;
  if (snippet.includes('your child') || snippet.includes('your student')) scores.mail += 25;

  // Canvas/school platform specific signals (assignment/grade tracking)
  if (from.includes('canvas') || from.includes('schoology') || from.includes('instructure')) scores.mail += 40;
  if (subject.includes('assignment') || subject.includes('homework')) scores.mail += 35;
  if (subject.includes('grade') || subject.includes('graded')) scores.mail += 30;
  if (snippet.includes('due date') || snippet.includes('points:')) scores.mail += 25;
  if (snippet.includes('current grade') || snippet.includes('grade:')) scores.mail += 30;

  // === WORK SIGNALS (Billing, Sales, Projects) ===

  // Sales signals
  if (entities.dealValue) scores.mail += 40;
  if (subject.includes('proposal') || subject.includes('contract')) scores.mail += 35;
  if (subject.includes('demo') || subject.includes('meeting request')) scores.mail += 30;
  if (snippet.includes('interested in') || snippet.includes('pricing')) scores.mail += 25;
  if (entities.companies.length > 0 && (subject.includes('follow up') || subject.includes('call'))) scores.mail += 30;
  if (snippet.includes('budget') || snippet.includes('purchase')) scores.mail += 20;

  // Billing signals - strong payment indicators
  if (subject.includes('payment received') || subject.includes('received your payment')) scores.mail += 70;
  if (subject.includes('payment') && snippet.includes('payment of $')) scores.mail += 60;
  if (snippet.includes('your payment of $')) scores.mail += 65;

  // Invoice/receipt signals
  if (subject.includes('invoice') && snippet.includes('paid')) scores.mail += 55;
  if (subject.includes('receipt') || subject.includes('order receipt')) scores.mail += 50;
  if (snippet.includes('invoice has been paid')) scores.mail += 50;

  // General financial signals
  if (subject.includes('payment processed')) scores.mail += 45;
  if (subject.includes('invoice') || subject.includes('receipt')) scores.mail += 40;
  if (subject.includes('approval') || subject.includes('sign off')) scores.mail += 35;
  if (subject.includes('review') && (subject.includes('budget') || subject.includes('expense'))) scores.mail += 40;
  if (subject.includes('board meeting') || subject.includes('executive')) scores.mail += 35;
  if (snippet.includes('needs your approval') || snippet.includes('requires approval')) scores.mail += 30;
  if (subject.includes('paid') || subject.includes('billing')) scores.mail += 35;
  if (snippet.includes('payment confirmation')) scores.mail += 35;
  if (from.includes('billing@') || from.includes('finance@') || from.includes('payments') || from.includes('payment')) scores.mail += 30;
  if (from.includes('stripe') || from.includes('paypal') || from.includes('square')) scores.mail += 25;
  if (from.includes('google') && (subject.includes('payment') || snippet.includes('payment'))) scores.mail += 30;
  if (subject.includes('statement') && (from.includes('bank') || from.includes('chase') || from.includes('wells fargo'))) scores.mail += 35;

  // Don't classify billing setup/configuration emails as work (no payment yet)
  if (subject.includes('setting up billing') || subject.includes('billing information added') ||
      snippet.includes('thanks for adding your billing') || snippet.includes('billing setup complete')) {
    scores.mail -= 50;
    scores.mail += 30; // These are service setup notifications
  }

  // Don't classify news/newsletter as work
  if (from.includes('newsletter') || from.includes('news')) scores.mail -= 20;

  // Project signals
  if (subject.includes('sprint') || subject.includes('standup')) scores.mail += 35;
  if (subject.includes('blocker') || subject.includes('blocked')) scores.mail += 40;
  if (subject.includes('deployment') || subject.includes('production')) scores.mail += 35;
  if (subject.includes('milestone') || subject.includes('timeline')) scores.mail += 30;
  if (snippet.includes('action items') || snippet.includes('next steps')) scores.mail += 25;
  // Calendar invites for meetings
  if (calendarInvite && calendarInvite.isCalendarInvite) scores.mail += 45;
  if (subject.includes('meeting') && (subject.includes('invite') || subject.includes('invitation'))) scores.mail += 30;

  // Fantasy sports management signals (lineup management, actionable decisions)
  if (from.includes('fantasy') || from.includes('espn') || from.includes('yahoo sports')) scores.mail += 40;
  if (subject.includes('matchup') || subject.includes('lineup')) scores.mail += 35;
  if (subject.includes('set your lineup') || snippet.includes('set your lineup')) scores.mail += 40;
  if (snippet.includes('injury alert') || snippet.includes('waiver wire')) scores.mail += 30;
  if (snippet.includes('trade offer') || snippet.includes('trade proposal')) scores.mail += 35;
  if (snippet.includes('actions needed') || snippet.includes('important actions')) scores.mail += 30;

  // === LIFESTYLE SIGNALS (Learning, Account Security, Health, Dining) ===

  // Learning signals
  if (subject.includes('webinar') || subject.includes('workshop')) scores.mail += 35;
  if (subject.includes('course') || subject.includes('training')) scores.mail += 30;
  if (subject.includes('certification') || subject.includes('conference')) scores.mail += 30;
  if (subject.includes('report') || subject.includes('whitepaper')) scores.mail += 25;
  if (subject.includes('newsletter') && !subject.includes('school')) scores.mail += 30;
  if (subject.includes('upgraded') || subject.includes('new features') || subject.includes('update')) scores.mail += 25;
  if (snippet.includes('newsletter') || snippet.includes('daily') || snippet.includes('weekly')) scores.mail += 25;
  if (snippet.includes('upgraded to') || snippet.includes('re-enabled') || snippet.includes('service update')) scores.mail += 25;
  if (from.includes('newsletter@') || from.includes('weekly@') || from.includes('daily@')) scores.mail += 30;
  if (from.includes('mit') || from.includes('stanford') || from.includes('harvard')) scores.mail += 25;
  if (from.includes('athletic') || from.includes('medium') || from.includes('substack')) scores.mail += 30;
  if (from.includes('netlify') || from.includes('vercel') || from.includes('heroku')) scores.mail += 20;

  // Account security signals
  if (subject.includes('security alert') || subject.includes('suspicious')) scores.mail += 40;
  if (subject.includes('verify') || subject.includes('confirm')) scores.mail += 30;
  if (subject.includes('password') || subject.includes('2fa')) scores.mail += 35;
  if (subject.includes('unusual activity') || subject.includes('locked')) scores.mail += 40;
  if (from.includes('security@') || from.includes('noreply@')) scores.mail += 25;
  if (subject.includes('third-party') && subject.includes('application')) scores.mail += 20;
  if (subject.includes('secret') || subject.includes('api key') || subject.includes('credential')) scores.mail += 35;
  if (from.includes('github') || from.includes('gitguardian')) scores.mail += 25;
  if (snippet.includes('publicly accessible') || snippet.includes('leaked')) scores.mail += 30;

  // === ADS SIGNALS (Marketing, Promotions, Shopping Deals) ===

  // Shopping/E-commerce signals
  if (subject.includes('sale') || subject.includes('discount')) scores.ads += 50;
  if (subject.includes('% off') || subject.includes('percent off')) scores.ads += 45;
  if (subject.includes('deal') || subject.includes('offer')) scores.ads += 40;
  if (subject.includes('save') && (subject.includes('$') || subject.includes('percent'))) scores.ads += 40;
  if (subject.includes('limited time') || subject.includes('today only')) scores.ads += 35;
  if (subject.includes('flash sale') || subject.includes('clearance')) scores.ads += 45;
  if (subject.includes('shop now') || subject.includes('buy now')) scores.ads += 40;
  if (from.includes('deals@') || from.includes('marketing@') || from.includes('promo')) scores.ads += 30;
  if (prices.discount > 0) scores.ads += 40;
  if (prices.discount >= 30) scores.ads += 20; // Bonus for high discounts
  if (entities.stores.length > 0) scores.ads += 35;
  if (entities.promoCodes.length > 0) scores.ads += 30;

  // Travel/Flight signals
  if (subject.includes('check-in') || subject.includes('check in')) scores.ads += 50;
  if (subject.includes('boarding') || subject.includes('flight')) scores.ads += 45;
  if (subject.includes('reservation') || subject.includes('booking')) scores.ads += 40;
  if (entities.flights.length > 0) scores.ads += 50;
  if (entities.hotels.length > 0) scores.ads += 40;
  if (from.includes('airline') || from.includes('airways') || from.includes('united') || from.includes('delta') || from.includes('southwest')) scores.ads += 40;

  // Marketing/Newsletter promotional signals
  if (snippet.includes('unsubscribe') && (subject.includes('sale') || subject.includes('deal'))) scores.ads += 25;
  if (snippet.includes('shop') || snippet.includes('browse')) scores.ads += 20;
  if (snippet.includes('exclusive offer') || snippet.includes('member exclusive')) scores.ads += 30;
  if (snippet.includes('free shipping') || snippet.includes('no minimum')) scores.ads += 25;
  if (deadline && deadline.isUrgent) scores.ads += 20;

  // Find highest scoring category
  let maxScore = 0;
  let winningType = EmailCard.ArchetypeTypes.MAIL; // Default to mail

  for (const [category, score] of Object.entries(scores)) {
    if (score > maxScore) {
      maxScore = score;
      winningType = EmailCard.ArchetypeTypes[category.toUpperCase()];
    }
  }

  // Determine priority and actions based on archetype and signals
  const priority = determinePriority(winningType, { deadline, subject, snippet, prices, calendarInvite });
  const { hpa, metaCTA } = determineActions(winningType, { deadline, formData, prices, subject, snippet, calendarInvite });

  return {
    type: winningType,
    priority,
    hpa,
    metaCTA,
    rawScores: scores,
    maxScore
  };
}

/**
 * Extract entities from email content
 * Uses shared entity extractor to avoid code duplication
 */
function extractEntities(email, fullText) {
  // Use shared entity extraction functions
  const basicEntities = extractBasicEntities(email, fullText);
  
  return {
    children: basicEntities.children || [],
    teachers: basicEntities.teachers || [],
    schools: basicEntities.schools || [],
    companies: basicEntities.companies || [],
    stores: basicEntities.stores || [],
    flights: basicEntities.flights || [],
    hotels: basicEntities.hotels || [],
    promoCodes: basicEntities.promoCodes || [],
    accounts: basicEntities.accounts || []
  };
}

// Entity extraction helpers
function extractChildren(text) {
  const childPatterns = [
    /\b([A-Z][a-z]+)\s+Chen\b/g,  // Sarah Chen's children pattern
    /your\s+child[,\s]+([A-Z][a-z]+)/gi,
    /\b([A-Z][a-z]+)'s\s+(grade|class|teacher)/gi
  ];

  const children = [];
  childPatterns.forEach(pattern => {
    const matches = text.matchAll(pattern);
    for (const match of matches) {
      if (match[1] && !children.includes(match[1])) {
        children.push(match[1]);
      }
    }
  });

  return children;
}

function extractTeachers(text) {
  const teacherPatterns = [
    /(Mrs?\.|Ms\.|Miss|Mr\.)\s+([A-Z][a-z]+)/g,
    /teacher\s+([A-Z][a-z]+\s+[A-Z][a-z]+)/gi
  ];

  const teachers = [];
  teacherPatterns.forEach(pattern => {
    const matches = text.matchAll(pattern);
    for (const match of matches) {
      const name = match[0].replace(/teacher\s+/gi, '').trim();
      if (!teachers.includes(name)) {
        teachers.push(name);
      }
    }
  });

  return teachers;
}

function extractSchools(text) {
  const schoolPatterns = [
    /([A-Z][a-z]+\s+(?:Elementary|Middle|High|Prep)\s+School)/g,
    /([A-Z][a-z]+\s+Academy)/g,
    /([A-Z][a-z]+\s+Preschool)/g
  ];

  const schools = [];
  schoolPatterns.forEach(pattern => {
    const matches = text.matchAll(pattern);
    for (const match of matches) {
      if (!schools.includes(match[1])) {
        schools.push(match[1]);
      }
    }
  });

  return schools;
}

function extractCompanies(text, email) {
  const companies = [];

  // Extract from formal company patterns in text
  const companyPatterns = [
    /\b([A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+){0,2})\s+(?:Inc|LLC|Corp|Corporation|Industries|Systems|Solutions|Technologies)\b/g
  ];

  companyPatterns.forEach(pattern => {
    const matches = text.matchAll(pattern);
    for (const match of matches) {
      if (!companies.includes(match[1])) {
        companies.push(match[1]);
      }
    }
  });

  // Extract company name from sender email address
  if (email && email.from) {
    const companyFromSender = extractCompanyFromSender(email.from);
    if (companyFromSender && !companies.includes(companyFromSender)) {
      companies.push(companyFromSender);
    }
  }

  return companies;
}

/**
 * Extract company name from sender email address or name
 */
function extractCompanyFromSender(from) {
  if (!from) return null;

  // Try to extract display name first (e.g., "GitHub <noreply@github.com>")
  const displayNameMatch = from.match(/^([^<]+)</);
  if (displayNameMatch) {
    const name = displayNameMatch[1].trim();
    // Remove common suffixes like "Team", "Support", etc.
    const cleanName = name.replace(/\s+(Team|Support|Inc|LLC|Notifications|Security|Admin)\.?$/i, '').trim();
    if (cleanName && cleanName.length > 2) {
      return cleanName;
    }
  }

  // Extract from email domain (e.g., "noreply@github.com" -> "GitHub")
  const emailMatch = from.match(/@([a-z0-9-]+)\./i);
  if (emailMatch) {
    const domain = emailMatch[1];

    // Skip generic domains
    const genericDomains = ['gmail', 'yahoo', 'outlook', 'hotmail', 'mail', 'email'];
    if (!genericDomains.includes(domain.toLowerCase())) {
      // Capitalize first letter
      return domain.charAt(0).toUpperCase() + domain.slice(1);
    }
  }

  return null;
}

function extractStores(text) {
  const knownStores = ['amazon', 'best buy', 'target', 'walmart', 'techmart', 'modernhome', 'fashionforward'];
  const stores = [];

  knownStores.forEach(store => {
    if (text.includes(store)) {
      stores.push(store.split(' ').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' '));
    }
  });

  return stores;
}

function extractFlights(text) {
  const flightPattern = /\b([A-Z]{2})\s*(\d{3,4})\b/g;
  const flights = [];
  const matches = text.matchAll(flightPattern);

  for (const match of matches) {
    flights.push({
      airline: match[1],
      number: match[2],
      full: `${match[1]} ${match[2]}`
    });
  }

  return flights;
}

function extractHotels(text) {
  const hotelPatterns = [
    /(Marriott|Hilton|Hyatt|Holiday Inn|Best Western)/gi
  ];

  const hotels = [];
  hotelPatterns.forEach(pattern => {
    const matches = text.matchAll(pattern);
    for (const match of matches) {
      if (!hotels.includes(match[1])) {
        hotels.push(match[1]);
      }
    }
  });

  return hotels;
}

function extractPromoCodes(text) {
  const promoPattern = /\b([A-Z0-9]{4,12})\b/g;
  const promoCodes = [];

  // Look for promo codes near keywords
  if (text.includes('promo') || text.includes('code') || text.includes('coupon')) {
    const matches = text.matchAll(promoPattern);
    for (const match of matches) {
      promoCodes.push(match[1]);
    }
  }

  return promoCodes.slice(0, 3); // Limit to first 3
}

function extractAccounts(text) {
  const accountTypes = [];

  if (text.includes('chase') || text.includes('wells fargo') || text.includes('bank of america')) {
    accountTypes.push('bank');
  }
  if (text.includes('lastpass') || text.includes('1password') || text.includes('password manager')) {
    accountTypes.push('password_manager');
  }
  if (text.includes('github') || text.includes('gitlab')) {
    accountTypes.push('developer');
  }

  return accountTypes;
}

/**
 * Extract deadline and expiration information
 */
function extractDeadline(text) {
  const deadlinePatterns = [
    { pattern: /due\s+today/i, isUrgent: true, text: 'today', unit: 'day', value: 0 },
    { pattern: /expires?\s+today/i, isUrgent: true, text: 'today', unit: 'day', value: 0 },
    { pattern: /today\s+only/i, isUrgent: true, text: 'today only', unit: 'day', value: 0 },
    { pattern: /last\s+chance/i, isUrgent: true, text: 'last chance', unit: 'unknown', value: 0 },
    { pattern: /ending\s+soon/i, isUrgent: true, text: 'ending soon', unit: 'unknown', value: 0 },

    // Relative time patterns
    { pattern: /expires?\s+in\s+(\d+)\s+(hour|day|week)s?/i, extract: true },
    { pattern: /ends?\s+in\s+(\d+)\s+(hour|day|week)s?/i, extract: true },
    { pattern: /(\d+)\s+(hour|day|week)s?\s+(?:left|remaining)/i, extract: true },
    { pattern: /due\s+(?:by\s+)?(\d{1,2})\s*(am|pm)/i, extract: true, unit: 'hour' },

    // Specific date patterns
    { pattern: /due\s+(?:by\s+)?(\w+\s+\d{1,2})/i, extract: true, unit: 'date' },
    { pattern: /expires?\s+(?:on\s+)?(\w+\s+\d{1,2})/i, extract: true, unit: 'date' },
    { pattern: /deadline:\s+(\w+\s+\d{1,2})/i, extract: true, unit: 'date' }
  ];

  for (const config of deadlinePatterns) {
    const match = text.match(config.pattern);
    if (match) {
      if (config.extract) {
        const value = parseInt(match[1]) || 0;
        const unit = config.unit || match[2] || 'unknown';
        const isUrgent = unit === 'hour' && value <= 4 || unit === 'day' && value <= 1;

        return {
          text: match[0],
          value,
          unit,
          isUrgent
        };
      } else {
        // Predefined urgent patterns
        return {
          text: config.text,
          value: config.value,
          unit: config.unit,
          isUrgent: config.isUrgent
        };
      }
    }
  }

  return null;
}

/**
 * Extract price information
 */
function extractPrices(text) {
  const pricePattern = /\$[\d,]+\.?\d{0,2}/g;
  const prices = [];
  const matches = text.matchAll(pricePattern);

  for (const match of matches) {
    const price = parseFloat(match[0].replace(/[$,]/g, ''));
    prices.push(price);
  }

  // Priority 1: Look for "Total:" with amount (receipts/invoices)
  const totalPatterns = [
    /total[:\s]+\$?([\d,]+\.?\d{0,2})/i,
    /grand total[:\s]+\$?([\d,]+\.?\d{0,2})/i,
    /amount[:\s]+\$?([\d,]+\.?\d{0,2})/i,
    /payment[:\s]+(?:of|amount)?[:\s]*\$?([\d,]+\.?\d{0,2})/i
  ];

  for (const pattern of totalPatterns) {
    const match = text.match(pattern);
    if (match) {
      const totalAmount = parseFloat(match[1].replace(/,/g, ''));
      return {
        original: totalAmount,
        sale: null,
        discount: 0,
        savings: 0
      };
    }
  }

  // Priority 2: Sale/discount scenario (2+ prices)
  if (prices.length >= 2) {
    // Check if this looks like a sale (has "sale", "discount", "save", etc.)
    const isSale = /\b(sale|discount|save|off|was|now)\b/i.test(text);

    if (isSale) {
      // Assume max is original, min is sale price
      const original = Math.max(...prices);
      const sale = Math.min(...prices);
      const discount = Math.round(((original - sale) / original) * 100);

      return {
        original,
        sale,
        discount,
        savings: original - sale
      };
    }

    // Multiple prices but not a sale - return largest (likely the total)
    return {
      original: Math.max(...prices),
      sale: null,
      discount: 0,
      savings: 0
    };
  }

  // Priority 3: Single price found
  return {
    original: prices[0] || null,
    sale: null,
    discount: 0,
    savings: 0
  };
}

/**
 * Detect form fields and signature requirements
 */
function detectFormFields(text) {
  // More precise signature detection - look for actual signature contexts
  const signaturePatterns = [
    /\bsign\s+(and\s+)?send\b/i,
    /\bsign\s+(the\s+)?form\b/i,
    /\bsign\s+(the\s+)?document\b/i,
    /\bsignature\s+required\b/i,
    /\brequires?\s+(your\s+)?signature\b/i,
    /\bpermission\s+form\b/i,
    /\bpermission\s+slip\b/i,
    /\bconsent\s+form\b/i,
    /\bplease\s+sign\b/i,
    /\bneed(s)?\s+(your\s+)?signature\b/i
  ];

  const requiresSignature = signaturePatterns.some(pattern => pattern.test(text));
  const requiresPayment = text.includes('pay') || text.includes('payment') || text.includes('$');
  const requiresRSVP = text.includes('rsvp') || text.includes('respond by');

  return {
    requiresSignature,
    requiresPayment,
    requiresRSVP,
    formFields: [] // Could extract specific fields in future
  };
}

/**
 * Detect calendar invites (Zoom, Google Meet, Teams)
 */
function detectCalendarInvite(email, text) {
  const from = (email.from || '').toLowerCase();
  const subject = (email.subject || '').toLowerCase();
  const body = (email.body || '').toLowerCase();

  // Meeting platform patterns
  const platforms = {
    zoom: {
      patterns: ['zoom.us', 'join zoom meeting', 'zoom meeting id', 'zoom.com'],
      urlPattern: /https?:\/\/[a-z0-9-]+\.zoom\.us\/j\/\d+/i,
      name: 'Zoom'
    },
    meet: {
      patterns: ['meet.google.com', 'google meet', 'meet.google'],
      urlPattern: /https?:\/\/meet\.google\.com\/[a-z0-9-]+/i,
      name: 'Google Meet'
    },
    teams: {
      patterns: ['teams.microsoft.com', 'microsoft teams', 'teams meeting', 'join microsoft teams'],
      urlPattern: /https?:\/\/teams\.microsoft\.com\/l\/meetup-join\/[^\s]+/i,
      name: 'Microsoft Teams'
    },
    webex: {
      patterns: ['webex.com', 'cisco webex', 'webex meeting'],
      urlPattern: /https?:\/\/[a-z0-9-]+\.webex\.com\/[^\s]+/i,
      name: 'Webex'
    }
  };

  // Calendar invite indicators
  const calendarIndicators = [
    'calendar invite',
    'meeting invitation',
    'event invitation',
    'has invited you',
    'vcalendar',
    'vevent',
    'ical',
    '.ics',
    'rsvp to this event',
    'accept this invitation'
  ];

  // Check if this is a calendar invite
  const hasCalendarIndicator = calendarIndicators.some(indicator =>
    text.includes(indicator) || body.includes(indicator)
  );

  // Detect meeting platform
  let platform = null;
  let meetingUrl = null;

  for (const [key, config] of Object.entries(platforms)) {
    // Check if platform is mentioned
    const hasPlatform = config.patterns.some(pattern =>
      text.includes(pattern) || body.includes(pattern)
    );

    if (hasPlatform) {
      platform = config.name;

      // Try to extract meeting URL
      const urlMatch = body.match(config.urlPattern) || text.match(config.urlPattern);
      if (urlMatch) {
        meetingUrl = urlMatch[0];
      }

      break;
    }
  }

  // If we found a meeting platform or calendar indicator
  if (platform || hasCalendarIndicator) {
    // Extract meeting time if present
    const timePatterns = [
      /(?:on|scheduled for)\s+(\w+,?\s+\w+\s+\d{1,2},?\s+\d{4})\s+(?:at\s+)?(\d{1,2}:\d{2}\s*(?:am|pm)?)/i,
      /(\w+,?\s+\d{1,2})\s+(?:at\s+)?(\d{1,2}:\d{2}\s*(?:am|pm)?)/i,
      /(\d{1,2}\/\d{1,2}\/\d{2,4})\s+(?:at\s+)?(\d{1,2}:\d{2}\s*(?:am|pm)?)/i
    ];

    let meetingTime = null;
    for (const pattern of timePatterns) {
      const match = text.match(pattern) || body.match(pattern);
      if (match) {
        meetingTime = match[0];
        break;
      }
    }

    // Extract meeting title (usually from subject, but clean it up)
    let meetingTitle = subject
      .replace(/^(fwd?:|re:)/gi, '')
      .replace(/invitation:/gi, '')
      .replace(/meeting:/gi, '')
      .trim();

    // If subject is generic, try to extract from body
    if (!meetingTitle || meetingTitle.length < 5) {
      const titleMatch = body.match(/(?:meeting|event):\s*([^\n]{10,80})/i);
      if (titleMatch) {
        meetingTitle = titleMatch[1].trim();
      }
    }

    return {
      isCalendarInvite: true,
      platform,
      meetingUrl,
      meetingTime,
      meetingTitle: meetingTitle || 'Meeting Invitation',
      hasAcceptDecline: body.includes('accept') && body.includes('decline'),
      // Extract organizer
      organizer: email.from ? extractCompanyFromSender(email.from) : null
    };
  }

  return {
    isCalendarInvite: false
  };
}

/**
 * Determine priority based on archetype and signals
 */
function determinePriority(type, { deadline, subject, snippet, prices, calendarInvite }) {
  if (deadline && deadline.isUrgent) return EmailCard.Priorities.CRITICAL;
  if (subject.includes('urgent') || subject.includes('asap')) return EmailCard.Priorities.CRITICAL;

  // Calendar invites with meeting URLs are high priority
  if (calendarInvite && calendarInvite.isCalendarInvite && calendarInvite.meetingUrl) {
    return EmailCard.Priorities.HIGH;
  }

  // Binary classification priority rules (MAIL vs ADS)
  if (type === EmailCard.ArchetypeTypes.MAIL) {
    // MAIL: Security alerts are critical
    if (subject.includes('security') || subject.includes('suspicious')) return EmailCard.Priorities.CRITICAL;
    // Calendar invites with meeting URLs are high priority
    if (calendarInvite && calendarInvite.isCalendarInvite && calendarInvite.meetingUrl) return EmailCard.Priorities.HIGH;
    // Other mail defaults to medium-high
    return EmailCard.Priorities.MEDIUM_HIGH;
  }

  if (type === EmailCard.ArchetypeTypes.ADS) {
    // ADS: High discounts or expiring deals are high priority
    if (prices.discount >= 40) return EmailCard.Priorities.HIGH;
    if (deadline && deadline.unit === 'hour') return EmailCard.Priorities.HIGH;
    // Other ads default to medium
    return EmailCard.Priorities.MEDIUM;
  }

  return EmailCard.Priorities.MEDIUM;
}

/**
 * Determine High-Priority Action and meta CTA
 */
function determineActions(type, { deadline, formData, prices, subject, snippet, calendarInvite }) {
  // Override with calendar-specific actions if this is a meeting invite
  if (calendarInvite && calendarInvite.isCalendarInvite) {
    if (calendarInvite.meetingUrl) {
      // Meeting with join URL
      return {
        hpa: 'Join Meeting',
        metaCTA: `Swipe Right: Join ${calendarInvite.platform || 'Meeting'}`
      };
    } else if (calendarInvite.hasAcceptDecline) {
      // Calendar invite with accept/decline options
      return {
        hpa: 'Accept Invite',
        metaCTA: 'Swipe Right: Accept | Swipe Left: Decline'
      };
    } else {
      // Generic meeting invitation
      return {
        hpa: 'View Invite',
        metaCTA: 'Swipe Right: View Details'
      };
    }
  }

  // Binary classification action mapping (MAIL vs ADS)
  const actions = {
    [EmailCard.ArchetypeTypes.MAIL]: {
      // MAIL: Combines personal + lifestyle + work logic
      hpa: subject.includes('security') || subject.includes('suspicious') || subject.includes('password') ? 'Verify Now' :
           subject.includes('secret') || subject.includes('api key') || subject.includes('leaked') ? 'Review Secrets' :
           subject.includes('assignment') || subject.includes('grade') || subject.includes('homework') ? 'View Details' :
           formData.requiresSignature ? 'Sign & Send' :
           formData.requiresRSVP ? 'RSVP' :
           formData.requiresPayment ? 'Pay Now' :
           subject.includes('receipt') || subject.includes('paid') || snippet.includes('payment received') ? 'View Receipt' :
           subject.includes('invoice') ? 'Download Invoice' :
           subject.includes('meeting') ? 'Join Meeting' :
           subject.includes('proposal') ? 'Send Proposal' :
           subject.includes('blocker') || subject.includes('blocked') ? 'Address Blockers' :
           subject.includes('upgrade') || snippet.includes('upgraded') ? 'View Details' :
           'Acknowledge',
      metaCTA: subject.includes('security') || subject.includes('password')
        ? 'Swipe Right: Secure Account'
        : subject.includes('assignment') || subject.includes('grade') || subject.includes('homework')
        ? 'Swipe Right: View Assignment'
        : formData.requiresSignature
        ? 'Swipe Right: Quick Sign & Send'
        : subject.includes('receipt') || subject.includes('paid') || snippet.includes('payment received')
        ? 'Swipe Right: View Receipt'
        : subject.includes('meeting')
        ? 'Swipe Right: Join Meeting'
        : subject.includes('upgrade') || snippet.includes('upgraded')
        ? 'Swipe Right: View Details'
        : 'Swipe Right: Respond'
    },
    [EmailCard.ArchetypeTypes.ADS]: {
      // ADS: Combines shop logic (shopping, deals, travel)
      hpa: subject.includes('check-in') || subject.includes('boarding') ? 'Check In Now' :
           prices.discount > 0 ? 'Claim Deal' : 'View Offer',
      metaCTA: subject.includes('check-in') || subject.includes('boarding')
        ? 'Swipe Right: Check In'
        : 'Swipe Right: Buy Now'
    }
  };

  return actions[type] || { hpa: 'Review', metaCTA: 'Swipe Right: Review' };
}

/**
 * Enrich archetype data with specific metadata
 */
function enrichArchetypeData(classification, { entities, deadline, prices, formData, email, urgency, calendarInvite }) {
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

  // Parent/School Mode detection (v2.0)
  const from = (email.from || '').toLowerCase();
  const subject = (email.subject || '').toLowerCase();
  const snippet = (email.snippet || '').toLowerCase();

  // Detect school emails
  const isSchoolEmail =
    from.includes('school') ||
    from.includes('.edu') ||
    from.includes('teacher') ||
    from.includes('principal') ||
    from.includes('canvas') ||
    from.includes('schoology') ||
    from.includes('instructure') ||
    from.includes('parentsquare') ||
    entities.teachers.length > 0 ||
    entities.schools.length > 0 ||
    entities.children.length > 0 ||
    subject.includes('parent') ||
    subject.includes('student') ||
    subject.includes('field trip') ||
    subject.includes('permission');

  if (isSchoolEmail) {
    enriched.isSchoolEmail = true;
    enriched.teacher = entities.teachers.length > 0 ? entities.teachers[0] : null;
    enriched.school = entities.schools.length > 0 ? entities.schools[0] : null;
  }

  // Detect VIP senders (teachers, coaches, principals)
  const isVIP =
    from.includes('teacher@') ||
    from.includes('principal@') ||
    from.includes('coach@') ||
    entities.teachers.length > 0 ||
    (from.includes('.edu') && entities.teachers.length > 0) ||
    (from.includes('school') && entities.teachers.length > 0);

  if (isVIP) {
    enriched.isVIP = true;
  }

  // Newsletter Mode detection (v2.0)
  const isNewsletter =
    from.includes('newsletter') ||
    from.includes('@substack.com') ||
    from.includes('@beehiiv.com') ||
    from.includes('@mail.beehiiv.com') ||
    from.includes('noreply') ||
    snippet.includes('unsubscribe') ||
    snippet.includes('view in browser') ||
    snippet.includes('view online') ||
    subject.includes('newsletter') ||
    subject.includes('issue') ||
    subject.includes('ep.') ||
    subject.includes('episode') ||
    subject.includes('digest') ||
    snippet.includes('sent weekly') ||
    snippet.includes('sent daily');

  if (isNewsletter) {
    enriched.isNewsletter = true;
    // Extract unsubscribe URL if available
    const unsubMatch = (email.body || '').match(/https?:\/\/[^\s]+unsubscribe[^\s]*/i);
    if (unsubMatch) {
      enriched.unsubscribeUrl = unsubMatch[0];
    }
  }

  // Shopping Mode detection (v2.0)
  const isShoppingEmail =
    subject.includes('order') ||
    subject.includes('shipped') ||
    subject.includes('tracking') ||
    subject.includes('delivery') ||
    subject.includes('receipt') ||
    subject.includes('invoice') ||
    subject.includes('cart') ||
    snippet.includes('order number') ||
    snippet.includes('tracking number') ||
    snippet.includes('shipped via') ||
    from.includes('orders@') ||
    from.includes('shipping@') ||
    from.includes('amazon') ||
    from.includes('shopify') ||
    from.includes('ebay') ||
    from.includes('etsy');

  if (isShoppingEmail) {
    enriched.isShoppingEmail = true;
    // Extract tracking number
    const trackingMatch = snippet.match(/tracking\s*(?:number|#)?:?\s*([A-Z0-9]{10,})/i);
    if (trackingMatch) {
      enriched.trackingNumber = trackingMatch[1];
    }
    // Extract order number
    const orderMatch = snippet.match(/order\s*(?:number|#)?:?\s*([A-Z0-9-]{5,})/i);
    if (orderMatch) {
      enriched.orderNumber = orderMatch[1];
    }
  }

  // Subscription Mode detection (v2.0)
  const isSubscription =
    subject.includes('subscription') ||
    subject.includes('renewal') ||
    subject.includes('auto-renewal') ||
    subject.includes('recurring') ||
    subject.includes('membership') ||
    subject.includes('trial') ||
    subject.includes('free trial') ||
    snippet.includes('subscription') ||
    snippet.includes('renew') ||
    snippet.includes('auto-renew') ||
    snippet.includes('/month') ||
    snippet.includes('/year') ||
    snippet.includes('cancel anytime') ||
    snippet.includes('manage subscription') ||
    from.includes('netflix') ||
    from.includes('spotify') ||
    from.includes('adobe') ||
    from.includes('microsoft') ||
    from.includes('google') && snippet.includes('subscription');

  if (isSubscription) {
    enriched.isSubscription = true;
    // Extract subscription amount
    const amountMatch = snippet.match(/\$(\d+\.?\d{0,2})\s*\/\s*(month|year|mo|yr)/i);
    if (amountMatch) {
      enriched.subscriptionAmount = parseFloat(amountMatch[1]);
      enriched.subscriptionFrequency = amountMatch[2].toLowerCase().startsWith('m') ? 'monthly' : 'annual';
    }
    // Extract cancellation URL
    const cancelMatch = (email.body || '').match(/https?:\/\/[^\s]+(?:cancel|subscription|account|manage)[^\s]*/i);
    if (cancelMatch) {
      enriched.cancellationUrl = cancelMatch[0];
    }
  }

  // Add calendar invite metadata
  if (calendarInvite && calendarInvite.isCalendarInvite) {
    enriched.calendarInvite = {
      platform: calendarInvite.platform,
      meetingUrl: calendarInvite.meetingUrl,
      meetingTime: calendarInvite.meetingTime,
      meetingTitle: calendarInvite.meetingTitle,
      organizer: calendarInvite.organizer,
      hasAcceptDecline: calendarInvite.hasAcceptDecline
    };
  }

  // Binary classification enrichment (MAIL vs ADS)
  switch (classification.type) {
    case EmailCard.ArchetypeTypes.MAIL:
      // MAIL: Combines personal + work + lifestyle enrichment
      // Family/kids/education entities
      if (entities.children.length > 0) {
        enriched.kid = {
          name: entities.children[0],
          initial: entities.children[0].charAt(0)
        };
      }
      if (formData.requiresSignature) {
        enriched.requiresSignature = true;
      }
      if (deadline) {
        enriched.deadline = deadline;
      }
      // Work entities (companies, billing)
      if (entities.companies.length > 0) {
        enriched.company = {
          name: entities.companies[0],
          initials: entities.companies[0].split(' ').map(w => w[0]).join('')
        };
      }
      // Extract payment amount from invoice/receipt emails
      if (prices.original) {
        const subject = (email.subject || '').toLowerCase();
        enriched.paymentAmount = prices.original;
        enriched.paymentDescription = subject.includes('invoice') ? 'Invoice Payment' :
                                     subject.includes('receipt') ? 'Payment Received' :
                                     'Payment';
      }
      // Account security entities
      if (entities.accounts.length > 0) {
        enriched.accountType = entities.accounts[0];
      }
      break;

    case EmailCard.ArchetypeTypes.ADS:
      // ADS: Shop enrichment (shopping, deals, travel)
      if (entities.stores.length > 0) {
        enriched.store = entities.stores[0];
      }
      if (prices.original) {
        enriched.originalPrice = prices.original;
        enriched.salePrice = prices.sale;
        enriched.discount = prices.discount;
      }
      if (deadline) {
        enriched.expiresIn = deadline.text;
        enriched.urgent = deadline.isUrgent;
      }
      if (entities.promoCodes.length > 0) {
        enriched.promoCode = entities.promoCodes[0];
      }
      // Travel data
      if (entities.flights.length > 0) {
        enriched.flight = entities.flights[0];
      }
      if (entities.hotels.length > 0) {
        enriched.hotel = entities.hotels[0];
      }
      break;
  }

  return enriched;
}

/**
 * Calculate confidence score
 */
function calculateConfidence(classification, entities, deadline) {
  let confidence = classification.maxScore / 100; // Normalize score to 0-1

  // Boost confidence if we found relevant entities for binary categories
  if (classification.type === EmailCard.ArchetypeTypes.MAIL) {
    // MAIL: boost for children, companies, or accounts
    if (entities.children.length > 0) confidence += 0.1;
    if (entities.companies.length > 0) confidence += 0.1;
    if (entities.accounts.length > 0) confidence += 0.1;
  }
  if (classification.type === EmailCard.ArchetypeTypes.ADS) {
    // ADS: boost for flights, stores, or promo codes
    if (entities.flights.length > 0) confidence += 0.15;
    if (entities.stores.length > 0) confidence += 0.1;
    if (entities.promoCodes.length > 0) confidence += 0.1;
  }
  if (deadline && deadline.isUrgent) {
    confidence += 0.05;
  }

  return Math.min(confidence, 1.0); // Cap at 1.0
}

/**
 * Generate suggested actions
 */
function generateActions(type, { deadline, formData, prices, entities }) {
  const actions = [];

  // Primary action based on binary categories
  if (type === EmailCard.ArchetypeTypes.MAIL) {
    // MAIL: prioritize signature, then default to reply
    if (formData.requiresSignature) {
      actions.push({ type: 'sign_document', label: 'Sign & Send', primary: true });
    } else {
      actions.push({ type: 'quick_reply', label: 'Quick Reply', primary: true });
    }
  } else if (type === EmailCard.ArchetypeTypes.ADS) {
    // ADS: prioritize deals and travel
    if (prices.discount > 0) {
      actions.push({ type: 'buy_now', label: 'Buy Now', primary: true });
    } else if (entities.flights && entities.flights.length > 0) {
      actions.push({ type: 'check_in', label: 'Check In', primary: true });
    } else {
      actions.push({ type: 'view_offer', label: 'View Offer', primary: true });
    }
  } else {
    actions.push({ type: 'quick_reply', label: 'Quick Reply', primary: true });
  }

  // Secondary actions
  actions.push({ type: 'save_later', label: 'Save for Later', primary: false });
  if (deadline) {
    actions.push({ type: 'add_calendar', label: 'Add to Calendar', primary: false });
  }

  return actions;
}

module.exports = {
  classifyEmailEnhanced,
  extractEntities,
  extractDeadline,
  extractPrices,
  detectFormFields
};
