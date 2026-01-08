/**
 * EmailComposerModal - Smart reply composer with AI suggestions
 * Used for reply, quick_reply, and respond actions
 */

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  Pressable,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';

// AI-generated reply suggestions (mock for now)
const REPLY_SUGGESTIONS = [
  "Thanks for your email. I'll get back to you shortly.",
  "Got it! I'll review this and respond by end of day.",
  "Thank you for the update. This looks good to proceed.",
  "I appreciate you reaching out. Let me check on this.",
];

interface EmailComposerModalProps {
  visible: boolean;
  onClose: () => void;
  onSend: (message: string) => void;
  card: EmailCard;
  action: SuggestedAction;
  context?: Record<string, string>;
}

export function EmailComposerModal({
  visible,
  onClose,
  onSend,
  card,
  action,
  context,
}: EmailComposerModalProps) {
  const insets = useSafeAreaInsets();
  const [message, setMessage] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [selectedSuggestion, setSelectedSuggestion] = useState<number | null>(null);

  // Reset state when modal opens
  useEffect(() => {
    if (visible) {
      setMessage('');
      setSelectedSuggestion(null);
      setIsSending(false);
    }
  }, [visible]);

  const recipientEmail = context?.senderEmail || card.sender?.email || 'Unknown';
  const recipientName = context?.senderName || card.sender?.name || 'Recipient';
  const subject = `Re: ${card.title}`;

  const handleSelectSuggestion = (index: number) => {
    HapticService.selection();
    setSelectedSuggestion(index);
    setMessage(REPLY_SUGGESTIONS[index]);
  };

  const handleSend = async () => {
    if (!message.trim()) return;

    HapticService.mediumImpact();
    setIsSending(true);

    // Simulate sending delay
    await new Promise((resolve) => setTimeout(resolve, 1000));

    onSend(message);
    setIsSending(false);
  };

  if (!visible) return null;

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
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
          <Pressable onPress={onClose} style={styles.headerButton}>
            <Text style={styles.cancelText}>Cancel</Text>
          </Pressable>
          <Text style={styles.headerTitle}>Reply</Text>
          <Pressable
            onPress={handleSend}
            style={[styles.headerButton, styles.sendButton]}
            disabled={!message.trim() || isSending}
          >
            {isSending ? (
              <ActivityIndicator size="small" color="#667eea" />
            ) : (
              <Ionicons
                name="send"
                size={20}
                color={message.trim() ? '#667eea' : 'rgba(255,255,255,0.3)'}
              />
            )}
          </Pressable>
        </View>

        {/* Recipient Info */}
        <View style={styles.recipientSection}>
          <Text style={styles.recipientLabel}>To:</Text>
          <Text style={styles.recipientEmail}>{recipientName}</Text>
          <Text style={styles.recipientEmailSmall}>&lt;{recipientEmail}&gt;</Text>
        </View>

        <View style={styles.subjectSection}>
          <Text style={styles.subjectLabel}>Subject:</Text>
          <Text style={styles.subjectText} numberOfLines={1}>
            {subject}
          </Text>
        </View>

        {/* Message Input */}
        <ScrollView style={styles.scrollContent} showsVerticalScrollIndicator={false}>
          <TextInput
            style={styles.messageInput}
            placeholder="Write your reply..."
            placeholderTextColor="rgba(255,255,255,0.4)"
            multiline
            value={message}
            onChangeText={setMessage}
            autoFocus
          />

          {/* AI Suggestions */}
          <View style={styles.suggestionsSection}>
            <Text style={styles.suggestionsTitle}>
              <Ionicons name="sparkles" size={14} color="#667eea" /> Quick Replies
            </Text>
            <View style={styles.suggestionsList}>
              {REPLY_SUGGESTIONS.map((suggestion, index) => (
                <Pressable
                  key={index}
                  style={[
                    styles.suggestionChip,
                    selectedSuggestion === index && styles.suggestionChipSelected,
                  ]}
                  onPress={() => handleSelectSuggestion(index)}
                >
                  <Text
                    style={[
                      styles.suggestionText,
                      selectedSuggestion === index && styles.suggestionTextSelected,
                    ]}
                    numberOfLines={2}
                  >
                    {suggestion}
                  </Text>
                </Pressable>
              ))}
            </View>
          </View>
        </ScrollView>
      </View>
    </KeyboardAvoidingView>
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
    maxHeight: '85%',
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
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.1)',
  },
  headerButton: {
    padding: 8,
    minWidth: 60,
  },
  headerTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: 'white',
  },
  cancelText: {
    fontSize: 16,
    color: '#667eea',
  },
  sendButton: {
    alignItems: 'flex-end',
  },
  recipientSection: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.05)',
    gap: 8,
  },
  recipientLabel: {
    fontSize: 15,
    color: 'rgba(255, 255, 255, 0.5)',
  },
  recipientEmail: {
    fontSize: 15,
    color: 'white',
    fontWeight: '500',
  },
  recipientEmailSmall: {
    fontSize: 13,
    color: 'rgba(255, 255, 255, 0.4)',
  },
  subjectSection: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.05)',
    gap: 8,
  },
  subjectLabel: {
    fontSize: 15,
    color: 'rgba(255, 255, 255, 0.5)',
  },
  subjectText: {
    fontSize: 15,
    color: 'white',
    flex: 1,
  },
  scrollContent: {
    flex: 1,
  },
  messageInput: {
    fontSize: 16,
    color: 'white',
    paddingHorizontal: 16,
    paddingVertical: 16,
    minHeight: 150,
    textAlignVertical: 'top',
  },
  suggestionsSection: {
    paddingHorizontal: 16,
    paddingTop: 8,
    paddingBottom: 16,
  },
  suggestionsTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: 'rgba(255, 255, 255, 0.6)',
    marginBottom: 12,
  },
  suggestionsList: {
    gap: 8,
  },
  suggestionChip: {
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    borderRadius: 12,
    padding: 12,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  suggestionChipSelected: {
    backgroundColor: 'rgba(102, 126, 234, 0.2)',
    borderColor: 'rgba(102, 126, 234, 0.5)',
  },
  suggestionText: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
    lineHeight: 20,
  },
  suggestionTextSelected: {
    color: '#a5b4fc',
  },
});

