/**
 * HapticService - Centralized haptic feedback for the app
 * Matches iOS implementation with expo-haptics
 */

import * as Haptics from 'expo-haptics';
import { Platform } from 'react-native';

class HapticServiceClass {
  private enabled = true;

  setEnabled(enabled: boolean) {
    this.enabled = enabled;
  }

  /**
   * Light impact - for subtle interactions
   */
  lightImpact() {
    if (!this.enabled || Platform.OS === 'web') return;
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  }

  /**
   * Medium impact - for standard interactions
   */
  mediumImpact() {
    if (!this.enabled || Platform.OS === 'web') return;
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
  }

  /**
   * Heavy impact - for significant actions like swipe completion
   */
  heavyImpact() {
    if (!this.enabled || Platform.OS === 'web') return;
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
  }

  /**
   * Selection feedback - for tab changes and selections
   */
  selection() {
    if (!this.enabled || Platform.OS === 'web') return;
    Haptics.selectionAsync();
  }

  /**
   * Success notification - for completed actions
   */
  success() {
    if (!this.enabled || Platform.OS === 'web') return;
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  }

  /**
   * Warning notification - for warnings
   */
  warning() {
    if (!this.enabled || Platform.OS === 'web') return;
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
  }

  /**
   * Error notification - for errors
   */
  error() {
    if (!this.enabled || Platform.OS === 'web') return;
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
  }
}

export const HapticService = new HapticServiceClass();

