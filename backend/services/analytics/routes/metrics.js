const express = require('express');
const router = express.Router();
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'analytics-metrics' },
  transports: [new winston.transports.Console()]
});

// In-memory storage (replace with database in production)
const events = [];
const metrics = {
  totalEvents: 0,
  eventsByType: {},
  eventsByUser: {},
  eventsByDay: {},
  recentEvents: []
};

/**
 * POST /events
 * Track analytics event
 * Body: { userId, eventType, eventName, properties, timestamp }
 */
router.post('/events', (req, res) => {
  try {
    const { userId, eventType, eventName, properties, timestamp, environment } = req.body;

    // Validation
    if (!userId || !eventType || !eventName) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'userId, eventType, and eventName are required'
      });
    }

    // Create event
    const event = {
      id: generateEventId(),
      userId,
      eventType,
      eventName,
      properties: properties || {},
      timestamp: timestamp || new Date().toISOString(),
      environment: environment || 'real',  // Default to 'real' if not specified
      sessionId: req.headers['x-session-id'] || null,
      userAgent: req.headers['user-agent'] || null,
      createdAt: new Date().toISOString()
    };

    // Store event
    events.push(event);

    // Update metrics
    updateMetrics(event);

    logger.info('Event tracked', {
      userId,
      eventType,
      eventName
    });

    res.json({
      success: true,
      event: {
        id: event.id,
        timestamp: event.timestamp
      }
    });

  } catch (error) {
    logger.error('Error tracking event', { error: error.message });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * POST /events/batch
 * Track multiple analytics events
 * Body: { events: [{ userId, eventType, eventName, properties, timestamp }] }
 */
router.post('/events/batch', (req, res) => {
  try {
    const { events: batchEvents } = req.body;

    if (!Array.isArray(batchEvents) || batchEvents.length === 0) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'events array is required and must not be empty'
      });
    }

    const processedEvents = [];

    for (const eventData of batchEvents) {
      const { userId, eventType, eventName, properties, timestamp, environment } = eventData;

      if (!userId || !eventType || !eventName) {
        continue; // Skip invalid events
      }

      const event = {
        id: generateEventId(),
        userId,
        eventType,
        eventName,
        properties: properties || {},
        timestamp: timestamp || new Date().toISOString(),
        environment: environment || 'real',  // Default to 'real' if not specified
        sessionId: req.headers['x-session-id'] || null,
        createdAt: new Date().toISOString()
      };

      events.push(event);
      updateMetrics(event);
      processedEvents.push(event.id);
    }

    logger.info('Batch events tracked', {
      count: processedEvents.length
    });

    res.json({
      success: true,
      eventsProcessed: processedEvents.length,
      eventIds: processedEvents
    });

  } catch (error) {
    logger.error('Error tracking batch events', { error: error.message });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * GET /metrics
 * Get aggregated metrics
 */
router.get('/metrics', (req, res) => {
  try {
    const { startDate, endDate, userId } = req.query;

    let filteredEvents = events;

    // Filter by date range
    if (startDate) {
      filteredEvents = filteredEvents.filter(e => new Date(e.timestamp) >= new Date(startDate));
    }
    if (endDate) {
      filteredEvents = filteredEvents.filter(e => new Date(e.timestamp) <= new Date(endDate));
    }

    // Filter by user
    if (userId) {
      filteredEvents = filteredEvents.filter(e => e.userId === userId);
    }

    // Calculate metrics
    const aggregatedMetrics = calculateMetrics(filteredEvents);

    res.json({
      success: true,
      metrics: aggregatedMetrics,
      period: {
        startDate: startDate || null,
        endDate: endDate || null
      },
      totalEvents: filteredEvents.length
    });

  } catch (error) {
    logger.error('Error fetching metrics', { error: error.message });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * GET /metrics/:metric
 * Get specific metric data
 */
router.get('/metrics/:metric', (req, res) => {
  try {
    const { metric } = req.params;
    const { userId, startDate, endDate } = req.query;

    let filteredEvents = events;

    // Filter by user
    if (userId) {
      filteredEvents = filteredEvents.filter(e => e.userId === userId);
    }

    // Filter by date range
    if (startDate) {
      filteredEvents = filteredEvents.filter(e => new Date(e.timestamp) >= new Date(startDate));
    }
    if (endDate) {
      filteredEvents = filteredEvents.filter(e => new Date(e.timestamp) <= new Date(endDate));
    }

    const metricData = getMetricData(metric, filteredEvents);

    res.json({
      success: true,
      metric,
      data: metricData
    });

  } catch (error) {
    logger.error('Error fetching metric', { error: error.message });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * GET /events
 * Get recent events
 */
router.get('/events', (req, res) => {
  try {
    const { userId, eventType, limit = 100 } = req.query;
    const parsedLimit = Math.min(parseInt(limit), 1000);

    let filteredEvents = [...events].reverse(); // Most recent first

    if (userId) {
      filteredEvents = filteredEvents.filter(e => e.userId === userId);
    }

    if (eventType) {
      filteredEvents = filteredEvents.filter(e => e.eventType === eventType);
    }

    const limitedEvents = filteredEvents.slice(0, parsedLimit);

    res.json({
      success: true,
      events: limitedEvents,
      count: limitedEvents.length,
      totalCount: events.length
    });

  } catch (error) {
    logger.error('Error fetching events', { error: error.message });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * GET /users
 * Get user analytics summary
 */
router.get('/users', (req, res) => {
  try {
    const userSummaries = [];
    const userIds = [...new Set(events.map(e => e.userId))];

    for (const userId of userIds) {
      const userEvents = events.filter(e => e.userId === userId);
      const summary = {
        userId,
        totalEvents: userEvents.length,
        eventTypes: countByKey(userEvents, 'eventType'),
        firstSeen: userEvents[0]?.timestamp,
        lastSeen: userEvents[userEvents.length - 1]?.timestamp,
        sessionCount: new Set(userEvents.map(e => e.sessionId).filter(Boolean)).size
      };
      userSummaries.push(summary);
    }

    res.json({
      success: true,
      users: userSummaries,
      totalUsers: userSummaries.length
    });

  } catch (error) {
    logger.error('Error fetching users', { error: error.message });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * DELETE /events
 * Clear all events (for testing)
 */
router.delete('/events', (req, res) => {
  try {
    const count = events.length;
    events.length = 0;

    // Reset metrics
    metrics.totalEvents = 0;
    metrics.eventsByType = {};
    metrics.eventsByUser = {};
    metrics.eventsByDay = {};
    metrics.recentEvents = [];

    logger.info('Events cleared', { count });

    res.json({
      success: true,
      message: `Cleared ${count} events`
    });

  } catch (error) {
    logger.error('Error clearing events', { error: error.message });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

// MARK: - Helper Functions

function generateEventId() {
  return `evt_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
}

function updateMetrics(event) {
  // Total events
  metrics.totalEvents++;

  // Events by type
  metrics.eventsByType[event.eventType] = (metrics.eventsByType[event.eventType] || 0) + 1;

  // Events by user
  metrics.eventsByUser[event.userId] = (metrics.eventsByUser[event.userId] || 0) + 1;

  // Events by day
  const day = event.timestamp.split('T')[0];
  metrics.eventsByDay[day] = (metrics.eventsByDay[day] || 0) + 1;

  // Recent events (keep last 50)
  metrics.recentEvents.unshift({
    id: event.id,
    userId: event.userId,
    eventType: event.eventType,
    eventName: event.eventName,
    timestamp: event.timestamp
  });
  if (metrics.recentEvents.length > 50) {
    metrics.recentEvents = metrics.recentEvents.slice(0, 50);
  }
}

function calculateMetrics(filteredEvents) {
  const totalEvents = filteredEvents.length;
  const uniqueUsers = new Set(filteredEvents.map(e => e.userId)).size;
  const eventsByType = countByKey(filteredEvents, 'eventType');
  const eventsByName = countByKey(filteredEvents, 'eventName');
  const eventsByDay = groupByDay(filteredEvents);

  return {
    totalEvents,
    uniqueUsers,
    eventsByType,
    eventsByName,
    eventsByDay,
    topEvents: Object.entries(eventsByName)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([name, count]) => ({ name, count }))
  };
}

function getMetricData(metric, filteredEvents) {
  switch (metric) {
    case 'email-views':
      return filteredEvents.filter(e => e.eventName === 'email_viewed').length;

    case 'card-swipes':
      return filteredEvents.filter(e => e.eventName === 'card_swiped').length;

    case 'action-executions':
      return filteredEvents.filter(e => e.eventName === 'action_executed').length;

    case 'modal-opens':
      return filteredEvents.filter(e => e.eventName === 'modal_opened').length;

    case 'engagement-rate':
      const views = filteredEvents.filter(e => e.eventName === 'email_viewed').length;
      const actions = filteredEvents.filter(e => e.eventName === 'action_executed').length;
      return views > 0 ? (actions / views * 100).toFixed(2) : 0;

    case 'average-session-duration':
      // Calculate from session events
      const sessions = groupByKey(filteredEvents, 'sessionId');
      const durations = Object.values(sessions).map(events => {
        if (events.length < 2) return 0;
        const start = new Date(events[0].timestamp);
        const end = new Date(events[events.length - 1].timestamp);
        return (end - start) / 1000; // seconds
      });
      const avgDuration = durations.reduce((sum, d) => sum + d, 0) / durations.length;
      return Math.round(avgDuration);

    default:
      return null;
  }
}

function countByKey(array, key) {
  return array.reduce((acc, item) => {
    const value = item[key];
    acc[value] = (acc[value] || 0) + 1;
    return acc;
  }, {});
}

function groupByKey(array, key) {
  return array.reduce((acc, item) => {
    const value = item[key];
    if (!acc[value]) acc[value] = [];
    acc[value].push(item);
    return acc;
  }, {});
}

function groupByDay(array) {
  return array.reduce((acc, item) => {
    const day = item.timestamp.split('T')[0];
    acc[day] = (acc[day] || 0) + 1;
    return acc;
  }, {});
}

module.exports = router;
