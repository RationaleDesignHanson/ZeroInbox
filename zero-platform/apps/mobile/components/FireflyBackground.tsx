/**
 * FireflyBackground - Animated particle background
 * Port of iOS FireflyBackgroundOnboarding
 * 
 * Features:
 * - 30 small/medium/warm particles
 * - 4 large ambient orbs
 * - Floating animation with opacity pulsing
 */

import React, { useEffect, useRef, useMemo } from 'react';
import { View, StyleSheet, Dimensions } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withTiming,
  withDelay,
  Easing,
  interpolate,
} from 'react-native-reanimated';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');

// Firefly types matching iOS
type FireflyType = 'small' | 'medium' | 'warm' | 'orb';

interface FireflyConfig {
  id: string;
  type: FireflyType;
  color: string;
  size: number;
  blur: number;
  opacity: number;
  duration: number;
  initialX: number;
  initialY: number;
}

// Color configurations matching iOS exactly
const FIREFLY_CONFIGS: Record<FireflyType, Omit<FireflyConfig, 'id' | 'duration' | 'initialX' | 'initialY'>> = {
  small: {
    type: 'small',
    color: 'rgb(147, 197, 253)', // Light blue
    size: 6,
    blur: 5,
    opacity: 0.8,
  },
  medium: {
    type: 'medium',
    color: 'rgb(196, 181, 253)', // Light purple
    size: 10,
    blur: 7.5,
    opacity: 0.9,
  },
  warm: {
    type: 'warm',
    color: 'rgb(251, 191, 36)', // Amber/yellow
    size: 8,
    blur: 6,
    opacity: 0.9,
  },
  orb: {
    type: 'orb',
    color: 'rgb(139, 92, 246)', // Purple
    size: 200,
    blur: 40,
    opacity: 0.15,
  },
};

// Generate firefly configurations
function generateFireflies(): FireflyConfig[] {
  const fireflies: FireflyConfig[] = [];

  // 30 small/medium/warm particles
  for (let i = 0; i < 30; i++) {
    const rand = Math.random();
    const type: FireflyType = rand < 0.33 ? 'small' : rand < 0.66 ? 'medium' : 'warm';
    const config = FIREFLY_CONFIGS[type];

    fireflies.push({
      ...config,
      id: `particle-${i}`,
      duration: 8 + Math.random() * 12, // 8-20s
      initialX: Math.random() * SCREEN_WIDTH,
      initialY: Math.random() * SCREEN_HEIGHT,
    });
  }

  // 4 large ambient orbs
  for (let i = 0; i < 4; i++) {
    const config = FIREFLY_CONFIGS.orb;

    fireflies.push({
      ...config,
      id: `orb-${i}`,
      duration: 20 + Math.random() * 15, // 20-35s
      initialX: Math.random() * SCREEN_WIDTH,
      initialY: Math.random() * SCREEN_HEIGHT,
    });
  }

  return fireflies;
}

// Individual firefly component
function Firefly({ config }: { config: FireflyConfig }) {
  const opacity = useSharedValue(0.3 + Math.random() * 0.6);
  const translateX = useSharedValue(0);
  const translateY = useSharedValue(0);

  useEffect(() => {
    const delay = Math.random() * config.duration * 1000;
    const moveRange = config.type === 'orb' ? 80 : 70;

    // Animate opacity
    opacity.value = withDelay(
      delay,
      withRepeat(
        withTiming(0.3 + Math.random() * 0.6, {
          duration: config.duration * 1000,
          easing: Easing.inOut(Easing.ease),
        }),
        -1,
        true
      )
    );

    // Animate position X
    translateX.value = withDelay(
      delay,
      withRepeat(
        withTiming(
          (Math.random() - 0.5) * moveRange * 2,
          {
            duration: config.duration * 1000,
            easing: Easing.inOut(Easing.ease),
          }
        ),
        -1,
        true
      )
    );

    // Animate position Y
    translateY.value = withDelay(
      delay + 500,
      withRepeat(
        withTiming(
          (Math.random() - 0.5) * moveRange * 2,
          {
            duration: config.duration * 1000 * 1.1,
            easing: Easing.inOut(Easing.ease),
          }
        ),
        -1,
        true
      )
    );
  }, []);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [
      { translateX: translateX.value },
      { translateY: translateY.value },
    ],
  }));

  return (
    <Animated.View
      style={[
        styles.firefly,
        {
          left: config.initialX - config.size / 2,
          top: config.initialY - config.size / 2,
          width: config.size,
          height: config.size,
          borderRadius: config.size / 2,
          backgroundColor: config.color,
          // Use shadow for blur effect on iOS
          shadowColor: config.color,
          shadowOffset: { width: 0, height: 0 },
          shadowOpacity: config.opacity,
          shadowRadius: config.blur,
          // Android elevation approximation
          elevation: config.blur / 5,
        },
        animatedStyle,
      ]}
    />
  );
}

interface FireflyBackgroundProps {
  variant?: 'onboarding' | 'mail' | 'ads';
}

export function FireflyBackground({ variant = 'onboarding' }: FireflyBackgroundProps) {
  // Memoize firefly configs so they don't regenerate on re-render
  const fireflies = useMemo(() => generateFireflies(), []);

  // Gradient colors based on variant (matching iOS)
  const gradientColors = useMemo(() => {
    switch (variant) {
      case 'mail':
        return ['#1a1a2e', '#2d1b4e', '#4a1942', '#1f1f3a'];
      case 'ads':
        return ['#1a2e1a', '#1b4e2d', '#194a42', '#1f3a1f'];
      case 'onboarding':
      default:
        return ['#1a1a2e', '#2d1b4e', '#4a1942', '#1f1f3a'];
    }
  }, [variant]);

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={gradientColors}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={StyleSheet.absoluteFill}
      />
      
      {/* Render orbs first (behind particles) */}
      {fireflies
        .filter((f) => f.type === 'orb')
        .map((config) => (
          <Firefly key={config.id} config={config} />
        ))}
      
      {/* Render particles on top */}
      {fireflies
        .filter((f) => f.type !== 'orb')
        .map((config) => (
          <Firefly key={config.id} config={config} />
        ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
    overflow: 'hidden',
  },
  firefly: {
    position: 'absolute',
  },
});

export default FireflyBackground;
