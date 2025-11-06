/**
 * Dashboard Authentication Middleware
 * Protects dashboard routes with session-based authentication
 *
 * SECURITY: Integrated with audit logging (2025-11-06)
 * All authentication events are tracked for compliance
 */

const crypto = require('crypto');
const auditLogger = require('./audit-logger');

// In-memory session store (for development)
// In production, use Redis or Firestore for distributed sessions
const sessions = new Map();

// Access codes (in production, move to Google Secret Manager or Firestore)
// SECURITY: Rotated on 2025-11-06 - Old codes: ZERO2024, ZEROADMIN
// Store these in 1Password and share securely
const ACCESS_CODES = {
  'ZERO451296': { level: 'user', description: 'Beta tester access', createdAt: '2025-11-06' },
  'ADMIN820876': { level: 'admin', description: 'Admin access with audit logging', createdAt: '2025-11-06' }
};

// Session configuration
const SESSION_DURATION = 24 * 60 * 60 * 1000; // 24 hours
const COOKIE_NAME = 'zero_session';

/**
 * Generate secure session ID
 */
function generateSessionId() {
  return crypto.randomBytes(32).toString('hex');
}

/**
 * Create new session
 */
function createSession(accessLevel = 'user', email = null, req = null) {
  const sessionId = generateSessionId();
  const session = {
    id: sessionId,
    accessLevel,
    email,
    createdAt: Date.now(),
    expiresAt: Date.now() + SESSION_DURATION,
    lastActivity: Date.now()
  };

  sessions.set(sessionId, session);

  // Audit log: Session created
  auditLogger.auditSessionCreated(sessionId, accessLevel, email, req);

  return session;
}

/**
 * Get session by ID
 */
function getSession(sessionId, req = null) {
  const session = sessions.get(sessionId);

  if (!session) {
    return null;
  }

  // Check if session expired
  if (Date.now() > session.expiresAt) {
    sessions.delete(sessionId);

    // Audit log: Session expired
    auditLogger.auditSessionExpired(sessionId, req);

    return null;
  }

  // Update last activity
  session.lastActivity = Date.now();
  return session;
}

/**
 * Delete session
 */
function deleteSession(sessionId) {
  sessions.delete(sessionId);
}

/**
 * Clean up expired sessions (run periodically)
 */
function cleanupSessions() {
  const now = Date.now();
  let cleanedCount = 0;

  for (const [sessionId, session] of sessions.entries()) {
    if (now > session.expiresAt) {
      sessions.delete(sessionId);
      cleanedCount++;

      // Audit log: Session expired during cleanup
      auditLogger.auditSessionExpired(sessionId, null);
    }
  }

  if (cleanedCount > 0) {
    console.log(`🧹 Cleaned up ${cleanedCount} expired session(s)`);
  }
}

// Run cleanup every 15 minutes
setInterval(cleanupSessions, 15 * 60 * 1000);

/**
 * Extract session ID from cookie
 */
function getSessionIdFromCookie(req) {
  const cookies = req.headers.cookie?.split(';').map(c => c.trim()) || [];
  const sessionCookie = cookies.find(c => c.startsWith(`${COOKIE_NAME}=`));

  if (!sessionCookie) {
    return null;
  }

  return sessionCookie.split('=')[1];
}

/**
 * Verify access code
 */
function verifyAccessCode(code) {
  return ACCESS_CODES[code] || null;
}

/**
 * Authentication middleware
 * Protects routes requiring authentication
 */
function requireAuth(req, res, next) {
  const sessionId = getSessionIdFromCookie(req);

  if (!sessionId) {
    // Audit log: No session cookie
    auditLogger.logAuditEvent('auth.no_session', {
      path: req.path,
      method: req.method
    }, req);

    return res.status(401).sendFile(__dirname + '/splash.html');
  }

  const session = getSession(sessionId, req);

  if (!session) {
    // Audit log: Invalid or expired session
    auditLogger.logAuditEvent('auth.invalid_session', {
      sessionId: sessionId.substring(0, 8) + '...',
      path: req.path,
      method: req.method
    }, req);

    // Clear invalid cookie
    res.setHeader('Set-Cookie', `${COOKIE_NAME}=; Path=/; Max-Age=0; HttpOnly; SameSite=Strict`);
    return res.status(401).sendFile(__dirname + '/splash.html');
  }

  // Attach session to request
  req.session = session;
  next();
}

/**
 * Admin-only middleware
 * Requires admin access level
 */
function requireAdmin(req, res, next) {
  if (!req.session || req.session.accessLevel !== 'admin') {
    // Audit log: Admin access denied
    auditLogger.auditAccessDenied('admin_endpoint', 'Insufficient privileges', req);

    return res.status(403).json({
      error: 'Admin access required',
      message: 'This tool requires administrator privileges'
    });
  }

  // Audit log: Admin action (record which endpoint was accessed)
  auditLogger.auditAdminAction('admin_endpoint_access', {
    path: req.path,
    method: req.method
  }, req);

  next();
}

/**
 * Optional auth middleware
 * Attaches session if present but doesn't block
 */
function optionalAuth(req, res, next) {
  const sessionId = getSessionIdFromCookie(req);

  if (sessionId) {
    const session = getSession(sessionId, req);
    if (session) {
      req.session = session;
    }
  }

  next();
}

module.exports = {
  requireAuth,
  requireAdmin,
  optionalAuth,
  createSession,
  getSession,
  deleteSession,
  verifyAccessCode,
  COOKIE_NAME,
  SESSION_DURATION,
  ACCESS_CODES
};
