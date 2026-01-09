/**
 * CheckInFlightModal - Flight check-in with airline details
 */

import React from 'react';
import { View, Text, StyleSheet, Linking, Share } from 'react-native';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';
import {
  BaseActionModal,
  ModalSection,
  InfoRow,
  CopyableField,
  ActionButton,
} from './BaseActionModal';

interface CheckInFlightModalProps {
  visible: boolean;
  onClose: () => void;
  card: EmailCard;
  action: SuggestedAction;
}

export function CheckInFlightModal({ visible, onClose, card, action }: CheckInFlightModalProps) {
  const context = action.context || {};
  const flightNumber = context.flightNumber || 'N/A';
  const airline = context.airline || 'Airline';
  const checkInUrl = context.checkInUrl || context.url || '';
  const departureTime = context.departureTime || '';
  const gate = context.gate || '';
  const seat = context.seat || '';
  const confirmationCode = context.confirmationCode || '';

  const handleCheckIn = async () => {
    HapticService.mediumImpact();
    if (checkInUrl) {
      await Linking.openURL(checkInUrl);
      onClose();
    }
  };

  const handleShare = async () => {
    HapticService.lightImpact();
    const shareText = `✈️ Flight Details\n\nFlight: ${flightNumber}\nAirline: ${airline}\nDeparture: ${departureTime}\n${gate ? `Gate: ${gate}` : ''}\n${seat ? `Seat: ${seat}` : ''}`;
    await Share.share({ message: shareText });
  };

  return (
    <BaseActionModal
      visible={visible}
      onClose={onClose}
      card={card}
      action={action}
      title="Flight Check-In"
      icon="airplane-outline"
      iconColor="#3b82f6"
      gradientColors={['#3b82f6', '#1d4ed8']}
      footer={
        <>
          <ActionButton
            title="Check In Now"
            icon="checkmark-circle-outline"
            onPress={handleCheckIn}
          />
          <ActionButton
            title="Share Flight Info"
            icon="share-outline"
            onPress={handleShare}
            variant="secondary"
          />
        </>
      }
    >
      {/* Flight Badge */}
      <View style={styles.flightBadge}>
        <Text style={styles.flightNumber}>{flightNumber}</Text>
        <Text style={styles.airlineName}>{airline}</Text>
      </View>

      {/* Flight Details */}
      <ModalSection title="FLIGHT DETAILS">
        {confirmationCode && (
          <CopyableField
            label="Confirmation Code"
            value={confirmationCode}
            icon="ticket-outline"
            iconColor="#f59e0b"
          />
        )}

        {departureTime && (
          <InfoRow
            icon="time-outline"
            iconColor="#22c55e"
            label="Departure"
            value={departureTime}
          />
        )}

        {gate && (
          <InfoRow
            icon="navigate-outline"
            iconColor="#8b5cf6"
            label="Gate"
            value={gate}
          />
        )}

        {seat && (
          <InfoRow
            icon="person-outline"
            iconColor="#3b82f6"
            label="Seat"
            value={seat}
          />
        )}
      </ModalSection>

      {/* Check-in Status */}
      <View style={styles.statusBanner}>
        <Text style={styles.statusIcon}>⏰</Text>
        <View>
          <Text style={styles.statusTitle}>Check-in is Open</Text>
          <Text style={styles.statusSubtitle}>Check in now to select your seat</Text>
        </View>
      </View>
    </BaseActionModal>
  );
}

const styles = StyleSheet.create({
  flightBadge: {
    alignItems: 'center',
    backgroundColor: 'rgba(59, 130, 246, 0.2)',
    borderRadius: 16,
    padding: 20,
    marginBottom: 20,
  },
  flightNumber: {
    fontSize: 28,
    fontWeight: '700',
    color: '#3b82f6',
  },
  airlineName: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.7)',
    marginTop: 4,
  },
  statusBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(34, 197, 94, 0.15)',
    borderRadius: 14,
    padding: 16,
    gap: 12,
    marginTop: 8,
  },
  statusIcon: {
    fontSize: 24,
  },
  statusTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: '#22c55e',
  },
  statusSubtitle: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.6)',
  },
});
