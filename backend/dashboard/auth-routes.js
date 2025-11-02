/**
 * Dashboard Authentication Routes
 * Handles login, logout, and access code verification
 */

const express = require('express');
const router = express.Router();
const { createSession, deleteSession, verifyAccessCode, getSession, COOKIE_NAME, SESSION_DURATION } = require('./auth-middleware');

/**
 * POST /auth/login
 * Login with access code
 */
router.post('/login', (req, res) => {
  try {
    const { accessCode, email } = req.body;

    if (!accessCode) {
      return res.status(400).json({
        success: false,
        error: 'Access code is required'
      });
    }

    // Verify access code
    const codeData = verifyAccessCode(accessCode);

    if (!codeData) {
      return res.status(401).json({
        success: false,
        error: 'Invalid access code'
      });
    }

    // Create session
    const session = createSession(codeData.level, email);

    // Set secure cookie
    const cookieOptions = [
      `${COOKIE_NAME}=${session.id}`,
      'Path=/',
      `Max-Age=${SESSION_DURATION / 1000}`, // Convert to seconds
      'HttpOnly', // Prevent XSS
      'SameSite=Strict', // CSRF protection
      // 'Secure' // Enable in production with HTTPS
    ];

    res.setHeader('Set-Cookie', cookieOptions.join('; '));

    res.json({
      success: true,
      accessLevel: session.accessLevel,
      message: 'Authentication successful'
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * POST /auth/logout
 * Logout and clear session
 */
router.post('/logout', (req, res) => {
  try {
    const cookies = req.headers.cookie?.split(';').map(c => c.trim()) || [];
    const sessionCookie = cookies.find(c => c.startsWith(`${COOKIE_NAME}=`));

    if (sessionCookie) {
      const sessionId = sessionCookie.split('=')[1];
      deleteSession(sessionId);
    }

    // Clear cookie
    res.setHeader('Set-Cookie', `${COOKIE_NAME}=; Path=/; Max-Age=0; HttpOnly; SameSite=Strict`);

    res.json({
      success: true,
      message: 'Logged out successfully'
    });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * GET /auth/status
 * Check authentication status
 */
router.get('/status', (req, res) => {
  const cookies = req.headers.cookie?.split(';').map(c => c.trim()) || [];
  const sessionCookie = cookies.find(c => c.startsWith(`${COOKIE_NAME}=`));

  if (!sessionCookie) {
    return res.json({
      authenticated: false
    });
  }

  const sessionId = sessionCookie.split('=')[1];
  const session = getSession(sessionId);

  if (!session) {
    return res.json({
      authenticated: false
    });
  }

  res.json({
    authenticated: true,
    accessLevel: session.accessLevel,
    email: session.email,
    expiresAt: session.expiresAt
  });
});

/**
 * POST /auth/waitlist
 * Add email to waitlist (for future signup feature)
 */
router.post('/waitlist', (req, res) => {
  try {
    const { email, name } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        error: 'Email is required'
      });
    }

    // TODO: Store in Firestore waitlist collection
    console.log('Waitlist signup:', { email, name, timestamp: new Date().toISOString() });

    res.json({
      success: true,
      message: 'Thanks for your interest! You\'ve been added to the waitlist.'
    });

  } catch (error) {
    console.error('Waitlist error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

module.exports = router;
