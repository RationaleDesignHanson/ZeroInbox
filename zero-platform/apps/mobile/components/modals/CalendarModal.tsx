/**
 * CalendarModal - Add events to calendar
 * Used for schedule and add_to_calendar actions
 * 
 * NOTE: This is a STUB version that doesn't use expo-calendar
 * to avoid crashes on builds without calendar permissions.
 * Real calendar integration requires a new native build.
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  ScrollView,
  Platform,
  Alert,
  Linking,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';

interface CalendarModalProps {
  visible: boolean;
  onClose: () => void;
  onAdd: () => void;
  card: EmailCard;
  action: SuggestedAction;
  context?: Record<string, string>;
}

export function CalendarModal({
  visible,
  onClose,
  onAdd,
  card,
  action,
  context,
}: CalendarModalProps) {
  const insets = useSafeAreaInsets();
  const [isAdding, setIsAdding] = useState(false);

  // Extract event details from context or card
  const eventTitle = context?.eventTitle || context?.title || card.title;
  const eventDate = context?.eventDate || context?.date || 'Date TBD';
  const eventTime = context?.eventTime || context?.time || 'Time TBD';
  const eventLocation = context?.eventLocation || context?.location || '';
  const eventDescription = context?.eventDescription || card.summary || '';

  const handleAddToCalendar = async () => {
    HapticService.mediumImpact();
    setIsAdding(true);

    try {
      // Create a calendar URL to open the native calendar app
      // This works without needing expo-calendar permissions
      const startDate = new Date();
      startDate.setHours(startDate.getHours() + 24);
      const endDate = new Date(startDate);
      endDate.setHours(endDate.getHours() + 1);

      // Format for iOS calendar URL
      const formatDateForURL = (date: Date) => {
        return date.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z';
      };

      // Try to open native calendar with the event
      // This approach doesn't require expo-calendar
      const calendarUrl = Platform.select({
        ios: `calshow:${startDate.getTime() / 1000}`,
        android: `content://com.android.calendar/time/${startDate.getTime()}`,
      });

      if (calendarUrl) {
        const canOpen = await Linking.canOpenURL(calendarUrl);
        if (canOpen) {
          await Linking.openURL(calendarUrl);
        }
      }

      // Show success and instructions
      Alert.alert(
        'Add to Calendar',
        `Event "${eventTitle}" details:\n\nDate: ${eventDate}\nTime: ${eventTime}${eventLocation ? `\nLocation: ${eventLocation}` : ''}\n\nPlease add this event manually in your calendar app.`,
        [
          { text: 'OK', onPress: () => {
            HapticService.success();
            onAdd();
          }}
        ]
      );
    } catch (error) {
      console.error('Failed to open calendar:', error);
      HapticService.error();
      Alert.alert(
        'Calendar',
        'Unable to open calendar. Please add the event manually.',
        [{ text: 'OK' }]
      );
    } finally {
      setIsAdding(false);
    }
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

        {/* Header */}
        <View style={styles.header}>
          <Ionicons name="calendar" size={28} color="#22c55e" />
          <Text style={styles.headerTitle}>Add to Calendar</Text>
        </View>

        <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
          {/* Event Card */}
          <View style={styles.eventCard}>
            <Text style={styles.eventTitle}>{eventTitle}</Text>

            <View style={styles.eventDetail}>
              <Ionicons name="calendar-outline" size={18} color="rgba(255,255,255,0.6)" />
              <Text style={styles.eventDetailText}>{eventDate}</Text>
            </View>

            <View style={styles.eventDetail}>
              <Ionicons name="time-outline" size={18} color="rgba(255,255,255,0.6)" />
              <Text style={styles.eventDetailText}>{eventTime}</Text>
            </View>

            {eventLocation && (
              <View style={styles.eventDetail}>
                <Ionicons name="location-outline" size={18} color="rgba(255,255,255,0.6)" />
                <Text style={styles.eventDetailText}>{eventLocation}</Text>
              </View>
            )}

            {eventDescription && (
              <View style={styles.descriptionSection}>
                <Text style={styles.descriptionLabel}>Details</Text>
                <Text style={styles.descriptionText} numberOfLines={3}>
                  {eventDescription}
                </Text>
              </View>
            )}
          </View>

          {/* Info about calendar integration */}
          <View style={styles.infoCard}>
            <Ionicons name="information-circle" size={20} color="rgba(255,255,255,0.5)" />
            <Text style={styles.infoText}>
              Tap "Add Event" to open your calendar with these details.
            </Text>
          </View>
        </ScrollView>

        {/* Actions */}
        <View style={styles.actions}>
          <Pressable style={styles.cancelButton} onPress={onClose}>
            <Text style={styles.cancelButtonText}>Cancel</Text>
          </Pressable>
          <Pressable
            style={[styles.addButton, isAdding && styles.addButtonDisabled]}
            onPress={handleAddToCalendar}
            disabled={isAdding}
          >
            <Text style={styles.addButtonText}>
              {isAdding ? 'Opening...' : 'Add Event'}
            </Text>
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
    maxHeight: '70%',
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
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: 'white',
  },
  content: {
    flex: 1,
    padding: 20,
  },
  eventCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    borderRadius: 16,
    padding: 16,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  eventTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: 'white',
    marginBottom: 16,
  },
  eventDetail: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginBottom: 10,
  },
  eventDetailText: {
    fontSize: 15,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  descriptionSection: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.1)',
  },
  descriptionLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: 'rgba(255, 255, 255, 0.5)',
    marginBottom: 6,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  descriptionText: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    lineHeight: 20,
  },
  infoCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderRadius: 12,
    padding: 12,
    marginBottom: 20,
  },
  infoText: {
    flex: 1,
    fontSize: 13,
    color: 'rgba(255, 255, 255, 0.5)',
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
  addButton: {
    flex: 1,
    paddingVertical: 16,
    backgroundColor: '#22c55e',
    borderRadius: 14,
    alignItems: 'center',
  },
  addButtonDisabled: {
    opacity: 0.6,
  },
  addButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
});
