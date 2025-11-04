/**
 * Redis Distributed Cache
 * Phase 6.2: Replace in-memory LRU cache with Redis for distributed caching
 *
 * Features:
 * - Redis connection with automatic reconnection
 * - Same interface as in-memory cache for backward compatibility
 * - TTL support for different cache types
 * - Health monitoring and metrics
 * - Automatic fallback to in-memory cache on Redis failure
 */

const logger = require('./shared/config/logger');
const { _caches: inMemoryCaches } = require('./performance-cache');

// Redis configuration
const REDIS_CONFIG = {
  enabled: process.env.REDIS_ENABLED === 'true',
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  password: process.env.REDIS_PASSWORD || undefined,
  db: parseInt(process.env.REDIS_DB || '0'),
  keyPrefix: process.env.REDIS_KEY_PREFIX || 'classifier:',
  connectTimeout: 10000, // 10 seconds
  commandTimeout: 5000,  // 5 seconds
  retryStrategy: {
    maxAttempts: 3,
    initialDelay: 1000,
    maxDelay: 5000
  }
};

// TTL configuration (in seconds)
const TTL_CONFIG = {
  intent: 3600,      // 1 hour - intent classifications are stable
  action: 1800,      // 30 minutes - actions may change with context
  entity: 3600,      // 1 hour - entities are stable
  reply: 1800,       // 30 minutes - replies may change with context
  ml_reply: 3600     // 1 hour - ML replies are expensive to generate
};

// Redis client state
let redisClient = null;
let isConnected = false;
let connectionAttempts = 0;
let lastConnectionError = null;

// Metrics
const metrics = {
  hits: 0,
  misses: 0,
  errors: 0,
  setOperations: 0,
  getOperations: 0,
  connectionAttempts: 0,
  lastError: null,
  lastErrorTime: null
};

/**
 * Create Redis client (lazy initialization)
 */
async function createRedisClient() {
  if (!REDIS_CONFIG.enabled) {
    logger.info('Redis caching disabled, using in-memory cache');
    return null;
  }

  try {
    // Dynamically import redis (only if enabled)
    const redis = await import('redis');

    const client = redis.createClient({
      socket: {
        host: REDIS_CONFIG.host,
        port: REDIS_CONFIG.port,
        connectTimeout: REDIS_CONFIG.connectTimeout,
        reconnectStrategy: (retries) => {
          if (retries > REDIS_CONFIG.retryStrategy.maxAttempts) {
            logger.error('Redis max reconnection attempts reached');
            return new Error('Max reconnection attempts reached');
          }
          const delay = Math.min(
            REDIS_CONFIG.retryStrategy.initialDelay * Math.pow(2, retries),
            REDIS_CONFIG.retryStrategy.maxDelay
          );
          logger.warn(`Redis reconnecting in ${delay}ms (attempt ${retries})`);
          return delay;
        }
      },
      password: REDIS_CONFIG.password,
      database: REDIS_CONFIG.db,
      commandsQueueMaxLength: 1000
    });

    // Event handlers
    client.on('connect', () => {
      logger.info('Redis client connecting');
      metrics.connectionAttempts++;
    });

    client.on('ready', () => {
      logger.info('Redis client ready', {
        host: REDIS_CONFIG.host,
        port: REDIS_CONFIG.port,
        db: REDIS_CONFIG.db
      });
      isConnected = true;
      connectionAttempts = 0;
      lastConnectionError = null;
    });

    client.on('error', (err) => {
      logger.error('Redis client error', { error: err.message });
      isConnected = false;
      lastConnectionError = err.message;
      metrics.lastError = err.message;
      metrics.lastErrorTime = Date.now();
      metrics.errors++;
    });

    client.on('reconnecting', () => {
      logger.warn('Redis client reconnecting');
      isConnected = false;
      connectionAttempts++;
    });

    client.on('end', () => {
      logger.info('Redis client connection closed');
      isConnected = false;
    });

    // Connect
    await client.connect();

    return client;

  } catch (error) {
    logger.error('Failed to create Redis client', { error: error.message });
    lastConnectionError = error.message;
    metrics.errors++;
    return null;
  }
}

/**
 * Get or create Redis client
 */
async function getRedisClient() {
  if (!REDIS_CONFIG.enabled) {
    return null;
  }

  if (redisClient && isConnected) {
    return redisClient;
  }

  if (!redisClient) {
    redisClient = await createRedisClient();
  }

  return isConnected ? redisClient : null;
}

/**
 * Build cache key with prefix
 */
function buildKey(cacheType, key) {
  return `${REDIS_CONFIG.keyPrefix}${cacheType}:${key}`;
}

/**
 * Get value from Redis or fallback to in-memory
 */
async function get(cacheType, key) {
  metrics.getOperations++;

  try {
    const client = await getRedisClient();

    if (!client) {
      // Fallback to in-memory cache
      const inMemoryCache = inMemoryCaches[cacheType];
      const result = inMemoryCache ? inMemoryCache.get(key) : null;
      if (result) metrics.hits++;
      else metrics.misses++;
      return result;
    }

    const redisKey = buildKey(cacheType, key);
    const value = await client.get(redisKey);

    if (value) {
      metrics.hits++;
      try {
        return JSON.parse(value);
      } catch (e) {
        logger.warn('Failed to parse cached value', { key: redisKey });
        metrics.misses++;
        return null;
      }
    }

    metrics.misses++;
    return null;

  } catch (error) {
    logger.error('Redis get error', { error: error.message, cacheType, key });
    metrics.errors++;

    // Fallback to in-memory
    const inMemoryCache = inMemoryCaches[cacheType];
    const result = inMemoryCache ? inMemoryCache.get(key) : null;
    if (result) metrics.hits++;
    else metrics.misses++;
    return result;
  }
}

/**
 * Set value in Redis and in-memory cache
 */
async function set(cacheType, key, value, customTTL = null) {
  metrics.setOperations++;

  try {
    const client = await getRedisClient();
    const ttl = customTTL || TTL_CONFIG[cacheType] || 1800;

    // Always set in memory for fast access
    const inMemoryCache = inMemoryCaches[cacheType];
    if (inMemoryCache) {
      inMemoryCache.set(key, value);
    }

    if (!client) {
      // Only in-memory cache available
      return true;
    }

    const redisKey = buildKey(cacheType, key);
    const serialized = JSON.stringify(value);

    await client.setEx(redisKey, ttl, serialized);

    return true;

  } catch (error) {
    logger.error('Redis set error', { error: error.message, cacheType, key });
    metrics.errors++;

    // Still succeed with in-memory cache
    return true;
  }
}

/**
 * Delete value from Redis and in-memory cache
 */
async function del(cacheType, key) {
  try {
    const client = await getRedisClient();

    // Delete from in-memory cache
    const inMemoryCache = inMemoryCaches[cacheType];
    if (inMemoryCache && inMemoryCache.cache) {
      inMemoryCache.cache.delete(key);
    }

    if (!client) {
      return true;
    }

    const redisKey = buildKey(cacheType, key);
    await client.del(redisKey);

    return true;

  } catch (error) {
    logger.error('Redis del error', { error: error.message, cacheType, key });
    metrics.errors++;
    return false;
  }
}

/**
 * Clear all caches for a specific type
 */
async function clearCacheType(cacheType) {
  try {
    const client = await getRedisClient();

    // Clear in-memory cache
    const inMemoryCache = inMemoryCaches[cacheType];
    if (inMemoryCache) {
      inMemoryCache.clear();
    }

    if (!client) {
      return true;
    }

    // Clear Redis keys matching pattern
    const pattern = buildKey(cacheType, '*');
    const keys = await client.keys(pattern);

    if (keys.length > 0) {
      await client.del(keys);
      logger.info(`Cleared ${keys.length} keys from Redis cache type: ${cacheType}`);
    }

    return true;

  } catch (error) {
    logger.error('Redis clear error', { error: error.message, cacheType });
    metrics.errors++;
    return false;
  }
}

/**
 * Clear all caches
 */
async function clearAllCaches() {
  const types = ['intent', 'action', 'entity', 'reply', 'ml_reply'];

  for (const type of types) {
    await clearCacheType(type);
  }

  logger.info('All caches cleared (Redis + in-memory)');
}

/**
 * Get cache statistics
 */
async function getCacheStats() {
  const total = metrics.hits + metrics.misses;
  const hitRate = total > 0 ? ((metrics.hits / total) * 100).toFixed(2) : '0.00';

  const stats = {
    redis: {
      enabled: REDIS_CONFIG.enabled,
      connected: isConnected,
      host: REDIS_CONFIG.host,
      port: REDIS_CONFIG.port,
      db: REDIS_CONFIG.db,
      lastError: lastConnectionError,
      connectionAttempts: metrics.connectionAttempts
    },
    metrics: {
      hits: metrics.hits,
      misses: metrics.misses,
      errors: metrics.errors,
      hitRate: hitRate + '%',
      getOperations: metrics.getOperations,
      setOperations: metrics.setOperations,
      errorRate: metrics.getOperations > 0
        ? ((metrics.errors / metrics.getOperations) * 100).toFixed(2) + '%'
        : '0.00%'
    },
    ttl: TTL_CONFIG
  };

  // Add Redis-specific stats if connected
  if (isConnected && redisClient) {
    try {
      const info = await redisClient.info('stats');
      const keyspaceInfo = await redisClient.info('keyspace');

      stats.redis.info = {
        totalConnectionsReceived: extractInfoValue(info, 'total_connections_received'),
        totalCommandsProcessed: extractInfoValue(info, 'total_commands_processed'),
        keyspace: keyspaceInfo
      };
    } catch (error) {
      logger.warn('Failed to get Redis info', { error: error.message });
    }
  }

  return stats;
}

/**
 * Extract value from Redis INFO output
 */
function extractInfoValue(infoString, key) {
  const match = infoString.match(new RegExp(`${key}:([^\r\n]+)`));
  return match ? match[1] : 'unknown';
}

/**
 * Health check for Redis
 */
async function healthCheck() {
  const health = {
    status: 'healthy',
    redis: {
      enabled: REDIS_CONFIG.enabled,
      connected: isConnected,
      healthy: false
    },
    fallback: {
      available: true,
      type: 'in-memory'
    },
    issues: []
  };

  if (!REDIS_CONFIG.enabled) {
    health.status = 'healthy';
    health.redis.healthy = false;
    health.issues.push('Redis disabled, using in-memory cache');
    return health;
  }

  try {
    const client = await getRedisClient();

    if (!client || !isConnected) {
      health.status = 'degraded';
      health.redis.healthy = false;
      health.issues.push('Redis not connected, using in-memory fallback');
      if (lastConnectionError) {
        health.issues.push(`Last error: ${lastConnectionError}`);
      }
      return health;
    }

    // Test Redis with ping
    const startTime = Date.now();
    const pong = await client.ping();
    const latency = Date.now() - startTime;

    if (pong === 'PONG') {
      health.redis.healthy = true;
      health.redis.latency = latency + 'ms';

      if (latency > 100) {
        health.status = 'degraded';
        health.issues.push(`High Redis latency: ${latency}ms`);
      }
    } else {
      health.status = 'degraded';
      health.redis.healthy = false;
      health.issues.push('Redis ping failed');
    }

  } catch (error) {
    health.status = 'degraded';
    health.redis.healthy = false;
    health.issues.push(`Redis health check error: ${error.message}`);
  }

  return health;
}

/**
 * Disconnect Redis client
 */
async function disconnect() {
  if (redisClient && isConnected) {
    try {
      await redisClient.quit();
      logger.info('Redis client disconnected');
    } catch (error) {
      logger.error('Error disconnecting Redis client', { error: error.message });
    } finally {
      redisClient = null;
      isConnected = false;
    }
  }
}

/**
 * Wrapper functions matching performance-cache.js interface
 */

async function getCachedIntent(cacheKey, computeFn) {
  const cached = await get('intent', cacheKey);
  if (cached) return cached;

  const result = computeFn();
  await set('intent', cacheKey, result);
  return result;
}

async function getCachedActions(cacheKey, computeFn) {
  const cached = await get('action', cacheKey);
  if (cached) return cached;

  const result = computeFn();
  await set('action', cacheKey, result);
  return result;
}

async function getCachedEntities(cacheKey, computeFn) {
  const cached = await get('entity', cacheKey);
  if (cached) return cached;

  const result = computeFn();
  await set('entity', cacheKey, result);
  return result;
}

async function getCachedReplies(cacheKey, computeFn) {
  const cached = await get('reply', cacheKey);
  if (cached) return cached;

  const result = computeFn();
  await set('reply', cacheKey, result);
  return result;
}

// Export
module.exports = {
  // Main cache functions
  get,
  set,
  del,
  clearCacheType,
  clearAllCaches,

  // Wrapper functions (same interface as performance-cache.js)
  getCachedIntent,
  getCachedActions,
  getCachedEntities,
  getCachedReplies,

  // Monitoring
  getCacheStats,
  healthCheck,

  // Lifecycle
  disconnect,

  // Export for testing
  _internal: {
    getRedisClient,
    buildKey,
    REDIS_CONFIG,
    TTL_CONFIG,
    metrics
  }
};
