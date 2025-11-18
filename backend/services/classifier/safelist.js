/**
 * Safelist Protection Module
 *
 * CRITICAL SAFETY: This module prevents the unsubscribe agent from automatically
 * unsubscribing from emails that users MUST receive (banking, medical, security, etc.)
 *
 * DO NOT modify this module without careful review of safety implications.
 */

// Domains that should NEVER be automatically unsubscribed
// These represent critical services that users rely on
const CRITICAL_DOMAINS = [
  // Banking & Financial
  'chase.com',
  'wellsfargo.com',
  'bankofamerica.com',
  'citibank.com',
  'capitalone.com',
  'discover.com',
  'americanexpress.com',
  'paypal.com',
  'stripe.com',
  'square.com',
  'venmo.com',
  'zelle.com',

  // Investment & Trading
  'fidelity.com',
  'schwab.com',
  'vanguard.com',
  'robinhood.com',
  'etrade.com',
  'tdameritrade.com',

  // Medical & Healthcare
  'kaiserpermanente.org',
  'sutterhealth.org',
  'memorialmedical.org',
  'mayoclinic.org',
  'clevelandclinic.org',
  'johnshopkins.edu',
  'stanfordhealthcare.org',
  'ucsfhealth.org',
  'cvs.com',  // CVS Health/pharmacy
  'walgreens.com',
  'optum.com',
  'unitedhealthcare.com',

  // Utilities
  'pge.com',  // Pacific Gas & Electric
  'sce.com',  // Southern California Edison
  'sdge.com',  // San Diego Gas & Electric
  'duke-energy.com',
  'nationalgrid.com',
  'xfinity.com',  // Comcast
  'att.com',  // AT&T internet/phone
  'verizon.com',  // Verizon internet/phone
  'spectrum.com',

  // Government & Legal
  'irs.gov',
  'ssa.gov',  // Social Security Administration
  'usps.com',
  'dmv.ca.gov',
  'uscis.gov',  // US Citizenship and Immigration
  'studentaid.gov',
  'medicare.gov',

  // Education
  'edu',  // All .edu domains
  'stanford.edu',
  'berkeley.edu',
  'harvard.edu',
  'mit.edu',

  // Tech Account Security
  'apple.com',
  'google.com',
  'microsoft.com',
  'amazon.com',  // Amazon account security (not marketing)
  'meta.com',
  'facebook.com',
  'twitter.com',
  'linkedin.com',
  'github.com',
  'gitlab.com',

  // Insurance
  'geico.com',
  'statefarm.com',
  'progressive.com',
  'allstate.com',
  'libertymutual.com'
];

// Intent patterns that should NEVER be automatically unsubscribed
// These are regex patterns that match against email classification intent
const CRITICAL_INTENT_PATTERNS = [
  // Banking & Financial
  /^banking\./,
  /^financial\./,
  /^payment\./,
  /^transaction\./,
  /^billing\./,
  /^invoice\./,
  /^receipt$/,  // Exact match for "receipt" intent
  /^order\.confirmation$/,
  /^shipment\./,

  // Security
  /^security\./,
  /^authentication\./,
  /^password/,
  /^verification/,
  /^two[_-]?factor/,
  /^2fa/,
  /^login/,
  /^account\.security/,

  // Healthcare
  /^healthcare\./,
  /^medical\./,
  /^appointment/,
  /^prescription/,
  /^health\.alert/,

  // Utilities
  /^utility\./,
  /^bill/,
  /^service\.alert/,

  // Government
  /^government\./,
  /^legal\./,
  /^tax/,

  // Account Management
  /^account\./,
  /^subscription\.change/,  // Allow marketing but not account changes
  /^delivery/,
  /^shipping/
];

// Email subjects that indicate critical communications
const CRITICAL_SUBJECT_PATTERNS = [
  /security alert/i,
  /password reset/i,
  /verification code/i,
  /two[- ]?factor/i,
  /2fa/i,
  /suspicious activity/i,
  /unauthorized/i,
  /account locked/i,
  /login attempt/i,
  /bill (is )?due/i,
  /payment (is )?due/i,
  /overdue/i,
  /appointment reminder/i,
  /prescription/i,
  /lab results/i,
  /test results/i,
  /delivery confirmation/i,
  /package delivered/i,
  /order confirmation/i,
  /receipt/i,
  /invoice/i
];

/**
 * Check if an email domain is on the critical domains safelist
 * @param {string} email - Email address or domain
 * @returns {boolean} - True if domain is critical and should not be unsubscribed
 */
function isCriticalDomain(email) {
  if (!email) return false;

  // Extract domain from email address
  const domain = email.includes('@') ? email.split('@')[1].toLowerCase() : email.toLowerCase();

  // Check exact domain match
  if (CRITICAL_DOMAINS.includes(domain)) {
    return true;
  }

  // Check if it's an .edu domain
  if (domain.endsWith('.edu')) {
    return true;
  }

  // Check parent domains (e.g., mail.google.com should match google.com)
  const domainParts = domain.split('.');
  if (domainParts.length > 2) {
    const parentDomain = domainParts.slice(-2).join('.');
    if (CRITICAL_DOMAINS.includes(parentDomain)) {
      return true;
    }
  }

  return false;
}

/**
 * Check if an email intent matches critical intent patterns
 * @param {string} intent - Email classification intent (e.g., "banking.security.alert")
 * @returns {boolean} - True if intent is critical and should not be unsubscribed
 */
function isCriticalIntent(intent) {
  if (!intent) return false;

  const intentLower = intent.toLowerCase();

  return CRITICAL_INTENT_PATTERNS.some(pattern => pattern.test(intentLower));
}

/**
 * Check if an email subject indicates critical communication
 * @param {string} subject - Email subject line
 * @returns {boolean} - True if subject indicates critical email
 */
function isCriticalSubject(subject) {
  if (!subject) return false;

  return CRITICAL_SUBJECT_PATTERNS.some(pattern => pattern.test(subject));
}

/**
 * Main function: Check if an email is safe to unsubscribe from
 * @param {object} email - Email object with sender, subject, classification
 * @param {string|object} email.from - Sender email address (string or {name, email} object)
 * @param {string} email.subject - Email subject line
 * @param {object} email.classification - Email classification with type, category, intent
 * @returns {object} - { safe: boolean, reason: string }
 */
function isSafeToUnsubscribe(email) {
  if (!email) {
    return { safe: false, reason: 'Invalid email object' };
  }

  const { from, subject, classification } = email;

  // Extract email address from 'from' field (handle both string and object format)
  const fromEmail = typeof from === 'string' ? from : (from && from.email ? from.email : null);

  // Check 1: Domain safelist
  if (fromEmail && isCriticalDomain(fromEmail)) {
    return {
      safe: false,
      reason: `Critical domain detected: ${fromEmail}. This is a banking, medical, utility, or security service.`
    };
  }

  // Check 2: Intent protection
  if (classification && classification.intent && isCriticalIntent(classification.intent)) {
    return {
      safe: false,
      reason: `Critical intent detected: ${classification.intent}. This email contains transactional or security information.`
    };
  }

  // Check 3: Explicit flag in classification
  if (classification && classification.shouldNeverUnsubscribe === true) {
    return {
      safe: false,
      reason: `Email explicitly marked as shouldNeverUnsubscribe=true.`
    };
  }

  // Check 4: Transactional email type
  if (classification && classification.type === 'transactional') {
    return {
      safe: false,
      reason: `Transactional email type detected. These are account-related communications.`
    };
  }

  // Check 5: Receipt classification
  if (classification && classification.type === 'receipt') {
    return {
      safe: false,
      reason: `Receipt/order email detected. These are purchase confirmations and should not be unsubscribed.`
    };
  }

  // Check 6: Subject line patterns
  if (subject && isCriticalSubject(subject)) {
    return {
      safe: false,
      reason: `Critical subject pattern detected: "${subject}". This appears to be a security, billing, or account communication.`
    };
  }

  // Passed all safety checks
  return { safe: true, reason: 'Email is a newsletter or marketing communication - safe to unsubscribe' };
}

/**
 * Get statistics about the safelist
 * @returns {object} - Counts of domains, intents, subject patterns
 */
function getSafelistStats() {
  return {
    criticalDomains: CRITICAL_DOMAINS.length,
    criticalIntentPatterns: CRITICAL_INTENT_PATTERNS.length,
    criticalSubjectPatterns: CRITICAL_SUBJECT_PATTERNS.length
  };
}

module.exports = {
  isSafeToUnsubscribe,
  isCriticalDomain,
  isCriticalIntent,
  isCriticalSubject,
  getSafelistStats,
  CRITICAL_DOMAINS,
  CRITICAL_INTENT_PATTERNS,
  CRITICAL_SUBJECT_PATTERNS
};
