const { Firestore } = require('@google-cloud/firestore');
const logger = require('../config/logger');

// Initialize Firestore
const firestore = new Firestore({
  projectId: process.env.GOOGLE_CLOUD_PROJECT || 'gen-lang-client-0622702687'
});

const TOKENS_COLLECTION = 'user_tokens';

/**
 * Store user OAuth tokens in Firestore
 * @param {string} userId - User ID
 * @param {string} provider - Email provider (gmail, outlook, etc.)
 * @param {Object} tokens - Token data
 * @param {string} tokens.accessToken - OAuth access token
 * @param {string} tokens.refreshToken - OAuth refresh token
 * @param {number} tokens.expiresAt - Token expiration timestamp
 * @param {string} tokens.email - User's email address
 */
async function storeUserTokens(userId, provider, tokens) {
  try {
    const docId = `${userId}_${provider}`;
    const docRef = firestore.collection(TOKENS_COLLECTION).doc(docId);

    const data = {
      userId,
      provider,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresAt: tokens.expiresAt,
      email: tokens.email,
      updatedAt: Firestore.Timestamp.now(),
      createdAt: Firestore.FieldValue.serverTimestamp()
    };

    await docRef.set(data, { merge: true });
    logger.info('Tokens stored in Firestore', { userId, provider });
  } catch (error) {
    logger.error('Error storing tokens in Firestore', {
      userId,
      provider,
      error: error.message
    });
    throw error;
  }
}

/**
 * Retrieve user OAuth tokens from Firestore
 * @param {string} userId - User ID
 * @param {string} provider - Email provider
 * @returns {Object|null} Token data or null if not found
 */
async function getUserTokens(userId, provider) {
  try {
    const docId = `${userId}_${provider}`;
    const docRef = firestore.collection(TOKENS_COLLECTION).doc(docId);
    const doc = await docRef.get();

    if (!doc.exists) {
      logger.warn('No tokens found in Firestore', { userId, provider });
      return null;
    }

    const data = doc.data();

    // Convert Firestore Timestamp to milliseconds for expiresAt
    return {
      accessToken: data.accessToken,
      refreshToken: data.refreshToken,
      expiresAt: data.expiresAt,
      email: data.email,
      updatedAt: data.updatedAt?.toMillis?.() || Date.now()
    };
  } catch (error) {
    logger.error('Error retrieving tokens from Firestore', {
      userId,
      provider,
      error: error.message
    });
    return null;
  }
}

/**
 * Delete user OAuth tokens from Firestore
 * @param {string} userId - User ID
 * @param {string} provider - Email provider
 */
async function deleteUserTokens(userId, provider) {
  try {
    const docId = `${userId}_${provider}`;
    const docRef = firestore.collection(TOKENS_COLLECTION).doc(docId);
    await docRef.delete();
    logger.info('Tokens deleted from Firestore', { userId, provider });
  } catch (error) {
    logger.error('Error deleting tokens from Firestore', {
      userId,
      provider,
      error: error.message
    });
    throw error;
  }
}

/**
 * Update access token after refresh (keeps refresh token unchanged)
 * @param {string} userId - User ID
 * @param {string} provider - Email provider
 * @param {string} newAccessToken - New access token
 * @param {number} expiresAt - New expiration timestamp
 */
async function updateAccessToken(userId, provider, newAccessToken, expiresAt) {
  try {
    const docId = `${userId}_${provider}`;
    const docRef = firestore.collection(TOKENS_COLLECTION).doc(docId);

    await docRef.update({
      accessToken: newAccessToken,
      expiresAt: expiresAt,
      updatedAt: Firestore.Timestamp.now()
    });

    logger.info('Access token updated in Firestore', { userId, provider });
  } catch (error) {
    logger.error('Error updating access token in Firestore', {
      userId,
      provider,
      error: error.message
    });
    throw error;
  }
}

/**
 * List all users with stored tokens (for admin/migration purposes)
 * @returns {Array} Array of user token documents
 */
async function listAllTokens() {
  try {
    const snapshot = await firestore.collection(TOKENS_COLLECTION).get();
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    logger.error('Error listing tokens from Firestore', { error: error.message });
    throw error;
  }
}

module.exports = {
  storeUserTokens,
  getUserTokens,
  deleteUserTokens,
  updateAccessToken,
  listAllTokens
};
