/**
 * Action Registry Service (v2.0)
 * Dynamic action registry with corpus-driven personalization
 *
 * Phase 2 of corpus migration: Replaces hardcoded iOS ActionRegistry with API-fetched actions
 */

const express = require('express');
const cors = require('cors');
const axios = require('axios');
const { ActionCatalog, getAllActionIds } = require('./action-catalog');
const ActionRegistryCache = require('./cache');

const app = express();
const PORT = process.env.PORT || 8085;

// Corpus Service URL
const CORPUS_SERVICE_URL = process.env.CORPUS_SERVICE_URL || 'http://localhost:8090';

// Initialize cache (24-hour TTL)
const cache = new ActionRegistryCache(24 * 60 * 60 * 1000);

// Enable CORS and JSON parsing
app.use(cors());
app.use(express.json());

// ============================================================================
// HEALTH CHECK
// ============================================================================

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'actions-registry',
    version: '2.0.0',
    timestamp: new Date().toISOString(),
    endpoints: {
      registry: '/api/actions/registry',
      action: '/api/actions/:actionId',
      catalog: '/api/actions/catalog'
    }
  });
});

// ============================================================================
// DYNAMIC ACTION REGISTRY API (Phase 2)
// ============================================================================

/**
 * GET /api/actions/registry
 *
 * Returns personalized, corpus-driven action registry for user
 * - Actions ranked by frequency in user's corpus
 * - Irrelevant actions filtered out
 * - Execution rates and usage stats included
 *
 * Query Parameters:
 * - userId (required): User identifier
 * - mode (optional): "mail" or "ads" (default: both)
 * - days (optional): Look-back period for corpus analysis (default: 30)
 * - limit (optional): Max actions to return (default: all)
 *
 * Response Format:
 * {
 *   "actions": [
 *     {
 *       "actionId": "track_package",
 *       "displayName": "Track Package",
 *       "actionType": "IN_APP",
 *       "mode": "both",
 *       "modalComponent": "TrackPackageModal",
 *       "requiredContextKeys": ["trackingNumber", "carrier"],
 *       "optionalContextKeys": ["url", "expectedDelivery"],
 *       "fallbackBehavior": "show_error",
 *       "analyticsEvent": "action_track_package",
 *       "priority": 95,           // Boosted from 90 based on usage
 *       "description": "Track package delivery status",
 *       "requiredPermission": "premium",
 *
 *       // Corpus-driven personalization data:
 *       "userStats": {
 *         "frequency": 0.18,         // 18% of user's emails
 *         "lastUsed": "2025-10-29T...",
 *         "timesUsed": 45,
 *         "timesS uggested": 55,
 *         "executionRate": 0.82,     // 82% of suggestions result in action
 *         "avgTimeToAction": 45       // Average seconds from suggestion to action
 *       }
 *     },
 *     // ... more actions, ranked by relevance
 *   ],
 *   "metadata": {
 *     "userId": "user_123",
 *     "corpusSize": 1250,
 *     "days": 30,
 *     "lastUpdated": "2025-10-30T10:00:00Z",
 *     "actionsReturned": 42,
 *     "actionsFiltered": 9,
 *     "personalizationApplied": true
 *   }
 * }
 */
app.get('/api/actions/registry', async (req, res) => {
  try {
    const { userId, mode, days = 30, limit, bustCache } = req.query;

    if (!userId) {
      return res.status(400).json({
        error: 'Missing required parameter: userId',
        message: 'userId query parameter is required'
      });
    }

    // Check cache (unless bustCache requested)
    if (!bustCache) {
      const cached = cache.get(userId, mode, days);
      if (cached) {
        return res.json({
          ...cached,
          fromCache: true,
          cacheHit: true
        });
      }
    }

    // 1. Get corpus statistics for user
    const corpusStats = await fetchCorpusStatistics(userId, days);

    // 2. Get all actions from catalog
    const allActionIds = getAllActionIds();
    let actions = allActionIds.map(actionId => {
      const action = ActionCatalog[actionId];
      return transformActionForAPI(action, corpusStats, userId);
    });

    // 3. Filter by mode if specified
    if (mode) {
      actions = actions.filter(action =>
        action.mode === mode || action.mode === 'both'
      );
    }

    // 4. Filter out irrelevant actions (never used after 100+ emails)
    if (corpusStats.overall.totalEmails > 100) {
      actions = filterIrrelevantActions(actions, corpusStats);
    }

    // 5. Rank actions by personalized priority
    actions = rankActionsByRelevance(actions, corpusStats);

    // 6. Limit results if requested
    if (limit) {
      actions = actions.slice(0, parseInt(limit));
    }

    // 7. Build response
    const response = {
      actions,
      metadata: {
        userId,
        corpusSize: corpusStats.overall.totalEmails,
        days: parseInt(days),
        lastUpdated: new Date().toISOString(),
        actionsReturned: actions.length,
        actionsFiltered: allActionIds.length - actions.length,
        personalizationApplied: corpusStats.overall.totalEmails >= 10,
        fromCache: false,
        cacheHit: false
      }
    };

    // 8. Cache the response (24-hour TTL)
    cache.set(userId, mode, days, response);

    // 9. Return personalized registry
    res.json(response);

  } catch (error) {
    console.error('Error generating action registry:', error);
    res.status(500).json({
      error: 'Failed to generate action registry',
      message: error.message,
      fallback: 'Use embedded action catalog'
    });
  }
});

/**
 * GET /api/actions/catalog
 *
 * Get raw action catalog (no personalization)
 * IMPORTANT: Must be defined BEFORE :actionId route to prevent route collision
 */
app.get('/api/actions/catalog', (req, res) => {
  try {
    const { mode } = req.query;

    let actions = getAllActionIds().map(actionId => {
      const action = ActionCatalog[actionId];
      return transformActionForAPI(action, null, null);
    });

    if (mode) {
      actions = actions.filter(action =>
        action.mode === mode || action.mode === 'both'
      );
    }

    // Convert actions array to object keyed by actionId for dashboard compatibility
    const actionsObject = {};
    actions.forEach(action => {
      actionsObject[action.actionId] = action;
    });

    res.json({
      actions: actionsObject,
      metadata: {
        totalActions: actions.length,
        personalizationApplied: false,
        timestamp: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('Error fetching catalog:', error);
    res.status(500).json({
      error: 'Failed to fetch catalog',
      message: error.message
    });
  }
});

/**
 * GET /api/actions/:actionId
 *
 * Get specific action configuration with user stats
 */
app.get('/api/actions/:actionId', async (req, res) => {
  try {
    const { actionId } = req.params;
    const { userId, days = 30 } = req.query;

    const action = ActionCatalog[actionId];

    if (!action) {
      return res.status(404).json({
        error: 'Action not found',
        actionId
      });
    }

    // Get user stats if userId provided
    let userStats = null;
    if (userId) {
      const corpusStats = await fetchCorpusStatistics(userId, days);
      userStats = extractActionStats(actionId, corpusStats);
    }

    res.json({
      ...transformActionForAPI(action, userStats ? { actions: { [actionId]: userStats } } : null, userId),
      requestedAt: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error fetching action:', error);
    res.status(500).json({
      error: 'Failed to fetch action',
      message: error.message
    });
  }
});

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Fetch corpus statistics from corpus service
 */
async function fetchCorpusStatistics(userId, days) {
  try {
    const response = await axios.get(`${CORPUS_SERVICE_URL}/api/corpus/statistics`, {
      params: { userId, days },
      timeout: 10000
    });

    return response.data;

  } catch (error) {
    console.warn('Failed to fetch corpus statistics:', error.message);

    // Return empty corpus stats as fallback
    return {
      overall: {
        totalEmails: 0,
        actionsTaken: 0,
        avgTimeToAction: 0
      },
      topActions: [],
      topIntents: []
    };
  }
}

/**
 * Transform action catalog format to API format
 */
function transformActionForAPI(action, corpusStats, userId) {
  const baseAction = {
    actionId: action.actionId,
    displayName: action.displayName,
    actionType: action.actionType,
    mode: determineMode(action),
    modalComponent: action.urlTemplate ? null : getModalComponent(action.actionId),
    requiredContextKeys: action.requiredEntities || [],
    optionalContextKeys: getOptionalContextKeys(action),
    fallbackBehavior: 'show_error',
    analyticsEvent: `action_${action.actionId}`,
    priority: action.priority,
    description: action.description || '',
    requiredPermission: getRequiredPermission(action),
  };

  // Add user stats if corpus data available
  if (corpusStats && userId) {
    const actionStats = extractActionStats(action.actionId, corpusStats);
    if (actionStats) {
      baseAction.userStats = actionStats;
      // Boost priority based on usage
      baseAction.priority = calculatePersonalizedPriority(baseAction.priority, actionStats);
    }
  }

  return baseAction;
}

/**
 * Extract user-specific stats for an action from corpus
 */
function extractActionStats(actionId, corpusStats) {
  const actionData = corpusStats.topActions?.find(a => a.action_id === actionId);

  if (!actionData) {
    return null;
  }

  return {
    frequency: parseFloat(actionData.frequency || 0),
    lastUsed: actionData.last_used || null,
    timesUsed: parseInt(actionData.times_executed || 0),
    timesSuggested: parseInt(actionData.times_suggested || 0),
    executionRate: parseFloat(actionData.execution_rate || 0),
    avgTimeToAction: parseInt(actionData.avg_time_to_action_seconds || 0)
  };
}

/**
 * Calculate personalized priority based on user stats
 */
function calculatePersonalizedPriority(basePriority, userStats) {
  let personalizedPriority = basePriority;

  // Boost priority for frequently used actions
  if (userStats.frequency > 0.15) { // > 15% of emails
    personalizedPriority += 10;
  } else if (userStats.frequency > 0.08) { // > 8% of emails
    personalizedPriority += 5;
  }

  // Boost for high execution rate
  if (userStats.executionRate > 0.75 && userStats.timesSuggested > 5) {
    personalizedPriority += 5;
  }

  // Slight boost for recently used
  if (userStats.lastUsed) {
    const daysSinceUse = (Date.now() - new Date(userStats.lastUsed)) / (1000 * 60 * 60 * 24);
    if (daysSinceUse < 7) {
      personalizedPriority += 3;
    }
  }

  // Cap at 100
  return Math.min(personalizedPriority, 100);
}

/**
 * Filter out actions never used after 100+ emails
 */
function filterIrrelevantActions(actions, corpusStats) {
  const usedActionIds = new Set(
    corpusStats.topActions?.map(a => a.action_id) || []
  );

  return actions.filter(action => {
    // Always keep generic actions
    if (isGenericAction(action.actionId)) {
      return true;
    }

    // Keep if user has used it
    if (usedActionIds.has(action.actionId)) {
      return true;
    }

    // Keep high-priority actions even if not used yet (user may need them)
    if (action.priority >= 90) {
      return true;
    }

    // Filter out if never suggested after 100 emails
    return false;
  });
}

/**
 * Rank actions by relevance (personalized priority + frequency)
 */
function rankActionsByRelevance(actions, corpusStats) {
  return actions.sort((a, b) => {
    // Primary sort: personalized priority
    const priorityDiff = b.priority - a.priority;
    if (priorityDiff !== 0) return priorityDiff;

    // Secondary sort: usage frequency
    const freqA = a.userStats?.frequency || 0;
    const freqB = b.userStats?.frequency || 0;
    return freqB - freqA;
  });
}

/**
 * Determine mode from action (helper)
 */
function determineMode(action) {
  // Use validIntents to infer mode
  const intents = action.validIntents || [];

  const hasMailIntents = intents.some(i =>
    i.includes('event.') ||
    i.includes('healthcare.') ||
    i.includes('education.') ||
    i.includes('account.')
  );

  const hasAdsIntents = intents.some(i =>
    i.includes('marketing.') ||
    i.includes('promotion.')
  );

  if (hasMailIntents && !hasAdsIntents) return 'mail';
  if (hasAdsIntents && !hasMailIntents) return 'ads';
  return 'both';
}

/**
 * Get modal component name (iOS modal)
 */
function getModalComponent(actionId) {
  const modalMapping = {
    // Existing modals
    track_package: 'TrackPackageModal',
    pay_invoice: 'PayInvoiceModal',
    check_in_flight: 'CheckInFlightModal',
    write_review: 'WriteReviewModal',
    sign_form: 'SignFormModal',
    quick_reply: 'QuickReplyModal',
    add_to_calendar: 'AddToCalendarModal',
    schedule_meeting: 'ScheduleMeetingModal',
    add_reminder: 'AddReminderModal',
    schedule_purchase: 'ScheduledPurchaseModal',
    view_newsletter_summary: 'NewsletterSummaryModal',
    cancel_subscription: 'CancelSubscriptionModal',
    add_to_wallet: 'AddToWalletModal',
    save_contact_native: 'SaveContactModal',
    view_reservation: 'ReservationModal',
    browse_shopping: 'BrowseShoppingModal',

    // High Priority - New modals
    rate_product: 'RateProductModal',
    rsvp_yes: 'RSVPModal',
    rsvp_no: 'RSVPModal',
    reply_to_thread: 'ReplyModal',
    reply_to_ticket: 'ReplyTicketModal',
    set_reminder: 'SetReminderModal',
    set_price_alert: 'SetPriceAlertModal',
    schedule_payment: 'SchedulePaymentModal',
    pay_form_fee: 'PayFormFeeModal',
    file_insurance_claim: 'FileInsuranceClaimModal',

    // Medium Priority - New modals
    notify_restock: 'NotifyRestockModal',
    save_for_later: 'SaveForLaterModal',
    copy_promo_code: 'CopyPromoCodeModal',
    set_payment_reminder: 'SetPaymentReminderModal',
    contact_driver: 'ContactDriverModal',
    accept_school_event: 'AcceptSchoolEventModal',
    pickup_prescription: 'PickupPrescriptionModal',

    // View modals - shared DocumentViewModal for viewing content
    view_pickup_details: 'DocumentViewModal',
    view_practice_details: 'DocumentViewModal',
    view_team_announcement: 'DocumentViewModal',
    view_benefits: 'DocumentViewModal',
    view_details: 'DocumentViewModal',
    view_introduction: 'DocumentViewModal',
    view_legal_document: 'DocumentViewModal',
    view_mortgage_details: 'DocumentViewModal',
    view_onboarding_info: 'DocumentViewModal'
  };

  return modalMapping[actionId] || null;
}

/**
 * Get optional context keys
 */
function getOptionalContextKeys(action) {
  // Define optional keys based on action type
  const optionalKeys = {
    track_package: ['url', 'expectedDelivery', 'currentStatus'],
    pay_invoice: ['dueDate', 'description'],
    check_in_flight: ['checkInUrl', 'departureTime', 'gate', 'seat'],
    // Add more as needed
  };

  return optionalKeys[action.actionId] || [];
}

/**
 * Get required permission
 */
function getRequiredPermission(action) {
  // Define premium actions
  const premiumActions = [
    'track_package',
    'pay_invoice',
    'check_in_flight',
    'sign_form',
    'schedule_purchase',
    'view_newsletter_summary',
    'unsubscribe'
  ];

  return premiumActions.includes(action.actionId) ? 'premium' : 'free';
}

/**
 * Check if action is generic (always relevant)
 */
function isGenericAction(actionId) {
  const genericActions = [
    'quick_reply',
    'save_for_later',
    'view_details',
    'share',
    'open_link'
  ];

  return genericActions.includes(actionId);
}

// ============================================================================
// CACHE MANAGEMENT ENDPOINTS
// ============================================================================

/**
 * GET /api/cache/stats
 * Get cache statistics
 */
app.get('/api/cache/stats', (req, res) => {
  try {
    const stats = cache.getStats();
    res.json({
      ...stats,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      error: 'Failed to get cache stats',
      message: error.message
    });
  }
});

/**
 * POST /api/cache/clear
 * Clear all cache
 */
app.post('/api/cache/clear', (req, res) => {
  try {
    const cleared = cache.clear();
    res.json({
      success: true,
      entriesCleared: cleared,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      error: 'Failed to clear cache',
      message: error.message
    });
  }
});

/**
 * POST /api/cache/invalidate/:userId
 * Invalidate cache for specific user
 */
app.post('/api/cache/invalidate/:userId', (req, res) => {
  try {
    const { userId } = req.params;
    const cleared = cache.invalidate(userId);
    res.json({
      success: true,
      userId,
      entriesCleared: cleared,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      error: 'Failed to invalidate cache',
      message: error.message
    });
  }
});

// ============================================================================
// START SERVER
// ============================================================================

app.listen(PORT, () => {
  console.log(`✅ Action Registry Service running on port ${PORT}`);
  console.log(`📡 Corpus Service: ${CORPUS_SERVICE_URL}`);
  console.log(`🎯 Endpoints:`);
  console.log(`   - GET /api/actions/registry?userId=<id>`);
  console.log(`   - GET /api/actions/:actionId`);
  console.log(`   - GET /api/actions/catalog`);
  console.log(`   - GET /api/cache/stats`);
  console.log(`   - POST /api/cache/clear`);
  console.log(`   - POST /api/cache/invalidate/:userId`);
  console.log(`   - GET /health`);
});

module.exports = app;
