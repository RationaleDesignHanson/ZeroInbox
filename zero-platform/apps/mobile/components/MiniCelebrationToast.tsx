/**
 * MiniCelebrationToast - Small toast notification for section cleared
 * Features mini confetti burst and slide-up animation
 */

import React, { useEffect, useRef, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Animated,
  Dimensions,
  Easing,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { HapticService } from '../services/HapticService';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

type CardType = 'mail' | 'ads';

interface MiniCelebrationToastProps {
  archetype: CardType;
  onDismiss: () => void;
}

interface ConfettiParticle {
  id: number;
  angle: number;
  velocity: number;
  size: number;
  color: string;
}

const CONFETTI_COLORS = ['#FFD700', '#32CD32', '#00BFFF', '#FF69B4', '#8A2BE2'];

const generateMiniConfetti = (count: number): ConfettiParticle[] => {
  return Array.from({ length: count }, (_, i) => ({
    id: i,
    angle: (i / count) * 360 + Math.random() * 20,
    velocity: 40 + Math.random() * 60,
    size: 4 + Math.random() * 4,
    color: CONFETTI_COLORS[Math.floor(Math.random() * CONFETTI_COLORS.length)],
  }));
};

function MiniConfettiParticle({
  particle,
  animatedValue,
}: {
  particle: ConfettiParticle;
  animatedValue: Animated.Value;
}) {
  const style = {
    width: particle.size,
    height: particle.size,
    borderRadius: particle.size / 2,
    backgroundColor: particle.color,
    position: 'absolute' as const,
    left: '50%' as any,
    top: '50%' as any,
    marginLeft: -particle.size / 2,
    marginTop: -particle.size / 2,
    transform: [
      {
        translateX: animatedValue.interpolate({
          inputRange: [0, 1],
          outputRange: [0, Math.cos((particle.angle * Math.PI) / 180) * particle.velocity],
        }),
      },
      {
        translateY: animatedValue.interpolate({
          inputRange: [0, 1],
          outputRange: [0, Math.sin((particle.angle * Math.PI) / 180) * particle.velocity],
        }),
      },
      {
        scale: animatedValue.interpolate({
          inputRange: [0, 0.5, 1],
          outputRange: [0, 1.3, 0.5],
        }),
      },
    ],
    opacity: animatedValue.interpolate({
      inputRange: [0, 0.6, 1],
      outputRange: [1, 0.8, 0],
    }),
  };

  return <Animated.View style={style} />;
}

export function MiniCelebrationToast({ archetype, onDismiss }: MiniCelebrationToastProps) {
  const scaleAnim = useRef(new Animated.Value(0.5)).current;
  const opacityAnim = useRef(new Animated.Value(0)).current;
  const translateYAnim = useRef(new Animated.Value(100)).current;
  const confettiAnim = useRef(new Animated.Value(0)).current;

  const confettiParticles = useMemo(() => generateMiniConfetti(20), []);

  useEffect(() => {
    // Trigger haptic
    HapticService.mediumImpact();

    // Confetti burst
    Animated.timing(confettiAnim, {
      toValue: 1,
      duration: 1500,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start();

    // Toast slide up and scale in
    Animated.parallel([
      Animated.spring(scaleAnim, {
        toValue: 1,
        friction: 7,
        tension: 100,
        useNativeDriver: true,
      }),
      Animated.timing(opacityAnim, {
        toValue: 1,
        duration: 300,
        easing: Easing.ease,
        useNativeDriver: true,
      }),
      Animated.spring(translateYAnim, {
        toValue: 0,
        friction: 7,
        tension: 100,
        useNativeDriver: true,
      }),
    ]).start();

    // Auto-dismiss after 2.5 seconds
    const timer = setTimeout(() => {
      Animated.parallel([
        Animated.timing(opacityAnim, {
          toValue: 0,
          duration: 300,
          useNativeDriver: true,
        }),
        Animated.timing(translateYAnim, {
          toValue: -50,
          duration: 300,
          useNativeDriver: true,
        }),
      ]).start(() => onDismiss());
    }, 2500);

    return () => clearTimeout(timer);
  }, [scaleAnim, opacityAnim, translateYAnim, confettiAnim, onDismiss]);

  const displayName = archetype === 'mail' ? 'Mail' : 'Ads';

  return (
    <Animated.View
      style={[
        styles.container,
        {
          opacity: opacityAnim,
          transform: [{ translateY: translateYAnim }, { scale: scaleAnim }],
        },
      ]}
    >
      {/* Confetti particles */}
      <View style={styles.confettiContainer}>
        {confettiParticles.map((particle) => (
          <MiniConfettiParticle key={particle.id} particle={particle} animatedValue={confettiAnim} />
        ))}
      </View>

      {/* Toast background */}
      <View style={styles.toastBackground}>
        <LinearGradient
          colors={['rgba(30, 30, 40, 0.95)', 'rgba(20, 20, 30, 0.95)']}
          style={StyleSheet.absoluteFill}
        />
        <View style={styles.borderGradient} />

        {/* Content */}
        <View style={styles.content}>
          <Ionicons name="checkmark-circle" size={32} color="#32CD32" />
          <View style={styles.textContainer}>
            <Text style={styles.title}>Nice work!</Text>
            <Text style={styles.subtitle}>{displayName} cleared!</Text>
          </View>
        </View>
      </View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    bottom: 100,
    alignSelf: 'center',
    zIndex: 1001,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.4,
    shadowRadius: 20,
    elevation: 10,
  },
  confettiContainer: {
    ...StyleSheet.absoluteFillObject,
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 1,
  },
  toastBackground: {
    borderRadius: 20,
    overflow: 'hidden',
    maxWidth: SCREEN_WIDTH - 48,
  },
  borderGradient: {
    ...StyleSheet.absoluteFillObject,
    borderRadius: 20,
    borderWidth: 2,
    borderColor: 'transparent',
    borderTopColor: 'rgba(50, 205, 50, 0.4)',
    borderLeftColor: 'rgba(50, 205, 50, 0.2)',
    borderRightColor: 'rgba(0, 191, 255, 0.2)',
    borderBottomColor: 'rgba(0, 191, 255, 0.4)',
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    gap: 16,
  },
  textContainer: {
    flex: 1,
  },
  title: {
    fontSize: 17,
    fontWeight: '700',
    color: 'white',
  },
  subtitle: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    marginTop: 2,
  },
});


