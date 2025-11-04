const jwt = require('jsonwebtoken');
const logger = require('../config/logger');

const JWT_SECRET = process.env.JWT_SECRET || 'default-secret-change-in-production';
const JWT_EXPIRATION = '7d';

/**
 * Generate JWT token for authenticated user
 */
function generateToken(userId, emailProvider, email) {
  return jwt.sign(
    {
      userId,
      emailProvider,
      email,
      iat: Math.floor(Date.now() / 1000)
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRATION }
  );
}

/**
 * Verify JWT token
 */
function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    logger.error('Token verification failed', { error: error.message });
    return null;
  }
}

/**
 * Middleware to authenticate requests
 */
function authenticateRequest(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const token = authHeader.substring(7);
  const decoded = verifyToken(token);

  if (!decoded) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }

  req.user = decoded;
  next();
}

/**
 * Token storage implementation
 * Supports both file-based storage (development) and Firestore (production)
 * Set USE_FIRESTORE=true to use Firestore
 */
const USE_FIRESTORE = process.env.USE_FIRESTORE === 'true';

// Import appropriate token store implementation
let tokenStore;

if (USE_FIRESTORE) {
  // Use Firestore for production (removes instance affinity issues)
  tokenStore = require('./tokenStore');
  logger.info('Using Firestore for token storage');
} else {
  // Use file-based storage for development
  const fs = require('fs');
  const path = require('path');

  const TOKEN_DIR = path.join(__dirname, '../../data/tokens');

  // Ensure token directory exists
  if (!fs.existsSync(TOKEN_DIR)) {
    fs.mkdirSync(TOKEN_DIR, { recursive: true });
  }

  tokenStore = {
    storeUserTokens: function(userId, provider, tokens) {
      const key = `${userId}_${provider}`;
      const filePath = path.join(TOKEN_DIR, `${key}.json`);

      const data = {
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresAt: tokens.expiresAt,
        email: tokens.email,
        updatedAt: Date.now()
      };

      fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
      logger.info('Tokens stored (file-based)', { userId, provider });
    },

    getUserTokens: function(userId, provider) {
      const key = `${userId}_${provider}`;
      const filePath = path.join(TOKEN_DIR, `${key}.json`);

      if (!fs.existsSync(filePath)) {
        return null;
      }

      try {
        const data = fs.readFileSync(filePath, 'utf-8');
        return JSON.parse(data);
      } catch (error) {
        logger.error('Error reading token file', { error: error.message });
        return null;
      }
    },

    deleteUserTokens: function(userId, provider) {
      const key = `${userId}_${provider}`;
      const filePath = path.join(TOKEN_DIR, `${key}.json`);

      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        logger.info('Tokens deleted (file-based)', { userId, provider });
      }
    }
  };

  logger.info('Using file-based storage for tokens');
}

// Export unified interface (async for Firestore, sync for file-based)
async function storeUserTokens(userId, provider, tokens) {
  return await tokenStore.storeUserTokens(userId, provider, tokens);
}

async function getUserTokens(userId, provider) {
  return await tokenStore.getUserTokens(userId, provider);
}

async function deleteUserTokens(userId, provider) {
  return await tokenStore.deleteUserTokens(userId, provider);
}

module.exports = {
  generateToken,
  verifyToken,
  authenticateRequest,
  storeUserTokens,
  getUserTokens,
  deleteUserTokens
};
