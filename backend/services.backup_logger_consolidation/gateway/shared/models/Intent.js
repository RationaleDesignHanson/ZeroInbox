/**
 * Intent Taxonomy System
 * Two-level classification: Primary Purpose → Specific Intent
 * Format: category.sub_category.action
 */

const IntentTaxonomy = {
  // E-COMMERCE INTENTS
  'e-commerce.order.confirmation': {
    category: 'e-commerce',
    subCategory: 'order',
    action: 'confirmation',
    description: 'Order placement confirmation',
    triggers: ['order confirmed', 'thank you for your order', 'order number'],
    requiredEntities: ['orderNumber'],
    optionalEntities: ['totalAmount', 'estimatedDelivery']
  },
  'e-commerce.shipping.notification': {
    category: 'e-commerce',
    subCategory: 'shipping',
    action: 'notification',
    description: 'Package shipped notification',
    triggers: [
      'has shipped',
      'on its way',
      'tracking number',
      'out for delivery',
      'arriving soon',
      'arriving tomorrow',
      'arriving today',
      'be on the lookout',
      'track your package',
      'track package',
      'shipment',
      'your shipment',
      'order is arriving'
    ],
    requiredEntities: ['trackingNumber', 'carrier'],
    optionalEntities: ['orderNumber', 'estimatedDelivery']
  },
  'e-commerce.delivery.completed': {
    category: 'e-commerce',
    subCategory: 'delivery',
    action: 'completed',
    description: 'Package delivered confirmation',
    triggers: ['delivered', 'package arrived', 'delivery confirmed'],
    requiredEntities: ['orderNumber'],
    optionalEntities: ['deliveryLocation']
  },
  'e-commerce.order.receipt': {
    category: 'e-commerce',
    subCategory: 'order',
    action: 'receipt',
    description: 'Order receipt or invoice',
    triggers: ['receipt', 'invoice', 'payment received'],
    requiredEntities: ['orderNumber', 'totalAmount'],
    optionalEntities: ['items']
  },

  // BILLING & PAYMENTS
  'billing.invoice.due': {
    category: 'billing',
    subCategory: 'invoice',
    action: 'due',
    description: 'Invoice due for payment',
    triggers: [
      'invoice due',
      'invoice #',
      'invoice number',
      'amount due',
      'payment required',
      'please pay',
      'pay by',
      'due date',
      'payment due',
      'billing statement'
    ],
    requiredEntities: ['invoiceId', 'amountDue', 'dueDate'],
    optionalEntities: ['paymentLink']
  },
  'billing.payment.received': {
    category: 'billing',
    subCategory: 'payment',
    action: 'received',
    description: 'Payment confirmation',
    triggers: ['payment received', 'payment confirmed', 'thank you for your payment'],
    requiredEntities: ['paymentAmount'],
    optionalEntities: ['invoiceId', 'receiptUrl']
  },
  'billing.subscription.renewal': {
    category: 'billing',
    subCategory: 'subscription',
    action: 'renewal',
    description: 'Subscription renewal notice or payment issue',
    triggers: [
      'subscription renews',
      'renewal date',
      'auto-renew',
      'will renew on',
      'automatically renew',
      'update payment method',
      'update your payment',
      'billing date',
      'subscription expires',
      'renews on',
      'continue watching',
      'payment method',
      'trouble processing'
    ],
    requiredEntities: [],
    optionalEntities: ['renewalDate', 'amount', 'subscriptionName']
  },

  // EVENTS & MEETINGS
  'event.meeting.invitation': {
    category: 'event',
    subCategory: 'meeting',
    action: 'invitation',
    description: 'Meeting invitation',
    triggers: ['meeting invitation', 'invited you to', 'calendar invite'],
    requiredEntities: ['eventDate', 'eventTime'],
    optionalEntities: ['meetingUrl', 'location', 'organizer']
  },
  'event.webinar.invitation': {
    category: 'event',
    subCategory: 'webinar',
    action: 'invitation',
    description: 'Webinar or online event invitation',
    triggers: ['webinar', 'online event', 'register now'],
    requiredEntities: ['eventDate', 'registrationLink'],
    optionalEntities: ['eventTime', 'topic']
  },
  'event.meeting.reminder': {
    category: 'event',
    subCategory: 'meeting',
    action: 'reminder',
    description: 'Upcoming meeting reminder',
    triggers: ['meeting reminder', 'starting soon', 'happening in'],
    requiredEntities: ['eventTime', 'meetingUrl'],
    optionalEntities: ['eventTitle']
  },

  // ACCOUNT & SECURITY
  'account.password.reset': {
    category: 'account',
    subCategory: 'password',
    action: 'reset',
    description: 'Password reset request',
    triggers: ['reset password', 'forgot password', 'password reset'],
    requiredEntities: ['resetLink'],
    optionalEntities: ['username']
  },
  'account.security.alert': {
    category: 'account',
    subCategory: 'security',
    action: 'alert',
    description: 'Security or login alert',
    triggers: ['security alert', 'unusual activity', 'new login', 'suspicious'],
    requiredEntities: [],
    optionalEntities: ['device', 'location', 'ipAddress']
  },
  'account.verification.required': {
    category: 'account',
    subCategory: 'verification',
    action: 'required',
    description: 'Email or account verification',
    triggers: ['verify email', 'confirm account', 'verification required'],
    requiredEntities: ['verificationLink'],
    optionalEntities: []
  },
  'account.secret.exposed': {
    category: 'account',
    subCategory: 'secret',
    action: 'exposed',
    description: 'API key or secret exposed',
    triggers: ['secret exposed', 'api key', 'credential leaked'],
    requiredEntities: ['secretType'],
    optionalEntities: ['repository', 'actionUrl']
  },

  // EDUCATION & SCHOOL
  'education.assignment.due': {
    category: 'education',
    subCategory: 'assignment',
    action: 'due',
    description: 'Assignment or homework due',
    triggers: ['assignment due', 'homework', 'due date'],
    requiredEntities: ['dueDate', 'assignmentName'],
    optionalEntities: ['studentName', 'courseName']
  },
  'education.grade.posted': {
    category: 'education',
    subCategory: 'grade',
    action: 'posted',
    description: 'Grade posted notification',
    triggers: ['grade posted', 'graded', 'score available'],
    requiredEntities: ['assignmentName'],
    optionalEntities: ['grade', 'studentName']
  },
  'education.permission.form': {
    category: 'education',
    subCategory: 'permission',
    action: 'form',
    description: 'Permission form requiring signature',
    triggers: ['permission form', 'field trip', 'please sign', 'consent form'],
    requiredEntities: ['formName'],
    optionalEntities: ['dueDate', 'studentName', 'eventDate']
  },
  'education.announcement.general': {
    category: 'education',
    subCategory: 'announcement',
    action: 'general',
    description: 'School announcement or newsletter',
    triggers: ['school announcement', 'newsletter', 'upcoming events'],
    requiredEntities: [],
    optionalEntities: ['eventDate']
  },

  // HEALTHCARE
  'healthcare.appointment.reminder': {
    category: 'healthcare',
    subCategory: 'appointment',
    action: 'reminder',
    description: 'Medical appointment reminder',
    triggers: [
      'appointment reminder',
      'upcoming appointment',
      'appointment with',
      'please arrive',
      'check-in online',
      'bring insurance card',
      'dr.',
      'doctor',
      'physician',
      'your appointment'
    ],
    requiredEntities: ['dateTime', 'provider'],
    optionalEntities: ['location', 'specialty', 'checkInUrl']
  },
  'healthcare.prescription.ready': {
    category: 'healthcare',
    subCategory: 'prescription',
    action: 'ready',
    description: 'Prescription ready for pickup',
    triggers: [
      'prescription ready',
      'rx ready',
      'pick up by',
      'pharmacy',
      'prescription is ready',
      'medication ready'
    ],
    requiredEntities: ['medication'],
    optionalEntities: ['rxNumber', 'pickupDeadline', 'pharmacyLocation']
  },
  'healthcare.results.available': {
    category: 'healthcare',
    subCategory: 'results',
    action: 'available',
    description: 'Lab or test results available',
    triggers: [
      'lab results',
      'test results available',
      'results now available',
      'results are ready',
      'view your results'
    ],
    requiredEntities: ['resultType'],
    optionalEntities: ['testDate', 'resultsUrl']
  },
  'healthcare.billing.superbill': {
    category: 'healthcare',
    subCategory: 'billing',
    action: 'superbill',
    description: 'Medical bill or superbill for insurance reimbursement',
    triggers: [
      'superbill',
      'medical bill',
      'patient statement',
      'submit to your insurance',
      'insurance reimbursement',
      'out-of-network benefits',
      'insurance provider',
      'insurance claim',
      'patient balance',
      'healthcare provider'
    ],
    requiredEntities: [],
    optionalEntities: ['amountDue', 'provider', 'dateOfService', 'insuranceUrl']
  },

  // TRAVEL
  'travel.flight.check-in': {
    category: 'travel',
    subCategory: 'flight',
    action: 'check-in',
    description: 'Flight check-in reminder',
    triggers: ['check-in', 'check in now', 'flight reminder'],
    requiredEntities: ['flightNumber', 'departureDate'],
    optionalEntities: ['confirmationCode', 'checkInUrl']
  },
  'travel.reservation.confirmation': {
    category: 'travel',
    subCategory: 'reservation',
    action: 'confirmation',
    description: 'Hotel, flight, or car reservation',
    triggers: ['reservation confirmed', 'booking confirmed', 'itinerary'],
    requiredEntities: ['confirmationCode'],
    optionalEntities: ['checkInDate', 'location']
  },
  'travel.itinerary.update': {
    category: 'travel',
    subCategory: 'itinerary',
    action: 'update',
    description: 'Travel itinerary change',
    triggers: ['itinerary change', 'flight change', 'delay', 'cancellation'],
    requiredEntities: ['confirmationCode'],
    optionalEntities: ['newTime', 'reason']
  },

  // DINING & RESTAURANTS
  'dining.reservation.confirmation': {
    category: 'dining',
    subCategory: 'reservation',
    action: 'confirmation',
    description: 'Restaurant reservation confirmation',
    triggers: [
      'reservation confirmed',
      'your table',
      'party of',
      'opentable',
      'resy',
      'looking forward to seeing you',
      'reservation at',
      'booked a table'
    ],
    requiredEntities: ['restaurant', 'dateTime', 'partySize'],
    optionalEntities: ['confirmationCode', 'location', 'specialRequests']
  },

  // DELIVERY
  'delivery.food.tracking': {
    category: 'delivery',
    subCategory: 'food',
    action: 'tracking',
    description: 'Food delivery tracking',
    triggers: [
      'on its way',
      'driver is',
      'dasher',
      'courier',
      'preparing your order',
      'minutes away',
      'out for delivery',
      'order is being prepared',
      'arriving soon'
    ],
    requiredEntities: ['restaurant', 'eta'],
    optionalEntities: ['driver', 'orderNumber', 'trackingUrl']
  },

  // FEEDBACK & REVIEWS
  'feedback.review.request': {
    category: 'feedback',
    subCategory: 'review',
    action: 'request',
    description: 'Request for product or service review',
    triggers: ['review', 'feedback', 'how was your', 'rate your'],
    requiredEntities: ['productName'],
    optionalEntities: ['orderNumber', 'reviewLink']
  },
  'feedback.survey.invitation': {
    category: 'feedback',
    subCategory: 'survey',
    action: 'invitation',
    description: 'Survey invitation',
    triggers: ['survey', 'questionnaire', 'your opinion'],
    requiredEntities: ['surveyLink'],
    optionalEntities: []
  },

  // MARKETING & PROMOTIONS
  'marketing.promotion.flash-sale': {
    category: 'marketing',
    subCategory: 'promotion',
    action: 'flash-sale',
    description: 'Time-limited flash sale',
    triggers: ['flash sale', 'today only', 'limited time', 'expires today'],
    requiredEntities: ['expiresAt'],
    optionalEntities: ['discount', 'promoCode']
  },
  'marketing.promotion.discount': {
    category: 'marketing',
    subCategory: 'promotion',
    action: 'discount',
    description: 'General discount or sale promotion',
    triggers: [
      '% off',
      'percent off',
      'discount',
      'sale',
      'savings',
      'save',
      'ends tonight',
      'ends soon',
      'sale ends',
      'use code',
      'promo code',
      'coupon code',
      'shop now',
      'buy now'
    ],
    requiredEntities: [],
    optionalEntities: ['discount', 'promoCode', 'expiresAt', 'productName']
  },
  'marketing.product.launch': {
    category: 'marketing',
    subCategory: 'product',
    action: 'launch',
    description: 'New product announcement',
    triggers: ['new product', 'just launched', 'now available'],
    requiredEntities: ['productName'],
    optionalEntities: ['productUrl', 'price']
  },
  'marketing.cart.abandonment': {
    category: 'marketing',
    subCategory: 'cart',
    action: 'abandonment',
    description: 'Cart abandonment reminder',
    triggers: ['left in cart', 'forgot something', 'complete your order'],
    requiredEntities: ['cartUrl'],
    optionalEntities: ['items', 'totalAmount']
  },

  // SHOPPING & FUTURE PURCHASES
  'shopping.future_sale': {
    category: 'shopping',
    subCategory: 'product',
    action: 'future_sale',
    description: 'Product launching or going on sale in the future',
    triggers: [
      'launching',
      'goes on sale',
      'dropping',
      'pre-sale',
      'coming soon',
      'releases on',
      'available for purchase',
      'limited edition drop',
      'one week only',
      'shop the collection',
      'product launch',
      'sale starts'
    ],
    requiredEntities: ['saleDate', 'productUrl'],
    optionalEntities: ['productName', 'saleTime', 'timezone', 'variants', 'duration', 'limitedQuantity', 'priceEstimate']
  },

  // SUPPORT & SERVICE
  'support.ticket.confirmation': {
    category: 'support',
    subCategory: 'ticket',
    action: 'confirmation',
    description: 'Support ticket created',
    triggers: ['ticket created', 'case number', 'support request'],
    requiredEntities: ['ticketId'],
    optionalEntities: ['ticketUrl']
  },
  'support.ticket.update': {
    category: 'support',
    subCategory: 'ticket',
    action: 'update',
    description: 'Support ticket update',
    triggers: ['ticket update', 'case update', 'response from'],
    requiredEntities: ['ticketId'],
    optionalEntities: ['status']
  },

  // PROJECT MANAGEMENT
  'project.task.assigned': {
    category: 'project',
    subCategory: 'task',
    action: 'assigned',
    description: 'Task assigned to user',
    triggers: ['assigned to you', 'new task', 'action item'],
    requiredEntities: ['taskName'],
    optionalEntities: ['dueDate', 'projectName']
  },
  'project.incident.alert': {
    category: 'project',
    subCategory: 'incident',
    action: 'alert',
    description: 'System incident or outage',
    triggers: ['incident', 'outage', 'production issue', 'alert'],
    requiredEntities: ['severity'],
    optionalEntities: ['incidentUrl']
  },
  'project.deployment.notification': {
    category: 'project',
    subCategory: 'deployment',
    action: 'notification',
    description: 'Deployment notification',
    triggers: ['deployed', 'deployment', 'release'],
    requiredEntities: [],
    optionalEntities: ['version', 'environment']
  },

  // CIVIC & GOVERNMENT
  'civic.appointment.summons': {
    category: 'civic',
    subCategory: 'appointment',
    action: 'summons',
    description: 'Government appointment or summons',
    triggers: [
      'jury duty',
      'summons',
      'dmv appointment',
      'voter registration',
      'jury service',
      'report to',
      'juror number',
      'polling place'
    ],
    requiredEntities: ['dateTime', 'location'],
    optionalEntities: ['jurorNumber', 'confirmationCode', 'instructions']
  },

  // GENERIC/FALLBACK
  'generic.transactional': {
    category: 'generic',
    subCategory: 'transactional',
    action: 'notification',
    description: 'Generic transactional email',
    triggers: [],
    requiredEntities: [],
    optionalEntities: []
  },
  'generic.newsletter': {
    category: 'generic',
    subCategory: 'newsletter',
    action: 'content',
    description: 'Newsletter or content digest',
    triggers: [
      'newsletter', 'digest', 'weekly', 'daily', 'monthly',
      'roundup', 'this week', 'what\'s new', 'latest updates',
      'top stories', 'curated', 'bulletin', 'issue #',
      'edition', 'briefing', 'wrap-up', 'recap'
    ],
    requiredEntities: [],
    optionalEntities: ['keyTopics', 'articleLinks']
  }
};

/**
 * Schema.org action type mappings
 */
const SchemaOrgMappings = {
  'TrackAction': 'e-commerce.shipping.notification',
  'PayAction': 'billing.invoice.due',
  'RsvpAction': 'event.meeting.invitation',
  'ViewAction': 'generic.transactional',
  'ReviewAction': 'feedback.review.request',
  'CheckInAction': 'travel.flight.check-in',
  'ConfirmAction': 'account.verification.required'
};

/**
 * Get intent definition by ID
 */
function getIntent(intentId) {
  return IntentTaxonomy[intentId] || null;
}

/**
 * Get all intents in a category
 */
function getIntentsByCategory(category) {
  return Object.entries(IntentTaxonomy)
    .filter(([id, intent]) => intent.category === category)
    .reduce((acc, [id, intent]) => {
      acc[id] = intent;
      return acc;
    }, {});
}

/**
 * Map schema.org action type to intent
 */
function mapSchemaOrgAction(schemaActionType) {
  return SchemaOrgMappings[schemaActionType] || null;
}

/**
 * Get all intent IDs
 */
function getAllIntentIds() {
  return Object.keys(IntentTaxonomy);
}

module.exports = {
  IntentTaxonomy,
  SchemaOrgMappings,
  getIntent,
  getIntentsByCategory,
  mapSchemaOrgAction,
  getAllIntentIds
};

