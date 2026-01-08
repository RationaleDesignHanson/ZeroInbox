/**
 * ScenicBackground - Animated background for ads cards
 * Features warm gradient with floating shapes
 */

import React, { useEffect, useRef, useMemo } from 'react';
import { View, StyleSheet, Animated, Dimensions, Easing } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');

interface FloatingShape {
  id: number;
  x: number;
  y: number;
  size: number;
  rotation: number;
  duration: number;
  color: string;
}

const COLORS = [
  'rgba(234, 179, 8, 0.3)',   // Gold
  'rgba(249, 115, 22, 0.25)', // Orange
  'rgba(239, 68, 68, 0.2)',   // Red
  'rgba(245, 158, 11, 0.25)', // Amber
];

const generateShapes = (count: number): FloatingShape[] => {
  return Array.from({ length: count }, (_, i) => ({
    id: i,
    x: Math.random() * SCREEN_WIDTH,
    y: Math.random() * SCREEN_HEIGHT * 0.7,
    size: 20 + Math.random() * 40,
    rotation: Math.random() * 360,
    duration: 4000 + Math.random() * 3000,
    color: COLORS[Math.floor(Math.random() * COLORS.length)],
  }));
};

function FloatingShapeComponent({ shape, animated }: { shape: FloatingShape; animated: boolean }) {
  const translateY = useRef(new Animated.Value(0)).current;
  const rotateAnim = useRef(new Animated.Value(0)).current;
  const opacityAnim = useRef(new Animated.Value(0.5)).current;

  useEffect(() => {
    if (!animated) return;

    // Floating animation
    const floatAnimation = Animated.loop(
      Animated.sequence([
        Animated.timing(translateY, {
          toValue: -15,
          duration: shape.duration,
          easing: Easing.inOut(Easing.sin),
          useNativeDriver: true,
        }),
        Animated.timing(translateY, {
          toValue: 15,
          duration: shape.duration,
          easing: Easing.inOut(Easing.sin),
          useNativeDriver: true,
        }),
      ])
    );

    // Rotation animation
    const rotateAnimation = Animated.loop(
      Animated.timing(rotateAnim, {
        toValue: 1,
        duration: shape.duration * 2,
        easing: Easing.linear,
        useNativeDriver: true,
      })
    );

    // Pulse animation
    const pulseAnimation = Animated.loop(
      Animated.sequence([
        Animated.timing(opacityAnim, {
          toValue: 0.3,
          duration: shape.duration * 0.6,
          easing: Easing.inOut(Easing.sin),
          useNativeDriver: true,
        }),
        Animated.timing(opacityAnim, {
          toValue: 0.6,
          duration: shape.duration * 0.6,
          easing: Easing.inOut(Easing.sin),
          useNativeDriver: true,
        }),
      ])
    );

    floatAnimation.start();
    rotateAnimation.start();
    pulseAnimation.start();

    return () => {
      floatAnimation.stop();
      rotateAnimation.stop();
      pulseAnimation.stop();
    };
  }, [animated, shape.duration, translateY, rotateAnim, opacityAnim]);

  const rotate = rotateAnim.interpolate({
    inputRange: [0, 1],
    outputRange: ['0deg', '360deg'],
  });

  return (
    <Animated.View
      style={[
        styles.shape,
        {
          left: shape.x,
          top: shape.y,
          width: shape.size,
          height: shape.size,
          borderRadius: shape.size / 4, // Rounded square
          backgroundColor: shape.color,
          opacity: opacityAnim,
          transform: [{ translateY }, { rotate }],
        },
      ]}
    />
  );
}

interface ScenicBackgroundProps {
  shapeCount?: number;
  animated?: boolean;
}

export function ScenicBackground({ shapeCount = 10, animated = true }: ScenicBackgroundProps) {
  const shapes = useMemo(() => generateShapes(shapeCount), [shapeCount]);

  return (
    <View style={styles.container}>
      {/* Warm gradient base */}
      <LinearGradient
        colors={['#1a1512', '#2d1f16', '#3d2617']}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={StyleSheet.absoluteFill}
      />

      {/* Golden overlay */}
      <LinearGradient
        colors={['rgba(234, 179, 8, 0.08)', 'rgba(249, 115, 22, 0.05)', 'transparent']}
        start={{ x: 0.5, y: 0 }}
        end={{ x: 0.5, y: 1 }}
        style={StyleSheet.absoluteFill}
      />

      {/* Floating shapes */}
      {shapes.map((shape) => (
        <FloatingShapeComponent key={shape.id} shape={shape} animated={animated} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
  },
  shape: {
    position: 'absolute',
  },
});


