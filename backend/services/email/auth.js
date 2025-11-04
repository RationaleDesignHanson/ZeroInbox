/**
 * Simple auth stub for email service
 * For Cloud Run deployment - handles both JWT and X-User-ID headers
 */

const jwt = require('jsonwebtoken');

function authenticateRequest(req, res, next) {
  try {
    // Check for X-User-ID header (internal service-to-service)
    const userId = req.headers['x-user-id'];
    if (userId) {
      req.user = { userId };
      return next();
    }

    // Check for JWT token
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing authorization token' });
    }

    const token = authHeader.substring(7);
    const secret = process.env.JWT_SECRET || 'dev-secret-key';

    const decoded = jwt.verify(token, secret);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

/**
 * Get stored user tokens for email provider
 * Stub for Cloud Run deployment - uses environment variables
 */
function getUserTokens(userId, provider) {
  // In production, this would fetch from database
  // For now, return empty tokens (email routes will handle gracefully)
  return {
    accessToken: process.env[`${provider.toUpperCase()}_ACCESS_TOKEN`] || null,
    refreshToken: process.env[`${provider.toUpperCase()}_REFRESH_TOKEN`] || null,
    password: process.env[`${provider.toUpperCase()}_PASSWORD`] || null
  };
}

module.exports = { authenticateRequest, getUserTokens };
