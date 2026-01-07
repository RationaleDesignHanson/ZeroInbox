/**
 * AIAnalysisSection - Expandable AI analysis panel
 * Shows suggested action, intent, why it matters, and context bullets
 */

import React, { useState, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  Animated,
  LayoutAnimation,
  Platform,
  UIManager,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { HapticService } from '../services/HapticService';

// Enable LayoutAnimation on Android
if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
  UIManager.setLayoutAnimationEnabledExperimental(true);
}

interface ContextItem {
  label: string;
  value: string;
}

interface AIAnalysisSectionProps {
  intent?: string;
  intentConfidence?: number;
  suggestedAction?: string;
  whyItMatters?: string;
  context?: Record<string, unknown>;
  mode: 'mail' | 'ads';
}

// Context key to human-readable label mapping
const CONTEXT_LABELS: Record<string, string> = {
  orderNumber: 'Order',
  trackingNumber: 'Tracking',
  carrier: 'Carrier',
  amountDue: 'Amount',
  dueDate: 'Due',
  verificationCode: 'Code',
  expectedDelivery: 'Expected',
  totalAmount: 'Total',
  paymentLink: 'Pay at',
  securityUrl: 'Review at',
  loginLocation: 'Location',
  loginDevice: 'Device',
  loginTime: 'Time',
  promoCode: 'Code',
  discount: 'Discount',
  expiresAt: 'Expires',
  productUrl: 'Shop at',
  unsubscribeUrl: 'Unsubscribe',
  deliveryLocation: 'Delivered to',
  deliveryTime: 'At',
};

// Format context into displayable bullet points
const formatContextBullets = (context?: Record<string, unknown>): ContextItem[] => {
  if (!context) return [];
  
  const items: ContextItem[] = [];
  
  // Priority order for display
  const priorityKeys = [
    'verificationCode',
    'orderNumber',
    'trackingNumber',
    'carrier',
    'expectedDelivery',
    'amountDue',
    'totalAmount',
    'dueDate',
    'promoCode',
    'discount',
    'expiresAt',
    'loginLocation',
    'deliveryLocation',
  ];
  
  for (const key of priorityKeys) {
    if (context[key] !== undefined && context[key] !== null) {
      const value = String(context[key]);
      // Skip URLs in bullet display (too long)
      if (!value.startsWith('http')) {
        items.push({
          label: CONTEXT_LABELS[key] || key,
          value,
        });
      }
    }
  }
  
  return items.slice(0, 4); // Max 4 items
};

// Format intent for display
const formatIntent = (intent?: string): string => {
  if (!intent) return 'Unknown';
  return intent
    .split('.')
    .map(segment => segment.replace(/_/g, ' '))
    .join(' → ');
};

export function AIAnalysisSection({
  intent,
  intentConfidence,
  suggestedAction,
  whyItMatters,
  context,
  mode,
}: AIAnalysisSectionProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const rotateAnim = useRef(new Animated.Value(0)).current;
  
  const contextBullets = formatContextBullets(context);
  const hasExpandableContent = whyItMatters || contextBullets.length > 0 || intent;
  
  const toggleExpand = () => {
    if (!hasExpandableContent) return;
    
    HapticService.lightImpact();
    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
    
    Animated.spring(rotateAnim, {
      toValue: isExpanded ? 0 : 1,
      friction: 8,
      tension: 100,
      useNativeDriver: true,
    }).start();
    
    setIsExpanded(!isExpanded);
  };
  
  const chevronRotation = rotateAnim.interpolate({
    inputRange: [0, 1],
    outputRange: ['0deg', '180deg'],
  });
  
  const gradientColors = mode === 'ads'
    ? ['rgba(22, 187, 170, 0.25)', 'rgba(79, 209, 158, 0.15)']
    : ['rgba(139, 92, 246, 0.2)', 'rgba(139, 92, 246, 0.1)'];
  
  const borderColor = mode === 'ads'
    ? 'rgba(79, 209, 158, 0.4)'
    : 'rgba(139, 92, 246, 0.4)';
  
  const accentColor = mode === 'ads' ? '#4fd19e' : '#a78bfa';

  return (
    <Pressable onPress={toggleExpand} disabled={!hasExpandableContent}>
      <View style={[styles.container, { borderColor }]}>
        <LinearGradient
          colors={gradientColors}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={StyleSheet.absoluteFill}
        />
        
        {/* Header */}
        <View style={styles.header}>
          {/* Star badge */}
          <View style={styles.starBadge}>
            <LinearGradient
              colors={['#fbbf24', '#f97316']}
              style={StyleSheet.absoluteFill}
            />
            <Ionicons name="star" size={12} color="#fff" />
          </View>
          
          <Text style={styles.headerText}>AI ANALYSIS</Text>
          
          {hasExpandableContent && (
            <Animated.View style={{ transform: [{ rotate: chevronRotation }] }}>
              <Ionicons name="chevron-down" size={16} color="rgba(255,255,255,0.5)" />
            </Animated.View>
          )}
        </View>
        
        {/* Suggested Action (always visible) */}
        {suggestedAction && (
          <View style={styles.actionRow}>
            <Ionicons name="arrow-forward" size={14} color={accentColor} />
            <Text style={styles.actionText}>{suggestedAction}</Text>
            {intentConfidence && (
              <View style={styles.confidenceBadge}>
                <Text style={styles.confidenceText}>
                  {Math.round(intentConfidence * 100)}%
                </Text>
              </View>
            )}
          </View>
        )}
        
        {/* Context bullets (always show first 2 when collapsed) */}
        {contextBullets.length > 0 && (
          <View style={styles.contextSection}>
            {contextBullets.slice(0, isExpanded ? 4 : 2).map((item, index) => (
              <View key={index} style={styles.contextRow}>
                <Text style={styles.bulletPoint}>•</Text>
                <Text style={styles.contextLabel}>{item.label}:</Text>
                <Text style={styles.contextValue} numberOfLines={1}>
                  {item.value}
                </Text>
              </View>
            ))}
          </View>
        )}
        
        {/* Expanded content */}
        {isExpanded && (
          <View style={styles.expandedContent}>
            {/* Intent classification */}
            {intent && (
              <View style={styles.intentSection}>
                <Text style={styles.sectionLabel}>INTENT</Text>
                <Text style={styles.intentText}>{formatIntent(intent)}</Text>
              </View>
            )}
            
            {/* Why it matters */}
            {whyItMatters && (
              <View style={styles.whySection}>
                <Text style={styles.sectionLabel}>WHY THIS MATTERS</Text>
                <Text style={styles.whyText}>{whyItMatters}</Text>
              </View>
            )}
          </View>
        )}
        
        {/* Expand hint */}
        {!isExpanded && hasExpandableContent && (
          <Text style={styles.expandHint}>Tap to expand</Text>
        )}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    borderRadius: 16,
    overflow: 'hidden',
    borderWidth: 1,
    padding: 14,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 10,
  },
  starBadge: {
    width: 24,
    height: 24,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  headerText: {
    flex: 1,
    fontSize: 11,
    fontWeight: '700',
    color: 'rgba(255,255,255,0.7)',
    letterSpacing: 0.5,
  },
  actionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 8,
  },
  actionText: {
    flex: 1,
    fontSize: 15,
    fontWeight: '600',
    color: '#fff',
  },
  confidenceBadge: {
    backgroundColor: 'rgba(255,255,255,0.15)',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
  },
  confidenceText: {
    fontSize: 12,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.8)',
  },
  contextSection: {
    gap: 4,
  },
  contextRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  bulletPoint: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.5)',
  },
  contextLabel: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.6)',
  },
  contextValue: {
    flex: 1,
    fontSize: 13,
    fontWeight: '500',
    color: '#fff',
  },
  expandedContent: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255,255,255,0.1)',
    gap: 12,
  },
  intentSection: {},
  sectionLabel: {
    fontSize: 10,
    fontWeight: '700',
    color: 'rgba(255,255,255,0.5)',
    letterSpacing: 0.5,
    marginBottom: 4,
  },
  intentText: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.7)',
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
  whySection: {},
  whyText: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.8)',
    lineHeight: 20,
  },
  expandHint: {
    fontSize: 11,
    color: 'rgba(255,255,255,0.4)',
    textAlign: 'center',
    marginTop: 8,
  },
});

