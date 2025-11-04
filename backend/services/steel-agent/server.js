/**
 * Steel Agent Service
 * Provides AI-powered subscription cancellation assistance
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const logger = require('../../shared/config/logger');
const { findService, detectServiceFromEmail, supportsAIAssistance } = require('./subscription-helper');
const { guideCancellation } = require('./steel-client');

const app = express();
const PORT = process.env.PORT || process.env.STEEL_AGENT_PORT || 8087;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'steel-agent-service',
    timestamp: new Date().toISOString(),
    steelApiConfigured: !!process.env.STEEL_API_KEY
  });
});

/**
 * GET /api/subscription/info
 * Get cancellation information for a service
 */
app.get('/api/subscription/info', (req, res) => {
  try {
    const { service: serviceName } = req.query;

    if (!serviceName) {
      return res.status(400).json({ error: 'Service name required' });
    }

    const service = findService(serviceName);

    if (!service) {
      return res.status(404).json({
        error: 'Service not found',
        serviceName,
        suggestion: 'Try a different service name or check spelling'
      });
    }

    const aiAssistanceAvailable = supportsAIAssistance(service);

    res.json({
      serviceName: service.name,
      accountPageUrl: service.accountPageUrl,
      cancellationUrl: service.cancellationUrl,
      cancellationSteps: service.cancellationSteps,
      requiresLogin: service.requiresLogin,
      aiAssistanceAvailable,
      note: service.note || null
    });

  } catch (error) {
    logger.error('Error getting subscription info', {
      error: error.message
    });
    res.status(500).json({ error: 'Failed to get subscription info' });
  }
});

/**
 * POST /api/subscription/detect
 * Detect subscription service from email content
 */
app.post('/api/subscription/detect', (req, res) => {
  try {
    const { email } = req.body;

    if (!email || !email.from) {
      return res.status(400).json({ error: 'Email data required' });
    }

    const serviceName = detectServiceFromEmail(email);

    if (!serviceName) {
      return res.json({
        detected: false,
        serviceName: null,
        message: 'Could not detect subscription service from email'
      });
    }

    const service = findService(serviceName);

    res.json({
      detected: true,
      serviceName: service.name,
      accountPageUrl: service.accountPageUrl,
      cancellationUrl: service.cancellationUrl,
      aiAssistanceAvailable: supportsAIAssistance(service)
    });

  } catch (error) {
    logger.error('Error detecting subscription service', {
      error: error.message
    });
    res.status(500).json({ error: 'Failed to detect service' });
  }
});

/**
 * POST /api/subscription/cancel/guided
 * Start AI-guided cancellation flow
 */
app.post('/api/subscription/cancel/guided', async (req, res) => {
  try {
    const { serviceName, userSessionId } = req.body;

    if (!serviceName) {
      return res.status(400).json({ error: 'Service name required' });
    }

    if (!process.env.STEEL_API_KEY) {
      return res.status(503).json({
        error: 'Steel.dev API not configured',
        fallbackMode: true,
        message: 'AI assistance temporarily unavailable. Use direct link instead.'
      });
    }

    const service = findService(serviceName);

    if (!service) {
      return res.status(404).json({
        error: 'Service not found',
        serviceName
      });
    }

    if (!supportsAIAssistance(service)) {
      return res.status(400).json({
        error: 'AI assistance not supported for this service',
        serviceName: service.name,
        reason: service.note || 'Service requires manual cancellation',
        accountPageUrl: service.accountPageUrl
      });
    }

    logger.info('Starting guided cancellation', {
      userSessionId,
      service: service.name
    });

    // Start AI-guided cancellation
    const result = await guideCancellation(service, userSessionId || 'anonymous');

    if (!result.success) {
      return res.status(500).json({
        error: 'Guided cancellation failed',
        serviceName: service.name,
        fallbackUrl: service.accountPageUrl,
        details: result.error
      });
    }

    res.json({
      success: true,
      serviceName: service.name,
      steps: result.steps,
      nextSteps: result.nextSteps,
      requiresLogin: result.requiresLogin,
      note: result.note
    });

  } catch (error) {
    logger.error('Error in guided cancellation', {
      error: error.message,
      stack: error.stack
    });
    res.status(500).json({
      error: 'Failed to start guided cancellation',
      message: error.message
    });
  }
});

/**
 * POST /api/subscription/cancel/direct
 * Get direct cancellation link (no AI assistance)
 */
app.post('/api/subscription/cancel/direct', (req, res) => {
  try {
    const { serviceName } = req.body;

    if (!serviceName) {
      return res.status(400).json({ error: 'Service name required' });
    }

    const service = findService(serviceName);

    if (!service) {
      return res.status(404).json({
        error: 'Service not found',
        serviceName
      });
    }

    const targetUrl = service.cancellationUrl || service.accountPageUrl;

    logger.info('Direct cancellation link requested', {
      service: service.name,
      url: targetUrl
    });

    res.json({
      success: true,
      serviceName: service.name,
      url: targetUrl,
      requiresLogin: service.requiresLogin,
      steps: service.cancellationSteps,
      note: service.note
    });

  } catch (error) {
    logger.error('Error getting direct cancellation link', {
      error: error.message
    });
    res.status(500).json({ error: 'Failed to get cancellation link' });
  }
});

// Error handling
app.use((err, req, res, next) => {
  logger.error('Steel agent service error', {
    error: err.message,
    stack: err.stack
  });
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
  const steelConfigured = !!process.env.STEEL_API_KEY;
  logger.info(`Steel agent service running on port ${PORT}`, {
    steelApiConfigured: steelConfigured
  });
  console.log(`\n🤖 Steel Agent Service listening on http://localhost:${PORT}`);
  console.log(`   Steel.dev API: ${steelConfigured ? '✓ Configured' : '✗ Not configured'}`);
  console.log(`   Status: http://localhost:${PORT}/health\n`);
});

module.exports = app;
