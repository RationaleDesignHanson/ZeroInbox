/**
 * EmailCard Model
 * Matches the Swift EmailCard structure from the iOS app
 */

class EmailCard {
  constructor(data) {
    this.id = data.id;
    this.type = data.type; // archetype: caregiver, deal_stacker, transactional_leader, etc.
    this.state = data.state || 'unseen'; // unseen, seen, archived
    this.priority = data.priority; // critical, high, medium, low
    this.hpa = data.hpa; // Highest Priority Action
    this.timeAgo = data.timeAgo;
    this.title = data.title;
    this.summary = data.summary;
    this.body = data.body || null; // Full email body text
    this.htmlBody = data.htmlBody || null; // Original HTML email content
    this.metaCTA = data.metaCTA; // Call to action text

    // ACTION-FIRST MODEL (v1.1)
    this.intent = data.intent || null; // Intent ID (e.g., 'e-commerce.shipping.notification')
    this.intentConfidence = data.intentConfidence || null; // 0-1 confidence score
    this.suggestedActions = data.suggestedActions || []; // Array of action objects
    // Each action: { actionId, displayName, actionType, isPrimary, context: {} }

    // Optional fields based on archetype
    this.sender = data.sender || null;
    this.kid = data.kid || null;
    this.company = data.company || null;
    this.store = data.store || null;
    this.airline = data.airline || null;

    // Shopping-specific fields
    this.productImageUrl = data.productImageUrl || null;
    this.brandName = data.brandName || null;
    this.originalPrice = data.originalPrice || null;
    this.salePrice = data.salePrice || null;
    this.discount = data.discount || null;
    this.urgent = data.urgent || null;
    this.expiresIn = data.expiresIn || null;

    // Other fields
    this.requiresSignature = data.requiresSignature || null;
    this.value = data.value || null; // For sales emails
    this.probability = data.probability || null; // For sales emails
    this.score = data.score || null; // For sales emails

    // Payment fields (for transactional_leader)
    this.paymentAmount = data.paymentAmount || null;
    this.paymentDescription = data.paymentDescription || null;

    // Calendar invite fields
    this.calendarInvite = data.calendarInvite || null;

    // Thread fields (for threading UI - v1.6)
    this.threadLength = data.threadLength || null; // Number of messages in thread

    // Newsletter-specific fields (v1.11+)
    this.keyLinks = data.keyLinks || null; // Array of {title, url, description}
    this.keyTopics = data.keyTopics || null; // Array of strings

    // Raw email data (not sent to iOS)
    this._rawEmail = data._rawEmail || null;
    this._emailId = data._emailId || null; // Gmail/Outlook ID
    this._threadId = data._threadId || null;
  }

  // Convert to iOS-compatible format (removes internal fields)
  toJSON() {
    const json = { ...this };
    delete json._rawEmail;
    delete json._emailId;
    delete json._threadId;
    return json;
  }
}

// Email Categories (formerly "Archetypes")
// Binary classification system (v1.10+)
EmailCard.ArchetypeTypes = {
  // Modern 2-category system (v1.10+)
  MAIL: 'mail',                 // All non-promotional emails
  ADS: 'ads',                   // Marketing, promotions, newsletters

  // Legacy 4-category aliases for backward compatibility (v1.7-1.9)
  PERSONAL: 'mail',
  LIFESTYLE: 'mail',
  WORK: 'mail',
  SHOP: 'ads',                  // Shopping emails are typically promotional

  // Legacy 8-category aliases for backward compatibility (pre-v1.7, deprecated)
  FAMILY: 'mail',
  CAREGIVER: 'mail',
  EDUCATION: 'mail',

  SHOPPING: 'ads',
  DEAL_STACKER: 'ads',

  BILLING: 'mail',
  SALES: 'mail',
  PROJECT: 'mail',
  TRANSACTIONAL_LEADER: 'mail',
  SALES_HUNTER: 'mail',
  PROJECT_COORDINATOR: 'mail',

  LEARNING: 'mail',
  TRAVEL: 'mail',
  ACCOUNT: 'mail',
  ENTERPRISE_INNOVATOR: 'mail',
  STATUS_SEEKER: 'ads',
  IDENTITY_MANAGER: 'mail'
};

// Priority levels
EmailCard.Priorities = {
  CRITICAL: 'critical',
  HIGH: 'high',
  MEDIUM: 'medium',
  LOW: 'low'
};

// States
EmailCard.States = {
  UNSEEN: 'unseen',
  SEEN: 'seen',
  ARCHIVED: 'archived'
};

module.exports = EmailCard;
