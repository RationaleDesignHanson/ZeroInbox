/**
 * Root Layout
 * Sets up providers, authentication, and navigation structure
 */

import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { ThemeProvider } from '@zero/ui';
import { initializeAPIClient } from '@zero/api';
import { useEffect, useState, useCallback } from 'react';
import { View, StyleSheet } from 'react-native';
import * as SplashScreen from 'expo-splash-screen';
import { AuthProvider, useAuth } from '../contexts/AuthContext';
import { SplashScreen as CustomSplashScreen } from '../components/SplashScreen';

// Keep splash screen visible while we initialize
SplashScreen.preventAutoHideAsync();

// Initialize API client
const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'https://api.zeroinbox.app';

// Create query client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      retry: 2,
    },
  },
});

function RootLayoutContent() {
  const { isAuthenticated, isLoading, loginWithMock, loginWithGoogle, loginWithMicrosoft } = useAuth();
  const [isReady, setIsReady] = useState(false);

  useEffect(() => {
    async function prepare() {
      try {
        // Initialize API client
        initializeAPIClient({
          baseUrl: API_BASE_URL,
          timeout: 30000,
        });
        
        // Small delay for smooth transition
        await new Promise(resolve => setTimeout(resolve, 300));
      } catch (e) {
        console.warn('Initialization error:', e);
      } finally {
        setIsReady(true);
      }
    }

    prepare();
  }, []);

  const onLayoutRootView = useCallback(async () => {
    if (isReady && !isLoading) {
      // Hide native splash screen
      await SplashScreen.hideAsync();
    }
  }, [isReady, isLoading]);

  // Still loading auth state or app not ready
  if (!isReady || isLoading) {
    return null;
  }

  // Not authenticated - show custom splash with auth buttons
  if (!isAuthenticated) {
    return (
      <View style={styles.container} onLayout={onLayoutRootView}>
        <StatusBar style="light" />
        <CustomSplashScreen
          onMockLogin={loginWithMock}
          onGoogleLogin={loginWithGoogle}
          onMicrosoftLogin={loginWithMicrosoft}
        />
      </View>
    );
  }

  // Authenticated - show main app
  return (
    <View style={styles.container} onLayout={onLayoutRootView}>
      <StatusBar style="light" />
      <Stack
        screenOptions={{
          headerShown: false,
          contentStyle: { backgroundColor: '#0a0a0f' },
          animation: 'slide_from_right',
        }}
      >
        <Stack.Screen name="index" options={{ headerShown: false }} />
        <Stack.Screen name="feed" options={{ headerShown: false }} />
        <Stack.Screen
          name="email/[id]"
          options={{
            presentation: 'card',
            animation: 'slide_from_bottom',
          }}
        />
        <Stack.Screen
          name="action/[actionId]"
          options={{
            presentation: 'modal',
            animation: 'slide_from_bottom',
          }}
        />
        <Stack.Screen
          name="settings-modal"
          options={{
            presentation: 'modal',
            animation: 'slide_from_bottom',
          }}
        />
      </Stack>
    </View>
  );
}

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={styles.container}>
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          <ThemeProvider mode="mail">
            <RootLayoutContent />
          </ThemeProvider>
        </AuthProvider>
      </QueryClientProvider>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0f',
  },
});
