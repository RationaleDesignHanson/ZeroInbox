/**
 * Smart Reply Generator
 * Phase 3.4: Generate contextual quick replies
 *
 * Purpose: Provide 2-4 quick reply suggestions based on email intent and context
 * Implementation: Template-based (can be enhanced with ML later)
 */

const logger = require('./shared/config/logger');

/**
 * Reply templates by intent category
 */
const REPLY_TEMPLATES = {
  // E-commerce
  'e-commerce.shipping.notification': [
    { text: 'Thanks for the update!', tone: 'positive', confidence: 0.9 },
    { text: 'When will it arrive?', tone: 'inquiry', confidence: 0.8 },
    { text: 'Can you change the delivery address?', tone: 'action', confidence: 0.7 }
  ],
  'e-commerce.order.confirmation': [
    { text: 'Thanks! Looking forward to it.', tone: 'positive', confidence: 0.9 },
    { text: 'Can I cancel this order?', tone: 'action', confidence: 0.7 },
    { text: 'When will it ship?', tone: 'inquiry', confidence: 0.8 }
  ],
  'e-commerce.delivery.scheduled': [
    { text: 'Perfect, I\u2019ll be home!', tone: 'positive', confidence: 0.9 },
    { text: 'Can we reschedule?', tone: 'action', confidence: 0.8 },
    { text: 'Leave it at the door', tone: 'instruction', confidence: 0.7 }
  ],

  // Billing & Payments
  'billing.invoice.due': [
    { text: 'I\u2019ll pay this today', tone: 'action', confidence: 0.9 },
    { text: 'Can I set up a payment plan?', tone: 'inquiry', confidence: 0.7 },
    { text: 'I already paid this', tone: 'clarification', confidence: 0.6 }
  ],
  'billing.payment.received': [
    { text: 'Thanks for confirming!', tone: 'positive', confidence: 0.9 },
    { text: 'Can I get a receipt?', tone: 'inquiry', confidence: 0.7 }
  ],

  // Healthcare
  'healthcare.appointment.reminder': [
    { text: 'I\u2019ll be there!', tone: 'positive', confidence: 0.9 },
    { text: 'Can we reschedule?', tone: 'action', confidence: 0.8 },
    { text: 'I need to cancel', tone: 'action', confidence: 0.7 }
  ],
  'healthcare.test.results': [
    { text: 'Thanks, I\u2019ll review these', tone: 'positive', confidence: 0.9 },
    { text: 'Can you explain the results?', tone: 'inquiry', confidence: 0.8 }
  ],

  // Travel
  'travel.flight.check-in': [
    { text: 'Thanks! Just checked in', tone: 'positive', confidence: 0.9 },
    { text: 'Can I change my seat?', tone: 'action', confidence: 0.7 },
    { text: 'What\u2019s the baggage limit?', tone: 'inquiry', confidence: 0.6 }
  ],
  'travel.itinerary.confirmation': [
    { text: 'Looking forward to the trip!', tone: 'positive', confidence: 0.9 },
    { text: 'Can I modify this booking?', tone: 'action', confidence: 0.7 }
  ],

  // Education
  'education.permission.form': [
    { text: 'Signed and approved!', tone: 'positive', confidence: 0.9 },
    { text: 'Can we discuss this?', tone: 'inquiry', confidence: 0.7 },
    { text: 'I have concerns about this', tone: 'concern', confidence: 0.6 }
  ],
  'education.assignment.due': [
    { text: 'Submitted!', tone: 'positive', confidence: 0.9 },
    { text: 'Can I get an extension?', tone: 'action', confidence: 0.8 }
  ],

  // Marketing (less engagement expected)
  'marketing.promotion.discount': [
    { text: 'Thanks, I\u2019ll check it out!', tone: 'positive', confidence: 0.7 },
    { text: 'Unsubscribe', tone: 'action', confidence: 0.8 }
  ],

  // Default/Generic
  '_default': [
    { text: 'Thanks!', tone: 'positive', confidence: 0.8 },
    { text: 'Got it', tone: 'acknowledgment', confidence: 0.8 },
    { text: 'I\u2019ll take a look', tone: 'action', confidence: 0.7 }
  ]
};

/**
 * Generate smart replies for an email
 * @param {Object} classification - Complete classification result
 * @returns {Array} Array of smart reply suggestions
 */
function generateSmartReplies(classification) {
  const startTime = Date.now();

  const {
    intent = '',
    entityMetadata = {},
    urgent = false,
    _classificationSource = 'unknown'
  } = classification;

  // Get base replies for this intent
  let replies = REPLY_TEMPLATES[intent] || REPLY_TEMPLATES._default;

  // Clone replies to avoid mutating templates
  replies = replies.map(r => ({...r}));

  // Apply urgency boost to action-oriented replies
  if (urgent) {
    replies.forEach(reply => {
      if (reply.tone === 'action') {
        reply.confidence += 0.1;
      }
    });
  }

  // Boost replies if we have high-quality entities
  const entityCount = Object.keys(entityMetadata).length;
  const highConfidenceEntities = Object.values(entityMetadata).filter(m => m.confidence >= 0.8).length;

  if (entityCount > 0 && highConfidenceEntities / entityCount > 0.7) {
    replies.forEach(reply => {
      if (reply.tone === 'positive' || reply.tone === 'action') {
        reply.confidence += 0.05;
      }
    });
  }

  // Sort by confidence and take top 3
  const sortedReplies = replies.sort((a, b) => b.confidence - a.confidence).slice(0, 3);

  // Add metadata
  const smartReplies = sortedReplies.map((reply, index) => ({
    text: reply.text,
    tone: reply.tone,
    confidence: Math.min(reply.confidence, 1.0),
    rank: index + 1,
    intent: intent || 'unknown'
  }));

  const processingTime = Date.now() - startTime;

  logger.info('Smart replies generated', {
    intent,
    replyCount: smartReplies.length,
    topReply: smartReplies[0]?.text,
    processingTime
  });

  return smartReplies;
}

/**
 * Check if email should have smart replies
 * Some emails (like automated notifications) don't need replies
 */
function shouldGenerateReplies(classification) {
  const { intent = '', _classificationSource = '' } = classification;

  // Don't generate replies for marketing/promotions
  if (intent.startsWith('marketing.')) {
    return false;
  }

  // Don't generate replies for automated system notifications
  const noReplyIntents = [
    'system.notification.automated',
    'system.newsletter.digest',
    'system.report.automated'
  ];

  return !noReplyIntents.includes(intent);
}

module.exports = {
  generateSmartReplies,
  shouldGenerateReplies,
  REPLY_TEMPLATES
};
