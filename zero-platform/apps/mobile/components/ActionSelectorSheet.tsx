/**
 * ActionSelectorSheet - Bottom sheet for selecting additional actions
 * Shown on swipe up gesture
 */

import React, { useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  Modal,
  Animated,
  Platform,
  ScrollView,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import type { EmailCard, EmailAction } from '@zero/types';
import { HapticService } from '../services/HapticService';

// Quick actions always available
const QUICK_ACTIONS = [
  { id: 'archive', label: 'Archive', icon: 'archive', color: '#667eea' },
  { id: 'snooze', label: 'Snooze', icon: 'time', color: '#eab308' },
  { id: 'save', label: 'Save for Later', icon: 'bookmark', color: '#22c55e' },
  { id: 'delete', label: 'Delete', icon: 'trash', color: '#ef4444' },
  { id: 'mark_unread', label: 'Mark Unread', icon: 'mail-unread', color: '#3b82f6' },
];

interface ActionSelectorSheetProps {
  visible: boolean;
  onClose: () => void;
  onSelectAction: (action: EmailAction) => void;
  card: EmailCard | null;
}

export function ActionSelectorSheet({
  visible,
  onClose,
  onSelectAction,
  card,
}: ActionSelectorSheetProps) {
  const insets = useSafeAreaInsets();
  const translateY = useRef(new Animated.Value(500)).current;
  const backdropOpacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (visible) {
      Animated.parallel([
        Animated.spring(translateY, {
          toValue: 0,
          friction: 8,
          tension: 100,
          useNativeDriver: true,
        }),
        Animated.timing(backdropOpacity, {
          toValue: 1,
          duration: 200,
          useNativeDriver: true,
        }),
      ]).start();
    } else {
      Animated.parallel([
        Animated.timing(translateY, {
          toValue: 500,
          duration: 200,
          useNativeDriver: true,
        }),
        Animated.timing(backdropOpacity, {
          toValue: 0,
          duration: 200,
          useNativeDriver: true,
        }),
      ]).start();
    }
  }, [visible, translateY, backdropOpacity]);

  const handleQuickAction = (action: typeof QUICK_ACTIONS[0]) => {
    HapticService.selection();
    onSelectAction({
      id: action.id,
      actionId: action.id,
      displayName: action.label,
      actionType: 'IN_APP',
    });
  };

  const handleSuggestedAction = (action: EmailAction) => {
    HapticService.selection();
    onSelectAction(action);
  };

  const suggestedActions = card?.suggestedActions || [];

  return (
    <Modal visible={visible} transparent animationType="none" onRequestClose={onClose}>
      <View style={styles.container}>
        {/* Backdrop */}
        <Animated.View style={[styles.backdrop, { opacity: backdropOpacity }]}>
          <Pressable style={StyleSheet.absoluteFill} onPress={onClose} />
        </Animated.View>

        {/* Sheet */}
        <Animated.View
          style={[
            styles.sheet,
            {
              transform: [{ translateY }],
              paddingBottom: insets.bottom + 16,
            },
          ]}
        >
          {Platform.OS === 'ios' ? (
            <BlurView intensity={80} tint="dark" style={StyleSheet.absoluteFill} />
          ) : (
            <View style={[StyleSheet.absoluteFill, styles.androidFallback]} />
          )}

          {/* Handle */}
          <View style={styles.handle} />

          <ScrollView showsVerticalScrollIndicator={false}>
            {/* Suggested Actions */}
            {suggestedActions.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>SUGGESTED ACTIONS</Text>
                <View style={styles.actionsGrid}>
                  {suggestedActions.map((action) => (
                    <Pressable
                      key={action.id}
                      style={[styles.actionCard, action.isPrimary && styles.primaryActionCard]}
                      onPress={() => handleSuggestedAction(action)}
                    >
                      <Text style={styles.actionEmoji}>
                        {action.isPrimary ? '⚡' : '📧'}
                      </Text>
                      <Text
                        style={[styles.actionLabel, action.isPrimary && styles.primaryActionLabel]}
                        numberOfLines={2}
                      >
                        {action.displayName}
                      </Text>
                      {action.confidence && (
                        <Text style={styles.actionConfidence}>
                          {Math.round(action.confidence * 100)}%
                        </Text>
                      )}
                    </Pressable>
                  ))}
                </View>
              </View>
            )}

            {/* Quick Actions */}
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>QUICK ACTIONS</Text>
              <View style={styles.quickActions}>
                {QUICK_ACTIONS.map((action) => (
                  <Pressable
                    key={action.id}
                    style={styles.quickAction}
                    onPress={() => handleQuickAction(action)}
                  >
                    <View style={[styles.quickActionIcon, { backgroundColor: action.color + '20' }]}>
                      <Ionicons
                        name={action.icon as keyof typeof Ionicons.glyphMap}
                        size={22}
                        color={action.color}
                      />
                    </View>
                    <Text style={styles.quickActionLabel}>{action.label}</Text>
                  </Pressable>
                ))}
              </View>
            </View>
          </ScrollView>

          {/* Cancel */}
          <Pressable style={styles.cancelButton} onPress={onClose}>
            <Text style={styles.cancelText}>Cancel</Text>
          </Pressable>
        </Animated.View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'flex-end',
  },
  backdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  sheet: {
    maxHeight: '80%',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
    borderBottomWidth: 0,
  },
  androidFallback: {
    backgroundColor: 'rgba(25, 25, 35, 0.98)',
  },
  handle: {
    width: 40,
    height: 4,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 2,
    alignSelf: 'center',
    marginTop: 12,
    marginBottom: 16,
  },
  section: {
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: 'rgba(255, 255, 255, 0.5)',
    letterSpacing: 0.5,
    marginBottom: 12,
  },
  actionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  actionCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    borderRadius: 14,
    padding: 14,
    minWidth: 100,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  primaryActionCard: {
    backgroundColor: 'rgba(102, 126, 234, 0.2)',
    borderColor: 'rgba(102, 126, 234, 0.4)',
  },
  actionEmoji: {
    fontSize: 24,
    marginBottom: 8,
  },
  actionLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: 'white',
    textAlign: 'center',
  },
  primaryActionLabel: {
    color: '#a5b4fc',
  },
  actionConfidence: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.5)',
    marginTop: 4,
  },
  quickActions: {
    gap: 2,
  },
  quickAction: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 4,
    gap: 14,
  },
  quickActionIcon: {
    width: 42,
    height: 42,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  quickActionLabel: {
    fontSize: 16,
    fontWeight: '500',
    color: 'white',
  },
  cancelButton: {
    marginHorizontal: 20,
    marginTop: 8,
    paddingVertical: 14,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 14,
    alignItems: 'center',
  },
  cancelText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'rgba(255, 255, 255, 0.8)',
  },
});

