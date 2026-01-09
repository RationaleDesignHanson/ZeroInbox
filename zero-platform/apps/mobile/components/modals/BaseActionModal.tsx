/**
 * BaseActionModal - Shared foundation for all action modals
 * Provides consistent styling, header, and footer patterns
 */

import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  Pressable,
  ScrollView,
  Platform,
  Dimensions,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

export interface BaseActionModalProps {
  visible: boolean;
  onClose: () => void;
  card: EmailCard;
  action: SuggestedAction;
  title: string;
  icon: string;
  iconColor: string;
  gradientColors?: [string, string];
  children: React.ReactNode;
  footer?: React.ReactNode;
}

export function BaseActionModal({
  visible,
  onClose,
  card,
  action,
  title,
  icon,
  iconColor,
  gradientColors = ['#667eea', '#764ba2'],
  children,
  footer,
}: BaseActionModalProps) {
  const insets = useSafeAreaInsets();

  const handleClose = () => {
    HapticService.lightImpact();
    onClose();
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={handleClose}
    >
      <View style={styles.container}>
        {/* Header gradient */}
        <LinearGradient
          colors={gradientColors}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={[styles.headerGradient, { paddingTop: insets.top }]}
        >
          {/* Close button */}
          <Pressable style={styles.closeButton} onPress={handleClose}>
            <Ionicons name="close" size={24} color="rgba(255,255,255,0.9)" />
          </Pressable>

          {/* Icon */}
          <View style={styles.iconContainer}>
            <View style={[styles.iconCircle, { backgroundColor: 'rgba(255,255,255,0.2)' }]}>
              <Ionicons
                name={icon as keyof typeof Ionicons.glyphMap}
                size={40}
                color="white"
              />
            </View>
          </View>

          {/* Title */}
          <Text style={styles.title}>{title}</Text>

          {/* Subtitle from card */}
          <Text style={styles.subtitle} numberOfLines={2}>
            {card.title}
          </Text>
        </LinearGradient>

        {/* Content */}
        <ScrollView
          style={styles.content}
          contentContainerStyle={styles.contentContainer}
          showsVerticalScrollIndicator={false}
        >
          {children}
        </ScrollView>

        {/* Footer */}
        {footer && (
          <View style={[styles.footer, { paddingBottom: insets.bottom + 16 }]}>
            {Platform.OS === 'ios' ? (
              <BlurView intensity={80} tint="dark" style={StyleSheet.absoluteFill} />
            ) : (
              <View style={[StyleSheet.absoluteFill, styles.androidFooter]} />
            )}
            <View style={styles.footerContent}>{footer}</View>
          </View>
        )}
      </View>
    </Modal>
  );
}

// Shared Section component for modals
export interface ModalSectionProps {
  title: string;
  children: React.ReactNode;
}

export function ModalSection({ title, children }: ModalSectionProps) {
  return (
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>{title}</Text>
      <View style={styles.sectionContent}>
        {Platform.OS === 'ios' ? (
          <BlurView intensity={20} tint="dark" style={StyleSheet.absoluteFill} />
        ) : (
          <View style={[StyleSheet.absoluteFill, styles.androidSection]} />
        )}
        {children}
      </View>
    </View>
  );
}

// Info row for displaying key-value pairs
export interface InfoRowProps {
  icon: string;
  iconColor: string;
  label: string;
  value: string;
  onPress?: () => void;
}

export function InfoRow({ icon, iconColor, label, value, onPress }: InfoRowProps) {
  const Content = (
    <View style={styles.infoRow}>
      <View style={[styles.infoIcon, { backgroundColor: `${iconColor}20` }]}>
        <Ionicons
          name={icon as keyof typeof Ionicons.glyphMap}
          size={18}
          color={iconColor}
        />
      </View>
      <View style={styles.infoContent}>
        <Text style={styles.infoLabel}>{label}</Text>
        <Text style={styles.infoValue}>{value}</Text>
      </View>
      {onPress && (
        <Ionicons name="chevron-forward" size={18} color="rgba(255,255,255,0.4)" />
      )}
    </View>
  );

  if (onPress) {
    return (
      <Pressable onPress={onPress} style={({ pressed }) => [{ opacity: pressed ? 0.7 : 1 }]}>
        {Content}
      </Pressable>
    );
  }

  return Content;
}

// Copyable field component
export interface CopyableFieldProps {
  label: string;
  value: string;
  icon?: string;
  iconColor?: string;
}

export function CopyableField({ label, value, icon, iconColor = '#3b82f6' }: CopyableFieldProps) {
  const handleCopy = () => {
    // Copy to clipboard (would use Clipboard API)
    HapticService.lightImpact();
    // In a real app, use Clipboard.setStringAsync(value)
  };

  return (
    <Pressable onPress={handleCopy} style={styles.copyableField}>
      {icon && (
        <View style={[styles.copyableIcon, { backgroundColor: `${iconColor}20` }]}>
          <Ionicons
            name={icon as keyof typeof Ionicons.glyphMap}
            size={18}
            color={iconColor}
          />
        </View>
      )}
      <View style={styles.copyableContent}>
        <Text style={styles.copyableLabel}>{label}</Text>
        <Text style={styles.copyableValue}>{value}</Text>
      </View>
      <Ionicons name="copy-outline" size={18} color="rgba(255,255,255,0.5)" />
    </Pressable>
  );
}

// Primary action button
export interface ActionButtonProps {
  title: string;
  icon: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary' | 'danger';
  disabled?: boolean;
  loading?: boolean;
}

export function ActionButton({
  title,
  icon,
  onPress,
  variant = 'primary',
  disabled,
  loading,
}: ActionButtonProps) {
  const getButtonStyle = () => {
    switch (variant) {
      case 'primary':
        return styles.primaryButton;
      case 'secondary':
        return styles.secondaryButton;
      case 'danger':
        return styles.dangerButton;
    }
  };

  const getTextStyle = () => {
    switch (variant) {
      case 'primary':
        return styles.primaryButtonText;
      case 'secondary':
        return styles.secondaryButtonText;
      case 'danger':
        return styles.dangerButtonText;
    }
  };

  return (
    <Pressable
      onPress={() => {
        if (!disabled && !loading) {
          HapticService.mediumImpact();
          onPress();
        }
      }}
      style={[getButtonStyle(), disabled && styles.buttonDisabled]}
      disabled={disabled || loading}
    >
      <Ionicons
        name={icon as keyof typeof Ionicons.glyphMap}
        size={20}
        color={variant === 'secondary' ? 'white' : 'white'}
      />
      <Text style={getTextStyle()}>{loading ? 'Loading...' : title}</Text>
    </Pressable>
  );
}

// Progress step component (for tracking, etc)
export interface ProgressStepProps {
  icon: string;
  title: string;
  isCompleted: boolean;
  isActive?: boolean;
  color: string;
}

export function ProgressStep({ icon, title, isCompleted, isActive, color }: ProgressStepProps) {
  return (
    <View style={styles.progressStep}>
      <View
        style={[
          styles.progressIcon,
          {
            backgroundColor: isCompleted || isActive ? `${color}30` : 'rgba(255,255,255,0.1)',
          },
        ]}
      >
        <Ionicons
          name={icon as keyof typeof Ionicons.glyphMap}
          size={18}
          color={isCompleted || isActive ? color : 'rgba(255,255,255,0.4)'}
        />
      </View>
      <Text
        style={[
          styles.progressTitle,
          { color: isCompleted || isActive ? 'white' : 'rgba(255,255,255,0.5)' },
        ]}
      >
        {title}
      </Text>
      <View style={{ flex: 1 }} />
      {isCompleted && (
        <Ionicons name="checkmark" size={16} color={color} />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0f',
  },
  headerGradient: {
    paddingBottom: 24,
    paddingHorizontal: 20,
    position: 'relative',
  },
  closeButton: {
    position: 'absolute',
    top: 12,
    right: 16,
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(0,0,0,0.3)',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 10,
  },
  iconContainer: {
    alignItems: 'center',
    marginTop: 40,
    marginBottom: 16,
  },
  iconCircle: {
    width: 80,
    height: 80,
    borderRadius: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: 'white',
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.7)',
    textAlign: 'center',
    marginTop: 8,
  },
  content: {
    flex: 1,
  },
  contentContainer: {
    padding: 16,
    paddingBottom: 100,
  },
  section: {
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 12,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.5)',
    letterSpacing: 0.5,
    marginBottom: 8,
    marginLeft: 4,
  },
  sectionContent: {
    borderRadius: 16,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
    padding: 16,
  },
  androidSection: {
    backgroundColor: 'rgba(26, 26, 46, 0.9)',
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
  },
  infoIcon: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  infoContent: {
    flex: 1,
  },
  infoLabel: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.5)',
    marginBottom: 2,
  },
  infoValue: {
    fontSize: 15,
    fontWeight: '500',
    color: 'white',
  },
  copyableField: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 12,
    padding: 12,
    marginBottom: 8,
  },
  copyableIcon: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  copyableContent: {
    flex: 1,
  },
  copyableLabel: {
    fontSize: 11,
    color: 'rgba(255,255,255,0.5)',
    marginBottom: 2,
  },
  copyableValue: {
    fontSize: 14,
    fontWeight: '600',
    color: 'white',
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
  footer: {
    borderTopWidth: 1,
    borderTopColor: 'rgba(255,255,255,0.1)',
  },
  androidFooter: {
    backgroundColor: 'rgba(20, 20, 30, 0.98)',
  },
  footerContent: {
    padding: 16,
    gap: 10,
  },
  primaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#667eea',
    borderRadius: 14,
    paddingVertical: 16,
    gap: 8,
  },
  secondaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 14,
    paddingVertical: 16,
    gap: 8,
  },
  dangerButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#ef4444',
    borderRadius: 14,
    paddingVertical: 16,
    gap: 8,
  },
  buttonDisabled: {
    opacity: 0.5,
  },
  primaryButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
  secondaryButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
  dangerButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
  progressStep: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
  },
  progressIcon: {
    width: 32,
    height: 32,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  progressTitle: {
    fontSize: 14,
    fontWeight: '500',
  },
});
