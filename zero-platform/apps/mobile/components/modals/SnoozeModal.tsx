/**
 * SnoozeModal - Snooze email with duration options
 */

import React, { useState } from 'react';
import { View, Text, StyleSheet, Pressable, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';
import {
  BaseActionModal,
  ActionButton,
} from './BaseActionModal';

interface SnoozeModalProps {
  visible: boolean;
  onClose: () => void;
  onSnooze?: (duration: string) => void;
  card: EmailCard;
  action: SuggestedAction;
}

const SNOOZE_OPTIONS = [
  { id: 'later_today', label: 'Later Today', sublabel: '4 hours', icon: 'time-outline', color: '#f59e0b' },
  { id: 'tomorrow', label: 'Tomorrow', sublabel: '9:00 AM', icon: 'sunny-outline', color: '#22c55e' },
  { id: 'this_weekend', label: 'This Weekend', sublabel: 'Saturday', icon: 'calendar-outline', color: '#3b82f6' },
  { id: 'next_week', label: 'Next Week', sublabel: 'Monday', icon: 'arrow-forward-outline', color: '#8b5cf6' },
  { id: 'custom', label: 'Pick Date & Time', sublabel: 'Custom', icon: 'options-outline', color: '#64748b' },
];

export function SnoozeModal({ visible, onClose, onSnooze, card, action }: SnoozeModalProps) {
  const [selectedOption, setSelectedOption] = useState<string | null>(null);

  const handleSelectOption = (optionId: string) => {
    HapticService.lightImpact();
    setSelectedOption(optionId);
  };

  const handleConfirmSnooze = () => {
    if (!selectedOption) return;

    HapticService.success();
    const option = SNOOZE_OPTIONS.find((o) => o.id === selectedOption);
    
    if (onSnooze) {
      onSnooze(option?.sublabel || 'later');
    }
    
    Alert.alert(
      '⏰ Snoozed',
      `This email will reappear ${option?.sublabel.toLowerCase() || 'later'}.`,
      [{ text: 'OK', onPress: onClose }]
    );
  };

  return (
    <BaseActionModal
      visible={visible}
      onClose={onClose}
      card={card}
      action={action}
      title="Snooze Email"
      icon="time-outline"
      iconColor="#f59e0b"
      gradientColors={['#f59e0b', '#d97706']}
      footer={
        <ActionButton
          title="Snooze"
          icon="time-outline"
          onPress={handleConfirmSnooze}
          disabled={!selectedOption}
        />
      }
    >
      {/* Snooze Options */}
      <View style={styles.optionsContainer}>
        {SNOOZE_OPTIONS.map((option) => (
          <Pressable
            key={option.id}
            style={[
              styles.optionCard,
              selectedOption === option.id && styles.optionCardSelected,
            ]}
            onPress={() => handleSelectOption(option.id)}
          >
            <View style={[styles.optionIcon, { backgroundColor: `${option.color}20` }]}>
              <Ionicons
                name={option.icon as keyof typeof Ionicons.glyphMap}
                size={24}
                color={option.color}
              />
            </View>
            <View style={styles.optionText}>
              <Text style={styles.optionLabel}>{option.label}</Text>
              <Text style={styles.optionSublabel}>{option.sublabel}</Text>
            </View>
            {selectedOption === option.id ? (
              <Ionicons name="checkmark-circle" size={24} color="#f59e0b" />
            ) : (
              <Ionicons name="ellipse-outline" size={24} color="rgba(255,255,255,0.2)" />
            )}
          </Pressable>
        ))}
      </View>

      {/* Info Note */}
      <View style={styles.infoNote}>
        <Ionicons name="information-circle-outline" size={18} color="rgba(255,255,255,0.5)" />
        <Text style={styles.infoText}>
          The email will be removed from your inbox and reappear at the selected time.
        </Text>
      </View>
    </BaseActionModal>
  );
}

const styles = StyleSheet.create({
  optionsContainer: {
    gap: 10,
  },
  optionCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 14,
    padding: 14,
    gap: 14,
    borderWidth: 2,
    borderColor: 'transparent',
  },
  optionCardSelected: {
    backgroundColor: 'rgba(245, 158, 11, 0.15)',
    borderColor: 'rgba(245, 158, 11, 0.4)',
  },
  optionIcon: {
    width: 48,
    height: 48,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  optionText: {
    flex: 1,
  },
  optionLabel: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
  optionSublabel: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.5)',
    marginTop: 2,
  },
  infoNote: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
    marginTop: 20,
    padding: 14,
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 12,
  },
  infoText: {
    flex: 1,
    fontSize: 13,
    color: 'rgba(255,255,255,0.6)',
    lineHeight: 18,
  },
});
