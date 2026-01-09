/**
 * NewsletterSummaryModal - AI-generated newsletter summary (Premium)
 */

import React from 'react';
import { View, Text, StyleSheet, Linking, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';
import {
  BaseActionModal,
  ModalSection,
  ActionButton,
} from './BaseActionModal';

interface NewsletterSummaryModalProps {
  visible: boolean;
  onClose: () => void;
  card: EmailCard;
  action: SuggestedAction;
}

export function NewsletterSummaryModal({ visible, onClose, card, action }: NewsletterSummaryModalProps) {
  const context = action.context || {};
  const summary = context.summaryText || card.summary || 'AI-generated summary will appear here.';
  const topLinks = (context.topLinks as string[]) || [];

  const handleViewFull = () => {
    HapticService.lightImpact();
    // Open full newsletter
    onClose();
  };

  const handleOpenLink = async (url: string) => {
    HapticService.lightImpact();
    await Linking.openURL(url);
  };

  return (
    <BaseActionModal
      visible={visible}
      onClose={onClose}
      card={card}
      action={action}
      title="Newsletter Summary"
      icon="newspaper-outline"
      iconColor="#8b5cf6"
      gradientColors={['#8b5cf6', '#7c3aed']}
      footer={
        <>
          <ActionButton
            title="View Full Newsletter"
            icon="document-text-outline"
            onPress={handleViewFull}
          />
          <ActionButton
            title="Done"
            icon="checkmark-outline"
            onPress={onClose}
            variant="secondary"
          />
        </>
      }
    >
      {/* Premium Badge */}
      <View style={styles.premiumBadge}>
        <Ionicons name="sparkles" size={16} color="#f59e0b" />
        <Text style={styles.premiumText}>AI Summary</Text>
      </View>

      {/* Summary */}
      <ModalSection title="KEY POINTS">
        <Text style={styles.summaryText}>{summary}</Text>
      </ModalSection>

      {/* Top Links */}
      {topLinks.length > 0 && (
        <ModalSection title="TOP LINKS">
          {topLinks.map((link, index) => (
            <Pressable
              key={index}
              style={styles.linkItem}
              onPress={() => handleOpenLink(link)}
            >
              <Ionicons name="link-outline" size={18} color="#3b82f6" />
              <Text style={styles.linkText} numberOfLines={1}>{link}</Text>
              <Ionicons name="open-outline" size={16} color="rgba(255,255,255,0.4)" />
            </Pressable>
          ))}
        </ModalSection>
      )}

      {/* Reading Time */}
      <View style={styles.readingTime}>
        <Ionicons name="time-outline" size={16} color="rgba(255,255,255,0.5)" />
        <Text style={styles.readingTimeText}>
          Original: ~5 min read • Summary: 30 seconds
        </Text>
      </View>
    </BaseActionModal>
  );
}

const styles = StyleSheet.create({
  premiumBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'center',
    gap: 6,
    backgroundColor: 'rgba(245, 158, 11, 0.2)',
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    marginBottom: 20,
  },
  premiumText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#f59e0b',
  },
  summaryText: {
    fontSize: 15,
    color: 'rgba(255,255,255,0.9)',
    lineHeight: 24,
  },
  linkItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.05)',
  },
  linkText: {
    flex: 1,
    fontSize: 14,
    color: '#3b82f6',
  },
  readingTime: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    marginTop: 20,
  },
  readingTimeText: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.5)',
  },
});
