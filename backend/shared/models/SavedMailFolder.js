/**
 * SavedMailFolder Model
 * User-created folders for organizing important emails
 */

const { v4: uuidv4 } = require('uuid');

class SavedMailFolder {
  constructor(data) {
    this.id = data.id || uuidv4();
    this.userId = data.userId;
    this.name = data.name;
    this.color = data.color || null; // Hex color code (optional)
    this.emailIds = data.emailIds || [];
    this.isPreset = data.isPreset || false; // True for system preset folders (Receipts, Travel, etc.)
    this.icon = data.icon || null; // SF Symbol name for preset folders
    this.createdAt = data.createdAt || new Date().toISOString();
    this.updatedAt = data.updatedAt || new Date().toISOString();
  }

  /**
   * Validate folder data
   */
  validate() {
    const errors = [];

    if (!this.userId || typeof this.userId !== 'string') {
      errors.push('userId is required and must be a string');
    }

    if (!this.name || typeof this.name !== 'string') {
      errors.push('name is required and must be a string');
    }

    if (this.name && this.name.length > 200) {
      errors.push('name must be 200 characters or less');
    }

    if (this.color && !/^#[0-9A-F]{6}$/i.test(this.color)) {
      errors.push('color must be a valid hex color code (e.g., #FF5733)');
    }

    if (!Array.isArray(this.emailIds)) {
      errors.push('emailIds must be an array');
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }

  /**
   * Add email to folder
   */
  addEmail(emailId) {
    if (!this.emailIds.includes(emailId)) {
      this.emailIds.push(emailId);
      this.updatedAt = new Date().toISOString();
      return true;
    }
    return false; // Already in folder
  }

  /**
   * Remove email from folder
   */
  removeEmail(emailId) {
    const index = this.emailIds.indexOf(emailId);
    if (index > -1) {
      this.emailIds.splice(index, 1);
      this.updatedAt = new Date().toISOString();
      return true;
    }
    return false; // Not in folder
  }

  /**
   * Update folder metadata
   */
  update(data) {
    if (data.name !== undefined) {
      this.name = data.name;
    }
    if (data.color !== undefined) {
      this.color = data.color;
    }
    this.updatedAt = new Date().toISOString();
  }

  /**
   * Convert to JSON (for API responses)
   */
  toJSON() {
    return {
      id: this.id,
      userId: this.userId,
      name: this.name,
      color: this.color,
      emailIds: this.emailIds,
      emailCount: this.emailIds.length,
      isPreset: this.isPreset,
      icon: this.icon,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }
}

/**
 * Preset Folder Templates
 */
SavedMailFolder.PRESET_FOLDERS = [
  {
    name: 'Receipts',
    color: '#34C759', // Green
    icon: 'receipt.fill',
    description: 'Shopping confirmations and purchase receipts'
  },
  {
    name: 'Travel',
    color: '#007AFF', // Blue
    icon: 'airplane.circle.fill',
    description: 'Flight bookings, hotels, and travel confirmations'
  },
  {
    name: 'Work',
    color: '#5856D6', // Purple
    icon: 'briefcase.fill',
    description: 'Professional and work-related emails'
  },
  {
    name: 'Family',
    color: '#FF2D55', // Magenta
    icon: 'heart.fill',
    description: 'Personal family communications'
  },
  {
    name: 'Bills',
    color: '#FF9500', // Orange
    icon: 'creditcard.fill',
    description: 'Utility bills, subscriptions, and payments'
  },
  {
    name: 'Events',
    color: '#FF3B30', // Red
    icon: 'calendar.badge.exclamationmark',
    description: 'Tickets, registrations, and event confirmations'
  }
];

module.exports = SavedMailFolder;
