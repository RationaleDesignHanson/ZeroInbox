/**
 * ConfirmationModal - Simple confirmation for actions
 * Used for acknowledge, confirm_attendance, archive, and similar actions
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  Platform,
  ActivityIndicator,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';

// Confirmation configurations based on action type
const CONFIRMATION_CONFIG: Record<string, {
  icon: keyof typeof Ionicons.glyphMap;
  color: string;
  title: string;
  message: string;
  confirmText: string;
}> = {
  acknowledge: {
    icon: 'checkmark-circle',
    color: '#22c55e',
    title: 'Acknowledge Email',
    message: 'Send a confirmation that you received this email?',
    confirmText: 'Send Acknowledgment',
  },
  confirm_attendance: {
    icon: 'calendar-outline',
    color: '#3b82f6',
    title: 'Confirm Attendance',
    message: 'Confirm that you will attend this event?',
    confirmText: 'Confirm',
  },
  archive: {
    icon: 'archive',
    color: '#667eea',
    title: 'Archive Email',
    message: 'Archive this email? You can find it later in your archive.',
    confirmText: 'Archive',
  },
  delete: {
    icon: 'trash',
    color: '#ef4444',
    title: 'Delete Email',
    message: 'Are you sure you want to delete this email? This cannot be undone.',
    confirmText: 'Delete',
  },
  mark_read: {
    icon: 'mail-open',
    color: '#6b7280',
    title: 'Mark as Read',
    message: 'Mark this email as read?',
    confirmText: 'Mark Read',
  },
  mark_unread: {
    icon: 'mail-unread',
    color: '#3b82f6',
    title: 'Mark as Unread',
    message: 'Mark this email as unread?',
    confirmText: 'Mark Unread',
  },
  default: {
    icon: 'checkmark-done',
    color: '#667eea',
    title: 'Confirm Action',
    message: 'Are you sure you want to perform this action?',
    confirmText: 'Confirm',
  },
};

interface ConfirmationModalProps {
  visible: boolean;
  onClose: () => void;
  onConfirm: () => void;
  card: EmailCard;
  action: SuggestedAction;
  context?: Record<string, string>;
}

export function ConfirmationModal({
  visible,
  onClose,
  onConfirm,
  card,
  action,
  context,
}: ConfirmationModalProps) {
  const insets = useSafeAreaInsets();
  const [isConfirming, setIsConfirming] = useState(false);

  // Get config for this action type
  const config = CONFIRMATION_CONFIG[action.id] || CONFIRMATION_CONFIG.default;

  const handleConfirm = async () => {
    HapticService.mediumImpact();
    setIsConfirming(true);

    // Simulate action delay
    await new Promise((resolve) => setTimeout(resolve, 500));

    HapticService.success();
    onConfirm();
    setIsConfirming(false);
  };

  if (!visible) return null;

  return (
    <View style={styles.container}>
      <View style={styles.backdrop}>
        <Pressable style={StyleSheet.absoluteFill} onPress={onClose} />
      </View>

      <View style={[styles.modal, { paddingBottom: insets.bottom + 16 }]}>
        {Platform.OS === 'ios' ? (
          <BlurView intensity={80} tint="dark" style={StyleSheet.absoluteFill} />
        ) : (
          <View style={[StyleSheet.absoluteFill, styles.androidFallback]} />
        )}

        {/* Handle */}
        <View style={styles.handle} />

        {/* Content */}
        <View style={styles.content}>
          {/* Icon */}
          <View style={[styles.iconContainer, { backgroundColor: config.color + '20' }]}>
            <Ionicons name={config.icon} size={36} color={config.color} />
          </View>

          {/* Title */}
          <Text style={styles.title}>{config.title}</Text>

          {/* Message */}
          <Text style={styles.message}>{config.message}</Text>

          {/* Email Preview */}
          <View style={styles.emailPreview}>
            <Text style={styles.emailFrom} numberOfLines={1}>
              {card.sender?.name || card.sender?.email || 'Unknown Sender'}
            </Text>
            <Text style={styles.emailSubject} numberOfLines={2}>
              {card.title}
            </Text>
          </View>
        </View>

        {/* Actions */}
        <View style={styles.actions}>
          <Pressable style={styles.cancelButton} onPress={onClose}>
            <Text style={styles.cancelButtonText}>Cancel</Text>
          </Pressable>
          <Pressable
            style={[
              styles.confirmButton,
              { backgroundColor: config.color },
              isConfirming && styles.buttonDisabled,
            ]}
            onPress={handleConfirm}
            disabled={isConfirming}
          >
            {isConfirming ? (
              <ActivityIndicator size="small" color="white" />
            ) : (
              <Text style={styles.confirmButtonText}>{config.confirmText}</Text>
            )}
          </Pressable>
        </View>
      </View>
    </View>
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
  modal: {
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
  },
  content: {
    padding: 24,
    alignItems: 'center',
  },
  iconContainer: {
    width: 72,
    height: 72,
    borderRadius: 36,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 20,
  },
  title: {
    fontSize: 22,
    fontWeight: '700',
    color: 'white',
    marginBottom: 12,
    textAlign: 'center',
  },
  message: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'center',
    lineHeight: 22,
    marginBottom: 20,
  },
  emailPreview: {
    width: '100%',
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    borderRadius: 12,
    padding: 14,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  emailFrom: {
    fontSize: 14,
    fontWeight: '600',
    color: 'rgba(255, 255, 255, 0.9)',
    marginBottom: 4,
  },
  emailSubject: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.6)',
    lineHeight: 18,
  },
  actions: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    gap: 12,
  },
  cancelButton: {
    flex: 1,
    paddingVertical: 16,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 14,
    alignItems: 'center',
  },
  cancelButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'rgba(255, 255, 255, 0.8)',
  },
  confirmButton: {
    flex: 1,
    paddingVertical: 16,
    borderRadius: 14,
    alignItems: 'center',
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  confirmButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
});

