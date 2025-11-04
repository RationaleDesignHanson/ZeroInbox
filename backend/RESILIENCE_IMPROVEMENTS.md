# Service Resilience Improvements

**Date**: 2025-11-03
**Status**: 🚨 **CRITICAL** - Email Service, Smart Replies, and Shopping Agent reported down
**Priority**: **IMMEDIATE ACTION REQUIRED**

---

## Executive Summary

**Current Issues**:
- ❌ Email Service (port 8081) - DOWN
- ❌ Smart Replies Service (port 8086) - DOWN
- ❌ Shopping Agent (port 8084) - DOWN

**Root Causes Identified**:
1. **No automatic restart mechanisms** for crashed services
2. **No circuit breakers** for external API failures
3. **No rate limiting** to prevent API quota exhaustion
4. **No connection pooling** for external services
5. **Insufficient error recovery** mechanisms
6. **No health check dependencies** (can report healthy while dependencies are down)
7. **No graceful degradation** patterns implemented consistently

---

## Immediate Actions (Next 2 Hours)

### 1. Check Service Status and Restart

```bash
# Check if services are running locally
lsof -i :8081  # email-service
lsof -i :8086  # smart-replies
lsof -i :8084  # shopping-agent

# Check Cloud Run services
gcloud run services list --platform managed --region us-central1

# Check service logs for errors
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=email-service" --limit 50 --format json

gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=smart-replies-service" --limit 50 --format json

gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=shopping-agent-service" --limit 50 --format json
```

### 2. Verify API Keys and Credentials

```bash
# Check if required environment variables are set in Cloud Run
gcloud run services describe email-service --region us-central1 --format="value(spec.template.spec.containers[0].env)"

# Verify credentials
# - Google Cloud authentication (Vertex AI for smart-replies)
# - Email provider credentials (Gmail, Outlook, Yahoo, iCloud)
# - OpenAI API key (shopping-agent)
```

### 3. Quick Fix Deployment

If services crashed due to errors, deploy with these immediate fixes:

```bash
cd /Users/matthanson/Zer0_Inbox/backend/services

# Redeploy with health check improvements
for service in email smart-replies shopping-agent; do
  cd $service
  gcloud run deploy ${service}-service \
    --source . \
    --region us-central1 \
    --platform managed \
    --allow-unauthenticated \
    --min-instances 1 \
    --max-instances 10 \
    --memory 512Mi \
    --cpu 1 \
    --timeout 60s
  cd ..
done
```

---

## Phase 1: Enhanced Health Checks (Immediate)

### Problem
Current health checks only verify the service is running, not that dependencies are healthy.

### Solution: Comprehensive Health Checks

<details>
<summary><b>Email Service Enhanced Health Check</b></summary>

```javascript
// File: /Users/matthanson/Zer0_Inbox/backend/services/email/server.js

// Add detailed health check endpoint
app.get('/health', async (req, res) => {
  const health = {
    status: 'healthy',
    service: 'email-service',
    timestamp: new Date().toISOString(),
    checks: {}
  };

  // Check Gmail credentials
  try {
    const gmailService = require('./routes/gmail');
    if (gmailService.checkAuth) {
      health.checks.gmail = await gmailService.checkAuth();
    } else {
      health.checks.gmail = { status: 'unknown' };
    }
  } catch (e) {
    health.checks.gmail = { status: 'error', error: e.message };
    health.status = 'degraded';
  }

  // Check Outlook credentials
  try {
    const outlookService = require('./routes/outlook');
    if (outlookService.checkAuth) {
      health.checks.outlook = await outlookService.checkAuth();
    } else {
      health.checks.outlook = { status: 'unknown' };
    }
  } catch (e) {
    health.checks.outlook = { status: 'error', error: e.message };
    health.status = 'degraded';
  }

  // Memory check
  const memUsage = process.memoryUsage();
  health.checks.memory = {
    heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024) + 'MB',
    heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024) + 'MB',
    rss: Math.round(memUsage.rss / 1024 / 1024) + 'MB'
  };

  // Uptime
  health.uptime = Math.floor(process.uptime());

  const statusCode = health.status === 'healthy' ? 200 : 503;
  res.status(statusCode).json(health);
});

// Add liveness check for k8s/Cloud Run
app.get('/health/liveness', (req, res) => {
  res.status(200).json({ alive: true });
});

// Add readiness check
app.get('/health/readiness', async (req, res) => {
  // Check if service can handle requests
  try {
    // Quick dependency check (timeout 2s)
    const canHandleRequests = await checkReadiness();
    if (canHandleRequests) {
      res.status(200).json({ ready: true });
    } else {
      res.status(503).json({ ready: false, reason: 'dependencies unavailable' });
    }
  } catch (e) {
    res.status(503).json({ ready: false, error: e.message });
  }
});

async function checkReadiness() {
  // Add quick checks here (e.g., database connection, critical APIs)
  return true; // Implement actual checks
}
```

</details>

<details>
<summary><b>Smart Replies Enhanced Health Check</b></summary>

```javascript
// File: /Users/matthanson/Zer0_Inbox/backend/services/smart-replies/server.js

app.get('/health', async (req, res) => {
  const health = {
    status: 'healthy',
    service: 'smart-replies',
    timestamp: new Date().toISOString(),
    checks: {}
  };

  // Check Vertex AI connection
  try {
    // Test Vertex AI with a minimal request (with timeout)
    const testPromise = vertex_ai.getGenerativeModel({
      model: 'gemini-1.5-flash'
    });

    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Vertex AI connection timeout')), 3000)
    );

    await Promise.race([testPromise, timeoutPromise]);

    health.checks.vertexAI = {
      status: 'connected',
      model: 'gemini-1.5-flash',
      project: process.env.GOOGLE_CLOUD_PROJECT
    };
  } catch (e) {
    health.checks.vertexAI = {
      status: 'error',
      error: e.message,
      hasFallback: true
    };
    health.status = 'degraded'; // Can still work with mock replies
  }

  // Memory check
  const memUsage = process.memoryUsage();
  health.checks.memory = {
    heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024) + 'MB',
    heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024) + 'MB'
  };

  health.uptime = Math.floor(process.uptime());

  const statusCode = health.status === 'healthy' ? 200 : 503;
  res.status(statusCode).json(health);
});

// Add liveness and readiness checks
app.get('/health/liveness', (req, res) => {
  res.status(200).json({ alive: true });
});

app.get('/health/readiness', (req, res) => {
  // Service is ready as long as it can fall back to mock replies
  res.status(200).json({ ready: true });
});
```

</details>

<details>
<summary><b>Shopping Agent Enhanced Health Check</b></summary>

```javascript
// File: /Users/matthanson/Zer0_Inbox/backend/services/shopping-agent/server.js

app.get('/health', async (req, res) => {
  const health = {
    status: 'healthy',
    service: 'shopping-agent',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    checks: {}
  };

  // Check OpenAI API key
  health.checks.openai = {
    apiKeyConfigured: !!process.env.OPENAI_API_KEY,
    status: process.env.OPENAI_API_KEY ? 'configured' : 'missing'
  };

  if (!process.env.OPENAI_API_KEY) {
    health.status = 'degraded';
    health.checks.openai.warning = 'OpenAI API key not configured';
  }

  // Test OpenAI connection (with timeout)
  if (process.env.OPENAI_API_KEY) {
    try {
      const testPromise = fetch('https://api.openai.com/v1/models', {
        headers: {
          'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`
        },
        signal: AbortSignal.timeout(3000)
      });

      const response = await testPromise;
      health.checks.openai.connectionStatus = response.ok ? 'connected' : 'error';

      if (!response.ok) {
        health.status = 'degraded';
        health.checks.openai.error = `HTTP ${response.status}`;
      }
    } catch (e) {
      health.checks.openai.connectionStatus = 'timeout_or_error';
      health.checks.openai.error = e.message;
      health.status = 'degraded';
    }
  }

  // Memory check
  const memUsage = process.memoryUsage();
  health.checks.memory = {
    heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024) + 'MB',
    heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024) + 'MB'
  };

  health.uptime = Math.floor(process.uptime());
  health.env = process.env.NODE_ENV;

  const statusCode = health.status === 'healthy' ? 200 : 503;
  res.status(statusCode).json(health);
});

// Add liveness and readiness
app.get('/health/liveness', (req, res) => {
  res.status(200).json({ alive: true });
});

app.get('/health/readiness', (req, res) => {
  const ready = !!process.env.OPENAI_API_KEY;
  res.status(ready ? 200 : 503).json({ ready });
});
```

</details>

---

## Phase 2: Circuit Breaker Pattern (Within 24 Hours)

### Problem
When external APIs (Vertex AI, OpenAI, Gmail) fail, services keep trying and crash.

### Solution: Implement Circuit Breaker

<details>
<summary><b>Circuit Breaker Implementation</b></summary>

```javascript
// File: /Users/matthanson/Zer0_Inbox/backend/shared/circuit-breaker.js

class CircuitBreaker {
  constructor(options = {}) {
    this.failureThreshold = options.failureThreshold || 5;
    this.successThreshold = options.successThreshold || 2;
    this.timeout = options.timeout || 60000; // 60 seconds
    this.fallback = options.fallback || (() => { throw new Error('Circuit open'); });

    this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
    this.failureCount = 0;
    this.successCount = 0;
    this.nextAttempt = Date.now();
  }

  async execute(fn) {
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        console.log('Circuit breaker OPEN, using fallback');
        return this.fallback();
      }
      // Try half-open
      this.state = 'HALF_OPEN';
      console.log('Circuit breaker entering HALF_OPEN state');
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  onSuccess() {
    this.failureCount = 0;

    if (this.state === 'HALF_OPEN') {
      this.successCount++;
      if (this.successCount >= this.successThreshold) {
        console.log('Circuit breaker CLOSED (recovered)');
        this.state = 'CLOSED';
        this.successCount = 0;
      }
    }
  }

  onFailure() {
    this.failureCount++;
    this.successCount = 0;

    if (this.failureCount >= this.failureThreshold) {
      console.log('Circuit breaker OPEN (too many failures)');
      this.state = 'OPEN';
      this.nextAttempt = Date.now() + this.timeout;
    }
  }

  getState() {
    return {
      state: this.state,
      failureCount: this.failureCount,
      successCount: this.successCount,
      nextAttempt: new Date(this.nextAttempt).toISOString()
    };
  }
}

module.exports = CircuitBreaker;
```

**Usage in Smart Replies Service:**

```javascript
// File: /Users/matthanson/Zer0_Inbox/backend/services/smart-replies/server.js

const CircuitBreaker = require('./shared/circuit-breaker');

// Create circuit breaker for Vertex AI
const vertexAIBreaker = new CircuitBreaker({
  failureThreshold: 3,
  successThreshold: 2,
  timeout: 30000, // 30 seconds
  fallback: () => {
    // Return mock replies when circuit is open
    return {
      replies: [
        "Thanks for reaching out! I'll review this and get back to you soon.",
        "Got it, thanks! I'll take a look.",
        "Thanks - will do!"
      ],
      source: 'fallback_circuit_open'
    };
  }
});

// Wrap Vertex AI calls with circuit breaker
app.post('/api/smart-replies', async (req, res) => {
  try {
    const { email, threadContext, userTone } = req.body;

    if (!email || !email.subject) {
      return res.status(400).json({ error: 'Email data required' });
    }

    // Use circuit breaker
    const result = await vertexAIBreaker.execute(async () => {
      const prompt = buildSmartReplyPrompt(email, threadContext, userTone);
      const startTime = Date.now();

      const response = await generativeModel.generateContent(prompt);
      const latency = Date.now() - startTime;
      const text = response.response.text();

      let replies = [];
      try {
        replies = JSON.parse(text);
      } catch (e) {
        replies = text
          .split('\n')
          .filter(line => line.trim().length > 0 && line.trim().length < 200)
          .slice(0, 3);
      }

      return { replies, latency, source: 'vertex_ai' };
    });

    res.json({
      replies: result.replies.slice(0, 3),
      metadata: {
        latency: result.latency || 0,
        model: 'gemini-1.5-flash',
        source: result.source,
        circuitBreakerState: vertexAIBreaker.getState()
      }
    });

  } catch (error) {
    logger.error('Error generating smart replies', {
      error: error.message
    });
    res.status(500).json({ error: 'Failed to generate smart replies' });
  }
});

// Add circuit breaker status endpoint
app.get('/circuit-breaker/status', (req, res) => {
  res.json({
    vertexAI: vertexAIBreaker.getState()
  });
});
```

</details>

---

## Phase 3: Rate Limiting & Retry Logic (Within 48 Hours)

### Problem
Services can exhaust API quotas or overwhelm external services.

### Solution: Implement Rate Limiting and Exponential Backoff

<details>
<summary><b>Rate Limiter Implementation</b></summary>

```javascript
// File: /Users/matthanson/Zer0_Inbox/backend/shared/rate-limiter.js

class RateLimiter {
  constructor(maxRequests, windowMs) {
    this.maxRequests = maxRequests;
    this.windowMs = windowMs;
    this.requests = [];
  }

  async acquire() {
    const now = Date.now();

    // Remove old requests outside the window
    this.requests = this.requests.filter(time => now - time < this.windowMs);

    if (this.requests.length >= this.maxRequests) {
      const oldestRequest = this.requests[0];
      const waitTime = this.windowMs - (now - oldestRequest);

      console.log(`Rate limit reached, waiting ${waitTime}ms`);
      await new Promise(resolve => setTimeout(resolve, waitTime));

      // Retry after waiting
      return this.acquire();
    }

    this.requests.push(now);
    return true;
  }

  getStatus() {
    const now = Date.now();
    const activeRequests = this.requests.filter(time => now - time < this.windowMs);

    return {
      limit: this.maxRequests,
      window: this.windowMs,
      current: activeRequests.length,
      available: this.maxRequests - activeRequests.length
    };
  }
}

module.exports = RateLimiter;
```

**Usage Example:**

```javascript
const RateLimiter = require('./shared/rate-limiter');

// OpenAI: 60 requests per minute (tier 1)
const openAILimiter = new RateLimiter(60, 60000);

// Vertex AI: 300 requests per minute
const vertexAILimiter = new RateLimiter(300, 60000);

// Before making API call
await openAILimiter.acquire();
const result = await callOpenAI(...);
```

</details>

<details>
<summary><b>Exponential Backoff with Jitter</b></summary>

```javascript
// File: /Users/matthanson/Zer0_Inbox/backend/shared/retry.js

async function retryWithBackoff(fn, options = {}) {
  const {
    maxRetries = 3,
    initialDelay = 1000,
    maxDelay = 30000,
    backoffMultiplier = 2,
    jitter = true
  } = options;

  let lastError;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      if (attempt === maxRetries) {
        throw error;
      }

      // Calculate delay with exponential backoff
      let delay = Math.min(
        initialDelay * Math.pow(backoffMultiplier, attempt),
        maxDelay
      );

      // Add jitter to prevent thundering herd
      if (jitter) {
        delay = delay * (0.5 + Math.random() * 0.5);
      }

      console.log(`Retry attempt ${attempt + 1}/${maxRetries} after ${Math.round(delay)}ms`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw lastError;
}

module.exports = { retryWithBackoff };
```

**Usage:**

```javascript
const { retryWithBackoff } = require('./shared/retry');

const result = await retryWithBackoff(
  async () => await callExternalAPI(),
  {
    maxRetries: 3,
    initialDelay: 1000,
    maxDelay: 10000
  }
);
```

</details>

---

## Phase 4: Connection Pooling (Within 1 Week)

### Problem
Creating new connections for every API call is slow and wasteful.

### Solution: Implement Connection Pooling

<details>
<summary><b>HTTP Agent Pooling</b></summary>

```javascript
// File: /Users/matthanson/Zer0_Inbox/backend/shared/http-pool.js

const http = require('http');
const https = require('https');

// Create reusable HTTPS agent with connection pooling
const httpsAgent = new https.Agent({
  keepAlive: true,
  keepAliveMsecs: 30000,
  maxSockets: 50,
  maxFreeSockets: 10,
  timeout: 30000,
  freeSocketTimeout: 4000
});

const httpAgent = new http.Agent({
  keepAlive: true,
  keepAliveMsecs: 30000,
  maxSockets: 50,
  maxFreeSockets: 10,
  timeout: 30000,
  freeSocketTimeout: 4000
});

module.exports = {
  httpsAgent,
  httpAgent
};
```

**Usage in Services:**

```javascript
// When making fetch requests
const { httpsAgent } = require('./shared/http-pool');

const response = await fetch('https://api.openai.com/v1/...', {
  agent: httpsAgent,
  headers: { ... }
});
```

</details>

---

## Phase 5: Monitoring & Alerting (Within 1 Week)

### Problem
No visibility into service health or failures until users report issues.

### Solution: Implement Comprehensive Monitoring

<details>
<summary><b>Structured Logging with Context</b></summary>

```javascript
// File: /Users/matthanson/Zer0_Inbox/backend/shared/monitoring.js

const winston = require('winston');

class ServiceMonitor {
  constructor(serviceName) {
    this.serviceName = serviceName;
    this.metrics = {
      requests: 0,
      errors: 0,
      latencies: [],
      apiCalls: new Map() // Track external API call counts
    };

    this.logger = winston.createLogger({
      level: process.env.LOG_LEVEL || 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
      ),
      defaultMeta: {
        service: serviceName,
        environment: process.env.NODE_ENV
      },
      transports: [
        new winston.transports.Console()
      ]
    });
  }

  recordRequest(endpoint, latency, success) {
    this.metrics.requests++;
    this.metrics.latencies.push(latency);

    if (!success) {
      this.metrics.errors++;
    }

    // Keep only last 1000 latencies
    if (this.metrics.latencies.length > 1000) {
      this.metrics.latencies.shift();
    }

    this.logger.info('Request completed', {
      endpoint,
      latency,
      success,
      errorRate: (this.metrics.errors / this.metrics.requests * 100).toFixed(2) + '%'
    });
  }

  recordAPICall(apiName, success) {
    if (!this.metrics.apiCalls.has(apiName)) {
      this.metrics.apiCalls.set(apiName, { calls: 0, errors: 0 });
    }

    const stats = this.metrics.apiCalls.get(apiName);
    stats.calls++;
    if (!success) stats.errors++;

    if (stats.errors / stats.calls > 0.1) {
      this.logger.warn(`High error rate for ${apiName}`, {
        api: apiName,
        errorRate: (stats.errors / stats.calls * 100).toFixed(2) + '%',
        totalCalls: stats.calls
      });
    }
  }

  getMetrics() {
    const sorted = [...this.metrics.latencies].sort((a, b) => a - b);
    const p50 = sorted[Math.floor(sorted.length * 0.5)] || 0;
    const p95 = sorted[Math.floor(sorted.length * 0.95)] || 0;
    const p99 = sorted[Math.floor(sorted.length * 0.99)] || 0;

    return {
      service: this.serviceName,
      requests: this.metrics.requests,
      errors: this.metrics.errors,
      errorRate: (this.metrics.errors / this.metrics.requests * 100).toFixed(2) + '%',
      latency: {
        p50,
        p95,
        p99,
        avg: sorted.reduce((a, b) => a + b, 0) / sorted.length || 0
      },
      apiCalls: Object.fromEntries(this.metrics.apiCalls)
    };
  }

  reset() {
    this.metrics = {
      requests: 0,
      errors: 0,
      latencies: [],
      apiCalls: new Map()
    };
  }
}

module.exports = ServiceMonitor;
```

**Add Metrics Endpoint:**

```javascript
const ServiceMonitor = require('./shared/monitoring');
const monitor = new ServiceMonitor('email-service');

// Add metrics endpoint
app.get('/metrics', (req, res) => {
  res.json(monitor.getMetrics());
});

// Use in request handling
app.use((req, res, next) => {
  const start = Date.now();

  res.on('finish', () => {
    const latency = Date.now() - start;
    const success = res.statusCode < 400;
    monitor.recordRequest(req.path, latency, success);
  });

  next();
});
```

</details>

---

## Phase 6: Cloud Run Specific Improvements

### Problem
Cloud Run services can cold start, scale to zero, or run out of resources.

### Solution: Optimize Cloud Run Configuration

<details>
<summary><b>Dockerfile Optimizations</b></summary>

```dockerfile
# Use smaller base image
FROM node:20-alpine

# Install production dependencies only
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy app files
COPY . .

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:' + (process.env.PORT || 8080) + '/health', (r) => { process.exit(r.statusCode === 200 ? 0 : 1); })"

# Run as non-root
USER node

# Start app
CMD ["node", "server.js"]
```

</details>

<details>
<summary><b>Deployment Configuration</b></summary>

```bash
# deploy.sh - Improved deployment script

SERVICE_NAME="email-service"
REGION="us-central1"
PROJECT_ID="gen-lang-client-0622702687"

gcloud run deploy $SERVICE_NAME \
  --source . \
  --region $REGION \
  --platform managed \
  --project $PROJECT_ID \
  --allow-unauthenticated \
  \
  --min-instances 1 \
  --max-instances 10 \
  --concurrency 80 \
  \
  --memory 512Mi \
  --cpu 1 \
  --cpu-boost \
  \
  --timeout 300s \
  --startup-cpu-boost \
  \
  --set-env-vars "NODE_ENV=production" \
  --set-env-vars "LOG_LEVEL=info" \
  \
  --cpu-throttling \
  --execution-environment gen2 \
  \
  --no-traffic \
  --tag "v$(date +%Y%m%d-%H%M%S)"

# Test new revision before promoting
NEW_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format="value(status.traffic[0].url)")
curl -f $NEW_URL/health || exit 1

# Promote to 100% traffic
gcloud run services update-traffic $SERVICE_NAME --region $REGION --to-latest
```

</details>

---

## Phase 7: Graceful Degradation

### Problem
Services fail completely instead of providing limited functionality.

### Solution: Implement Feature Flags and Fallbacks

<details>
<summary><b>Feature Flag System</b></summary>

```javascript
// File: /Users/matthanson/Zer0_Inbox/backend/shared/feature-flags.js

class FeatureFlags {
  constructor() {
    this.flags = {
      // Email service features
      'email.gmail': process.env.FEATURE_GMAIL !== 'false',
      'email.outlook': process.env.FEATURE_OUTLOOK !== 'false',
      'email.yahoo': process.env.FEATURE_YAHOO !== 'false',

      // Smart replies features
      'smart-replies.ai': process.env.FEATURE_AI_REPLIES !== 'false',
      'smart-replies.mock': process.env.FEATURE_MOCK_REPLIES !== 'false',

      // Shopping agent features
      'shopping.openai': process.env.FEATURE_OPENAI !== 'false',
      'shopping.fallback': process.env.FEATURE_FALLBACK !== 'false'
    };
  }

  isEnabled(flagName) {
    return this.flags[flagName] === true;
  }

  disable(flagName) {
    this.flags[flagName] = false;
    console.log(`Feature flag ${flagName} disabled`);
  }

  enable(flagName) {
    this.flags[flagName] = true;
    console.log(`Feature flag ${flagName} enabled`);
  }

  getAll() {
    return { ...this.flags };
  }
}

const flags = new FeatureFlags();
module.exports = flags;
```

**Usage:**

```javascript
const featureFlags = require('./shared/feature-flags');

app.post('/api/smart-replies', async (req, res) => {
  let replies;

  if (featureFlags.isEnabled('smart-replies.ai')) {
    try {
      replies = await generateAIReplies(req.body);
    } catch (e) {
      // Disable AI temporarily if it keeps failing
      featureFlags.disable('smart-replies.ai');
      replies = getMockReplies(req.body);
    }
  } else if (featureFlags.isEnabled('smart-replies.mock')) {
    replies = getMockReplies(req.body);
  } else {
    return res.status(503).json({ error: 'Smart replies unavailable' });
  }

  res.json({ replies });
});
```

</details>

---

## Summary of Improvements

| Improvement | Priority | Impact | Effort |
|-------------|----------|--------|--------|
| Enhanced Health Checks | 🔴 Critical | High | Low |
| Circuit Breaker Pattern | 🔴 Critical | High | Medium |
| Rate Limiting | 🟡 High | Medium | Low |
| Retry with Backoff | 🟡 High | Medium | Low |
| Connection Pooling | 🟡 High | Medium | Medium |
| Monitoring & Metrics | 🟡 High | High | Medium |
| Cloud Run Optimization | 🟢 Medium | Medium | Low |
| Feature Flags | 🟢 Medium | Medium | Low |

---

## Implementation Roadmap

### Week 1 (Immediate)
- ✅ Restart services
- ✅ Verify credentials
- ✅ Deploy enhanced health checks
- ✅ Implement basic circuit breakers

### Week 2
- ✅ Add rate limiting
- ✅ Implement retry logic
- ✅ Add monitoring endpoints
- ✅ Optimize Cloud Run config

### Week 3
- ✅ Add connection pooling
- ✅ Implement feature flags
- ✅ Set up alerting
- ✅ Load testing

### Week 4
- ✅ Review and refine
- ✅ Documentation
- ✅ Team training
- ✅ Post-mortem analysis

---

## Testing the Improvements

```bash
# Test health endpoints
curl https://your-service.run.app/health | jq
curl https://your-service.run.app/health/liveness
curl https://your-service.run.app/health/readiness

# Test metrics
curl https://your-service.run.app/metrics | jq

# Test circuit breaker
curl https://your-service.run.app/circuit-breaker/status | jq

# Load test (use hey or ab)
hey -n 1000 -c 10 https://your-service.run.app/api/endpoint
```

---

## Monitoring Dashboard

Create a simple monitoring dashboard to track service health:

```bash
# File: /Users/matthanson/Zer0_Inbox/backend/dashboard/service-health.html
# Add health monitoring dashboard with auto-refresh
```

---

**Next Steps**: Review this document and let me know which improvements you want to implement first. I recommend starting with Phase 1 (health checks) immediately.
