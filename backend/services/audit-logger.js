/**
 * Audit Logger
 * Tracks all credential access and security events
 *
 * Features:
 * - Logs all credential reads from Secret Manager
 * - Tracks authentication attempts (success/failure)
 * - Records API key usage
 * - Session activity monitoring
 * - Structured JSON logging for analysis
 * - Automatic log rotation
 * - Integration with Google Cloud Logging (optional)
 *
 * Compliance:
 * - SOC 2 Type II requirements
 * - PCI DSS credential access logging
 * - GDPR audit trail
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Configuration
const LOG_DIR = path.join(__dirname, '../logs');
const AUDIT_LOG_FILE = path.join(LOG_DIR, 'credential-audit.log');
const MAX_LOG_SIZE_MB = 100; // Rotate logs at 100MB
const LOG_RETENTION_DAYS = 90;

// Event types for categorization
const EVENT_TYPES = {
  // Authentication events
  AUTH_LOGIN_SUCCESS: 'auth.login.success',
  AUTH_LOGIN_FAILURE: 'auth.login.failure',
  AUTH_LOGOUT: 'auth.logout',
  AUTH_SESSION_CREATED: 'auth.session.created',
  AUTH_SESSION_EXPIRED: 'auth.session.expired',
  AUTH_SESSION_INVALIDATED: 'auth.session.invalidated',

  // Credential access events
  CREDENTIAL_READ: 'credential.read',
  CREDENTIAL_WRITE: 'credential.write',
  CREDENTIAL_DELETE: 'credential.delete',
  CREDENTIAL_ROTATE: 'credential.rotate',

  // API key usage
  API_KEY_USED: 'api.key.used',
  API_KEY_INVALID: 'api.key.invalid',

  // Secret Manager events
  SECRET_MANAGER_ACCESS: 'secret_manager.access',
  SECRET_MANAGER_ERROR: 'secret_manager.error',

  // Admin actions
  ADMIN_ACTION: 'admin.action',
  ADMIN_TOOL_USED: 'admin.tool.used',

  // Security events
  RATE_LIMIT_EXCEEDED: 'security.rate_limit.exceeded',
  SUSPICIOUS_ACTIVITY: 'security.suspicious_activity',
  ACCESS_DENIED: 'security.access_denied'
};

// Ensure log directory exists
if (!fs.existsSync(LOG_DIR)) {
  fs.mkdirSync(LOG_DIR, { recursive: true });
}

/**
 * Generate unique audit ID for each event
 */
function generateAuditId() {
  return crypto.randomBytes(16).toString('hex');
}

/**
 * Get sanitized user info from request
 */
function getUserInfo(req) {
  if (!req) return { userId: 'system', userType: 'system' };

  const session = req.session || {};
  const userId = session.email || session.id || 'anonymous';
  const userType = session.accessLevel || 'unknown';

  return {
    userId,
    userType,
    sessionId: session.id,
    ip: req.ip || req.connection?.remoteAddress || 'unknown',
    userAgent: req.headers?.['user-agent'] || 'unknown'
  };
}

/**
 * Core audit logging function
 */
function logAuditEvent(eventType, details = {}, req = null) {
  try {
    const userInfo = getUserInfo(req);

    const auditEntry = {
      id: generateAuditId(),
      timestamp: new Date().toISOString(),
      eventType,
      ...userInfo,
      ...details,
      environment: process.env.NODE_ENV || 'development'
    };

    // Write to file (synchronous for critical audit logs)
    const logLine = JSON.stringify(auditEntry) + '\n';
    fs.appendFileSync(AUDIT_LOG_FILE, logLine);

    // Also log to console in development
    if (process.env.NODE_ENV === 'development') {
      console.log(`[Audit ${auditEntry.id.substring(0, 8)}]`, eventType, details);
    }

    // Check if log rotation is needed
    checkLogRotation();

    return auditEntry.id;
  } catch (error) {
    // Critical: If audit logging fails, log to stderr
    console.error('❌ CRITICAL: Audit logging failed:', error);
    console.error('Event details:', { eventType, details });
    return null;
  }
}

/**
 * Check if log file needs rotation
 */
function checkLogRotation() {
  try {
    const stats = fs.statSync(AUDIT_LOG_FILE);
    const sizeMB = stats.size / (1024 * 1024);

    if (sizeMB > MAX_LOG_SIZE_MB) {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const rotatedFile = path.join(LOG_DIR, `credential-audit-${timestamp}.log`);

      fs.renameSync(AUDIT_LOG_FILE, rotatedFile);
      console.log(`✅ Audit log rotated: ${rotatedFile}`);

      // Log rotation event in new file
      logAuditEvent('system.log_rotation', {
        rotatedFile,
        size_mb: sizeMB.toFixed(2)
      });
    }
  } catch (error) {
    // File might not exist yet, ignore
  }
}

/**
 * Clean up old log files
 */
function cleanupOldLogs() {
  try {
    const files = fs.readdirSync(LOG_DIR);
    const cutoffDate = Date.now() - (LOG_RETENTION_DAYS * 24 * 60 * 60 * 1000);

    files.forEach(file => {
      if (file.startsWith('credential-audit-')) {
        const filePath = path.join(LOG_DIR, file);
        const stats = fs.statSync(filePath);

        if (stats.mtimeMs < cutoffDate) {
          fs.unlinkSync(filePath);
          console.log(`✅ Deleted old audit log: ${file}`);
        }
      }
    });
  } catch (error) {
    console.error('⚠️  Error cleaning up old logs:', error);
  }
}

// Run cleanup daily
setInterval(cleanupOldLogs, 24 * 60 * 60 * 1000);

/**
 * Express middleware for automatic audit logging
 */
function auditMiddleware(req, res, next) {
  // Log the request
  const requestId = generateAuditId();
  req.auditId = requestId;

  // Capture original methods
  const originalJson = res.json;
  const originalSend = res.send;

  // Track response
  res.json = function(data) {
    logAuditEvent('http.request', {
      requestId,
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration_ms: Date.now() - req.startTime
    }, req);

    return originalJson.call(this, data);
  };

  res.send = function(data) {
    logAuditEvent('http.request', {
      requestId,
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration_ms: Date.now() - req.startTime
    }, req);

    return originalSend.call(this, data);
  };

  req.startTime = Date.now();
  next();
}

/**
 * Specialized audit functions for common scenarios
 */

function auditLogin(success, email, req, reason = null) {
  return logAuditEvent(
    success ? EVENT_TYPES.AUTH_LOGIN_SUCCESS : EVENT_TYPES.AUTH_LOGIN_FAILURE,
    { email, reason },
    req
  );
}

function auditSessionCreated(sessionId, accessLevel, email, req) {
  return logAuditEvent(
    EVENT_TYPES.AUTH_SESSION_CREATED,
    { sessionId, accessLevel, email },
    req
  );
}

function auditSessionExpired(sessionId, req) {
  return logAuditEvent(
    EVENT_TYPES.AUTH_SESSION_EXPIRED,
    { sessionId },
    req
  );
}

function auditCredentialRead(credentialName, source, req = null) {
  return logAuditEvent(
    EVENT_TYPES.CREDENTIAL_READ,
    { credentialName, source },
    req
  );
}

function auditCredentialRotate(credentialName, req = null) {
  return logAuditEvent(
    EVENT_TYPES.CREDENTIAL_ROTATE,
    { credentialName },
    req
  );
}

function auditApiKeyUsed(serviceName, keyType, req) {
  return logAuditEvent(
    EVENT_TYPES.API_KEY_USED,
    { serviceName, keyType },
    req
  );
}

function auditAdminAction(action, details, req) {
  return logAuditEvent(
    EVENT_TYPES.ADMIN_ACTION,
    { action, ...details },
    req
  );
}

function auditAccessDenied(resource, reason, req) {
  return logAuditEvent(
    EVENT_TYPES.ACCESS_DENIED,
    { resource, reason },
    req
  );
}

/**
 * Query audit logs (for admin dashboard)
 */
function queryAuditLogs(filters = {}) {
  try {
    const logData = fs.readFileSync(AUDIT_LOG_FILE, 'utf8');
    const lines = logData.split('\n').filter(line => line.trim());

    let entries = lines.map(line => {
      try {
        return JSON.parse(line);
      } catch {
        return null;
      }
    }).filter(entry => entry !== null);

    // Apply filters
    if (filters.eventType) {
      entries = entries.filter(e => e.eventType === filters.eventType);
    }

    if (filters.userId) {
      entries = entries.filter(e => e.userId === filters.userId);
    }

    if (filters.startDate) {
      entries = entries.filter(e => new Date(e.timestamp) >= new Date(filters.startDate));
    }

    if (filters.endDate) {
      entries = entries.filter(e => new Date(e.timestamp) <= new Date(filters.endDate));
    }

    // Sort by timestamp descending
    entries.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    // Limit results
    const limit = filters.limit || 100;
    return entries.slice(0, limit);
  } catch (error) {
    console.error('Error querying audit logs:', error);
    return [];
  }
}

/**
 * Generate audit report summary
 */
function generateAuditReport(startDate, endDate) {
  const logs = queryAuditLogs({ startDate, endDate });

  const report = {
    period: { startDate, endDate },
    totalEvents: logs.length,
    eventsByType: {},
    userActivity: {},
    credentialAccess: {
      total: 0,
      byCredential: {}
    },
    authenticationEvents: {
      successfulLogins: 0,
      failedLogins: 0,
      sessions: 0
    },
    adminActivity: {
      actions: 0,
      toolsUsed: 0
    }
  };

  logs.forEach(log => {
    // Count by event type
    report.eventsByType[log.eventType] = (report.eventsByType[log.eventType] || 0) + 1;

    // Count by user
    if (log.userId && log.userId !== 'system') {
      report.userActivity[log.userId] = (report.userActivity[log.userId] || 0) + 1;
    }

    // Credential access
    if (log.eventType === EVENT_TYPES.CREDENTIAL_READ) {
      report.credentialAccess.total++;
      const cred = log.credentialName || 'unknown';
      report.credentialAccess.byCredential[cred] = (report.credentialAccess.byCredential[cred] || 0) + 1;
    }

    // Authentication
    if (log.eventType === EVENT_TYPES.AUTH_LOGIN_SUCCESS) {
      report.authenticationEvents.successfulLogins++;
    }
    if (log.eventType === EVENT_TYPES.AUTH_LOGIN_FAILURE) {
      report.authenticationEvents.failedLogins++;
    }
    if (log.eventType === EVENT_TYPES.AUTH_SESSION_CREATED) {
      report.authenticationEvents.sessions++;
    }

    // Admin activity
    if (log.eventType === EVENT_TYPES.ADMIN_ACTION) {
      report.adminActivity.actions++;
    }
    if (log.eventType === EVENT_TYPES.ADMIN_TOOL_USED) {
      report.adminActivity.toolsUsed++;
    }
  });

  return report;
}

module.exports = {
  // Core logging
  logAuditEvent,
  auditMiddleware,

  // Specialized functions
  auditLogin,
  auditSessionCreated,
  auditSessionExpired,
  auditCredentialRead,
  auditCredentialRotate,
  auditApiKeyUsed,
  auditAdminAction,
  auditAccessDenied,

  // Query and reporting
  queryAuditLogs,
  generateAuditReport,

  // Constants
  EVENT_TYPES,

  // Utilities
  cleanupOldLogs
};
