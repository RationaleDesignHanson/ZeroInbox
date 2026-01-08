/**
 * AuthService - OAuth authentication service
 * Handles Google and Microsoft OAuth flows using expo-auth-session
 */

import * as AuthSession from 'expo-auth-session';
import * as WebBrowser from 'expo-web-browser';
import { Platform } from 'react-native';
import { SecureStorage } from './SecureStorage';

// Required for OAuth flow completion
WebBrowser.maybeCompleteAuthSession();

// OAuth Configuration
const GOOGLE_CLIENT_ID = process.env.EXPO_PUBLIC_GOOGLE_CLIENT_ID || '';
const MICROSOFT_CLIENT_ID = process.env.EXPO_PUBLIC_MICROSOFT_CLIENT_ID || '';
const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'https://api.zeroinbox.app';

// OAuth redirect URIs
const GOOGLE_REDIRECT_URI = AuthSession.makeRedirectUri({
  scheme: 'com.zeroinbox.app',
  path: 'oauth/google',
});

const MICROSOFT_REDIRECT_URI = AuthSession.makeRedirectUri({
  scheme: 'com.zeroinbox.app',
  path: 'oauth/microsoft',
});

export type AuthProvider = 'google' | 'microsoft' | 'mock';

export interface AuthUser {
  email: string;
  provider: AuthProvider;
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
          provider: provider as AuthProvider,
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
   */
  async loginWithGoogle(): Promise<AuthUser> {
    try {
      // Request auth URL from backend
      const authUrlResponse = await fetch(`${API_BASE_URL}/auth/gmail`);
      if (!authUrlResponse.ok) {
        throw new Error('Failed to get Google auth URL');
      }
      
      const { authUrl } = await authUrlResponse.json();

      // Open browser for OAuth flow
      const result = await WebBrowser.openAuthSessionAsync(
        authUrl,
        GOOGLE_REDIRECT_URI
      );

      if (result.type !== 'success') {
        throw new Error('Google authentication was cancelled');
      }

      // Extract token and email from callback URL
      const url = new URL(result.url);
      const token = url.searchParams.get('token');
      const email = url.searchParams.get('email');

      if (!token || !email) {
        throw new Error('Missing token or email from OAuth callback');
      }

      const user: AuthUser = {
        token,
        email,
        provider: 'google',
      };

      await Promise.all([
        SecureStorage.setToken(token),
        SecureStorage.setUserEmail(email),
        SecureStorage.setAuthProvider('google'),
        SecureStorage.setUseMockData(false),
        SecureStorage.setHasSeenSplash(true),
      ]);

      console.log('AuthService: Google login successful for', email);
      return user;
    } catch (error) {
      console.error('AuthService: Google login failed:', error);
      throw error;
    }
  }

  /**
   * Login with Microsoft OAuth
   */
  async loginWithMicrosoft(): Promise<AuthUser> {
    try {
      // Request auth URL from backend
      const authUrlResponse = await fetch(`${API_BASE_URL}/auth/outlook`);
      if (!authUrlResponse.ok) {
        throw new Error('Failed to get Microsoft auth URL');
      }
      
      const { authUrl } = await authUrlResponse.json();

      // Open browser for OAuth flow
      const result = await WebBrowser.openAuthSessionAsync(
        authUrl,
        MICROSOFT_REDIRECT_URI
      );

      if (result.type !== 'success') {
        throw new Error('Microsoft authentication was cancelled');
      }

      // Extract token and email from callback URL
      const url = new URL(result.url);
      const token = url.searchParams.get('token');
      const email = url.searchParams.get('email');

      if (!token || !email) {
        throw new Error('Missing token or email from OAuth callback');
      }

      const user: AuthUser = {
        token,
        email,
        provider: 'microsoft',
      };

      await Promise.all([
        SecureStorage.setToken(token),
        SecureStorage.setUserEmail(email),
        SecureStorage.setAuthProvider('microsoft'),
        SecureStorage.setUseMockData(false),
        SecureStorage.setHasSeenSplash(true),
      ]);

      console.log('AuthService: Microsoft login successful for', email);
      return user;
    } catch (error) {
      console.error('AuthService: Microsoft login failed:', error);
      throw error;
    }
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
    // TODO: Implement token refresh logic
    const token = await SecureStorage.getToken();
    return !!token;
  }
}

export const AuthService = new AuthServiceClass();

