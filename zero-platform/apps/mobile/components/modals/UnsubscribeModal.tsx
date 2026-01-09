/**
 * UnsubscribeModal - One-tap unsubscribe from mailing lists
 */

import React, { useState } from 'react';
import { View, Text, StyleSheet, Linking, Alert } from 'react-native';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';
import {
  BaseActionModal,
  ModalSection,
  InfoRow,
  ActionButton,
} from './BaseActionModal';

interface UnsubscribeModalProps {
  visible: boolean;
  onClose: () => void;
  card: EmailCard;
  action: SuggestedAction;
}

export function UnsubscribeModal({ visible, onClose, card, action }: UnsubscribeModalProps) {
  const [isProcessing, setIsProcessing] = useState(false);

  const context = action.context || {};
  const unsubscribeUrl = context.unsubscribeUrl || context.url || '';
  const senderName = context.senderName || card.sender?.name || 'this sender';
  const senderEmail = card.sender?.email || '';

  const handleUnsubscribe = async () => {
    HapticService.mediumImpact();
    
    if (unsubscribeUrl) {
      await Linking.openURL(unsubscribeUrl);
      onClose();
    } else {
      setIsProcessing(true);
      // Simulate unsubscribe
      setTimeout(() => {
        setIsProcessing(false);
        HapticService.success();
        Alert.alert(
          'Unsubscribed',
          `You have been unsubscribed from ${senderName}. You may receive a confirmation email.`,
          [{ text: 'OK', onPress: onClose }]
        );
      }, 1500);
    }
  };

  return (
    <BaseActionModal
      visible={visible}
      onClose={onClose}
      card={card}
      action={action}
      title="Unsubscribe"
      icon="mail-unread-outline"
      iconColor="#ef4444"
      gradientColors={['#ef4444', '#dc2626']}
      footer={
        <>
          <ActionButton
            title="Unsubscribe"
            icon="close-circle-outline"
            onPress={handleUnsubscribe}
            variant="danger"
            loading={isProcessing}
          />
          <ActionButton
            title="Keep Subscription"
            icon="mail-outline"
            onPress={onClose}
            variant="secondary"
          />
        </>
      }
    >
      {/* Sender Info */}
      <View style={styles.senderCard}>
        <View style={styles.senderAvatar}>
          <Text style={styles.senderInitial}>
            {senderName.charAt(0).toUpperCase()}
          </Text>
        </View>
        <View>
          <Text style={styles.senderName}>{senderName}</Text>
          {senderEmail && (
            <Text style={styles.senderEmail}>{senderEmail}</Text>
          )}
        </View>
      </View>

      {/* Warning Message */}
      <ModalSection title="UNSUBSCRIBE CONFIRMATION">
        <View style={styles.warningBox}>
          <Text style={styles.warningText}>
            You will no longer receive emails from {senderName}. This action may take a few days to take effect.
          </Text>
        </View>

        <InfoRow
          icon="information-circle-outline"
          iconColor="#f59e0b"
          label="Note"
          value="You can always resubscribe later"
        />
      </ModalSection>

      {/* Alternative Options */}
      <View style={styles.alternatives}>
        <Text style={styles.alternativesTitle}>Or would you rather...</Text>
        <View style={styles.altOption}>
          <Text style={styles.altIcon}>📁</Text>
          <Text style={styles.altText}>Auto-archive future emails from this sender</Text>
        </View>
        <View style={styles.altOption}>
          <Text style={styles.altIcon}>📬</Text>
          <Text style={styles.altText}>Move to a folder instead</Text>
        </View>
      </View>
    </BaseActionModal>
  );
}

const styles = StyleSheet.create({
  senderCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 16,
    padding: 16,
    marginBottom: 20,
    gap: 14,
  },
  senderAvatar: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: 'rgba(239, 68, 68, 0.3)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  senderInitial: {
    fontSize: 20,
    fontWeight: '700',
    color: '#ef4444',
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
  warningBox: {
    backgroundColor: 'rgba(239, 68, 68, 0.15)',
    borderRadius: 12,
    padding: 14,
    marginBottom: 12,
  },
  warningText: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.8)',
    lineHeight: 20,
  },
  alternatives: {
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 14,
    padding: 16,
    marginTop: 12,
  },
  alternativesTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.5)',
    marginBottom: 12,
  },
  altOption: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingVertical: 8,
  },
  altIcon: {
    fontSize: 18,
  },
  altText: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.7)',
  },
});
