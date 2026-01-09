/**
 * ModelTuningScreen - Train the AI with feedback
 * Based on iOS ModelTuningView.swift
 * 
 * Features:
 * - Email preview with category/action feedback
 * - Reward system (10 reviews = 1 free month)
 * - Privacy-first with local storage
 */

import React, { useState, useCallback, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Pressable,
  TextInput,
  Modal,
  ActivityIndicator,
  Alert,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { HapticService } from '../services/HapticService';
import { MOCK_MAIL_EMAILS, MOCK_ADS_EMAILS } from '../data/mockEmails';

// Action categories for feedback
const ACTION_CATEGORIES = [
  { id: 'documents', name: 'Documents & Files', actions: ['view_document', 'sign_form', 'review_attachment'] },
  { id: 'calendar', name: 'Calendar & Meetings', actions: ['schedule_meeting', 'add_to_calendar', 'rsvp_yes', 'rsvp_no'] },
  { id: 'shopping', name: 'Shopping & E-commerce', actions: ['track_package', 'view_order', 'return_item', 'buy_again'] },
  { id: 'billing', name: 'Billing & Payments', actions: ['pay_invoice', 'view_invoice', 'download_receipt'] },
  { id: 'account', name: 'Account & Security', actions: ['reset_password', 'verify_account', 'review_security'] },
  { id: 'general', name: 'General Actions', actions: ['reply', 'quick_reply', 'archive', 'save_for_later'] },
];

interface RewardStats {
  currentProgress: number;
  earnedMonths: number;
  totalFeedback: number;
}

export default function ModelTuningScreen() {
  // State
  const [currentEmailIndex, setCurrentEmailIndex] = useState(0);
  const [isLoading, setIsLoading] = useState(false);
  const [showConsent, setShowConsent] = useState(false);
  const [hasConsent, setHasConsent] = useState(true); // For demo, assume consent
  const [showDataInfo, setShowDataInfo] = useState(false);
  
  // Feedback state
  const [correctedCategory, setCorrectedCategory] = useState<'mail' | 'ads' | null>(null);
  const [missedActions, setMissedActions] = useState<Set<string>>(new Set());
  const [unnecessaryActions, setUnnecessaryActions] = useState<Set<string>>(new Set());
  const [notes, setNotes] = useState('');
  const [expandedCategory, setExpandedCategory] = useState<string | null>(null);
  
  // Rewards
  const [rewardStats, setRewardStats] = useState<RewardStats>({
    currentProgress: 3,
    earnedMonths: 0,
    totalFeedback: 3,
  });

  // Get all emails for tuning
  const allEmails = [...MOCK_MAIL_EMAILS, ...MOCK_ADS_EMAILS];
  const currentEmail = allEmails[currentEmailIndex % allEmails.length];

  // Initialize category on email change
  useEffect(() => {
    setCorrectedCategory(currentEmail.type as 'mail' | 'ads');
    setMissedActions(new Set());
    setUnnecessaryActions(new Set());
    setNotes('');
  }, [currentEmailIndex]);

  const handleClose = useCallback(() => {
    router.back();
  }, []);

  const handleSkip = useCallback(() => {
    HapticService.lightImpact();
    setCurrentEmailIndex((i) => i + 1);
  }, []);

  const handleSubmit = useCallback(() => {
    if (!correctedCategory) {
      Alert.alert('Select Category', 'Please select the correct category for this email.');
      return;
    }

    HapticService.success();
    
    // Update reward stats
    const newProgress = (rewardStats.currentProgress + 1) % 10;
    const earnedNew = newProgress === 0 && rewardStats.currentProgress === 9;
    
    setRewardStats({
      currentProgress: newProgress,
      earnedMonths: earnedNew ? rewardStats.earnedMonths + 1 : rewardStats.earnedMonths,
      totalFeedback: rewardStats.totalFeedback + 1,
    });

    if (earnedNew) {
      Alert.alert(
        '🎉 Free Month Earned!',
        'Congratulations! You\'ve earned a free month of Zero Premium by helping improve our AI!',
        [{ text: 'Continue', onPress: () => setCurrentEmailIndex((i) => i + 1) }]
      );
    } else {
      Alert.alert(
        'Feedback Submitted',
        `Progress: ${newProgress + 1}/10 toward free month. Thank you for helping improve Zero!`,
        [{ text: 'Next Email', onPress: () => setCurrentEmailIndex((i) => i + 1) }]
      );
    }
  }, [correctedCategory, rewardStats]);

  const toggleMissedAction = useCallback((actionId: string) => {
    HapticService.selection();
    setMissedActions((prev) => {
      const next = new Set(prev);
      if (next.has(actionId)) {
        next.delete(actionId);
      } else {
        next.add(actionId);
      }
      return next;
    });
  }, []);

  const toggleUnnecessaryAction = useCallback((actionId: string) => {
    HapticService.selection();
    setUnnecessaryActions((prev) => {
      const next = new Set(prev);
      if (next.has(actionId)) {
        next.delete(actionId);
      } else {
        next.add(actionId);
      }
      return next;
    });
  }, []);

  // Consent Dialog
  if (!hasConsent) {
    return (
      <ConsentDialog
        onAccept={() => setHasConsent(true)}
        onDecline={handleClose}
      />
    );
  }

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={['#0a0a1a', '#1a1a2e', '#0a0a1a']}
        style={StyleSheet.absoluteFill}
      />

      <SafeAreaView style={styles.safeArea} edges={['top']}>
        {/* Header */}
        <View style={styles.header}>
          <Pressable onPress={handleClose} style={styles.closeButton}>
            <Ionicons name="close" size={24} color="white" />
          </Pressable>

          {/* Reward Progress Pill */}
          <RewardProgressPill stats={rewardStats} />

          <Pressable onPress={() => setShowDataInfo(true)} style={styles.infoButton}>
            <Ionicons name="ellipsis-horizontal" size={24} color="white" />
          </Pressable>
        </View>

        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Email Preview Card */}
          <View style={styles.section}>
            <SectionHeader icon="mail" title="EMAIL PREVIEW" color="#667eea" />
            <View style={styles.card}>
              <View style={styles.emailMeta}>
                <Ionicons name="person" size={16} color="#3b82f6" />
                <Text style={styles.metaLabel}>From:</Text>
                <Text style={styles.metaValue}>{currentEmail.sender?.name || 'Unknown'}</Text>
              </View>
              <View style={styles.emailMeta}>
                <Ionicons name="mail" size={16} color="#8b5cf6" />
                <Text style={styles.metaLabel}>Subject:</Text>
                <Text style={styles.metaValue} numberOfLines={2}>{currentEmail.title}</Text>
              </View>
              <Text style={styles.snippet} numberOfLines={4}>
                {currentEmail.summary}
              </Text>
              <View style={styles.emailFooter}>
                <Text style={styles.timeAgo}>{currentEmail.timeAgo}</Text>
                {currentEmail.intent && (
                  <View style={styles.intentBadge}>
                    <Ionicons name="sparkles" size={12} color="#667eea" />
                    <Text style={styles.intentText}>{currentEmail.intent}</Text>
                  </View>
                )}
              </View>
            </View>
          </View>

          {/* Category Feedback */}
          <View style={styles.section}>
            <SectionHeader icon="folder" title="EMAIL CATEGORY" color="#8b5cf6" />
            <View style={styles.card}>
              <View style={styles.detectedRow}>
                <Text style={styles.detectedLabel}>Detected:</Text>
                <View style={[styles.categoryChip, { backgroundColor: currentEmail.type === 'mail' ? '#3b82f620' : '#22c55e20' }]}>
                  <Text style={[styles.categoryChipText, { color: currentEmail.type === 'mail' ? '#3b82f6' : '#22c55e' }]}>
                    {currentEmail.type === 'mail' ? '📬 Mail' : '🏷️ Ads'}
                  </Text>
                </View>
              </View>

              <Text style={styles.correctLabel}>Correct category:</Text>
              <View style={styles.categoryButtons}>
                <Pressable
                  style={[styles.categoryButton, correctedCategory === 'mail' && styles.categoryButtonActive]}
                  onPress={() => { HapticService.selection(); setCorrectedCategory('mail'); }}
                >
                  <Ionicons name="mail" size={20} color={correctedCategory === 'mail' ? '#fff' : '#3b82f6'} />
                  <Text style={[styles.categoryButtonText, correctedCategory === 'mail' && styles.categoryButtonTextActive]}>
                    Mail
                  </Text>
                </Pressable>
                <Pressable
                  style={[styles.categoryButton, correctedCategory === 'ads' && styles.categoryButtonActiveAds]}
                  onPress={() => { HapticService.selection(); setCorrectedCategory('ads'); }}
                >
                  <Ionicons name="pricetag" size={20} color={correctedCategory === 'ads' ? '#fff' : '#22c55e'} />
                  <Text style={[styles.categoryButtonText, correctedCategory === 'ads' && styles.categoryButtonTextActive]}>
                    Ads
                  </Text>
                </Pressable>
              </View>
            </View>
          </View>

          {/* Action Feedback */}
          <View style={styles.section}>
            <SectionHeader icon="flash" title="SUGGESTED ACTIONS" color="#eab308" />
            <View style={styles.card}>
              {/* Current suggested actions */}
              <Text style={styles.subLabel}>Currently Suggested:</Text>
              <View style={styles.actionChips}>
                {currentEmail.suggestedActions?.map((action) => (
                  <View key={action.id} style={styles.actionChipBlue}>
                    <Text style={styles.actionChipText}>{action.displayName}</Text>
                  </View>
                ))}
              </View>

              <View style={styles.divider} />

              {/* Missed actions */}
              <Text style={styles.subLabel}>Missed Actions (should have been suggested):</Text>
              {ACTION_CATEGORIES.map((category) => (
                <View key={category.id}>
                  <Pressable
                    style={styles.categoryHeader}
                    onPress={() => setExpandedCategory(expandedCategory === category.id ? null : category.id)}
                  >
                    <Text style={styles.categoryName}>{category.name}</Text>
                    <Ionicons
                      name={expandedCategory === category.id ? 'chevron-down' : 'chevron-forward'}
                      size={16}
                      color="rgba(255,255,255,0.5)"
                    />
                  </Pressable>
                  {expandedCategory === category.id && (
                    <View style={styles.actionChips}>
                      {category.actions.map((actionId) => (
                        <Pressable
                          key={actionId}
                          style={[styles.actionChipOrange, missedActions.has(actionId) && styles.actionChipSelected]}
                          onPress={() => toggleMissedAction(actionId)}
                        >
                          <Text style={styles.actionChipText}>{actionId.replace(/_/g, ' ')}</Text>
                        </Pressable>
                      ))}
                    </View>
                  )}
                </View>
              ))}

              <View style={styles.divider} />

              {/* Unnecessary actions */}
              <Text style={styles.subLabel}>Unnecessary Actions (shouldn't have been suggested):</Text>
              <View style={styles.actionChips}>
                {currentEmail.suggestedActions?.map((action) => (
                  <Pressable
                    key={action.id}
                    style={[styles.actionChipRed, unnecessaryActions.has(action.id) && styles.actionChipSelectedRed]}
                    onPress={() => toggleUnnecessaryAction(action.id)}
                  >
                    <Text style={styles.actionChipText}>{action.displayName}</Text>
                  </Pressable>
                ))}
              </View>
            </View>
          </View>

          {/* Notes */}
          <View style={styles.section}>
            <Text style={styles.notesLabel}>Additional Notes (optional):</Text>
            <TextInput
              style={styles.notesInput}
              placeholder="Any additional feedback..."
              placeholderTextColor="rgba(255,255,255,0.3)"
              value={notes}
              onChangeText={setNotes}
              multiline
              numberOfLines={3}
            />
          </View>

          {/* Action Buttons */}
          <View style={styles.actionButtons}>
            <Pressable style={styles.submitButton} onPress={handleSubmit}>
              <Ionicons name="paper-plane" size={20} color="white" />
              <Text style={styles.submitButtonText}>Submit Feedback</Text>
            </Pressable>
            <Pressable style={styles.skipButton} onPress={handleSkip}>
              <Text style={styles.skipButtonText}>Skip This Email</Text>
            </Pressable>
          </View>

          <View style={{ height: 100 }} />
        </ScrollView>
      </SafeAreaView>

      {/* Data Info Modal */}
      <DataInfoModal visible={showDataInfo} onClose={() => setShowDataInfo(false)} stats={rewardStats} />
    </View>
  );
}

// Components

function SectionHeader({ icon, title, color }: { icon: string; title: string; color: string }) {
  return (
    <View style={styles.sectionHeader}>
      <Ionicons name={icon as any} size={16} color={color} />
      <Text style={styles.sectionTitle}>{title}</Text>
    </View>
  );
}

function RewardProgressPill({ stats }: { stats: RewardStats }) {
  const progress = stats.currentProgress / 10;

  return (
    <View style={styles.rewardPill}>
      <Ionicons name="trophy" size={16} color="#eab308" />
      <View style={styles.rewardProgress}>
        <Text style={styles.rewardText}>{stats.currentProgress}/10</Text>
        <View style={styles.progressBar}>
          <View style={[styles.progressFill, { width: `${progress * 100}%` }]} />
        </View>
      </View>
      {stats.earnedMonths > 0 && (
        <View style={styles.earnedBadge}>
          <Text style={styles.earnedText}>{stats.earnedMonths}</Text>
        </View>
      )}
    </View>
  );
}

function ConsentDialog({ onAccept, onDecline }: { onAccept: () => void; onDecline: () => void }) {
  return (
    <View style={styles.consentContainer}>
      <LinearGradient colors={['#0a0a1a', '#1a1a2e']} style={StyleSheet.absoluteFill} />
      <SafeAreaView style={styles.consentSafe}>
        <ScrollView contentContainerStyle={styles.consentContent}>
          <Ionicons name="brain" size={60} color="#06b6d4" />
          <Text style={styles.consentTitle}>Help Improve Zero's AI</Text>
          <Text style={styles.consentSubtitle}>
            Model Tuning collects email samples to improve classification accuracy.
          </Text>

          <View style={styles.privacyFeatures}>
            <PrivacyFeature icon="shield-checkmark" title="PII Automatically Redacted" description="Sensitive data removed" />
            <PrivacyFeature icon="phone-portrait" title="Stored Locally" description="Data stays on your device" />
            <PrivacyFeature icon="hand-left" title="You Control Export" description="Review before sharing" />
            <PrivacyFeature icon="trash" title="Delete Anytime" description="Clear all data whenever you want" />
          </View>

          <Pressable style={styles.consentAccept} onPress={onAccept}>
            <Text style={styles.consentAcceptText}>I Understand</Text>
          </Pressable>
          <Pressable style={styles.consentDecline} onPress={onDecline}>
            <Text style={styles.consentDeclineText}>Not Now</Text>
          </Pressable>
        </ScrollView>
      </SafeAreaView>
    </View>
  );
}

function PrivacyFeature({ icon, title, description }: { icon: string; title: string; description: string }) {
  return (
    <View style={styles.privacyFeature}>
      <Ionicons name={icon as any} size={24} color="#06b6d4" />
      <View style={styles.privacyText}>
        <Text style={styles.privacyTitle}>{title}</Text>
        <Text style={styles.privacyDesc}>{description}</Text>
      </View>
    </View>
  );
}

function DataInfoModal({ visible, onClose, stats }: { visible: boolean; onClose: () => void; stats: RewardStats }) {
  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet" onRequestClose={onClose}>
      <View style={styles.modalContainer}>
        <LinearGradient colors={['#0a0a1a', '#1a1a2e']} style={StyleSheet.absoluteFill} />
        <SafeAreaView style={styles.modalSafe}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Data Collection</Text>
            <Pressable onPress={onClose}>
              <Text style={styles.modalDone}>Done</Text>
            </Pressable>
          </View>

          <ScrollView contentContainerStyle={styles.modalContent}>
            <Text style={styles.modalSectionTitle}>What's Collected?</Text>

            <View style={styles.dataItems}>
              <DataItem icon="mail" title="Email Subjects" description="Sanitized with PII removed" />
              <DataItem icon="at" title="Sender Domains" description="Full addresses redacted" />
              <DataItem icon="document-text" title="Email Snippets" description="Preview text only" />
              <DataItem icon="checkmark-circle" title="Your Classifications" description="Category corrections" />
              <DataItem icon="flash" title="Action Feedback" description="Suggested action corrections" />
            </View>

            <View style={styles.statsCard}>
              <Text style={styles.statsTitle}>Storage Info</Text>
              <View style={styles.statRow}>
                <Text style={styles.statLabel}>Samples Collected:</Text>
                <Text style={styles.statValue}>{stats.totalFeedback}</Text>
              </View>
              <View style={styles.statRow}>
                <Text style={styles.statLabel}>Free Months Earned:</Text>
                <Text style={styles.statValue}>{stats.earnedMonths}</Text>
              </View>
            </View>

            <Pressable
              style={styles.exportButton}
              onPress={() => Alert.alert('Export', 'Export functionality would generate a JSONL file for sharing.')}
            >
              <Ionicons name="share-outline" size={20} color="#06b6d4" />
              <Text style={styles.exportButtonText}>Export Feedback ({stats.totalFeedback})</Text>
            </Pressable>

            <Pressable
              style={styles.clearButton}
              onPress={() => Alert.alert('Clear Data', 'This would clear all local feedback data.', [
                { text: 'Cancel', style: 'cancel' },
                { text: 'Clear', style: 'destructive' },
              ])}
            >
              <Ionicons name="trash-outline" size={20} color="#ef4444" />
              <Text style={styles.clearButtonText}>Clear All Feedback</Text>
            </Pressable>
          </ScrollView>
        </SafeAreaView>
      </View>
    </Modal>
  );
}

function DataItem({ icon, title, description }: { icon: string; title: string; description: string }) {
  return (
    <View style={styles.dataItem}>
      <Ionicons name={icon as any} size={20} color="#06b6d4" />
      <View style={styles.dataItemText}>
        <Text style={styles.dataItemTitle}>{title}</Text>
        <Text style={styles.dataItemDesc}>{description}</Text>
      </View>
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
  infoButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rewardPill: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.1)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
    gap: 8,
  },
  rewardProgress: {
    alignItems: 'center',
  },
  rewardText: {
    fontSize: 11,
    fontWeight: '600',
    color: 'white',
  },
  progressBar: {
    width: 50,
    height: 4,
    backgroundColor: 'rgba(255,255,255,0.2)',
    borderRadius: 2,
    marginTop: 2,
  },
  progressFill: {
    height: '100%',
    borderRadius: 2,
    backgroundColor: '#22c55e',
  },
  earnedBadge: {
    backgroundColor: '#ef4444',
    width: 18,
    height: 18,
    borderRadius: 9,
    alignItems: 'center',
    justifyContent: 'center',
  },
  earnedText: {
    fontSize: 10,
    fontWeight: '700',
    color: 'white',
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    padding: 16,
  },
  section: {
    marginBottom: 20,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 11,
    fontWeight: '700',
    color: 'rgba(255,255,255,0.5)',
    letterSpacing: 0.5,
  },
  card: {
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
  },
  emailMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 8,
  },
  metaLabel: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.5)',
  },
  metaValue: {
    fontSize: 14,
    fontWeight: '600',
    color: 'white',
    flex: 1,
  },
  snippet: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.6)',
    lineHeight: 20,
    marginTop: 12,
  },
  emailFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255,255,255,0.1)',
  },
  timeAgo: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.4)',
  },
  intentBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: 'rgba(102, 126, 234, 0.2)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
  },
  intentText: {
    fontSize: 11,
    color: '#667eea',
    fontWeight: '500',
  },
  detectedRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 16,
  },
  detectedLabel: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.6)',
  },
  categoryChip: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
  },
  categoryChipText: {
    fontSize: 14,
    fontWeight: '600',
  },
  correctLabel: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.6)',
    marginBottom: 12,
  },
  categoryButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  categoryButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 14,
    borderRadius: 12,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderWidth: 2,
    borderColor: 'rgba(255,255,255,0.2)',
  },
  categoryButtonActive: {
    backgroundColor: 'rgba(59, 130, 246, 0.3)',
    borderColor: '#3b82f6',
  },
  categoryButtonActiveAds: {
    backgroundColor: 'rgba(34, 197, 94, 0.3)',
    borderColor: '#22c55e',
  },
  categoryButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.7)',
  },
  categoryButtonTextActive: {
    color: 'white',
  },
  subLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: 'white',
    marginBottom: 12,
  },
  actionChips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 8,
  },
  actionChipBlue: {
    backgroundColor: 'rgba(59, 130, 246, 0.2)',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(59, 130, 246, 0.4)',
  },
  actionChipOrange: {
    backgroundColor: 'rgba(255,255,255,0.1)',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.2)',
  },
  actionChipRed: {
    backgroundColor: 'rgba(255,255,255,0.1)',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.2)',
  },
  actionChipSelected: {
    backgroundColor: 'rgba(249, 115, 22, 0.3)',
    borderColor: '#f97316',
  },
  actionChipSelectedRed: {
    backgroundColor: 'rgba(239, 68, 68, 0.3)',
    borderColor: '#ef4444',
  },
  actionChipText: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.8)',
    textTransform: 'capitalize',
  },
  divider: {
    height: 1,
    backgroundColor: 'rgba(255,255,255,0.1)',
    marginVertical: 16,
  },
  categoryHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
  },
  categoryName: {
    fontSize: 12,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.5)',
    textTransform: 'uppercase',
  },
  notesLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: 'white',
    marginBottom: 8,
  },
  notesInput: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 12,
    padding: 12,
    fontSize: 14,
    color: 'white',
    minHeight: 80,
    textAlignVertical: 'top',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
  },
  actionButtons: {
    gap: 12,
    marginTop: 8,
  },
  submitButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: '#3b82f6',
    paddingVertical: 16,
    borderRadius: 14,
  },
  submitButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
  skipButton: {
    alignItems: 'center',
    paddingVertical: 12,
  },
  skipButtonText: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.5)',
  },
  // Consent Dialog
  consentContainer: {
    flex: 1,
  },
  consentSafe: {
    flex: 1,
  },
  consentContent: {
    padding: 24,
    alignItems: 'center',
  },
  consentTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: 'white',
    marginTop: 20,
  },
  consentSubtitle: {
    fontSize: 15,
    color: 'rgba(255,255,255,0.6)',
    textAlign: 'center',
    marginTop: 8,
    marginBottom: 32,
  },
  privacyFeatures: {
    gap: 16,
    width: '100%',
    marginBottom: 32,
  },
  privacyFeature: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
  },
  privacyText: {
    flex: 1,
  },
  privacyTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: 'white',
  },
  privacyDesc: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.5)',
    marginTop: 2,
  },
  consentAccept: {
    width: '100%',
    backgroundColor: '#06b6d4',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  consentAcceptText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
  consentDecline: {
    width: '100%',
    paddingVertical: 16,
    alignItems: 'center',
  },
  consentDeclineText: {
    fontSize: 16,
    color: 'rgba(255,255,255,0.5)',
  },
  // Data Info Modal
  modalContainer: {
    flex: 1,
  },
  modalSafe: {
    flex: 1,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.1)',
  },
  modalTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: 'white',
  },
  modalDone: {
    fontSize: 16,
    fontWeight: '600',
    color: '#06b6d4',
  },
  modalContent: {
    padding: 20,
  },
  modalSectionTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: 'white',
    marginBottom: 20,
  },
  dataItems: {
    gap: 16,
    marginBottom: 24,
  },
  dataItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
  },
  dataItemText: {
    flex: 1,
  },
  dataItemTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: 'white',
  },
  dataItemDesc: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.5)',
    marginTop: 2,
  },
  statsCard: {
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
  },
  statsTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: 'white',
    marginBottom: 12,
  },
  statRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  statLabel: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.6)',
  },
  statValue: {
    fontSize: 14,
    fontWeight: '600',
    color: 'white',
  },
  exportButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: 'rgba(6, 182, 212, 0.2)',
    paddingVertical: 14,
    borderRadius: 12,
    marginBottom: 12,
  },
  exportButtonText: {
    fontSize: 15,
    fontWeight: '600',
    color: '#06b6d4',
  },
  clearButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: 'rgba(239, 68, 68, 0.1)',
    paddingVertical: 14,
    borderRadius: 12,
  },
  clearButtonText: {
    fontSize: 15,
    fontWeight: '600',
    color: '#ef4444',
  },
});
