/**
 * Settings Modal
 * Full-screen modal for app settings
 */

import { View, Text, StyleSheet, ScrollView, Pressable } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { BlurView } from 'expo-blur';
import { Platform } from 'react-native';
import { tokens, colors, typography } from '@zero/ui';

interface SettingsModalProps {
  onClose: () => void;
}

interface SettingsItemProps {
  title: string;
  subtitle?: string;
  icon?: string;
  onPress?: () => void;
  showArrow?: boolean;
}

function SettingsItem({ title, subtitle, icon, onPress, showArrow = true }: SettingsItemProps) {
  return (
    <Pressable onPress={onPress} style={styles.item}>
      {icon && <Text style={styles.itemIcon}>{icon}</Text>}
      <View style={styles.itemContent}>
        <Text style={styles.itemTitle}>{title}</Text>
        {subtitle && <Text style={styles.itemSubtitle}>{subtitle}</Text>}
      </View>
      {showArrow && <Ionicons name="chevron-forward" size={18} color="rgba(255,255,255,0.4)" />}
    </Pressable>
  );
}

function SettingsSection({ title, children }: { title: string; children: React.ReactNode }) {
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

export default function SettingsModal({ onClose }: SettingsModalProps) {
  return (
    <View style={styles.container}>
      <SafeAreaView style={styles.safeArea} edges={['top']}>
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.headerLeft} />
          <Text style={styles.headerTitle}>Settings</Text>
          <Pressable style={styles.closeButton} onPress={onClose}>
            <Ionicons name="close" size={24} color="white" />
          </Pressable>
        </View>

        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          <SettingsSection title="ACCOUNT">
            <SettingsItem icon="📧" title="Email Accounts" subtitle="Manage connected accounts" />
            <SettingsItem icon="👤" title="Profile" subtitle="Name, avatar, preferences" />
          </SettingsSection>

          <SettingsSection title="INBOX">
            <SettingsItem icon="🏷️" title="Categories" subtitle="Mail vs Ads classification" />
            <SettingsItem icon="⚡" title="Quick Actions" subtitle="Swipe gesture customization" />
            <SettingsItem icon="🔔" title="Notifications" subtitle="Alert preferences" />
          </SettingsSection>

          <SettingsSection title="AI & INTELLIGENCE">
            <SettingsItem icon="🤖" title="AI Classification" subtitle="Intent detection settings" />
            <SettingsItem icon="📊" title="Confidence Thresholds" subtitle="Action confirmation levels" />
            <SettingsItem icon="💡" title="Feedback" subtitle="Help improve suggestions" />
          </SettingsSection>

          <SettingsSection title="WEARABLES">
            <SettingsItem icon="⌚" title="Apple Watch" subtitle="Triage mode settings" />
            <SettingsItem icon="🕶️" title="Smart Glasses" subtitle="Meta & Samsung glasses" />
            <SettingsItem icon="✋" title="EMG Gestures" subtitle="Neural input configuration" />
          </SettingsSection>

          <SettingsSection title="ABOUT">
            <SettingsItem icon="ℹ️" title="About Zero" subtitle="Version 2.0.0" showArrow={false} />
            <SettingsItem icon="📜" title="Privacy Policy" />
            <SettingsItem icon="📋" title="Terms of Service" />
          </SettingsSection>

          <View style={styles.footer}>
            <Text style={styles.footerText}>Zero Inbox v2.0.0</Text>
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

