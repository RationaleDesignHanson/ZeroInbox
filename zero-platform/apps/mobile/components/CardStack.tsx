/**
 * CardStack - Tinder-style card stack with swipe gestures
 * Supports left (archive), right (action), up (more), down (snooze)
 */

import React, { useCallback } from 'react';
import { View, StyleSheet, Dimensions, Pressable } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  runOnJS,
  interpolate,
  Extrapolation,
} from 'react-native-reanimated';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import type { EmailCard as EmailCardType } from '@zero/types';
import { SwipeableCard } from './SwipeableCard';
import { SwipeOverlay, type SwipeDirection } from './SwipeOverlay';
import { HapticService } from '../services/HapticService';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');

const SWIPE_THRESHOLD = 120;
const SWIPE_VELOCITY_THRESHOLD = 500;
const HAPTIC_THRESHOLD = 60;

interface CardStackProps {
  cards: EmailCardType[];
  currentIndex: number;
  onSwipeLeft: (card: EmailCardType) => void;
  onSwipeRight: (card: EmailCardType) => void;
  onSwipeUp: (card: EmailCardType) => void;
  onSwipeDown: (card: EmailCardType) => void;
  onCardPress: (card: EmailCardType) => void;
  onIndexChange: (index: number) => void;
  renderEmpty?: () => React.ReactNode;
}

export function CardStack({
  cards,
  currentIndex,
  onSwipeLeft,
  onSwipeRight,
  onSwipeUp,
  onSwipeDown,
  onCardPress,
  onIndexChange,
  renderEmpty,
}: CardStackProps) {
  const translateX = useSharedValue(0);
  const translateY = useSharedValue(0);
  const hapticTriggered = useSharedValue(false);

  // Get current swipe direction for overlay
  const getSwipeDirection = useCallback((x: number, y: number): SwipeDirection | null => {
    const absX = Math.abs(x);
    const absY = Math.abs(y);
    const isHorizontal = absX > absY;
    const distance = isHorizontal ? absX : absY;

    if (distance < 50) return null;

    if (isHorizontal) {
      return x > 0 ? 'right' : 'left';
    } else {
      return y > 0 ? 'down' : 'up';
    }
  }, []);

  const handleSwipeComplete = useCallback((direction: SwipeDirection, card: EmailCardType) => {
    HapticService.heavyImpact();
    
    switch (direction) {
      case 'left':
        onSwipeLeft(card);
        break;
      case 'right':
        onSwipeRight(card);
        break;
      case 'up':
        onSwipeUp(card);
        break;
      case 'down':
        onSwipeDown(card);
        break;
    }
  }, [onSwipeLeft, onSwipeRight, onSwipeUp, onSwipeDown]);

  const resetPosition = useCallback(() => {
    translateX.value = withSpring(0, {
      damping: 15,
      stiffness: 150,
    });
    translateY.value = withSpring(0, {
      damping: 15,
      stiffness: 150,
    });
  }, [translateX, translateY]);

  // Render visible cards (top 3)
  const visibleCards = cards.slice(currentIndex, currentIndex + 3);

  if (visibleCards.length === 0) {
    return (
      <View style={styles.container}>
        {renderEmpty?.()}
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {visibleCards.map((card, index) => {
        const isTopCard = index === 0;
        const offset = index;

        return (
          <CardItem
            key={card.id}
            card={card}
            index={offset}
            isTopCard={isTopCard}
            translateX={translateX}
            translateY={translateY}
            hapticTriggered={hapticTriggered}
            getSwipeDirection={getSwipeDirection}
            handleSwipeComplete={handleSwipeComplete}
            resetPosition={resetPosition}
            onCardPress={onCardPress}
          />
        );
      }).reverse()}
    </View>
  );
}

interface CardItemProps {
  card: EmailCardType;
  index: number;
  isTopCard: boolean;
  translateX: Animated.SharedValue<number>;
  translateY: Animated.SharedValue<number>;
  hapticTriggered: Animated.SharedValue<boolean>;
  getSwipeDirection: (x: number, y: number) => SwipeDirection | null;
  handleSwipeComplete: (direction: SwipeDirection, card: EmailCardType) => void;
  resetPosition: () => void;
  onCardPress: (card: EmailCardType) => void;
}

function CardItem({
  card,
  index,
  isTopCard,
  translateX,
  translateY,
  hapticTriggered,
  getSwipeDirection,
  handleSwipeComplete,
  resetPosition,
  onCardPress,
}: CardItemProps) {
  // Animated styles for this card
  const animatedStyle = useAnimatedStyle(() => {
    if (!isTopCard) {
      // Background cards: scale and offset
      const scale = interpolate(index, [0, 1, 2], [1, 0.95, 0.9], Extrapolation.CLAMP);
      const offsetY = interpolate(index, [0, 1, 2], [0, 20, 40], Extrapolation.CLAMP);
      // Fixed opacity for background cards (matching iOS: 0.85 minimum)
      const opacity = interpolate(index, [0, 1, 2], [1, 0.85, 0.7], Extrapolation.CLAMP);

      return {
        transform: [{ scale }, { translateY: offsetY }],
        opacity,
        zIndex: 3 - index,
      };
    }

    // Top card: follows gesture
    const rotateZ = interpolate(
      translateX.value,
      [-SCREEN_WIDTH / 2, 0, SCREEN_WIDTH / 2],
      [-15, 0, 15],
      Extrapolation.CLAMP
    );

    return {
      transform: [
        { translateX: translateX.value },
        { translateY: translateY.value },
        { rotateZ: `${rotateZ}deg` },
      ],
      opacity: 1,
      zIndex: 10,
    };
  });

  // Overlay animated style
  const overlayStyle = useAnimatedStyle(() => {
    if (!isTopCard) return { opacity: 0 };

    const absX = Math.abs(translateX.value);
    const absY = Math.abs(translateY.value);
    const distance = Math.max(absX, absY);
    const opacity = interpolate(distance, [50, 150], [0, 1], Extrapolation.CLAMP);

    return { opacity };
  });

  // Pan gesture for top card only
  const panGesture = Gesture.Pan()
    .enabled(isTopCard)
    .onUpdate((event) => {
      translateX.value = event.translationX;
      translateY.value = event.translationY;

      // Haptic feedback at threshold
      const absX = Math.abs(event.translationX);
      const absY = Math.abs(event.translationY);
      const distance = Math.max(absX, absY);

      if (distance > HAPTIC_THRESHOLD && !hapticTriggered.value) {
        hapticTriggered.value = true;
        runOnJS(HapticService.mediumImpact)();
      }
      if (distance < HAPTIC_THRESHOLD) {
        hapticTriggered.value = false;
      }
    })
    .onEnd((event) => {
      const absX = Math.abs(event.translationX);
      const absY = Math.abs(event.translationY);
      const velocityX = Math.abs(event.velocityX);
      const velocityY = Math.abs(event.velocityY);

      const isHorizontal = absX > absY;
      const distance = isHorizontal ? absX : absY;
      const velocity = isHorizontal ? velocityX : velocityY;

      const shouldComplete = distance > SWIPE_THRESHOLD || velocity > SWIPE_VELOCITY_THRESHOLD;

      if (shouldComplete) {
        // Determine direction
        let direction: SwipeDirection;
        if (isHorizontal) {
          direction = event.translationX > 0 ? 'right' : 'left';
        } else {
          direction = event.translationY > 0 ? 'down' : 'up';
        }

        // Animate off screen
        const targetX = isHorizontal
          ? (direction === 'right' ? SCREEN_WIDTH * 1.5 : -SCREEN_WIDTH * 1.5)
          : 0;
        const targetY = !isHorizontal
          ? (direction === 'down' ? SCREEN_HEIGHT * 1.5 : -SCREEN_HEIGHT * 1.5)
          : 0;

        translateX.value = withTiming(targetX, { duration: 300 }, () => {
          translateX.value = 0;
        });
        translateY.value = withTiming(targetY, { duration: 300 }, () => {
          translateY.value = 0;
          runOnJS(handleSwipeComplete)(direction, card);
        });
      } else {
        // Snap back
        runOnJS(resetPosition)();
      }

      hapticTriggered.value = false;
    });

  // Tap gesture for card press
  const tapGesture = Gesture.Tap()
    .enabled(isTopCard)
    .onEnd(() => {
      runOnJS(onCardPress)(card);
    });

  // Combine gestures - pan takes priority
  const combinedGesture = Gesture.Exclusive(panGesture, tapGesture);

  // Calculate current direction for overlay
  const direction = getSwipeDirection(translateX.value, translateY.value);

  return (
    <Animated.View style={[styles.cardContainer, animatedStyle]}>
      <GestureDetector gesture={combinedGesture}>
        <Animated.View style={styles.cardInner}>
          <SwipeableCard card={card} />
          {/* Swipe overlay */}
          {isTopCard && direction && (
            <Animated.View style={[styles.overlay, overlayStyle]}>
              <SwipeOverlay
                direction={direction}
                distance={Math.max(Math.abs(translateX.value), Math.abs(translateY.value))}
              />
            </Animated.View>
          )}
        </Animated.View>
      </GestureDetector>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  cardContainer: {
    position: 'absolute',
    width: SCREEN_WIDTH - 32,
    aspectRatio: 0.7,
  },
  cardInner: {
    flex: 1,
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    borderRadius: 24,
    overflow: 'hidden',
  },
});

