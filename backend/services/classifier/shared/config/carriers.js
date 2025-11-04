/**
 * Shipping Carrier Configuration
 * Centralized carrier information for tracking URL generation
 * Override URLs via environment variables for testing
 */

module.exports = {
  carriers: {
    ups: {
      name: 'UPS',
      trackingUrl: process.env.UPS_TRACKING_URL || 'https://www.ups.com/track?tracknum={trackingNumber}',
      pattern: /\b(1Z[A-Z0-9]{16})\b/i,
      description: 'UPS tracking numbers start with 1Z followed by 16 alphanumeric characters'
    },
    fedex: {
      name: 'FedEx',
      trackingUrl: process.env.FEDEX_TRACKING_URL || 'https://www.fedex.com/fedextrack/?tracknumbers={trackingNumber}',
      pattern: /\b(\d{12,14})\b/,
      description: 'FedEx tracking numbers are 12-14 digits'
    },
    usps: {
      name: 'USPS',
      trackingUrl: process.env.USPS_TRACKING_URL || 'https://tools.usps.com/go/TrackConfirmAction?tLabels={trackingNumber}',
      pattern: /\b(\d{20,22})\b/,
      description: 'USPS tracking numbers are 20-22 digits'
    },
    dhl: {
      name: 'DHL',
      trackingUrl: process.env.DHL_TRACKING_URL || 'https://www.dhl.com/en/express/tracking.html?AWB={trackingNumber}',
      pattern: /\b(\d{10,11})\b/,
      description: 'DHL tracking numbers are 10-11 digits'
    },
    amazon: {
      name: 'Amazon',
      trackingUrl: process.env.AMAZON_TRACKING_URL || 'https://www.amazon.com/progress-tracker/package?itemId={trackingNumber}',
      pattern: /\b(TBA\d{12})\b/i,
      description: 'Amazon tracking numbers start with TBA followed by 12 digits'
    }
  },

  /**
   * Get carrier tracking URL with tracking number substituted
   * @param {string} carrierName - Carrier name (case-insensitive)
   * @param {string} trackingNumber - Tracking number to substitute
   * @returns {string|null} Full tracking URL or null if carrier not found
   */
  getTrackingUrl(carrierName, trackingNumber) {
    const carrierKey = carrierName.toLowerCase();
    
    for (const [key, config] of Object.entries(this.carriers)) {
      if (carrierKey.includes(key)) {
        return config.trackingUrl.replace('{trackingNumber}', encodeURIComponent(trackingNumber));
      }
    }
    
    // Generic tracking search if carrier unknown
    return `https://www.google.com/search?q=track+${encodeURIComponent(trackingNumber)}`;
  },

  /**
   * Detect carrier from tracking number pattern
   * @param {string} trackingNumber - Tracking number to analyze
   * @returns {string|null} Detected carrier name or null
   */
  detectCarrier(trackingNumber) {
    for (const [key, config] of Object.entries(this.carriers)) {
      if (config.pattern.test(trackingNumber)) {
        return config.name;
      }
    }
    return null;
  }
};

