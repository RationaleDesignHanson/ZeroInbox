/**
 * Mock Classifier
 * Returns realistic classification responses from pre-defined templates
 * For Phase 2 Task 2.2: Mock Mode Implementation
 *
 * Purpose: Enable frontend testing without live ML models
 */

const logger = require('./shared/config/logger');
const { getActionsForIntent } = require('../actions/action-catalog');
const { CompoundActionRegistry } = require('../actions/compound-action-registry');

// Load mock templates
let mockTemplates = null;

function loadMockTemplates() {
  if (mockTemplates) return mockTemplates;

  try {
    mockTemplates = require('../../test-data/mock-email-templates.json');
    logger.info('Mock templates loaded', { count: mockTemplates.totalTemplates });
    return mockTemplates;
  } catch (error) {
    logger.error('Failed to load mock templates', { error: error.message });
    throw new Error('Mock templates not available');
  }
}

/**
 * Find best matching mock template for an email
 * @param {Object} email - Email object with subject, from, body
 * @returns {Object|null} Matching template or null
 */
function findMatchingTemplate(email) {
  const templates = loadMockTemplates();
  const subject = (email.subject || '').toLowerCase();
  const body = (email.body || '').toLowerCase();
  const from = (email.from || '').toLowerCase();

  // Try to find exact or close match
  const allTemplates = Object.values(templates.templates);

  // Strategy 1: Match by subject keywords
  for (const template of allTemplates) {
    const templateSubject = (template.subject || '').toLowerCase();
    const keywords = templateSubject.split(' ').filter(w => w.length > 4);

    if (keywords.some(keyword => subject.includes(keyword))) {
      logger.info('Mock template matched by subject', {
        templateId: template.id,
        emailSubject: email.subject
      });
      return template;
    }
  }

  // Strategy 2: Match by sender domain
  for (const template of allTemplates) {
    const templateFrom = (template.from || '').toLowerCase();
    if (templateFrom.includes('@')) {
      const domain = templateFrom.split('@')[1].replace(/[<>]/g, '');
      if (from.includes(domain)) {
        logger.info('Mock template matched by domain', {
          templateId: template.id,
          domain
        });
        return template;
      }
    }
  }

  // Strategy 3: Match by body keywords
  for (const template of allTemplates) {
    const templateBody = (template.body || '').toLowerCase();
    const bodyKeywords = templateBody.split(' ').slice(0, 10).filter(w => w.length > 6);

    if (bodyKeywords.length > 0 && bodyKeywords.some(keyword => body.includes(keyword))) {
      logger.info('Mock template matched by body', {
        templateId: template.id
      });
      return template;
    }
  }

  // Fallback: Return generic template
  logger.info('No specific match found, using generic template');
  return allTemplates.find(t => t.id === 'edge_case_no_subject') || allTemplates[0];
}

/**
 * Get mock template by ID
 * @param {string} templateId - Template ID
 * @returns {Object|null} Template or null
 */
function getTemplateById(templateId) {
  const templates = loadMockTemplates();
  return templates.templates[templateId] || null;
}

/**
 * Get all mock template IDs
 * @returns {string[]} Array of template IDs
 */
function getAllTemplateIds() {
  const templates = loadMockTemplates();
  return Object.keys(templates.templates);
}

/**
 * Generate entities for a template
 * @param {Object} template - Mock template
 * @returns {Object} Entities object
 */
function generateEntitiesForTemplate(template) {
  const entities = {};

  if (!template.expectedEntities) {
    return entities;
  }

  // Generate sample values for expected entities
  const entitySamples = {
    orderNumber: '112-7654321',
    trackingNumber: '1Z999AA10123456784',
    carrier: 'UPS',
    deliveryDate: '2025-01-15',
    estimatedDelivery: '3-5 business days',
    dateTime: '2025-01-15T14:00:00Z',
    provider: 'Dr. Smith',
    location: '123 Medical Plaza',
    amount: '$25.00',
    totalAmount: '$120.00',
    invoiceId: 'INV-2025-1234',
    dueDate: '2025-10-30',
    paymentLink: 'https://pay.com/invoice',
    paymentAmount: '$89.99',
    flightNumber: 'UA 123',
    airline: 'United Airlines',
    confirmationCode: 'ABC123',
    formName: 'Field Trip Permission Form',
    eventDate: '2025-01-20',
    promoCode: 'FLASH50',
    dealUrl: 'https://store.com/sale',
    meetingUrl: 'https://zoom.us/j/123456789',
    resetLink: 'https://service.com/reset/abc123',
    restaurant: 'Chipotle',
    driver: 'John',
    eta: '25 minutes',
    trackingUrl: 'https://doordash.com/track/xyz789',
    company: 'TechCorp',
    position: 'Software Engineer',
    interviewUrl: 'https://calendly.com/techcorp/interview',
    deadline: '2025-10-15',
    registrationUrl: 'https://vote.gov/register',
    serviceName: 'Spotify Premium',
    expirationDate: '2025-03-15',
    upgradeUrl: 'https://spotify.com/upgrade',
    productName: 'Wireless Headphones',
    reviewLink: 'https://amazon.com/review/prod123',
    newsUrl: 'https://techcrunch.com/newsletter',
    sport: 'Soccer',
    team: 'Blue Thunder',
    opponent: 'Red Dragons',
    scheduleUrl: 'https://league.com/schedule',
    platform: 'LinkedIn',
    sender: 'John Doe',
    messageUrl: 'https://linkedin.com/notifications/abc123',
    verificationLink: 'https://roblox.com/verify/xyz789',
    partySize: '4',
    outageStart: '2025-03-20T09:00:00Z',
    outageEnd: '2025-03-20T15:00:00Z',
    outageUrl: 'https://pge.com/outage/plan123',
    propertyCount: '3',
    priceRange: '$850K-$1.2M',
    listingsUrl: 'https://zillow.com/saved-search/abc123',
    lender: 'Quicken Loans',
    rate: '6.5%',
    accountId: 'ACCT-12345',
    statementUrl: 'https://bank.com/statements',
    amountDue: '$125.00',
    medication: 'Lisinopril',
    rxNumber: '12345',
    pickupDeadline: '2025-03-10',
    pharmacyLocation: 'CVS on Main St',
    resultType: 'Lab Results',
    testDate: '2025-01-10',
    resultsUrl: 'https://labcorp.com/results/abc123',
    schedulingUrl: 'https://scheduling.healthcare.com/book',
    assignmentName: 'Math Chapter 5 homework',
    studentName: 'Emma Johnson',
    teacher: 'Mrs. Davis',
    course: 'Biology',
    assignmentUrl: 'https://classroom.google.com/assignment/123',
    duration: '1.5 hours',
    rsvpUrl: 'https://rsvp.sports.com/game/123',
    topic: 'Project Collaboration',
    noteContent: 'Call dentist for cleaning',
    tags: ['personal', 'health'],
    device: 'iPhone',
    securityUrl: 'https://google.com/security',
    salary: '$150K',
    startDate: '2025-04-01',
    offerUrl: 'https://startup.com/offers/abc123',
    jurorNumber: '123456',
    paymentUrl: 'https://amex.com/pay',
    subscriptionUrl: 'https://service.com/billing',
    renewalDate: '2025-01-15',
    cartUrl: 'https://nike.com/cart/xyz789',
    items: ['Nike Air Max shoes'],
    totalAmount: '$120.00',
    pointsBalance: '2000',
    rewardUrl: 'https://sephora.com/rewards',
    preferencesUrl: 'https://ups.com/mychoice',
    refundAmount: '$89.99',
    processingDays: '5-7',
    oldPrice: '$999',
    newPrice: '$799',
    savings: '$200',
    productUrl: 'https://bestbuy.com/iphone15',
    returnDeadline: '2025-03-15',
    labelUrl: 'https://nordstrom.com/return/label',
    estimatedDelivery: '3-5 business days',
    checkInUrl: 'https://united.com/checkin/ABC123',
    departureDate: '2025-01-15',
    checkInDate: '2025-03-15',
    specialty: 'Cardiology',
    confirmationCode: 'RES-999888',
    discount: '30%',
    expiresAt: '2025-12-31T23:59:59Z',
    cancellationDate: '2025-03-31',
    transactionAmount: '$500',
    verificationUrl: 'https://bank.com/verify/alert123',
    merchant: 'Electronics Store',
    statementPeriod: 'February 2025'
  };

  template.expectedEntities.forEach(entityName => {
    if (entitySamples[entityName]) {
      entities[entityName] = entitySamples[entityName];
    } else {
      // Generate generic value
      entities[entityName] = `sample_${entityName}`;
    }
  });

  return entities;
}

/**
 * Classify email using mock templates
 * @param {Object} email - Email object
 * @returns {Object} Classification result
 */
function classifyEmailMock(email) {
  const template = findMatchingTemplate(email);

  if (!template) {
    logger.warn('No mock template found for email', { subject: email.subject });
    return {
      intent: 'generic.transactional.notification',
      intentConfidence: 0.50,
      suggestedActions: [
        {
          actionId: 'quick_reply',
          displayName: 'Quick Reply',
          actionType: 'IN_APP',
          priority: 5,
          isPrimary: true
        }
      ],
      entities: {},
      source: 'mock-fallback'
    };
  }

  // Generate entities
  const entities = generateEntitiesForTemplate(template);

  // Get actions for this intent
  const actions = getActionsForIntent(template.expectedIntent);

  // Map to action format
  const suggestedActions = actions.slice(0, 3).map((action, index) => ({
    actionId: action.actionId,
    displayName: action.displayName,
    actionType: action.actionType,
    description: action.description,
    priority: action.priority,
    isPrimary: index === 0,
    urlTemplate: action.urlTemplate || null,
    requiredEntities: action.requiredEntities || []
  }));

  // Check for compound action
  let compoundAction = null;
  if (template.compoundAction) {
    const compound = CompoundActionRegistry.getCompoundAction(template.compoundAction);
    if (compound) {
      compoundAction = {
        actionId: compound.actionId,
        displayName: compound.displayName,
        steps: compound.steps,
        endBehavior: compound.endBehavior,
        requiresResponse: compound.requiresResponse,
        isPremium: compound.isPremium
      };
    }
  }

  const classification = {
    intent: template.expectedIntent,
    intentConfidence: template.confidence || 0.85,
    suggestedActions,
    entities,
    compoundAction,
    source: 'mock-template',
    mockTemplateId: template.id
  };

  logger.info('Mock classification complete', {
    templateId: template.id,
    intent: template.expectedIntent,
    actionCount: suggestedActions.length,
    hasCompoundAction: !!compoundAction
  });

  return classification;
}

/**
 * Get random mock template
 * @returns {Object} Random template
 */
function getRandomTemplate() {
  const templates = loadMockTemplates();
  const allTemplates = Object.values(templates.templates);
  const randomIndex = Math.floor(Math.random() * allTemplates.length);
  return allTemplates[randomIndex];
}

/**
 * Get mock templates by intent category
 * @param {string} category - Intent category (e.g., 'e-commerce', 'healthcare')
 * @returns {Object[]} Templates matching category
 */
function getTemplatesByCategory(category) {
  const templates = loadMockTemplates();
  return Object.values(templates.templates).filter(template =>
    template.expectedIntent.startsWith(category + '.')
  );
}

module.exports = {
  classifyEmailMock,
  findMatchingTemplate,
  getTemplateById,
  getAllTemplateIds,
  getRandomTemplate,
  getTemplatesByCategory,
  loadMockTemplates
};
