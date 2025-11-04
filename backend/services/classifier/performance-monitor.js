/**
 * Performance Monitor
 * Phase 4.2: Track and analyze classification performance
 *
 * Purpose: Identify bottlenecks and monitor system health
 */

const logger = require('./shared/config/logger');

class PerformanceMonitor {
  constructor() {
    this.metrics = {
      // Component timings
      intentClassification: [],
      entityExtraction: [],
      actionSuggestion: [],
      actionPrioritization: [],
      confidenceScoring: [],
      smartReplies: [],
      totalClassification: [],

      // Counts
      classificationsCount: 0,
      errorsCount: 0,

      // Timestamps
      startTime: Date.now(),
      lastReset: Date.now()
    };

    this.maxSamples = 1000; // Keep last 1000 samples
  }

  /**
   * Record a timing metric
   */
  recordTiming(component, durationMs) {
    if (!this.metrics[component]) {
      this.metrics[component] = [];
    }

    this.metrics[component].push(durationMs);

    // Keep only recent samples
    if (this.metrics[component].length > this.maxSamples) {
      this.metrics[component].shift();
    }
  }

  /**
   * Record a classification
   */
  recordClassification(timings) {
    this.metrics.classificationsCount++;

    if (timings.intent) this.recordTiming('intentClassification', timings.intent);
    if (timings.entities) this.recordTiming('entityExtraction', timings.entities);
    if (timings.actions) this.recordTiming('actionSuggestion', timings.actions);
    if (timings.prioritization) this.recordTiming('actionPrioritization', timings.prioritization);
    if (timings.confidence) this.recordTiming('confidenceScoring', timings.confidence);
    if (timings.replies) this.recordTiming('smartReplies', timings.replies);
    if (timings.total) this.recordTiming('totalClassification', timings.total);
  }

  /**
   * Record an error
   */
  recordError() {
    this.metrics.errorsCount++;
  }

  /**
   * Calculate statistics for a metric
   */
  calculateStats(samples) {
    if (!samples || samples.length === 0) {
      return {
        count: 0,
        min: 0,
        max: 0,
        avg: 0,
        p50: 0,
        p95: 0,
        p99: 0
      };
    }

    const sorted = [...samples].sort((a, b) => a - b);
    const count = sorted.length;

    return {
      count,
      min: sorted[0],
      max: sorted[count - 1],
      avg: sorted.reduce((a, b) => a + b, 0) / count,
      p50: sorted[Math.floor(count * 0.50)],
      p95: sorted[Math.floor(count * 0.95)],
      p99: sorted[Math.floor(count * 0.99)]
    };
  }

  /**
   * Get performance report
   */
  getReport() {
    const uptime = Date.now() - this.metrics.startTime;
    const timeSinceReset = Date.now() - this.metrics.lastReset;

    return {
      uptime: Math.floor(uptime / 1000), // seconds
      timeSinceReset: Math.floor(timeSinceReset / 1000), // seconds
      classifications: this.metrics.classificationsCount,
      errors: this.metrics.errorsCount,
      errorRate: this.metrics.classificationsCount > 0
        ? ((this.metrics.errorsCount / this.metrics.classificationsCount) * 100).toFixed(2) + '%'
        : '0%',
      throughput: {
        perSecond: (this.metrics.classificationsCount / (timeSinceReset / 1000)).toFixed(2),
        perMinute: (this.metrics.classificationsCount / (timeSinceReset / 60000)).toFixed(2)
      },
      timings: {
        intentClassification: this.calculateStats(this.metrics.intentClassification),
        entityExtraction: this.calculateStats(this.metrics.entityExtraction),
        actionSuggestion: this.calculateStats(this.metrics.actionSuggestion),
        actionPrioritization: this.calculateStats(this.metrics.actionPrioritization),
        confidenceScoring: this.calculateStats(this.metrics.confidenceScoring),
        smartReplies: this.calculateStats(this.metrics.smartReplies),
        totalClassification: this.calculateStats(this.metrics.totalClassification)
      }
    };
  }

  /**
   * Get summary (for logging)
   */
  getSummary() {
    const report = this.getReport();
    const total = report.timings.totalClassification;

    return {
      classifications: report.classifications,
      throughput: report.throughput.perSecond + '/s',
      avgTime: total.avg ? total.avg.toFixed(1) + 'ms' : '0ms',
      p95Time: total.p95 ? total.p95.toFixed(1) + 'ms' : '0ms',
      errorRate: report.errorRate
    };
  }

  /**
   * Reset metrics
   */
  reset() {
    this.metrics = {
      intentClassification: [],
      entityExtraction: [],
      actionSuggestion: [],
      actionPrioritization: [],
      confidenceScoring: [],
      smartReplies: [],
      totalClassification: [],
      classificationsCount: 0,
      errorsCount: 0,
      startTime: this.metrics.startTime,
      lastReset: Date.now()
    };
    logger.info('Performance metrics reset');
  }

  /**
   * Check if performance is degrading
   */
  checkHealth() {
    const report = this.getReport();
    const total = report.timings.totalClassification;

    const health = {
      status: 'healthy',
      issues: []
    };

    // Check average time
    if (total.avg > 100) {
      health.status = 'degraded';
      health.issues.push(`High average classification time: ${total.avg.toFixed(1)}ms`);
    }

    // Check p95 time
    if (total.p95 > 200) {
      health.status = 'degraded';
      health.issues.push(`High p95 classification time: ${total.p95.toFixed(1)}ms`);
    }

    // Check error rate
    const errorRate = parseFloat(report.errorRate);
    if (errorRate > 5) {
      health.status = 'unhealthy';
      health.issues.push(`High error rate: ${report.errorRate}`);
    }

    // Check if no recent activity
    if (report.timeSinceReset > 600 && report.classifications === 0) {
      health.status = 'idle';
      health.issues.push('No classifications in last 10 minutes');
    }

    return health;
  }
}

// Global monitor instance
const monitor = new PerformanceMonitor();

// Start periodic health logging (every 5 minutes)
let healthCheckInterval = null;

function startHealthChecks(intervalMs = 300000) {
  if (healthCheckInterval) {
    clearInterval(healthCheckInterval);
  }

  healthCheckInterval = setInterval(() => {
    const summary = monitor.getSummary();
    const health = monitor.checkHealth();

    logger.info('Performance summary', { ...summary, healthStatus: health.status });

    if (health.status !== 'healthy') {
      logger.warn('Performance health issues detected', health);
    }
  }, intervalMs);
}

function stopHealthChecks() {
  if (healthCheckInterval) {
    clearInterval(healthCheckInterval);
    healthCheckInterval = null;
  }
}

/**
 * Create a timer utility
 */
function createTimer() {
  const start = Date.now();
  return {
    stop: () => Date.now() - start
  };
}

module.exports = {
  monitor,
  createTimer,
  startHealthChecks,
  stopHealthChecks
};
