/**
 * Request Logger Middleware - IP Theft Protection
 *
 * Provides comprehensive logging to detect and prevent unauthorized access:
 * - IP address tracking (both direct and proxied)
 * - User agent logging (detect scrapers/bots)
 * - Request rate monitoring per IP
 * - Suspicious activity pattern detection
 * - Forensic data for security analysis
 */

const winston = require('winston');

// Rate limiting tracker: IP -> {count, firstSeen, lastSeen, requests: []}
const requestTracker = new Map();

// Suspicious patterns to detect
const SUSPICIOUS_PATTERNS = {
    // High request rate (requests per minute)
    highFrequency: 30,
    // Burst detection (requests in 10 seconds)
    burstThreshold: 10,
    burstWindow: 10000, // ms
    // Known scraper/bot patterns in User-Agent
    botPatterns: [
        /curl/i,
        /wget/i,
        /python-requests/i,
        /scrapy/i,
        /bot/i,
        /crawler/i,
        /spider/i,
        /scraper/i
    ],
    // Cleanup interval (clear old tracking data)
    cleanupInterval: 3600000 // 1 hour
};

// Create logger with file output for forensics
const securityLogger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({
            filename: '/tmp/security-requests.log',
            maxsize: 10485760, // 10MB
            maxFiles: 5
        })
    ]
});

// Cleanup old tracking data periodically
setInterval(() => {
    const now = Date.now();
    const oneHourAgo = now - SUSPICIOUS_PATTERNS.cleanupInterval;

    for (const [ip, data] of requestTracker.entries()) {
        if (data.lastSeen < oneHourAgo) {
            requestTracker.delete(ip);
        }
    }
}, SUSPICIOUS_PATTERNS.cleanupInterval);

/**
 * Extract real IP address from request
 */
function getRealIP(req) {
    // Check X-Forwarded-For header (common in proxied requests)
    const forwarded = req.headers['x-forwarded-for'];
    if (forwarded) {
        // Take first IP if multiple
        return forwarded.split(',')[0].trim();
    }

    // Check other proxy headers
    return req.headers['x-real-ip'] ||
           req.connection?.remoteAddress ||
           req.socket?.remoteAddress ||
           req.ip ||
           'unknown';
}

/**
 * Detect if User-Agent matches known scraper patterns
 */
function isSuspiciousUserAgent(userAgent) {
    if (!userAgent) return true; // No user agent is suspicious

    return SUSPICIOUS_PATTERNS.botPatterns.some(pattern =>
        pattern.test(userAgent)
    );
}

/**
 * Track request rate and detect suspicious patterns
 */
function trackRequest(ip, userAgent, path) {
    const now = Date.now();

    if (!requestTracker.has(ip)) {
        requestTracker.set(ip, {
            count: 0,
            firstSeen: now,
            lastSeen: now,
            requests: []
        });
    }

    const tracker = requestTracker.get(ip);
    tracker.count++;
    tracker.lastSeen = now;
    tracker.requests.push({ timestamp: now, path, userAgent });

    // Keep only last 100 requests per IP for analysis
    if (tracker.requests.length > 100) {
        tracker.requests.shift();
    }

    // Analyze patterns
    const analysis = {
        totalRequests: tracker.count,
        durationMinutes: (now - tracker.firstSeen) / 60000,
        recentRequests: tracker.requests.length
    };

    // Calculate request rate
    analysis.requestsPerMinute = analysis.durationMinutes > 0
        ? analysis.totalRequests / analysis.durationMinutes
        : 0;

    // Check for burst activity (many requests in short time)
    const recentBurst = tracker.requests.filter(
        req => (now - req.timestamp) < SUSPICIOUS_PATTERNS.burstWindow
    ).length;
    analysis.burstDetected = recentBurst >= SUSPICIOUS_PATTERNS.burstThreshold;

    // Check for high frequency
    analysis.highFrequency = analysis.requestsPerMinute > SUSPICIOUS_PATTERNS.highFrequency;

    // Overall suspicion score
    analysis.suspicious = analysis.burstDetected ||
                          analysis.highFrequency ||
                          isSuspiciousUserAgent(userAgent);

    return analysis;
}

/**
 * Request Logger Middleware
 *
 * Usage in Express app:
 *   const requestLogger = require('./shared/middleware/request-logger');
 *   app.use(requestLogger('service-name'));
 */
function createRequestLogger(serviceName) {
    return function requestLoggerMiddleware(req, res, next) {
        const startTime = Date.now();

        // Extract request details
        const ip = getRealIP(req);
        const userAgent = req.headers['user-agent'] || 'none';
        const path = req.path || req.url;
        const method = req.method;

        // Track request and analyze patterns
        const analysis = trackRequest(ip, userAgent, path);

        // Build log entry
        const logEntry = {
            service: serviceName,
            timestamp: new Date().toISOString(),
            method,
            path,
            ip,
            userAgent,
            forwardedFor: req.headers['x-forwarded-for'] || null,
            realIP: req.headers['x-real-ip'] || null,
            analysis: {
                totalRequests: analysis.totalRequests,
                requestsPerMinute: parseFloat(analysis.requestsPerMinute.toFixed(2)),
                burstDetected: analysis.burstDetected,
                highFrequency: analysis.highFrequency,
                suspicious: analysis.suspicious
            }
        };

        // Log to security file
        securityLogger.info(logEntry);

        // If suspicious, log warning to console
        if (analysis.suspicious) {
            console.warn(`⚠️  SUSPICIOUS REQUEST DETECTED on ${serviceName}:`, {
                ip,
                path,
                userAgent: userAgent.substring(0, 100),
                requestsPerMinute: analysis.requestsPerMinute.toFixed(2),
                burst: analysis.burstDetected,
                highFreq: analysis.highFrequency
            });
        }

        // Add request tracking to response
        res.on('finish', () => {
            const duration = Date.now() - startTime;
            securityLogger.info({
                ...logEntry,
                responseStatus: res.statusCode,
                duration: `${duration}ms`
            });
        });

        next();
    };
}

module.exports = createRequestLogger;
module.exports.getRealIP = getRealIP;
module.exports.trackRequest = trackRequest;
