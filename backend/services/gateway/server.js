require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const logger = require('./shared/config/logger');
const { authenticateRequest } = require('./shared/utils/auth');
const axios = require('axios');

const authRoutes = require('./routes/auth');
const emailRoutes = require('./routes/emails');
// Commented out - these routes import services outside Docker context
// const savedMailRoutes = require('./routes/saved-mail');
// const feedbackRoutes = require('./routes/feedback');

// Token refresh scheduler for proactive token management
const { startTokenRefreshScheduler } = require('./shared/services/token-refresh-scheduler');

const app = express();
const PORT = process.env.PORT || 3001;

// Trust proxy for Cloud Run and local development
// Setting to specific number instead of boolean to prevent rate limiter errors
// In production: trust Google Cloud's proxy (1 hop)
// In development: trust local proxy/loopback (1 hop)
app.set('trust proxy', 1);

// Rate limiting (with skip for development/testing)
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 1000, // Increased from 100 to 1000
  standardHeaders: true,
  legacyHeaders: false,
  // Validate trust proxy setting to prevent IP spoofing
  validate: { trustProxy: false },
  // Skip rate limiting if unable to determine IP (prevents crashes)
  skip: (req) => !req.ip
});

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true
}));
app.use(express.json());
app.use(limiter);

// Request logging
app.use((req, res, next) => {
  logger.info('Incoming request', {
    method: req.method,
    path: req.path,
    ip: req.ip
  });
  next();
});

// Welcome page
app.get('/', (req, res) => {
  res.json({
    service: 'Zero Email API Gateway',
    version: '1.0.0',
    status: 'operational',
    endpoints: {
      health: '/health',
      auth: {
        gmail: '/api/auth/gmail',
        microsoft: '/api/auth/microsoft'
      },
      api: {
        emails: '/api/emails/*',
        classifier: '/api/classifier/*',
        summarization: '/api/summarization/*'
      },
      dashboard: 'https://zero-dashboard-514014482017.us-central1.run.app'
    },
    documentation: 'https://github.com/yourusername/zero-email'
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'api-gateway',
    timestamp: new Date().toISOString(),
    services: {
      email: process.env.EMAIL_SERVICE_URL,
      classifier: process.env.CLASSIFIER_SERVICE_URL,
      summarization: process.env.SUMMARIZATION_SERVICE_URL
    }
  });
});

// Auth routes (public)
app.use('/api/auth', authRoutes);

// Email routes (protected)
app.use('/api/emails', authenticateRequest, emailRoutes);

// Commented out - these routes import services outside Docker context
// Saved mail routes (protected)
// app.use('/api/saved-mail', authenticateRequest, savedMailRoutes);

// Feedback routes (protected)
// app.use('/api/feedback', authenticateRequest, feedbackRoutes);

// Proxy to email service
app.use('/api/email-service', authenticateRequest, async (req, res) => {
  try {
    const response = await axios({
      method: req.method,
      url: `${process.env.EMAIL_SERVICE_URL}${req.path}`,
      data: req.body,
      headers: {
        'Content-Type': 'application/json'
      }
    });
    res.json(response.data);
  } catch (error) {
    logger.error('Email service proxy error', { error: error.message });
    res.status(error.response?.status || 500).json({
      error: error.response?.data || 'Service unavailable'
    });
  }
});

// Proxy to classifier service
app.use('/api/classifier', async (req, res) => {
  try {
    const response = await axios({
      method: req.method,
      url: `${process.env.CLASSIFIER_SERVICE_URL}${req.path}`,
      data: req.body,
      headers: {
        'Content-Type': 'application/json'
      }
    });
    res.json(response.data);
  } catch (error) {
    logger.error('Classifier service proxy error', { error: error.message });
    res.status(error.response?.status || 500).json({
      error: error.response?.data || 'Service unavailable'
    });
  }
});

// Proxy to summarization service
app.use('/api/summarization', async (req, res) => {
  try {
    const response = await axios({
      method: req.method,
      url: `${process.env.SUMMARIZATION_SERVICE_URL}${req.path}`,
      data: req.body,
      headers: {
        'Content-Type': 'application/json'
      }
    });
    res.json(response.data);
  } catch (error) {
    logger.error('Summarization service proxy error', { error: error.message });
    res.status(error.response?.status || 500).json({
      error: error.response?.data || 'Service unavailable'
    });
  }
});

// Dashboard API routes (development only - provides service management)
const dashboardAPI = require('../../dashboard/api');
app.use('/api/dashboard', dashboardAPI);

// Serve dashboard static files (HTML, JS, CSS)
const path = require('path');
app.use('/dashboard', express.static(path.join(__dirname, '../../dashboard')));

// Auth Status API routes (OAuth token management)
const authStatusRoutes = require('./routes/auth-status');
app.use('/api/auth-status', authStatusRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Error handling
app.use((err, req, res, next) => {
  logger.error('Gateway error', { error: err.message, stack: err.stack });
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
  logger.info(`API Gateway running on port ${PORT}`);
  console.log(`\n🚀 API Gateway listening on http://localhost:${PORT}`);
  console.log(`\n📧 Connected Services:`);
  console.log(`   Email Service:         ${process.env.EMAIL_SERVICE_URL}`);
  console.log(`   Classifier Service:    ${process.env.CLASSIFIER_SERVICE_URL}`);
  console.log(`   Summarization Service: ${process.env.SUMMARIZATION_SERVICE_URL}`);
  console.log(`\n🔐 OAuth Endpoints:`);
  console.log(`   Gmail:     http://localhost:${PORT}/api/auth/gmail`);
  console.log(`   Outlook:   http://localhost:${PORT}/api/auth/microsoft`);
  console.log(`\n💡 Tip: Start all services with: npm run start:all\n`);

  // Start token refresh scheduler for proactive OAuth management
  startTokenRefreshScheduler();
  console.log(`🔄 Token refresh scheduler started (checks every hour)\n`);
});

module.exports = app;
