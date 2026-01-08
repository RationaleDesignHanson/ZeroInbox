/**
 * UndoToast - Toast notification with undo action
 * Used for archive, snooze, and other reversible actions
 */

import React, { useEffect, useRef, createContext, useContext, useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  Animated,
  Easing,
  Platform,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

interface ToastConfig {
  message: string;
  duration?: number;
  actionColor?: string;
  onUndo?: () => void;
  onComplete?: () => void;
}

interface ToastContextValue {
  showToast: (config: ToastConfig) => void;
  hideToast: () => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

export function useToast() {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToast must be used within ToastProvider');
  }
  return context;
}

interface ToastProviderProps {
  children: React.ReactNode;
}

export function ToastProvider({ children }: ToastProviderProps) {
  const [toast, setToast] = useState<ToastConfig | null>(null);

  const showToast = useCallback((config: ToastConfig) => {
    setToast(config);
  }, []);

  const hideToast = useCallback(() => {
    setToast(null);
  }, []);

  return (
    <ToastContext.Provider value={{ showToast, hideToast }}>
      {children}
      {toast && (
        <ToastNotification
          {...toast}
          onDismiss={() => {
            toast.onComplete?.();
            setToast(null);
          }}
          onUndo={() => {
            toast.onUndo?.();
            setToast(null);
          }}
        />
      )}
    </ToastContext.Provider>
  );
}

interface ToastNotificationProps extends ToastConfig {
  onDismiss: () => void;
  onUndo: () => void;
}

function ToastNotification({
  message,
  duration = 5,
  actionColor = '#667eea',
  onDismiss,
  onUndo,
}: ToastNotificationProps) {
  const insets = useSafeAreaInsets();
  const translateY = useRef(new Animated.Value(100)).current;
  const opacity = useRef(new Animated.Value(0)).current;
  const progress = useRef(new Animated.Value(0)).current;

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

    // Progress animation
    Animated.timing(progress, {
      toValue: 1,
      duration: duration * 1000,
      easing: Easing.linear,
      useNativeDriver: false,
    }).start(() => {
      // Auto dismiss
      dismissToast();
    });
  }, [translateY, opacity, progress, duration]);

  const dismissToast = () => {
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
    progress.stopAnimation();
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
    ]).start(() => onUndo());
  };

  return (
    <Animated.View
      style={[
        styles.container,
        {
          bottom: insets.bottom + 120, // Above bottom nav
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

        {/* Progress bar */}
        <View style={styles.progressContainer}>
          <Animated.View
            style={[
              styles.progressBar,
              {
                width: progress.interpolate({
                  inputRange: [0, 1],
                  outputRange: ['100%', '0%'],
                }),
                backgroundColor: actionColor,
              },
            ]}
          />
        </View>

        {/* Content */}
        <View style={styles.content}>
          <Text style={styles.message} numberOfLines={1}>
            {message}
          </Text>
          <Pressable onPress={handleUndo} style={styles.undoButton}>
            <Text style={[styles.undoText, { color: actionColor }]}>Undo</Text>
          </Pressable>
        </View>
      </View>
    </Animated.View>
  );
}

// Standalone container that uses context
export function ToastContainer() {
  // This is just a marker component - actual rendering is done in ToastProvider
  return null;
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
  progressContainer: {
    height: 3,
    backgroundColor: 'rgba(255,255,255,0.1)',
  },
  progressBar: {
    height: '100%',
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 14,
  },
  message: {
    flex: 1,
    fontSize: 15,
    color: 'white',
    marginRight: 12,
  },
  undoButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 8,
  },
  undoText: {
    fontSize: 14,
    fontWeight: '600',
  },
});


