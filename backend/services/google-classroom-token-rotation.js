/**
 * Google Classroom OAuth Token Rotation
 * Automatically refreshes access tokens before expiration
 *
 * Features:
 * - Refreshes access token using refresh token
 * - Updates Secret Manager with new token
 * - Runs on schedule (every 50 minutes for 1-hour tokens)
 * - Audit logging for compliance
 * - Graceful error handling with retries
 *
 * Setup:
 * 1. Ensure GOOGLE_CLASSROOM_CLIENT_ID and CLIENT_SECRET are in Secret Manager
 * 2. Store GOOGLE_CLASSROOM_REFRESH_TOKEN in Secret Manager
 * 3. Run: node services/google-classroom-token-rotation.js
 *
 * For production: Run as cron job or Cloud Scheduler task
 */

const https = require('https');
const secretsManager = require('./secrets-manager');
const fs = require('fs');
const path = require('path');

// Configuration
const ROTATION_INTERVAL_MS = 50 * 60 * 1000; // 50 minutes (tokens expire in 1 hour)
const RETRY_ATTEMPTS = 3;
const RETRY_DELAY_MS = 5000;

// Audit log path
const AUDIT_LOG_PATH = path.join(__dirname, '../logs/credential-audit.log');

/**
 * Write audit log entry
 */
function auditLog(action, details) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    action,
    service: 'google-classroom',
    ...details
  };

  const logLine = JSON.stringify(logEntry) + '\n';

  // Ensure logs directory exists
  const logDir = path.dirname(AUDIT_LOG_PATH);
  if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
  }

  // Append to log file
  fs.appendFileSync(AUDIT_LOG_PATH, logLine);

  // Also log to console
  console.log(`[Audit] ${action}:`, details);
}

/**
 * Refresh Google OAuth token
 * @param {string} clientId - OAuth client ID
 * @param {string} clientSecret - OAuth client secret
 * @param {string} refreshToken - Refresh token
 * @returns {Promise<Object>} New token data
 */
async function refreshAccessToken(clientId, clientSecret, refreshToken) {
  return new Promise((resolve, reject) => {
    const postData = new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      refresh_token: refreshToken,
      grant_type: 'refresh_token'
    }).toString();

    const options = {
      hostname: 'oauth2.googleapis.com',
      port: 443,
      path: '/token',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const tokenData = JSON.parse(data);

          if (res.statusCode === 200) {
            resolve(tokenData);
          } else {
            reject(new Error(`Token refresh failed: ${tokenData.error_description || tokenData.error}`));
          }
        } catch (error) {
          reject(new Error(`Failed to parse token response: ${error.message}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(new Error(`Token refresh request failed: ${error.message}`));
    });

    req.write(postData);
    req.end();
  });
}

/**
 * Rotate Google Classroom token with retries
 */
async function rotateToken(attempt = 1) {
  try {
    console.log(`\n${'='.repeat(80)}`);
    console.log(`🔄 Google Classroom Token Rotation (Attempt ${attempt}/${RETRY_ATTEMPTS})`);
    console.log(`⏰ ${new Date().toISOString()}`);
    console.log('='.repeat(80));

    // Load credentials from Secret Manager
    console.log('📥 Loading credentials from Secret Manager...');
    const clientId = await secretsManager.getSecret('GOOGLE_CLASSROOM_CLIENT_ID');
    const clientSecret = await secretsManager.getSecret('GOOGLE_CLASSROOM_CLIENT_SECRET');
    const refreshToken = await secretsManager.getSecret('GOOGLE_CLASSROOM_REFRESH_TOKEN');

    if (!clientId || !clientSecret || !refreshToken) {
      throw new Error('Missing required OAuth credentials in Secret Manager');
    }

    auditLog('credentials_loaded', {
      success: true,
      source: 'secret_manager'
    });

    // Refresh access token
    console.log('🔑 Refreshing access token...');
    const tokenData = await refreshAccessToken(clientId, clientSecret, refreshToken);

    console.log('✅ New access token received');
    console.log(`   Expires in: ${tokenData.expires_in} seconds`);
    console.log(`   Token type: ${tokenData.token_type}`);

    // Store new token in Secret Manager
    console.log('💾 Storing new token in Secret Manager...');
    await secretsManager.rotateSecret('GOOGLE_CLASSROOM_TOKEN', tokenData.access_token);

    auditLog('token_rotated', {
      success: true,
      expires_in: tokenData.expires_in,
      rotation_time: new Date().toISOString(),
      attempt
    });

    console.log('✅ Token rotation complete!');
    console.log(`📅 Next rotation scheduled in ${ROTATION_INTERVAL_MS / 60000} minutes`);
    console.log('='.repeat(80));

    return true;

  } catch (error) {
    console.error(`❌ Token rotation failed (attempt ${attempt}):`, error.message);

    auditLog('token_rotation_failed', {
      success: false,
      error: error.message,
      attempt,
      timestamp: new Date().toISOString()
    });

    // Retry with exponential backoff
    if (attempt < RETRY_ATTEMPTS) {
      const delay = RETRY_DELAY_MS * Math.pow(2, attempt - 1);
      console.log(`⏳ Retrying in ${delay / 1000} seconds...`);
      await new Promise(resolve => setTimeout(resolve, delay));
      return rotateToken(attempt + 1);
    } else {
      console.error('❌ All retry attempts exhausted');

      auditLog('token_rotation_exhausted', {
        success: false,
        error: 'Maximum retry attempts reached',
        attempts: RETRY_ATTEMPTS
      });

      throw error;
    }
  }
}

/**
 * Start token rotation scheduler
 */
async function startRotationScheduler() {
  console.log('\n🚀 Starting Google Classroom Token Rotation Service');
  console.log(`⏰ Rotation interval: ${ROTATION_INTERVAL_MS / 60000} minutes`);
  console.log(`📝 Audit log: ${AUDIT_LOG_PATH}\n`);

  auditLog('rotation_service_started', {
    interval_minutes: ROTATION_INTERVAL_MS / 60000,
    start_time: new Date().toISOString()
  });

  // Perform initial rotation
  try {
    await rotateToken();
  } catch (error) {
    console.error('⚠️  Initial token rotation failed, will retry on schedule');
  }

  // Schedule recurring rotations
  setInterval(async () => {
    try {
      await rotateToken();
    } catch (error) {
      console.error('⚠️  Scheduled rotation failed, will retry on next interval');
    }
  }, ROTATION_INTERVAL_MS);

  console.log('✅ Token rotation scheduler running...\n');
}

/**
 * Manual token rotation (for testing or one-off rotations)
 */
async function manualRotation() {
  console.log('🔧 Manual token rotation initiated\n');

  try {
    await rotateToken();
    console.log('\n✅ Manual rotation complete!');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Manual rotation failed:', error.message);
    process.exit(1);
  }
}

// Export functions
module.exports = {
  rotateToken,
  startRotationScheduler,
  manualRotation,
  auditLog
};

// Run as standalone script
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.includes('--manual') || args.includes('-m')) {
    manualRotation();
  } else {
    startRotationScheduler();
  }
}
