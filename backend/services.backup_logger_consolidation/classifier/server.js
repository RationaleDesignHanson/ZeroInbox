require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const logger = require('./logger');
const EmailCard = require('./EmailCard');
const { classifyEmailEnhanced } = require('./enhanced-classifier');
const { classifyEmailActionFirst } = require('./action-first-classifier');

const app = express();
const PORT = process.env.PORT || process.env.CLASSIFIER_SERVICE_PORT || 8082;
const USE_ENHANCED_CLASSIFIER = process.env.USE_ENHANCED_CLASSIFIER !== 'false'; // Default to enhanced
const USE_ACTION_FIRST = process.env.USE_ACTION_FIRST === 'true'; // v1.1 action-first model

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'classifier-service', timestamp: new Date().toISOString() });
});

/**
 * POST /api/classify
 * Classify email into archetype (uses enhanced classifier by default)
 */
app.post('/api/classify', async (req, res) => {
  const startTime = Date.now();

  try {
    const { email } = req.body;

    if (!email || !email.subject || !email.from) {
      return res.status(400).json({ error: 'Invalid email data' });
    }

    logger.info('Classifying email', {
      subject: email.subject,
      enhanced: USE_ENHANCED_CLASSIFIER,
      actionFirst: USE_ACTION_FIRST
    });

    // Use action-first classifier (v1.1) if enabled, otherwise fall back to enhanced or basic
    let classification;
    if (USE_ACTION_FIRST) {
      classification = classifyEmailActionFirst(email);
      logger.info('Using ACTION-FIRST classifier (v1.1)', { intent: classification.intent });
    } else if (USE_ENHANCED_CLASSIFIER) {
      classification = classifyEmailEnhanced(email);
    } else {
      classification = classifyEmail(email);
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
      classifications = emails.map(email => classifyEmailActionFirst(email));
    } else if (USE_ENHANCED_CLASSIFIER) {
      classifications = emails.map(email => classifyEmailEnhanced(email));
    } else {
      classifications = emails.map(email => classifyEmail(email));
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

// Error handling
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
