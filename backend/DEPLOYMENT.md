# ZerO Inbox Backend - Deployment Guide

Complete guide for deploying and managing the ZerO Inbox backend services in production.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Service Management](#service-management)
- [Monitoring](#monitoring)
- [Environment Variables](#environment-variables)
- [Troubleshooting](#troubleshooting)
- [Production Best Practices](#production-best-practices)

---

## Overview

The ZerO Inbox backend consists of 10 microservices managed by PM2 for production-grade reliability:

- **Gateway** (Port 3000) - API Gateway and routing
- **Classifier** (Port 3001) - Email classification and intent detection
- **Email** (Port 3002) - Email fetching and processing
- **Smart Replies** (Port 3003) - AI-powered reply suggestions
- **Shopping Agent** (Port 3004) - E-commerce assistance
- **Analytics** (Port 3005) - Usage analytics and metrics
- **Summarization** (Port 3006) - Content summarization
- **Scheduled Purchase** (Port 3007) - Scheduled buying and reminders
- **Actions** (Port 3008) - Action execution and tracking
- **Steel Agent** (Port 3009) - Advanced AI agent

## Prerequisites

### Required Software

```bash
# Node.js 18+ (recommended: use nvm)
node --version  # Should be v18.0.0 or higher

# npm (comes with Node.js)
npm --version

# PM2 (will be auto-installed by start script if missing)
npm install -g pm2
```

### System Requirements

- **Memory**: Minimum 4GB RAM (8GB recommended)
- **CPU**: 2+ cores
- **Disk**: 2GB free space
- **OS**: macOS, Linux, or Windows with WSL

### Environment Setup

1. **Clone the repository**:
```bash
git clone <your-repo-url>
cd Zer0_Inbox/backend
```

2. **Install dependencies**:
```bash
npm install
```

3. **Configure environment variables** (see [Environment Variables](#environment-variables))

---

## Quick Start

### 1. Start All Services

```bash
cd /Users/matthanson/Zer0_Inbox/backend
./start-services.sh start
```

This will:
- Install PM2 if not present
- Create log directories
- Start all 10 services with auto-restart
- Save the process list for persistence

### 2. Check Service Status

```bash
./start-services.sh status
# or
pm2 list
```

### 3. View Logs

```bash
# All services
./start-services.sh logs

# Specific service
pm2 logs gateway
pm2 logs classifier
```

### 4. Stop All Services

```bash
./start-services.sh stop
```

---

## Architecture

### Service Dependencies

```
Gateway (3000)
  ├─> Classifier (3001)
  ├─> Email (3002)
  ├─> Summarization (3006)
  └─> All other services

Client/iOS App
  └─> Gateway (3000) - Single entry point
```

**Important**: The Gateway service should start first and remain running for other services to function properly.

### Port Allocation

| Service | Port | Memory Limit | Purpose |
|---------|------|--------------|---------|
| Gateway | 3000 | 500M | API Gateway |
| Classifier | 3001 | 1G | Email classification |
| Email | 3002 | 500M | Email operations |
| Smart Replies | 3003 | 800M | AI replies |
| Shopping Agent | 3004 | 800M | Shopping assistance |
| Analytics | 3005 | 500M | Usage metrics |
| Summarization | 3006 | 800M | Summarization |
| Scheduled Purchase | 3007 | 500M | Purchase scheduling |
| Actions | 3008 | 500M | Action execution |
| Steel Agent | 3009 | 1G | Advanced AI |

### Health Check Endpoints

All services expose a `/health` endpoint:

```bash
curl http://localhost:3000/health  # Gateway
curl http://localhost:3001/health  # Classifier
# ... and so on
```

Response format:
```json
{
  "status": "ok",
  "service": "service-name",
  "timestamp": "2025-11-04T12:00:00.000Z"
}
```

---

## Service Management

### Available Commands

```bash
# Start all services
./start-services.sh start

# Stop all services
./start-services.sh stop

# Restart all services
./start-services.sh restart

# Show service status
./start-services.sh status

# View logs
./start-services.sh logs

# Run health check
./start-services.sh health

# Enable auto-start on boot
./start-services.sh startup
```

### PM2 Commands

```bash
# List all services
pm2 list

# View logs (all services)
pm2 logs

# View logs (specific service)
pm2 logs gateway
pm2 logs classifier

# Real-time monitoring dashboard
pm2 monit

# Restart a specific service
pm2 restart gateway

# Stop a specific service
pm2 stop gateway

# Delete a service
pm2 delete gateway

# Reload all services (zero-downtime)
pm2 reload all

# Save current process list
pm2 save

# Resurrect saved processes after reboot
pm2 resurrect

# Describe a service (detailed info)
pm2 describe gateway
```

### Auto-Restart on System Boot

To enable services to start automatically when your system boots:

```bash
./start-services.sh startup
```

This will display a command to run. Copy and execute it with sudo:

```bash
# Example output (run the command it gives you):
sudo env PATH=$PATH:/usr/local/bin pm2 startup darwin -u yourusername --hp /Users/yourusername
```

Then save your current process list:

```bash
pm2 save
```

---

## Monitoring

### Real-Time Monitoring

```bash
# PM2 built-in monitor
pm2 monit

# View metrics
pm2 describe gateway
```

### Health Checks

Use the built-in health check command:

```bash
./start-services.sh health
```

This checks if each service is responding on its designated port.

### Log Management

Logs are stored in `/Users/matthanson/Zer0_Inbox/backend/services/logs/`:

```
logs/
├── gateway-error.log
├── gateway-out.log
├── classifier-error.log
├── classifier-out.log
└── ... (one pair per service)
```

**Log rotation** is handled automatically by PM2 (configured in `ecosystem.config.js`).

### Memory Monitoring

Services will automatically restart if they exceed their memory limits:

```javascript
// Configured in ecosystem.config.js
max_memory_restart: '500M'  // or '800M' or '1G'
```

View current memory usage:

```bash
pm2 list  # Shows memory column
pm2 monit  # Real-time memory graph
```

---

## Environment Variables

### Required Variables

Create a `.env` file in `/Users/matthanson/Zer0_Inbox/backend/`:

```bash
# Node Environment
NODE_ENV=production

# Service URLs (internal)
EMAIL_SERVICE_URL=http://localhost:3002
CLASSIFIER_SERVICE_URL=http://localhost:3001
SUMMARIZATION_SERVICE_URL=http://localhost:3006
SMART_REPLIES_SERVICE_URL=http://localhost:3003
SHOPPING_AGENT_SERVICE_URL=http://localhost:3004
ANALYTICS_SERVICE_URL=http://localhost:3005
SCHEDULED_PURCHASE_SERVICE_URL=http://localhost:3007
ACTIONS_SERVICE_URL=http://localhost:3008
STEEL_AGENT_SERVICE_URL=http://localhost:3009

# OAuth Configuration
GMAIL_CLIENT_ID=your-gmail-client-id
GMAIL_CLIENT_SECRET=your-gmail-client-secret
GMAIL_REDIRECT_URI=http://localhost:3000/api/auth/gmail/callback

MICROSOFT_CLIENT_ID=your-microsoft-client-id
MICROSOFT_CLIENT_SECRET=your-microsoft-client-secret
MICROSOFT_REDIRECT_URI=http://localhost:3000/api/auth/microsoft/callback

# API Keys
OPENAI_API_KEY=your-openai-api-key
ANTHROPIC_API_KEY=your-anthropic-api-key

# Security
JWT_SECRET=your-secure-jwt-secret-here
ENCRYPTION_KEY=your-32-character-encryption-key

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000  # 15 minutes
RATE_LIMIT_MAX_REQUESTS=1000

# Database (if applicable)
# DATABASE_URL=your-database-url
```

### Setting Variables Per Service

Variables can be set in `ecosystem.config.js` under each service's `env` object:

```javascript
env: {
  NODE_ENV: 'production',
  PORT: 3000,
  CUSTOM_VAR: 'value'
}
```

---

## Troubleshooting

### Service Won't Start

1. **Check if port is already in use**:
```bash
lsof -i :3000  # Replace with your port
```

2. **Kill the process using the port**:
```bash
kill -9 <PID>
```

3. **Check logs for errors**:
```bash
pm2 logs gateway --lines 100
```

### Service Keeps Restarting

1. **Check error logs**:
```bash
pm2 logs gateway --err --lines 50
```

2. **Common issues**:
   - Missing environment variables
   - Port conflicts
   - Memory limits too low
   - Missing dependencies

3. **Increase restart delay** (in `ecosystem.config.js`):
```javascript
restart_delay: 8000  // Wait 8 seconds between restarts
```

### Memory Issues

If services are hitting memory limits:

1. **Increase memory limit** in `ecosystem.config.js`:
```javascript
max_memory_restart: '1G'  // Increase from 500M
```

2. **Check for memory leaks**:
```bash
pm2 monit  # Watch memory over time
```

### All Services Down

1. **Stop everything**:
```bash
./start-services.sh stop
```

2. **Clear PM2 cache**:
```bash
pm2 kill
```

3. **Start fresh**:
```bash
./start-services.sh start
```

### Can't Access Services from iOS App

1. **Verify Gateway is running**:
```bash
curl http://localhost:3000/health
```

2. **Check firewall settings**:
   - macOS: System Preferences > Security & Privacy > Firewall
   - Allow Node.js connections

3. **Verify CORS settings**:
   - Check `ALLOWED_ORIGINS` in `.env`
   - Should include your iOS simulator/device IP

### Logs Not Appearing

1. **Check log directory exists**:
```bash
ls -la /Users/matthanson/Zer0_Inbox/backend/services/logs/
```

2. **Check permissions**:
```bash
chmod -R 755 /Users/matthanson/Zer0_Inbox/backend/services/logs/
```

3. **Verify log paths** in `ecosystem.config.js`

---

## Production Best Practices

### Security

1. **Environment Variables**:
   - Never commit `.env` files to git
   - Use strong, unique values for `JWT_SECRET` and `ENCRYPTION_KEY`
   - Rotate secrets regularly

2. **CORS Configuration**:
   - Restrict `ALLOWED_ORIGINS` to specific domains
   - Don't use `*` in production

3. **Rate Limiting**:
   - Adjust limits based on expected traffic
   - Monitor for abuse patterns

### Performance

1. **Memory Limits**:
   - Set appropriate limits per service
   - Monitor actual usage and adjust

2. **Clustering**:
   - For high-traffic services, enable cluster mode:
   ```javascript
   instances: 2,  // Run 2 instances
   exec_mode: 'cluster'
   ```

3. **Log Rotation**:
   - PM2 handles this automatically
   - For custom rotation, use `pm2 install pm2-logrotate`

### Reliability

1. **Health Checks**:
   - Run periodic health checks:
   ```bash
   # Add to cron
   */5 * * * * /Users/matthanson/Zer0_Inbox/backend/start-services.sh health >> /tmp/health-check.log 2>&1
   ```

2. **Monitoring**:
   - Consider PM2 Plus for advanced monitoring
   - Set up alerts for service failures

3. **Backups**:
   - Regularly backup your `.env` file (securely)
   - Save PM2 process list after changes: `pm2 save`

### Deployment Checklist

- [ ] All dependencies installed
- [ ] `.env` file configured with production values
- [ ] Services start successfully
- [ ] Health checks pass
- [ ] Logs are being written
- [ ] Gateway is accessible from client
- [ ] PM2 startup script configured
- [ ] Monitoring/alerting set up
- [ ] Documentation shared with team

---

## Getting Help

1. **Check logs first**:
```bash
pm2 logs --lines 100
```

2. **Run health check**:
```bash
./start-services.sh health
```

3. **Check GitHub Issues**:
   - Search for similar issues
   - Create a new issue with logs and environment details

4. **Contact**: [Your contact information]

---

## Additional Resources

- [PM2 Documentation](https://pm2.keymetrics.io/docs/usage/quick-start/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [ZerO Inbox Main Repository](your-repo-url)

---

**Last Updated**: 2025-11-04
**Version**: 1.0.0
