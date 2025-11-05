/**
 * CompoundActionRegistry
 * Backend registry mirroring iOS CompoundActionRegistry.swift
 * Defines all multi-step action flows with end behavior rules
 *
 * Business Rules:
 * - "requiresResponse" = true → ends with email composer
 * - "requiresResponse" = false → returns to app or dismisses
 * - Backend sets isPrimary based on intent confidence and context completeness
 *
 * Contract with iOS:
 * - actionId must match iOS CompoundActionRegistry actionIds exactly
 * - steps array must reference valid actionIds from action-catalog.js
 * - endBehavior types must match iOS enum: emailComposer, dismissWithSuccess, returnToApp
 */

const logger = require('../../shared/config/logger');

// End Behavior Types (matching iOS CompoundActionDefinition.CompoundEndBehavior)
// iOS expects uppercase with underscores for enum values
const END_BEHAVIORS = {
  EMAIL_COMPOSER: 'EMAIL_COMPOSER',
  DISMISS_WITH_SUCCESS: 'DISMISS_WITH_SUCCESS',
  RETURN_TO_APP: 'RETURN_TO_APP'
};

/**
 * CompoundActionDefinition
 * Matches iOS CompoundActionDefinition structure
 *
 * @typedef {Object} CompoundActionDefinition
 * @property {string} actionId - Unique identifier matching iOS
 * @property {string} displayName - User-facing name
 * @property {string[]} steps - Ordered array of actionIds to execute
 * @property {Object} endBehavior - Defines what happens after final step
 * @property {string} endBehavior.type - One of END_BEHAVIORS
 * @property {Object} [endBehavior.template] - Email template (if type is emailComposer)
 * @property {boolean} requiresResponse - Whether email composer is needed
 * @property {boolean} isPremium - Premium feature flag
 * @property {string} description - Admin/developer description
 */

/**
 * All compound action definitions
 * Must match iOS CompoundActionRegistry.swift allCompoundActions
 */
const COMPOUND_ACTIONS = {

  // ==========================================
  // EDUCATION & CHILDCARE COMPOUND FLOWS
  // ==========================================

  sign_form_with_payment: {
    actionId: 'sign_form_with_payment',
    displayName: 'Sign & Pay Permission Form',
    steps: ['sign_form', 'pay_form_fee', 'email_composer'],
    endBehavior: {
      type: END_BEHAVIORS.EMAIL_COMPOSER,
      template: {
        subjectPrefix: 'Re: Permission Form - Signed & Paid',
        bodyTemplate: 'Hi {sender_name},\n\nI\'ve signed the permission form and completed the ${amount} payment via {payment_method}.\n\nThank you!',
        includeOriginalSender: true
      }
    },
    requiresResponse: true,  // Permission slips need confirmation
    isPremium: true,
    description: 'Sign permission form, pay associated fee, send email confirmation to sender'
  },

  sign_form_with_calendar: {
    actionId: 'sign_form_with_calendar',
    displayName: 'Sign Form & Add to Calendar',
    steps: ['sign_form', 'add_to_calendar', 'email_composer'],
    endBehavior: {
      type: END_BEHAVIORS.EMAIL_COMPOSER,
      template: {
        subjectPrefix: 'Re: {form_name} - Signed & Calendar Updated',
        bodyTemplate: 'Hi {sender_name},\n\nI\'ve signed the form and added the event to my calendar for {event_date}.\n\nLooking forward to it!',
        includeOriginalSender: true
      }
    },
    requiresResponse: true,  // School forms with events need confirmation
    isPremium: true,
    description: 'Sign form (e.g., field trip), add event to calendar, confirm attendance with sender'
  },

  sign_and_send: {
    actionId: 'sign_and_send',
    displayName: 'Sign & Send',
    steps: ['sign_form', 'email_composer'],
    endBehavior: {
      type: END_BEHAVIORS.EMAIL_COMPOSER,
      template: {
        subjectPrefix: 'Re: {form_name} - Signed',
        bodyTemplate: 'Hi {sender_name},\n\nI\'ve signed the form and it\'s ready to go.\n\nThank you!',
        includeOriginalSender: true
      }
    },
    requiresResponse: true,  // Permission forms need confirmation
    isPremium: false,  // Basic sign and send is free
    description: 'Sign permission form and send confirmation email to sender (basic permission form flow)'
  },

  // ==========================================
  // SHOPPING COMPOUND FLOWS
  // ==========================================

  track_with_calendar: {
    actionId: 'track_with_calendar',
    displayName: 'Track Package & Schedule Delivery',
    steps: ['track_package', 'add_to_calendar'],
    endBehavior: {
      type: END_BEHAVIORS.RETURN_TO_APP
    },
    requiresResponse: false,  // No response needed - personal action
    isPremium: true,
    description: 'View package tracking info, add estimated delivery date/time to calendar for planning'
  },

  schedule_purchase_with_reminder: {
    actionId: 'schedule_purchase_with_reminder',
    displayName: 'Schedule Purchase with Calendar Reminder',
    steps: ['schedule_purchase', 'add_to_calendar'],
    endBehavior: {
      type: END_BEHAVIORS.RETURN_TO_APP
    },
    requiresResponse: false,  // No response needed - personal planning
    isPremium: true,
    description: 'Set reminder for product launch/sale, add notification to calendar 15min before'
  },

  // ==========================================
  // PAYMENT COMPOUND FLOWS
  // ==========================================

  pay_invoice_with_confirmation: {
    actionId: 'pay_invoice_with_confirmation',
    displayName: 'Pay Invoice & Send Confirmation',
    steps: ['pay_invoice', 'email_composer'],
    endBehavior: {
      type: END_BEHAVIORS.EMAIL_COMPOSER,
      template: {
        subjectPrefix: 'Re: Invoice {invoice_id} - Payment Sent',
        bodyTemplate: 'Hi {merchant},\n\nI\'ve completed payment of {amount} for invoice {invoice_id} via {payment_method}.\n\nPlease confirm receipt.\n\nThank you!',
        includeOriginalSender: true
      }
    },
    requiresResponse: true,  // Payment confirmations need response from merchant
    isPremium: true,
    description: 'Complete invoice payment, send confirmation email to merchant requesting receipt'
  },

  // ==========================================
  // TRAVEL COMPOUND FLOWS
  // ==========================================

  check_in_with_wallet: {
    actionId: 'check_in_with_wallet',
    displayName: 'Check In & Add Boarding Pass to Wallet',
    steps: ['check_in_flight', 'add_to_wallet'],
    endBehavior: {
      type: END_BEHAVIORS.RETURN_TO_APP
    },
    requiresResponse: false,  // No response needed - personal action
    isPremium: true,
    description: 'Check in for flight online, add boarding pass to Apple Wallet for easy access'
  },

  // ==========================================
  // CALENDAR COMPOUND FLOWS
  // ==========================================

  calendar_with_reminder: {
    actionId: 'calendar_with_reminder',
    displayName: 'Add to Calendar with Pre-Event Reminder',
    steps: ['add_to_calendar', 'add_reminder'],
    endBehavior: {
      type: END_BEHAVIORS.RETURN_TO_APP
    },
    requiresResponse: false,  // No response needed - personal planning
    isPremium: false,  // Basic calendar functionality - keep free
    description: 'Add event to iOS Calendar, set reminder (default 15min before event start)'
  },

  // ==========================================
  // SUBSCRIPTION COMPOUND FLOWS
  // ==========================================

  cancel_with_confirmation: {
    actionId: 'cancel_with_confirmation',
    displayName: 'Cancel Subscription & Request Confirmation',
    steps: ['cancel_subscription', 'email_composer'],
    endBehavior: {
      type: END_BEHAVIORS.EMAIL_COMPOSER,
      template: {
        subjectPrefix: 'Re: Subscription Cancellation Request',
        bodyTemplate: 'Hi {service_name} Support,\n\nI\'d like to cancel my subscription as discussed. Please confirm the cancellation and let me know the final billing date.\n\nThank you!',
        includeOriginalSender: true
      }
    },
    requiresResponse: true,  // Cancellation requests need confirmation from service
    isPremium: false,  // Keep unsubscribe/cancel flow free (customer-friendly)
    description: 'Cancel subscription, send confirmation request to service support team'
  },

  // ==========================================
  // THREAD FINDER COMPOUND FLOWS
  // Link-heavy emails with extracted content
  // ==========================================

  extract_and_calendar: {
    actionId: 'extract_and_calendar',
    displayName: 'Extract Content & Add to Calendar',
    steps: ['view_extracted_content', 'add_to_calendar'],
    endBehavior: {
      type: END_BEHAVIORS.RETURN_TO_APP
    },
    requiresResponse: false,  // No response needed - personal planning
    isPremium: true,
    description: 'View automatically extracted content from link (Canvas, school portal), add due date/event to calendar'
  },

  extract_and_reminder: {
    actionId: 'extract_and_reminder',
    displayName: 'Extract Content & Set Reminder',
    steps: ['view_extracted_content', 'add_reminder'],
    endBehavior: {
      type: END_BEHAVIORS.RETURN_TO_APP
    },
    requiresResponse: false,  // No response needed - personal planning
    isPremium: true,
    description: 'View automatically extracted content from link, set reminder for due date (default 2 days before)'
  },

  extract_calendar_and_reminder: {
    actionId: 'extract_calendar_and_reminder',
    displayName: 'Extract, Calendar & Reminder',
    steps: ['view_extracted_content', 'add_to_calendar', 'add_reminder'],
    endBehavior: {
      type: END_BEHAVIORS.RETURN_TO_APP
    },
    requiresResponse: false,  // No response needed - personal planning
    isPremium: true,
    description: 'Full Thread Finder flow: View extracted content, add to calendar, set pre-event reminder'
  },

  extract_download_and_calendar: {
    actionId: 'extract_download_and_calendar',
    displayName: 'Extract, Download & Calendar',
    steps: ['view_extracted_content', 'download_attachment', 'add_to_calendar'],
    endBehavior: {
      type: END_BEHAVIORS.RETURN_TO_APP
    },
    requiresResponse: false,  // No response needed - personal planning
    isPremium: true,
    description: 'Complete parent workflow: View assignment details, download materials (PDFs/worksheets), add due date to calendar'
  }
};

/**
 * CompoundActionRegistry
 * Query and validation methods for compound actions
 */
class CompoundActionRegistry {
  constructor() {
    this.compoundActions = COMPOUND_ACTIONS;
    logger.info(`CompoundActionRegistry initialized with ${Object.keys(this.compoundActions).length} compound actions`);
  }

  /**
   * Get compound action definition by ID
   * @param {string} actionId - Compound action ID
   * @returns {CompoundActionDefinition|null}
   */
  getCompoundAction(actionId) {
    return this.compoundActions[actionId] || null;
  }

  /**
   * Check if action is compound
   * @param {string} actionId - Action ID to check
   * @returns {boolean}
   */
  isCompoundAction(actionId) {
    return actionId in this.compoundActions;
  }

  /**
   * Get all compound actions requiring email composer (requiresResponse = true)
   * @returns {CompoundActionDefinition[]}
   */
  getCompoundActionsRequiringResponse() {
    return Object.values(this.compoundActions).filter(action => action.requiresResponse);
  }

  /**
   * Get all compound actions that return to app (requiresResponse = false)
   * @returns {CompoundActionDefinition[]}
   */
  getPersonalCompoundActions() {
    return Object.values(this.compoundActions).filter(action => !action.requiresResponse);
  }

  /**
   * Get all premium compound actions
   * @returns {CompoundActionDefinition[]}
   */
  getPremiumCompoundActions() {
    return Object.values(this.compoundActions).filter(action => action.isPremium);
  }

  /**
   * Get all free compound actions
   * @returns {CompoundActionDefinition[]}
   */
  getFreeCompoundActions() {
    return Object.values(this.compoundActions).filter(action => !action.isPremium);
  }

  /**
   * Get compound action statistics
   * @returns {Object} Statistics object
   */
  getCompoundActionCount() {
    const all = Object.values(this.compoundActions);
    return {
      total: all.length,
      premium: all.filter(a => a.isPremium).length,
      free: all.filter(a => !a.isPremium).length,
      requiresResponse: all.filter(a => a.requiresResponse).length
    };
  }

  /**
   * Get all compound action IDs
   * @returns {string[]}
   */
  getAllCompoundActionIds() {
    return Object.keys(this.compoundActions).sort();
  }

  /**
   * Validate compound action steps against ActionRegistry
   * @param {string} actionId - Compound action ID
   * @param {Object} actionRegistry - ActionRegistry instance with getAction(id) method
   * @returns {Object} Validation result { isValid: boolean, missingActions: string[] }
   */
  validateCompoundAction(actionId, actionRegistry) {
    const compound = this.getCompoundAction(actionId);

    if (!compound) {
      return { isValid: false, missingActions: [] };
    }

    const missingActions = [];

    for (const stepActionId of compound.steps) {
      // Skip email_composer and add_reminder as these are built-in iOS actions
      if (stepActionId === 'email_composer' || stepActionId === 'add_reminder') {
        continue;
      }

      const stepAction = actionRegistry[stepActionId];
      if (!stepAction) {
        missingActions.push(stepActionId);
      }
    }

    return {
      isValid: missingActions.length === 0,
      missingActions
    };
  }

  /**
   * Get statistics for debugging and admin dashboard
   * @returns {Object} Statistics object with descriptions
   */
  getStatistics() {
    const counts = this.getCompoundActionCount();

    return {
      totalCompoundActions: counts.total,
      premiumCompoundActions: counts.premium,
      freeCompoundActions: counts.free,
      requiresResponseCount: counts.requiresResponse,
      personalActionsCount: counts.total - counts.requiresResponse,
      description: `CompoundActionRegistry Statistics:
- Total Compound Actions: ${counts.total}
- Premium Compound Actions: ${counts.premium}
- Free Compound Actions: ${counts.free}
- Requires Email Response: ${counts.requiresResponse}
- Personal Actions (no response): ${counts.total - counts.requiresResponse}`
    };
  }

  /**
   * Detect if compound action is appropriate for given intent and entities
   * Smart detection based on email context richness
   *
   * @param {string} intent - Email intent (e.g., 'education.permission.form')
   * @param {Object} entities - Extracted entities from email
   * @returns {string|null} Suggested compound action ID or null
   */
  detectCompoundAction(intent, entities) {
    // Education permission forms with payment info
    if (intent === 'education.permission.form' && entities.amount) {
      logger.info('Detected education permission form with payment → sign_form_with_payment', { intent, hasAmount: !!entities.amount });
      return 'sign_form_with_payment';
    }

    // Education permission forms with event date/time
    if (intent === 'education.permission.form' && entities.eventDate) {
      logger.info('Detected education permission form with event → sign_form_with_calendar', { intent, hasEventDate: !!entities.eventDate });
      return 'sign_form_with_calendar';
    }

    // Basic education permission forms (fallback for all permission forms without payment or event)
    if (intent === 'education.permission.form') {
      logger.info('Detected basic education permission form → sign_and_send', { intent });
      return 'sign_and_send';
    }

    // Shipping notifications with delivery date
    if (intent === 'e-commerce.shipping.notification' && entities.deliveryDate) {
      logger.info('Detected shipping notification with delivery date → track_with_calendar', { intent, hasDeliveryDate: !!entities.deliveryDate });
      return 'track_with_calendar';
    }

    // Product launch/sale with date
    if (intent === 'e-commerce.promotion' && entities.saleDate) {
      logger.info('Detected promotion with sale date → schedule_purchase_with_reminder', { intent, hasSaleDate: !!entities.saleDate });
      return 'schedule_purchase_with_reminder';
    }

    // Invoice with payment capability
    if (intent === 'billing.invoice.due' && entities.amount && entities.merchant) {
      logger.info('Detected invoice with payment info → pay_invoice_with_confirmation', { intent, hasAmount: !!entities.amount, hasMerchant: !!entities.merchant });
      return 'pay_invoice_with_confirmation';
    }

    // Flight check-in notifications
    if (intent === 'travel.flight.check-in' && entities.flightNumber) {
      logger.info('Detected flight check-in → check_in_with_wallet', { intent, hasFlightNumber: !!entities.flightNumber });
      return 'check_in_with_wallet';
    }

    // Generic calendar events
    if (intent.includes('appointment') || intent.includes('event')) {
      if (entities.eventDate || entities.appointmentTime) {
        logger.info('Detected event with date → calendar_with_reminder', { intent, hasDateTime: !!(entities.eventDate || entities.appointmentTime) });
        return 'calendar_with_reminder';
      }
    }

    // Subscription cancellation requests
    if (intent === 'subscription.cancellation' || intent.includes('cancel')) {
      logger.info('Detected cancellation intent → cancel_with_confirmation', { intent });
      return 'cancel_with_confirmation';
    }

    // Thread Finder link-only emails with extracted content
    // Prioritize download flow if attachments present, otherwise calendar/reminder flow
    if ((intent === 'education.lms.link-only' ||
         intent === 'education.school-portal.link-only' ||
         intent === 'youth.sports.link-only') &&
        entities.extractedContent) {

      const hasCalendarData = entities.extractedContent.dueDate || entities.extractedContent.date;
      const hasAttachments = entities.extractedContent.attachments &&
                             entities.extractedContent.attachments.length > 0;

      // Prioritize download + calendar flow if attachments present
      if (hasAttachments && hasCalendarData) {
        logger.info('Detected Thread Finder email with attachments and calendar data → extract_download_and_calendar', {
          intent,
          hasExtractedContent: !!entities.extractedContent,
          hasAttachments,
          hasDueDate: !!entities.extractedContent.dueDate,
          attachmentCount: entities.extractedContent.attachments.length
        });
        return 'extract_download_and_calendar';
      } else if (hasCalendarData) {
        logger.info('Detected Thread Finder email with calendar data → extract_calendar_and_reminder', {
          intent,
          hasExtractedContent: !!entities.extractedContent,
          hasDueDate: !!entities.extractedContent.dueDate
        });
        return 'extract_calendar_and_reminder';
      } else {
        logger.info('Detected Thread Finder email → extract_and_reminder', {
          intent,
          hasExtractedContent: !!entities.extractedContent
        });
        return 'extract_and_reminder';
      }
    }

    // No compound action detected
    return null;
  }

  /**
   * Get all compound actions available for a given intent
   * @param {string} intent - Email intent
   * @returns {CompoundActionDefinition[]}
   */
  getCompoundActionsForIntent(intent) {
    const actions = [];

    // Map intents to compound actions
    const intentMapping = {
      'education.permission.form': ['sign_form_with_payment', 'sign_form_with_calendar', 'sign_and_send'],
      'e-commerce.shipping.notification': ['track_with_calendar'],
      'e-commerce.promotion': ['schedule_purchase_with_reminder'],
      'billing.invoice.due': ['pay_invoice_with_confirmation'],
      'travel.flight.check-in': ['check_in_with_wallet'],
      'subscription.cancellation': ['cancel_with_confirmation'],
      'education.lms.link-only': ['extract_download_and_calendar', 'extract_calendar_and_reminder', 'extract_and_calendar', 'extract_and_reminder'],
      'education.school-portal.link-only': ['extract_download_and_calendar', 'extract_calendar_and_reminder', 'extract_and_calendar', 'extract_and_reminder'],
      'youth.sports.link-only': ['extract_download_and_calendar', 'extract_calendar_and_reminder', 'extract_and_calendar', 'extract_and_reminder']
    };

    const compoundIds = intentMapping[intent] || [];
    compoundIds.forEach(id => {
      const action = this.getCompoundAction(id);
      if (action) actions.push(action);
    });

    return actions;
  }
}

// Singleton instance
const registry = new CompoundActionRegistry();

// Export singleton and classes
module.exports = {
  CompoundActionRegistry: registry,
  END_BEHAVIORS,
  COMPOUND_ACTIONS
};
