require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const logger = require('./shared/config/logger');
const EmailCard = require('./EmailCard');
const { classifyEmailEnhanced } = require('./enhanced-classifier');
const { classifyEmailActionFirst } = require('./action-first-classifier');
const { classifyEmailMock, getAllTemplateIds } = require('./mock-classifier');
const { enrichWithThreadFinder, isThreadFinderEnabled } = require('./thread-finder-middleware');

const app = express();
const PORT = process.env.PORT || process.env.CLASSIFIER_SERVICE_PORT || 8082;
const USE_ENHANCED_CLASSIFIER = process.env.USE_ENHANCED_CLASSIFIER !== 'false'; // Default to enhanced
const USE_ACTION_FIRST = process.env.USE_ACTION_FIRST === 'true'; // v1.1 action-first model

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// IP Theft Protection: Request logging and monitoring
const requestLogger = require('../../shared/middleware/request-logger');
app.use(requestLogger('classifier-service'));

// Health check
app.get('/health', (req, res) => {
  // Check Thread Finder configuration
  const threadFinderStatus = {
    enabled: process.env.USE_THREAD_FINDER === 'true',
    steelApiConfigured: !!process.env.STEEL_API_KEY,
    canvasApiConfigured: !!process.env.CANVAS_API_TOKEN,
    googleClassroomConfigured: !!process.env.GOOGLE_CLASSROOM_TOKEN,
    apiFirstStrategy: {
      canvas: !!process.env.CANVAS_API_TOKEN,
      googleClassroom: !!process.env.GOOGLE_CLASSROOM_TOKEN,
      steelFallback: !!process.env.STEEL_API_KEY
    }
  };

  res.json({
    status: 'ok',
    service: 'classifier-service',
    timestamp: new Date().toISOString(),
    threadFinder: threadFinderStatus
  });
});

/**
 * POST /api/classify
 * Classify email into archetype (uses enhanced classifier by default)
 */
app.post('/api/classify', async (req, res) => {
  const startTime = Date.now();

  try {
    // Validate request body exists and is an object
    if (!req.body || typeof req.body !== 'object') {
      logger.error('Invalid request body', { body: req.body });
      return res.status(400).json({ error: 'Invalid request: body must be a JSON object' });
    }

    const { email } = req.body;

    // Validate email object
    if (!email) {
      logger.error('Missing email object in request', { body: req.body });
      return res.status(400).json({ error: 'Missing email object in request body' });
    }

    if (typeof email !== 'object') {
      logger.error('Email must be an object', { email, type: typeof email });
      return res.status(400).json({ error: 'Email must be an object' });
    }

    if (!email.subject || !email.from) {
      logger.error('Invalid email data: missing required fields', {
        hasSubject: !!email.subject,
        hasFrom: !!email.from
      });
      return res.status(400).json({ error: 'Invalid email data: subject and from are required' });
    }

    logger.info('Classifying email', {
      subject: email.subject,
      enhanced: USE_ENHANCED_CLASSIFIER,
      actionFirst: USE_ACTION_FIRST
    });

    // Use action-first classifier (v1.1) if enabled, otherwise fall back to enhanced or basic
    let classification;
    if (USE_ACTION_FIRST) {
      classification = await classifyEmailActionFirst(email); // Now async for secondary classifier
      logger.info('Using ACTION-FIRST classifier (v1.1)', { intent: classification.intent });
    } else if (USE_ENHANCED_CLASSIFIER) {
      classification = classifyEmailEnhanced(email);
    } else {
      classification = classifyEmail(email);
    }

    // THREAD FINDER: Enrich link-only emails with extracted content
    if (isThreadFinderEnabled()) {
      classification = await enrichWithThreadFinder(classification, email);
    }

    // TELEMETRY: Log classification metrics
    const processingTimeMs = Date.now() - startTime;
    const emailDomain = email.from.includes('@') ? email.from.split('@')[1].replace(/[<>]/g, '') : 'unknown';
    const isFallback = classification.intent === 'generic.transactional' ||
                       classification.type === 'generic' ||
                       !classification.intent;

    logger.info('Classification complete', {
      intent: classification.intent || classification.type,
      intentConfidence: classification.intentConfidence || classification.confidence,
      isFallback,
      processingTimeMs,
      emailDomain,
      hasActions: !!(classification.suggestedActions && classification.suggestedActions.length > 0),
      actionCount: classification.suggestedActions ? classification.suggestedActions.length : 0,
      hasEntities: !!(classification.entities && Object.keys(classification.entities).length > 0),
      classifierVersion: USE_ACTION_FIRST ? 'v1.1-action-first' : (USE_ENHANCED_CLASSIFIER ? 'v1.0-enhanced' : 'v0.9-basic')
    });

    res.json(classification);

  } catch (error) {
    const processingTimeMs = Date.now() - startTime;
    logger.error('Error classifying email', {
      error: error.message,
      processingTimeMs,
      stack: error.stack
    });
    res.status(500).json({ error: 'Failed to classify email' });
  }
});

/**
 * POST /api/classify/batch
 * Classify multiple emails
 */
app.post('/api/classify/batch', async (req, res) => {
  const startTime = Date.now();

  try {
    const { emails } = req.body;

    if (!Array.isArray(emails)) {
      return res.status(400).json({ error: 'emails must be an array' });
    }

    logger.info('Classifying batch of emails', {
      count: emails.length,
      enhanced: USE_ENHANCED_CLASSIFIER,
      actionFirst: USE_ACTION_FIRST
    });

    let classifications;
    if (USE_ACTION_FIRST) {
      // Action-first is now async, use Promise.all
      classifications = await Promise.all(emails.map(email => classifyEmailActionFirst(email)));
    } else if (USE_ENHANCED_CLASSIFIER) {
      classifications = emails.map(email => classifyEmailEnhanced(email));
    } else {
      classifications = emails.map(email => classifyEmail(email));
    }

    // THREAD FINDER: Enrich link-only emails with extracted content
    if (isThreadFinderEnabled()) {
      classifications = await Promise.all(
        classifications.map((classification, index) =>
          enrichWithThreadFinder(classification, emails[index])
        )
      );
    }

    // TELEMETRY: Aggregate batch metrics
    const processingTimeMs = Date.now() - startTime;
    const avgProcessingTimeMs = processingTimeMs / emails.length;
    const fallbackCount = classifications.filter(c =>
      c.intent === 'generic.transactional' ||
      c.type === 'generic' ||
      !c.intent
    ).length;
    const fallbackRate = (fallbackCount / classifications.length) * 100;
    const avgConfidence = classifications.reduce((sum, c) =>
      sum + (c.intentConfidence || c.confidence || 0), 0) / classifications.length;

    logger.info('Batch classification complete', {
      totalEmails: emails.length,
      processingTimeMs,
      avgProcessingTimeMs: Math.round(avgProcessingTimeMs),
      fallbackCount,
      fallbackRate: fallbackRate.toFixed(2) + '%',
      avgConfidence: avgConfidence.toFixed(3),
      classifierVersion: USE_ACTION_FIRST ? 'v1.1-action-first' : (USE_ENHANCED_CLASSIFIER ? 'v1.0-enhanced' : 'v0.9-basic')
    });

    res.json({ classifications, count: classifications.length });

  } catch (error) {
    const processingTimeMs = Date.now() - startTime;
    logger.error('Error classifying emails', {
      error: error.message,
      processingTimeMs,
      stack: error.stack
    });
    res.status(500).json({ error: 'Failed to classify emails' });
  }
});

/**
 * POST /api/classify/compare
 * Compare basic vs enhanced classifier (for testing)
 */
app.post('/api/classify/compare', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email || !email.subject || !email.from) {
      return res.status(400).json({ error: 'Invalid email data' });
    }

    logger.info('Comparing classifiers', { subject: email.subject });

    const basicClassification = classifyEmail(email);
    const enhancedClassification = classifyEmailEnhanced(email);

    res.json({
      email: {
        subject: email.subject,
        from: email.from,
        snippet: (email.snippet || email.body || '').substring(0, 100)
      },
      basic: basicClassification,
      enhanced: enhancedClassification,
      comparison: {
        sameType: basicClassification.type === enhancedClassification.type,
        samePriority: basicClassification.priority === enhancedClassification.priority,
        enhancedHasEntities: !!enhancedClassification.entities,
        enhancedHasDeadline: !!enhancedClassification.deadline,
        enhancedHasPrices: !!enhancedClassification.originalPrice
      }
    });

  } catch (error) {
    logger.error('Error comparing classifiers', { error: error.message });
    res.status(500).json({ error: 'Failed to compare classifiers' });
  }
});

/**
 * POST /api/classify/debug
 * Get comprehensive debugging information for email classification
 * Includes all pipeline steps, confidence scores, entity extraction, and action mappings
 */
app.post('/api/classify/debug', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email || !email.subject || !email.from) {
      return res.status(400).json({ error: 'Invalid email data' });
    }

    logger.info('Debug classification requested', { subject: email.subject });

    // Import debug helper
    const { getDebugClassification } = require('./debug-classifier');

    // Get full debug information
    const debugInfo = getDebugClassification(email);

    res.json(debugInfo);

  } catch (error) {
    logger.error('Error in debug classification', { error: error.message });
    res.status(500).json({ error: 'Failed to debug classify email', details: error.message });
  }
});

/**
 * POST /api/classify/secondary
 * Test the secondary AI classifier directly (for fallback emails)
 * Forces body analysis even if pattern matching would succeed
 */
app.post('/api/classify/secondary', async (req, res) => {
  const startTime = Date.now();

  try {
    const { email } = req.body;

    if (!email || !email.subject || !email.from) {
      return res.status(400).json({ error: 'Invalid email data: subject and from are required' });
    }

    logger.info('Testing secondary AI classifier', {
      subject: email.subject?.substring(0, 60),
      from: email.from?.substring(0, 50)
    });

    // Import secondary classifier
    const { classifyWithBodyAnalysis } = require('./fallback-classifier');

    // Run AI body analysis
    const aiResult = await classifyWithBodyAnalysis(email);

    const processingTimeMs = Date.now() - startTime;

    logger.info('Secondary classifier test completed', {
      intent: aiResult.intent,
      confidence: aiResult.confidence,
      source: aiResult.source,
      processingTimeMs
    });

    res.json({
      email: {
        subject: email.subject,
        from: email.from,
        snippet: (email.snippet || email.body || '').substring(0, 200)
      },
      aiClassification: aiResult,
      metadata: {
        processingTimeMs,
        model: 'gemini-2.0-flash-exp',
        timestamp: new Date().toISOString()
      }
    });

  } catch (error) {
    const processingTimeMs = Date.now() - startTime;
    logger.error('Error testing secondary classifier', {
      error: error.message,
      processingTimeMs,
      stack: error.stack
    });
    res.status(500).json({
      error: 'Failed to test secondary classifier',
      details: error.message
    });
  }
});

/**
 * POST /api/classify/mock
 * Classify email using mock templates (for frontend testing without live ML)
 * Phase 2 Task 2.2: Mock Mode Implementation
 */
app.post('/api/classify/mock', async (req, res) => {
  const startTime = Date.now();

  try {
    const { email } = req.body;

    if (!email || !email.subject || !email.from) {
      return res.status(400).json({ error: 'Invalid email data: subject and from are required' });
    }

    logger.info('Mock classification requested', {
      subject: email.subject?.substring(0, 60),
      from: email.from?.substring(0, 50)
    });

    // Run mock classification
    const classification = classifyEmailMock(email);

    const processingTimeMs = Date.now() - startTime;

    logger.info('Mock classification complete', {
      intent: classification.intent,
      confidence: classification.intentConfidence,
      mockTemplateId: classification.mockTemplateId,
      actionCount: classification.suggestedActions?.length || 0,
      hasCompoundAction: !!classification.compoundAction,
      processingTimeMs
    });

    res.json(classification);

  } catch (error) {
    const processingTimeMs = Date.now() - startTime;
    logger.error('Error in mock classification', {
      error: error.message,
      processingTimeMs,
      stack: error.stack
    });
    res.status(500).json({
      error: 'Failed to classify email with mock mode',
      details: error.message
    });
  }
});

/**
 * GET /api/classify/mock/templates
 * Get list of all available mock template IDs (for testing)
 */
app.get('/api/classify/mock/templates', (req, res) => {
  try {
    const templateIds = getAllTemplateIds();
    res.json({
      count: templateIds.length,
      templateIds
    });
  } catch (error) {
    logger.error('Error getting mock template IDs', { error: error.message });
    res.status(500).json({ error: 'Failed to get mock template IDs' });
  }
});

/**
 * Email Classification Logic
 * Analyzes email content and determines archetype, priority, and actions
 */
function classifyEmail(email) {
  const subject = (email.subject || '').toLowerCase();
  const body = (email.body || '').toLowerCase();
  const from = (email.from || '').toLowerCase();
  const snippet = (email.snippet || body).substring(0, 200).toLowerCase();

  let type = 'lifestyle'; // default (was IDENTITY_MANAGER)
  let priority = EmailCard.Priorities.MEDIUM;
  let hpa = 'Review';
  let metaCTA = 'Swipe Right: Review';

  // PERSONAL - School, kids, family-related emails (was EDUCATION/CAREGIVER)
  if (
    from.includes('school') ||
    from.includes('teacher') ||
    subject.includes('field trip') ||
    subject.includes('permission') ||
    subject.includes('report card') ||
    subject.includes('parent') ||
    subject.includes('pta') ||
    snippet.includes('your child') ||
    snippet.includes('your student')
  ) {
    type = EmailCard.ArchetypeTypes.PERSONAL;
    priority = detectPriority(subject, snippet);
    hpa = detectCaregiverAction(subject, snippet);
    metaCTA = `Swipe Right: ${hpa}`;
  }

  // SHOP - Shopping, deals, sales (was SHOPPING/DEAL_STACKER)
  else if (
    subject.includes('sale') ||
    subject.includes('deal') ||
    subject.includes('discount') ||
    subject.includes('% off') ||
    subject.includes('clearance') ||
    subject.includes('limited time') ||
    from.includes('amazon') ||
    from.includes('best buy') ||
    from.includes('target') ||
    from.includes('walmart') ||
    snippet.includes('save $') ||
    snippet.includes('price drop')
  ) {
    type = EmailCard.ArchetypeTypes.SHOP;
    priority = detectDealPriority(subject, snippet);
    hpa = 'Claim Deal';
    metaCTA = 'Swipe Right: Claim Deal';
  }

  // WORK - Executive, management, approval needed (was BILLING/TRANSACTIONAL_LEADER)
  else if (
    subject.includes('approval') ||
    subject.includes('sign off') ||
    subject.includes('review') ||
    subject.includes('budget') ||
    subject.includes('hiring') ||
    subject.includes('onboarding') ||
    subject.includes('board meeting') ||
    snippet.includes('needs your approval') ||
    snippet.includes('executive')
  ) {
    type = 'work';
    priority = EmailCard.Priorities.HIGH;
    hpa = 'Review & Approve';
    metaCTA = 'Swipe Right: Quick Approve';
  }

  // WORK - Sales leads, prospects, deals (was SALES/SALES_HUNTER)
  else if (
    subject.includes('proposal') ||
    subject.includes('demo') ||
    subject.includes('interested in') ||
    subject.includes('meeting request') ||
    snippet.includes('pricing') ||
    snippet.includes('contract') ||
    snippet.includes('purchase') ||
    snippet.includes('budget')
  ) {
    type = 'work';
    priority = EmailCard.Priorities.HIGH;
    hpa = 'Schedule Demo';
    metaCTA = 'Swipe Right: Schedule Demo';
  }

  // WORK - Project updates, sprints, bugs (was PROJECT/PROJECT_COORDINATOR)
  else if (
    subject.includes('sprint') ||
    subject.includes('bug') ||
    subject.includes('production') ||
    subject.includes('deployment') ||
    subject.includes('critical issue') ||
    subject.includes('war room') ||
    snippet.includes('milestone') ||
    snippet.includes('deadline')
  ) {
    type = 'work';
    priority = detectProjectPriority(subject, snippet);
    hpa = 'Review Milestone';
    metaCTA = 'Swipe Right: Review';
  }

  // LIFESTYLE - Learning, courses, research (was LEARNING/ENTERPRISE_INNOVATOR)
  else if (
    subject.includes('course') ||
    subject.includes('webinar') ||
    subject.includes('training') ||
    subject.includes('certification') ||
    subject.includes('research') ||
    subject.includes('whitepaper') ||
    snippet.includes('learn') ||
    snippet.includes('register')
  ) {
    type = 'lifestyle';
    priority = EmailCard.Priorities.MEDIUM;
    hpa = 'Save Article';
    metaCTA = 'Swipe Left: Save for Later';
  }

  // SHOP - Travel, flights, hotels (was TRAVEL/STATUS_SEEKER)
  else if (
    subject.includes('flight') ||
    subject.includes('check-in') ||
    subject.includes('boarding pass') ||
    subject.includes('hotel') ||
    subject.includes('reservation') ||
    from.includes('airline') ||
    from.includes('united') ||
    from.includes('delta') ||
    from.includes('hotel')
  ) {
    type = 'shop';
    priority = detectTravelPriority(subject, snippet);
    hpa = 'Check In';
    metaCTA = 'Swipe Right: Check In';
  }

  // LIFESTYLE - Security, passwords, 2FA (was ACCOUNT/IDENTITY_MANAGER)
  else if (
    subject.includes('security') ||
    subject.includes('password') ||
    subject.includes('verify') ||
    subject.includes('2fa') ||
    subject.includes('suspicious') ||
    subject.includes('login') ||
    snippet.includes('account security') ||
    snippet.includes('reset')
  ) {
    type = 'lifestyle';
    priority = EmailCard.Priorities.CRITICAL;
    hpa = 'Verify Identity';
    metaCTA = 'Swipe Right: Verify Now';
  }

  return {
    type,
    priority,
    hpa,
    metaCTA,
    confidence: 0.85 // Could be calculated based on matching patterns
  };
}

// Helper functions for specific archetype detection

function detectPriority(subject, snippet) {
  if (subject.includes('urgent') || subject.includes('asap') || subject.includes('due today')) {
    return EmailCard.Priorities.CRITICAL;
  }
  if (subject.includes('important') || subject.includes('please review')) {
    return EmailCard.Priorities.HIGH;
  }
  if (subject.includes('reminder')) {
    return EmailCard.Priorities.MEDIUM;
  }
  return EmailCard.Priorities.LOW;
}

function detectCaregiverAction(subject, snippet) {
  if (subject.includes('sign') || subject.includes('permission')) return 'Sign & Send';
  if (subject.includes('rsvp')) return 'RSVP';
  if (subject.includes('payment') || subject.includes('pay')) return 'Pay Now';
  if (subject.includes('calendar') || subject.includes('event')) return 'Add to Calendar';
  return 'Acknowledge';
}

function detectDealPriority(subject, snippet) {
  if (snippet.includes('expires') || snippet.includes('limited') || snippet.includes('today only')) {
    return EmailCard.Priorities.HIGH;
  }
  return EmailCard.Priorities.MEDIUM;
}

function detectProjectPriority(subject, snippet) {
  if (subject.includes('critical') || subject.includes('production') || subject.includes('down')) {
    return EmailCard.Priorities.CRITICAL;
  }
  if (subject.includes('bug') || subject.includes('issue')) {
    return EmailCard.Priorities.HIGH;
  }
  return EmailCard.Priorities.MEDIUM;
}

function detectTravelPriority(subject, snippet) {
  if (subject.includes('check-in') || subject.includes('boarding')) {
    return EmailCard.Priorities.CRITICAL;
  }
  return EmailCard.Priorities.HIGH;
}

// MARK: - Admin Feedback Endpoints

// In-memory storage for feedback (MVP - replace with database later)
const feedbackStore = [];
const reviewedEmails = new Set();

/**
 * GET /api/admin/next-review
 * Get next unreviewed email for admin classification feedback
 */
app.get('/api/admin/next-review', (req, res) => {
  try {
    // For MVP, generate a sample email
    // In production, this would fetch from a database of classified emails

    const samples = [
      {
        id: `review-${Date.now()}-${Math.random()}`,
        from: 'sarah.johnson@techcorp.com',
        subject: 'Q4 Budget Approval Needed',
        snippet: 'Hi team, I need your sign-off on the Q4 budget for the new product launch. Please review the attached spreadsheet and approve by Friday.',
        timeAgo: '2 hours ago',
        classifiedType: 'billing',
        priority: 'high',
        confidence: 0.78
      },
      {
        id: `review-${Date.now()}-${Math.random()}`,
        from: 'deals@bestbuy.com',
        subject: '48-Hour Flash Sale: 40% Off Electronics',
        snippet: 'Limited time offer! Save big on TVs, laptops, and more. Sale ends Sunday at midnight. Shop now before items sell out.',
        timeAgo: '5 hours ago',
        classifiedType: 'shopping',
        priority: 'medium',
        confidence: 0.92
      },
      {
        id: `review-${Date.now()}-${Math.random()}`,
        from: 'teacher@school.edu',
        subject: 'Field Trip Permission Form - Due Oct 25',
        snippet: 'Dear Parents, Your child\'s class will visit the Science Museum on Nov 15. Please sign and return the permission form by October 25th.',
        timeAgo: '1 day ago',
        classifiedType: 'education',
        priority: 'high',
        confidence: 0.88
      }
    ];

    const sample = samples[Math.floor(Math.random() * samples.length)];

    logger.info('Generated sample email for review', { emailId: sample.id });

    res.json(sample);

  } catch (error) {
    logger.error('Error getting next review email', { error: error.message });
    res.status(500).json({ error: 'Failed to get next email for review' });
  }
});

/**
 * POST /api/admin/feedback
 * Submit admin feedback on email classification
 */
app.post('/api/admin/feedback', (req, res) => {
  try {
    const { emailId, originalType, correctedType, isCorrect, confidence, notes, timestamp, reviewerId } = req.body;

    if (!emailId || originalType === undefined || isCorrect === undefined) {
      return res.status(400).json({ error: 'Missing required fields: emailId, originalType, isCorrect' });
    }

    const feedback = {
      id: `feedback-${Date.now()}-${Math.random()}`,
      emailId,
      originalType,
      correctedType: correctedType || null,
      isCorrect,
      confidence,
      notes: notes || null,
      timestamp: timestamp || new Date().toISOString(),
      reviewerId: reviewerId || 'admin',
      submittedAt: new Date().toISOString()
    };

    // Store feedback
    feedbackStore.push(feedback);
    reviewedEmails.add(emailId);

    logger.info('Admin feedback submitted', {
      emailId,
      originalType,
      correctedType,
      isCorrect,
      totalFeedback: feedbackStore.length
    });

    res.json({
      success: true,
      message: 'Feedback submitted successfully',
      feedback: feedback,
      stats: {
        totalReviewed: feedbackStore.length,
        accuracy: feedbackStore.filter(f => f.isCorrect).length / feedbackStore.length
      }
    });

  } catch (error) {
    logger.error('Error submitting feedback', { error: error.message });
    res.status(500).json({ error: 'Failed to submit feedback' });
  }
});

/**
 * GET /api/admin/feedback/stats
 * Get classification accuracy statistics from feedback
 */
app.get('/api/admin/feedback/stats', (req, res) => {
  try {
    const totalReviewed = feedbackStore.length;
    const correctClassifications = feedbackStore.filter(f => f.isCorrect).length;
    const overallAccuracy = totalReviewed > 0 ? correctClassifications / totalReviewed : 0;

    // Group by type
    const typeStats = {};
    feedbackStore.forEach(feedback => {
      if (!typeStats[feedback.originalType]) {
        typeStats[feedback.originalType] = { correct: 0, total: 0 };
      }
      typeStats[feedback.originalType].total++;
      if (feedback.isCorrect) {
        typeStats[feedback.originalType].correct++;
      }
    });

    // Calculate accuracy per type
    Object.keys(typeStats).forEach(type => {
      const stats = typeStats[type];
      stats.accuracy = stats.total > 0 ? stats.correct / stats.total : 0;
    });

    res.json({
      totalReviewed,
      overallAccuracy,
      correctClassifications,
      incorrectClassifications: totalReviewed - correctClassifications,
      typeStats,
      lastUpdated: new Date().toISOString()
    });

  } catch (error) {
    logger.error('Error getting feedback stats', { error: error.message });
    res.status(500).json({ error: 'Failed to get feedback statistics' });
  }
});

// MARK: - Intent Taxonomy Endpoints

/**
 * GET /api/intent-taxonomy/:intentId
 * Get full taxonomy data for a specific intent (for dashboard)
 */
app.get('/api/intent-taxonomy/:intentId', (req, res) => {
  try {
    const { intentId } = req.params;
    const { IntentTaxonomy } = require('./shared/models/Intent');

    const intentData = IntentTaxonomy[intentId];

    if (!intentData) {
      return res.status(404).json({ error: 'Intent not found', intentId });
    }

    // Format the response with examples
    const formattedResponse = {
      id: intentId,
      description: intentData.description,
      triggers: intentData.triggers || [],
      entities: {
        required: intentData.requiredEntities || [],
        optional: intentData.optionalEntities || []
      },
      examples: generateExamples(intentId, intentData)
    };

    res.json(formattedResponse);

  } catch (error) {
    logger.error('Error fetching intent taxonomy', { error: error.message });
    res.status(500).json({ error: 'Failed to fetch intent taxonomy' });
  }
});

/**
 * GET /api/intent-taxonomy
 * Get list of all intent IDs with complete data including mapped actions
 */
app.get('/api/intent-taxonomy', (req, res) => {
  try {
    const { IntentTaxonomy } = require('./shared/models/Intent');
    const { getActionsForIntent } = require('../actions/action-catalog');

    // Return full intent data for each intent
    const intentList = Object.keys(IntentTaxonomy).map(intentId => {
      const intent = IntentTaxonomy[intentId];

      // Get mapped actions for this intent
      const mappedActions = getActionsForIntent(intentId);
      const actionIds = mappedActions
        .filter(action => action.validIntents.includes(intentId)) // Only non-generic actions
        .map(action => action.actionId);

      return {
        id: intentId,
        description: intent.description,
        category: intent.category,
        subCategory: intent.subCategory,
        action: intent.action,
        triggers: intent.triggers || [],
        requiredEntities: intent.requiredEntities || [],
        optionalEntities: intent.optionalEntities || [],
        // Generate example for this intent
        examples: [generateExamples(intentId, intent)],
        // Add mapped action IDs
        actions: actionIds
      };
    });

    res.json({
      count: intentList.length,
      intents: intentList
    });

  } catch (error) {
    logger.error('Error fetching intent list', { error: error.message });
    res.status(500).json({ error: 'Failed to fetch intent list' });
  }
});

/**
 * Generate example emails for an intent
 */
function generateExamples(intentId, intentData) {
  // Example templates based on common patterns
  const exampleTemplates = {
    'e-commerce.shipping.notification': {
      subject: 'Your package has shipped!',
      body: 'Your order is on its way! Tracking number: 1Z999AA10123456784. Carrier: UPS. Arriving tomorrow.'
    },
    'billing.invoice.due': {
      subject: 'Invoice #INV-2025-001 Due Nov 15',
      body: 'Invoice INV-2025-001 is due on Nov 15, 2025. Amount due: $599.00. Pay at: https://pay.acme.com'
    },
    'education.permission.form': {
      subject: 'Field Trip Permission Form - Please Sign',
      body: 'Please sign the permission form for the Science Museum field trip on Nov 10. Fee: $15. Deadline: Nov 1.'
    },
    'healthcare.appointment.reminder': {
      subject: 'Appointment Reminder - Dr. Smith tomorrow',
      body: 'Your appointment with Dr. Smith is tomorrow at 10:30 AM. Please arrive 15 minutes early and bring your insurance card.'
    },
    'travel.flight.check-in': {
      subject: 'Check in for flight UA 1234',
      body: 'Your flight UA 1234 to SFO departs tomorrow at 9:00 AM. Check in now to get your boarding pass.'
    },
    'marketing.promotion.discount': {
      subject: '25% off everything - today only!',
      body: 'Flash sale! Save 25% on everything with code SAVE25. Sale ends tonight at midnight. Shop now!'
    }
  };

  // Return specific template if available, otherwise generate from triggers
  if (exampleTemplates[intentId]) {
    return exampleTemplates[intentId];
  }

  // Generate generic example from first few triggers
  const triggers = intentData.triggers || [];
  if (triggers.length > 0) {
    return {
      subject: `Email about ${intentData.description.toLowerCase()}`,
      body: `This email contains keywords like "${triggers.slice(0, 3).join('", "')}" which trigger the ${intentId} intent.`
    };
  }

  return {
    subject: `Sample ${intentData.description}`,
    body: `Example email for ${intentId} intent.`
  };
}

// Body-parser error handling (must come before generic error handler)
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    logger.error('JSON parsing error', {
      error: err.message,
      body: req.body,
      rawBody: err.body,
      contentType: req.headers['content-type']
    });
    return res.status(400).json({
      error: 'Invalid JSON in request body',
      details: err.message,
      hint: 'Ensure you are sending valid JSON, not a string literal like "null"'
    });
  }
  next(err);
});

// Generic error handling
app.use((err, req, res, next) => {
  logger.error('Classifier service error', { error: err.message, stack: err.stack });
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
  logger.info(`Classifier service running on port ${PORT}`);
  console.log(`🔍 Classifier Service listening on http://localhost:${PORT}`);
});

module.exports = app;
