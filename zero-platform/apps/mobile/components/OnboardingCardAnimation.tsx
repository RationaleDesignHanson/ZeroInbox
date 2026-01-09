/**
 * OnboardingCardAnimation - Animated card gesture demo
 * Port of iOS OnboardingCardAnimation
 * 
 * Shows all 4 swipe directions in a cycle:
 * - Right: "Take Action" (green)
 * - Left: "Mark as Read" (blue)
 * - Down: "Snooze" (purple)
 * - Up: "Choose Action" (orange)
 */

import React, { useEffect, useState, useCallback } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  withDelay,
  withSequence,
  runOnJS,
  Easing,
} from 'react-native-reanimated';

// Direction configuration matching iOS exactly
type HintDirection = 'right' | 'left' | 'down' | 'up';

interface DirectionConfig {
  icon: keyof typeof Ionicons.glyphMap;
  color: string;
  label: string;
  offsetX: number;
  offsetY: number;
  iconOffsetX: number;
  iconOffsetY: number;
}

const DIRECTION_CONFIGS: Record<HintDirection, DirectionConfig> = {
  right: {
    icon: 'arrow-forward-circle',
    color: '#22c55e', // Green
    label: 'Take Action',
    offsetX: 45,
    offsetY: 0,
    iconOffsetX: 90,
    iconOffsetY: 0,
  },
  left: {
    icon: 'checkmark-circle',
    color: '#3b82f6', // Blue
    label: 'Mark as Read',
    offsetX: -45,
    offsetY: 0,
    iconOffsetX: -90,
    iconOffsetY: 0,
  },
  down: {
    icon: 'time',
    color: '#a855f7', // Purple
    label: 'Snooze',
    offsetX: 0,
    offsetY: 20,
    iconOffsetX: 0,
    iconOffsetY: 55,
  },
  up: {
    icon: 'sync-circle',
    color: '#f97316', // Orange
    label: 'Choose Action',
    offsetX: 0,
    offsetY: -20,
    iconOffsetX: 0,
    iconOffsetY: -55,
  },
};

const DIRECTIONS: HintDirection[] = ['right', 'left', 'down', 'up'];

// Animation timing matching iOS (1.4s hold at peak, 1.9s total cycle)
const PHASE_1_DURATION = 600; // Card moves + icon scales up
const HOLD_DURATION = 800;    // Hold at peak
const PHASE_3_DURATION = 500; // Return to center
const TOTAL_CYCLE = 1900;     // Total time per direction

export function OnboardingCardAnimation() {
  const [currentDirectionIndex, setCurrentDirectionIndex] = useState(0);
  
  // Shared values for animations
  const cardOffsetX = useSharedValue(0);
  const cardOffsetY = useSharedValue(0);
  const iconScale = useSharedValue(0.5);
  const iconOpacity = useSharedValue(0.3);
  const labelOpacity = useSharedValue(0);

  const currentDirection = DIRECTIONS[currentDirectionIndex];
  const config = DIRECTION_CONFIGS[currentDirection];

  const advanceDirection = useCallback(() => {
    setCurrentDirectionIndex((prev) => (prev + 1) % DIRECTIONS.length);
  }, []);

  // Run animation cycle
  useEffect(() => {
    const runCycle = () => {
      const cfg = DIRECTION_CONFIGS[DIRECTIONS[currentDirectionIndex]];

      // Phase 1: Card moves + icon scales up (0.6s)
      cardOffsetX.value = withSpring(cfg.offsetX, {
        damping: 12,
        stiffness: 100,
      });
      cardOffsetY.value = withSpring(cfg.offsetY, {
        damping: 12,
        stiffness: 100,
      });
      iconScale.value = withSpring(1.3, {
        damping: 10,
        stiffness: 80,
      });
      iconOpacity.value = withTiming(1, {
        duration: PHASE_1_DURATION,
        easing: Easing.out(Easing.ease),
      });
      labelOpacity.value = withTiming(1, {
        duration: PHASE_1_DURATION,
        easing: Easing.out(Easing.ease),
      });

      // Phase 2 + 3: After hold, return to center
      const returnDelay = PHASE_1_DURATION + HOLD_DURATION;
      
      cardOffsetX.value = withDelay(returnDelay, withSpring(0, {
        damping: 15,
        stiffness: 100,
      }));
      cardOffsetY.value = withDelay(returnDelay, withSpring(0, {
        damping: 15,
        stiffness: 100,
      }));
      iconScale.value = withDelay(returnDelay, withTiming(0.5, {
        duration: PHASE_3_DURATION,
        easing: Easing.inOut(Easing.ease),
      }));
      iconOpacity.value = withDelay(returnDelay, withTiming(0.3, {
        duration: PHASE_3_DURATION,
        easing: Easing.inOut(Easing.ease),
      }));
      labelOpacity.value = withDelay(returnDelay, withTiming(0, {
        duration: PHASE_3_DURATION,
        easing: Easing.inOut(Easing.ease),
      }));
    };

    runCycle();

    // Schedule next direction
    const timeout = setTimeout(() => {
      advanceDirection();
    }, TOTAL_CYCLE);

    return () => clearTimeout(timeout);
  }, [currentDirectionIndex, advanceDirection]);

  // Animated styles
  const cardAnimatedStyle = useAnimatedStyle(() => ({
    transform: [
      { translateX: cardOffsetX.value },
      { translateY: cardOffsetY.value },
    ],
  }));

  const iconAnimatedStyle = useAnimatedStyle(() => ({
    opacity: iconOpacity.value,
    transform: [{ scale: iconScale.value }],
  }));

  const labelAnimatedStyle = useAnimatedStyle(() => ({
    opacity: labelOpacity.value,
  }));

  return (
    <View style={styles.container}>
      {/* Background card simulation */}
      <Animated.View style={[styles.card, cardAnimatedStyle]}>
        <View style={styles.cardContent}>
          <View style={styles.cardLine1} />
          <View style={styles.cardLine2} />
          <View style={styles.cardLine3} />
        </View>
      </Animated.View>

      {/* Action icon and label */}
      <Animated.View
        style={[
          styles.iconContainer,
          {
            left: 120 + config.iconOffsetX - 30,
            top: 65 + config.iconOffsetY - 30,
          },
          iconAnimatedStyle,
        ]}
      >
        <Ionicons
          name={config.icon}
          size={30}
          color="white"
        />
      </Animated.View>

      {/* Label pill */}
      <Animated.View
        style={[
          styles.labelContainer,
          {
            left: 120 + config.iconOffsetX - 50,
            top: 65 + config.iconOffsetY + 20,
          },
          labelAnimatedStyle,
        ]}
      >
        <View style={[styles.labelPill, { backgroundColor: 'white' }]}>
          <Text style={[styles.labelText, { color: config.color }]}>
            {config.label}
          </Text>
        </View>
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: 240,
    height: 130,
    alignItems: 'center',
    justifyContent: 'center',
  },
  card: {
    width: 150,
    height: 90,
    borderRadius: 16,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.2)',
    alignItems: 'center',
    justifyContent: 'center',
    position: 'absolute',
    left: 45,
    top: 20,
  },
  cardContent: {
    alignItems: 'center',
    gap: 6,
  },
  cardLine1: {
    width: 105,
    height: 10,
    borderRadius: 4,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
  cardLine2: {
    width: 120,
    height: 6,
    borderRadius: 3,
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
  },
  cardLine3: {
    width: 105,
    height: 6,
    borderRadius: 3,
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
  },
  iconContainer: {
    position: 'absolute',
    width: 60,
    height: 60,
    alignItems: 'center',
    justifyContent: 'center',
  },
  labelContainer: {
    position: 'absolute',
    width: 100,
    alignItems: 'center',
  },
  labelPill: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
  },
  labelText: {
    fontSize: 12,
    fontWeight: '700',
  },
});

export default OnboardingCardAnimation;
