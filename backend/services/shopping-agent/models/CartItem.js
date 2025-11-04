const { v4: uuidv4 } = require('uuid');

class CartItem {
  constructor(data) {
    this.id = data.id || uuidv4();
    this.userId = data.userId;
    this.emailId = data.emailId; // Reference to the email this product came from
    this.productUrl = data.productUrl;
    this.productName = data.productName;
    this.productImage = data.productImage;
    this.price = data.price; // Current price
    this.originalPrice = data.originalPrice; // Original price (if on sale)
    this.quantity = data.quantity || 1;
    this.merchant = data.merchant; // Amazon, Target, etc.
    this.sku = data.sku;
    this.category = data.category;
    this.expiresAt = data.expiresAt; // Deal expiration timestamp
    this.metadata = data.metadata || {}; // Additional product metadata
    this.addedAt = data.addedAt || new Date().toISOString();
    this.updatedAt = data.updatedAt || new Date().toISOString();
  }

  /**
   * Calculate item total price
   */
  getTotal() {
    return this.price * this.quantity;
  }

  /**
   * Calculate savings if on sale
   */
  getSavings() {
    if (!this.originalPrice || this.originalPrice <= this.price) {
      return 0;
    }
    return (this.originalPrice - this.price) * this.quantity;
  }

  /**
   * Check if deal is expired
   */
  isExpired() {
    if (!this.expiresAt) return false;
    return new Date(this.expiresAt) < new Date();
  }

  /**
   * Get time until expiration in hours
   */
  getHoursUntilExpiration() {
    if (!this.expiresAt) return null;
    const now = new Date();
    const expiry = new Date(this.expiresAt);
    const diff = expiry - now;
    return Math.max(0, Math.floor(diff / (1000 * 60 * 60)));
  }

  /**
   * Update quantity
   */
  setQuantity(quantity) {
    if (quantity < 1) {
      throw new Error('Quantity must be at least 1');
    }
    this.quantity = quantity;
    this.updatedAt = new Date().toISOString();
  }

  /**
   * Update price (for price tracking)
   */
  updatePrice(newPrice) {
    if (newPrice !== this.price) {
      this.price = newPrice;
      this.updatedAt = new Date().toISOString();
    }
  }

  /**
   * Convert to plain object for JSON
   */
  toJSON() {
    return {
      id: this.id,
      userId: this.userId,
      emailId: this.emailId,
      productUrl: this.productUrl,
      productName: this.productName,
      productImage: this.productImage,
      price: this.price,
      originalPrice: this.originalPrice,
      quantity: this.quantity,
      merchant: this.merchant,
      sku: this.sku,
      category: this.category,
      expiresAt: this.expiresAt,
      metadata: this.metadata,
      addedAt: this.addedAt,
      updatedAt: this.updatedAt,
      total: this.getTotal(),
      savings: this.getSavings(),
      isExpired: this.isExpired(),
      hoursUntilExpiration: this.getHoursUntilExpiration()
    };
  }
}

module.exports = CartItem;
