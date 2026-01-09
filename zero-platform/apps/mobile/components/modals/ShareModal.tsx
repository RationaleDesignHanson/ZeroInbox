/**
 * ShareModal - Share content via iOS share sheet
 */

import React from 'react';
import { View, Text, StyleSheet, Share as RNShare, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';
import {
  BaseActionModal,
  ActionButton,
} from './BaseActionModal';

interface ShareModalProps {
  visible: boolean;
  onClose: () => void;
  card: EmailCard;
  action: SuggestedAction;
}

const SHARE_OPTIONS = [
  { id: 'message', label: 'Messages', icon: 'chatbubble-outline', color: '#22c55e' },
  { id: 'email', label: 'Email', icon: 'mail-outline', color: '#3b82f6' },
  { id: 'copy', label: 'Copy Link', icon: 'copy-outline', color: '#64748b' },
  { id: 'more', label: 'More...', icon: 'ellipsis-horizontal-outline', color: '#8b5cf6' },
];

export function ShareModal({ visible, onClose, card, action }: ShareModalProps) {
  const generateShareContent = () => {
    let content = card.title;
    if (card.summary) {
      content += `\n\n${card.summary}`;
    }
    return content;
  };

  const handleShare = async () => {
    HapticService.mediumImpact();
    
    try {
      const result = await RNShare.share({
        message: generateShareContent(),
        title: card.title,
      });
      
      if (result.action === RNShare.sharedAction) {
        HapticService.success();
        onClose();
      }
    } catch (error) {
      console.error('Share failed:', error);
    }
  };

  const handleCopy = () => {
    HapticService.lightImpact();
    // In real app, use Clipboard.setStringAsync
    HapticService.success();
    onClose();
  };

  return (
    <BaseActionModal
      visible={visible}
      onClose={onClose}
      card={card}
      action={action}
      title="Share"
      icon="share-outline"
      iconColor="#3b82f6"
      gradientColors={['#3b82f6', '#2563eb']}
      footer={
        <ActionButton
          title="Share via..."
          icon="share-outline"
          onPress={handleShare}
        />
      }
    >
      {/* Preview */}
      <View style={styles.previewCard}>
        <Text style={styles.previewTitle}>{card.title}</Text>
        {card.summary && (
          <Text style={styles.previewSummary} numberOfLines={3}>
            {card.summary}
          </Text>
        )}
        <View style={styles.previewMeta}>
          <Ionicons name="person-outline" size={14} color="rgba(255,255,255,0.5)" />
          <Text style={styles.previewMetaText}>
            From: {card.sender?.name || 'Unknown'}
          </Text>
        </View>
      </View>

      {/* Quick Share Options */}
      <View style={styles.optionsGrid}>
        {SHARE_OPTIONS.map((option) => (
          <Pressable
            key={option.id}
            style={styles.optionItem}
            onPress={option.id === 'copy' ? handleCopy : handleShare}
          >
            <View style={[styles.optionIcon, { backgroundColor: `${option.color}20` }]}>
              <Ionicons
                name={option.icon as keyof typeof Ionicons.glyphMap}
                size={24}
                color={option.color}
              />
            </View>
            <Text style={styles.optionLabel}>{option.label}</Text>
          </Pressable>
        ))}
      </View>
    </BaseActionModal>
  );
}

const styles = StyleSheet.create({
  previewCard: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 14,
    padding: 16,
    marginBottom: 20,
  },
  previewTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
    marginBottom: 8,
  },
  previewSummary: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.7)',
    lineHeight: 20,
    marginBottom: 12,
  },
  previewMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  previewMetaText: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.5)',
  },
  optionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  optionItem: {
    width: '47%',
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 14,
    padding: 16,
    alignItems: 'center',
  },
  optionIcon: {
    width: 50,
    height: 50,
    borderRadius: 25,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 8,
  },
  optionLabel: {
    fontSize: 13,
    fontWeight: '500',
    color: 'white',
  },
});
