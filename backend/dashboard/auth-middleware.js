/**
 * Dashboard Authentication Middleware
 * Protects dashboard routes with session-based authentication
 */

const crypto = require('crypto');

// In-memory session store (for development)
// In production, use Redis or Firestore for distributed sessions
const sessions = new Map();

// Access codes (in production, move to Google Secret Manager or Firestore)
const ACCESS_CODES = {
  'ZERO2024': { level: 'user', description: 'Beta tester access' },
  'ZEROADMIN': { level: 'admin', description: 'Admin access' }
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
function createSession(accessLevel = 'user', email = null) {
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
  return session;
}

/**
 * Get session by ID
 */
function getSession(sessionId) {
  const session = sessions.get(sessionId);

  if (!session) {
    return null;
  }

  // Check if session expired
  if (Date.now() > session.expiresAt) {
    sessions.delete(sessionId);
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
  for (const [sessionId, session] of sessions.entries()) {
    if (now > session.expiresAt) {
      sessions.delete(sessionId);
    }
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
    return res.status(401).sendFile(__dirname + '/splash.html');
  }

  const session = getSession(sessionId);

  if (!session) {
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
    return res.status(403).json({
      error: 'Admin access required',
      message: 'This tool requires administrator privileges'
    });
  }
  next();
}

/**
 * Optional auth middleware
 * Attaches session if present but doesn't block
 */
function optionalAuth(req, res, next) {
  const sessionId = getSessionIdFromCookie(req);

  if (sessionId) {
    const session = getSession(sessionId);
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
