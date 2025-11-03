require('dotenv').config();
const express = require('express');
const cors = require('cors');
const winston = require('winston');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 8084;

// Configure Winston logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: { service: 'shopping-agent' },
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    service: 'shopping-agent',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    env: process.env.NODE_ENV
  });
});

// API Routes
const cartRoutes = require('./routes/cart');
const productsRoutes = require('./routes/products');
const checkoutRoutes = require('./routes/checkout');

app.use('/cart', cartRoutes);
app.use('/products', productsRoutes);
app.use('/checkout', checkoutRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.path} not found`,
    availableRoutes: [
      'GET  /health',
      'POST /cart/add',
      'GET  /cart/:userId',
      'DELETE /cart/:userId/:itemId',
      'PATCH /cart/:userId/:itemId',
      'POST /products/resolve',
      'POST /products/compare',
      'POST /products/analyze',
      'POST /checkout/generate-link',
      'POST /checkout/stripe'
    ]
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Unhandled error', {
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method
  });

  res.status(err.status || 500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'An error occurred',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  logger.info(`🛒 Shopping Agent Service listening on http://0.0.0.0:${PORT}`);
  logger.info(`Environment: ${process.env.NODE_ENV}`);
  logger.info(`OpenAI API Key: ${process.env.OPENAI_API_KEY ? '✓ Configured' : '✗ Missing'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  process.exit(0);
});

module.exports = app;
