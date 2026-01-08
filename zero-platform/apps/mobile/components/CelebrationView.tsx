/**
 * CelebrationView - Full-screen celebration for Inbox Zero
 * Features confetti explosion, scaling animations, and haptic feedback
 */

import React, { useEffect, useRef, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Animated,
  Dimensions,
  Easing,
  Pressable,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { HapticService } from '../services/HapticService';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');

type CardType = 'mail' | 'ads';

interface CelebrationViewProps {
  archetype: CardType;
  allArchetypesCleared: boolean;
  onContinue: () => void;
}

interface ConfettiParticle {
  id: number;
  angle: number;
  velocity: number;
  size: number;
  color: string;
  rotationSpeed: number;
}

const CONFETTI_COLORS = [
  '#FFD700', // Gold
  '#FF69B4', // Pink
  '#00BFFF', // Blue
  '#32CD32', // Green
  '#8A2BE2', // Purple
  '#FF8C00', // Orange
  '#FFFFFF', // White
];

const generateConfetti = (count: number): ConfettiParticle[] => {
  return Array.from({ length: count }, (_, i) => ({
    id: i,
    angle: (i / count) * 360 + Math.random() * 20,
    velocity: 150 + Math.random() * 250,
    size: 6 + Math.random() * 10,
    color: CONFETTI_COLORS[Math.floor(Math.random() * CONFETTI_COLORS.length)],
    rotationSpeed: Math.random() * 720,
  }));
};

function ConfettiParticle({ particle, animatedValue }: { particle: ConfettiParticle; animatedValue: Animated.Value }) {
  const style = {
    width: particle.size,
    height: particle.size,
    borderRadius: particle.size / 2,
    backgroundColor: particle.color,
    position: 'absolute' as const,
    left: SCREEN_WIDTH / 2,
    top: SCREEN_HEIGHT / 2,
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
          outputRange: [0, 1.2, 0.8],
        }),
      },
      {
        rotate: animatedValue.interpolate({
          inputRange: [0, 1],
          outputRange: ['0deg', `${particle.rotationSpeed}deg`],
        }),
      },
    ],
    opacity: animatedValue.interpolate({
      inputRange: [0, 0.7, 1],
      outputRange: [1, 1, 0],
    }),
  };

  return <Animated.View style={style} />;
}

export function CelebrationView({ archetype, allArchetypesCleared, onContinue }: CelebrationViewProps) {
  const scaleAnim = useRef(new Animated.Value(0.5)).current;
  const opacityAnim = useRef(new Animated.Value(0)).current;
  const confettiAnim = useRef(new Animated.Value(0)).current;

  const confettiCount = allArchetypesCleared ? 80 : 40;
  const confettiParticles = useMemo(() => generateConfetti(confettiCount), [confettiCount]);

  useEffect(() => {
    // Trigger haptic
    HapticService.success();

    // Scale in content with bouncy spring
    Animated.spring(scaleAnim, {
      toValue: 1,
      friction: 5,
      tension: 80,
      useNativeDriver: true,
    }).start();

    // Fade in
    Animated.timing(opacityAnim, {
      toValue: 1,
      duration: 400,
      easing: Easing.out(Easing.ease),
      useNativeDriver: true,
    }).start();

    // Confetti explosion
    Animated.timing(confettiAnim, {
      toValue: 1,
      duration: 2500,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start();
  }, [scaleAnim, opacityAnim, confettiAnim]);

  const gradientColors = allArchetypesCleared
    ? ['#FFD700', '#FF69B4', '#00BFFF'] // Gold → Pink → Blue for total
    : ['#667eea', '#764ba2', '#ec4899']; // Purple-blue for single

  const iconName = allArchetypesCleared ? 'trophy' : 'checkmark-circle';
  const iconColor = allArchetypesCleared ? '#FFD700' : '#32CD32';
  const iconSize = allArchetypesCleared ? 120 : 100;
  const titleSize = allArchetypesCleared ? 48 : 42;
  const mainTitle = allArchetypesCleared ? 'Total Inbox Zero!' : 'Inbox Zero!';
  const subTitle = allArchetypesCleared
    ? 'All Categories Cleared!'
    : `${archetype === 'mail' ? 'Mail' : 'Ads'} Cleared!`;

  return (
    <View style={styles.overlay}>
      <LinearGradient
        colors={gradientColors}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={StyleSheet.absoluteFill}
      />

      {/* Confetti particles */}
      {confettiParticles.map((particle) => (
        <ConfettiParticle key={particle.id} particle={particle} animatedValue={confettiAnim} />
      ))}

      {/* Content */}
      <Animated.View
        style={[
          styles.content,
          {
            transform: [{ scale: scaleAnim }],
            opacity: opacityAnim,
          },
        ]}
      >
        {/* Icon with shadow */}
        <View style={styles.iconContainer}>
          <Ionicons name={iconName} size={iconSize} color={iconColor} />
        </View>

        {/* Titles */}
        <Text style={[styles.mainTitle, { fontSize: titleSize }]}>{mainTitle}</Text>
        <Text style={styles.subTitle}>{subTitle}</Text>

        {/* Continue button */}
        <Pressable style={styles.continueButton} onPress={onContinue}>
          <Text style={styles.continueButtonText}>Continue</Text>
          <Ionicons name="arrow-forward" size={18} color="#fff" />
        </Pressable>
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  overlay: {
    ...StyleSheet.absoluteFillObject,
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 1000,
  },
  content: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  iconContainer: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.3,
    shadowRadius: 20,
    marginBottom: 24,
  },
  mainTitle: {
    fontWeight: '800',
    color: 'white',
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.3)',
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 8,
    marginBottom: 8,
  },
  subTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: 'rgba(255, 255, 255, 0.85)',
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.2)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 4,
  },
  continueButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    paddingHorizontal: 28,
    paddingVertical: 14,
    borderRadius: 28,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    marginTop: 40,
    gap: 8,
  },
  continueButtonText: {
    fontSize: 17,
    fontWeight: '600',
    color: 'white',
  },
});


