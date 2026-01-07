/**
 * SwipeableCard - Email card matching Zero web demo styling
 * Features intent tags, dynamic summary, expandable AI analysis, and clean layout
 */

import React from 'react';
import { View, Text, StyleSheet, Platform } from 'react-native';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import type { EmailCard as EmailCardType, Priority } from '@zero/types';
import { AIAnalysisSection } from './AIAnalysisSection';

// Priority configuration
const PRIORITY_CONFIG: Record<Priority, { color: string; icon: string; label: string }> = {
  critical: { color: '#ef4444', icon: 'alert-circle', label: 'Critical' },
  high: { color: '#f97316', icon: 'arrow-up-circle', label: 'High' },
  medium: { color: '#eab308', icon: 'remove-circle', label: 'Medium' },
  low: { color: '#22c55e', icon: 'arrow-down-circle', label: 'Low' },
};

// Intent tag configuration - maps intent prefixes to display labels and colors
const INTENT_TAGS: Record<string, { label: string; color: string }> = {
  'e-commerce.shipping': { label: 'SHIPPING', color: '#3b82f6' },
  'e-commerce.order': { label: 'ORDER', color: '#22c55e' },
  'billing.invoice': { label: 'BILLING', color: '#f97316' },
  'billing': { label: 'BILLING', color: '#f97316' },
  'security.two_factor': { label: 'SECURITY', color: '#ef4444' },
  'security.fraud': { label: 'SECURITY', color: '#ef4444' },
  'security': { label: 'SECURITY', color: '#ef4444' },
  'newsletter': { label: 'NEWSLETTER', color: '#8b5cf6' },
  'marketing.promotion': { label: 'PROMOTION', color: '#eab308' },
  'marketing': { label: 'PROMOTION', color: '#eab308' },
};

// Mode-specific colors
const MODE_COLORS = {
  mail: {
    accent: '#667eea',
    secondary: '#764ba2',
    glow: 'rgba(102, 126, 234, 0.4)',
  },
  ads: {
    accent: '#4fd19e',
    secondary: '#16bbaa',
    glow: 'rgba(79, 209, 158, 0.4)',
  },
};

interface SwipeableCardProps {
  card: EmailCardType;
}

// Get intent tag from full intent string
const getIntentTag = (intent?: string): { label: string; color: string } | null => {
  if (!intent) return null;
  
  // Try increasingly shorter prefixes
  const parts = intent.split('.');
  for (let i = parts.length; i > 0; i--) {
    const prefix = parts.slice(0, i).join('.');
    if (INTENT_TAGS[prefix]) {
      return INTENT_TAGS[prefix];
    }
  }
  
  return null;
};

// Get dynamic summary line limit based on priority and context
const getSummaryLineLimit = (card: EmailCardType): number => {
  const contextKeys = Object.keys(card.context || {}).filter(
    k => !String(card.context?.[k] || '').startsWith('http')
  );
  const hasRichContext = contextKeys.length > 2;
  
  if (hasRichContext) return 2; // Less summary, more context
  
  switch (card.priority) {
    case 'critical': return 5;
    case 'high': return 4;
    case 'medium': return 3;
    default: return 2;
  }
};

// Format intent for "why it matters" - extract actionable insight
const getWhyItMatters = (card: EmailCardType): string | undefined => {
  // Use AI summary if available and different from regular summary
  if (card.aiGeneratedSummary && card.aiGeneratedSummary !== card.summary) {
    return card.aiGeneratedSummary;
  }
  return undefined;
};

export function SwipeableCard({ card }: SwipeableCardProps) {
  const mode = card.type === 'ads' ? 'ads' : 'mail';
  const colors = MODE_COLORS[mode];
  const priorityConfig = PRIORITY_CONFIG[card.priority];
  const intentTag = getIntentTag(card.intent);
  const summaryLineLimit = getSummaryLineLimit(card);
  
  const senderName = card.sender?.name || 'Unknown';
  const senderInitial = card.sender?.initial || senderName.charAt(0).toUpperCase();
  
  // Get primary action text
  const primaryAction = card.suggestedActions?.find(a => a.isPrimary);
  const actionText = primaryAction?.displayName || card.hpa || 'Take Action';

  return (
    <View style={styles.cardWrapper}>
      <View style={styles.card}>
        {/* Blur background for glass effect */}
        {Platform.OS === 'ios' ? (
          <BlurView intensity={40} tint="dark" style={StyleSheet.absoluteFill} />
        ) : (
          <View style={[StyleSheet.absoluteFill, styles.androidFallback]} />
        )}
        
        {/* Glass overlay */}
        <View style={styles.glassOverlay} />

        {/* Accent border glow */}
        <View style={[styles.accentBorder, { borderColor: colors.glow }]} />

        {/* Content */}
        <View style={styles.content}>
          {/* Title - prominent at top */}
          <Text style={styles.title} numberOfLines={2}>
            {card.title}
          </Text>

          {/* Sender row with "to me" indicator */}
          <View style={styles.senderRow}>
            {/* Avatar */}
            <View style={[styles.avatar, { backgroundColor: colors.accent }]}>
              <Text style={styles.avatarText}>{senderInitial}</Text>
            </View>

            {/* Sender info */}
            <View style={styles.senderInfo}>
              <View style={styles.senderTopRow}>
                <Text style={styles.senderName} numberOfLines={1}>{senderName}</Text>
                <Text style={styles.timeAgo}>{card.timeAgo}</Text>
              </View>
              <Text style={styles.toMe}>to me</Text>
            </View>

            {/* View button */}
            <View style={styles.viewButton}>
              <Text style={styles.viewButtonText}>View</Text>
            </View>
          </View>

          {/* Priority badge + Intent tag row */}
          <View style={styles.badgeRow}>
            {/* Priority badge */}
            <View style={[styles.priorityBadge, { backgroundColor: priorityConfig.color + '25' }]}>
              <Ionicons
                name={priorityConfig.icon as keyof typeof Ionicons.glyphMap}
                size={12}
                color={priorityConfig.color}
              />
              <Text style={[styles.priorityText, { color: priorityConfig.color }]}>
                {priorityConfig.label}
              </Text>
            </View>

            {/* Intent tag */}
            {intentTag && (
              <View style={[styles.intentTag, { backgroundColor: intentTag.color + '25' }]}>
                <Text style={[styles.intentTagText, { color: intentTag.color }]}>
                  {intentTag.label}
                </Text>
              </View>
            )}

            {/* Status indicators */}
            <View style={styles.statusDots}>
              {card.isVIP && <View style={[styles.statusDot, { backgroundColor: '#eab308' }]} />}
              {card.hasAttachments && <View style={[styles.statusDot, { backgroundColor: '#3b82f6' }]} />}
              {card.isNewsletter && <View style={[styles.statusDot, { backgroundColor: '#8b5cf6' }]} />}
            </View>
          </View>

          {/* Email Summary - dynamic length based on priority */}
          <Text style={styles.summary} numberOfLines={summaryLineLimit}>
            {card.summary}
          </Text>

          {/* AI Analysis Section - expandable */}
          <AIAnalysisSection
            intent={card.intent}
            intentConfidence={card.intentConfidence}
            suggestedAction={actionText}
            whyItMatters={getWhyItMatters(card)}
            context={card.context}
            mode={mode}
          />

          {/* Primary Action Button - improved styling */}
          <View style={styles.actionButtonContainer}>
            <LinearGradient
              colors={[colors.accent, colors.secondary]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
              style={styles.actionButtonGradient}
            >
              <Text style={styles.actionButtonText}>{actionText}</Text>
              <Ionicons name="arrow-forward" size={18} color="#fff" />
            </LinearGradient>
            {/* Glow effect */}
            <View style={[styles.actionButtonGlow, { backgroundColor: colors.glow }]} />
          </View>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  cardWrapper: {
    width: '100%',
    aspectRatio: 0.68,
    padding: 16,
  },
  card: {
    flex: 1,
    borderRadius: 24,
    overflow: 'hidden',
    backgroundColor: 'rgba(26, 26, 46, 0.6)',
  },
  androidFallback: {
    backgroundColor: 'rgba(26, 26, 46, 0.9)',
  },
  glassOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(255, 255, 255, 0.03)',
  },
  accentBorder: {
    ...StyleSheet.absoluteFillObject,
    borderRadius: 24,
    borderWidth: 1,
  },
  content: {
    flex: 1,
    padding: 20,
  },
  // Title
  title: {
    fontSize: 22,
    fontWeight: '700',
    color: '#fff',
    lineHeight: 28,
    marginBottom: 14,
    letterSpacing: -0.3,
  },
  // Sender row
  senderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    fontSize: 17,
    fontWeight: '700',
    color: '#fff',
  },
  senderInfo: {
    flex: 1,
    marginLeft: 12,
  },
  senderTopRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  senderName: {
    fontSize: 15,
    fontWeight: '600',
    color: '#fff',
    flex: 1,
  },
  timeAgo: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.5)',
    marginLeft: 8,
  },
  toMe: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.4)',
    marginTop: 2,
  },
  viewButton: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.15)',
  },
  viewButtonText: {
    fontSize: 13,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.8)',
  },
  // Badge row
  badgeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 12,
    flexWrap: 'wrap',
  },
  priorityBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
    gap: 4,
  },
  priorityText: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  intentTag: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
  },
  intentTagText: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  statusDots: {
    flexDirection: 'row',
    gap: 6,
    marginLeft: 'auto',
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  // Summary
  summary: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.75)',
    lineHeight: 21,
    marginBottom: 14,
  },
  // Action button
  actionButtonContainer: {
    marginTop: 'auto',
    position: 'relative',
  },
  actionButtonGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    borderRadius: 14,
    gap: 8,
  },
  actionButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#fff',
  },
  actionButtonGlow: {
    position: 'absolute',
    left: 20,
    right: 20,
    bottom: -8,
    height: 20,
    borderRadius: 20,
    opacity: 0.5,
  },
});
