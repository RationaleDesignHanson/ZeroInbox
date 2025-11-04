/**
 * Dashboard Configuration
 * Central configuration for all dashboard pages
 * Mirrors iOS Constants.swift for 100% backend parity
 */

const DashboardConfig = {
  // Environment (defaults to production for public demos, use ?env=development for localhost testing)
  environment: new URLSearchParams(window.location.search).get('env') === 'development' ? 'development' : 'production',

  // Backend Services - Development (localhost)
  development: {
    gateway: 'http://localhost:3001',
    email: 'http://localhost:8081',
    classifier: 'http://localhost:8082',
    summarization: 'http://localhost:8083',
    shoppingCart: 'http://localhost:8084',
    scheduledPurchase: 'http://localhost:8085',
    smartReplies: 'http://localhost:8086',
    steelAgent: 'http://localhost:8087',
    actions: 'http://localhost:8089',
    analytics: 'http://localhost:8090'
  },

  // Backend Services - Production (Google Cloud Run)
  production: {
    gateway: 'https://emailshortform-gateway-514014482017.us-central1.run.app',
    email: 'https://emailshortform-email-514014482017.us-central1.run.app',
    classifier: 'https://emailshortform-classifier-514014482017.us-central1.run.app',
    summarization: 'https://emailshortform-summarization-514014482017.us-central1.run.app',
    shoppingCart: 'https://shopping-agent-service-514014482017.us-central1.run.app',
    actions: 'https://scheduled-purchase-service-514014482017.us-central1.run.app',
    smartReplies: 'https://smart-replies-service-514014482017.us-central1.run.app',
    steelAgent: 'https://steel-agent-service-514014482017.us-central1.run.app',
    analytics: 'https://analytics-service-514014482017.us-central1.run.app'
  },

  // Active services (based on environment)
  get services() {
    return this[this.environment];
  },

  // API Endpoints (service-agnostic paths)
  endpoints: {
    // Classifier Service (Port 8082)
    intentTaxonomy: '/api/intent-taxonomy',
    intentTaxonomyById: '/api/intent-taxonomy/:intentId',
    classify: '/api/classify',
    classifyDebug: '/api/classify/debug',
    classifyBatch: '/api/classify/batch',

    // Actions Service (Port 8085)
    actionsRegistry: '/api/actions/registry',
    actionsById: '/api/actions/:actionId',
    actionsCatalog: '/api/actions/catalog',

    // Analytics Service (Port 8090)
    analyticsMetrics: '/api/metrics',
    analyticsEvents: '/api/events',

    // Email Service (Port 8081)
    emailFetch: '/api/emails',
    emailSend: '/api/emails/send',

    // Summarization Service (Port 8083)
    summarize: '/api/summarize',
    summarizeBatch: '/api/summarize/batch',

    // Smart Replies Service (Port 8086)
    smartReplies: '/api/smart-replies',
    smartRepliesFeedback: '/api/smart-replies/feedback',

    // Shopping Cart Service (Port 8084)
    shoppingCart: '/cart',
    shoppingCartAdd: '/cart/add',

    // Steel Agent Service (Port 8087)
    steelSession: '/api/session',
    steelScreenshot: '/api/screenshot',

    // Gateway (Port 3001)
    gatewayAuth: '/auth',
    gatewayEmails: '/api/emails'
  },

  // Build full URL for an endpoint
  getUrl(service, endpoint, params = {}) {
    const baseUrl = this.services[service];
    let url = baseUrl + this.endpoints[endpoint];

    // Replace path parameters (e.g., :intentId)
    Object.keys(params).forEach(key => {
      url = url.replace(`:${key}`, params[key]);
    });

    return url;
  },

  // Fetch helper with error handling
  async fetch(service, endpoint, options = {}) {
    const url = this.getUrl(service, endpoint, options.params || {});

    try {
      const response = await fetch(url, {
        method: options.method || 'GET',
        headers: {
          'Content-Type': 'application/json',
          ...options.headers
        },
        body: options.body ? JSON.stringify(options.body) : undefined
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error(`Failed to fetch ${url}:`, error);
      throw error;
    }
  },

  // Health check helper - check all services
  async checkHealth() {
    const services = Object.keys(this.services);
    const results = {};

    for (const serviceName of services) {
      try {
        const url = `${this.services[serviceName]}/health`;
        const response = await fetch(url, { method: 'GET', timeout: 3000 });
        results[serviceName] = {
          status: response.ok ? 'healthy' : 'unhealthy',
          url,
          code: response.status
        };
      } catch (error) {
        results[serviceName] = {
          status: 'error',
          url: `${this.services[serviceName]}/health`,
          error: error.message
        };
      }
    }

    return results;
  },

  // Get environment indicator for UI
  getEnvironmentBadge() {
    return this.environment === 'production'
      ? '<span style="background: #f59e0b; color: white; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: 600;">PRODUCTION</span>'
      : '<span style="background: #10b981; color: white; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: 600;">DEV</span>';
  }
};

// Make available globally
if (typeof window !== 'undefined') {
  window.DashboardConfig = DashboardConfig;
}

// Export for modules
if (typeof module !== 'undefined' && module.exports) {
  module.exports = DashboardConfig;
}
