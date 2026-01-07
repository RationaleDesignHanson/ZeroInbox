/**
 * SwipeOverlay - Visual feedback during card swipes
 * Shows action indicator (Archive, Action, Snooze, etc.)
 */

import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

export type SwipeDirection = 'left' | 'right' | 'up' | 'down';

interface SwipeOverlayProps {
  direction: SwipeDirection;
  distance: number;
}

const SWIPE_CONFIG: Record<SwipeDirection, {
  icon: keyof typeof Ionicons.glyphMap;
  label: string;
  color: string;
  backgroundColor: string;
}> = {
  left: {
    icon: 'archive',
    label: 'Archive',
    color: '#fff',
    backgroundColor: 'rgba(102, 126, 234, 0.9)',
  },
  right: {
    icon: 'flash',
    label: 'Action',
    color: '#fff',
    backgroundColor: 'rgba(34, 197, 94, 0.9)',
  },
  up: {
    icon: 'apps',
    label: 'More',
    color: '#fff',
    backgroundColor: 'rgba(168, 85, 247, 0.9)',
  },
  down: {
    icon: 'time',
    label: 'Snooze',
    color: '#fff',
    backgroundColor: 'rgba(234, 179, 8, 0.9)',
  },
};

export function SwipeOverlay({ direction, distance }: SwipeOverlayProps) {
  const config = SWIPE_CONFIG[direction];
  const progress = Math.min(distance / 150, 1);
  const opacity = 0.5 + progress * 0.5;
  const scale = 0.8 + progress * 0.2;

  return (
    <View style={[styles.overlay, { backgroundColor: config.backgroundColor, opacity }]}>
      <View style={[styles.content, { transform: [{ scale }] }]}>
        <Ionicons name={config.icon} size={48} color={config.color} />
        <Text style={styles.label}>{config.label}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  overlay: {
    ...StyleSheet.absoluteFillObject,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 24,
  },
  content: {
    alignItems: 'center',
    gap: 8,
  },
  label: {
    fontSize: 18,
    fontWeight: '700',
    color: '#fff',
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
});

