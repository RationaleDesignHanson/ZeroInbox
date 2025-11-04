/**
 * Scheduled Purchase Service
 * Handles creation and execution of scheduled purchases
 * Port: 8085
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const logger = require('../../shared/config/logger');

const {
  initDatabase,
  createPurchase,
  getPurchaseById,
  getPurchasesByUser,
  getAllPurchases,
  cancelPurchase,
  updatePurchaseStatus
} = require('./database');

const {
  startScheduler,
  stopScheduler,
  getSchedulerStatus
} = require('./scheduler');

const app = express();
const PORT = process.env.PORT || process.env.SCHEDULED_PURCHASE_SERVICE_PORT || 8085;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  const schedulerStatus = getSchedulerStatus();
  res.json({
    status: 'ok',
    service: 'scheduled-purchase-service',
    scheduler: schedulerStatus,
    timestamp: new Date().toISOString()
  });
});

/**
 * POST /api/purchases
 * Create a new scheduled purchase
 */
app.post('/api/purchases', async (req, res) => {
  try {
    const { userId, emailId, productName, productUrl, scheduledTime, timezone, variant } = req.body;

    // Validate required fields
    if (!userId || !emailId || !productUrl || !scheduledTime) {
      return res.status(400).json({
        error: 'Missing required fields',
        required: ['userId', 'emailId', 'productUrl', 'scheduledTime']
      });
    }

    // Validate scheduled time is in the future
    const scheduledDate = new Date(scheduledTime);
    if (scheduledDate <= new Date()) {
      return res.status(400).json({
        error: 'Scheduled time must be in the future'
      });
    }

    const purchase = await createPurchase({
      userId,
      emailId,
      productName: productName || 'Product',
      productUrl,
      scheduledTime,
      timezone: timezone || 'UTC',
      variant
    });

    res.status(201).json(purchase);

  } catch (error) {
    logger.error('Error creating scheduled purchase', { error: error.message });
    res.status(500).json({ error: 'Failed to create scheduled purchase' });
  }
});

/**
 * GET /api/purchases/:id
 * Get a specific purchase by ID
 */
app.get('/api/purchases/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const purchase = await getPurchaseById(id);

    if (!purchase) {
      return res.status(404).json({ error: 'Purchase not found' });
    }

    res.json(purchase);

  } catch (error) {
    logger.error('Error fetching purchase', { error: error.message });
    res.status(500).json({ error: 'Failed to fetch purchase' });
  }
});

/**
 * GET /api/purchases/user/:userId
 * Get all purchases for a user
 */
app.get('/api/purchases/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const purchases = await getPurchasesByUser(userId);

    res.json({
      purchases,
      count: purchases.length
    });

  } catch (error) {
    logger.error('Error fetching user purchases', { error: error.message });
    res.status(500).json({ error: 'Failed to fetch user purchases' });
  }
});

/**
 * POST /api/purchases/:id/cancel
 * Cancel a scheduled purchase
 */
app.post('/api/purchases/:id/cancel', async (req, res) => {
  try {
    const { id } = req.params;
    const purchase = await cancelPurchase(id);

    res.json({
      message: 'Purchase cancelled successfully',
      purchase
    });

  } catch (error) {
    logger.error('Error cancelling purchase', { error: error.message });
    res.status(500).json({ error: 'Failed to cancel purchase' });
  }
});

/**
 * GET /api/purchases
 * Get all purchases (admin/debug)
 */
app.get('/api/purchases', async (req, res) => {
  try {
    const purchases = await getAllPurchases();

    res.json({
      purchases,
      count: purchases.length
    });

  } catch (error) {
    logger.error('Error fetching all purchases', { error: error.message });
    res.status(500).json({ error: 'Failed to fetch purchases' });
  }
});

/**
 * GET /api/scheduler/status
 * Get scheduler status
 */
app.get('/api/scheduler/status', (req, res) => {
  const status = getSchedulerStatus();
  res.json(status);
});

// Error handling
app.use((err, req, res, next) => {
  logger.error('Scheduled purchase service error', { error: err.message, stack: err.stack });
  res.status(500).json({ error: 'Internal server error' });
});

// Initialize and start server
async function startServer() {
  try {
    // Initialize database
    await initDatabase();

    // Start scheduler
    startScheduler();

    // Start HTTP server
    app.listen(PORT, () => {
      logger.info(`Scheduled purchase service running on port ${PORT}`);
      console.log(`\n🛒 Scheduled Purchase Service listening on http://localhost:${PORT}`);
      console.log(`   Status: http://localhost:${PORT}/health`);
    });

  } catch (error) {
    logger.error('Failed to start scheduled purchase service', { error: error.message });
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  stopScheduler();
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  stopScheduler();
  process.exit(0);
});

// Start server
if (require.main === module) {
  startServer();
}

module.exports = app;
