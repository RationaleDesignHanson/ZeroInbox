/**
 * LiquidGlassBottomNav - Floating glassmorphic bottom navigation
 * Features mode toggle, progress bar, and quick actions
 */

import React, { useRef, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  Platform,
  Animated,
  Easing,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { HapticService } from '../services/HapticService';

interface LiquidGlassBottomNavProps {
  mode: 'mail' | 'ads';
  onModeChange: (mode: 'mail' | 'ads') => void;
  mailCount: number;
  adsCount: number;
  totalInitialCards: number;
  onSettingsPress: () => void;
  onSearchPress: () => void;
  onRefreshPress: () => void;
}

export function LiquidGlassBottomNav({
  mode,
  onModeChange,
  mailCount,
  adsCount,
  totalInitialCards,
  onSettingsPress,
  onSearchPress,
  onRefreshPress,
}: LiquidGlassBottomNavProps) {
  const insets = useSafeAreaInsets();
  const progressAnim = useRef(new Animated.Value(0)).current;

  const totalRemaining = mailCount + adsCount;
  const progress = totalInitialCards > 0
    ? ((totalInitialCards - totalRemaining) / totalInitialCards) * 100
    : 0;

  useEffect(() => {
    Animated.timing(progressAnim, {
      toValue: progress,
      duration: 500,
      easing: Easing.out(Easing.ease),
      useNativeDriver: false,
    }).start();
  }, [progress, progressAnim]);

  const handleModeToggle = (newMode: 'mail' | 'ads') => {
    if (newMode !== mode) {
      HapticService.selection();
      onModeChange(newMode);
    }
  };

  const isMail = mode === 'mail';
  const accentColor = isMail ? '#667eea' : '#eab308';

  return (
    <View style={[styles.container, { paddingBottom: insets.bottom + 8 }]}>
      {/* Main nav card */}
      <View style={styles.navCard}>
        {/* Blur background */}
        {Platform.OS === 'ios' ? (
          <BlurView intensity={60} tint="dark" style={StyleSheet.absoluteFill} />
        ) : (
          <View style={[StyleSheet.absoluteFill, styles.androidFallback]} />
        )}

        {/* Glass overlay */}
        <View style={styles.glassOverlay} />

        {/* Progress bar */}
        <View style={styles.progressContainer}>
          <Animated.View
            style={[
              styles.progressBar,
              {
                width: progressAnim.interpolate({
                  inputRange: [0, 100],
                  outputRange: ['0%', '100%'],
                }),
                backgroundColor: accentColor,
              },
            ]}
          />
        </View>

        {/* Content */}
        <View style={styles.content}>
          {/* Left: Search */}
          <Pressable style={styles.iconButton} onPress={onSearchPress}>
            <Ionicons name="search" size={22} color="rgba(255,255,255,0.7)" />
          </Pressable>

          {/* Center: Mode toggle */}
          <View style={styles.modeToggle}>
            <Pressable
              style={[styles.modeButton, isMail && styles.modeButtonActive]}
              onPress={() => handleModeToggle('mail')}
            >
              <Ionicons
                name="mail"
                size={18}
                color={isMail ? '#fff' : 'rgba(255,255,255,0.5)'}
              />
              <Text style={[styles.modeText, isMail && styles.modeTextActive]}>
                Mail
              </Text>
              {mailCount > 0 && (
                <View style={[styles.badge, isMail && { backgroundColor: '#fff' }]}>
                  <Text style={[styles.badgeText, isMail && { color: accentColor }]}>
                    {mailCount}
                  </Text>
                </View>
              )}
            </Pressable>

            <View style={styles.modeDivider} />

            <Pressable
              style={[styles.modeButton, !isMail && styles.modeButtonActive]}
              onPress={() => handleModeToggle('ads')}
            >
              <Ionicons
                name="pricetag"
                size={18}
                color={!isMail ? '#fff' : 'rgba(255,255,255,0.5)'}
              />
              <Text style={[styles.modeText, !isMail && styles.modeTextActive]}>
                Ads
              </Text>
              {adsCount > 0 && (
                <View style={[styles.badge, !isMail && { backgroundColor: '#fff' }]}>
                  <Text style={[styles.badgeText, !isMail && { color: accentColor }]}>
                    {adsCount}
                  </Text>
                </View>
              )}
            </Pressable>
          </View>

          {/* Right: Settings */}
          <Pressable style={styles.iconButton} onPress={onSettingsPress}>
            <Ionicons name="settings-outline" size={22} color="rgba(255,255,255,0.7)" />
          </Pressable>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    paddingHorizontal: 16,
    zIndex: 100,
  },
  navCard: {
    borderRadius: 24,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -4 },
    shadowOpacity: 0.3,
    shadowRadius: 12,
    elevation: 10,
  },
  androidFallback: {
    backgroundColor: 'rgba(20, 20, 30, 0.95)',
  },
  glassOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
  },
  progressContainer: {
    height: 2,
    backgroundColor: 'rgba(255,255,255,0.1)',
  },
  progressBar: {
    height: '100%',
    borderRadius: 1,
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 8,
    paddingVertical: 12,
  },
  iconButton: {
    padding: 10,
    borderRadius: 12,
  },
  modeToggle: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 16,
    padding: 4,
  },
  modeButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 12,
    gap: 6,
  },
  modeButtonActive: {
    backgroundColor: 'rgba(102, 126, 234, 0.3)',
  },
  modeText: {
    fontSize: 14,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.5)',
  },
  modeTextActive: {
    color: '#fff',
  },
  modeDivider: {
    width: 1,
    height: 20,
    backgroundColor: 'rgba(255,255,255,0.1)',
    marginHorizontal: 4,
  },
  badge: {
    backgroundColor: 'rgba(255,255,255,0.2)',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 8,
    minWidth: 20,
    alignItems: 'center',
  },
  badgeText: {
    fontSize: 11,
    fontWeight: '700',
    color: 'rgba(255,255,255,0.8)',
  },
});


