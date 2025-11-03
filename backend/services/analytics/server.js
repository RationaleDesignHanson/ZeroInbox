/**
 * Analytics Service
 *
 * Collects and analyzes usage metrics from Zero Email App
 * Provides real-time insights into user behavior and system performance
 *
 * Port: 8090
 * Endpoints:
 * - POST /api/events - Track analytics events
 * - GET /api/metrics - Get aggregated metrics
 * - GET /api/metrics/:metric - Get specific metric data
 * - GET /api/health - Health check
 */

const express = require('express');
const cors = require('cors');
const winston = require('winston');
require('dotenv').config();

const metricsRouter = require('./routes/metrics');

const app = express();
const PORT = process.env.PORT || 8090;

// Logging
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: { service: 'analytics' },
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    }),
    new winston.transports.File({ filename: 'analytics.log' })
  ]
});

// Middleware
app.use(cors()); // Allow all origins for dashboard access
app.use(express.json({ limit: '10mb' }));

// Request logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.headers['user-agent']
  });
  next();
});

// Routes
app.use('/api', metricsRouter);

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'analytics',
    port: PORT,
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Error handling
app.use((err, req, res, next) => {
  logger.error('Error:', {
    error: err.message,
    stack: err.stack,
    path: req.path
  });
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.path
  });
});

// Start server
app.listen(PORT, () => {
  logger.info(`Analytics service listening on port ${PORT}`);
  logger.info(`Health check: http://localhost:${PORT}/health`);
  logger.info(`API: http://localhost:${PORT}/api`);
});

module.exports = app;
