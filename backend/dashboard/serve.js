/**
 * Zero Dashboard Server
 * Serves static files with authentication protection
 */

const express = require('express');
const path = require('path');
const { requireAuth } = require('./auth-middleware');
const authRoutes = require('./auth-routes');

const app = express();
const PORT = 8088;

// Parse JSON request bodies
app.use(express.json());

// Enable CORS for API calls
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  next();
});

// Auth routes (publicly accessible)
app.use('/auth', authRoutes);

// Public static assets (JS, CSS, images) - no auth required
app.use('/js', express.static(path.join(__dirname, 'js')));
app.use('/css', express.static(path.join(__dirname, 'css')));
app.use('/images', express.static(path.join(__dirname, 'images')));

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

// Root route - redirect to splash if not authenticated, otherwise show index
app.get('/', requireAuth, (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
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
