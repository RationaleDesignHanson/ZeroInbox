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
 * Store user tokens securely (in production, use a database)
 * Using file-based storage for persistence across restarts
 */
const fs = require('fs');
const path = require('path');

const TOKEN_DIR = path.join(__dirname, '../../data/tokens');

// Ensure token directory exists
if (!fs.existsSync(TOKEN_DIR)) {
  fs.mkdirSync(TOKEN_DIR, { recursive: true });
}

function storeUserTokens(userId, provider, tokens) {
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
  logger.info('Tokens stored', { userId, provider });
}

function getUserTokens(userId, provider) {
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
}

function deleteUserTokens(userId, provider) {
  const key = `${userId}_${provider}`;
  const filePath = path.join(TOKEN_DIR, `${key}.json`);

  if (fs.existsSync(filePath)) {
    fs.unlinkSync(filePath);
    logger.info('Tokens deleted', { userId, provider });
  }
}

module.exports = {
  generateToken,
  verifyToken,
  authenticateRequest,
  storeUserTokens,
  getUserTokens,
  deleteUserTokens
};
