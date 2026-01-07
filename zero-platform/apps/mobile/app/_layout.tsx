/**
 * Root Layout
 * Sets up providers and navigation structure
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
import { LinearGradient } from 'expo-linear-gradient';
import Animated, { 
  useSharedValue, 
  useAnimatedStyle, 
  withTiming,
  withDelay,
  Easing,
  runOnJS,
} from 'react-native-reanimated';

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

export default function RootLayout() {
  const [isReady, setIsReady] = useState(false);
  const [showSplash, setShowSplash] = useState(true);
  
  // Animation values
  const logoScale = useSharedValue(0.8);
  const logoOpacity = useSharedValue(0);
  const contentOpacity = useSharedValue(0);

  useEffect(() => {
    async function prepare() {
      try {
        // Initialize API client
        initializeAPIClient({
          baseUrl: API_BASE_URL,
          timeout: 30000,
        });
        
        // Simulate minimum splash time for smooth animation
        await new Promise(resolve => setTimeout(resolve, 500));
      } catch (e) {
        console.warn('Initialization error:', e);
      } finally {
        setIsReady(true);
      }
    }

    prepare();
  }, []);

  const onLayoutRootView = useCallback(async () => {
    if (isReady) {
      // Hide native splash screen
      await SplashScreen.hideAsync();
      
      // Animate our custom splash
      logoOpacity.value = withTiming(1, { duration: 400 });
      logoScale.value = withTiming(1, { duration: 600, easing: Easing.out(Easing.back(1.5)) });
      
      // Fade out splash and show content
      setTimeout(() => {
        logoOpacity.value = withTiming(0, { duration: 300 });
        contentOpacity.value = withDelay(200, withTiming(1, { duration: 400 }));
        setTimeout(() => setShowSplash(false), 600);
      }, 1200);
    }
  }, [isReady, logoOpacity, logoScale, contentOpacity]);

  const logoAnimatedStyle = useAnimatedStyle(() => ({
    opacity: logoOpacity.value,
    transform: [{ scale: logoScale.value }],
  }));

  const contentAnimatedStyle = useAnimatedStyle(() => ({
    opacity: contentOpacity.value,
  }));

  if (!isReady) {
    return null; // Native splash screen is still visible
  }

  return (
    <GestureHandlerRootView style={styles.container} onLayout={onLayoutRootView}>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider mode="mail">
          <StatusBar style="light" />
          
          {/* Custom animated splash */}
          {showSplash && (
            <Animated.View style={[styles.splash, logoAnimatedStyle]}>
              <LinearGradient
                colors={['#0a0a1a', '#1a1a2e', '#16213e']}
                style={StyleSheet.absoluteFill}
              />
              <View style={styles.logoContainer}>
                <Animated.Text style={styles.logoText}>Zer0</Animated.Text>
                <Animated.Text style={styles.taglineText}>Inbox Zero, Reimagined</Animated.Text>
              </View>
            </Animated.View>
          )}
          
          {/* Main content */}
          <Animated.View style={[styles.content, contentAnimatedStyle]}>
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
          </Animated.View>
        </ThemeProvider>
      </QueryClientProvider>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  splash: {
    ...StyleSheet.absoluteFillObject,
    zIndex: 100,
    alignItems: 'center',
    justifyContent: 'center',
  },
  logoContainer: {
    alignItems: 'center',
  },
  logoText: {
    fontSize: 56,
    fontWeight: '800',
    color: '#fff',
    letterSpacing: -2,
    textShadowColor: 'rgba(102, 126, 234, 0.5)',
    textShadowOffset: { width: 0, height: 4 },
    textShadowRadius: 20,
  },
  taglineText: {
    fontSize: 16,
    fontWeight: '500',
    color: 'rgba(255,255,255,0.6)',
    marginTop: 8,
    letterSpacing: 1,
  },
  content: {
    flex: 1,
  },
});

