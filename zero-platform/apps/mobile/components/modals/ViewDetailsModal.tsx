/**
 * ViewDetailsModal - Generic fallback for viewing email/card details
 */

import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';
import {
  BaseActionModal,
  ModalSection,
  InfoRow,
  ActionButton,
} from './BaseActionModal';

interface ViewDetailsModalProps {
  visible: boolean;
  onClose: () => void;
  card: EmailCard;
  action: SuggestedAction;
}

export function ViewDetailsModal({ visible, onClose, card, action }: ViewDetailsModalProps) {
  const handleClose = () => {
    HapticService.lightImpact();
    onClose();
  };

  return (
    <BaseActionModal
      visible={visible}
      onClose={onClose}
      card={card}
      action={action}
      title="Email Details"
      icon="document-text-outline"
      iconColor="#64748b"
      gradientColors={['#64748b', '#475569']}
      footer={
        <ActionButton
          title="Done"
          icon="checkmark-outline"
          onPress={handleClose}
          variant="secondary"
        />
      }
    >
      {/* Email Header */}
      <ModalSection title="FROM">
        <View style={styles.senderRow}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>
              {(card.sender?.name || 'U').charAt(0).toUpperCase()}
            </Text>
          </View>
          <View style={styles.senderInfo}>
            <Text style={styles.senderName}>{card.sender?.name || 'Unknown Sender'}</Text>
            <Text style={styles.senderEmail}>{card.sender?.email || ''}</Text>
          </View>
        </View>
      </ModalSection>

      {/* Subject */}
      <ModalSection title="SUBJECT">
        <Text style={styles.subject}>{card.title}</Text>
      </ModalSection>

      {/* Summary */}
      {card.summary && (
        <ModalSection title="SUMMARY">
          <Text style={styles.summary}>{card.summary}</Text>
        </ModalSection>
      )}

      {/* AI Analysis */}
      {card.intent && (
        <ModalSection title="AI ANALYSIS">
          <InfoRow
            icon="flash-outline"
            iconColor="#f59e0b"
            label="Intent"
            value={card.intent}
          />
          <InfoRow
            icon="flag-outline"
            iconColor="#ef4444"
            label="Priority"
            value={card.priority || 'Normal'}
          />
          {card.category && (
            <InfoRow
              icon="folder-outline"
              iconColor="#3b82f6"
              label="Category"
              value={card.category}
            />
          )}
        </ModalSection>
      )}

      {/* Suggested Actions */}
      {card.suggestedActions && card.suggestedActions.length > 0 && (
        <ModalSection title="SUGGESTED ACTIONS">
          {card.suggestedActions.map((action, index) => (
            <View key={index} style={styles.actionItem}>
              <Text style={styles.actionIcon}>{action.isPrimary ? '⚡' : '📌'}</Text>
              <Text style={styles.actionName}>{action.displayName}</Text>
            </View>
          ))}
        </ModalSection>
      )}
    </BaseActionModal>
  );
}

const styles = StyleSheet.create({
  senderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  avatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(102, 126, 234, 0.3)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    fontSize: 18,
    fontWeight: '700',
    color: '#667eea',
  },
  senderInfo: {
    flex: 1,
  },
  senderName: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
  senderEmail: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.5)',
    marginTop: 2,
  },
  subject: {
    fontSize: 16,
    fontWeight: '500',
    color: 'white',
    lineHeight: 22,
  },
  summary: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.8)',
    lineHeight: 20,
  },
  actionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingVertical: 8,
  },
  actionIcon: {
    fontSize: 18,
  },
  actionName: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.8)',
  },
});
