/**
 * AuthService - OAuth authentication service
 * Handles Google and Microsoft OAuth flows using expo-auth-session
 */

import { Platform } from 'react-native';
import { SecureStorage } from './SecureStorage';

// Lazy load OAuth modules to prevent crashes on app start
let AuthSession: typeof import('expo-auth-session') | null = null;
let WebBrowser: typeof import('expo-web-browser') | null = null;

// OAuth Configuration
const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'https://api.zeroinbox.app';

// Initialize OAuth modules lazily
async function initOAuthModules() {
  if (!AuthSession) {
    AuthSession = await import('expo-auth-session');
  }
  if (!WebBrowser) {
    WebBrowser = await import('expo-web-browser');
    try {
      WebBrowser.maybeCompleteAuthSession();
    } catch (e) {
      console.warn('AuthService: maybeCompleteAuthSession failed:', e);
    }
  }
}

// Get redirect URI (called after modules are loaded)
function getRedirectUri(path: string): string {
  if (!AuthSession) {
    return '';
  }
  return AuthSession.makeRedirectUri({
    scheme: 'com.zeroinbox.app',
    path,
  });
}

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
   */
  async loginWithGoogle(): Promise<AuthUser> {
    try {
      // Initialize OAuth modules
      await initOAuthModules();
      if (!WebBrowser) {
        throw new Error('OAuth modules not available');
      }

      // Request auth URL from backend
      const authUrlResponse = await fetch(`${API_BASE_URL}/auth/gmail`);
      if (!authUrlResponse.ok) {
        throw new Error('Failed to get Google auth URL');
      }
      
      const { authUrl } = await authUrlResponse.json();
      const redirectUri = getRedirectUri('oauth/google');

      // Open browser for OAuth flow
      const result = await WebBrowser.openAuthSessionAsync(
        authUrl,
        redirectUri
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
      // Initialize OAuth modules
      await initOAuthModules();
      if (!WebBrowser) {
        throw new Error('OAuth modules not available');
      }

      // Request auth URL from backend
      const authUrlResponse = await fetch(`${API_BASE_URL}/auth/outlook`);
      if (!authUrlResponse.ok) {
        throw new Error('Failed to get Microsoft auth URL');
      }
      
      const { authUrl } = await authUrlResponse.json();
      const redirectUri = getRedirectUri('oauth/microsoft');

      // Open browser for OAuth flow
      const result = await WebBrowser.openAuthSessionAsync(
        authUrl,
        redirectUri
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

