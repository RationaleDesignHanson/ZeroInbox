/**
 * Simple In-Memory Cache for Action Registry
 * - TTL-based expiration
 * - Per-user caching
 * - Automatic cleanup
 */

class ActionRegistryCache {
  constructor(defaultTTL = 24 * 60 * 60 * 1000) { // 24 hours default
    this.cache = new Map();
    this.defaultTTL = defaultTTL;

    // Clean up expired entries every hour
    setInterval(() => this.cleanup(), 60 * 60 * 1000);
  }

  /**
   * Generate cache key
   */
  getKey(userId, mode = 'all', days = 30) {
    return `${userId}:${mode}:${days}`;
  }

  /**
   * Get cached registry
   */
  get(userId, mode, days) {
    const key = this.getKey(userId, mode, days);
    const entry = this.cache.get(key);

    if (!entry) {
      return null;
    }

    // Check if expired
    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return null;
    }

    return entry.data;
  }

  /**
   * Set cached registry
   */
  set(userId, mode, days, data, ttl = null) {
    const key = this.getKey(userId, mode, days);
    const expiresAt = Date.now() + (ttl || this.defaultTTL);

    this.cache.set(key, {
      data,
      expiresAt,
      cachedAt: new Date().toISOString()
    });
  }

  /**
   * Invalidate user's cache
   */
  invalidate(userId) {
    const keysToDelete = [];

    for (const key of this.cache.keys()) {
      if (key.startsWith(`${userId}:`)) {
        keysToDelete.push(key);
      }
    }

    keysToDelete.forEach(key => this.cache.delete(key));

    return keysToDelete.length;
  }

  /**
   * Clear all cache
   */
  clear() {
    const size = this.cache.size;
    this.cache.clear();
    return size;
  }

  /**
   * Clean up expired entries
   */
  cleanup() {
    const now = Date.now();
    const keysToDelete = [];

    for (const [key, entry] of this.cache.entries()) {
      if (now > entry.expiresAt) {
        keysToDelete.push(key);
      }
    }

    keysToDelete.forEach(key => this.cache.delete(key));

    if (keysToDelete.length > 0) {
      console.log(`🧹 Cache cleanup: Removed ${keysToDelete.length} expired entries`);
    }

    return keysToDelete.length;
  }

  /**
   * Get cache statistics
   */
  getStats() {
    const now = Date.now();
    let activeEntries = 0;
    let expiredEntries = 0;

    for (const entry of this.cache.values()) {
      if (now > entry.expiresAt) {
        expiredEntries++;
      } else {
        activeEntries++;
      }
    }

    return {
      totalEntries: this.cache.size,
      activeEntries,
      expiredEntries,
      defaultTTL: this.defaultTTL,
      memoryUsage: process.memoryUsage().heapUsed
    };
  }
}

module.exports = ActionRegistryCache;
