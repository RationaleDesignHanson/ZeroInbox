/**
 * Health Check
 * Phase 5.2: Production health monitoring endpoint
 * Phase 6: Added Redis and ML monitoring
 */

const { monitor } = require('./performance-monitor');
const { getAllCacheStats } = require('./performance-cache');
const logger = require('./shared/config/logger');

// Phase 6: Redis and ML imports
const redisCache = require('./redis-cache');
const { getMLConfig, getMLCacheStats } = require('./ml-smart-reply-generator');

/**
 * Get comprehensive health status
 */
async function getHealthStatus() {
  try {
    const performanceHealth = monitor.checkHealth();
    const performanceSummary = monitor.getSummary();
    const cacheStats = getAllCacheStats();

    // Phase 6: Redis health check
    const redisHealth = await redisCache.healthCheck();
    const redisCacheStats = await redisCache.getCacheStats();

    // Phase 6: ML configuration
    const mlConfig = getMLConfig();
    const mlCacheStats = getMLCacheStats();

    const health = {
      status: performanceHealth.status,
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: {
        used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024) + 'MB',
        total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024) + 'MB',
        rss: Math.round(process.memoryUsage().rss / 1024 / 1024) + 'MB'
      },
      performance: {
        classifications: performanceSummary.classifications,
        throughput: performanceSummary.throughput,
        avgTime: performanceSummary.avgTime,
        p95Time: performanceSummary.p95Time,
        errorRate: performanceSummary.errorRate
      },
      cache: {
        inMemory: {
          intent: {
            hitRate: cacheStats.intent.hitRate,
            size: cacheStats.intent.size
          },
          action: {
            hitRate: cacheStats.action.hitRate,
            size: cacheStats.action.size
          },
          entity: {
            hitRate: cacheStats.entity.hitRate,
            size: cacheStats.entity.size
          },
          reply: {
            hitRate: cacheStats.reply.hitRate,
            size: cacheStats.reply.size
          }
        },
        redis: {
          enabled: redisCacheStats.redis.enabled,
          connected: redisCacheStats.redis.connected,
          healthy: redisHealth.redis.healthy,
          hitRate: redisCacheStats.metrics.hitRate,
          errorRate: redisCacheStats.metrics.errorRate,
          operations: {
            get: redisCacheStats.metrics.getOperations,
            set: redisCacheStats.metrics.setOperations
          }
        }
      },
      ml: {
        enabled: mlConfig.enabled,
        provider: mlConfig.provider,
        model: mlConfig.model,
        hasApiKey: mlConfig.hasApiKey,
        fallbackEnabled: mlConfig.fallbackEnabled,
        cache: {
          size: mlCacheStats.size,
          maxSize: mlCacheStats.maxSize,
          avgAge: mlCacheStats.avgAge + 's'
        }
      },
      issues: [...performanceHealth.issues]
    };

    // Add Redis issues
    if (redisHealth.issues.length > 0) {
      health.issues.push(...redisHealth.issues);
      if (redisHealth.status === 'degraded' && health.status === 'healthy') {
        health.status = 'degraded';
      }
    }

    // Add ML warnings
    if (mlConfig.enabled && !mlConfig.hasApiKey) {
      health.issues.push('ML replies enabled but API key not configured');
      health.status = 'degraded';
    }

    return health;
  } catch (error) {
    logger.error('Health check error', { error: error.message });
    return {
      status: 'error',
      error: error.message,
      timestamp: new Date().toISOString()
    };
  }
}

/**
 * Simple liveness check (for k8s/docker)
 */
function getLivenessStatus() {
  return {
    status: 'alive',
    timestamp: new Date().toISOString()
  };
}

/**
 * Readiness check (for k8s/docker)
 */
async function getReadinessStatus() {
  const health = await getHealthStatus();

  return {
    status: health.status !== 'unhealthy' ? 'ready' : 'not_ready',
    timestamp: new Date().toISOString()
  };
}

module.exports = {
  getHealthStatus,
  getLivenessStatus,
  getReadinessStatus
};
