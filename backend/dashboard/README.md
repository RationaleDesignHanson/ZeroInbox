# Zero Email Dashboard Control Center

Comprehensive web-based dashboard for monitoring, testing, and managing EmailShortForm (Zero) backend services.

## 📋 Overview

The Dashboard Control Center provides a beautiful, responsive web interface for managing all aspects of the Zero Email backend infrastructure:

- **Real-time service monitoring** with health checks
- **Comprehensive system testing** with detailed results
- **Analytics and metrics** for classification and actions
- **Proactive issue detection** with guided resolution workflows
- **Integration with existing tools** (Design System, Zero Sequence Generator)

## 🌐 Pages

### 1. Main Dashboard (`index.html`)
**URL**: `/dashboard/index.html`

The central navigation hub providing:
- System status overview
- Quick actions (start/stop/validate/test)
- Service health preview (8 services)
- Navigation cards to all tools
- Real-time statistics

**Features**:
- Auto-refresh every 5 seconds
- System status badge (operational/degraded/down)
- KPI cards (services healthy, uptime, requests, test pass rate)
- Links to all dashboard pages and existing tools

### 2. Service Monitor (`service-monitor.html`)
**URL**: `/dashboard/service-monitor.html`

Detailed real-time monitoring of all 8 backend services:
- Live health status with pulse animations
- Service control buttons (start/stop/restart/logs)
- Response times and PID tracking
- Critical vs optional service badges
- Service logs viewer

**Services Monitored**:
- Gateway (3001) - Critical
- Email Service (8081) - Critical
- Classifier (8082) - Critical
- Summarization (8083) - Critical
- Smart Replies (8084) - Optional
- Scheduled Purchase (8085) - Optional
- Shopping Agent (8086) - Optional
- Steel Agent (8087) - Optional

### 3. System Health Tests (`system-health.html`)
**URL**: `/dashboard/system-health.html`

Interactive test execution and results display:
- Run all 26 comprehensive health tests
- Real-time progress tracking
- Test categories: Service Health, Configuration, Shared Resources, Critical Path
- Pass/fail indicators with error details
- Console output logging

**Test Categories**:
1. **Service Health** (8 tests) - All service health checks
2. **Configuration** (7 tests) - Environment variables
3. **Shared Resources** (5 tests) - Intent taxonomy, action catalog
4. **Critical Path** (6 tests) - OAuth, JWT, email classification

### 4. Analytics Dashboard (`analytics.html`)
**URL**: `/dashboard/analytics.html`

Visual analytics with Chart.js:
- Email processing volume (line chart)
- Intent category distribution (donut chart)
- Most executed actions (horizontal bar chart)
- Service performance metrics (radar chart)
- Top classified intents table

**KPIs Displayed**:
- Emails processed (with trends)
- Intent types (117 intents)
- Classification accuracy
- Average actions per email

### 5. Issue Resolution Center (`issues.html`)
**URL**: `/dashboard/issues.html`

Proactive issue detection with guided fixes:
- Detected issues with severity badges (critical/warning/info)
- Step-by-step resolution workflows
- Auto-resolve functionality
- Issue history and tracking

**Issue Types**:
- Service failures (critical)
- Performance degradation (warning)
- Configuration issues (warning)
- Optimization recommendations (info)

## 🔌 Backend API

### Installation

Add the dashboard API router to your Gateway server:

```javascript
// In backend/gateway/server.js
const dashboardAPI = require('../dashboard/api');

// Add after other routes
app.use('/api/dashboard', dashboardAPI);
```

### API Endpoints

#### Service Status
```
GET  /api/dashboard/status
GET  /api/dashboard/services/:port/health
```

#### Service Control
```
POST /api/dashboard/services/start-all
POST /api/dashboard/services/stop-all
POST /api/dashboard/services/:port/start
POST /api/dashboard/services/:port/stop
POST /api/dashboard/services/:port/restart
```

#### Service Logs
```
GET  /api/dashboard/services/:port/logs
```

#### System Tests
```
POST /api/dashboard/tests/run
POST /api/dashboard/validate
```

## 🎨 Design System

The dashboard uses the same beautiful glass-morphism design as existing Zero tools:

**Color Gradients**:
- `--gradient-mail`: `linear-gradient(135deg, #667eea 0%, #764ba2 100%)`
- `--gradient-ads`: `linear-gradient(135deg, #f093fb 0%, #f5576c 100%)`
- `--gradient-child-school`: `linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)`
- `--gradient-travel`: `linear-gradient(135deg, #fa709a 0%, #fee140 100%)`
- `--gradient-health`: `linear-gradient(135deg, #30cfd0 0%, #330867 100%)`

**UI Components**:
- Glass-morphism cards with `backdrop-filter: blur(10px)`
- Responsive grid layouts
- Animated status indicators
- Interactive buttons with hover effects
- Real-time charts using Chart.js

## 🚀 Quick Start

### ⚠️ IMPORTANT: HTTP Server Required

**The dashboard pages MUST be served via HTTP (not opened with `file://`)** due to CORS restrictions when loading JSON data files.

**Symptoms of opening with `file://`:**
- Intent dropdown only shows "All Intents" (no other options)
- Console error: `Failed to fetch` or `CORS policy` blocked
- Console log: `emailsByIntent has 0 intents`

### 1. Start the Web Server

```bash
cd /Users/matthanson/Zer0_Inbox/backend/dashboard
python3 -m http.server 8088
```

### 2. Open in Browser

```
http://localhost:8088/index.html
http://localhost:8088/action-modal-explorer.html
http://localhost:8088/intent-action-explorer.html
http://localhost:8088/shopping-cart.html
```

**Do NOT use `file:///` protocol** - the fetch() calls for JSON data will fail.

### 3. Navigate

From the main dashboard:
- **Service Monitor** → Real-time service status
- **System Health Tests** → Run comprehensive tests
- **Analytics Dashboard** → View metrics and charts
- **Issue Resolution** → Detect and fix problems
- **Design System** → UI component library
- **Zero Sequence Tools** → Intent-Action auditor

### 4. Use Quick Actions

- **Start All Services** → Launches all 8 backend services
- **Stop All Services** → Gracefully stops all services
- **Validate Critical Path** → Tests OAuth + email flow
- **Run Health Tests** → Executes all 26 tests
- **Refresh Status** → Updates dashboard data

## 📊 Features

### Real-Time Monitoring
- Auto-refresh every 5 seconds
- WebSocket support (planned)
- Live service health indicators
- Animated pulse effects for status

### Service Management
- Start/stop individual services
- Restart services with one click
- View service logs in real-time
- Control all services at once

### System Testing
- 26 comprehensive health tests
- Test categories with collapsible sections
- Real-time progress tracking
- Detailed error messages
- Console output logging

### Analytics
- Beautiful charts with Chart.js
- Email processing volume trends
- Intent distribution visualization
- Action execution frequency
- Service performance metrics

### Issue Detection
- Proactive issue scanning
- Severity-based prioritization (critical/warning/info)
- Step-by-step resolution guides
- Auto-resolve capability
- Issue history tracking

## 🔒 Security

**Safety Guarantees**:
- ✅ Never modifies token files (`./data/tokens/*.json`)
- ✅ Never modifies `.env` configuration
- ✅ Confirms destructive actions (stop services, clear cache)
- ✅ Validates OAuth flow before operations
- ✅ Read-only access to configuration files

**Best Practices**:
- Always run validation before stopping services
- Use service monitor to check logs before restarting
- Run health tests after any changes
- Review issue recommendations before auto-resolving

## 🛠️ Development

### File Structure
```
backend/dashboard/
├── index.html              # Main homepage
├── service-monitor.html    # Service monitoring
├── system-health.html      # Health testing
├── analytics.html          # Analytics dashboard
├── issues.html             # Issue resolution
├── api.js                  # Backend API router
├── assets/                 # Shared assets (future)
│   ├── dashboard.css       # Shared styles
│   ├── dashboard.js        # Shared utilities
│   └── charts.js           # Chart.js wrapper
└── README.md               # This file
```

### Adding New Features

**1. Add a New Page**:
```html
<!-- Copy structure from existing pages -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>New Feature - Zero Email Dashboard</title>
    <!-- Include existing styles for consistency -->
</head>
<body>
    <div class="container">
        <div class="header">
            <a href="index.html" class="btn">← Back to Dashboard</a>
        </div>
        <!-- Your content here -->
    </div>
</body>
</html>
```

**2. Add API Endpoint**:
```javascript
// In dashboard/api.js
router.get('/new-endpoint', async (req, res) => {
    try {
        // Your logic here
        res.json({ success: true, data: {} });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});
```

**3. Add to Main Navigation**:
```html
<!-- In index.html -->
<a href="new-page.html" class="nav-card">
    <div class="nav-card-icon">🆕</div>
    <div class="nav-card-title">New Feature</div>
    <div class="nav-card-description">Description here</div>
</a>
```

## 📈 Performance

### Load Times
- Main dashboard: <2 seconds
- Service monitor: <1 second
- System health tests: Variable (depends on test execution)
- Analytics: <1 second (Chart.js rendering)

### Auto-Refresh
- Service monitor: Every 5 seconds
- Main dashboard: Every 5 seconds
- Health tests: On-demand only

### Resource Usage
- Minimal CPU usage (no heavy processing)
- ~5-10MB memory per page
- No data persistence (stateless)

## 🔗 Integration

### With Existing Tools

**Design System**:
- Navigation card from main dashboard
- Opens `../Zero/design-system-renderer.html`
- Shares same visual language

**Zero Sequence Generator**:
- Navigation card from main dashboard
- Opens `../Zero/zero-sequence-generator.html`
- Access to 117 intents and action catalog

**Service Manager**:
- Dashboard API uses `service-manager.js`
- Leverages existing start/stop/validate commands
- Preserves OAuth token safety checks

### With Backend Services

Dashboard integrates with:
- Gateway (3001) - OAuth endpoints
- Email Service (8081) - Email fetching
- Classifier (8082) - Intent detection
- Summarization (8083) - AI summaries
- Smart Replies (8084) - Reply suggestions
- Scheduled Purchase (8085) - Purchase scheduling
- Shopping Agent (8086) - Shopping assistant
- Steel Agent (8087) - Browser automation

## 🐛 Troubleshooting

### Dashboard Not Loading
- Check file path is correct
- Try serving via HTTP server
- Check browser console for errors

### API Endpoints Not Working
- Verify dashboard API is registered in gateway/server.js
- Check services are running
- Review backend logs for errors

### Services Not Starting
- Run `npm run start:all` manually
- Check port conflicts with `lsof -ti:PORT`
- Verify .env configuration

### Charts Not Rendering
- Check Chart.js CDN is accessible
- Review browser console for errors
- Verify canvas elements are present

## 📝 TODO

### Phase 1: Core Infrastructure ✅
- [x] Main dashboard homepage
- [x] Service monitor page
- [x] System health testing page
- [x] Analytics dashboard
- [x] Issue resolution center
- [x] Backend API router

### Phase 2: Enhancement (Future)
- [ ] WebSocket server for real-time updates
- [ ] Shared CSS/JS assets
- [ ] User authentication
- [ ] Dashboard configuration persistence
- [ ] Email notification for critical issues
- [ ] Historical metrics storage
- [ ] Service performance profiling

### Phase 3: Advanced Features (Future)
- [ ] Docker integration
- [ ] Kubernetes dashboard
- [ ] CI/CD pipeline status
- [ ] Automated deployment tools
- [ ] A/B testing framework
- [ ] Feature flag management

## 📄 License

Part of EmailShortForm (Zero) project - MIT License

## 👥 Contributors

Built with ❤️ for rapid email triage

---

**Version**: 1.0.0
**Last Updated**: October 28, 2025
**Backend Version**: 1.2.0
**iOS App Version**: 1.0
