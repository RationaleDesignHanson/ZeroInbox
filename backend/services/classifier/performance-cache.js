/**
 * Performance Cache
 * Phase 4.1: LRU cache for frequently accessed data
 *
 * Purpose: Reduce redundant computations and lookups
 */

const logger = require('./shared/config/logger');

class LRUCache {
  constructor(maxSize = 1000) {
    this.maxSize = maxSize;
    this.cache = new Map();
    this.hits = 0;
    this.misses = 0;
  }

  get(key) {
    if (this.cache.has(key)) {
      // Move to end (most recently used)
      const value = this.cache.get(key);
      this.cache.delete(key);
      this.cache.set(key, value);
      this.hits++;
      return value;
    }
    this.misses++;
    return null;
  }

  set(key, value) {
    // Remove if already exists
    if (this.cache.has(key)) {
      this.cache.delete(key);
    }

    // Add to end
    this.cache.set(key, value);

    // Evict oldest if over size
    if (this.cache.size > this.maxSize) {
      const firstKey = this.cache.keys().next().value;
      this.cache.delete(firstKey);
    }
  }

  clear() {
    this.cache.clear();
    this.hits = 0;
    this.misses = 0;
  }

  getStats() {
    const total = this.hits + this.misses;
    return {
      size: this.cache.size,
      maxSize: this.maxSize,
      hits: this.hits,
      misses: this.misses,
      hitRate: total > 0 ? (this.hits / total * 100).toFixed(2) + '%' : '0%'
    };
  }
}

// Create caches for different data types
const intentCache = new LRUCache(500);      // Intent classifications
const actionCache = new LRUCache(1000);     // Action suggestions
const entityCache = new LRUCache(500);      // Entity extractions
const replyCache = new LRUCache(200);       // Smart replies

/**
 * Get or compute intent classification
 */
function getCachedIntent(cacheKey, computeFn) {
  const cached = intentCache.get(cacheKey);
  if (cached) {
    return cached;
  }

  const result = computeFn();
  intentCache.set(cacheKey, result);
  return result;
}

/**
 * Get or compute actions
 */
function getCachedActions(cacheKey, computeFn) {
  const cached = actionCache.get(cacheKey);
  if (cached) {
    return cached;
  }

  const result = computeFn();
  actionCache.set(cacheKey, result);
  return result;
}

/**
 * Get or compute entities
 */
function getCachedEntities(cacheKey, computeFn) {
  const cached = entityCache.get(cacheKey);
  if (cached) {
    return cached;
  }

  const result = computeFn();
  entityCache.set(cacheKey, result);
  return result;
}

/**
 * Get or compute smart replies
 */
function getCachedReplies(cacheKey, computeFn) {
  const cached = replyCache.get(cacheKey);
  if (cached) {
    return cached;
  }

  const result = computeFn();
  replyCache.set(cacheKey, result);
  return result;
}

/**
 * Generate cache key from email
 */
function generateEmailCacheKey(email) {
  const subject = (email.subject || '').toLowerCase().trim();
  const from = (email.from || '').toLowerCase().trim();
  const bodySnippet = (email.body || email.snippet || '').substring(0, 200).toLowerCase().trim();

  // Simple hash for cache key
  return `${subject}_${from}_${bodySnippet}`.substring(0, 100);
}

/**
 * Get all cache statistics
 */
function getAllCacheStats() {
  return {
    intent: intentCache.getStats(),
    action: actionCache.getStats(),
    entity: entityCache.getStats(),
    reply: replyCache.getStats(),
    timestamp: new Date().toISOString()
  };
}

/**
 * Clear all caches
 */
function clearAllCaches() {
  intentCache.clear();
  actionCache.clear();
  entityCache.clear();
  replyCache.clear();
  logger.info('All caches cleared');
}

/**
 * Log cache stats periodically
 */
let statsInterval = null;

function startCacheStatsLogging(intervalMs = 300000) { // 5 minutes
  if (statsInterval) {
    clearInterval(statsInterval);
  }

  statsInterval = setInterval(() => {
    const stats = getAllCacheStats();
    logger.info('Cache statistics', stats);
  }, intervalMs);
}

function stopCacheStatsLogging() {
  if (statsInterval) {
    clearInterval(statsInterval);
    statsInterval = null;
  }
}

module.exports = {
  getCachedIntent,
  getCachedActions,
  getCachedEntities,
  getCachedReplies,
  generateEmailCacheKey,
  getAllCacheStats,
  clearAllCaches,
  startCacheStatsLogging,
  stopCacheStatsLogging,
  // Export for testing
  _caches: {
    intent: intentCache,
    action: actionCache,
    entity: entityCache,
    reply: replyCache
  }
};
