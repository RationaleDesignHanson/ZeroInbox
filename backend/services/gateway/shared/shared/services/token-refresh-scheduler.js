/**
 * Token Refresh Scheduler
 * Background service that proactively refreshes OAuth tokens before expiry
 * Prevents re-authentication issues by keeping tokens fresh even during inactivity
 */

const logger = require('../config/logger');
const {
  getAllUserTokenStatus,
  refreshTokenIfNeeded
} = require('../utils/token-manager');

// Configuration
const REFRESH_INTERVAL = 60 * 60 * 1000; // Check every hour
const REFRESH_THRESHOLD = 10 * 60 * 1000; // Refresh if expiring within 10 minutes

let schedulerInterval = null;
let isRunning = false;

/**
 * Start the token refresh scheduler
 */
function startTokenRefreshScheduler() {
  if (isRunning) {
    logger.warn('Token refresh scheduler already running');
    return;
  }

  logger.info('🔄 Starting token refresh scheduler', {
    checkInterval: `${REFRESH_INTERVAL / 60000} minutes`,
    refreshThreshold: `${REFRESH_THRESHOLD / 60000} minutes`
  });

  // Run immediately on start
  runRefreshCycle();

  // Schedule periodic refresh checks
  schedulerInterval = setInterval(() => {
    runRefreshCycle();
  }, REFRESH_INTERVAL);

  isRunning = true;

  logger.info('✅ Token refresh scheduler started');
}

/**
 * Stop the token refresh scheduler
 */
function stopTokenRefreshScheduler() {
  if (!isRunning) {
    logger.warn('Token refresh scheduler not running');
    return;
  }

  if (schedulerInterval) {
    clearInterval(schedulerInterval);
    schedulerInterval = null;
  }

  isRunning = false;
  logger.info('⏹️ Token refresh scheduler stopped');
}

/**
 * Run a single refresh cycle
 * Checks all users and refreshes tokens that are expiring soon
 */
async function runRefreshCycle() {
  try {
    logger.info('🔍 Running token refresh cycle');

    // Get status for all users
    const allUsers = getAllUserTokenStatus();

    if (!allUsers || allUsers.length === 0) {
      logger.info('No users to check for token refresh');
      return;
    }

    logger.info(`Checking ${allUsers.length} users for token refresh`);

    // Check each user and refresh if needed
    const refreshResults = await Promise.allSettled(
      allUsers.map(async (user) => {
        try {
          // Skip if already expired or needs reauth
          if (user.status === 'expired' || user.needsReauth) {
            logger.debug('Skipping user - needs reauth', {
              userId: user.userId,
              status: user.status
            });
            return { userId: user.userId, action: 'skipped', reason: 'needs_reauth' };
          }

          // Skip if token is healthy and not expiring soon
          if (user.status === 'healthy' && user.minutesUntilExpiry > (REFRESH_THRESHOLD / 60000)) {
            logger.debug('Skipping user - token healthy', {
              userId: user.userId,
              minutesUntilExpiry: user.minutesUntilExpiry
            });
            return { userId: user.userId, action: 'skipped', reason: 'healthy' };
          }

          // Token is expiring soon - refresh it
          logger.info('⏰ Proactively refreshing token', {
            userId: user.userId,
            provider: user.provider,
            status: user.status,
            minutesUntilExpiry: user.minutesUntilExpiry
          });

          const freshTokens = await refreshTokenIfNeeded(user.userId, user.provider);

          if (freshTokens) {
            logger.info('✅ Token refreshed successfully', {
              userId: user.userId,
              provider: user.provider,
              newExpiresAt: new Date(freshTokens.expiresAt).toISOString()
            });
            return { userId: user.userId, action: 'refreshed', success: true };
          } else {
            logger.warn('⚠️ Token refresh returned null', {
              userId: user.userId,
              provider: user.provider
            });
            return { userId: user.userId, action: 'failed', reason: 'refresh_returned_null' };
          }

        } catch (error) {
          logger.error('❌ Token refresh failed for user', {
            userId: user.userId,
            provider: user.provider,
            error: error.message
          });
          return { userId: user.userId, action: 'failed', error: error.message };
        }
      })
    );

    // Summarize results
    const summary = {
      total: allUsers.length,
      refreshed: 0,
      skipped: 0,
      failed: 0
    };

    refreshResults.forEach(result => {
      if (result.status === 'fulfilled') {
        const value = result.value;
        if (value.action === 'refreshed') summary.refreshed++;
        else if (value.action === 'skipped') summary.skipped++;
        else if (value.action === 'failed') summary.failed++;
      } else {
        summary.failed++;
      }
    });

    logger.info('✅ Token refresh cycle complete', summary);

  } catch (error) {
    logger.error('❌ Token refresh cycle error', {
      error: error.message,
      stack: error.stack
    });
  }
}

/**
 * Get scheduler status
 */
function getSchedulerStatus() {
  return {
    isRunning,
    checkInterval: REFRESH_INTERVAL,
    refreshThreshold: REFRESH_THRESHOLD,
    nextRun: isRunning ? new Date(Date.now() + REFRESH_INTERVAL).toISOString() : null
  };
}

/**
 * Manually trigger a refresh cycle (for testing/debugging)
 */
async function triggerManualRefresh() {
  logger.info('🔧 Manual token refresh triggered');
  await runRefreshCycle();
}

module.exports = {
  startTokenRefreshScheduler,
  stopTokenRefreshScheduler,
  getSchedulerStatus,
  triggerManualRefresh
};
