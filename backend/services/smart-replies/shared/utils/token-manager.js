/**
 * Token Manager
 * Handles automatic OAuth token refresh, persistence, and lifecycle management
 * Prevents re-authentication issues by keeping tokens fresh and persisted
 */

const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');
const logger = require('../config/logger');
const { storeUserTokens, getUserTokens } = require('./auth');

const TOKEN_DIR = path.join(__dirname, '../../data/tokens');
const REFRESH_BUFFER = 5 * 60 * 1000; // Refresh 5 minutes before expiry

// Track token refresh attempts and failures
const refreshAttempts = new Map(); // userId -> { attempts: number, lastAttempt: timestamp }
const MAX_REFRESH_ATTEMPTS = 3;
const ATTEMPT_RESET_TIME = 15 * 60 * 1000; // Reset after 15 minutes

/**
 * Create an OAuth2 client with automatic token refresh handling
 */
function createOAuth2Client(userId, provider, tokens) {
  const oauth2Client = new google.auth.OAuth2(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    process.env.GOOGLE_REDIRECT_URI
  );

  // Set initial credentials
  oauth2Client.setCredentials({
    access_token: tokens.accessToken,
    refresh_token: tokens.refreshToken,
    expiry_date: tokens.expiresAt
  });

  // Listen for automatic token refresh events
  oauth2Client.on('tokens', (newTokens) => {
    handleTokenRefresh(userId, provider, tokens, newTokens);
  });

  return oauth2Client;
}

/**
 * Handle token refresh event - persist new tokens immediately
 */
function handleTokenRefresh(userId, provider, oldTokens, newTokens) {
  try {
    logger.info('🔄 Token refresh detected', {
      userId,
      provider,
      hasNewAccessToken: !!newTokens.access_token,
      hasNewRefreshToken: !!newTokens.refresh_token,
      newExpiry: newTokens.expiry_date
    });

    // Prepare updated tokens
    const updatedTokens = {
      accessToken: newTokens.access_token || oldTokens.accessToken,
      refreshToken: newTokens.refresh_token || oldTokens.refreshToken,
      expiresAt: newTokens.expiry_date || oldTokens.expiresAt,
      email: oldTokens.email,
      refreshedAt: Date.now()
    };

    // Persist to disk immediately
    storeUserTokens(userId, provider, updatedTokens);

    // Reset failed attempts counter on successful refresh
    refreshAttempts.delete(userId);

    logger.info('✅ Tokens refreshed and persisted successfully', {
      userId,
      provider,
      expiresAt: new Date(updatedTokens.expiresAt).toISOString()
    });

  } catch (error) {
    logger.error('❌ Failed to persist refreshed tokens', {
      userId,
      provider,
      error: error.message
    });

    // Track failed refresh attempt
    trackFailedRefresh(userId);
  }
}

/**
 * Track failed token refresh attempts
 */
function trackFailedRefresh(userId) {
  const now = Date.now();
  const existing = refreshAttempts.get(userId);

  if (existing && (now - existing.lastAttempt) < ATTEMPT_RESET_TIME) {
    // Within reset window - increment attempts
    existing.attempts++;
    existing.lastAttempt = now;
    refreshAttempts.set(userId, existing);

    if (existing.attempts >= MAX_REFRESH_ATTEMPTS) {
      logger.warn('⚠️ Max refresh attempts reached - user needs re-authentication', {
        userId,
        attempts: existing.attempts
      });

      // Mark user for re-authentication (will be checked by auth-status endpoint)
      markUserForReauth(userId);
    }
  } else {
    // First attempt or outside reset window
    refreshAttempts.set(userId, { attempts: 1, lastAttempt: now });
  }
}

/**
 * Mark user as needing re-authentication
 */
function markUserForReauth(userId) {
  const flagFile = path.join(TOKEN_DIR, `${userId}_needs_reauth.flag`);

  try {
    fs.writeFileSync(flagFile, JSON.stringify({
      needsReauth: true,
      markedAt: Date.now(),
      reason: 'Token refresh failed after multiple attempts'
    }));

    logger.info('🚨 User marked for re-authentication', { userId });
  } catch (error) {
    logger.error('Failed to create reauth flag', { userId, error: error.message });
  }
}

/**
 * Check if user needs re-authentication
 */
function needsReauth(userId) {
  const flagFile = path.join(TOKEN_DIR, `${userId}_needs_reauth.flag`);
  return fs.existsSync(flagFile);
}

/**
 * Clear re-authentication flag (after successful re-auth)
 */
function clearReauthFlag(userId) {
  const flagFile = path.join(TOKEN_DIR, `${userId}_needs_reauth.flag`);

  if (fs.existsSync(flagFile)) {
    fs.unlinkSync(flagFile);
    logger.info('✅ Re-authentication flag cleared', { userId });
  }
}

/**
 * Check if token is expired or expiring soon
 */
function isTokenExpiring(tokens) {
  if (!tokens.expiresAt) {
    return false; // No expiry info
  }

  const now = Date.now();
  const expiresAt = tokens.expiresAt;
  const timeUntilExpiry = expiresAt - now;

  return timeUntilExpiry < REFRESH_BUFFER;
}

/**
 * Check if token is already expired
 */
function isTokenExpired(tokens) {
  if (!tokens.expiresAt) {
    return false; // No expiry info
  }

  return Date.now() >= tokens.expiresAt;
}

/**
 * Proactively refresh token if expiring soon
 */
async function refreshTokenIfNeeded(userId, provider) {
  try {
    const tokens = getUserTokens(userId, provider);

    if (!tokens) {
      logger.warn('No tokens found for proactive refresh', { userId, provider });
      return null;
    }

    // Check if refresh is needed
    if (!isTokenExpiring(tokens)) {
      const timeUntilExpiry = tokens.expiresAt - Date.now();
      logger.debug('Token still fresh, no refresh needed', {
        userId,
        provider,
        minutesUntilExpiry: Math.floor(timeUntilExpiry / 60000)
      });
      return tokens;
    }

    // Token is expiring soon - refresh it
    logger.info('⏰ Token expiring soon, refreshing proactively', {
      userId,
      provider,
      expiresAt: new Date(tokens.expiresAt).toISOString()
    });

    const oauth2Client = createOAuth2Client(userId, provider, tokens);

    // Request a token refresh
    const { credentials } = await oauth2Client.refreshAccessToken();

    // The 'tokens' event will handle persistence automatically
    logger.info('✅ Proactive token refresh successful', {
      userId,
      provider,
      newExpiry: credentials.expiry_date
    });

    // Return fresh tokens
    return {
      accessToken: credentials.access_token,
      refreshToken: credentials.refresh_token || tokens.refreshToken,
      expiresAt: credentials.expiry_date,
      email: tokens.email
    };

  } catch (error) {
    logger.error('❌ Proactive token refresh failed', {
      userId,
      provider,
      error: error.message
    });

    // Track failure
    trackFailedRefresh(userId);

    return null;
  }
}

/**
 * Get OAuth2 client with automatic token management
 */
async function getManagedOAuth2Client(userId, provider = 'gmail') {
  try {
    // Get current tokens
    let tokens = getUserTokens(userId, provider);

    if (!tokens) {
      logger.error('No tokens found for user', { userId, provider });
      return null;
    }

    // Proactively refresh if expiring soon
    if (isTokenExpiring(tokens)) {
      const freshTokens = await refreshTokenIfNeeded(userId, provider);
      if (freshTokens) {
        tokens = freshTokens;
      }
    }

    // Create client with automatic refresh handling
    return createOAuth2Client(userId, provider, tokens);

  } catch (error) {
    logger.error('Failed to create managed OAuth2 client', {
      userId,
      provider,
      error: error.message
    });
    return null;
  }
}

/**
 * Get token health status
 */
function getTokenHealth(userId, provider = 'gmail') {
  try {
    const tokens = getUserTokens(userId, provider);

    if (!tokens) {
      return {
        status: 'missing',
        message: 'No tokens found',
        needsReauth: true
      };
    }

    if (needsReauth(userId)) {
      return {
        status: 'expired',
        message: 'Re-authentication required',
        needsReauth: true,
        expiresAt: tokens.expiresAt,
        refreshedAt: tokens.refreshedAt
      };
    }

    if (isTokenExpired(tokens)) {
      return {
        status: 'expired',
        message: 'Token has expired',
        needsReauth: true,
        expiresAt: tokens.expiresAt,
        refreshedAt: tokens.refreshedAt
      };
    }

    if (isTokenExpiring(tokens)) {
      const minutesUntilExpiry = Math.floor((tokens.expiresAt - Date.now()) / 60000);
      return {
        status: 'expiring',
        message: `Token expires in ${minutesUntilExpiry} minutes`,
        needsReauth: false,
        expiresAt: tokens.expiresAt,
        refreshedAt: tokens.refreshedAt,
        minutesUntilExpiry
      };
    }

    const minutesUntilExpiry = Math.floor((tokens.expiresAt - Date.now()) / 60000);
    return {
      status: 'healthy',
      message: 'Token is valid',
      needsReauth: false,
      expiresAt: tokens.expiresAt,
      refreshedAt: tokens.refreshedAt,
      minutesUntilExpiry
    };

  } catch (error) {
    logger.error('Failed to check token health', { userId, provider, error: error.message });
    return {
      status: 'error',
      message: 'Failed to check token status',
      needsReauth: true
    };
  }
}

/**
 * Get all authenticated users with token status
 */
function getAllUserTokenStatus() {
  try {
    if (!fs.existsSync(TOKEN_DIR)) {
      return [];
    }

    const tokenFiles = fs.readdirSync(TOKEN_DIR)
      .filter(f => f.endsWith('_gmail.json'));

    return tokenFiles.map(file => {
      const userId = file.replace('_gmail.json', '');
      const health = getTokenHealth(userId, 'gmail');

      return {
        userId,
        provider: 'gmail',
        ...health
      };
    });

  } catch (error) {
    logger.error('Failed to get all user token status', { error: error.message });
    return [];
  }
}

module.exports = {
  createOAuth2Client,
  getManagedOAuth2Client,
  refreshTokenIfNeeded,
  isTokenExpiring,
  isTokenExpired,
  needsReauth,
  clearReauthFlag,
  markUserForReauth,
  getTokenHealth,
  getAllUserTokenStatus
};
