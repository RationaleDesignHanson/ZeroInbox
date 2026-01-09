/**
 * GenericActionModal - Universal fallback for actions without specific modals
 * Dynamically renders based on action config
 */

import React, { useState } from 'react';
import { View, Text, StyleSheet, Alert, Linking } from 'react-native';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';
import { getActionConfig } from '../../data/actionConfigs';
import {
  BaseActionModal,
  ModalSection,
  InfoRow,
  ActionButton,
} from './BaseActionModal';

interface GenericActionModalProps {
  visible: boolean;
  onClose: () => void;
  onConfirm?: () => void;
  card: EmailCard;
  action: SuggestedAction;
}

export function GenericActionModal({ visible, onClose, onConfirm, card, action }: GenericActionModalProps) {
  const [isProcessing, setIsProcessing] = useState(false);
  
  // Get action config from registry
  const actionConfig = getActionConfig(action.id);
  const context = action.context || {};

  const icon = actionConfig?.icon || 'flash-outline';
  const iconColor = actionConfig?.iconColor || '#667eea';
  const category = actionConfig?.category || 'Action';
  const description = actionConfig?.description || `Execute ${action.displayName}`;

  const handleExecute = async () => {
    HapticService.mediumImpact();
    setIsProcessing(true);

    // Check if there's a URL to open
    const url = context.url || context.link;
    if (url) {
      await Linking.openURL(url);
      setIsProcessing(false);
      if (onConfirm) onConfirm();
      onClose();
      return;
    }

    // Simulate action execution
    setTimeout(() => {
      setIsProcessing(false);
      HapticService.success();
      Alert.alert(
        '✓ Action Completed',
        `${action.displayName} has been executed successfully.`,
        [{ text: 'OK', onPress: () => {
          if (onConfirm) onConfirm();
          onClose();
        }}]
      );
    }, 1000);
  };

  // Render context items dynamically
  const contextItems = Object.entries(context).filter(
    ([key]) => !['url', 'link'].includes(key)
  );

  return (
    <BaseActionModal
      visible={visible}
      onClose={onClose}
      card={card}
      action={action}
      title={action.displayName}
      icon={icon}
      iconColor={iconColor}
      gradientColors={[iconColor, '#667eea']}
      footer={
        <>
          <ActionButton
            title={`${action.displayName}`}
            icon="checkmark-circle-outline"
            onPress={handleExecute}
            loading={isProcessing}
          />
          <ActionButton
            title="Cancel"
            icon="close-outline"
            onPress={onClose}
            variant="secondary"
          />
        </>
      }
    >
      {/* Category Badge */}
      <View style={styles.categoryBadge}>
        <Text style={styles.categoryText}>{category}</Text>
      </View>

      {/* Description */}
      <View style={styles.descriptionBox}>
        <Text style={styles.descriptionText}>{description}</Text>
      </View>

      {/* Context Data */}
      {contextItems.length > 0 && (
        <ModalSection title="DETAILS">
          {contextItems.map(([key, value]) => (
            <InfoRow
              key={key}
              icon="document-text-outline"
              iconColor="#64748b"
              label={key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
              value={String(value)}
            />
          ))}
        </ModalSection>
      )}

      {/* Email Info */}
      <ModalSection title="EMAIL">
        <InfoRow
          icon="person-outline"
          iconColor="#3b82f6"
          label="From"
          value={card.sender?.name || 'Unknown'}
        />
        <InfoRow
          icon="mail-outline"
          iconColor="#8b5cf6"
          label="Subject"
          value={card.title}
        />
      </ModalSection>
    </BaseActionModal>
  );
}

const styles = StyleSheet.create({
  categoryBadge: {
    alignSelf: 'center',
    backgroundColor: 'rgba(255,255,255,0.1)',
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: 14,
    marginBottom: 16,
  },
  categoryText: {
    fontSize: 12,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.6)',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  descriptionBox: {
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
  },
  descriptionText: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.8)',
    lineHeight: 20,
    textAlign: 'center',
  },
});
