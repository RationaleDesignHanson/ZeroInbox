/**
 * DynamicActionModal - Routes to appropriate modal based on actionId
 */

import React from 'react';
import { View, Text, StyleSheet, Modal, Pressable, TextInput, Platform } from 'react-native';
import { BlurView } from 'expo-blur';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { HapticService } from '../services/HapticService';

interface DynamicActionModalProps {
  visible: boolean;
  actionId: string;
  emailId: string;
  context?: Record<string, any>;
  onClose: () => void;
  onSuccess?: () => void;
}

export function DynamicActionModal({
  visible,
  actionId,
  emailId,
  context = {},
  onClose,
  onSuccess,
}: DynamicActionModalProps) {
  const insets = useSafeAreaInsets();
  const [inputValue, setInputValue] = React.useState('');

  if (!visible) return null;

  // Determine modal type based on actionId
  const getModalConfig = () => {
    switch (actionId) {
      case 'quick_reply':
      case 'reply':
        return {
          title: 'Quick Reply',
          icon: 'mail' as const,
          iconColor: '#667eea',
          placeholder: 'Type your reply...',
          buttonText: 'Send Reply',
          buttonColor: '#667eea',
        };
      case 'add_to_calendar':
      case 'schedule':
        return {
          title: 'Add to Calendar',
          icon: 'calendar' as const,
          iconColor: '#22c55e',
          placeholder: '',
          buttonText: 'Add Event',
          buttonColor: '#22c55e',
        };
      case 'confirm':
      case 'archive':
        return {
          title: 'Confirm Action',
          icon: 'checkmark-circle' as const,
          iconColor: '#3b82f6',
          placeholder: '',
          buttonText: 'Confirm',
          buttonColor: '#3b82f6',
        };
      default:
        return {
          title: 'Action',
          icon: 'flash' as const,
          iconColor: '#667eea',
          placeholder: '',
          buttonText: 'Continue',
          buttonColor: '#667eea',
        };
    }
  };

  const config = getModalConfig();
  const isReplyModal = actionId === 'quick_reply' || actionId === 'reply';
  const isCalendarModal = actionId === 'add_to_calendar' || actionId === 'schedule';

  const handleAction = () => {
    HapticService.success();
    onSuccess?.();
    onClose();
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="slide"
      onRequestClose={onClose}
    >
      {/* Backdrop */}
      <Pressable style={styles.backdrop} onPress={onClose}>
        {Platform.OS === 'ios' ? (
          <BlurView intensity={40} tint="dark" style={StyleSheet.absoluteFill} />
        ) : (
          <View style={[StyleSheet.absoluteFill, { backgroundColor: 'rgba(0,0,0,0.7)' }]} />
        )}
      </Pressable>

      {/* Modal Content */}
      <View style={[styles.modalContainer, { paddingBottom: insets.bottom + 16 }]}>
        {Platform.OS === 'ios' ? (
          <BlurView intensity={80} tint="dark" style={StyleSheet.absoluteFill} />
        ) : (
          <View style={[StyleSheet.absoluteFill, styles.androidFallback]} />
        )}

        {/* Handle */}
        <View style={styles.handle} />

        {/* Header */}
        <View style={styles.header}>
          <Ionicons name={config.icon} size={28} color={config.iconColor} />
          <Text style={styles.title}>{config.title}</Text>
        </View>

        {/* Context Info */}
        {context.subject && (
          <View style={styles.contextCard}>
            <Text style={styles.contextLabel}>Subject</Text>
            <Text style={styles.contextValue}>{context.subject}</Text>
          </View>
        )}

        {context.title && isCalendarModal && (
          <View style={styles.contextCard}>
            <View style={styles.eventRow}>
              <Ionicons name="calendar-outline" size={18} color="rgba(255,255,255,0.6)" />
              <Text style={styles.eventTitle}>{context.title}</Text>
            </View>
            {context.date && (
              <View style={styles.eventRow}>
                <Ionicons name="time-outline" size={18} color="rgba(255,255,255,0.6)" />
                <Text style={styles.eventDate}>{context.date}</Text>
              </View>
            )}
          </View>
        )}

        {/* Reply Input */}
        {isReplyModal && (
          <View style={styles.inputContainer}>
            <TextInput
              style={styles.textInput}
              placeholder={config.placeholder}
              placeholderTextColor="rgba(255,255,255,0.4)"
              value={inputValue}
              onChangeText={setInputValue}
              multiline
              numberOfLines={4}
              textAlignVertical="top"
            />
            {/* AI Suggestions */}
            <View style={styles.suggestions}>
              <Text style={styles.suggestionsLabel}>Quick responses:</Text>
              <View style={styles.suggestionChips}>
                <Pressable 
                  style={styles.chip} 
                  onPress={() => setInputValue("Thanks for reaching out! I'll get back to you soon.")}
                >
                  <Text style={styles.chipText}>Thanks, will reply soon</Text>
                </Pressable>
                <Pressable 
                  style={styles.chip}
                  onPress={() => setInputValue("Sounds good, let's do it!")}
                >
                  <Text style={styles.chipText}>Sounds good!</Text>
                </Pressable>
              </View>
            </View>
          </View>
        )}

        {/* Confirmation Message */}
        {!isReplyModal && !isCalendarModal && (
          <View style={styles.confirmMessage}>
            <Text style={styles.confirmText}>
              Are you sure you want to proceed with this action?
            </Text>
            <Text style={styles.confirmSubtext}>
              Email ID: {emailId}
            </Text>
          </View>
        )}

        {/* Actions */}
        <View style={styles.actions}>
          <Pressable style={styles.cancelButton} onPress={onClose}>
            <Text style={styles.cancelButtonText}>Cancel</Text>
          </Pressable>
          <Pressable
            style={[styles.actionButton, { backgroundColor: config.buttonColor }]}
            onPress={handleAction}
          >
            <Ionicons name="checkmark" size={20} color="white" />
            <Text style={styles.actionButtonText}>{config.buttonText}</Text>
          </Pressable>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
    justifyContent: 'flex-end',
  },
  modalContainer: {
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
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    gap: 12,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.1)',
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: 'white',
  },
  contextCard: {
    margin: 20,
    marginBottom: 0,
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  contextLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: 'rgba(255, 255, 255, 0.5)',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: 4,
  },
  contextValue: {
    fontSize: 16,
    color: 'white',
    fontWeight: '500',
  },
  eventRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginBottom: 8,
  },
  eventTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
  eventDate: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  inputContainer: {
    padding: 20,
  },
  textInput: {
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    borderRadius: 16,
    padding: 16,
    fontSize: 16,
    color: 'white',
    minHeight: 120,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  suggestions: {
    marginTop: 16,
  },
  suggestionsLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: 'rgba(255, 255, 255, 0.5)',
    marginBottom: 8,
  },
  suggestionChips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  chip: {
    backgroundColor: 'rgba(102, 126, 234, 0.2)',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: 'rgba(102, 126, 234, 0.3)',
  },
  chipText: {
    fontSize: 13,
    color: '#a5b4fc',
  },
  confirmMessage: {
    padding: 20,
    alignItems: 'center',
  },
  confirmText: {
    fontSize: 16,
    color: 'white',
    textAlign: 'center',
    marginBottom: 8,
  },
  confirmSubtext: {
    fontSize: 13,
    color: 'rgba(255, 255, 255, 0.5)',
  },
  actions: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    paddingTop: 8,
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
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    paddingVertical: 16,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  actionButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
});

export default DynamicActionModal;
