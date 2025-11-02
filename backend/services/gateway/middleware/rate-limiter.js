/**
 * Rate Limiting Middleware
 * Protects API endpoints from abuse and DDoS attacks
 */

const logger = require('../../shared/config/logger');

// In-memory rate limit store (for development)
// In production, use Redis for distributed rate limiting
const rateLimitStore = new Map();

// Rate limit configuration
const RATE_LIMITS = {
  // Per-user API limits (requests per minute)
  api: {
    windowMs: 60 * 1000, // 1 minute
    max: 100, // 100 requests per minute per user
    message: 'Too many requests, please try again later'
  },

  // Stricter limits for authentication endpoints
  auth: {
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // 5 attempts per 15 minutes
    message: 'Too many authentication attempts, please try again later'
  },

  // Email fetching limits
  email: {
    windowMs: 60 * 1000, // 1 minute
    max: 30, // 30 email fetch requests per minute
    message: 'Too many email requests, please slow down'
  }
};

/**
 * Clean up expired rate limit entries
 */
function cleanupExpiredEntries() {
  const now = Date.now();
  let cleaned = 0;

  for (const [key, data] of rateLimitStore.entries()) {
    if (now > data.resetTime) {
      rateLimitStore.delete(key);
      cleaned++;
    }
  }

  if (cleaned > 0) {
    logger.debug('Cleaned up expired rate limit entries', { cleaned, storeSize: rateLimitStore.size });
  }
}

// Run cleanup every 5 minutes
setInterval(cleanupExpiredEntries, 5 * 60 * 1000);

/**
 * Create rate limiter middleware
 * @param {string} limitType - Type of rate limit (api, auth, email)
 * @param {function} keyGenerator - Function to generate rate limit key (default: userId or IP)
 */
function createRateLimiter(limitType = 'api', keyGenerator = null) {
  const config = RATE_LIMITS[limitType] || RATE_LIMITS.api;

  return (req, res, next) => {
    try {
      // Generate rate limit key (userId or IP address)
      let key;
      if (keyGenerator) {
        key = keyGenerator(req);
      } else if (req.user?.userId) {
        key = `${limitType}:user:${req.user.userId}`;
      } else {
        // Fallback to IP address for unauthenticated requests
        const ip = req.ip || req.connection.remoteAddress;
        key = `${limitType}:ip:${ip}`;
      }

      const now = Date.now();
      let rateLimitData = rateLimitStore.get(key);

      // Initialize or reset if window expired
      if (!rateLimitData || now > rateLimitData.resetTime) {
        rateLimitData = {
          count: 0,
          resetTime: now + config.windowMs
        };
        rateLimitStore.set(key, rateLimitData);
      }

      // Increment request count
      rateLimitData.count++;

      // Set rate limit headers
      const remaining = Math.max(0, config.max - rateLimitData.count);
      const resetTime = Math.ceil((rateLimitData.resetTime - now) / 1000);

      res.setHeader('X-RateLimit-Limit', config.max);
      res.setHeader('X-RateLimit-Remaining', remaining);
      res.setHeader('X-RateLimit-Reset', resetTime);

      // Check if rate limit exceeded
      if (rateLimitData.count > config.max) {
        logger.warn('Rate limit exceeded', {
          key,
          count: rateLimitData.count,
          max: config.max,
          userId: req.user?.userId,
          ip: req.ip
        });

        res.setHeader('Retry-After', resetTime);
        return res.status(429).json({
          error: 'Too Many Requests',
          message: config.message,
          retryAfter: resetTime
        });
      }

      next();

    } catch (error) {
      logger.error('Rate limiter error', { error: error.message });
      // Fail open - allow request if rate limiter fails
      next();
    }
  };
}

/**
 * Pre-configured rate limiters
 */
const rateLimiters = {
  // General API rate limiter
  api: createRateLimiter('api'),

  // Authentication rate limiter (stricter)
  auth: createRateLimiter('auth'),

  // Email fetching rate limiter
  email: createRateLimiter('email'),

  // Custom key generator for IP-based limiting
  byIP: (limitType = 'api') => {
    return createRateLimiter(limitType, (req) => {
      const ip = req.ip || req.connection.remoteAddress;
      return `${limitType}:ip:${ip}`;
    });
  }
};

/**
 * Get rate limit statistics (for monitoring)
 */
function getRateLimitStats() {
  const stats = {
    totalKeys: rateLimitStore.size,
    byType: {
      api: 0,
      auth: 0,
      email: 0,
      ip: 0
    }
  };

  for (const key of rateLimitStore.keys()) {
    if (key.startsWith('api:')) stats.byType.api++;
    else if (key.startsWith('auth:')) stats.byType.auth++;
    else if (key.startsWith('email:')) stats.byType.email++;
    else if (key.includes(':ip:')) stats.byType.ip++;
  }

  return stats;
}

// Log rate limit stats every 10 minutes
setInterval(() => {
  const stats = getRateLimitStats();
  logger.info('Rate limit statistics', stats);
}, 10 * 60 * 1000);

module.exports = {
  createRateLimiter,
  rateLimiters,
  getRateLimitStats
};
