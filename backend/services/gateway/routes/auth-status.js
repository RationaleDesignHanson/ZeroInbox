/**
 * Auth Status API
 * Provides endpoints for checking authentication health and re-auth needs
 * Used by iOS app and dashboard to monitor token status
 */

const express = require('express');
const router = express.Router();
const logger = require('../../../shared/config/logger');
const { authenticateRequest } = require('../../../shared/utils/auth');
const {
  getTokenHealth,
  getAllUserTokenStatus,
  needsReauth,
  clearReauthFlag,
  markUserForReauth,
  refreshTokenIfNeeded
} = require('../../../shared/utils/token-manager');
const { checkTokenHealth } = require('../../../shared/middleware/token-validator');
const {
  getSchedulerStatus,
  triggerManualRefresh
} = require('../../../shared/services/token-refresh-scheduler');

/**
 * GET /api/auth-status
 * Check current user's authentication status
 * Used by iOS app to determine if re-auth is needed
 */
router.get('/', authenticateRequest, async (req, res) => {
  try {
    const userId = req.user.userId;
    const provider = req.user.emailProvider || 'gmail';

    const health = getTokenHealth(userId, provider);

    logger.info('Auth status checked', {
      userId,
      provider,
      status: health.status,
      needsReauth: health.needsReauth
    });

    res.json({
      userId,
      provider,
      email: req.user.email,
      ...health,
      timestamp: Date.now()
    });

  } catch (error) {
    logger.error('Auth status check error', {
      error: error.message,
      userId: req.user?.userId
    });

    res.status(500).json({
      error: 'Failed to check auth status',
      message: error.message
    });
  }
});

/**
 * GET /api/auth-status/all
 * Get authentication status for all users
 * Admin/dashboard endpoint
 */
router.get('/all', (req, res) => {
  try {
    const allStatus = getAllUserTokenStatus();

    logger.info('All user auth status retrieved', {
      userCount: allStatus.length
    });

    res.json({
      users: allStatus,
      totalUsers: allStatus.length,
      needsReauth: allStatus.filter(u => u.needsReauth).length,
      healthy: allStatus.filter(u => u.status === 'healthy').length,
      expiring: allStatus.filter(u => u.status === 'expiring').length,
      expired: allStatus.filter(u => u.status === 'expired').length,
      timestamp: Date.now()
    });

  } catch (error) {
    logger.error('All auth status check error', {
      error: error.message
    });

    res.status(500).json({
      error: 'Failed to get auth status for all users',
      message: error.message
    });
  }
});

/**
 * POST /api/auth-status/refresh
 * Manually trigger token refresh
 * Used by dashboard or iOS app to force refresh
 */
router.post('/refresh', authenticateRequest, async (req, res) => {
  try {
    const userId = req.user.userId;
    const provider = req.user.emailProvider || 'gmail';

    logger.info('Manual token refresh requested', { userId, provider });

    const freshTokens = await refreshTokenIfNeeded(userId, provider);

    if (!freshTokens) {
      return res.status(400).json({
        success: false,
        error: 'Token refresh failed',
        message: 'Unable to refresh tokens. Re-authentication may be required.',
        needsReauth: true
      });
    }

    logger.info('✅ Manual token refresh successful', { userId, provider });

    res.json({
      success: true,
      message: 'Tokens refreshed successfully',
      expiresAt: freshTokens.expiresAt,
      timestamp: Date.now()
    });

  } catch (error) {
    logger.error('Manual token refresh error', {
      error: error.message,
      userId: req.user?.userId
    });

    res.status(500).json({
      success: false,
      error: 'Token refresh failed',
      message: error.message
    });
  }
});

/**
 * POST /api/auth-status/mark-reauth
 * Mark user as needing re-authentication
 * Used internally when token refresh fails repeatedly
 */
router.post('/mark-reauth', authenticateRequest, (req, res) => {
  try {
    const userId = req.user.userId;

    markUserForReauth(userId);

    logger.warn('🚨 User manually marked for re-authentication', { userId });

    res.json({
      success: true,
      message: 'User marked for re-authentication',
      needsReauth: true
    });

  } catch (error) {
    logger.error('Mark reauth error', {
      error: error.message,
      userId: req.user?.userId
    });

    res.status(500).json({
      success: false,
      error: 'Failed to mark for re-authentication',
      message: error.message
    });
  }
});

/**
 * POST /api/auth-status/clear-reauth
 * Clear re-authentication flag
 * Called after successful re-authentication
 */
router.post('/clear-reauth', authenticateRequest, (req, res) => {
  try {
    const userId = req.user.userId;

    clearReauthFlag(userId);

    logger.info('✅ Re-authentication flag cleared', { userId });

    res.json({
      success: true,
      message: 'Re-authentication flag cleared',
      needsReauth: false
    });

  } catch (error) {
    logger.error('Clear reauth flag error', {
      error: error.message,
      userId: req.user?.userId
    });

    res.status(500).json({
      success: false,
      error: 'Failed to clear re-authentication flag',
      message: error.message
    });
  }
});

/**
 * GET /api/auth-status/health/:userId
 * Get token health for specific user (admin/dashboard)
 * No auth required for dashboard use
 */
router.get('/health/:userId', (req, res) => {
  try {
    const { userId } = req.params;
    const provider = req.query.provider || 'gmail';

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
      userId: req.params.userId
    });

    res.status(500).json({
      error: 'Failed to check token health',
      message: error.message
    });
  }
});

/**
 * POST /api/auth-status/refresh/:userId
 * Manually refresh tokens for specific user (admin/dashboard)
 * No auth required for dashboard use
 */
router.post('/refresh/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const provider = req.query.provider || 'gmail';

    logger.info('Admin token refresh requested', { userId, provider });

    const freshTokens = await refreshTokenIfNeeded(userId, provider);

    if (!freshTokens) {
      return res.status(400).json({
        success: false,
        error: 'Token refresh failed',
        message: 'Unable to refresh tokens for this user'
      });
    }

    logger.info('✅ Admin token refresh successful', { userId, provider });

    res.json({
      success: true,
      message: 'Tokens refreshed successfully',
      expiresAt: freshTokens.expiresAt,
      timestamp: Date.now()
    });

  } catch (error) {
    logger.error('Admin token refresh error', {
      error: error.message,
      userId: req.params.userId
    });

    res.status(500).json({
      success: false,
      error: 'Token refresh failed',
      message: error.message
    });
  }
});

/**
 * DELETE /api/auth-status/reauth-flag/:userId
 * Clear re-auth flag for specific user (admin/dashboard)
 */
router.delete('/reauth-flag/:userId', (req, res) => {
  try {
    const { userId } = req.params;

    clearReauthFlag(userId);

    logger.info('✅ Admin cleared re-authentication flag', { userId });

    res.json({
      success: true,
      message: 'Re-authentication flag cleared'
    });

  } catch (error) {
    logger.error('Admin clear reauth flag error', {
      error: error.message,
      userId: req.params.userId
    });

    res.status(500).json({
      success: false,
      error: 'Failed to clear re-authentication flag',
      message: error.message
    });
  }
});

/**
 * GET /api/auth-status/needs-reauth/:userId
 * Quick check if specific user needs re-auth (for dashboard)
 */
router.get('/needs-reauth/:userId', (req, res) => {
  try {
    const { userId } = req.params;

    const needs = needsReauth(userId);

    res.json({
      userId,
      needsReauth: needs,
      timestamp: Date.now()
    });

  } catch (error) {
    logger.error('Needs reauth check error', {
      error: error.message,
      userId: req.params.userId
    });

    res.status(500).json({
      error: 'Failed to check re-auth status',
      message: error.message
    });
  }
});

/**
 * GET /api/auth-status/scheduler
 * Get token refresh scheduler status
 */
router.get('/scheduler', (req, res) => {
  try {
    const status = getSchedulerStatus();

    res.json({
      scheduler: status,
      timestamp: Date.now()
    });

  } catch (error) {
    logger.error('Scheduler status error', {
      error: error.message
    });

    res.status(500).json({
      error: 'Failed to get scheduler status',
      message: error.message
    });
  }
});

/**
 * POST /api/auth-status/scheduler/trigger
 * Manually trigger token refresh cycle (admin/testing)
 */
router.post('/scheduler/trigger', async (req, res) => {
  try {
    logger.info('Manual token refresh cycle triggered via API');

    // Trigger refresh in background (don't wait for completion)
    triggerManualRefresh().catch(error => {
      logger.error('Manual refresh cycle error', { error: error.message });
    });

    res.json({
      success: true,
      message: 'Token refresh cycle triggered',
      timestamp: Date.now()
    });

  } catch (error) {
    logger.error('Trigger scheduler error', {
      error: error.message
    });

    res.status(500).json({
      error: 'Failed to trigger token refresh',
      message: error.message
    });
  }
});

module.exports = router;
