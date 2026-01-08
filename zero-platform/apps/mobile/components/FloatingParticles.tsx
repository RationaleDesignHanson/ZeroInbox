/**
 * FloatingParticles - Ambient floating particles for backgrounds
 * Creates subtle animated white dots that drift across the screen
 * Matches iOS SplashView.swift implementation
 */

import React, { useEffect, useMemo } from 'react';
import { View, StyleSheet, Dimensions } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withTiming,
  withDelay,
  Easing,
} from 'react-native-reanimated';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');

interface FloatingParticlesProps {
  particleCount?: number;
  particleSize?: number;
  speed?: number;
}

interface Particle {
  id: number;
  initialX: number;
  initialY: number;
  targetX: number;
  targetY: number;
  opacity: number;
  delay: number;
  duration: number;
}

function ParticleView({ particle, size }: { particle: Particle; size: number }) {
  const translateX = useSharedValue(particle.initialX);
  const translateY = useSharedValue(particle.initialY);

  useEffect(() => {
    translateX.value = withDelay(
      particle.delay,
      withRepeat(
        withTiming(particle.targetX, {
          duration: particle.duration,
          easing: Easing.inOut(Easing.ease),
        }),
        -1,
        true
      )
    );
    translateY.value = withDelay(
      particle.delay,
      withRepeat(
        withTiming(particle.targetY, {
          duration: particle.duration,
          easing: Easing.inOut(Easing.ease),
        }),
        -1,
        true
      )
    );
  }, [translateX, translateY, particle]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [
      { translateX: translateX.value },
      { translateY: translateY.value },
    ],
  }));

  return (
    <Animated.View
      style={[
        styles.particle,
        animatedStyle,
        {
          width: size,
          height: size,
          borderRadius: size / 2,
          opacity: particle.opacity,
        },
      ]}
    />
  );
}

export function FloatingParticles({
  particleCount = 20,
  particleSize = 4,
  speed = 3,
}: FloatingParticlesProps) {
  const particles = useMemo<Particle[]>(() => {
    return Array.from({ length: particleCount }, (_, i) => ({
      id: i,
      initialX: Math.random() * SCREEN_WIDTH - SCREEN_WIDTH / 2,
      initialY: Math.random() * SCREEN_HEIGHT - SCREEN_HEIGHT / 2,
      targetX: Math.random() * SCREEN_WIDTH - SCREEN_WIDTH / 2,
      targetY: Math.random() * SCREEN_HEIGHT - SCREEN_HEIGHT / 2,
      opacity: Math.random() * 0.2 + 0.1,
      delay: i * 100,
      duration: (speed + Math.random() * 2 - 1) * 1000,
    }));
  }, [particleCount, speed]);

  return (
    <View style={styles.container} pointerEvents="none">
      {particles.map((particle) => (
        <ParticleView key={particle.id} particle={particle} size={particleSize} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
    alignItems: 'center',
    justifyContent: 'center',
  },
  particle: {
    position: 'absolute',
    backgroundColor: 'white',
  },
});

