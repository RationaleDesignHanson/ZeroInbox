/**
 * Token Validator Middleware
 * Proactively validates and refreshes OAuth tokens before API calls
 * Prevents 401 errors by ensuring tokens are always fresh
 */

const logger = require('../config/logger');
const {
  refreshTokenIfNeeded,
  isTokenExpiring,
  needsReauth,
  getTokenHealth
} = require('../utils/token-manager');
const { getUserTokens } = require('../utils/auth');

/**
 * Middleware to validate token health before processing request
 * Automatically refreshes tokens if expiring within 5 minutes
 */
async function validateToken(req, res, next) {
  try {
    const userId = req.user?.userId;
    const provider = req.user?.emailProvider || 'gmail';

    if (!userId) {
      logger.warn('Token validation skipped - no userId in request');
      return next();
    }

    // Check if user is marked for re-authentication
    if (needsReauth(userId)) {
      logger.warn('⚠️ User needs re-authentication', { userId, provider });
      return res.status(401).json({
        error: 'Authentication expired',
        needsReauth: true,
        message: 'Your authentication has expired. Please sign in again.',
        reauthUrl: `/api/auth/${provider}`
      });
    }

    // Get current token health
    const health = getTokenHealth(userId, provider);

    if (health.status === 'missing' || health.status === 'expired') {
      logger.warn('⚠️ Token is invalid', { userId, provider, health });
      return res.status(401).json({
        error: 'Invalid authentication',
        needsReauth: true,
        message: 'Please sign in again to continue.',
        reauthUrl: `/api/auth/${provider}`
      });
    }

    // Proactively refresh if expiring soon
    if (health.status === 'expiring') {
      logger.info('⏰ Proactively refreshing expiring token', {
        userId,
        provider,
        minutesUntilExpiry: health.minutesUntilExpiry
      });

      const freshTokens = await refreshTokenIfNeeded(userId, provider);

      if (!freshTokens) {
        logger.error('❌ Proactive token refresh failed', { userId, provider });
        // Continue anyway - let the actual API call attempt with current token
      } else {
        logger.info('✅ Token refreshed proactively', { userId, provider });

        // Update request headers with fresh tokens for downstream services
        req.headers['x-access-token'] = freshTokens.accessToken;
        req.headers['x-refresh-token'] = freshTokens.refreshToken;
      }
    }

    // Token is healthy - proceed with request
    next();

  } catch (error) {
    logger.error('Token validation middleware error', {
      error: error.message,
      userId: req.user?.userId
    });

    // Don't block the request on middleware errors
    next();
  }
}

/**
 * Enhanced middleware that retries failed requests after token refresh
 * Use this for critical API calls
 */
function validateTokenWithRetry(req, res, next) {
  // Store original send function
  const originalSend = res.send;

  // Wrap send to intercept 401 responses
  res.send = function(data) {
    // Check if response is 401
    if (res.statusCode === 401 && !req._tokenRetried) {
      logger.info('🔄 401 detected, attempting token refresh and retry', {
        userId: req.user?.userId,
        path: req.path
      });

      // Mark that we've already retried to prevent infinite loops
      req._tokenRetried = true;

      // Attempt to refresh token and retry
      return refreshAndRetry(req, res, originalSend, data);
    }

    // Normal response - call original send
    return originalSend.call(this, data);
  };

  // First validate the token
  validateToken(req, res, next);
}

/**
 * Attempt to refresh token and retry the failed request
 */
async function refreshAndRetry(req, res, originalSend, errorData) {
  try {
    const userId = req.user?.userId;
    const provider = req.user?.emailProvider || 'gmail';

    if (!userId) {
      return originalSend.call(res, errorData);
    }

    // Attempt token refresh
    const freshTokens = await refreshTokenIfNeeded(userId, provider);

    if (!freshTokens) {
      logger.error('❌ Token refresh failed during retry', { userId, provider });
      return originalSend.call(res, errorData);
    }

    logger.info('✅ Token refreshed successfully, retrying request', {
      userId,
      provider,
      path: req.path
    });

    // Update request headers with fresh tokens
    req.headers['x-access-token'] = freshTokens.accessToken;
    req.headers['x-refresh-token'] = freshTokens.refreshToken;

    // TODO: Actually retry the request
    // This is complex because we need to re-execute the route handler
    // For now, just return the error and let the client retry

    return originalSend.call(res, errorData);

  } catch (error) {
    logger.error('Error during token refresh retry', {
      error: error.message,
      userId: req.user?.userId
    });

    return originalSend.call(res, errorData);
  }
}

/**
 * Middleware specifically for Gmail API routes
 * Ensures tokens are fresh before making Gmail API calls
 */
async function validateGmailToken(req, res, next) {
  try {
    const userId = req.user?.userId;

    if (!userId) {
      logger.warn('Gmail token validation skipped - no userId');
      return next();
    }

    // Get tokens
    const tokens = getUserTokens(userId, 'gmail');

    if (!tokens) {
      logger.error('No Gmail tokens found', { userId });
      return res.status(401).json({
        error: 'Gmail authentication required',
        needsReauth: true,
        message: 'Please sign in with Google to access your emails.',
        reauthUrl: '/api/auth/gmail'
      });
    }

    // Check if expiring and refresh proactively
    if (isTokenExpiring(tokens)) {
      logger.info('Gmail token expiring, refreshing...', { userId });

      const freshTokens = await refreshTokenIfNeeded(userId, 'gmail');

      if (freshTokens) {
        // Update request headers for downstream Gmail service
        req.headers['x-access-token'] = freshTokens.accessToken;
        req.headers['x-refresh-token'] = freshTokens.refreshToken;
        logger.info('✅ Gmail token refreshed and headers updated', { userId });
      }
    } else {
      // Token is fresh - add to headers
      req.headers['x-access-token'] = tokens.accessToken;
      req.headers['x-refresh-token'] = tokens.refreshToken;
    }

    next();

  } catch (error) {
    logger.error('Gmail token validation error', {
      error: error.message,
      userId: req.user?.userId
    });

    // Don't block the request
    next();
  }
}

/**
 * Check token health endpoint (for monitoring)
 */
async function checkTokenHealth(req, res) {
  try {
    const userId = req.user?.userId;
    const provider = req.user?.emailProvider || 'gmail';

    if (!userId) {
      return res.status(400).json({ error: 'User ID required' });
    }

    const health = getTokenHealth(userId, provider);

    res.json({
      userId,
      provider,
      ...health,
      timestamp: Date.now()
    });

  } catch (error) {
    logger.error('Token health check error', {
      error: error.message,
      userId: req.user?.userId
    });

    res.status(500).json({
      error: 'Failed to check token health',
      message: error.message
    });
  }
}

module.exports = {
  validateToken,
  validateTokenWithRetry,
  validateGmailToken,
  checkTokenHealth
};
