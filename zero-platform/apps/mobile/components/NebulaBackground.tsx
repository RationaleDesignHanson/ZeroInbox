/**
 * NebulaBackground - Animated cosmic background for mail cards
 * Features floating particle orbs with glow and subtle parallax
 */

import React, { useEffect, useRef, useMemo } from 'react';
import { View, StyleSheet, Animated, Dimensions, Easing } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');

type ParticleSize = 'small' | 'medium' | 'large';

interface Particle {
  id: number;
  size: ParticleSize;
  x: number;
  y: number;
  opacity: number;
  color: string;
  duration: number;
}

const PARTICLE_SIZES = {
  small: 4,
  medium: 8,
  large: 14,
};

const COLORS = [
  'rgba(102, 126, 234, 0.6)', // Primary blue
  'rgba(118, 75, 162, 0.5)',  // Purple
  'rgba(236, 72, 153, 0.4)',  // Pink
  'rgba(79, 209, 197, 0.3)',  // Teal
  'rgba(255, 255, 255, 0.2)', // White stars
];

const generateParticles = (count: number): Particle[] => {
  const sizes: ParticleSize[] = ['small', 'medium', 'large'];
  
  return Array.from({ length: count }, (_, i) => ({
    id: i,
    size: sizes[Math.floor(Math.random() * sizes.length)],
    x: Math.random() * SCREEN_WIDTH,
    y: Math.random() * SCREEN_HEIGHT * 0.7,
    opacity: 0.3 + Math.random() * 0.5,
    color: COLORS[Math.floor(Math.random() * COLORS.length)],
    duration: 3000 + Math.random() * 4000,
  }));
};

function ParticleOrb({ particle, animated }: { particle: Particle; animated: boolean }) {
  const translateY = useRef(new Animated.Value(0)).current;
  const opacityAnim = useRef(new Animated.Value(particle.opacity)).current;

  useEffect(() => {
    if (!animated) return;

    // Floating animation
    const floatAnimation = Animated.loop(
      Animated.sequence([
        Animated.timing(translateY, {
          toValue: -20,
          duration: particle.duration,
          easing: Easing.inOut(Easing.sin),
          useNativeDriver: true,
        }),
        Animated.timing(translateY, {
          toValue: 20,
          duration: particle.duration,
          easing: Easing.inOut(Easing.sin),
          useNativeDriver: true,
        }),
      ])
    );

    // Pulse animation
    const pulseAnimation = Animated.loop(
      Animated.sequence([
        Animated.timing(opacityAnim, {
          toValue: particle.opacity * 0.5,
          duration: particle.duration * 0.8,
          easing: Easing.inOut(Easing.sin),
          useNativeDriver: true,
        }),
        Animated.timing(opacityAnim, {
          toValue: particle.opacity,
          duration: particle.duration * 0.8,
          easing: Easing.inOut(Easing.sin),
          useNativeDriver: true,
        }),
      ])
    );

    floatAnimation.start();
    pulseAnimation.start();

    return () => {
      floatAnimation.stop();
      pulseAnimation.stop();
    };
  }, [animated, particle.duration, particle.opacity, translateY, opacityAnim]);

  const size = PARTICLE_SIZES[particle.size];
  const glowSize = size * 3;

  return (
    <Animated.View
      style={[
        styles.particle,
        {
          left: particle.x,
          top: particle.y,
          transform: [{ translateY }],
        },
      ]}
    >
      {/* Outer glow */}
      <Animated.View
        style={[
          styles.particleGlow,
          {
            width: glowSize,
            height: glowSize,
            borderRadius: glowSize / 2,
            backgroundColor: particle.color,
            opacity: Animated.multiply(opacityAnim, new Animated.Value(0.3)),
          },
        ]}
      />
      {/* Core */}
      <Animated.View
        style={[
          styles.particleCore,
          {
            width: size,
            height: size,
            borderRadius: size / 2,
            backgroundColor: particle.color,
            opacity: opacityAnim,
          },
        ]}
      />
    </Animated.View>
  );
}

interface NebulaBackgroundProps {
  particleCount?: number;
  animated?: boolean;
}

export function NebulaBackground({ particleCount = 15, animated = true }: NebulaBackgroundProps) {
  const particles = useMemo(() => generateParticles(particleCount), [particleCount]);

  return (
    <View style={styles.container}>
      {/* Deep space gradient base */}
      <LinearGradient
        colors={['#0a0a1a', '#1a1a2e', '#16213e']}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={StyleSheet.absoluteFill}
      />

      {/* Purple nebula overlay */}
      <LinearGradient
        colors={['rgba(102, 126, 234, 0.1)', 'rgba(118, 75, 162, 0.05)', 'transparent']}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={StyleSheet.absoluteFill}
      />

      {/* Particles */}
      {particles.map((particle) => (
        <ParticleOrb key={particle.id} particle={particle} animated={animated} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
  },
  particle: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
  },
  particleGlow: {
    position: 'absolute',
  },
  particleCore: {},
});

