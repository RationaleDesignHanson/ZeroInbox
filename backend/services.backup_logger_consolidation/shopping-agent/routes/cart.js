const express = require('express');
const router = express.Router();
const cartStore = require('../lib/cartStore');
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'shopping-agent-cart' },
  transports: [new winston.transports.Console()]
});

/**
 * POST /cart/add
 * Add item to cart
 */
router.post('/add', async (req, res) => {
  try {
    const { userId, ...itemData } = req.body;

    if (!userId) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'userId is required'
      });
    }

    // Validate required fields
    if (!itemData.productName || !itemData.price) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'productName and price are required'
      });
    }

    const item = cartStore.addItem(userId, itemData);

    logger.info('Item added to cart', {
      userId,
      itemId: item.id,
      productName: item.productName
    });

    res.status(201).json({
      success: true,
      item: item.toJSON(),
      summary: cartStore.getCartSummary(userId)
    });

  } catch (error) {
    logger.error('Error adding item to cart', {
      error: error.message,
      stack: error.stack
    });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * GET /cart/:userId
 * Get user's cart
 */
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const cart = cartStore.getCart(userId);
    const summary = cartStore.getCartSummary(userId);

    logger.info('Cart retrieved', {
      userId,
      itemCount: cart.length
    });

    res.json({
      success: true,
      cart: cart.map(item => item.toJSON()),
      summary
    });

  } catch (error) {
    logger.error('Error retrieving cart', {
      error: error.message,
      userId: req.params.userId
    });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * PATCH /cart/:userId/:itemId
 * Update cart item (quantity, etc.)
 */
router.patch('/:userId/:itemId', async (req, res) => {
  try {
    const { userId, itemId } = req.params;
    const { quantity } = req.body;

    if (!quantity || quantity < 1) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'quantity must be at least 1'
      });
    }

    const item = cartStore.updateItemQuantity(userId, itemId, quantity);

    logger.info('Cart item updated', {
      userId,
      itemId,
      newQuantity: quantity
    });

    res.json({
      success: true,
      item: item.toJSON(),
      summary: cartStore.getCartSummary(userId)
    });

  } catch (error) {
    logger.error('Error updating cart item', {
      error: error.message,
      userId: req.params.userId,
      itemId: req.params.itemId
    });

    const statusCode = error.message === 'Item not found in cart' ? 404 : 500;
    res.status(statusCode).json({
      error: statusCode === 404 ? 'Not Found' : 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * DELETE /cart/:userId/:itemId
 * Remove item from cart
 */
router.delete('/:userId/:itemId', async (req, res) => {
  try {
    const { userId, itemId } = req.params;

    const removed = cartStore.removeItem(userId, itemId);

    if (!removed) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Item not found in cart'
      });
    }

    logger.info('Cart item removed', {
      userId,
      itemId
    });

    res.json({
      success: true,
      message: 'Item removed from cart',
      summary: cartStore.getCartSummary(userId)
    });

  } catch (error) {
    logger.error('Error removing cart item', {
      error: error.message,
      userId: req.params.userId,
      itemId: req.params.itemId
    });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * DELETE /cart/:userId
 * Clear entire cart
 */
router.delete('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    cartStore.clearCart(userId);

    logger.info('Cart cleared', { userId });

    res.json({
      success: true,
      message: 'Cart cleared'
    });

  } catch (error) {
    logger.error('Error clearing cart', {
      error: error.message,
      userId: req.params.userId
    });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * GET /cart/:userId/summary
 * Get cart summary (counts, totals, expiring items)
 */
router.get('/:userId/summary', async (req, res) => {
  try {
    const { userId } = req.params;

    const summary = cartStore.getCartSummary(userId);

    res.json({
      success: true,
      summary
    });

  } catch (error) {
    logger.error('Error getting cart summary', {
      error: error.message,
      userId: req.params.userId
    });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

module.exports = router;
