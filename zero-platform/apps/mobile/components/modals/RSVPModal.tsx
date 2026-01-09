/**
 * RSVPModal - Event invitation response
 * Handles accept/decline with calendar integration
 */

import React, { useState } from 'react';
import { View, Text, StyleSheet, Alert, Linking } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';
import {
  BaseActionModal,
  ModalSection,
  InfoRow,
  ActionButton,
} from './BaseActionModal';

interface RSVPModalProps {
  visible: boolean;
  onClose: () => void;
  card: EmailCard;
  action: SuggestedAction;
}

export function RSVPModal({ visible, onClose, card, action }: RSVPModalProps) {
  const [sendReply, setSendReply] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Determine response type from action
  const isAccepting = action.id === 'rsvp_yes';
  const responseType = isAccepting ? 'accept' : 'decline';

  // Extract context
  const context = action.context || {};
  const eventName = context.eventName || context.eventTitle || card.title || 'Event';
  const eventDate = context.date || context.eventDate || '';
  const eventTime = context.time || context.eventTime || '';
  const location = context.location || context.venue || '';
  const host = context.host || card.sender?.name || '';

  const gradientColors: [string, string] = isAccepting
    ? ['#22c55e', '#16a34a']
    : ['#ef4444', '#dc2626'];

  const handleConfirm = async () => {
    HapticService.mediumImpact();
    setIsSubmitting(true);

    // Simulate API call
    setTimeout(() => {
      setIsSubmitting(false);
      HapticService.success();
      
      Alert.alert(
        isAccepting ? '✅ Response Sent' : '📧 Response Sent',
        isAccepting
          ? 'You have accepted the invitation. Would you like to add it to your calendar?'
          : 'Your decline has been sent to the host.',
        isAccepting
          ? [
              { text: 'Skip', style: 'cancel', onPress: onClose },
              { text: 'Add to Calendar', onPress: handleAddToCalendar },
            ]
          : [{ text: 'OK', onPress: onClose }]
      );
    }, 1000);
  };

  const handleAddToCalendar = () => {
    // Open calendar with prefilled event
    const calendarUrl = `calshow://`;
    Linking.openURL(calendarUrl).catch(() => {
      Alert.alert('Calendar', 'Unable to open Calendar app');
    });
    onClose();
  };

  return (
    <BaseActionModal
      visible={visible}
      onClose={onClose}
      card={card}
      action={action}
      title={isAccepting ? 'Accept Invitation' : 'Decline Invitation'}
      icon={isAccepting ? 'checkmark-circle-outline' : 'close-circle-outline'}
      iconColor={isAccepting ? '#22c55e' : '#ef4444'}
      gradientColors={gradientColors}
      footer={
        <>
          <ActionButton
            title={isAccepting ? 'Confirm Attendance' : 'Send Decline'}
            icon={isAccepting ? 'checkmark-circle-outline' : 'close-circle-outline'}
            onPress={handleConfirm}
            loading={isSubmitting}
          />
          {isAccepting && (
            <ActionButton
              title="Add to Calendar"
              icon="calendar-outline"
              onPress={handleAddToCalendar}
              variant="secondary"
            />
          )}
        </>
      }
    >
      {/* Response Badge */}
      <View style={[styles.responseBadge, { backgroundColor: isAccepting ? 'rgba(34,197,94,0.2)' : 'rgba(239,68,68,0.2)' }]}>
        <Ionicons
          name={isAccepting ? 'checkmark-circle' : 'close-circle'}
          size={20}
          color={isAccepting ? '#22c55e' : '#ef4444'}
        />
        <Text style={[styles.responseBadgeText, { color: isAccepting ? '#22c55e' : '#ef4444' }]}>
          You're {isAccepting ? 'attending' : 'not attending'}
        </Text>
      </View>

      {/* Event Details */}
      <ModalSection title="EVENT DETAILS">
        <View style={styles.eventTitle}>
          <Text style={styles.eventName}>{eventName}</Text>
        </View>

        {eventDate && (
          <InfoRow
            icon="calendar-outline"
            iconColor="#3b82f6"
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

        {host && (
          <InfoRow
            icon="person-outline"
            iconColor="#8b5cf6"
            label="Host"
            value={host}
          />
        )}
      </ModalSection>

      {/* Send Reply Toggle */}
      <View style={styles.toggleContainer}>
        <View style={styles.toggleInfo}>
          <Ionicons name="mail-outline" size={20} color="rgba(255,255,255,0.6)" />
          <View style={styles.toggleText}>
            <Text style={styles.toggleTitle}>Send Reply Email</Text>
            <Text style={styles.toggleSubtitle}>Notify the host of your response</Text>
          </View>
        </View>
        <View style={[styles.toggleSwitch, sendReply && styles.toggleSwitchActive]}>
          <View style={[styles.toggleKnob, sendReply && styles.toggleKnobActive]} />
        </View>
      </View>
    </BaseActionModal>
  );
}

const styles = StyleSheet.create({
  responseBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 20,
    gap: 8,
    marginBottom: 20,
  },
  responseBadgeText: {
    fontSize: 14,
    fontWeight: '600',
  },
  eventTitle: {
    marginBottom: 12,
  },
  eventName: {
    fontSize: 18,
    fontWeight: '600',
    color: 'white',
    textAlign: 'center',
  },
  toggleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 14,
    padding: 16,
    marginTop: 8,
  },
  toggleInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    flex: 1,
  },
  toggleText: {
    flex: 1,
  },
  toggleTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: 'white',
  },
  toggleSubtitle: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.5)',
  },
  toggleSwitch: {
    width: 50,
    height: 30,
    borderRadius: 15,
    backgroundColor: 'rgba(255,255,255,0.2)',
    padding: 2,
    justifyContent: 'center',
  },
  toggleSwitchActive: {
    backgroundColor: '#22c55e',
  },
  toggleKnob: {
    width: 26,
    height: 26,
    borderRadius: 13,
    backgroundColor: 'white',
  },
  toggleKnobActive: {
    alignSelf: 'flex-end',
  },
});
