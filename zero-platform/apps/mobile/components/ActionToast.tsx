/**
 * ActionToast - Simple toast for action feedback with optional undo
 */

import React, { useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  Animated,
  Platform,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { HapticService } from '../services/HapticService';

interface ActionToastProps {
  message: string;
  onUndo?: () => void;
  onDismiss: () => void;
  duration?: number;
}

export function ActionToast({
  message,
  onUndo,
  onDismiss,
  duration = 3000,
}: ActionToastProps) {
  const insets = useSafeAreaInsets();
  const translateY = useRef(new Animated.Value(100)).current;
  const opacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    // Slide in
    Animated.parallel([
      Animated.spring(translateY, {
        toValue: 0,
        friction: 8,
        tension: 100,
        useNativeDriver: true,
      }),
      Animated.timing(opacity, {
        toValue: 1,
        duration: 200,
        useNativeDriver: true,
      }),
    ]).start();

    // Auto dismiss
    const timer = setTimeout(() => {
      dismiss();
    }, duration);

    return () => clearTimeout(timer);
  }, [translateY, opacity, duration]);

  const dismiss = () => {
    Animated.parallel([
      Animated.timing(translateY, {
        toValue: 100,
        duration: 200,
        useNativeDriver: true,
      }),
      Animated.timing(opacity, {
        toValue: 0,
        duration: 200,
        useNativeDriver: true,
      }),
    ]).start(() => onDismiss());
  };

  const handleUndo = () => {
    HapticService.selection();
    onUndo?.();
    dismiss();
  };

  return (
    <Animated.View
      style={[
        styles.container,
        {
          bottom: insets.bottom + 120,
          transform: [{ translateY }],
          opacity,
        },
      ]}
    >
      <View style={styles.toast}>
        {Platform.OS === 'ios' ? (
          <BlurView intensity={60} tint="dark" style={StyleSheet.absoluteFill} />
        ) : (
          <View style={[StyleSheet.absoluteFill, styles.androidFallback]} />
        )}

        <View style={styles.content}>
          <Ionicons name="checkmark-circle" size={20} color="#22c55e" />
          <Text style={styles.message} numberOfLines={1}>
            {message}
          </Text>
          {onUndo && (
            <Pressable onPress={handleUndo} style={styles.undoButton}>
              <Text style={styles.undoText}>Undo</Text>
            </Pressable>
          )}
        </View>
      </View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    left: 16,
    right: 16,
    zIndex: 999,
  },
  toast: {
    borderRadius: 16,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  androidFallback: {
    backgroundColor: 'rgba(30, 30, 40, 0.95)',
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    gap: 10,
  },
  message: {
    flex: 1,
    fontSize: 15,
    fontWeight: '500',
    color: 'white',
  },
  undoButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: 'rgba(102, 126, 234, 0.2)',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(102, 126, 234, 0.3)',
  },
  undoText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#667eea',
  },
});


