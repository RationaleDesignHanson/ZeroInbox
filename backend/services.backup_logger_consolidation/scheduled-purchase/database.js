/**
 * Scheduled Purchase Database
 * Simple JSON-based database for storing scheduled purchases
 */

const fs = require('fs').promises;
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const logger = require('./logger');

const DB_PATH = path.join(__dirname, 'scheduled-purchases.json');

// In-memory cache
let purchases = [];

/**
 * Initialize database
 */
async function initDatabase() {
  try {
    const data = await fs.readFile(DB_PATH, 'utf8');
    purchases = JSON.parse(data);
    logger.info('Scheduled purchases database loaded', { count: purchases.length });
  } catch (error) {
    if (error.code === 'ENOENT') {
      // File doesn't exist, create it
      purchases = [];
      await saveDatabase();
      logger.info('Scheduled purchases database initialized');
    } else {
      logger.error('Error loading scheduled purchases database', { error: error.message });
      throw error;
    }
  }
}

/**
 * Save database to disk
 */
async function saveDatabase() {
  try {
    await fs.writeFile(DB_PATH, JSON.stringify(purchases, null, 2), 'utf8');
  } catch (error) {
    logger.error('Error saving scheduled purchases database', { error: error.message });
    throw error;
  }
}

/**
 * Create a new scheduled purchase
 */
async function createPurchase(data) {
  const purchase = {
    id: uuidv4(),
    userId: data.userId,
    emailId: data.emailId,
    productName: data.productName,
    productUrl: data.productUrl,
    scheduledTime: data.scheduledTime,
    timezone: data.timezone || 'UTC',
    status: 'pending',
    variant: data.variant || null,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };

  purchases.push(purchase);
  await saveDatabase();

  logger.info('Scheduled purchase created', {
    id: purchase.id,
    productName: purchase.productName,
    scheduledTime: purchase.scheduledTime
  });

  return purchase;
}

/**
 * Get purchase by ID
 */
async function getPurchaseById(id) {
  return purchases.find(p => p.id === id);
}

/**
 * Get all purchases for a user
 */
async function getPurchasesByUser(userId) {
  return purchases.filter(p => p.userId === userId);
}

/**
 * Get purchases due for execution
 */
async function getDuePurchases() {
  const now = new Date();
  return purchases.filter(p => {
    if (p.status !== 'pending') return false;
    const scheduledDate = new Date(p.scheduledTime);
    return scheduledDate <= now;
  });
}

/**
 * Update purchase status
 */
async function updatePurchaseStatus(id, status, message = null) {
  const purchase = purchases.find(p => p.id === id);
  if (!purchase) {
    throw new Error('Purchase not found');
  }

  purchase.status = status;
  purchase.updatedAt = new Date().toISOString();
  if (message) {
    purchase.statusMessage = message;
  }

  await saveDatabase();

  logger.info('Purchase status updated', { id, status, message });

  return purchase;
}

/**
 * Cancel a scheduled purchase
 */
async function cancelPurchase(id) {
  return await updatePurchaseStatus(id, 'cancelled', 'Cancelled by user');
}

/**
 * Delete a purchase (for testing/cleanup)
 */
async function deletePurchase(id) {
  const index = purchases.findIndex(p => p.id === id);
  if (index === -1) {
    throw new Error('Purchase not found');
  }

  purchases.splice(index, 1);
  await saveDatabase();

  logger.info('Purchase deleted', { id });
}

/**
 * Get all purchases (admin/debug)
 */
async function getAllPurchases() {
  return purchases;
}

module.exports = {
  initDatabase,
  createPurchase,
  getPurchaseById,
  getPurchasesByUser,
  getDuePurchases,
  updatePurchaseStatus,
  cancelPurchase,
  deletePurchase,
  getAllPurchases
};
