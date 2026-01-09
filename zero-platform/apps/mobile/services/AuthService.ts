/**
 * AuthService - OAuth authentication service
 * Handles Google and Microsoft OAuth flows
 * 
 * NOTE: Real OAuth requires backend API. For now, show helpful message
 * and offer mock data as fallback.
 */

import { Alert, Platform } from 'react-native';
import { SecureStorage } from './SecureStorage';

export type AuthProviderType = 'google' | 'microsoft' | 'mock';

export interface AuthUser {
  email: string;
  provider: AuthProviderType;
  token: string;
}

export interface AuthState {
  isAuthenticated: boolean;
  isLoading: boolean;
  user: AuthUser | null;
  error: string | null;
}

class AuthServiceClass {
  /**
   * Initialize auth state from stored credentials
   */
  async initialize(): Promise<AuthUser | null> {
    try {
      const [token, email, provider] = await Promise.all([
        SecureStorage.getToken(),
        SecureStorage.getUserEmail(),
        SecureStorage.getAuthProvider(),
      ]);

      if (token && email && provider) {
        return {
          token,
          email,
          provider: provider as AuthProviderType,
        };
      }

      return null;
    } catch (error) {
      console.error('AuthService: Failed to initialize:', error);
      return null;
    }
  }

  /**
   * Login with mock data (no real authentication)
   */
  async loginWithMock(): Promise<AuthUser> {
    const mockUser: AuthUser = {
      email: 'demo@zeroinbox.app',
      provider: 'mock',
      token: 'mock_token_' + Date.now(),
    };

    await Promise.all([
      SecureStorage.setToken(mockUser.token),
      SecureStorage.setUserEmail(mockUser.email),
      SecureStorage.setAuthProvider(mockUser.provider),
      SecureStorage.setUseMockData(true),
      SecureStorage.setHasSeenSplash(true),
    ]);

    console.log('AuthService: Mock login successful');
    return mockUser;
  }

  /**
   * Login with Google OAuth
   * NOTE: Requires backend API integration
   */
  async loginWithGoogle(): Promise<AuthUser> {
    return new Promise((resolve, reject) => {
      Alert.alert(
        'Google Sign-In',
        'Google OAuth requires backend integration.\n\nWould you like to use mock data to explore the app instead?',
        [
          {
            text: 'Cancel',
            style: 'cancel',
            onPress: () => reject(new Error('Cancelled')),
          },
          {
            text: 'Use Mock Data',
            onPress: async () => {
              try {
                const user = await this.loginWithMock();
                resolve(user);
              } catch (e) {
                reject(e);
              }
            },
          },
        ]
      );
    });
  }

  /**
   * Login with Microsoft OAuth
   * NOTE: Requires backend API integration
   */
  async loginWithMicrosoft(): Promise<AuthUser> {
    return new Promise((resolve, reject) => {
      Alert.alert(
        'Microsoft Sign-In',
        'Microsoft OAuth requires backend integration.\n\nWould you like to use mock data to explore the app instead?',
        [
          {
            text: 'Cancel',
            style: 'cancel',
            onPress: () => reject(new Error('Cancelled')),
          },
          {
            text: 'Use Mock Data',
            onPress: async () => {
              try {
                const user = await this.loginWithMock();
                resolve(user);
              } catch (e) {
                reject(e);
              }
            },
          },
        ]
      );
    });
  }

  /**
   * Logout and clear stored credentials
   */
  async logout(): Promise<void> {
    await SecureStorage.clearAuth();
    console.log('AuthService: Logged out');
  }

  /**
   * Check if user is using mock data mode
   */
  async isUsingMockData(): Promise<boolean> {
    return SecureStorage.isUsingMockData();
  }

  /**
   * Get the current JWT token
   */
  async getToken(): Promise<string | null> {
    return SecureStorage.getToken();
  }

  /**
   * Refresh token if needed (placeholder for future implementation)
   */
  async refreshTokenIfNeeded(): Promise<boolean> {
    const token = await SecureStorage.getToken();
    return !!token;
  }
}

export const AuthService = new AuthServiceClass();
