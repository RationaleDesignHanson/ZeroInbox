/**
 * Graceful Degradation Layer
 *
 * Provides localStorage caching and fallback mechanisms for when backend services
 * are unavailable (e.g., on mobile devices without VPN access to localhost).
 *
 * Features:
 * - Automatic response caching with TTL
 * - Fallback to cached data when services fail
 * - Cache invalidation strategies
 * - Visual indicators for cached/stale data
 *
 * Usage:
 * Include this script after config.js on any page that needs graceful degradation:
 * <script src="/js/config.js"></script>
 * <script src="/js/graceful-degradation.js"></script>
 */

const GracefulDegradation = {
  // Cache configuration
  cache: {
    prefix: 'zero_cache_',
    ttl: {
      intentTaxonomy: 24 * 60 * 60 * 1000,  // 24 hours (stable data)
      actionCatalog: 24 * 60 * 60 * 1000,    // 24 hours (stable data)
      classification: 60 * 60 * 1000,        // 1 hour (dynamic but can be cached)
      health: 5 * 60 * 1000                  // 5 minutes (should be fresh)
    },
    maxSize: 5 * 1024 * 1024  // 5MB total cache limit
  },

  // Cache statistics
  stats: {
    hits: 0,
    misses: 0,
    errors: 0,
    storageUsed: 0
  },

  /**
   * Initialize graceful degradation
   * - Overrides DashboardConfig.fetch() with caching layer
   * - Displays cache status in console
   */
  init() {
    console.log('[Graceful Degradation] Initializing...');

    // Check if localStorage is available
    if (!this.isStorageAvailable()) {
      console.warn('[Graceful Degradation] localStorage not available - degradation disabled');
      return false;
    }

    // Calculate current storage usage
    this.updateStorageStats();

    // Override the config fetch method
    this.wrapConfigFetch();

    // Add global fetch wrapper for non-config fetches
    this.wrapGlobalFetch();

    console.log(`[Graceful Degradation] Ready (${this.formatBytes(this.stats.storageUsed)} cached)`);

    return true;
  },

  /**
   * Check if localStorage is available and working
   */
  isStorageAvailable() {
    try {
      const test = '__storage_test__';
      localStorage.setItem(test, test);
      localStorage.removeItem(test);
      return true;
    } catch (e) {
      return false;
    }
  },

  /**
   * Update storage usage statistics
   */
  updateStorageStats() {
    let totalSize = 0;
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.startsWith(this.cache.prefix)) {
        totalSize += localStorage.getItem(key).length;
      }
    }
    this.stats.storageUsed = totalSize;
  },

  /**
   * Generate cache key from URL and options
   */
  getCacheKey(url, options = {}) {
    const method = options.method || 'GET';
    const body = options.body ? JSON.stringify(options.body) : '';
    const key = `${method}:${url}:${body}`;
    return this.cache.prefix + btoa(key).substring(0, 100); // Base64 encode, limit length
  },

  /**
   * Determine TTL for a given URL
   */
  getTTL(url) {
    if (url.includes('/intent-taxonomy')) return this.cache.ttl.intentTaxonomy;
    if (url.includes('/actions/catalog') || url.includes('/actions/registry')) return this.cache.ttl.actionCatalog;
    if (url.includes('/classify')) return this.cache.ttl.classification;
    if (url.includes('/health')) return this.cache.ttl.health;
    // Static data files (like corpus) should be cached for 24 hours
    if (url.includes('data/') && url.endsWith('.json')) return 24 * 60 * 60 * 1000;
    return 60 * 60 * 1000; // Default: 1 hour
  },

  /**
   * Get item from cache
   * Returns { data, cached, stale } or null
   */
  getFromCache(cacheKey, ttl) {
    try {
      const item = localStorage.getItem(cacheKey);
      if (!item) return null;

      const cached = JSON.parse(item);
      const age = Date.now() - cached.timestamp;
      const stale = age > ttl;

      this.stats.hits++;

      return {
        data: cached.data,
        cached: true,
        stale,
        age: Math.floor(age / 1000) // seconds
      };
    } catch (error) {
      console.error('[Graceful Degradation] Cache read error:', error);
      return null;
    }
  },

  /**
   * Store item in cache
   */
  setCache(cacheKey, data) {
    try {
      const item = {
        data,
        timestamp: Date.now()
      };

      const serialized = JSON.stringify(item);

      // Check if adding this would exceed size limit
      if (this.stats.storageUsed + serialized.length > this.cache.maxSize) {
        console.warn('[Graceful Degradation] Cache size limit reached, clearing old entries');
        this.clearOldEntries();
      }

      localStorage.setItem(cacheKey, serialized);
      this.updateStorageStats();

      return true;
    } catch (error) {
      console.error('[Graceful Degradation] Cache write error:', error);

      // If QuotaExceededError, try clearing old entries and retry
      if (error.name === 'QuotaExceededError') {
        this.clearOldEntries();
        try {
          localStorage.setItem(cacheKey, JSON.stringify({ data, timestamp: Date.now() }));
          return true;
        } catch (retryError) {
          console.error('[Graceful Degradation] Cache write failed after clearing:', retryError);
        }
      }

      return false;
    }
  },

  /**
   * Clear old cache entries (oldest first)
   */
  clearOldEntries() {
    const entries = [];

    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.startsWith(this.cache.prefix)) {
        try {
          const item = JSON.parse(localStorage.getItem(key));
          entries.push({ key, timestamp: item.timestamp });
        } catch (e) {
          // Invalid entry, add to removal list with old timestamp
          entries.push({ key, timestamp: 0 });
        }
      }
    }

    // Sort by timestamp (oldest first)
    entries.sort((a, b) => a.timestamp - b.timestamp);

    // Remove oldest 30% of entries
    const toRemove = Math.ceil(entries.length * 0.3);
    for (let i = 0; i < toRemove && i < entries.length; i++) {
      localStorage.removeItem(entries[i].key);
    }

    this.updateStorageStats();
    console.log(`[Graceful Degradation] Cleared ${toRemove} old cache entries`);
  },

  /**
   * Wrap DashboardConfig.fetch() with caching layer
   */
  wrapConfigFetch() {
    if (!window.DashboardConfig) {
      console.warn('[Graceful Degradation] DashboardConfig not found, skipping wrapper');
      return;
    }

    const originalFetch = DashboardConfig.fetch.bind(DashboardConfig);

    DashboardConfig.fetch = async (service, endpoint, options = {}) => {
      const url = DashboardConfig.getUrl(service, endpoint, options.params || {});
      const cacheKey = this.getCacheKey(url, options);
      const ttl = this.getTTL(url);

      try {
        // Try to fetch from network
        this.stats.misses++;
        const data = await originalFetch(service, endpoint, options);

        // Cache the successful response
        this.setCache(cacheKey, data);

        return { ...data, _cached: false, _stale: false };
      } catch (error) {
        this.stats.errors++;
        console.warn(`[Graceful Degradation] Network request failed: ${url}`, error.message);

        // Try to get from cache (even if stale)
        const cached = this.getFromCache(cacheKey, ttl);

        if (cached) {
          console.log(`[Graceful Degradation] Using ${cached.stale ? 'stale' : 'fresh'} cache (age: ${cached.age}s)`);
          return { ...cached.data, _cached: true, _stale: cached.stale, _age: cached.age };
        }

        // No cache available, throw original error
        throw error;
      }
    };

    console.log('[Graceful Degradation] DashboardConfig.fetch() wrapped');
  },

  /**
   * Wrap global fetch() with caching layer for non-config requests
   */
  wrapGlobalFetch() {
    const originalFetch = window.fetch;
    const self = this;

    window.fetch = async function(url, options = {}) {
      // Only cache GET requests to our backend services and static data files
      const method = options.method || 'GET';
      const isBackendRequest = typeof url === 'string' && (
        url.includes('localhost:8') ||
        url.includes('localhost:3') ||
        url.includes('.run.app')
      );

      // Also cache static data JSON files (like comprehensive-corpus.json)
      const isStaticData = typeof url === 'string' && (
        url.includes('data/') && url.endsWith('.json')
      );

      if (method === 'GET' && (isBackendRequest || isStaticData)) {
        const cacheKey = self.getCacheKey(url, options);
        const ttl = self.getTTL(url);

        try {
          // Try network first
          self.stats.misses++;
          const response = await originalFetch(url, options);

          // Clone response to cache it
          const clonedResponse = response.clone();

          if (response.ok) {
            try {
              const data = await clonedResponse.json();
              self.setCache(cacheKey, data);
            } catch (e) {
              // Not JSON, skip caching
            }
          }

          return response;
        } catch (error) {
          self.stats.errors++;
          console.warn(`[Graceful Degradation] Network request failed: ${url}`, error.message);

          // Try cache
          const cached = self.getFromCache(cacheKey, ttl);

          if (cached) {
            console.log(`[Graceful Degradation] Using ${cached.stale ? 'stale' : 'fresh'} cache (age: ${cached.age}s)`);

            // Return a fake Response object with cached data
            return new Response(JSON.stringify(cached.data), {
              status: 200,
              statusText: 'OK (Cached)',
              headers: {
                'Content-Type': 'application/json',
                'X-Cached': 'true',
                'X-Cache-Age': cached.age.toString(),
                'X-Cache-Stale': cached.stale.toString()
              }
            });
          }

          // No cache, throw original error
          throw error;
        }
      }

      // Not a GET or not a backend request, use original fetch
      return originalFetch(url, options);
    };

    console.log('[Graceful Degradation] Global fetch() wrapped');
  },

  /**
   * Show cache status in UI (can be called from console or page)
   */
  showStatus() {
    const hitRate = this.stats.hits + this.stats.misses > 0
      ? ((this.stats.hits / (this.stats.hits + this.stats.misses)) * 100).toFixed(1)
      : 0;

    console.table({
      'Cache Hits': this.stats.hits,
      'Cache Misses': this.stats.misses,
      'Errors (Fallback Used)': this.stats.errors,
      'Hit Rate': `${hitRate}%`,
      'Storage Used': this.formatBytes(this.stats.storageUsed),
      'Storage Limit': this.formatBytes(this.cache.maxSize)
    });
  },

  /**
   * Clear all cache
   */
  clearCache() {
    let count = 0;
    for (let i = localStorage.length - 1; i >= 0; i--) {
      const key = localStorage.key(i);
      if (key && key.startsWith(this.cache.prefix)) {
        localStorage.removeItem(key);
        count++;
      }
    }
    this.updateStorageStats();
    console.log(`[Graceful Degradation] Cleared ${count} cache entries`);
    return count;
  },

  /**
   * Format bytes to human-readable string
   */
  formatBytes(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${(bytes / Math.pow(k, i)).toFixed(2)} ${sizes[i]}`;
  },

  /**
   * Add visual indicator to page when using cached data
   * Call this after a request that returned cached data
   */
  showCacheIndicator(message = 'Using cached data - offline mode', stale = false) {
    // Remove existing indicator
    const existing = document.getElementById('graceful-degradation-indicator');
    if (existing) existing.remove();

    // Create new indicator
    const indicator = document.createElement('div');
    indicator.id = 'graceful-degradation-indicator';
    indicator.style.cssText = `
      position: fixed;
      top: 80px;
      right: 20px;
      background: ${stale ? 'rgba(255, 152, 0, 0.95)' : 'rgba(33, 150, 243, 0.95)'};
      color: white;
      padding: 12px 20px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
      z-index: 10000;
      display: flex;
      align-items: center;
      gap: 10px;
      backdrop-filter: blur(10px);
      animation: slideIn 0.3s ease;
    `;

    const icon = stale ? '⚠️' : '📦';
    indicator.innerHTML = `
      <span style="font-size: 18px;">${icon}</span>
      <span>${message}</span>
      <button onclick="this.parentElement.remove()" style="
        background: rgba(255, 255, 255, 0.2);
        border: none;
        color: white;
        padding: 4px 8px;
        border-radius: 4px;
        cursor: pointer;
        font-weight: 600;
        font-size: 12px;
        margin-left: 10px;
      ">✕</button>
    `;

    // Add animation
    const style = document.createElement('style');
    style.textContent = `
      @keyframes slideIn {
        from {
          transform: translateX(400px);
          opacity: 0;
        }
        to {
          transform: translateX(0);
          opacity: 1;
        }
      }
    `;
    document.head.appendChild(style);

    document.body.appendChild(indicator);

    // Auto-hide after 8 seconds
    setTimeout(() => {
      if (indicator.parentElement) {
        indicator.style.animation = 'slideIn 0.3s ease reverse';
        setTimeout(() => indicator.remove(), 300);
      }
    }, 8000);
  }
};

// Auto-initialize on page load
if (typeof window !== 'undefined') {
  window.GracefulDegradation = GracefulDegradation;

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => GracefulDegradation.init());
  } else {
    GracefulDegradation.init();
  }

  // Expose helper functions to console
  window.cacheStatus = () => GracefulDegradation.showStatus();
  window.clearCache = () => GracefulDegradation.clearCache();

  console.log('[Graceful Degradation] Helpers available: cacheStatus(), clearCache()');
}

// Export for modules
if (typeof module !== 'undefined' && module.exports) {
  module.exports = GracefulDegradation;
}
