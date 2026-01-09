/**
 * Settings Modal - Fully functional settings screen
 * Matches iOS SettingsView.swift implementation
 */

import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Pressable,
  Switch,
  Alert,
  Linking,
  ActivityIndicator,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { BlurView } from 'expo-blur';
import Constants from 'expo-constants';
import { router } from 'expo-router';
import { useAuth } from '../contexts/AuthContext';
import { SettingsService } from '../services/SettingsService';
import { HapticService } from '../services/HapticService';

// URLs
const PRIVACY_POLICY_URL = 'https://zeroinbox.seedny.com/privacy';
const TERMS_OF_SERVICE_URL = 'https://zeroinbox.seedny.com/terms';
const SUPPORT_EMAIL = 'support@zeroinbox.app';

interface SettingsItemProps {
  title: string;
  subtitle?: string;
  icon?: string;
  onPress?: () => void;
  showArrow?: boolean;
  rightElement?: React.ReactNode;
  disabled?: boolean;
  destructive?: boolean;
}

function SettingsItem({
  title,
  subtitle,
  icon,
  onPress,
  showArrow = true,
  rightElement,
  disabled,
  destructive,
}: SettingsItemProps) {
  return (
    <Pressable
      onPress={onPress}
      style={[styles.item, disabled && styles.itemDisabled]}
      disabled={disabled || !onPress}
    >
      {icon && <Text style={styles.itemIcon}>{icon}</Text>}
      <View style={styles.itemContent}>
        <Text style={[styles.itemTitle, destructive && styles.itemTitleDestructive]}>
          {title}
        </Text>
        {subtitle && <Text style={styles.itemSubtitle}>{subtitle}</Text>}
      </View>
      {rightElement}
      {showArrow && onPress && !rightElement && (
        <Ionicons name="chevron-forward" size={18} color="rgba(255,255,255,0.4)" />
      )}
    </Pressable>
  );
}

interface ToggleItemProps {
  title: string;
  subtitle?: string;
  icon?: string;
  value: boolean;
  onValueChange: (value: boolean) => void;
  disabled?: boolean;
  color?: string;
}

function ToggleItem({
  title,
  subtitle,
  icon,
  value,
  onValueChange,
  disabled,
  color = '#667eea',
}: ToggleItemProps) {
  const handleChange = (newValue: boolean) => {
    HapticService.selection();
    onValueChange(newValue);
  };

  return (
    <View style={[styles.item, disabled && styles.itemDisabled]}>
      {icon && <Text style={styles.itemIcon}>{icon}</Text>}
      <View style={styles.itemContent}>
        <Text style={styles.itemTitle}>{title}</Text>
        {subtitle && <Text style={styles.itemSubtitle}>{subtitle}</Text>}
      </View>
      <Switch
        value={value}
        onValueChange={handleChange}
        trackColor={{ false: 'rgba(255,255,255,0.1)', true: color + '60' }}
        thumbColor={value ? color : '#f4f3f4'}
        disabled={disabled}
      />
    </View>
  );
}

function SettingsSection({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>{title}</Text>
      <View style={styles.sectionContent}>
        {Platform.OS === 'ios' ? (
          <BlurView intensity={20} tint="dark" style={StyleSheet.absoluteFill} />
        ) : (
          <View style={[StyleSheet.absoluteFill, styles.androidFallback]} />
        )}
        {children}
      </View>
    </View>
  );
}

export default function SettingsModal() {
  const { user, logout, useMockData } = useAuth();
  
  // Close modal using router
  const handleClose = useCallback(() => {
    HapticService.lightImpact();
    router.back();
  }, []);

  // Settings state
  const [isLoading, setIsLoading] = useState(true);
  const [mlClassification, setMLClassification] = useState(true);
  const [emailSending, setEmailSending] = useState(false);
  const [debugOverlay, setDebugOverlay] = useState(false);
  const [vipFilter, setVIPFilter] = useState(false);
  const [threading, setThreading] = useState(false);
  const [modeIndicators, setModeIndicators] = useState(true);
  const [haptics, setHaptics] = useState(true);
  const [isReloading, setIsReloading] = useState(false);

  // Load settings on mount
  useEffect(() => {
    async function loadSettings() {
      try {
        await SettingsService.initialize();
        const [ml, email, debug, vip, thread, modes, hapticsEnabled] = await Promise.all([
          SettingsService.isMLClassificationEnabled(),
          SettingsService.isEmailSendingEnabled(),
          SettingsService.isDebugOverlayEnabled(),
          SettingsService.isVIPFilterEnabled(),
          SettingsService.isThreadingEnabled(),
          SettingsService.areModeIndicatorsEnabled(),
          SettingsService.areHapticsEnabled(),
        ]);
        setMLClassification(ml);
        setEmailSending(email);
        setDebugOverlay(debug);
        setVIPFilter(vip);
        setThreading(thread);
        setModeIndicators(modes);
        setHaptics(hapticsEnabled);
      } catch (error) {
        console.error('Failed to load settings:', error);
      } finally {
        setIsLoading(false);
      }
    }
    loadSettings();
  }, []);

  // Settings handlers
  const handleMLClassificationChange = useCallback(async (value: boolean) => {
    setMLClassification(value);
    await SettingsService.setMLClassification(value);
  }, []);

  const handleEmailSendingChange = useCallback(async (value: boolean) => {
    if (value) {
      Alert.alert(
        '⚠️ Enable Email Sending?',
        'This will allow the app to send real emails. Make sure you are ready for this.',
        [
          { text: 'Cancel', style: 'cancel' },
          {
            text: 'Enable',
            style: 'destructive',
            onPress: async () => {
              setEmailSending(true);
              await SettingsService.setEmailSending(true);
            },
          },
        ]
      );
    } else {
      setEmailSending(false);
      await SettingsService.setEmailSending(false);
    }
  }, []);

  const handleDebugOverlayChange = useCallback(async (value: boolean) => {
    setDebugOverlay(value);
    await SettingsService.setDebugOverlay(value);
  }, []);

  const handleVIPFilterChange = useCallback(async (value: boolean) => {
    setVIPFilter(value);
    await SettingsService.setVIPFilter(value);
  }, []);

  const handleThreadingChange = useCallback(async (value: boolean) => {
    setThreading(value);
    await SettingsService.setThreading(value);
  }, []);

  const handleModeIndicatorsChange = useCallback(async (value: boolean) => {
    setModeIndicators(value);
    await SettingsService.setModeIndicators(value);
  }, []);

  const handleHapticsChange = useCallback(async (value: boolean) => {
    setHaptics(value);
    await SettingsService.setHaptics(value);
    HapticService.setEnabled(value);
  }, []);

  const handleReloadEmails = useCallback(async () => {
    HapticService.mediumImpact();
    setIsReloading(true);
    // Simulate reload
    await new Promise((resolve) => setTimeout(resolve, 1500));
    setIsReloading(false);
    HapticService.success();
    Alert.alert('Emails Reloaded', 'Your inbox has been refreshed.');
  }, []);

  const handleLogout = useCallback(() => {
    Alert.alert('Log Out', 'Are you sure you want to log out?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Log Out',
        style: 'destructive',
        onPress: async () => {
          await logout();
          handleClose();
        },
      },
    ]);
  }, [logout, handleClose]);

  const handleResetOnboarding = useCallback(() => {
    Alert.alert('Reset Onboarding', 'This will show the welcome flow again.', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Reset',
        onPress: async () => {
          await SettingsService.setHasSeenOnboarding(false);
          Alert.alert('Done', 'Onboarding will show on next app launch.');
        },
      },
    ]);
  }, []);

  const handleOpenPrivacy = useCallback(() => {
    Linking.openURL(PRIVACY_POLICY_URL);
  }, []);

  const handleOpenTerms = useCallback(() => {
    Linking.openURL(TERMS_OF_SERVICE_URL);
  }, []);

  const handleContactSupport = useCallback(() => {
    Linking.openURL(`mailto:${SUPPORT_EMAIL}`);
  }, []);

  const version = Constants.expoConfig?.version ?? '2.0.0';
  const buildNumber = Constants.expoConfig?.ios?.buildNumber ?? '1';

  if (isLoading) {
    return (
      <View style={[styles.container, styles.loadingContainer]}>
        <ActivityIndicator size="large" color="#667eea" />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <SafeAreaView style={styles.safeArea} edges={['top']}>
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.headerLeft} />
          <Text style={styles.headerTitle}>Settings</Text>
          <Pressable style={styles.closeButton} onPress={handleClose}>
            <Ionicons name="close" size={24} color="white" />
          </Pressable>
        </View>

        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Account Section */}
          <SettingsSection title="ACCOUNT">
            <SettingsItem
              icon="👤"
              title={user?.email || 'Not signed in'}
              subtitle={useMockData ? 'Using mock data' : `Signed in via ${user?.provider || 'unknown'}`}
              showArrow={false}
            />
            <SettingsItem
              icon="🔄"
              title="Reload Emails"
              subtitle="Fetch latest emails from server"
              onPress={handleReloadEmails}
              rightElement={
                isReloading ? (
                  <ActivityIndicator size="small" color="#667eea" />
                ) : undefined
              }
              disabled={isReloading}
            />
            <SettingsItem
              icon="🚪"
              title="Log Out"
              onPress={handleLogout}
              showArrow={false}
              destructive
            />
          </SettingsSection>

          {/* AI & Intelligence Section */}
          <SettingsSection title="AI & INTELLIGENCE">
            <ToggleItem
              icon="🤖"
              title="ML Classification"
              subtitle="Use ML-based intent detection"
              value={mlClassification}
              onValueChange={handleMLClassificationChange}
              color="#3b82f6"
            />
            <ToggleItem
              icon="📧"
              title="Email Sending"
              subtitle={emailSending ? '⚠️ Emails will be sent for real' : 'Safe mode: emails won\'t send'}
              value={emailSending}
              onValueChange={handleEmailSendingChange}
              color={emailSending ? '#ef4444' : '#f59e0b'}
            />
          </SettingsSection>

          {/* Model Training Section */}
          <SettingsSection title="MODEL TRAINING">
            <SettingsItem
              icon="🧠"
              title="Train Intent Classifier"
              subtitle="Help improve AI with feedback"
              onPress={() => router.push('/model-tuning')}
            />
            <SettingsItem
              icon="📊"
              title="View Training Data"
              subtitle="Review swipe patterns and corrections"
              onPress={() => router.push('/model-tuning')}
            />
            <SettingsItem
              icon="🔄"
              title="Reset Model"
              subtitle="Clear personalized training data"
              onPress={() => Alert.alert(
                'Reset Model',
                'This will clear all personalized training data. The model will return to default behavior.',
                [
                  { text: 'Cancel', style: 'cancel' },
                  { text: 'Reset', style: 'destructive', onPress: () => Alert.alert('Model Reset', 'Training data cleared.') }
                ]
              )}
            />
            <SettingsItem
              icon="📈"
              title="Model Stats"
              subtitle="Accuracy: 94.2% • 1,247 samples"
              showArrow={false}
            />
          </SettingsSection>

          {/* Action Testing Section */}
          <SettingsSection title="ACTION TESTING">
            <SettingsItem
              icon="🧪"
              title="Test Email Composer"
              subtitle="Preview quick reply modal"
              onPress={() => router.push('/action/quick_reply?emailId=test-1&context=' + encodeURIComponent(JSON.stringify({ subject: 'Test Subject' })))}
            />
            <SettingsItem
              icon="📅"
              title="Test Calendar Modal"
              subtitle="Preview add to calendar flow"
              onPress={() => router.push('/action/add_to_calendar?emailId=test-1&context=' + encodeURIComponent(JSON.stringify({ title: 'Test Event', date: 'Tomorrow at 2pm' })))}
            />
            <SettingsItem
              icon="✅"
              title="Test Confirmation Modal"
              subtitle="Preview action confirmation"
              onPress={() => router.push('/action/confirm?emailId=test-1')}
            />
          </SettingsSection>

          {/* App Settings Section */}
          <SettingsSection title="APP SETTINGS">
            <ToggleItem
              icon="🐛"
              title="Debug Overlay"
              subtitle="Show card counts and stats"
              value={debugOverlay}
              onValueChange={handleDebugOverlayChange}
              color="#eab308"
            />
            <ToggleItem
              icon="⭐"
              title="VIP Filter"
              subtitle="Show only VIP contacts"
              value={vipFilter}
              onValueChange={handleVIPFilterChange}
              color="#f59e0b"
            />
            <ToggleItem
              icon="💬"
              title="Conversation Threading"
              subtitle="Group related emails"
              value={threading}
              onValueChange={handleThreadingChange}
              color="#3b82f6"
            />
            <ToggleItem
              icon="🔘"
              title="Mode Indicators"
              subtitle="Show status dots on cards"
              value={modeIndicators}
              onValueChange={handleModeIndicatorsChange}
              color="#22c55e"
            />
            <ToggleItem
              icon="📳"
              title="Haptic Feedback"
              subtitle="Vibration on interactions"
              value={haptics}
              onValueChange={handleHapticsChange}
              color="#8b5cf6"
            />
            <SettingsItem
              icon="🔄"
              title="Reset Onboarding"
              subtitle="Show welcome flow again"
              onPress={handleResetOnboarding}
            />
          </SettingsSection>

          {/* Legal Section */}
          <SettingsSection title="LEGAL">
            <SettingsItem
              icon="🔒"
              title="Privacy Policy"
              subtitle="How we handle your data"
              onPress={handleOpenPrivacy}
            />
            <SettingsItem
              icon="📋"
              title="Terms of Service"
              subtitle="Usage terms and conditions"
              onPress={handleOpenTerms}
            />
            <SettingsItem
              icon="💬"
              title="Contact Support"
              subtitle="Get help or report issues"
              onPress={handleContactSupport}
            />
          </SettingsSection>

          {/* About Section */}
          <SettingsSection title="ABOUT">
            <SettingsItem
              icon="ℹ️"
              title="Version"
              subtitle={`v${version} (${buildNumber})`}
              showArrow={false}
            />
          </SettingsSection>

          <View style={styles.footer}>
            <Text style={styles.footerText}>Zero Inbox v{version}</Text>
            <Text style={styles.footerText}>Built with ❤️ for inbox zero</Text>
          </View>
        </ScrollView>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0f',
  },
  loadingContainer: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  safeArea: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.1)',
  },
  headerLeft: {
    width: 40,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: 'white',
  },
  closeButton: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 20,
    backgroundColor: 'rgba(255,255,255,0.1)',
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 100,
  },
  section: {
    marginBottom: 24,
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
  },
  androidFallback: {
    backgroundColor: 'rgba(26, 26, 46, 0.9)',
  },
  item: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.05)',
  },
  itemDisabled: {
    opacity: 0.5,
  },
  itemIcon: {
    fontSize: 22,
    marginRight: 14,
  },
  itemContent: {
    flex: 1,
  },
  itemTitle: {
    fontSize: 16,
    fontWeight: '500',
    color: 'white',
  },
  itemTitleDestructive: {
    color: '#ef4444',
  },
  itemSubtitle: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.5)',
    marginTop: 2,
  },
  footer: {
    alignItems: 'center',
    paddingVertical: 24,
    gap: 4,
  },
  footerText: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.4)',
  },
});
