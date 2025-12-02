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

// IP Theft Protection: Request logging and monitoring (optional in production)
try {
  const requestLogger = require('../shared/middleware/request-logger');
  app.use(requestLogger('dashboard-web-server'));
  console.log('✅ Request logger middleware loaded');
} catch (error) {
  console.log('ℹ️  Request logger not available (production mode)');
}

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

// Helper function to get action objects from ActionCatalog
function getActionObjects(actionIds) {
  const { ActionCatalog } = require('./action-catalog');
  return actionIds.map(actionId => {
    const action = ActionCatalog[actionId];
    if (!action) {
      console.warn(`Action not found in catalog: ${actionId}`);
      return null;
    }
    // Return full action object with all properties
    return {
      actionId: action.actionId,
      displayName: action.displayName,
      actionType: action.actionType,
      description: action.description,
      priority: action.priority,
      requiredEntities: action.requiredEntities,
      validIntents: action.validIntents,
      isPrimary: false // Will be set for first action
    };
  }).filter(a => a !== null);
}

// Classify endpoint for production demo (static mock response)
app.post('/api/classify', (req, res) => {
  try {
    const email = req.body.email || {};

    // Mock classification based on email subject patterns
    let intent = 'general.inquiry';
    let confidence = 0.85;
    let actionIds = ['quick_reply', 'save_for_later'];
    let entities = {};

    const subject = (email.subject || '').toLowerCase();
    const body = (email.body || '').toLowerCase();

    // Pattern matching for demo purposes with entity extraction
    if (subject.includes('meeting') || subject.includes('calendar')) {
      intent = 'scheduling.meeting-request';
      actionIds = ['add_to_calendar', 'quick_reply'];
      confidence = 0.92;
      // Add meeting entities
      entities.deadline = 'Tomorrow at 2 PM';
      entities.dateTime = 'Tomorrow at 2:00 PM';
    } else if (subject.includes('shipped') || subject.includes('tracking') || body.includes('track')) {
      intent = 'e-commerce.shipping';
      actionIds = ['track_package', 'save_for_later'];
      confidence = 0.95;
      // Add shipping entities
      entities.trackingNumber = '1Z999AA10123456784';
      entities.trackingNumbers = ['1Z999AA10123456784'];
      entities.companies = [{ name: 'UPS', type: 'carrier' }];
      entities.company = { name: 'UPS', type: 'carrier' };
    } else if (subject.includes('invoice') || subject.includes('payment')) {
      intent = 'transactions.invoice';
      actionIds = ['pay_invoice', 'save_for_later'];
      confidence = 0.90;
      // Add invoice entities
      entities.paymentAmount = 149.99;
      entities.prices = { original: 149.99, currency: 'USD' };
      entities.invoiceId = 'INV-2024-001234';
    }

    // Convert action IDs to full action objects from ActionCatalog
    const suggestedActions = getActionObjects(actionIds);
    // Mark first action as primary
    if (suggestedActions.length > 0) {
      suggestedActions[0].isPrimary = true;
    }

    res.json({
      intent: intent,
      intentConfidence: confidence,
      confidence: confidence,
      suggestedActions: suggestedActions,
      // Entity extraction data
      trackingNumber: entities.trackingNumber,
      trackingNumbers: entities.trackingNumbers,
      companies: entities.companies,
      company: entities.company,
      deadline: entities.deadline,
      dateTime: entities.dateTime,
      paymentAmount: entities.paymentAmount,
      prices: entities.prices,
      invoiceId: entities.invoiceId,
      _classificationSource: 'demo-mock',
      type: 'mail'
    });
  } catch (error) {
    console.error('Error in classify endpoint:', error);
    res.status(500).json({ error: 'Classification failed' });
  }
});

console.log('✅ API endpoints configured');

// Health endpoint - used by demo pages to check service availability
// In production, dashboard serves classifier/actions as static data
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'zero-dashboard',
    timestamp: new Date().toISOString(),
    provides: ['classifier', 'actions', 'static-data']
  });
});

// Protected routes - require authentication
// Public pages (accessible without auth)
const PUBLIC_PAGES = [
  'splash.html',
  'landing.html',
  'app-demo.html',
  'zero-sequence-live.html',
  'zero-sequence-live-with-64.html'
];

// Root route - public marketing landing page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'landing.html'));
});

// Landing page - public marketing page
app.get('/landing.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'landing.html'));
});

// Splash page - beta tester login gateway
app.get('/splash.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'splash.html'));
});

// App demo page - public access (for iframe embed)
app.get('/app-demo.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'app-demo.html'));
});

// Zero Sequence Live demo pages - public access
app.get('/zero-sequence-live.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'zero-sequence-live.html'));
});

app.get('/zero-sequence-live-with-64.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'zero-sequence-live-with-64.html'));
});

// All other HTML pages require authentication
app.get('/*.html', requireAuth, (req, res) => {
  const fileName = path.basename(req.path);
  res.sendFile(path.join(__dirname, fileName));
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
