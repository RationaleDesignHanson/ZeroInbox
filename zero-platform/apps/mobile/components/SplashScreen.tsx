/**
 * SplashScreen - Authentication splash screen
 * Matches iOS SplashView.swift with 10000 logo and auth buttons
 */

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  ActivityIndicator,
  Dimensions,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  Easing,
} from 'react-native-reanimated';
import Constants from 'expo-constants';

// Lazy load FloatingParticles to prevent crashes
let FloatingParticles: React.ComponentType<{ particleCount?: number; particleSize?: number; speed?: number }> | null = null;
try {
  FloatingParticles = require('./FloatingParticles').FloatingParticles;
} catch (e) {
  console.warn('FloatingParticles failed to load:', e);
}

const { width: SCREEN_WIDTH } = Dimensions.get('window');

type AuthProvider = 'mock' | 'google' | 'microsoft';

interface SplashScreenProps {
  onMockLogin: () => void;
  onGoogleLogin: () => Promise<void>;
  onMicrosoftLogin: () => Promise<void>;
}

export function SplashScreen({
  onMockLogin,
  onGoogleLogin,
  onMicrosoftLogin,
}: SplashScreenProps) {
  const [isAuthenticating, setIsAuthenticating] = useState(false);
  const [activeProvider, setActiveProvider] = useState<AuthProvider | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Animation values
  const scale = useSharedValue(0.8);
  const opacity = useSharedValue(0);

  useEffect(() => {
    // Animate in on mount
    scale.value = withSpring(1, { damping: 12, stiffness: 100 });
    opacity.value = withTiming(1, { duration: 600, easing: Easing.out(Easing.ease) });
  }, [scale, opacity]);

  const containerAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
    opacity: opacity.value,
  }));

  const handleAuth = async (provider: AuthProvider) => {
    if (isAuthenticating) return;

    setError(null);
    setActiveProvider(provider);

    if (provider === 'mock') {
      onMockLogin();
      return;
    }

    setIsAuthenticating(true);

    try {
      if (provider === 'google') {
        await onGoogleLogin();
      } else if (provider === 'microsoft') {
        await onMicrosoftLogin();
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Authentication failed');
      // Auto-hide error after 3 seconds
      setTimeout(() => setError(null), 3000);
    } finally {
      setIsAuthenticating(false);
      setActiveProvider(null);
    }
  };

  const version = Constants.expoConfig?.version ?? '2.0.0';
  const buildNumber = Constants.expoConfig?.ios?.buildNumber ?? '1';

  return (
    <View style={styles.container}>
      {/* Background gradient */}
      <LinearGradient
        colors={['#0a0a1a', '#1a1a2e', '#16213e']}
        style={StyleSheet.absoluteFill}
      />

      {/* Floating particles - conditionally rendered */}
      {FloatingParticles && <FloatingParticles particleCount={20} particleSize={4} speed={3} />}

      <Animated.View style={[styles.content, containerAnimatedStyle]}>
        {/* Logo: 10000 */}
        <View style={styles.logoSection}>
          <View style={styles.logoRow}>
            <Text style={[styles.logoDigits, styles.logoBlurred]}>10</Text>
            <View style={styles.zeroHighlight}>
              <LinearGradient
                colors={['#60A5FA', '#A855F7']}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                style={styles.zeroGradient}
              >
                <Text style={styles.zeroText}>0</Text>
              </LinearGradient>
            </View>
            <Text style={[styles.logoDigits, styles.logoBlurred]}>00</Text>
          </View>
          <Text style={styles.zeroLabel}>zero</Text>
        </View>

        {/* Tagline */}
        <View style={styles.taglineSection}>
          <Text style={styles.taglineTitle}>Clear your inbox fast.</Text>
          <Text style={styles.taglineSubtitle}>
            Swipe to keep, act, or archive for later.
          </Text>
          <Text style={styles.versionText}>
            v{version} ({buildNumber})
          </Text>
        </View>

        {/* Auth Buttons */}
        <View style={styles.authSection}>
          <View style={styles.authButtonsRow}>
            {/* Mock Data Button */}
            <AuthButton
              icon="book"
              label="Mock"
              color="#F97316"
              onPress={() => handleAuth('mock')}
              isLoading={activeProvider === 'mock' && isAuthenticating}
              disabled={isAuthenticating}
            />

            {/* Google OAuth Button */}
            <AuthButton
              icon="logo-google"
              label={activeProvider === 'google' && isAuthenticating ? 'Wait...' : 'Google'}
              color="#4285F4"
              onPress={() => handleAuth('google')}
              isLoading={activeProvider === 'google' && isAuthenticating}
              disabled={isAuthenticating}
            />

            {/* Microsoft OAuth Button */}
            <AuthButton
              icon="logo-windows"
              label={activeProvider === 'microsoft' && isAuthenticating ? 'Wait...' : 'Microsoft'}
              color="#A855F7"
              onPress={() => handleAuth('microsoft')}
              isLoading={activeProvider === 'microsoft' && isAuthenticating}
              disabled={isAuthenticating}
            />
          </View>

          {/* Error message */}
          {error && (
            <Animated.Text style={styles.errorText}>{error}</Animated.Text>
          )}
        </View>
      </Animated.View>
    </View>
  );
}

interface AuthButtonProps {
  icon: keyof typeof Ionicons.glyphMap;
  label: string;
  color: string;
  onPress: () => void;
  isLoading?: boolean;
  disabled?: boolean;
}

function AuthButton({
  icon,
  label,
  color,
  onPress,
  isLoading,
  disabled,
}: AuthButtonProps) {
  return (
    <Pressable
      style={[styles.authButton, disabled && styles.authButtonDisabled]}
      onPress={onPress}
      disabled={disabled}
    >
      <View style={styles.authButtonCircle}>
        {/* Use a solid background instead of BlurView for stability */}
        <View style={[StyleSheet.absoluteFill, { backgroundColor: 'rgba(30, 30, 50, 0.8)' }]} />
        <View style={styles.authButtonInner}>
          {isLoading ? (
            <ActivityIndicator color="white" size="small" />
          ) : (
            <Ionicons name={icon} size={24} color={color} />
          )}
        </View>
        <View style={styles.authButtonRim} />
      </View>
      <Text style={styles.authButtonLabel}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a1a',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 40,
  },
  logoSection: {
    alignItems: 'center',
    marginBottom: 30,
  },
  logoRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  logoDigits: {
    fontSize: 70,
    fontWeight: '800',
    color: 'white',
  },
  logoBlurred: {
    opacity: 0.3,
    // Note: React Native doesn't support blur on text directly
    // We simulate with opacity
  },
  zeroHighlight: {
    marginHorizontal: 4,
  },
  zeroGradient: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 10,
    elevation: 8,
  },
  zeroText: {
    fontSize: 70,
    fontWeight: '800',
    color: 'white',
  },
  zeroLabel: {
    fontSize: 36,
    fontWeight: '800',
    color: 'white',
    marginTop: 8,
    marginLeft: -10,
  },
  taglineSection: {
    alignItems: 'center',
    marginBottom: 60,
  },
  taglineTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: 'white',
    marginBottom: 8,
  },
  taglineSubtitle: {
    fontSize: 16,
    fontWeight: '400',
    color: 'rgba(255, 255, 255, 0.6)',
    textAlign: 'center',
  },
  versionText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.3)',
    marginTop: 8,
  },
  authSection: {
    width: '100%',
    alignItems: 'center',
  },
  authButtonsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    width: '100%',
    paddingHorizontal: 20,
  },
  authButton: {
    alignItems: 'center',
    flex: 1,
  },
  authButtonDisabled: {
    opacity: 0.6,
  },
  authButtonCircle: {
    width: 64,
    height: 64,
    borderRadius: 32,
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.4)',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 5 },
    shadowOpacity: 0.3,
    shadowRadius: 15,
    elevation: 10,
  },
  authButtonInner: {
    width: '100%',
    height: '100%',
    alignItems: 'center',
    justifyContent: 'center',
  },
  authButtonRim: {
    ...StyleSheet.absoluteFillObject,
    borderRadius: 32,
    borderWidth: 0.5,
    borderColor: 'rgba(255, 255, 255, 0.15)',
  },
  authButtonLabel: {
    fontSize: 13,
    fontWeight: '500',
    color: 'rgba(255, 255, 255, 0.7)',
    marginTop: 8,
  },
  errorText: {
    fontSize: 14,
    color: 'rgba(239, 68, 68, 0.8)',
    marginTop: 20,
    textAlign: 'center',
  },
});

