/**
 * AddToCalendarModal - Add event to iOS Calendar
 */

import React, { useState } from 'react';
import { View, Text, StyleSheet, TextInput, Linking, Alert } from 'react-native';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';
import {
  BaseActionModal,
  ModalSection,
  InfoRow,
  ActionButton,
} from './BaseActionModal';

interface AddToCalendarModalProps {
  visible: boolean;
  onClose: () => void;
  onAdd?: () => void;
  card: EmailCard;
  action: SuggestedAction;
}

export function AddToCalendarModal({ visible, onClose, onAdd, card, action }: AddToCalendarModalProps) {
  const context = action.context || {};
  const [eventTitle, setEventTitle] = useState(context.eventTitle || context.title || card.title || '');
  const eventDate = context.date || context.eventDate || '';
  const eventTime = context.time || context.eventTime || '';
  const location = context.location || '';

  const handleAddToCalendar = async () => {
    HapticService.mediumImpact();
    
    // Open native calendar
    const calendarUrl = `calshow://`;
    try {
      await Linking.openURL(calendarUrl);
      if (onAdd) onAdd();
      onClose();
    } catch (error) {
      Alert.alert('Error', 'Could not open Calendar app');
    }
  };

  return (
    <BaseActionModal
      visible={visible}
      onClose={onClose}
      card={card}
      action={action}
      title="Add to Calendar"
      icon="calendar-outline"
      iconColor="#3b82f6"
      gradientColors={['#3b82f6', '#2563eb']}
      footer={
        <ActionButton
          title="Add to Calendar"
          icon="calendar-outline"
          onPress={handleAddToCalendar}
        />
      }
    >
      {/* Event Title */}
      <ModalSection title="EVENT TITLE">
        <TextInput
          style={styles.input}
          value={eventTitle}
          onChangeText={setEventTitle}
          placeholder="Event name"
          placeholderTextColor="rgba(255,255,255,0.4)"
        />
      </ModalSection>

      {/* Event Details */}
      <ModalSection title="EVENT DETAILS">
        {eventDate && (
          <InfoRow
            icon="calendar-outline"
            iconColor="#22c55e"
            label="Date"
            value={eventDate}
          />
        )}
        {eventTime && (
          <InfoRow
            icon="time-outline"
            iconColor="#f59e0b"
            label="Time"
            value={eventTime}
          />
        )}
        {location && (
          <InfoRow
            icon="location-outline"
            iconColor="#ef4444"
            label="Location"
            value={location}
          />
        )}
      </ModalSection>

      {/* Detected Info */}
      <View style={styles.detectedInfo}>
        <Text style={styles.detectedIcon}>✨</Text>
        <Text style={styles.detectedText}>
          Event details detected from email content
        </Text>
      </View>
    </BaseActionModal>
  );
}

const styles = StyleSheet.create({
  input: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 12,
    padding: 14,
    fontSize: 16,
    color: 'white',
  },
  detectedInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: 'rgba(59, 130, 246, 0.15)',
    borderRadius: 12,
    padding: 14,
    marginTop: 12,
  },
  detectedIcon: {
    fontSize: 18,
  },
  detectedText: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.7)',
  },
});
