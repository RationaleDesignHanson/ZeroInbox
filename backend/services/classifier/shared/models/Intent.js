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
      'package arriving',
      'your package',
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
    triggers: ['order receipt', 'purchase receipt', 'order invoice', 'receipt for', 'receipt from', 'thank you for your order', 'order summary'],
    negativePatterns: ['invoice due', 'amount due', 'payment due', 'pay by', 'due date', 'please pay'],
    requiredEntities: ['orderNumber', 'totalAmount'],
    optionalEntities: ['items']
  },
  'e-commerce.order.delayed': {
    category: 'e-commerce',
    subCategory: 'order',
    action: 'delayed',
    description: 'Order or shipment delayed',
    triggers: [
      'delayed',
      'running late',
      'shipping delayed',
      'delivery delayed',
      'delayed shipment',
      'later than expected',
      'behind schedule',
      'delay in shipment'
    ],
    requiredEntities: ['orderNumber'],
    optionalEntities: ['newEstimatedDelivery', 'reason']
  },
  'e-commerce.return.label': {
    category: 'e-commerce',
    subCategory: 'return',
    action: 'label',
    description: 'Return label or instructions',
    triggers: [
      'return label',
      'return shipping',
      'return instructions',
      'how to return',
      'return your order',
      'return process',
      'print return label',
      'return package'
    ],
    requiredEntities: ['orderNumber'],
    optionalEntities: ['returnDeadline', 'returnUrl', 'labelUrl']
  },
  'e-commerce.refund.processing': {
    category: 'e-commerce',
    subCategory: 'refund',
    action: 'processing',
    description: 'Refund being processed',
    triggers: [
      'refund initiated',
      'refund processing',
      'money back',
      'refund in progress',
      'processing your refund',
      'refund will be issued',
      'refund approved',
      'refund started'
    ],
    requiredEntities: ['refundAmount'],
    optionalEntities: ['orderNumber', 'processingDays', 'refundMethod']
  },
  'e-commerce.backorder.notification': {
    category: 'e-commerce',
    subCategory: 'backorder',
    action: 'notification',
    description: 'Item on backorder or out of stock',
    triggers: [
      'back ordered',
      'out of stock',
      'delayed shipment',
      'item unavailable',
      'stock delay',
      'temporarily unavailable',
      'backorder',
      'supply chain delay'
    ],
    requiredEntities: ['productName'],
    optionalEntities: ['orderNumber', 'expectedRestockDate']
  },
  'e-commerce.price.drop': {
    category: 'e-commerce',
    subCategory: 'price',
    action: 'drop',
    description: 'Price drop alert for watched item',
    triggers: [
      'price drop',
      'now on sale',
      'price reduced',
      'price lowered',
      'cheaper now',
      'save on',
      'price match',
      'price adjustment'
    ],
    requiredEntities: ['productName', 'newPrice'],
    optionalEntities: ['oldPrice', 'savings', 'productUrl']
  },
  'e-commerce.restock.alert': {
    category: 'e-commerce',
    subCategory: 'restock',
    action: 'alert',
    description: 'Item back in stock alert',
    triggers: [
      'back in stock',
      'now available',
      'restock alert',
      'available again',
      'replenished',
      'restocked',
      'item you wanted',
      'in stock now'
    ],
    requiredEntities: ['productName'],
    optionalEntities: ['productUrl', 'quantity']
  },
  'e-commerce.warranty.expiring': {
    category: 'e-commerce',
    subCategory: 'warranty',
    action: 'expiring',
    description: 'Warranty expiration notice',
    triggers: [
      'warranty expiring',
      'warranty ends',
      'protection plan',
      'warranty expires',
      'coverage ending',
      'extend warranty',
      'warranty renewal',
      'protection expires'
    ],
    requiredEntities: ['productName', 'expirationDate'],
    optionalEntities: ['orderNumber', 'extensionUrl']
  },
  'e-commerce.delivery.schedule': {
    category: 'e-commerce',
    subCategory: 'delivery',
    action: 'schedule',
    description: 'Delivery scheduling required for pre-order or special item',
    triggers: [
      'schedule your delivery',
      'choose delivery time',
      'delivery appointment',
      'schedule a delivery',
      'select delivery window',
      'schedule delivery now',
      'pick delivery time',
      'schedule your order',
      'pre-order delivery'
    ],
    requiredEntities: [],
    optionalEntities: ['productName', 'orderNumber', 'schedulingUrl', 'deadline']
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
      'billing statement',
      'outstanding invoice',
      'overdue invoice',
      'invoice amount',
      'payment overdue',
      'pay invoice',
      'invoice reminder',
      'payment request'
    ],
    negativePatterns: ['paid', 'payment received', 'thank you for', 'receipt', 'order confirmed', 'shipped'],
    requiredEntities: ['invoiceId', 'amountDue', 'dueDate'],
    optionalEntities: ['paymentLink']
  },
  'billing.payment.received': {
    category: 'billing',
    subCategory: 'payment',
    action: 'received',
    description: 'Payment confirmation',
    triggers: [
      'payment received',
      'payment confirmed',
      'thank you for your payment',
      'we received your payment',
      'payment has been received',
      'payment successfully received',
      'payment processed successfully',
      'payment confirmation',
      'invoice paid',
      'invoice payment received'
    ],
    negativePatterns: ['order confirmed', 'shipped', 'track', 'delivery'],
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
  'finance.statement.ready': {
    category: 'finance',
    subCategory: 'statement',
    action: 'ready',
    description: 'Financial statement available',
    triggers: [
      'statement available',
      'statement ready',
      'monthly statement',
      'statement is ready',
      'view your statement',
      'account statement',
      'bank statement',
      'credit card statement'
    ],
    requiredEntities: ['accountId'],
    optionalEntities: ['statementPeriod', 'statementUrl']
  },
  'finance.payment.reminder': {
    category: 'finance',
    subCategory: 'payment',
    action: 'reminder',
    description: 'Upcoming payment reminder',
    triggers: [
      'payment reminder',
      'payment approaching',
      'upcoming payment',
      'payment coming up',
      'payment scheduled',
      'payment will be withdrawn',
      'automatic payment',
      'scheduled payment'
    ],
    requiredEntities: ['amountDue', 'dueDate'],
    optionalEntities: ['accountId', 'paymentMethod']
  },
  'finance.payment.failed': {
    category: 'finance',
    subCategory: 'payment',
    action: 'failed',
    description: 'Payment failed notification',
    triggers: [
      'payment failed',
      'payment declined',
      'insufficient funds',
      'payment unsuccessful',
      'payment could not be processed',
      'unable to process payment',
      'payment issue',
      'payment problem'
    ],
    requiredEntities: ['amountDue'],
    optionalEntities: ['accountId', 'failureReason', 'retryDate']
  },
  'finance.refund.processed': {
    category: 'finance',
    subCategory: 'refund',
    action: 'processed',
    description: 'Refund issued notification',
    triggers: [
      'refund issued',
      'refund processed',
      'money returned',
      'refund sent',
      'refund has been processed',
      'refund completed',
      'credit issued',
      'credited to your account'
    ],
    requiredEntities: ['refundAmount'],
    optionalEntities: ['accountId', 'originalTransaction', 'processingDays']
  },
  'finance.credit.alert': {
    category: 'finance',
    subCategory: 'credit',
    action: 'alert',
    description: 'Credit score or report update',
    triggers: [
      'credit score updated',
      'credit report available',
      'score change',
      'credit monitoring',
      'score increased',
      'score decreased',
      'credit update',
      'new credit score'
    ],
    requiredEntities: [],
    optionalEntities: ['creditScore', 'scoreChange', 'reportUrl']
  },
  'finance.tax.document': {
    category: 'finance',
    subCategory: 'tax',
    action: 'document',
    description: 'Tax document available',
    triggers: [
      'tax document ready',
      '1099 available',
      'w-2 available',
      'tax form',
      'tax statement',
      'tax return',
      '1098 available',
      'tax document'
    ],
    requiredEntities: ['taxYear'],
    optionalEntities: ['documentType', 'downloadUrl']
  },
  'finance.investment.performance': {
    category: 'finance',
    subCategory: 'investment',
    action: 'performance',
    description: 'Investment portfolio update',
    triggers: [
      'portfolio update',
      'investment summary',
      'market performance',
      'portfolio performance',
      'investment update',
      'account summary',
      'portfolio balance',
      'investment gains'
    ],
    requiredEntities: ['accountId'],
    optionalEntities: ['portfolioValue', 'changePercent', 'timeframe']
  },
  'finance.fraud.alert': {
    category: 'finance',
    subCategory: 'fraud',
    action: 'alert',
    description: 'Suspicious activity or fraud alert',
    triggers: [
      'suspicious activity',
      'fraud alert',
      'unusual transaction',
      'potential fraud',
      'verify transaction',
      'did you make this purchase',
      'unauthorized transaction',
      'fraudulent activity'
    ],
    requiredEntities: ['accountId'],
    optionalEntities: ['transactionAmount', 'transactionDate', 'verificationUrl']
  },
  'finance.payment.sent': {
    category: 'finance',
    subCategory: 'payment',
    action: 'sent',
    description: 'Payment sent confirmation (Venmo, Zelle, etc.)',
    triggers: [
      'you paid',
      'you sent',
      'payment sent',
      'payment to',
      'venmo',
      'zelle',
      'paypal',
      'cash app',
      'transfer sent',
      'sent $',
      'paid $'
    ],
    requiredEntities: [],
    optionalEntities: ['paymentAmount', 'recipient', 'paymentMethod']
  },
  'finance.payment.received': {
    category: 'finance',
    subCategory: 'payment',
    action: 'received',
    description: 'Payment received notification',
    triggers: [
      'you received',
      'payment received',
      'deposited',
      'transfer received',
      'money received',
      'received $',
      'sent you $'
    ],
    requiredEntities: [],
    optionalEntities: ['paymentAmount', 'sender', 'paymentMethod']
  },
  'finance.payment.scam-alert': {
    category: 'finance',
    subCategory: 'payment',
    action: 'scam-alert',
    description: 'Payment scam alert or fraud education',
    triggers: [
      'payment scam',
      'scams you need',
      'fraud alert',
      'protect yourself',
      'scam alert',
      'payment fraud',
      'avoid scams',
      'common scams'
    ],
    requiredEntities: [],
    optionalEntities: []
  },

  // SUBSCRIPTION MANAGEMENT
  'subscription.trial.ending': {
    category: 'subscription',
    subCategory: 'trial',
    action: 'ending',
    description: 'Free trial ending soon',
    triggers: [
      'trial ending',
      'trial expires',
      'trial period',
      'free trial ends',
      'trial ending soon',
      'trial will end',
      'end of trial',
      'last day of trial'
    ],
    requiredEntities: ['expirationDate'],
    optionalEntities: ['serviceName', 'upgradeUrl']
  },
  'subscription.cancellation.confirmation': {
    category: 'subscription',
    subCategory: 'cancellation',
    action: 'confirmation',
    description: 'Subscription cancelled confirmation',
    triggers: [
      'subscription cancelled',
      'subscription canceled',
      'cancellation confirmed',
      'service ended',
      'membership cancelled',
      'canceled your subscription',
      'subscription has ended',
      'no longer subscribed'
    ],
    requiredEntities: ['serviceName'],
    optionalEntities: ['cancellationDate', 'refundAmount']
  },
  'subscription.upgrade.offer': {
    category: 'subscription',
    subCategory: 'upgrade',
    action: 'offer',
    description: 'Upgrade or premium offer',
    triggers: [
      'upgrade offer',
      'upgrade to premium',
      'unlock features',
      'premium features',
      'upgrade now',
      'special offer',
      'upgrade your plan',
      'premium subscription'
    ],
    requiredEntities: ['serviceName'],
    optionalEntities: ['discount', 'offerExpiration', 'upgradeUrl']
  },
  'subscription.usage.limit': {
    category: 'subscription',
    subCategory: 'usage',
    action: 'limit',
    description: 'Usage limit or quota reached',
    triggers: [
      'usage limit',
      'quota reached',
      'limit exceeded',
      'reached your limit',
      'storage full',
      'usage threshold',
      'approaching limit',
      'exceeded quota'
    ],
    requiredEntities: ['serviceName'],
    optionalEntities: ['currentUsage', 'maxUsage', 'upgradeUrl']
  },
  'subscription.anniversary.notification': {
    category: 'subscription',
    subCategory: 'anniversary',
    action: 'notification',
    description: 'Subscription anniversary or milestone',
    triggers: [
      'anniversary',
      'been with us for',
      'member since',
      'years as a member',
      'months subscribed',
      'loyalty reward',
      'membership milestone',
      'thank you for'
    ],
    requiredEntities: ['serviceName'],
    optionalEntities: ['membershipDuration', 'rewardUrl']
  },
  'subscription.feature.update': {
    category: 'subscription',
    subCategory: 'feature',
    action: 'update',
    description: 'Subscription feature updates and perks',
    triggers: [
      'new features',
      'trial',
      'your trial',
      'membership',
      'extras included',
      'just got',
      'now includes',
      'features for',
      'even more awesome',
      'upgrade',
      'explore all the',
      'missing the best',
      'features you',
      'all the features'
    ],
    requiredEntities: [],
    optionalEntities: ['subscriptionService', 'features']
  },
  'account.device.login': {
    category: 'account',
    subCategory: 'device',
    action: 'login',
    description: 'New device login notification',
    triggers: [
      'new device',
      'signed in',
      'login from',
      'new sign-in',
      'unusual activity',
      'logged in from',
      'device is signed',
      'a new device',
      'signed in to your'
    ],
    requiredEntities: [],
    optionalEntities: ['device', 'location', 'ipAddress']
  },
  'finance.credit.available': {
    category: 'finance',
    subCategory: 'credit',
    action: 'available',
    description: 'Credit availability and offers',
    triggers: [
      'credit available',
      'available to spend',
      'credit limit',
      'pre-approved',
      'line of credit',
      'confirmed:',
      'remember you have',
      'you have $',
      'spending power'
    ],
    requiredEntities: [],
    optionalEntities: ['creditAmount', 'lender']
  },
  'account.payment.expiration': {
    category: 'account',
    subCategory: 'payment',
    action: 'expiration',
    description: 'Payment method expiring soon',
    triggers: [
      'card is about to expire',
      'card about to expire',
      'payment method expiring',
      'update payment method',
      'card expires',
      'card will expire',
      'payment expiring',
      'update your card',
      'card expiration',
      'expiring soon'
    ],
    requiredEntities: [],
    optionalEntities: ['expirationDate', 'serviceName', 'cardLast4']
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
  'education.lms.message': {
    category: 'education',
    subCategory: 'lms',
    action: 'message',
    description: 'Message from teacher via Learning Management System',
    triggers: [
      'sent you a message in canvas',
      'sent you a message',
      'commented on your submission',
      'replied to your',
      'new comment in',
      'google classroom',
      'schoology',
      'posted a new assignment',
      'returned your work',
      'canvas notification'
    ],
    requiredEntities: ['teacher', 'messageUrl'],
    optionalEntities: ['subject', 'course', 'platform']
  },
  'education.lms.assignment-posted': {
    category: 'education',
    subCategory: 'lms',
    action: 'assignment-posted',
    description: 'New assignment posted in LMS',
    triggers: [
      'new assignment',
      'assignment posted',
      'posted an assignment',
      'assignment is due',
      'upcoming assignment',
      'assignment due date'
    ],
    requiredEntities: ['assignment', 'assignmentUrl'],
    optionalEntities: ['dueDate', 'course', 'teacher']
  },
  'education.event.invitation': {
    category: 'education',
    subCategory: 'event',
    action: 'invitation',
    description: 'School event or parent meeting invitation',
    triggers: [
      'parent-teacher conference',
      'open house',
      'pta meeting',
      'pto meeting',
      'school event',
      'back to school night',
      'curriculum night',
      'parent night',
      'school meeting',
      'meet the teacher'
    ],
    requiredEntities: ['event', 'dateTime'],
    optionalEntities: ['location', 'rsvpUrl', 'teacher']
  },
  'education.parent.teacher-communication': {
    category: 'education',
    subCategory: 'parent',
    action: 'teacher-communication',
    description: 'Direct teacher-parent correspondence',
    triggers: [
      'classroom update',
      'weekly newsletter',
      'your child',
      'your son',
      'your daughter',
      'homework',
      'classwork',
      'behavior',
      'student progress',
      'from your teacher'
    ],
    requiredEntities: ['teacher'],
    optionalEntities: ['subject', 'class', 'studentName']
  },
  'education.activity.announcement': {
    category: 'education',
    subCategory: 'activity',
    action: 'announcement',
    description: 'Educational activity or workshop announcement',
    triggers: [
      'new activity',
      'museum activity',
      'kids activity',
      'family activity',
      'hands-on activity',
      'educational activity',
      'workshop',
      'make',
      'create',
      'build',
      'explore',
      'learn how to',
      'science activity',
      'stem activity',
      'diy activity'
    ],
    requiredEntities: [],
    optionalEntities: ['activityName', 'venue', 'date', 'ageGroup', 'registrationUrl']
  },
  'youth.sports.registration': {
    category: 'youth',
    subCategory: 'sports',
    action: 'registration',
    description: 'Youth sports or activity registration',
    triggers: [
      'registration',
      'sign up',
      'tryouts',
      'enroll',
      'registration opens',
      'register now',
      'registration deadline',
      'sign up now',
      'team registration',
      'season registration'
    ],
    requiredEntities: ['sport', 'registrationUrl'],
    optionalEntities: ['organization', 'deadline', 'cost', 'ageGroup']
  },
  'youth.sports.game-schedule': {
    category: 'youth',
    subCategory: 'sports',
    action: 'game-schedule',
    description: 'Game schedule notification',
    triggers: [
      'game schedule',
      'match schedule',
      'tournament',
      'game day',
      'next game',
      'opponent',
      'game time',
      'schedule update',
      'season schedule'
    ],
    requiredEntities: ['sport', 'dateTime'],
    optionalEntities: ['location', 'opponent', 'scheduleUrl']
  },
  'youth.sports.practice-reminder': {
    category: 'youth',
    subCategory: 'sports',
    action: 'practice-reminder',
    description: 'Practice reminder',
    triggers: [
      'practice',
      'training',
      'scrimmage',
      'practice schedule',
      'practice today',
      'practice tomorrow',
      'practice time',
      'practice location'
    ],
    requiredEntities: ['sport', 'dateTime'],
    optionalEntities: ['location', 'duration', 'rsvpUrl']
  },
  'youth.sports.team-announcement': {
    category: 'youth',
    subCategory: 'sports',
    action: 'team-announcement',
    description: 'Team announcement',
    triggers: [
      'team update',
      'roster',
      'uniform',
      'equipment',
      'team announcement',
      'coach message',
      'team news',
      'important update',
      'little league',
      'milb opportunities',
      'youth baseball',
      'little leaguer',
      'little league opportunities',
      'baseball opportunities',
      'youth sports opportunities',
      'check out these',
      'opportunities for your'
    ],
    requiredEntities: ['sport', 'team'],
    optionalEntities: ['message', 'coach']
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
    negativePatterns: ['cancelled', 'canceled', 'rescheduled', 'no longer needed', 'confirmed', 'confirmation', 'scheduled for', 'booking confirmed', 'schedule your', 'book your', 'time to schedule', 'please schedule', 'schedule now', 'book now', 'make an appointment', 'schedule online', 'book online', 'due for', 'time for your'],
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
  'healthcare.appointment.confirmation': {
    category: 'healthcare',
    subCategory: 'appointment',
    action: 'confirmation',
    description: 'Medical appointment confirmation',
    triggers: [
      'appointment confirmed',
      'appointment scheduled',
      'scheduled for',
      'see you on',
      'booking confirmed',
      'appointment booked',
      'confirmed with dr',
      'confirmed with doctor'
    ],
    requiredEntities: ['dateTime', 'provider'],
    optionalEntities: ['location', 'specialty', 'confirmationCode']
  },
  'healthcare.appointment.cancellation': {
    category: 'healthcare',
    subCategory: 'appointment',
    action: 'cancellation',
    description: 'Medical appointment cancelled',
    triggers: [
      'appointment cancelled',
      'appointment canceled',
      'visit cancelled',
      'visit canceled',
      'rescheduling required',
      'cancelled your appointment',
      'canceled your appointment',
      'no longer scheduled',
      'appointment has been cancelled'
    ],
    requiredEntities: ['dateTime'],
    optionalEntities: ['provider', 'reason', 'rescheduleUrl']
  },
  'healthcare.appointment.booking-request': {
    category: 'healthcare',
    subCategory: 'appointment',
    action: 'booking-request',
    description: 'Request to schedule or book new appointment',
    triggers: [
      'schedule your appointment',
      'schedule an appointment',
      'book your appointment',
      'book an appointment',
      'time to schedule',
      'please schedule',
      'schedule your visit',
      'book your visit',
      'schedule now',
      'book now',
      'time for your annual',
      'due for your',
      'schedule your checkup',
      'schedule your physical',
      'book your checkup',
      'make an appointment',
      'schedule online',
      'book online',
      'request an appointment',
      'available appointments',
      'schedule a visit',
      'need to schedule',               // NEW
      'ready to schedule',              // NEW
      'click to schedule',              // NEW
      'call to schedule',               // NEW
      'visit us online to schedule',    // NEW
      'schedule your next',             // NEW
      'time for your next',             // NEW
      'overdue for',                    // NEW
      'appointments available'          // NEW
    ],
    negativePatterns: ['confirmed', 'confirmation', 'scheduled for', 'appointment with', 'appointment on', 'see you on', 'reminder', 'upcoming', 'tomorrow', 'today', 'please arrive', 'bring insurance', 'check-in', 'your appointment is', 'appointment reminder'],
    requiredEntities: [],
    optionalEntities: ['provider', 'specialty', 'schedulingUrl', 'deadline']
  },
  'healthcare.referral.request': {
    category: 'healthcare',
    subCategory: 'referral',
    action: 'request',
    description: 'Medical referral to specialist',
    triggers: [
      'referral to specialist',
      'see a specialist',
      'referral form',
      'specialist referral',
      'referred you to',
      'consult with',
      'refer you to a',
      'specialist appointment'
    ],
    requiredEntities: ['specialistType'],
    optionalEntities: ['provider', 'referralCode', 'specialistName']
  },
  'healthcare.insurance.claim': {
    category: 'healthcare',
    subCategory: 'insurance',
    action: 'claim',
    description: 'Insurance claim status update',
    triggers: [
      'claim submitted',
      'claim approved',
      'claim denied',
      'eob available',
      'explanation of benefits',
      'insurance claim',
      'claim processed',
      'claim status',
      'claim update'
    ],
    requiredEntities: ['claimNumber'],
    optionalEntities: ['claimAmount', 'claimStatus', 'provider']
  },
  'healthcare.test.order': {
    category: 'healthcare',
    subCategory: 'test',
    action: 'order',
    description: 'Medical test or lab work scheduled',
    triggers: [
      'lab test scheduled',
      'lab test',
      'imaging scheduled',
      'bloodwork required',
      'test appointment',
      'lab appointment',
      'x-ray scheduled',
      'mri scheduled',
      'scan scheduled',
      'blood draw',
      'lab order',
      'diagnostic test',
      'medical test',
      'lab work',
      'ct scan',
      'ultrasound',
      'blood test',
      'urine test',
      'fasting required',
      'lab requisition'
    ],
    requiredEntities: ['testType'],
    optionalEntities: ['dateTime', 'location', 'preparationInstructions']
  },
  'healthcare.follow-up.reminder': {
    category: 'healthcare',
    subCategory: 'follow-up',
    action: 'reminder',
    description: 'Follow-up appointment reminder',
    triggers: [
      'follow up appointment',
      'follow-up required',
      'follow up with',
      'check back with',
      'schedule follow-up',
      'follow-up visit',
      'return visit',
      'follow up in'
    ],
    requiredEntities: ['dateTime'],
    optionalEntities: ['provider', 'reason', 'schedulingUrl']
  },

  // TRAVEL
  'travel.flight.check-in': {
    category: 'travel',
    subCategory: 'flight',
    action: 'check-in',
    description: 'Flight check-in reminder',
    triggers: [
      'check-in',
      'check in',
      'check in for',
      'check in now',
      'check in for your flight',
      'flight reminder',
      'boarding pass',
      'mobile boarding',
      'gate',
      'flight to',
      'departure',
      'time to check in',
      'ready to check in',
      'checking in'
    ],
    requiredEntities: [],
    optionalEntities: ['flightNumber', 'departureDate', 'confirmationCode', 'checkInUrl']
  },
  'travel.reservation.confirmation': {
    category: 'travel',
    subCategory: 'reservation',
    action: 'confirmation',
    description: 'Hotel, flight, or car reservation',
    triggers: ['reservation confirmed', 'booking confirmed', 'itinerary'],
    negativePatterns: ['restaurant', 'table', 'party of', 'opentable', 'resy', 'dinner', 'dining', 'meal', 'menu', 'cuisine'],
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
      'your table',
      'party of',
      'restaurant reservation',
      'dinner reservation',
      'table for',
      'dining reservation',
      'opentable',
      'resy',
      'reservation at',
      'booked a table',
      'restaurant confirmed',
      'table reservation',
      'looking forward to seeing you',
      'reservation confirmed'
    ],
    negativePatterns: ['hotel', 'flight', 'car rental', 'itinerary', 'check-in', 'check in'],
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
      'dasher',
      'doordash',
      'uber eats',
      'grubhub',
      'postmates',
      'driver is',
      'courier is',
      'preparing your order',
      'minutes away',
      'order is being prepared',
      'food delivery',
      'restaurant order',
      'delivery driver',
      'your order from'
    ],
    negativePatterns: ['tracking number', 'ups', 'fedex', 'usps', 'shipment', 'package'],
    requiredEntities: ['restaurant', 'eta'],
    optionalEntities: ['driver', 'orderNumber', 'trackingUrl']
  },
  'delivery.tracking.alert': {
    category: 'delivery',
    subCategory: 'tracking',
    action: 'alert',
    description: 'Package delivery alert and tracking update',
    triggers: [
      'delivery status update',
      'my choice',
      'ups my choice',
      'package alert',
      'delivery alert',
      'package notification',
      'delivery notification',
      'tracking update',
      'shipment alert',
      'package arriving',
      'delivery approaching',
      'expected delivery',
      'delivery window',
      'delivery preferences'
    ],
    requiredEntities: [],
    optionalEntities: ['trackingNumber', 'carrier', 'eta', 'deliveryDate', 'preferencesUrl']
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
      'buy now',
      '$ off',
      'dollars off',
      'off orders over',
      'bogo',
      'buy one get one',
      'rules!',
      'deals!',
      'carryout',
      'welcome back',
      'rules',
      'off order',
      'orders over'
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
  'marketing.loyalty.reward': {
    category: 'marketing',
    subCategory: 'loyalty',
    action: 'reward',
    description: 'Loyalty points or rewards notification',
    triggers: [
      'reward points',
      'loyalty points',
      'points earned',
      'redeem points',
      'rewards balance',
      'cashback available',
      'rewards available',
      'points expire',
      'vip member',
      'exclusive access',
      // Enhanced Phase 3C+ triggers
      '+', 'reward', 'your $', 'earn', 'points',
      'loyalty', 'member exclusive', 'vip'
    ],
    requiredEntities: [],
    optionalEntities: ['pointsBalance', 'expirationDate', 'rewardUrl']
  },
  'marketing.brand.announcement': {
    category: 'marketing',
    subCategory: 'brand',
    action: 'announcement',
    description: 'Brand news or company announcement',
    triggers: [
      'announcing',
      'exciting news',
      'we\'re thrilled',
      'new collaboration',
      'partnership',
      'brand update',
      'company news',
      'press release',
      'big announcement',
      'proud to announce'
    ],
    requiredEntities: [],
    optionalEntities: ['announcementUrl', 'topic']
  },
  'marketing.collection.new-arrivals': {
    category: 'marketing',
    subCategory: 'collection',
    action: 'new-arrivals',
    description: 'New product collections and arrivals',
    triggers: [
      'new arrivals',
      'just dropped',
      'just launched',
      'new collection',
      'latest collection',
      'fall edit',
      'summer collection',
      'winter collection',
      'spring collection',
      'now available',
      'has arrived',
      'fresh picks',
      'new styles',
      'latest styles'
    ],
    requiredEntities: [],
    optionalEntities: ['collectionName', 'productUrl']
  },
  'marketing.seasonal.campaign': {
    category: 'marketing',
    subCategory: 'seasonal',
    action: 'campaign',
    description: 'Seasonal marketing campaigns',
    triggers: [
      'fall',
      'summer',
      'winter',
      'spring',
      'seasonal',
      'harvest',
      'back to school',
      'holiday',
      'mother\'s day',
      'father\'s day',
      'halloween',
      'thanksgiving',
      'christmas',
      'valentine',
      'season\'s',
      'seasonal edit'
    ],
    requiredEntities: [],
    optionalEntities: ['season', 'productUrl']
  },
  'marketing.brand.storytelling': {
    category: 'marketing',
    subCategory: 'brand',
    action: 'storytelling',
    description: 'Brand storytelling and heritage',
    triggers: [
      'trusted by',
      'since 19',
      'return of',
      'founded',
      'heritage',
      'legacy',
      'meet',
      'introducing',
      'our story',
      'the story of',
      'history of',
      'est. 19',
      'celebrating',
      'tradition',
      'everything is new',
      'everything new',
      'all new',
      'the staples',
      'essentials',
      'grow.',
      'grow',
      'we think you',
      'you might like'
    ],
    requiredEntities: [],
    optionalEntities: ['brandName', 'storyUrl']
  },
  'marketing.content.lifestyle': {
    category: 'marketing',
    subCategory: 'content',
    action: 'lifestyle',
    description: 'Lifestyle content and inspiration',
    triggers: [
      'tips',
      'guide',
      'how to',
      'inspiration',
      'ideas',
      'recipes',
      'design tip',
      'style guide',
      'get the look',
      'decorating',
      'entertaining',
      'lifestyle',
      'your guide to',
      'outfit forecast',
      'wear this',
      'wear next',
      'tomorrow\'s outfit',
      'fashion forecast',
      'style forecast',
      'what to wear'
    ],
    requiredEntities: [],
    optionalEntities: ['topicName', 'contentUrl']
  },
  'marketing.trending.popular': {
    category: 'marketing',
    subCategory: 'trending',
    action: 'popular',
    description: 'Trending products and bestsellers',
    triggers: [
      'trending',
      'hottest',
      'popular',
      'best sellers',
      'top picks',
      'most loved',
      'fan favorites',
      'customer favorites',
      'top rated',
      'best selling',
      'most popular',
      'everyone\'s loving'
    ],
    requiredEntities: [],
    optionalEntities: ['productName', 'productUrl']
  },
  'marketing.home-decor.products': {
    category: 'marketing',
    subCategory: 'home-decor',
    action: 'products',
    description: 'Home decor and furnishing products',
    triggers: [
      'roller shade',
      'window treatments',
      'home decor',
      'furniture',
      'chic',
      'materials',
      'shade materials',
      'interior design',
      'home furnishing',
      'decor ideas'
    ],
    requiredEntities: [],
    optionalEntities: ['productName', 'productUrl', 'style']
  },
  'social.content.recommendation': {
    category: 'social',
    subCategory: 'content',
    action: 'recommendation',
    description: 'Social platform content recommendations',
    triggers: [
      'we think you might like',
      'pins for you',
      'recommended for you',
      'you might like these',
      'based on your interests',
      'personalized recommendations',
      'picked for you',
      'suggested pins',
      'suggested posts'
    ],
    requiredEntities: [],
    optionalEntities: ['platform', 'contentType', 'recommendationsUrl']
  },

  // SHOPPING & FUTURE PURCHASES
  'shopping.product.future-sale': {
    category: 'shopping',
    subCategory: 'product',
    action: 'future-sale',
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
  'civic.voting.registration': {
    category: 'civic',
    subCategory: 'voting',
    action: 'registration',
    description: 'Voter registration reminder',
    triggers: [
      'register to vote',
      'voter registration',
      'election registration',
      'register by',
      'voter deadline',
      'registration deadline',
      'register now',
      'voting registration'
    ],
    requiredEntities: ['deadline'],
    optionalEntities: ['electionDate', 'registrationUrl']
  },
  'civic.license.renewal': {
    category: 'civic',
    subCategory: 'license',
    action: 'renewal',
    description: 'Driver\'s license or ID renewal',
    triggers: [
      'license renewal',
      'renew your license',
      'license expires',
      'driver license renewal',
      'id renewal',
      'renew by',
      'license expiration',
      'renewal notice'
    ],
    requiredEntities: ['expirationDate'],
    optionalEntities: ['licenseNumber', 'renewalUrl']
  },
  'civic.tax.assessment': {
    category: 'civic',
    subCategory: 'tax',
    action: 'assessment',
    description: 'Property tax assessment or bill',
    triggers: [
      'property tax',
      'tax assessment',
      'assessed value',
      'tax bill',
      'property tax due',
      'tax assessment notice',
      'annual property tax',
      'tax statement'
    ],
    requiredEntities: ['amountDue'],
    optionalEntities: ['dueDate', 'propertyAddress', 'assessedValue']
  },
  'civic.permit.application': {
    category: 'civic',
    subCategory: 'permit',
    action: 'application',
    description: 'Permit application status or requirement',
    triggers: [
      'permit application',
      'permit required',
      'building permit',
      'permit status',
      'permit approved',
      'permit denied',
      'permit number',
      'application submitted'
    ],
    requiredEntities: ['permitType'],
    optionalEntities: ['permitNumber', 'applicationStatus', 'approvalDate']
  },
  'civic.court.notice': {
    category: 'civic',
    subCategory: 'court',
    action: 'notice',
    description: 'Court appearance or legal notice',
    triggers: [
      'court appearance',
      'court date',
      'jury duty',
      'court notice',
      'legal notice',
      'appear in court',
      'court hearing',
      'scheduled hearing'
    ],
    requiredEntities: ['dateTime'],
    optionalEntities: ['caseNumber', 'location', 'courtroom']
  },
  'civic.ballot.information': {
    category: 'civic',
    subCategory: 'ballot',
    action: 'information',
    description: 'Ballot information or voting guide',
    triggers: [
      'ballot information',
      'voting guide',
      'election day',
      'sample ballot',
      'ballot measures',
      'candidates',
      'voter guide',
      'election information'
    ],
    requiredEntities: ['electionDate'],
    optionalEntities: ['pollingLocation', 'guideUrl']
  },
  'civic.donation.request': {
    category: 'civic',
    subCategory: 'donation',
    action: 'request',
    description: 'Political campaign donation request',
    triggers: [
      'donate',
      'donation',
      'contribute',
      'chip in',
      'asking for $',
      'asking you to donate',
      'campaign needs',
      'support our',
      'support my',
      'movement',
      'victory',
      'fight for',
      'join me',
      'stand with',
      'donate now',
      'urgent donation',
      'matching donations',
      'deadline approaching',
      'campaign fund'
    ],
    requiredEntities: [],
    optionalEntities: ['amount', 'deadline', 'candidate']
  },
  'utility.service.alert': {
    category: 'utility',
    subCategory: 'service',
    action: 'alert',
    description: 'Utility service alert or planned outage',
    triggers: [
      'power shutoff',
      'power outage',
      'planned outage',
      'service disruption',
      'public safety power shutoff',
      'psps',
      'high winds',
      'pge',
      'pg&e',
      'utility alert',
      'outage notification',
      'service interruption',
      'planned power shutoff'
    ],
    requiredEntities: [],
    optionalEntities: ['outageStart', 'outageEnd', 'affectedAreas', 'reason', 'provider']
  },

  // COMMUNICATION & CORRESPONDENCE
  'communication.thread.reply': {
    category: 'communication',
    subCategory: 'thread',
    action: 'reply',
    description: 'Email thread reply',
    triggers: [
      're:',
      'fwd:',
      'fw:',
      'reply',
      'forwarded message',
      'wrote:',
      'on ',
      'said:',
      '> ',
      'original message',
      'thanks for',
      'thank you for',
      'thanks,',
      'hi ',
      'hey ',
      'hello ',
      'great to hear',
      'good to hear',
      'sounds good',
      'that works',
      'let me know',
      'i\'ll',
      'we can',
      'looking forward',
      'from:',
      'sent:',
      'subject:',
      '------ forwarded'
    ],
    requiredEntities: [],
    optionalEntities: ['sender', 'subject']
  },
  'communication.introduction.connect': {
    category: 'communication',
    subCategory: 'introduction',
    action: 'connect',
    description: 'Professional introduction',
    triggers: [
      'meet',
      'meet ',
      'introduction',
      'intro',
      'connect you with',
      'would like to introduce',
      'i\'d like you to meet',
      'connecting you with',
      'please meet',
      'happy to introduce'
    ],
    requiredEntities: ['introducedPerson'],
    optionalEntities: ['context', 'reason']
  },
  'communication.professional.inquiry': {
    category: 'communication',
    subCategory: 'professional',
    action: 'inquiry',
    description: 'Business or professional inquiry',
    triggers: [
      'reaching out',
      'quick question',
      'wanted to ask',
      'wondering if',
      'would you be interested',
      'following up',
      'checking in',
      'touching base',
      'interested in discussing',
      'opportunity to'
    ],
    requiredEntities: [],
    optionalEntities: ['topic', 'company']
  },
  'communication.personal.message': {
    category: 'communication',
    subCategory: 'personal',
    action: 'message',
    description: 'Personal casual message from self or close contacts',
    triggers: [
      'done',
      'thanks',
      'got it',
      'ok',
      'sounds good',
      'test',
      'testing',
      'working'
    ],
    negativePatterns: ['lab test', 'medical test', 'blood test', 'test scheduled', 'diagnostic test', 'test appointment', 'lab', 'doctor', 'hospital', 'clinic', 'appointment', 'scheduled', 'imaging', 'x-ray', 'mri', 'ct scan', 'ultrasound', 'lab work'],
    requiredEntities: [],
    optionalEntities: []
  },
  'communication.personal.self-note': {
    category: 'communication',
    subCategory: 'personal',
    action: 'self-note',
    description: 'Self-sent email or note to self',
    triggers: [
      'note to self',
      'reminder:',
      'todo:',
      'self-sent',
      'note:',
      'reminder',
      'remember to',
      'don\'t forget',
      'for later',
      'save this'
    ],
    requiredEntities: [],
    optionalEntities: ['noteContent', 'tags']
  },

  // CAREER & RECRUITING
  'career.interview.invitation': {
    category: 'career',
    subCategory: 'interview',
    action: 'invitation',
    description: 'Interview invitation',
    triggers: [
      'interview',
      'schedule an interview',
      'interview opportunity',
      'meet with our team',
      'next steps in the hiring process',
      'phone screen',
      'interview request',
      'scheduling interview',
      'interview invitation',
      'video interview',
      // Enhanced patterns from corpus analysis
      'interview availability',
      'phone interview',
      'interview prep',
      'interview invite',
      'would like to interview',
      'set up a call',
      'chat about the',
      'discuss the role',
      'talk about the position',
      'schedule a call',
      'zoom interview',
      'teams interview',
      'onsite interview',
      'first round interview',
      'technical interview',
      'hiring manager',
      'meet with',
      'speak with you',
      'coordinate a time',
      'book a time',
      'calendar link',
      'calendly'
    ],
    requiredEntities: [],
    optionalEntities: ['company', 'position', 'dateTime', 'interviewType', 'interviewUrl', 'interviewer']
  },
  'career.job.offer': {
    category: 'career',
    subCategory: 'job',
    action: 'offer',
    description: 'Job offer received',
    triggers: [
      'offer letter',
      'job offer',
      'offer of employment',
      'pleased to offer',
      'extend an offer',
      'congratulations',
      'employment offer',
      'offer package',
      'compensation package',
      'welcome to the team'
    ],
    requiredEntities: ['company', 'position'],
    optionalEntities: ['salary', 'startDate', 'offerDeadline']
  },
  'career.recruiter.outreach': {
    category: 'career',
    subCategory: 'recruiter',
    action: 'outreach',
    description: 'Recruiter reaching out about opportunity',
    triggers: [
      'recruiting',
      'great opportunity',
      'your background',
      'your profile',
      'career opportunity',
      'may be interested',
      'looking for candidates',
      'headhunter',
      'talent acquisition',
      'hiring manager',
      'role that might interest you'
    ],
    requiredEntities: [],
    optionalEntities: ['company', 'position', 'recruiterName']
  },
  'career.application.status': {
    category: 'career',
    subCategory: 'application',
    action: 'status',
    description: 'Job application status update',
    triggers: [
      'application received',
      'application status',
      'under review',
      'thank you for applying',
      'received your application',
      'reviewing your application',
      'application update',
      'next steps',
      'hiring process'
    ],
    requiredEntities: ['company', 'position'],
    optionalEntities: ['applicationStatus', 'nextSteps']
  },
  'career.rejection.notice': {
    category: 'career',
    subCategory: 'rejection',
    action: 'notice',
    description: 'Job rejection or application declined',
    triggers: [
      'unfortunately',
      'not moving forward',
      'decided to pursue',
      'other candidates',
      'will not be moving',
      'regret to inform',
      'chosen to move forward with',
      'not selected',
      'appreciate your interest',
      'decided not to proceed'
    ],
    requiredEntities: ['company', 'position'],
    optionalEntities: ['reason', 'futureOpportunities']
  },
  'career.onboarding.information': {
    category: 'career',
    subCategory: 'onboarding',
    action: 'information',
    description: 'New hire onboarding information',
    triggers: [
      'first day',
      'first day information',
      'welcome to the team',
      'start date',
      'new hire',
      'onboarding',
      'employee handbook',
      'orientation',
      'first week',
      'reporting to'
    ],
    requiredEntities: ['company'],
    optionalEntities: ['startDate', 'location', 'contactPerson']
  },

  // PROFESSIONAL SERVICES
  'finance.mortgage.communication': {
    category: 'finance',
    subCategory: 'mortgage',
    action: 'communication',
    description: 'Mortgage or refinancing communication',
    triggers: [
      'mortgage',
      'refi',
      'refinance',
      'refinancing',
      'home loan',
      'mortgage rate',
      'pre-approval',
      'loan approval',
      'closing date',
      'mortgage options',
      // Enhanced from corpus
      'refi options',
      'mortgage approval',
      'mortgage application',
      'loan estimate',
      'appraisal',
      'title company',
      'escrow',
      'closing disclosure',
      'mortgage broker',
      'lender',
      'interest rate',
      'down payment',
      'mortgage payment',
      'home buying',
      'home purchase',
      'mortgage pre-qual',
      'credit score',
      'debt-to-income',
      'mortgage documents'
    ],
    requiredEntities: [],
    optionalEntities: ['lender', 'rate', 'amount', 'closingDate']
  },
  'finance.utility.bill': {
    category: 'finance',
    subCategory: 'utility',
    action: 'bill',
    description: 'Utility bill notification',
    triggers: [
      'utility bill',
      'electric bill',
      'gas bill',
      'water bill',
      'bill is ready',
      'your new bill',
      'monthly bill',
      'pse&g',
      'bill ready to view',
      'account balance'
    ],
    requiredEntities: [],
    optionalEntities: ['amountDue', 'dueDate', 'provider']
  },
  'legal.document.communication': {
    category: 'legal',
    subCategory: 'document',
    action: 'communication',
    description: 'Legal documents and communications',
    triggers: [
      'mediation',
      'legal',
      'attorney',
      'lawyer',
      'contract',
      'agreement',
      'legal notice',
      'settlement',
      'divorce',
      'custody',
      // Enhanced from corpus
      'mediation session',
      'arbitration',
      'legal counsel',
      'law firm',
      'litigation',
      'deposition',
      'hearing',
      'court date',
      'legal matter',
      'legal representation',
      'retainer',
      'legal fees',
      'case number',
      'docket',
      'summons',
      'subpoena',
      'discovery',
      'plaintiff',
      'defendant',
      'legal action'
    ],
    requiredEntities: [],
    optionalEntities: ['attorney', 'caseNumber', 'deadline']
  },
  'real-estate.service.communication': {
    category: 'real-estate',
    subCategory: 'service',
    action: 'communication',
    description: 'Real estate services and inspections',
    triggers: [
      'home inspection',
      'inspection',
      'real estate',
      'property',
      'listing',
      'open house',
      'showing',
      'appraisal',
      'closing',
      'escrow'
    ],
    requiredEntities: [],
    optionalEntities: ['property', 'agent', 'date', 'location']
  },
  'real-estate.recommendation.listing': {
    category: 'real-estate',
    subCategory: 'recommendation',
    action: 'listing',
    description: 'Recommended property listings',
    triggers: [
      'recommended homes',
      'homes for you',
      'properties you might like',
      'new listings',
      'properties matching',
      'homes matching',
      'zillow',
      'redfin',
      'realtor.com',
      'trulia',
      'property recommendations'
    ],
    requiredEntities: [],
    optionalEntities: ['propertyCount', 'location', 'priceRange', 'listingsUrl']
  },

  // SOCIAL & PLATFORM NOTIFICATIONS
  'social.notification.message': {
    category: 'social',
    subCategory: 'notification',
    action: 'message',
    description: 'Social platform notifications and messages',
    triggers: [
      'sent you a message',
      'mentioned you',
      'you were mentioned',
      'tagged you',
      'you were tagged',
      'posted new',
      'new videos',
      'new posts',
      'posted',
      'shared a',
      'shared',
      'commented on',
      'liked your',
      'followed you',
      'new follower',
      'started following',
      'linkedin',
      'discord',
      'slack',
      'tiktok',
      'facebook',
      'instagram',
      'twitter',
      'connection request',
      'new message from',
      'message from',
      'notification from',
      'activity on'
    ],
    requiredEntities: [],
    optionalEntities: ['platform', 'sender', 'messageUrl']
  },
  'social.notification.kudos': {
    category: 'social',
    subCategory: 'notification',
    action: 'kudos',
    description: 'Social kudos or appreciation notification',
    triggers: [
      'gave you kudos',
      'kudos from',
      'liked your activity',
      'kudos on your',
      'gave kudos to',
      'strava kudos',
      'activity kudos',
      'ride kudos',
      'run kudos',
      'workout kudos'
    ],
    requiredEntities: [],
    optionalEntities: ['sender', 'activityType', 'activityUrl', 'platform']
  },
  'social.verification.required': {
    category: 'social',
    subCategory: 'verification',
    action: 'required',
    description: 'Social platform account verification',
    triggers: [
      'verify your account',
      'email verification',
      'confirm your email',
      'verify email address',
      'roblox',
      'gaming account',
      'verify account',
      'activation required'
    ],
    requiredEntities: ['platform'],
    optionalEntities: ['verificationLink', 'username']
  },
  'social.invitation.request': {
    category: 'social',
    subCategory: 'invitation',
    action: 'request',
    description: 'Social platform invitations',
    triggers: [
      'invited you to',
      'join',
      'invitation to join',
      'wants to connect',
      'sent you an invitation',
      'team invitation',
      'workspace invitation',
      'group invitation'
    ],
    requiredEntities: [],
    optionalEntities: ['platform', 'inviter', 'invitationLink']
  },
  'community.post.notification': {
    category: 'community',
    subCategory: 'post',
    action: 'notification',
    description: 'Community or neighborhood post notification',
    triggers: [
      'top post:',
      'popular post',
      'trending in your neighborhood',
      'nextdoor',
      'community post',
      'neighborhood post',
      'local post',
      'post from your neighbor',
      'new post in',
      'community update'
    ],
    requiredEntities: [],
    optionalEntities: ['postTitle', 'author', 'postUrl', 'category']
  },

  // PET SERVICES
  'pets.service.grooming': {
    category: 'pets',
    subCategory: 'service',
    action: 'grooming',
    description: 'Pet grooming and care services',
    triggers: [
      'grooming',
      'pet grooming',
      'nail trims',
      'nail trim',
      'bath',
      'haircut',
      'pet spa',
      'grooming appointment',
      'dog grooming',
      'cat grooming',
      'pet care'
    ],
    requiredEntities: [],
    optionalEntities: ['petName', 'serviceDate', 'serviceName']
  },
  'pets.content.tips': {
    category: 'pets',
    subCategory: 'content',
    action: 'tips',
    description: 'Pet care tips and advice',
    triggers: [
      'pet tips',
      'pet care',
      'dog tips',
      'cat tips',
      'pet health',
      'pet advice',
      'caring for your pet',
      'pet wellness',
      'pet nutrition'
    ],
    requiredEntities: [],
    optionalEntities: ['topic', 'contentUrl']
  },

  // CONTENT & NEWSLETTERS
  'content.newsletter.gaming': {
    category: 'content',
    subCategory: 'newsletter',
    action: 'gaming',
    description: 'Gaming news and announcements',
    triggers: [
      'game announcements',
      'new games',
      'gaming news',
      'nintendo',
      'playstation',
      'xbox',
      'steam',
      'game releases',
      'gaming',
      'game updates',
      'video games',
      'esports',
      'new game'
    ],
    requiredEntities: [],
    optionalEntities: ['gameName', 'platform', 'newsUrl']
  },
  'content.newsletter.sports': {
    category: 'content',
    subCategory: 'newsletter',
    action: 'sports',
    description: 'Sports news and updates',
    triggers: [
      'mlb',
      'nfl',
      'nba',
      'nhl',
      'free agency',
      'trade',
      'roster',
      'game recap',
      'electrifies',
      'sports',
      'athletic',
      'score',
      'playoff',
      'championship',
      'season',
      'highlights'
    ],
    requiredEntities: [],
    optionalEntities: ['sport', 'team', 'newsUrl']
  },
  'content.newsletter.entertainment': {
    category: 'content',
    subCategory: 'newsletter',
    action: 'entertainment',
    description: 'Entertainment and content newsletters',
    triggers: [
      'stories of the week',
      'this week in',
      'top stories',
      'what to watch',
      'weekly roundup',
      'favorite stories',
      'sunday schedule',
      'packed schedule',
      'watch now',
      'streaming',
      'new episode',
      'season premiere'
    ],
    requiredEntities: [],
    optionalEntities: ['showName', 'contentUrl']
  },
  'content.newsletter.career': {
    category: 'content',
    subCategory: 'newsletter',
    action: 'career',
    description: 'Job alerts and career newsletters',
    triggers: [
      'jobs posted',
      'new jobs',
      'job alert',
      'career opportunities',
      'resume',
      'hired',
      'career',
      'job search',
      'openings',
      'positions available',
      'now hiring'
    ],
    requiredEntities: [],
    optionalEntities: ['jobTitle', 'company', 'jobUrl']
  },
  'content.newsletter.tech': {
    category: 'content',
    subCategory: 'newsletter',
    action: 'tech',
    description: 'Technology news and updates',
    triggers: [
      'tech news',
      'technology',
      'software update',
      'hardware',
      'gadgets',
      'innovation',
      'startup',
      'ai news',
      'crypto',
      'blockchain',
      'tech industry'
    ],
    requiredEntities: [],
    optionalEntities: ['topic', 'newsUrl']
  },
  'content.newsletter.finance': {
    category: 'content',
    subCategory: 'newsletter',
    action: 'finance',
    description: 'Finance and market news',
    triggers: [
      'market news',
      'stock market',
      'financial news',
      'investing',
      'market update',
      'trading',
      'economy',
      'finance news',
      'market analysis',
      'stocks'
    ],
    requiredEntities: [],
    optionalEntities: ['topic', 'newsUrl']
  },
  'content.newsletter.lifestyle': {
    category: 'content',
    subCategory: 'newsletter',
    action: 'lifestyle',
    description: 'Lifestyle and wellness newsletters',
    triggers: [
      'lifestyle',
      'wellness',
      'health tips',
      'self care',
      'mindfulness',
      'fitness',
      'nutrition',
      'lifestyle tips',
      'wellbeing',
      'healthy living'
    ],
    requiredEntities: [],
    optionalEntities: ['topic', 'contentUrl']
  },

  // GENERIC/FALLBACK
  'generic.transactional.notification': {
    category: 'generic',
    subCategory: 'transactional',
    action: 'notification',
    description: 'Generic transactional email',
    triggers: [],
    requiredEntities: [],
    optionalEntities: []
  },
  'generic.newsletter.content': {
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
  'ViewAction': 'generic.transactional.notification',
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

