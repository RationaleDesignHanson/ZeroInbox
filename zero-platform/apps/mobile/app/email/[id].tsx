/**
 * Email Detail Screen
 * Full email view with body, AI analysis, and actions
 */

import React, { useState, useMemo, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  ScrollView,
  Modal,
  Platform,
} from 'react-native';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { BlurView } from 'expo-blur';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { MOCK_MAIL_EMAILS, MOCK_ADS_EMAILS } from '../../data/mockEmails';
import { HapticService } from '../../services/HapticService';
import { ActionRouter } from '../../services/ActionRouter';
import {
  EmailComposerModal,
  CalendarModal,
  ConfirmationModal,
} from '../../components/modals';

// Priority colors
const PRIORITY_COLORS = {
  high: '#ef4444',
  medium: '#f59e0b',
  low: '#22c55e',
};

export default function EmailDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();

  // Find the email from mock data
  const email = useMemo(() => {
    const allEmails = [...MOCK_MAIL_EMAILS, ...MOCK_ADS_EMAILS];
    return allEmails.find((e) => e.id === id);
  }, [id]);

  // Modal state
  const [showReplyModal, setShowReplyModal] = useState(false);
  const [showCalendarModal, setShowCalendarModal] = useState(false);
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [pendingAction, setPendingAction] = useState<SuggestedAction | null>(null);

  const handleClose = () => {
    router.back();
  };

  const handleAction = useCallback(async (action: SuggestedAction) => {
    HapticService.mediumImpact();

    // Check action type and show appropriate modal
    const route = ActionRouter.routeAction(action, email!);

    if (route.type === 'GO_TO') {
      // External action - execute directly
      await ActionRouter.executeAction(action, email!);
    } else if (route.modalType === 'quick_reply') {
      setPendingAction(action);
      setShowReplyModal(true);
    } else if (route.modalType === 'add_to_calendar') {
      setPendingAction(action);
      setShowCalendarModal(true);
    } else {
      // Show confirmation modal for other actions
      setPendingAction(action);
      setShowConfirmModal(true);
    }
  }, [email]);

  const handleModalComplete = useCallback((message: string) => {
    HapticService.success();
    setShowReplyModal(false);
    setShowCalendarModal(false);
    setShowConfirmModal(false);
    setPendingAction(null);
    // Navigate back after action
    router.back();
  }, [router]);

  const handleModalClose = useCallback(() => {
    setShowReplyModal(false);
    setShowCalendarModal(false);
    setShowConfirmModal(false);
    setPendingAction(null);
  }, []);

  if (!email) {
    return (
      <View style={styles.container}>
        <SafeAreaView style={styles.safeArea}>
          <View style={styles.header}>
            <Pressable onPress={handleClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color="white" />
            </Pressable>
            <Text style={styles.headerTitle}>Email Not Found</Text>
            <View style={styles.headerRight} />
          </View>
          <View style={styles.errorContainer}>
            <Ionicons name="mail-outline" size={64} color="rgba(255,255,255,0.3)" />
            <Text style={styles.errorText}>Email not found</Text>
          </View>
        </SafeAreaView>
      </View>
    );
  }

  const primaryAction = ActionRouter.getPrimaryAction(email);
  const secondaryActions = ActionRouter.getSecondaryActions(email);

  return (
    <View style={styles.container}>
      <Stack.Screen options={{ headerShown: false }} />

      <SafeAreaView style={styles.safeArea} edges={['top']}>
        {/* Header */}
        <View style={styles.header}>
          <Pressable onPress={handleClose} style={styles.closeButton}>
            <Ionicons name="chevron-back" size={24} color="white" />
          </Pressable>
          <Text style={styles.headerTitle} numberOfLines={1}>
            {email.type === 'mail' ? 'Mail' : 'Promotion'}
          </Text>
          <Pressable style={styles.moreButton}>
            <Ionicons name="ellipsis-horizontal" size={24} color="white" />
          </Pressable>
        </View>

        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Sender Info */}
          <View style={styles.senderSection}>
            <View style={styles.avatar}>
              <Text style={styles.avatarText}>
                {(email.sender?.name || email.sender?.email || 'U')[0].toUpperCase()}
              </Text>
            </View>
            <View style={styles.senderInfo}>
              <Text style={styles.senderName}>{email.sender?.name || 'Unknown'}</Text>
              <Text style={styles.senderEmail}>{email.sender?.email || ''}</Text>
            </View>
            <Text style={styles.timeAgo}>{email.timeAgo}</Text>
          </View>

          {/* Subject */}
          <Text style={styles.subject}>{email.title}</Text>

          {/* Priority & Intent */}
          <View style={styles.metaRow}>
            {email.priority && (
              <View style={[styles.badge, { backgroundColor: PRIORITY_COLORS[email.priority] + '20' }]}>
                <View style={[styles.badgeDot, { backgroundColor: PRIORITY_COLORS[email.priority] }]} />
                <Text style={[styles.badgeText, { color: PRIORITY_COLORS[email.priority] }]}>
                  {email.priority.charAt(0).toUpperCase() + email.priority.slice(1)} Priority
                </Text>
              </View>
            )}
            {email.intent && (
              <View style={styles.intentBadge}>
                <Ionicons name="sparkles" size={12} color="#667eea" />
                <Text style={styles.intentText}>{email.intent}</Text>
              </View>
            )}
          </View>

          {/* AI Summary */}
          {email.aiGeneratedSummary && (
            <View style={styles.aiCard}>
              {Platform.OS === 'ios' ? (
                <BlurView intensity={30} tint="dark" style={StyleSheet.absoluteFill} />
              ) : (
                <View style={[StyleSheet.absoluteFill, styles.androidFallback]} />
              )}
              <View style={styles.aiContent}>
                <View style={styles.aiHeader}>
                  <Ionicons name="sparkles" size={16} color="#667eea" />
                  <Text style={styles.aiTitle}>AI Summary</Text>
                </View>
                <Text style={styles.aiText}>{email.aiGeneratedSummary}</Text>
              </View>
            </View>
          )}

          {/* Email Body */}
          <View style={styles.bodyCard}>
            {Platform.OS === 'ios' ? (
              <BlurView intensity={20} tint="dark" style={StyleSheet.absoluteFill} />
            ) : (
              <View style={[StyleSheet.absoluteFill, styles.androidFallback]} />
            )}
            <View style={styles.bodyContent}>
              <Text style={styles.bodyText}>
                {email.context?.body || email.summary || 'No email body available.'}
              </Text>
            </View>
          </View>

          {/* Suggested Actions */}
          {email.suggestedActions && email.suggestedActions.length > 0 && (
            <View style={styles.suggestedSection}>
              <Text style={styles.sectionTitle}>SUGGESTED ACTIONS</Text>
              <View style={styles.actionsList}>
                {email.suggestedActions.map((action, index) => (
                  <Pressable
                    key={action.id}
                    style={[
                      styles.actionChip,
                      action.isPrimary && styles.actionChipPrimary,
                    ]}
                    onPress={() => handleAction(action)}
                  >
                    {action.isPrimary && (
                      <Ionicons name="flash" size={16} color="white" style={styles.actionIcon} />
                    )}
                    <Text
                      style={[
                        styles.actionChipText,
                        action.isPrimary && styles.actionChipTextPrimary,
                      ]}
                    >
                      {action.displayName}
                    </Text>
                  </Pressable>
                ))}
              </View>
            </View>
          )}
        </ScrollView>

        {/* Bottom Action Bar */}
        <View style={styles.bottomBar}>
          {Platform.OS === 'ios' ? (
            <BlurView intensity={80} tint="dark" style={StyleSheet.absoluteFill} />
          ) : (
            <View style={[StyleSheet.absoluteFill, styles.androidFallbackBottom]} />
          )}
          <View style={styles.bottomContent}>
            {primaryAction ? (
              <Pressable
                style={styles.primaryActionButton}
                onPress={() => handleAction(primaryAction)}
              >
                <Ionicons name="flash" size={20} color="white" />
                <Text style={styles.primaryActionText}>{primaryAction.displayName}</Text>
              </Pressable>
            ) : (
              <Pressable
                style={styles.archiveButton}
                onPress={handleClose}
              >
                <Ionicons name="archive-outline" size={20} color="white" />
                <Text style={styles.archiveText}>Archive</Text>
              </Pressable>
            )}
          </View>
        </View>
      </SafeAreaView>

      {/* Reply Modal */}
      <Modal
        visible={showReplyModal}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={handleModalClose}
      >
        {pendingAction && (
          <EmailComposerModal
            visible={true}
            onClose={handleModalClose}
            onSend={() => handleModalComplete('Reply sent')}
            card={email}
            action={pendingAction}
          />
        )}
      </Modal>

      {/* Calendar Modal */}
      <Modal
        visible={showCalendarModal}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={handleModalClose}
      >
        {pendingAction && (
          <CalendarModal
            visible={true}
            onClose={handleModalClose}
            onAdd={() => handleModalComplete('Added to calendar')}
            card={email}
            action={pendingAction}
          />
        )}
      </Modal>

      {/* Confirmation Modal */}
      <Modal
        visible={showConfirmModal}
        animationType="fade"
        transparent
        onRequestClose={handleModalClose}
      >
        {pendingAction && (
          <ConfirmationModal
            visible={true}
            onClose={handleModalClose}
            onConfirm={() => handleModalComplete(pendingAction.displayName)}
            card={email}
            action={pendingAction}
          />
        )}
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0f',
  },
  safeArea: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.1)',
  },
  closeButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255,255,255,0.1)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: 'white',
    flex: 1,
    textAlign: 'center',
    marginHorizontal: 8,
  },
  moreButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerRight: {
    width: 40,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 100,
  },
  senderSection: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: 'rgba(102, 126, 234, 0.3)',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  avatarText: {
    fontSize: 20,
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
    marginBottom: 2,
  },
  senderEmail: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.5)',
  },
  timeAgo: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.4)',
  },
  subject: {
    fontSize: 22,
    fontWeight: '700',
    color: 'white',
    marginBottom: 12,
    lineHeight: 28,
  },
  metaRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 16,
  },
  badge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 4,
    paddingHorizontal: 10,
    borderRadius: 12,
    gap: 6,
  },
  badgeDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  badgeText: {
    fontSize: 12,
    fontWeight: '600',
  },
  intentBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 4,
    paddingHorizontal: 10,
    borderRadius: 12,
    backgroundColor: 'rgba(102, 126, 234, 0.15)',
    gap: 4,
  },
  intentText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#667eea',
  },
  aiCard: {
    borderRadius: 16,
    overflow: 'hidden',
    marginBottom: 16,
    borderWidth: 1,
    borderColor: 'rgba(102, 126, 234, 0.3)',
  },
  androidFallback: {
    backgroundColor: 'rgba(26, 26, 46, 0.9)',
  },
  aiContent: {
    padding: 16,
  },
  aiHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 8,
  },
  aiTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: '#667eea',
  },
  aiText: {
    fontSize: 15,
    color: 'rgba(255,255,255,0.85)',
    lineHeight: 22,
  },
  bodyCard: {
    borderRadius: 16,
    overflow: 'hidden',
    marginBottom: 20,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
  },
  bodyContent: {
    padding: 16,
  },
  bodyText: {
    fontSize: 15,
    color: 'rgba(255,255,255,0.8)',
    lineHeight: 24,
  },
  suggestedSection: {
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 12,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.5)',
    letterSpacing: 0.5,
    marginBottom: 12,
  },
  actionsList: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  actionChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 12,
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
  },
  actionChipPrimary: {
    backgroundColor: 'rgba(102, 126, 234, 0.2)',
    borderColor: 'rgba(102, 126, 234, 0.4)',
  },
  actionIcon: {
    marginRight: 6,
  },
  actionChipText: {
    fontSize: 14,
    fontWeight: '500',
    color: 'rgba(255,255,255,0.8)',
  },
  actionChipTextPrimary: {
    color: '#a5b4fc',
  },
  bottomBar: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    overflow: 'hidden',
    borderTopWidth: 1,
    borderTopColor: 'rgba(255,255,255,0.1)',
  },
  androidFallbackBottom: {
    backgroundColor: 'rgba(10, 10, 15, 0.95)',
  },
  bottomContent: {
    padding: 16,
    paddingBottom: 32,
  },
  primaryActionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#667eea',
    paddingVertical: 16,
    borderRadius: 14,
    gap: 8,
  },
  primaryActionText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
  archiveButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.1)',
    paddingVertical: 16,
    borderRadius: 14,
    gap: 8,
  },
  archiveText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
  errorContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  errorText: {
    fontSize: 18,
    color: 'rgba(255,255,255,0.6)',
    marginTop: 16,
  },
});
