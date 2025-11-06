/**
 * Steel Agent Service
 * Provides AI-powered subscription cancellation assistance
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const winston = require('winston');

// Create logger directly in this file for Cloud Run compatibility
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});

const { findService, detectServiceFromEmail, supportsAIAssistance } = require('./subscription-helper');
const { guideCancellation } = require('./steel-client');
const { automateAddToCart, getPlatformInfo, closeSessionEarly } = require('./shopping-automation');

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

// ===================================================================
// SHOPPING AUTOMATION ENDPOINTS
// ===================================================================

/**
 * POST /api/shopping/add-to-cart
 * Automate adding product to cart and navigate to checkout
 *
 * Request body:
 * {
 *   productUrl: string (required) - URL of product page
 *   productName: string (required) - Name of product
 *   userSessionId: string (optional) - User session ID for tracking
 * }
 *
 * Response:
 * {
 *   success: boolean,
 *   checkoutUrl: string | null,
 *   cartUrl: string | null,
 *   screenshots: Array<{step: string, data: string, timestamp: string}>,
 *   steps: Array<{step: string, success: boolean, ...}>,
 *   error: string | null
 * }
 */
app.post('/api/shopping/add-to-cart', async (req, res) => {
  try {
    const { productUrl, productName, userSessionId } = req.body;

    // Validation
    if (!productUrl) {
      return res.status(400).json({
        error: 'Product URL is required',
        field: 'productUrl'
      });
    }

    if (!productName) {
      return res.status(400).json({
        error: 'Product name is required',
        field: 'productName'
      });
    }

    // Check if Steel API is configured
    if (!process.env.STEEL_API_KEY) {
      return res.status(503).json({
        success: false,
        error: 'Steel.dev API not configured',
        fallbackMode: true,
        productUrl,
        message: 'AI shopping automation temporarily unavailable. Opening product page instead.'
      });
    }

    logger.info('Starting shopping automation', {
      userSessionId,
      productName,
      productUrl
    });

    // Start automation
    const result = await automateAddToCart(
      productUrl,
      productName,
      userSessionId || 'anonymous'
    );

    if (!result.success) {
      logger.warn('Shopping automation failed, returning fallback', {
        productName,
        error: result.error
      });

      return res.status(200).json({
        success: false,
        error: result.error,
        fallbackMode: true,
        productUrl,
        steps: result.steps,
        screenshots: result.screenshots,
        message: 'Automation failed. Opening product page for manual checkout.'
      });
    }

    logger.info('Shopping automation succeeded', {
      productName,
      checkoutUrl: result.checkoutUrl,
      sessionId: result.sessionId
    });

    res.json({
      success: true,
      checkoutUrl: result.checkoutUrl,
      cartUrl: result.cartUrl,
      sessionId: result.sessionId,
      sessionViewerUrl: result.sessionViewerUrl,
      productName,
      steps: result.steps,
      screenshots: result.screenshots,
      message: `Successfully added ${productName} to cart! Open the session viewer URL to complete your purchase with cart state preserved.`,
      note: 'Use sessionViewerUrl to view the browser session with the item in cart. Session will remain active for 30 minutes.'
    });

  } catch (error) {
    logger.error('Error in shopping automation', {
      error: error.message,
      stack: error.stack
    });

    res.status(500).json({
      success: false,
      error: 'Shopping automation failed',
      message: error.message,
      fallbackMode: true
    });
  }
});

/**
 * GET /api/shopping/platform-info
 * Get platform detection info for a product URL (diagnostic)
 *
 * Query params:
 * - url: Product URL
 *
 * Response:
 * {
 *   url: string,
 *   platform: string,
 *   platformId: string,
 *   addToCartSelectors: string[],
 *   checkoutSelectors: string[]
 * }
 */
app.get('/api/shopping/platform-info', (req, res) => {
  try {
    const { url } = req.query;

    if (!url) {
      return res.status(400).json({
        error: 'URL parameter required',
        example: '/api/shopping/platform-info?url=https://amazon.com/product/123'
      });
    }

    const platformInfo = getPlatformInfo(url);

    res.json(platformInfo);

  } catch (error) {
    logger.error('Error getting platform info', {
      error: error.message
    });
    res.status(500).json({
      error: 'Failed to get platform info',
      message: error.message
    });
  }
});

/**
 * DELETE /api/shopping/session/:sessionId
 * Manually close a Steel session before the automatic timeout
 *
 * Response:
 * {
 *   success: boolean,
 *   message: string
 * }
 */
app.delete('/api/shopping/session/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;

    if (!sessionId) {
      return res.status(400).json({
        error: 'Session ID required'
      });
    }

    logger.info('Manually closing shopping session', { sessionId });

    await closeSessionEarly(sessionId);

    res.json({
      success: true,
      message: `Session ${sessionId} closed successfully`
    });

  } catch (error) {
    logger.error('Error closing session', {
      sessionId: req.params.sessionId,
      error: error.message
    });
    res.status(500).json({
      success: false,
      error: 'Failed to close session',
      message: error.message
    });
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
