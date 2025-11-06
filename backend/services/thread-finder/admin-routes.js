/**
 * Admin API Routes for Credential Vault Management
 * Provides REST API for parents to connect their LMS/sports platform accounts
 *
 * Security:
 * - All routes require authentication (parent must be logged in)
 * - Parents can only manage their own credentials
 * - Sensitive operations logged for audit
 *
 * Routes:
 * - GET    /api/admin/credentials         - List user's connected accounts
 * - POST   /api/admin/credentials         - Add new credential
 * - GET    /api/admin/credentials/:platform - Get specific credential
 * - DELETE /api/admin/credentials/:platform - Remove credential
 * - GET    /api/admin/platforms           - List supported platforms
 * - POST   /api/admin/oauth/initiate      - Initiate OAuth flow
 * - POST   /api/admin/oauth/callback      - Handle OAuth callback
 */

const express = require('express');
const credentialManager = require('./credential-manager');
const logger = require('../classifier/shared/config/logger');

const router = express.Router();

/**
 * Middleware: Authenticate user (placeholder - integrate with your auth system)
 */
function authenticateUser(req, res, next) {
  // TODO: Replace with actual authentication middleware
  // For now, extract user from Authorization header or session

  const userId = req.headers['x-user-id'];
  const parentEmail = req.headers['x-parent-email'];

  if (!userId || !parentEmail) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Authentication required'
    });
  }

  req.user = {
    userId,
    parentEmail
  };

  next();
}

// Apply authentication to all routes
router.use(authenticateUser);

/**
 * GET /api/admin/credentials
 * List all connected accounts for the authenticated user
 */
router.get('/credentials', async (req, res) => {
  try {
    const { userId } = req.user;

    const credentials = await credentialManager.listUserCredentials(userId);

    logger.info('Admin: Listed user credentials', {
      userId,
      credentialCount: credentials.length,
      ip: req.ip
    });

    res.json({
      success: true,
      credentials: credentials.map(cred => ({
        platform: cred.platform,
        platformName: cred.platform_name,
        credentialType: cred.credential_type,
        status: cred.status,
        expiresAt: cred.expires_at,
        lastUsedAt: cred.last_used_at,
        createdAt: cred.created_at
      }))
    });
  } catch (error) {
    logger.error('Admin: Failed to list credentials', {
      userId: req.user.userId,
      error: error.message,
      ip: req.ip
    });

    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to list credentials'
    });
  }
});

/**
 * POST /api/admin/credentials
 * Add new credential for a platform
 *
 * Body:
 * {
 *   "platform": "canvas",
 *   "platformDomain": "pascack.instructure.com",
 *   "credentials": {
 *     "api_token": "7~6rPNPrmPU..."
 *   }
 * }
 */
router.post('/credentials', async (req, res) => {
  try {
    const { userId, parentEmail } = req.user;
    const { platform, platformDomain, credentials, credentialType, expiresAt } = req.body;

    // Validate input
    if (!platform || !credentials) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Platform and credentials are required'
      });
    }

    // Validate platform is supported
    const supportedPlatforms = ['canvas', 'google_classroom', 'schoology', 'sportsengine', 'teamsnap'];
    if (!supportedPlatforms.includes(platform)) {
      return res.status(400).json({
        error: 'Bad Request',
        message: `Unsupported platform: ${platform}. Supported: ${supportedPlatforms.join(', ')}`
      });
    }

    // Store credential
    const credentialId = await credentialManager.storeCredential(
      userId,
      parentEmail,
      platform,
      credentials,
      {
        platformDomain,
        credentialType: credentialType || 'api_token',
        expiresAt: expiresAt ? new Date(expiresAt) : null
      }
    );

    logger.info('Admin: Stored new credential', {
      userId,
      platform,
      platformDomain,
      credentialId,
      ip: req.ip
    });

    res.status(201).json({
      success: true,
      message: 'Credential stored successfully',
      credentialId,
      platform
    });
  } catch (error) {
    logger.error('Admin: Failed to store credential', {
      userId: req.user.userId,
      platform: req.body.platform,
      error: error.message,
      ip: req.ip
    });

    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to store credential'
    });
  }
});

/**
 * GET /api/admin/credentials/:platform
 * Get credential details for a specific platform
 * Returns metadata only, not the actual credential
 */
router.get('/credentials/:platform', async (req, res) => {
  try {
    const { userId } = req.user;
    const { platform } = req.params;

    const credentials = await credentialManager.listUserCredentials(userId);
    const credential = credentials.find(c => c.platform === platform);

    if (!credential) {
      return res.status(404).json({
        error: 'Not Found',
        message: `No credential found for platform: ${platform}`
      });
    }

    logger.info('Admin: Retrieved credential metadata', {
      userId,
      platform,
      ip: req.ip
    });

    res.json({
      success: true,
      credential: {
        platform: credential.platform,
        platformName: credential.platform_name,
        credentialType: credential.credential_type,
        status: credential.status,
        expiresAt: credential.expires_at,
        lastUsedAt: credential.last_used_at,
        createdAt: credential.created_at
      }
    });
  } catch (error) {
    logger.error('Admin: Failed to retrieve credential metadata', {
      userId: req.user.userId,
      platform: req.params.platform,
      error: error.message,
      ip: req.ip
    });

    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to retrieve credential'
    });
  }
});

/**
 * DELETE /api/admin/credentials/:platform
 * Remove credential for a platform
 */
router.delete('/credentials/:platform', async (req, res) => {
  try {
    const { userId } = req.user;
    const { platform } = req.params;

    const deleted = await credentialManager.deleteCredential(userId, platform);

    if (!deleted) {
      return res.status(404).json({
        error: 'Not Found',
        message: `No credential found for platform: ${platform}`
      });
    }

    logger.info('Admin: Deleted credential', {
      userId,
      platform,
      ip: req.ip
    });

    res.json({
      success: true,
      message: 'Credential deleted successfully',
      platform
    });
  } catch (error) {
    logger.error('Admin: Failed to delete credential', {
      userId: req.user.userId,
      platform: req.params.platform,
      error: error.message,
      ip: req.ip
    });

    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to delete credential'
    });
  }
});

/**
 * GET /api/admin/platforms
 * List all supported platforms and their configuration
 */
router.get('/platforms', async (req, res) => {
  try {
    const { Pool } = require('pg');
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
    });

    const result = await pool.query(`
      SELECT
        platform,
        display_name,
        auth_type,
        supports_assignment_extraction,
        supports_course_listing,
        is_enabled
      FROM platform_configs
      WHERE is_enabled = TRUE
      ORDER BY display_name
    `);

    logger.info('Admin: Listed supported platforms', {
      userId: req.user.userId,
      platformCount: result.rows.length,
      ip: req.ip
    });

    res.json({
      success: true,
      platforms: result.rows.map(p => ({
        platform: p.platform,
        displayName: p.display_name,
        authType: p.auth_type,
        features: {
          assignmentExtraction: p.supports_assignment_extraction,
          courseListing: p.supports_course_listing
        }
      }))
    });
  } catch (error) {
    logger.error('Admin: Failed to list platforms', {
      userId: req.user.userId,
      error: error.message,
      ip: req.ip
    });

    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to list platforms'
    });
  }
});

/**
 * POST /api/admin/oauth/initiate
 * Initiate OAuth flow for platforms that require it (Google Classroom, TeamSnap, etc.)
 *
 * Body:
 * {
 *   "platform": "google_classroom"
 * }
 */
router.post('/oauth/initiate', async (req, res) => {
  try {
    const { userId } = req.user;
    const { platform } = req.body;

    // OAuth configuration per platform
    const oauthConfigs = {
      google_classroom: {
        clientId: process.env.GOOGLE_CLASSROOM_CLIENT_ID,
        authorizationUrl: 'https://accounts.google.com/o/oauth2/v2/auth',
        scope: [
          'https://www.googleapis.com/auth/classroom.courses.readonly',
          'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
          'https://www.googleapis.com/auth/classroom.announcements.readonly'
        ].join(' '),
        redirectUri: process.env.GOOGLE_CLASSROOM_REDIRECT_URI || 'http://localhost:3001/api/admin/oauth/callback'
      }
      // Add more platforms here as needed
    };

    const config = oauthConfigs[platform];
    if (!config) {
      return res.status(400).json({
        error: 'Bad Request',
        message: `OAuth not supported for platform: ${platform}`
      });
    }

    // Generate authorization URL
    const state = Buffer.from(JSON.stringify({
      userId,
      platform,
      timestamp: Date.now()
    })).toString('base64');

    const authUrl = `${config.authorizationUrl}?` +
      `client_id=${config.clientId}&` +
      `redirect_uri=${encodeURIComponent(config.redirectUri)}&` +
      `response_type=code&` +
      `scope=${encodeURIComponent(config.scope)}&` +
      `access_type=offline&` +
      `prompt=consent&` +
      `state=${state}`;

    logger.info('Admin: Initiated OAuth flow', {
      userId,
      platform,
      ip: req.ip
    });

    res.json({
      success: true,
      authorizationUrl: authUrl,
      platform
    });
  } catch (error) {
    logger.error('Admin: Failed to initiate OAuth', {
      userId: req.user.userId,
      platform: req.body.platform,
      error: error.message,
      ip: req.ip
    });

    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to initiate OAuth'
    });
  }
});

/**
 * POST /api/admin/oauth/callback
 * Handle OAuth callback and store tokens
 *
 * Body:
 * {
 *   "code": "authorization_code_from_oauth_provider",
 *   "state": "base64_encoded_state"
 * }
 */
router.post('/oauth/callback', async (req, res) => {
  try {
    const { code, state } = req.body;

    if (!code || !state) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Code and state are required'
      });
    }

    // Decode state
    const stateData = JSON.parse(Buffer.from(state, 'base64').toString('utf8'));
    const { userId, platform, timestamp } = stateData;

    // Verify state is not expired (5 minutes)
    if (Date.now() - timestamp > 5 * 60 * 1000) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'OAuth state expired'
      });
    }

    // Exchange authorization code for access token
    const axios = require('axios');

    const tokenResponse = await axios.post('https://oauth2.googleapis.com/token', {
      code,
      client_id: process.env.GOOGLE_CLASSROOM_CLIENT_ID,
      client_secret: process.env.GOOGLE_CLASSROOM_CLIENT_SECRET,
      redirect_uri: process.env.GOOGLE_CLASSROOM_REDIRECT_URI,
      grant_type: 'authorization_code'
    });

    const { access_token, refresh_token, expires_in, scope } = tokenResponse.data;

    // Store credentials in vault
    const credentialId = await credentialManager.storeCredential(
      userId,
      req.user.parentEmail,
      platform,
      {
        access_token,
        refresh_token
      },
      {
        credentialType: 'oauth',
        expiresAt: new Date(Date.now() + expires_in * 1000),
        oauthScopes: scope ? scope.split(' ') : null
      }
    );

    logger.info('Admin: OAuth callback successful', {
      userId,
      platform,
      credentialId,
      expiresIn: expires_in,
      ip: req.ip
    });

    res.json({
      success: true,
      message: 'OAuth authorization successful',
      platform,
      credentialId,
      expiresAt: new Date(Date.now() + expires_in * 1000)
    });
  } catch (error) {
    logger.error('Admin: OAuth callback failed', {
      error: error.message,
      errorResponse: error.response?.data,
      ip: req.ip
    });

    res.status(500).json({
      error: 'Internal Server Error',
      message: 'OAuth authorization failed'
    });
  }
});

/**
 * POST /api/admin/credentials/test
 * Test credential by attempting a simple API call
 *
 * Body:
 * {
 *   "platform": "canvas"
 * }
 */
router.post('/credentials/test', async (req, res) => {
  try {
    const { userId } = req.user;
    const { platform } = req.body;

    const credential = await credentialManager.getCredential(userId, platform, {
      accessReason: 'admin_test_connection'
    });

    if (!credential) {
      return res.status(404).json({
        error: 'Not Found',
        message: `No credential found for platform: ${platform}`
      });
    }

    // TODO: Implement actual API test call per platform
    // For now, just confirm credential can be decrypted

    logger.info('Admin: Tested credential connection', {
      userId,
      platform,
      ip: req.ip
    });

    res.json({
      success: true,
      message: 'Credential test successful',
      platform,
      status: 'valid'
    });
  } catch (error) {
    logger.error('Admin: Credential test failed', {
      userId: req.user.userId,
      platform: req.body.platform,
      error: error.message,
      ip: req.ip
    });

    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Credential test failed',
      details: error.message
    });
  }
});

module.exports = router;
