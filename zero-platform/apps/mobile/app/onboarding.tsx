/**
 * OnboardingScreen - First-time user onboarding flow
 * Port of iOS OnboardingView.swift with 100% parity
 * 
 * Features:
 * - 2-step flow (Welcome, Ready)
 * - Animated card gesture demo
 * - Firefly background
 * - Progress dots with spring animation
 * - Previous/Next navigation with gradients
 * - Skip button for returning users
 * - Persists completion state
 */

import React, { useState, useCallback, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  Dimensions,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  FadeIn,
  FadeOut,
  SlideInRight,
  SlideOutLeft,
  SlideInLeft,
  SlideOutRight,
} from 'react-native-reanimated';
import AsyncStorage from '@react-native-async-storage/async-storage';

import { FireflyBackground } from '../components/FireflyBackground';
import { OnboardingCardAnimation } from '../components/OnboardingCardAnimation';
import { HapticService } from '../services/HapticService';
import { useAuth } from '../contexts/AuthContext';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

const STORAGE_KEY = 'hasCompletedOnboarding';

// Step definitions
const STEPS = ['Welcome to Zero', 'Ready to Go'];

export default function OnboardingScreen() {
  const { user, useMockData } = useAuth();
  const [currentStep, setCurrentStep] = useState(0);
  const [hasCompletedBefore, setHasCompletedBefore] = useState(false);
  const [slideDirection, setSlideDirection] = useState<'forward' | 'backward'>('forward');

  const isLastStep = currentStep === STEPS.length - 1;

  // Check if user has completed onboarding before
  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY).then((value) => {
      setHasCompletedBefore(value === 'true');
    });
  }, []);

  const handleSkip = useCallback(() => {
    HapticService.lightImpact();
    router.replace('/feed');
  }, []);

  const handlePrevious = useCallback(() => {
    if (currentStep > 0) {
      HapticService.lightImpact();
      setSlideDirection('backward');
      setCurrentStep((prev) => prev - 1);
    }
  }, [currentStep]);

  const handleNext = useCallback(async () => {
    HapticService.mediumImpact();

    if (isLastStep) {
      // Mark onboarding as completed
      await AsyncStorage.setItem(STORAGE_KEY, 'true');
      HapticService.success();
      router.replace('/feed');
    } else {
      setSlideDirection('forward');
      setCurrentStep((prev) => prev + 1);
    }
  }, [isLastStep]);

  return (
    <View style={styles.container}>
      {/* Firefly Background */}
      <FireflyBackground variant="onboarding" />

      <SafeAreaView style={styles.safeArea} edges={['top', 'bottom']}>
        {/* Skip button (only for returning users) */}
        {hasCompletedBefore ? (
          <View style={styles.skipContainer}>
            <Pressable onPress={handleSkip} style={styles.skipButton}>
              <Ionicons name="close" size={24} color="rgba(255, 255, 255, 0.4)" />
            </Pressable>
          </View>
        ) : (
          <View style={styles.skipPlaceholder} />
        )}

        {/* Progress dots */}
        <View style={styles.progressContainer}>
          {STEPS.map((_, index) => (
            <ProgressDot
              key={index}
              index={index}
              currentStep={currentStep}
            />
          ))}
        </View>

        {/* Content */}
        <View style={styles.content}>
          {currentStep === 0 ? (
            <WelcomeStep
              userEmail={useMockData ? null : user?.email}
              useMockData={useMockData}
              direction={slideDirection}
            />
          ) : (
            <ReadyStep
              useMockData={useMockData}
              direction={slideDirection}
            />
          )}
        </View>

        {/* Navigation */}
        <View style={styles.navigation}>
          <Text style={styles.stepCounter}>
            {currentStep + 1} of {STEPS.length}
          </Text>

          <View style={styles.buttonRow}>
            {/* Previous button */}
            <Pressable
              onPress={handlePrevious}
              style={[styles.button, currentStep === 0 && styles.buttonDisabled]}
              disabled={currentStep === 0}
            >
              {currentStep === 0 ? (
                <View style={styles.buttonBgDisabled} />
              ) : (
                <LinearGradient
                  colors={['rgba(59, 130, 246, 0.4)', 'rgba(168, 85, 247, 0.4)']}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 1, y: 0 }}
                  style={StyleSheet.absoluteFill}
                />
              )}
              <View style={styles.buttonContent}>
                <Ionicons
                  name="arrow-back"
                  size={18}
                  color={currentStep === 0 ? 'rgba(255, 255, 255, 0.2)' : 'white'}
                />
                <Text
                  style={[
                    styles.buttonText,
                    currentStep === 0 && styles.buttonTextDisabled,
                  ]}
                >
                  Previous
                </Text>
              </View>
            </Pressable>

            {/* Next / Get Started button */}
            <Pressable onPress={handleNext} style={styles.button}>
              <LinearGradient
                colors={['#3b82f6', '#a855f7']}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 0 }}
                style={StyleSheet.absoluteFill}
              />
              <View style={styles.buttonContent}>
                <Text style={styles.buttonText}>
                  {isLastStep ? 'Get Started' : 'Next'}
                </Text>
                <Ionicons
                  name={isLastStep ? 'flash' : 'arrow-forward'}
                  size={18}
                  color="white"
                />
              </View>
            </Pressable>
          </View>
        </View>
      </SafeAreaView>
    </View>
  );
}

// Progress dot component with spring animation
function ProgressDot({ index, currentStep }: { index: number; currentStep: number }) {
  const width = useSharedValue(8);
  const backgroundColor = useSharedValue('rgba(255, 255, 255, 0.2)');

  useEffect(() => {
    if (index === currentStep) {
      width.value = withSpring(24, { damping: 15, stiffness: 150 });
    } else {
      width.value = withSpring(8, { damping: 15, stiffness: 150 });
    }
  }, [currentStep, index]);

  const animatedStyle = useAnimatedStyle(() => ({
    width: width.value,
  }));

  const isActive = index === currentStep;
  const isCompleted = index < currentStep;

  return (
    <Animated.View
      style={[
        styles.progressDot,
        {
          backgroundColor: isActive
            ? 'white'
            : isCompleted
            ? '#22c55e'
            : 'rgba(255, 255, 255, 0.2)',
        },
        animatedStyle,
      ]}
    />
  );
}

// Welcome step content
function WelcomeStep({
  userEmail,
  useMockData,
  direction,
}: {
  userEmail?: string | null;
  useMockData: boolean;
  direction: 'forward' | 'backward';
}) {
  return (
    <Animated.View
      entering={direction === 'forward' ? SlideInRight.duration(300) : SlideInLeft.duration(300)}
      exiting={direction === 'forward' ? SlideOutLeft.duration(300) : SlideOutRight.duration(300)}
      style={styles.stepContent}
    >
      <Ionicons name="sparkles" size={48} color="#eab308" />

      <Text style={styles.stepTitle}>Welcome to Zero</Text>

      <Text style={styles.stepSubtitle}>
        Clear your inbox in minutes, not hours
      </Text>

      <Text style={styles.stepDescription}>
        Zero organizes emails with smart actions so you can swipe through what matters.
      </Text>

      {!useMockData && userEmail && (
        <Text style={styles.connectedEmail}>
          Connected: {userEmail}
        </Text>
      )}

      <Text style={styles.hintText}>
        Watch the cards to learn the gestures
      </Text>

      {/* Card Animation Demo */}
      <View style={styles.animationContainer}>
        <OnboardingCardAnimation />
      </View>
    </Animated.View>
  );
}

// Ready step content
function ReadyStep({
  useMockData,
  direction,
}: {
  useMockData: boolean;
  direction: 'forward' | 'backward';
}) {
  return (
    <Animated.View
      entering={direction === 'forward' ? SlideInRight.duration(300) : SlideInLeft.duration(300)}
      exiting={direction === 'forward' ? SlideOutLeft.duration(300) : SlideOutRight.duration(300)}
      style={styles.stepContent}
    >
      <Ionicons name="checkmark-circle" size={48} color="#22c55e" />

      <Text style={styles.stepTitle}>You're All Set!</Text>

      <Text style={styles.stepDescription}>
        {useMockData
          ? 'Start swiping and watch your inbox clear in record time.'
          : 'Start swiping through your emails and watch your inbox clear in record time.'}
      </Text>

      {/* Quick reference */}
      <View style={styles.gestureReference}>
        <GestureItem
          direction="right"
          icon="arrow-forward-circle"
          label="Swipe Right"
          action="Take Action"
          color="#22c55e"
        />
        <GestureItem
          direction="left"
          icon="checkmark-circle"
          label="Swipe Left"
          action="Mark as Read"
          color="#3b82f6"
        />
        <GestureItem
          direction="down"
          icon="time"
          label="Swipe Down"
          action="Snooze"
          color="#a855f7"
        />
        <GestureItem
          direction="up"
          icon="apps"
          label="Swipe Up"
          action="More Actions"
          color="#f97316"
        />
      </View>
    </Animated.View>
  );
}

// Gesture reference item
function GestureItem({
  icon,
  label,
  action,
  color,
}: {
  direction: string;
  icon: keyof typeof Ionicons.glyphMap;
  label: string;
  action: string;
  color: string;
}) {
  return (
    <View style={styles.gestureItem}>
      <View style={[styles.gestureIcon, { backgroundColor: color + '20' }]}>
        <Ionicons name={icon} size={20} color={color} />
      </View>
      <View style={styles.gestureText}>
        <Text style={styles.gestureLabel}>{label}</Text>
        <Text style={styles.gestureAction}>{action}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0f',
  },
  safeArea: {
    flex: 1,
  },
  skipContainer: {
    alignItems: 'flex-end',
    paddingHorizontal: 16,
    paddingTop: 8,
  },
  skipButton: {
    padding: 12,
  },
  skipPlaceholder: {
    height: 56,
  },
  progressContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 8,
    paddingVertical: 16,
  },
  progressDot: {
    height: 8,
    borderRadius: 4,
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
  },
  stepContent: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 16,
  },
  stepTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: 'white',
    textAlign: 'center',
  },
  stepSubtitle: {
    fontSize: 18,
    fontWeight: '600',
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'center',
  },
  stepDescription: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.5)',
    textAlign: 'center',
    paddingHorizontal: 30,
    lineHeight: 24,
  },
  connectedEmail: {
    fontSize: 13,
    color: 'rgba(255, 255, 255, 0.4)',
    marginTop: 8,
  },
  hintText: {
    fontSize: 13,
    color: 'rgba(255, 255, 255, 0.4)',
    marginTop: 16,
  },
  animationContainer: {
    marginTop: 24,
  },
  gestureReference: {
    marginTop: 32,
    gap: 12,
    width: '100%',
    paddingHorizontal: 20,
  },
  gestureItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
  },
  gestureIcon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  gestureText: {
    flex: 1,
  },
  gestureLabel: {
    fontSize: 15,
    fontWeight: '600',
    color: 'white',
  },
  gestureAction: {
    fontSize: 13,
    color: 'rgba(255, 255, 255, 0.5)',
  },
  navigation: {
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  stepCounter: {
    fontSize: 13,
    color: 'rgba(255, 255, 255, 0.5)',
    textAlign: 'center',
    marginBottom: 12,
  },
  buttonRow: {
    flexDirection: 'row',
    gap: 12,
  },
  button: {
    flex: 1,
    height: 52,
    borderRadius: 14,
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
  },
  buttonDisabled: {
    opacity: 1,
  },
  buttonBgDisabled: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
  },
  buttonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
  buttonTextDisabled: {
    color: 'rgba(255, 255, 255, 0.2)',
  },
});

export default OnboardingScreen;
