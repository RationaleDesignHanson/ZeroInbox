/**
 * SettingsService - Persistent settings storage
 * Uses AsyncStorage for app preferences
 */

import AsyncStorage from '@react-native-async-storage/async-storage';

// Settings keys
const KEYS = {
  USE_MOCK_DATA: 'settings_use_mock_data',
  ML_CLASSIFICATION: 'settings_ml_classification',
  EMAIL_SENDING_ENABLED: 'settings_email_sending_enabled',
  DEBUG_OVERLAY: 'settings_debug_overlay',
  VIP_FILTER: 'settings_vip_filter',
  CONVERSATION_THREADING: 'settings_conversation_threading',
  MODE_INDICATORS: 'settings_mode_indicators',
  HAPTICS_ENABLED: 'settings_haptics_enabled',
  HAS_SEEN_ONBOARDING: 'settings_has_seen_onboarding',
} as const;

type SettingsKey = typeof KEYS[keyof typeof KEYS];

// Default settings values
const DEFAULTS: Record<SettingsKey, boolean> = {
  [KEYS.USE_MOCK_DATA]: true,
  [KEYS.ML_CLASSIFICATION]: true,
  [KEYS.EMAIL_SENDING_ENABLED]: false, // Safe mode by default
  [KEYS.DEBUG_OVERLAY]: false,
  [KEYS.VIP_FILTER]: false,
  [KEYS.CONVERSATION_THREADING]: false,
  [KEYS.MODE_INDICATORS]: true,
  [KEYS.HAPTICS_ENABLED]: true,
  [KEYS.HAS_SEEN_ONBOARDING]: false,
};

// Settings change listeners
type SettingsListener = (key: string, value: boolean) => void;

class SettingsServiceClass {
  private listeners: Set<SettingsListener> = new Set();
  private cache: Map<SettingsKey, boolean> = new Map();

  /**
   * Initialize settings from storage
   */
  async initialize(): Promise<void> {
    try {
      const keys = Object.values(KEYS);
      const pairs = await AsyncStorage.multiGet(keys);

      pairs.forEach(([key, value]) => {
        if (value !== null) {
          this.cache.set(key as SettingsKey, value === 'true');
        } else {
          // Use default value
          const defaultValue = DEFAULTS[key as SettingsKey];
          this.cache.set(key as SettingsKey, defaultValue);
        }
      });

      console.log('SettingsService: Initialized');
    } catch (error) {
      console.error('SettingsService: Failed to initialize:', error);
    }
  }

  /**
   * Get a boolean setting value
   */
  async get(key: SettingsKey): Promise<boolean> {
    // Check cache first
    if (this.cache.has(key)) {
      return this.cache.get(key)!;
    }

    try {
      const value = await AsyncStorage.getItem(key);
      if (value !== null) {
        const boolValue = value === 'true';
        this.cache.set(key, boolValue);
        return boolValue;
      }
      return DEFAULTS[key];
    } catch (error) {
      console.error(`SettingsService: Failed to get ${key}:`, error);
      return DEFAULTS[key];
    }
  }

  /**
   * Set a boolean setting value
   */
  async set(key: SettingsKey, value: boolean): Promise<void> {
    try {
      await AsyncStorage.setItem(key, value.toString());
      this.cache.set(key, value);
      this.notifyListeners(key, value);
      console.log(`SettingsService: Set ${key} = ${value}`);
    } catch (error) {
      console.error(`SettingsService: Failed to set ${key}:`, error);
    }
  }

  /**
   * Toggle a boolean setting
   */
  async toggle(key: SettingsKey): Promise<boolean> {
    const current = await this.get(key);
    const newValue = !current;
    await this.set(key, newValue);
    return newValue;
  }

  /**
   * Reset all settings to defaults
   */
  async resetAll(): Promise<void> {
    try {
      const keys = Object.values(KEYS);
      await AsyncStorage.multiRemove(keys);
      this.cache.clear();

      // Re-initialize with defaults
      Object.entries(DEFAULTS).forEach(([key, value]) => {
        this.cache.set(key as SettingsKey, value);
      });

      console.log('SettingsService: Reset all settings to defaults');
    } catch (error) {
      console.error('SettingsService: Failed to reset:', error);
    }
  }

  /**
   * Add a settings change listener
   */
  addListener(listener: SettingsListener): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  /**
   * Notify all listeners of a setting change
   */
  private notifyListeners(key: string, value: boolean): void {
    this.listeners.forEach((listener) => {
      try {
        listener(key, value);
      } catch (error) {
        console.error('SettingsService: Listener error:', error);
      }
    });
  }

  // Convenience getters/setters for common settings

  // Mock Data Mode
  async isUsingMockData(): Promise<boolean> {
    return this.get(KEYS.USE_MOCK_DATA);
  }
  async setUseMockData(value: boolean): Promise<void> {
    return this.set(KEYS.USE_MOCK_DATA, value);
  }

  // ML Classification
  async isMLClassificationEnabled(): Promise<boolean> {
    return this.get(KEYS.ML_CLASSIFICATION);
  }
  async setMLClassification(value: boolean): Promise<void> {
    return this.set(KEYS.ML_CLASSIFICATION, value);
  }

  // Email Sending
  async isEmailSendingEnabled(): Promise<boolean> {
    return this.get(KEYS.EMAIL_SENDING_ENABLED);
  }
  async setEmailSending(value: boolean): Promise<void> {
    return this.set(KEYS.EMAIL_SENDING_ENABLED, value);
  }

  // Debug Overlay
  async isDebugOverlayEnabled(): Promise<boolean> {
    return this.get(KEYS.DEBUG_OVERLAY);
  }
  async setDebugOverlay(value: boolean): Promise<void> {
    return this.set(KEYS.DEBUG_OVERLAY, value);
  }

  // VIP Filter
  async isVIPFilterEnabled(): Promise<boolean> {
    return this.get(KEYS.VIP_FILTER);
  }
  async setVIPFilter(value: boolean): Promise<void> {
    return this.set(KEYS.VIP_FILTER, value);
  }

  // Conversation Threading
  async isThreadingEnabled(): Promise<boolean> {
    return this.get(KEYS.CONVERSATION_THREADING);
  }
  async setThreading(value: boolean): Promise<void> {
    return this.set(KEYS.CONVERSATION_THREADING, value);
  }

  // Mode Indicators
  async areModeIndicatorsEnabled(): Promise<boolean> {
    return this.get(KEYS.MODE_INDICATORS);
  }
  async setModeIndicators(value: boolean): Promise<void> {
    return this.set(KEYS.MODE_INDICATORS, value);
  }

  // Haptics
  async areHapticsEnabled(): Promise<boolean> {
    return this.get(KEYS.HAPTICS_ENABLED);
  }
  async setHaptics(value: boolean): Promise<void> {
    return this.set(KEYS.HAPTICS_ENABLED, value);
  }

  // Onboarding
  async hasSeenOnboarding(): Promise<boolean> {
    return this.get(KEYS.HAS_SEEN_ONBOARDING);
  }
  async setHasSeenOnboarding(value: boolean): Promise<void> {
    return this.set(KEYS.HAS_SEEN_ONBOARDING, value);
  }
}

export const SettingsService = new SettingsServiceClass();

// Export keys for external reference
export const SETTINGS_KEYS = KEYS;

