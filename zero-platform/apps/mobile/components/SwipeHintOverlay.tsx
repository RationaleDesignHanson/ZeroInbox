/**
 * SwipeHintOverlay - First-time user tutorial for swipe gestures
 */

import React, { useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  Animated,
  Dimensions,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

interface SwipeHintOverlayProps {
  visible: boolean;
  onDismiss: () => void;
}

const HINTS = [
  { direction: 'left', icon: 'arrow-back', label: 'Swipe left to archive', color: '#667eea' },
  { direction: 'right', icon: 'arrow-forward', label: 'Swipe right to take action', color: '#22c55e' },
  { direction: 'up', icon: 'arrow-up', label: 'Swipe up for more options', color: '#a855f7' },
  { direction: 'down', icon: 'arrow-down', label: 'Swipe down to snooze', color: '#eab308' },
];

export function SwipeHintOverlay({ visible, onDismiss }: SwipeHintOverlayProps) {
  const opacity = useRef(new Animated.Value(0)).current;
  const scale = useRef(new Animated.Value(0.9)).current;

  useEffect(() => {
    if (visible) {
      Animated.parallel([
        Animated.timing(opacity, {
          toValue: 1,
          duration: 300,
          useNativeDriver: true,
        }),
        Animated.spring(scale, {
          toValue: 1,
          friction: 8,
          tension: 100,
          useNativeDriver: true,
        }),
      ]).start();
    } else {
      Animated.parallel([
        Animated.timing(opacity, {
          toValue: 0,
          duration: 200,
          useNativeDriver: true,
        }),
        Animated.timing(scale, {
          toValue: 0.9,
          duration: 200,
          useNativeDriver: true,
        }),
      ]).start();
    }
  }, [visible, opacity, scale]);

  if (!visible) return null;

  return (
    <Animated.View style={[styles.overlay, { opacity }]}>
      <Pressable style={styles.backdrop} onPress={onDismiss} />

      <Animated.View style={[styles.content, { transform: [{ scale }] }]}>
        <Text style={styles.title}>Swipe to manage emails</Text>
        <Text style={styles.subtitle}>Quick gestures for fast email processing</Text>

        <View style={styles.hintsContainer}>
          {HINTS.map((hint) => (
            <View key={hint.direction} style={styles.hintRow}>
              <View style={[styles.iconContainer, { backgroundColor: hint.color + '30' }]}>
                <Ionicons
                  name={hint.icon as keyof typeof Ionicons.glyphMap}
                  size={24}
                  color={hint.color}
                />
              </View>
              <Text style={styles.hintText}>{hint.label}</Text>
            </View>
          ))}
        </View>

        <Pressable style={styles.gotItButton} onPress={onDismiss}>
          <Text style={styles.gotItText}>Got it!</Text>
        </Pressable>
      </Animated.View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  overlay: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 2000,
  },
  backdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
  },
  content: {
    backgroundColor: 'rgba(30, 30, 45, 0.98)',
    borderRadius: 24,
    padding: 28,
    width: SCREEN_WIDTH - 48,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: 'white',
    textAlign: 'center',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 15,
    color: 'rgba(255, 255, 255, 0.6)',
    textAlign: 'center',
    marginBottom: 24,
  },
  hintsContainer: {
    gap: 16,
  },
  hintRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
  },
  iconContainer: {
    width: 48,
    height: 48,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  hintText: {
    fontSize: 16,
    color: 'white',
    flex: 1,
  },
  gotItButton: {
    backgroundColor: '#667eea',
    paddingVertical: 14,
    borderRadius: 14,
    marginTop: 24,
    alignItems: 'center',
  },
  gotItText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
});

