require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const logger = require('./logger');
const { authenticateRequest } = require('./auth');

const gmailRouter = require('./routes/gmail');
const outlookRouter = require('./routes/outlook');
const yahooRouter = require('./routes/yahoo');
const icloudRouter = require('./routes/icloud');

const app = express();
const PORT = process.env.PORT || process.env.EMAIL_SERVICE_PORT || 8081;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Simple internal auth middleware for service-to-service calls
const internalAuth = (req, res, next) => {
  const userId = req.headers['x-user-id'];
  if (userId) {
    req.user = { userId };
    next();
  } else {
    // Try JWT auth as fallback
    authenticateRequest(req, res, next);
  }
};

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'email-service', timestamp: new Date().toISOString() });
});

// Routes - accept both JWT and internal X-User-ID header
app.use('/api/gmail', internalAuth, gmailRouter);
app.use('/api/outlook', internalAuth, outlookRouter);
app.use('/api/yahoo', internalAuth, yahooRouter);
app.use('/api/icloud', internalAuth, icloudRouter);

// Error handling
app.use((err, req, res, next) => {
  logger.error('Email service error', { error: err.message, stack: err.stack });
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
  logger.info(`Email service running on port ${PORT}`);
  console.log(`📧 Email Service listening on http://localhost:${PORT}`);
});

module.exports = app;
