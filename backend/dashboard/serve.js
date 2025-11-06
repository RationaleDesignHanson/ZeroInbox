/**
 * Zero Dashboard Server
 * Serves static files with authentication protection
 */

// Startup logging for Cloud Run debugging
console.log('🚀 Starting Zero Dashboard Server...');
console.log('📦 Node version:', process.version);
console.log('🔧 Environment PORT:', process.env.PORT);

const express = require('express');
const compression = require('compression');
const path = require('path');

console.log('✅ Core dependencies loaded');

const { requireAuth } = require('./auth-middleware');
const authRoutes = require('./auth-routes');

console.log('✅ Auth modules loaded');

const app = express();
const PORT = process.env.PORT || 8088;

console.log(`🎯 Server will listen on port ${PORT}`);

// Enable gzip compression for all responses
// Reduces 340KB HTML + 132KB JSON to ~50KB total
app.use(compression({
  filter: (req, res) => {
    if (req.headers['x-no-compression']) {
      return false;
    }
    return compression.filter(req, res);
  },
  level: 6 // Balance between speed and compression ratio
}));

// Parse JSON request bodies
app.use(express.json());

// IP Theft Protection: Request logging and monitoring
const requestLogger = require('../shared/middleware/request-logger');
app.use(requestLogger('dashboard-web-server'));

// Enable CORS for API calls
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  next();
});

// Auth routes (publicly accessible)
app.use('/auth', authRoutes);

// Public static assets (JS, CSS, images, data) - no auth required
app.use('/js', express.static(path.join(__dirname, 'js')));
app.use('/css', express.static(path.join(__dirname, 'css')));
app.use('/images', express.static(path.join(__dirname, 'images')));
app.use('/data', express.static(path.join(__dirname, 'data')));

// API Endpoints - Static data fallbacks for production
console.log('📡 Setting up API endpoints...');

// Intent Taxonomy endpoint
app.get('/api/intent-taxonomy', (req, res) => {
  try {
    const { IntentTaxonomy } = require('./Intent');
    const { ActionCatalog } = require('./action-catalog');

    // Map intents with their actions
    const intentList = Object.keys(IntentTaxonomy).map(intentId => {
      const intent = IntentTaxonomy[intentId];

      // Find actions mapped to this intent
      const mappedActions = Object.entries(ActionCatalog)
        .filter(([actionId, action]) => action.intents?.includes(intentId))
        .map(([actionId]) => actionId);

      return {
        id: intentId,
        category: intent.category,
        displayName: intent.displayName,
        description: intent.description,
        examplePhrases: intent.examplePhrases || [],
        mappedActions: mappedActions,
        confidence: intent.confidence || 'medium',
        keywords: intent.keywords || []
      };
    });

    res.json({ intents: intentList, count: intentList.length });
  } catch (error) {
    console.error('Error serving intent taxonomy:', error);
    res.status(500).json({ error: 'Failed to load intent taxonomy' });
  }
});

// Actions Catalog endpoint
app.get('/api/actions/catalog', (req, res) => {
  try {
    const { ActionCatalog } = require('./action-catalog');
    res.json({
      actions: ActionCatalog,
      count: Object.keys(ActionCatalog).length
    });
  } catch (error) {
    console.error('Error serving actions catalog:', error);
    res.status(500).json({ error: 'Failed to load actions catalog' });
  }
});

console.log('✅ API endpoints configured');

// Protected routes - require authentication
// Splash page (login) is accessible without auth
app.get('/splash.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'splash.html'));
});

// All other HTML pages require authentication
app.get('/*.html', requireAuth, (req, res) => {
  const fileName = path.basename(req.path);
  res.sendFile(path.join(__dirname, fileName));
});

// Root route - redirect to splash if not authenticated, otherwise show landing page
app.get('/', requireAuth, (req, res) => {
  res.sendFile(path.join(__dirname, 'landing.html'));
});

// Error handling for uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`
╔═══════════════════════════════════════════════════════════╗
║              Zero Dashboard Server                         ║
║                   Port ${PORT}                                ║
╠═══════════════════════════════════════════════════════════╣
║                                                            ║
║  Dashboard: http://localhost:${PORT}                           ║
║                                                            ║
║  Pages:                                                    ║
║    • http://localhost:${PORT}/                                 ║
║    • http://localhost:${PORT}/system-health.html               ║
║    • http://localhost:${PORT}/zero-sequence-live.html          ║
║    • http://localhost:${PORT}/intent-action-explorer.html      ║
║    • http://localhost:${PORT}/design-system-renderer.html      ║
║                                                            ║
║  Status: ✅ Ready                                           ║
╚═══════════════════════════════════════════════════════════╝
  `);
});

server.on('error', (error) => {
  console.error('❌ Server error:', error);
  process.exit(1);
});
