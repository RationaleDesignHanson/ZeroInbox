/**
 * Purchase Scheduler
 * Checks for due purchases and executes them
 * Runs every minute via setInterval
 */

const { getDuePurchases, updatePurchaseStatus } = require('./database');
const { executePurchase, notifyUser } = require('./purchase-agent');
const logger = require('../../shared/config/logger');

let schedulerInterval = null;
let isRunning = false;

/**
 * Start the scheduler
 */
function startScheduler() {
  if (schedulerInterval) {
    logger.warn('Scheduler already running');
    return;
  }

  logger.info('Starting purchase scheduler');

  // Run immediately
  checkDuePurchases();

  // Then run every minute
  schedulerInterval = setInterval(checkDuePurchases, 60 * 1000);
}

/**
 * Stop the scheduler
 */
function stopScheduler() {
  if (schedulerInterval) {
    clearInterval(schedulerInterval);
    schedulerInterval = null;
    logger.info('Purchase scheduler stopped');
  }
}

/**
 * Check for due purchases and execute them
 */
async function checkDuePurchases() {
  if (isRunning) {
    logger.debug('Scheduler already processing purchases, skipping this cycle');
    return;
  }

  isRunning = true;

  try {
    const duePurchases = await getDuePurchases();

    if (duePurchases.length === 0) {
      logger.debug('No purchases due for execution');
      isRunning = false;
      return;
    }

    logger.info('Found due purchases', { count: duePurchases.length });

    for (const purchase of duePurchases) {
      try {
        // Mark as processing
        await updatePurchaseStatus(purchase.id, 'processing', 'Preparing purchase');

        // Execute purchase
        const result = await executePurchase(purchase);

        // Update status based on result
        if (result.status === 'ready_for_checkout') {
          await updatePurchaseStatus(purchase.id, 'ready_for_checkout', result.message);

          // Notify user
          await notifyUser(purchase.userId, purchase, result);

          logger.info('Purchase ready for user checkout', {
            id: purchase.id,
            productName: purchase.productName
          });
        } else if (result.status === 'failed') {
          await updatePurchaseStatus(purchase.id, 'failed', result.message);

          logger.error('Purchase execution failed', {
            id: purchase.id,
            error: result.message
          });
        }

      } catch (error) {
        logger.error('Error processing purchase', {
          id: purchase.id,
          error: error.message,
          stack: error.stack
        });

        await updatePurchaseStatus(purchase.id, 'failed', error.message);
      }
    }

  } catch (error) {
    logger.error('Error in scheduler', {
      error: error.message,
      stack: error.stack
    });
  } finally {
    isRunning = false;
  }
}

/**
 * Get scheduler status
 */
function getSchedulerStatus() {
  return {
    running: schedulerInterval !== null,
    processing: isRunning
  };
}

module.exports = {
  startScheduler,
  stopScheduler,
  checkDuePurchases,
  getSchedulerStatus
};
