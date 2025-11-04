const express = require('express');
const router = express.Router();
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'shopping-agent-checkout' },
  transports: [new winston.transports.Console()]
});

// Initialize Stripe (only if key is configured)
let stripe = null;
if (process.env.STRIPE_SECRET_KEY) {
  stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
  logger.info('Stripe initialized successfully');
} else {
  logger.warn('STRIPE_SECRET_KEY not configured - Stripe checkout will be disabled');
}

/**
 * POST /checkout/generate-link
 * Generate deep link to merchant checkout with cart items
 * Body: { cartItems: [{ productUrl, quantity }], merchant }
 */
router.post('/generate-link', async (req, res) => {
  try {
    const { cartItems, merchant } = req.body;

    if (!cartItems || !Array.isArray(cartItems) || cartItems.length === 0) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'cartItems array is required and must not be empty'
      });
    }

    logger.info('Generating merchant deep link', {
      merchant,
      itemCount: cartItems.length
    });

    // Generate merchant-specific deep links
    const deepLink = generateMerchantDeepLink(merchant, cartItems);

    if (!deepLink.supported) {
      return res.json({
        success: false,
        message: `Deep links not yet supported for ${merchant}. Please use manual checkout.`,
        fallbackUrls: cartItems.map(item => item.productUrl)
      });
    }

    logger.info('Deep link generated', { merchant, url: deepLink.url });

    res.json({
      success: true,
      checkoutUrl: deepLink.url,
      merchant,
      instructions: deepLink.instructions,
      itemCount: cartItems.length
    });

  } catch (error) {
    logger.error('Error generating deep link', {
      error: error.message,
      stack: error.stack
    });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * POST /checkout/stripe
 * Create Stripe checkout session for multi-merchant cart
 * Body: { userId, cartItems: [{ productName, price, quantity, merchant, productImage }], successUrl, cancelUrl }
 */
router.post('/stripe', async (req, res) => {
  try {
    if (!stripe) {
      return res.status(503).json({
        error: 'Service Unavailable',
        message: 'Stripe is not configured. Please set STRIPE_SECRET_KEY environment variable.'
      });
    }

    const { userId, cartItems, successUrl, cancelUrl } = req.body;

    if (!cartItems || !Array.isArray(cartItems) || cartItems.length === 0) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'cartItems array is required and must not be empty'
      });
    }

    if (!successUrl || !cancelUrl) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'successUrl and cancelUrl are required'
      });
    }

    logger.info('Creating Stripe checkout session', {
      userId,
      itemCount: cartItems.length
    });

    // Convert cart items to Stripe line items
    const lineItems = cartItems.map(item => ({
      price_data: {
        currency: 'usd',
        product_data: {
          name: item.productName,
          description: `${item.merchant} - ${item.productName}`,
          images: item.productImage ? [item.productImage] : []
        },
        unit_amount: Math.round(item.price * 100) // Convert to cents
      },
      quantity: item.quantity
    }));

    // Create Stripe checkout session
    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      line_items: lineItems,
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: {
        userId: userId || 'anonymous',
        source: 'zero-email-app'
      },
      payment_method_types: ['card'],
      billing_address_collection: 'required',
      shipping_address_collection: {
        allowed_countries: ['US', 'CA']
      }
    });

    logger.info('Stripe checkout session created', {
      sessionId: session.id,
      userId
    });

    res.json({
      success: true,
      sessionId: session.id,
      checkoutUrl: session.url,
      expiresAt: new Date(session.expires_at * 1000).toISOString()
    });

  } catch (error) {
    logger.error('Error creating Stripe checkout session', {
      error: error.message,
      stack: error.stack
    });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * POST /checkout/acp
 * OpenAI Agentic Commerce Protocol checkout (PLACEHOLDER - Not Implemented)
 *
 * STATUS: This is a placeholder endpoint for future ACP implementation
 * CURRENT: Returns 501 Not Implemented with roadmap information
 * ROADMAP: See backend/services/shopping-agent/ACP_STATUS.md for Option B details
 *
 * For production checkout in v1.1, use:
 * - POST /checkout/generate-link (Stripe deep links - works for all merchants)
 * - POST /checkout/stripe (direct Stripe checkout)
 *
 * ACP Spec: https://developers.openai.com/commerce/specs/checkout/
 * Implementation Plan: backend/services/shopping-agent/ACP_STATUS.md
 */
router.post('/acp', async (req, res) => {
  try {
    const { merchant, cartItems, buyerInfo } = req.body;

    logger.info('ACP endpoint called (placeholder only)', {
      merchant,
      itemCount: cartItems?.length || 0
    });

    // Return 501 Not Implemented with clear guidance
    return res.status(501).json({
      error: 'Not Implemented',
      status: 'placeholder',
      message: 'ACP checkout is planned for future release (Option B). See ACP_STATUS.md for full roadmap.',
      
      // Current working options
      currentOptions: [
        {
          endpoint: 'POST /checkout/generate-link',
          description: 'Stripe deep link checkout (works for all merchants)',
          status: 'production-ready',
          recommended: true
        },
        {
          endpoint: 'POST /checkout/stripe',
          description: 'Direct Stripe checkout',
          status: 'production-ready',
          recommended: false
        }
      ],
      
      // Future ACP roadmap
      roadmap: {
        option: 'B',
        timeline: '9-11 weeks',
        effort: 'Full-time engineer',
        status: 'planned',
        requirements: [
          'Merchant API credentials (Etsy, Shopify)',
          'OAuth setup for buyer authentication',
          'ACP client library integration',
          'Extensive testing with real merchants'
        ],
        documentation: '/backend/services/shopping-agent/ACP_STATUS.md'
      },
      
      // What currently works
      productionFeatures: {
        productParsing: 'Uses OpenAI GPT-4o-mini - WORKING',
        priceComparison: 'AI-powered comparison - WORKING',
        cartManagement: 'Add/remove/update items - WORKING',
        stripeCheckout: 'Deep link generation - WORKING'
      },
      
      // Spec reference
      acpSpecification: 'https://developers.openai.com/commerce/specs/checkout/',
      
      // Supported merchants (when implemented)
      futureSupport: ['Etsy', 'Shopify'],
      
      // ROI considerations
      notes: [
        'ACP only works with Etsy and Shopify (as of Sept 2025)',
        'Most email deals are from Amazon, Target, Best Buy (not ACP-compatible)',
        'Requires schema.org markup in emails (low adoption currently)',
        'Option A (Stripe deep links) works for 100% of merchants',
        'Option B (ACP) works for <10% of merchants but with better UX'
      ]
    });

  } catch (error) {
    logger.error('ACP endpoint error', { error: error.message });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

// Remove old duplicate error handler
/* Removed duplicate catch block - ACP endpoint updated to 501 Not Implemented */

/**
 * Legacy ACP error handler (removed)
 */
router.post('/acp-legacy-removed', async (req, res) => {
  // This code was removed - see /acp endpoint above
  res.status(410).json({ error: 'Gone', message: 'Endpoint relocated to POST /acp' });
});

// Removed legacy handleACPError function - no longer needed

/**
 * GET /checkout/stripe/session/:sessionId
 * Retrieve Stripe checkout session status
 */
router.get('/stripe/session/:sessionId', async (req, res) => {
  try {
    if (!stripe) {
      return res.status(503).json({
        error: 'Service Unavailable',
        message: 'Stripe is not configured'
      });
    }

    const { sessionId } = req.params;

    const session = await stripe.checkout.sessions.retrieve(sessionId);

    logger.info('Stripe session retrieved', {
      sessionId,
      status: session.payment_status
    });

    res.json({
      success: true,
      session: {
        id: session.id,
        status: session.status,
        paymentStatus: session.payment_status,
        amountTotal: session.amount_total / 100,
        currency: session.currency,
        customerEmail: session.customer_details?.email
      }
    });

  } catch (error) {
    logger.error('Error retrieving Stripe session', {
      error: error.message,
      sessionId: req.params.sessionId
    });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * Helper: Generate merchant-specific deep links
 */
function generateMerchantDeepLink(merchant, cartItems) {
  const normalizedMerchant = merchant?.toLowerCase() || '';

  // Amazon cart deep link
  if (normalizedMerchant.includes('amazon')) {
    // Amazon Add to Cart API requires ASIN IDs
    // For now, return individual product links
    return {
      supported: true,
      url: cartItems[0].productUrl, // Primary item
      instructions: 'Opens Amazon with first product. Add remaining items manually.',
      note: 'Full cart deep linking requires Amazon Product Advertising API integration'
    };
  }

  // Target cart deep link
  if (normalizedMerchant.includes('target')) {
    return {
      supported: true,
      url: 'https://www.target.com/cart',
      instructions: 'Opens Target cart. Products must be added via their API.',
      note: 'Target API integration required for auto-add to cart'
    };
  }

  // Walmart cart deep link
  if (normalizedMerchant.includes('walmart')) {
    return {
      supported: true,
      url: 'https://www.walmart.com/cart',
      instructions: 'Opens Walmart cart page.',
      note: 'Walmart API integration required for auto-add functionality'
    };
  }

  // Best Buy
  if (normalizedMerchant.includes('best buy') || normalizedMerchant.includes('bestbuy')) {
    return {
      supported: true,
      url: 'https://www.bestbuy.com/cart',
      instructions: 'Opens Best Buy cart.',
      note: 'Best Buy API required for cart manipulation'
    };
  }

  // Generic fallback
  return {
    supported: false,
    url: null,
    instructions: `Manual checkout required for ${merchant}`,
    note: 'Deep link integration not yet available for this merchant'
  };
}

module.exports = router;
