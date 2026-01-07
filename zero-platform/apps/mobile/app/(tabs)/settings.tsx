/**
 * Settings Screen
 * App preferences and account settings
 */

import { View, Text, StyleSheet, ScrollView, Pressable } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Screen, Card, Stack, tokens, colors, typography, useTheme } from '@zero/ui';

interface SettingsItemProps {
  title: string;
  subtitle?: string;
  icon?: string;
  onPress?: () => void;
  showArrow?: boolean;
}

function SettingsItem({ title, subtitle, icon, onPress, showArrow = true }: SettingsItemProps) {
  const theme = useTheme();

  return (
    <Pressable onPress={onPress} style={styles.item}>
      {icon && <Text style={styles.itemIcon}>{icon}</Text>}
      <View style={styles.itemContent}>
        <Text style={[styles.itemTitle, { color: theme.colors.text.primary }]}>{title}</Text>
        {subtitle && (
          <Text style={[styles.itemSubtitle, { color: theme.colors.text.tertiary }]}>
            {subtitle}
          </Text>
        )}
      </View>
      {showArrow && <Text style={styles.arrow}>›</Text>}
    </Pressable>
  );
}

function SettingsSection({ title, children }: { title: string; children: React.ReactNode }) {
  const theme = useTheme();

  return (
    <View style={styles.section}>
      <Text style={[styles.sectionTitle, { color: theme.colors.text.tertiary }]}>{title}</Text>
      <Card variant="glass" padding="minimal">
        {children}
      </Card>
    </View>
  );
}

export default function SettingsScreen() {
  const router = useRouter();
  const theme = useTheme();

  return (
    <Screen>
      <SafeAreaView style={styles.container} edges={['top']}>
        <View style={styles.header}>
          <Text style={[styles.title, { color: theme.colors.text.primary }]}>Settings</Text>
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
            <Text style={[styles.footerText, { color: theme.colors.text.tertiary }]}>
              Zero Inbox v2.0.0
            </Text>
            <Text style={[styles.footerText, { color: theme.colors.text.tertiary }]}>
              Built with ❤️ for inbox zero
            </Text>
          </View>
        </ScrollView>
      </SafeAreaView>
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingHorizontal: tokens.spacing.card,
    paddingVertical: tokens.spacing.section,
  },
  title: {
    ...typography.displayMedium,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    padding: tokens.spacing.component,
    paddingBottom: 100,
  },
  section: {
    marginBottom: tokens.spacing.section,
  },
  sectionTitle: {
    ...typography.labelMedium,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: tokens.spacing.inline,
    marginLeft: tokens.spacing.inline,
  },
  item: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: tokens.spacing.component,
    borderBottomWidth: 1,
    borderBottomColor: colors.borderSubtle,
  },
  itemIcon: {
    fontSize: 24,
    marginRight: tokens.spacing.element,
  },
  itemContent: {
    flex: 1,
  },
  itemTitle: {
    ...typography.bodyMedium,
    fontWeight: '500',
  },
  itemSubtitle: {
    ...typography.labelSmall,
    marginTop: 2,
  },
  arrow: {
    fontSize: 20,
    color: colors.textSubtle,
  },
  footer: {
    alignItems: 'center',
    paddingVertical: tokens.spacing.section,
    gap: tokens.spacing.tight,
  },
  footerText: {
    ...typography.labelSmall,
  },
});

