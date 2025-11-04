const express = require('express');
const router = express.Router();
const logger = require('../shared/config/logger');

/**
 * POST /api/feedback/classification
 * Submit classification feedback (user corrects Mail/Ads category)
 */
router.post('/classification', async (req, res) => {
  try {
    const {
      emailId,
      originalCategory,
      correctedCategory,
      userEmail
    } = req.body;

    // Validate required fields
    if (!emailId || !originalCategory || !correctedCategory) {
      return res.status(400).json({
        error: 'Missing required fields: emailId, originalCategory, correctedCategory'
      });
    }

    logger.info('📊 Classification feedback received', {
      emailId,
      originalCategory,
      correctedCategory,
      userEmail: userEmail || 'anonymous'
    });

    // TODO: Store in database for analysis
    // TODO: Use for retraining classifier
    // For now, just log it

    res.json({
      success: true,
      message: 'Thank you for your feedback!'
    });

  } catch (error) {
    logger.error('Error processing classification feedback', {
      error: error.message,
      stack: error.stack
    });
    res.status(500).json({ error: 'Failed to submit feedback' });
  }
});

/**
 * POST /api/feedback/issue
 * Submit general issue report
 */
router.post('/issue', async (req, res) => {
  try {
    const {
      emailId,
      emailFrom,
      emailSubject,
      issueDescription,
      userEmail
    } = req.body;

    // Validate required fields
    if (!issueDescription || issueDescription.length < 10) {
      return res.status(400).json({
        error: 'Issue description must be at least 10 characters'
      });
    }

    logger.info('🐛 Issue report received', {
      emailId: emailId || 'N/A',
      emailFrom: emailFrom || 'N/A',
      emailSubject: emailSubject || 'N/A',
      issueLength: issueDescription.length,
      userEmail: userEmail || 'anonymous'
    });

    // TODO: Send email to support@zero.com
    // TODO: Store in support ticket system
    // For now, just log it

    logger.warn('📧 Support Issue Report', {
      from: userEmail || 'anonymous',
      emailId,
      emailFrom,
      emailSubject,
      issue: issueDescription
    });

    res.json({
      success: true,
      message: 'Issue report submitted successfully'
    });

  } catch (error) {
    logger.error('Error processing issue report', {
      error: error.message,
      stack: error.stack
    });
    res.status(500).json({ error: 'Failed to submit issue report' });
  }
});

module.exports = router;
