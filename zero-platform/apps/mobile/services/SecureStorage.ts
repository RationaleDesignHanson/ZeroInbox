/**
 * SecureStorage - Secure storage for sensitive data like JWT tokens
 * Uses expo-secure-store for encrypted storage on device
 */

import * as SecureStore from 'expo-secure-store';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';

const KEYS = {
  JWT_TOKEN: 'zero_jwt_token',
  USER_EMAIL: 'zero_user_email',
  AUTH_PROVIDER: 'zero_auth_provider',
  HAS_SEEN_SPLASH: 'zero_has_seen_splash',
  USE_MOCK_DATA: 'zero_use_mock_data',
} as const;

type StorageKey = typeof KEYS[keyof typeof KEYS];

class SecureStorageService {
  /**
   * Store a value securely
   * Falls back to AsyncStorage on web
   */
  async setItem(key: StorageKey, value: string): Promise<void> {
    try {
      if (Platform.OS === 'web') {
        await AsyncStorage.setItem(key, value);
      } else {
        await SecureStore.setItemAsync(key, value);
      }
    } catch (error) {
      console.error(`SecureStorage: Failed to store ${key}:`, error);
      throw error;
    }
  }

  /**
   * Retrieve a stored value
   */
  async getItem(key: StorageKey): Promise<string | null> {
    try {
      if (Platform.OS === 'web') {
        return await AsyncStorage.getItem(key);
      }
      return await SecureStore.getItemAsync(key);
    } catch (error) {
      console.error(`SecureStorage: Failed to retrieve ${key}:`, error);
      return null;
    }
  }

  /**
   * Delete a stored value
   */
  async deleteItem(key: StorageKey): Promise<void> {
    try {
      if (Platform.OS === 'web') {
        await AsyncStorage.removeItem(key);
      } else {
        await SecureStore.deleteItemAsync(key);
      }
    } catch (error) {
      console.error(`SecureStorage: Failed to delete ${key}:`, error);
    }
  }

  // Convenience methods for common operations

  /**
   * Store JWT token
   */
  async setToken(token: string): Promise<void> {
    await this.setItem(KEYS.JWT_TOKEN, token);
  }

  /**
   * Get stored JWT token
   */
  async getToken(): Promise<string | null> {
    return this.getItem(KEYS.JWT_TOKEN);
  }

  /**
   * Clear JWT token
   */
  async clearToken(): Promise<void> {
    await this.deleteItem(KEYS.JWT_TOKEN);
  }

  /**
   * Store user email
   */
  async setUserEmail(email: string): Promise<void> {
    await this.setItem(KEYS.USER_EMAIL, email);
  }

  /**
   * Get stored user email
   */
  async getUserEmail(): Promise<string | null> {
    return this.getItem(KEYS.USER_EMAIL);
  }

  /**
   * Store auth provider (google, microsoft, mock)
   */
  async setAuthProvider(provider: string): Promise<void> {
    await this.setItem(KEYS.AUTH_PROVIDER, provider);
  }

  /**
   * Get stored auth provider
   */
  async getAuthProvider(): Promise<string | null> {
    return this.getItem(KEYS.AUTH_PROVIDER);
  }

  /**
   * Check if user has seen splash screen
   */
  async hasSeenSplash(): Promise<boolean> {
    const value = await this.getItem(KEYS.HAS_SEEN_SPLASH);
    return value === 'true';
  }

  /**
   * Mark splash screen as seen
   */
  async setHasSeenSplash(seen: boolean): Promise<void> {
    await this.setItem(KEYS.HAS_SEEN_SPLASH, seen ? 'true' : 'false');
  }

  /**
   * Check if using mock data
   */
  async isUsingMockData(): Promise<boolean> {
    const value = await this.getItem(KEYS.USE_MOCK_DATA);
    return value === 'true';
  }

  /**
   * Set mock data mode
   */
  async setUseMockData(useMock: boolean): Promise<void> {
    await this.setItem(KEYS.USE_MOCK_DATA, useMock ? 'true' : 'false');
  }

  /**
   * Clear all auth-related data (for logout)
   */
  async clearAuth(): Promise<void> {
    await Promise.all([
      this.deleteItem(KEYS.JWT_TOKEN),
      this.deleteItem(KEYS.USER_EMAIL),
      this.deleteItem(KEYS.AUTH_PROVIDER),
    ]);
  }

  /**
   * Clear all stored data
   */
  async clearAll(): Promise<void> {
    await Promise.all(
      Object.values(KEYS).map((key) => this.deleteItem(key))
    );
  }
}

export const SecureStorage = new SecureStorageService();

