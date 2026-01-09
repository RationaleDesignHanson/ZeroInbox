/**
 * AuthContext - Authentication state management
 * Provides auth state and methods to all components
 */

import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { AuthService, AuthUser } from '../services/AuthService';
import { SecureStorage } from '../services/SecureStorage';

const ONBOARDING_KEY = 'hasCompletedOnboarding';

interface AuthContextType {
  // State
  isAuthenticated: boolean;
  isLoading: boolean;
  user: AuthUser | null;
  error: string | null;
  useMockData: boolean;
  hasCompletedOnboarding: boolean;

  // Actions
  loginWithMock: () => Promise<void>;
  loginWithGoogle: () => Promise<void>;
  loginWithMicrosoft: () => Promise<void>;
  logout: () => Promise<void>;
  clearError: () => void;
  setOnboardingComplete: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [user, setUser] = useState<AuthUser | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [useMockData, setUseMockData] = useState(false);
  const [hasCompletedOnboarding, setHasCompletedOnboarding] = useState(false);

  // Initialize auth state on mount
  useEffect(() => {
    let mounted = true;

    async function initializeAuth() {
      try {
        if (!mounted) return;
        setIsLoading(true);
        
        // Check for existing auth - with defensive try-catch
        let existingUser = null;
        let mockMode = false;
        let onboardingComplete = false;
        
        try {
          existingUser = await AuthService.initialize();
        } catch (e) {
          console.warn('AuthContext: AuthService.initialize failed:', e);
        }
        
        try {
          mockMode = await SecureStorage.isUsingMockData();
        } catch (e) {
          console.warn('AuthContext: SecureStorage.isUsingMockData failed:', e);
        }
        
        try {
          const onboardingValue = await AsyncStorage.getItem(ONBOARDING_KEY);
          onboardingComplete = onboardingValue === 'true';
        } catch (e) {
          console.warn('AuthContext: Failed to get onboarding state:', e);
        }
        
        if (!mounted) return;
        
        if (existingUser) {
          setUser(existingUser);
          setIsAuthenticated(true);
          setUseMockData(mockMode);
          setHasCompletedOnboarding(onboardingComplete);
        }
      } catch (err) {
        console.error('AuthContext: Failed to initialize:', err);
      } finally {
        if (mounted) {
          setIsLoading(false);
        }
      }
    }

    initializeAuth();
    
    return () => {
      mounted = false;
    };
  }, []);

  const loginWithMock = useCallback(async () => {
    try {
      setError(null);
      const authUser = await AuthService.loginWithMock();
      setUser(authUser);
      setIsAuthenticated(true);
      setUseMockData(true);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Mock login failed';
      setError(message);
      throw err;
    }
  }, []);

  const loginWithGoogle = useCallback(async () => {
    try {
      setError(null);
      const authUser = await AuthService.loginWithGoogle();
      setUser(authUser);
      setIsAuthenticated(true);
      setUseMockData(false);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Google login failed';
      setError(message);
      throw err;
    }
  }, []);

  const loginWithMicrosoft = useCallback(async () => {
    try {
      setError(null);
      const authUser = await AuthService.loginWithMicrosoft();
      setUser(authUser);
      setIsAuthenticated(true);
      setUseMockData(false);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Microsoft login failed';
      setError(message);
      throw err;
    }
  }, []);

  const logout = useCallback(async () => {
    try {
      await AuthService.logout();
      setUser(null);
      setIsAuthenticated(false);
      setUseMockData(false);
    } catch (err) {
      console.error('AuthContext: Logout failed:', err);
    }
  }, []);

  const clearError = useCallback(() => {
    setError(null);
  }, []);

  const setOnboardingComplete = useCallback(async () => {
    try {
      await AsyncStorage.setItem(ONBOARDING_KEY, 'true');
      setHasCompletedOnboarding(true);
    } catch (e) {
      console.error('AuthContext: Failed to set onboarding complete:', e);
    }
  }, []);

  const value: AuthContextType = {
    isAuthenticated,
    isLoading,
    user,
    error,
    useMockData,
    hasCompletedOnboarding,
    loginWithMock,
    loginWithGoogle,
    loginWithMicrosoft,
    logout,
    clearError,
    setOnboardingComplete,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

