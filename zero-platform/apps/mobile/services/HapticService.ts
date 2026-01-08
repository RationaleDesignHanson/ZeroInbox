/**
 * HapticService - Centralized haptic feedback for the app
 * Matches iOS implementation with expo-haptics
 */

import * as Haptics from 'expo-haptics';
import { Platform } from 'react-native';

class HapticServiceClass {
  private enabled = true;

  constructor() {
    // Bind all methods to preserve 'this' context when used with runOnJS
    this.lightImpact = this.lightImpact.bind(this);
    this.mediumImpact = this.mediumImpact.bind(this);
    this.heavyImpact = this.heavyImpact.bind(this);
    this.selection = this.selection.bind(this);
    this.success = this.success.bind(this);
    this.warning = this.warning.bind(this);
    this.error = this.error.bind(this);
  }

  setEnabled(enabled: boolean) {
    this.enabled = enabled;
  }

  /**
   * Light impact - for subtle interactions
   */
  lightImpact() {
    try {
      if (!this.enabled || Platform.OS === 'web') return;
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    } catch (e) {
      // Silently fail - haptics are not critical
    }
  }

  /**
   * Medium impact - for standard interactions
   */
  mediumImpact() {
    try {
      if (!this.enabled || Platform.OS === 'web') return;
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    } catch (e) {
      // Silently fail - haptics are not critical
    }
  }

  /**
   * Heavy impact - for significant actions like swipe completion
   */
  heavyImpact() {
    try {
      if (!this.enabled || Platform.OS === 'web') return;
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
    } catch (e) {
      // Silently fail - haptics are not critical
    }
  }

  /**
   * Selection feedback - for tab changes and selections
   */
  selection() {
    try {
      if (!this.enabled || Platform.OS === 'web') return;
      Haptics.selectionAsync();
    } catch (e) {
      // Silently fail - haptics are not critical
    }
  }

  /**
   * Success notification - for completed actions
   */
  success() {
    try {
      if (!this.enabled || Platform.OS === 'web') return;
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    } catch (e) {
      // Silently fail - haptics are not critical
    }
  }

  /**
   * Warning notification - for warnings
   */
  warning() {
    try {
      if (!this.enabled || Platform.OS === 'web') return;
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
    } catch (e) {
      // Silently fail - haptics are not critical
    }
  }

  /**
   * Error notification - for errors
   */
  error() {
    try {
      if (!this.enabled || Platform.OS === 'web') return;
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
    } catch (e) {
      // Silently fail - haptics are not critical
    }
  }
}

export const HapticService = new HapticServiceClass();

