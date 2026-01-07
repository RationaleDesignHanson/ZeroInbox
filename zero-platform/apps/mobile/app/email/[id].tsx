/**
 * Email Detail Screen
 * Full email view with AI summary and actions
 */

import { useCallback } from 'react';
import { View, Text, ScrollView, StyleSheet, Pressable } from 'react-native';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  Screen,
  Card,
  Avatar,
  Badge,
  Button,
  ActionButton,
  ConfidenceBadge,
  LoadingSpinner,
  EmptyState,
  tokens,
  colors,
  typography,
  useTheme,
} from '@zero/ui';
import { useEmail, useExecuteAction } from '@zero/api';
import type { ActionSuggestion, ConfidenceLevel } from '@zero/types';

export default function EmailDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const theme = useTheme();

  const { data: email, isLoading, isError } = useEmail(id || '');
  const executeAction = useExecuteAction();

  const handleActionPress = useCallback(
    async (action: ActionSuggestion) => {
      if (!email) return;

      if (action.actionType === 'GO_TO' && action.context?.url) {
        // Open external URL
        // Linking.openURL(action.context.url as string);
      } else {
        // Execute in-app action
        try {
          await executeAction.mutateAsync({
            emailId: email.id,
            actionId: action.actionId,
            context: action.context,
          });
          router.back();
        } catch (error) {
          console.error('Action failed:', error);
        }
      }
    },
    [email, executeAction, router]
  );

  const handleClose = useCallback(() => {
    router.back();
  }, [router]);

  if (isLoading) {
    return (
      <Screen>
        <Stack.Screen options={{ title: 'Loading...' }} />
        <LoadingSpinner message="Loading email..." />
      </Screen>
    );
  }

  if (isError || !email) {
    return (
      <Screen>
        <Stack.Screen options={{ title: 'Error' }} />
        <EmptyState
          title="Email not found"
          message="This email may have been deleted or moved."
          actionLabel="Go Back"
          onAction={handleClose}
        />
      </Screen>
    );
  }

  const senderName = email.sender?.name || 'Unknown Sender';
  const senderEmail = email.sender?.email || '';
  const primaryAction = email.suggestedActions?.find((a) => a.isPrimary);
  const secondaryActions = email.suggestedActions?.filter((a) => !a.isPrimary) || [];

  return (
    <Screen>
      <Stack.Screen
        options={{
          title: '',
          headerShown: true,
          headerTransparent: true,
          headerLeft: () => (
            <Pressable onPress={handleClose} style={styles.closeButton}>
              <Text style={styles.closeIcon}>✕</Text>
            </Pressable>
          ),
        }}
      />

      <SafeAreaView style={styles.container}>
        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Header */}
          <View style={styles.header}>
            <Avatar name={senderName} size="large" />
            <View style={styles.headerInfo}>
              <Text style={[styles.senderName, { color: theme.colors.text.primary }]}>
                {senderName}
              </Text>
              <Text style={[styles.senderEmail, { color: theme.colors.text.tertiary }]}>
                {senderEmail}
              </Text>
              <Text style={[styles.timestamp, { color: theme.colors.text.tertiary }]}>
                {email.timeAgo}
              </Text>
            </View>
            {email.priority && (email.priority === 'critical' || email.priority === 'high') && (
              <Badge
                label={email.priority}
                variant="priority"
                priority={email.priority}
              />
            )}
          </View>

          {/* Subject */}
          <Text style={[styles.subject, { color: theme.colors.text.primary }]}>
            {email.title}
          </Text>

          {/* AI Summary */}
          {email.aiGeneratedSummary && (
            <Card variant="glass" style={styles.summaryCard}>
              <View style={styles.summaryHeader}>
                <Text style={[styles.summaryLabel, { color: theme.colors.text.tertiary }]}>
                  AI SUMMARY
                </Text>
                {email.intentConfidence && (
                  <ConfidenceBadge
                    confidence={email.intentConfidence}
                    level={getConfidenceLevel(email.intentConfidence)}
                  />
                )}
              </View>
              <Text style={[styles.summaryText, { color: theme.colors.text.secondary }]}>
                {email.aiGeneratedSummary}
              </Text>
            </Card>
          )}

          {/* Email Body */}
          <Card variant="default" style={styles.bodyCard}>
            <Text style={[styles.bodyText, { color: theme.colors.text.primary }]}>
              {email.body || email.summary}
            </Text>
          </Card>

          {/* Actions */}
          {email.suggestedActions && email.suggestedActions.length > 0 && (
            <View style={styles.actionsSection}>
              <Text style={[styles.actionsLabel, { color: theme.colors.text.tertiary }]}>
                SUGGESTED ACTIONS
              </Text>

              {primaryAction && (
                <ActionButton
                  title={primaryAction.displayName}
                  actionType={primaryAction.actionType}
                  isPrimary
                  isCompound={primaryAction.isCompound}
                  onPress={() => handleActionPress(primaryAction)}
                  style={styles.primaryAction}
                />
              )}

              {secondaryActions.map((action) => (
                <ActionButton
                  key={action.actionId}
                  title={action.displayName}
                  actionType={action.actionType}
                  isCompound={action.isCompound}
                  onPress={() => handleActionPress(action)}
                  style={styles.secondaryAction}
                />
              ))}
            </View>
          )}

          {/* Thread Indicator */}
          {email.threadLength && email.threadLength > 1 && (
            <Card variant="glass" style={styles.threadCard}>
              <Text style={[styles.threadText, { color: theme.colors.text.secondary }]}>
                📬 {email.threadLength} messages in this thread
              </Text>
            </Card>
          )}
        </ScrollView>

        {/* Bottom Action Bar */}
        <View style={styles.bottomBar}>
          <Button
            title="Archive"
            variant="secondary"
            size="medium"
            onPress={() => {}}
            style={styles.bottomButton}
          />
          <Button
            title="Reply"
            variant="primary"
            size="medium"
            onPress={() => {}}
            style={styles.bottomButton}
          />
        </View>
      </SafeAreaView>
    </Screen>
  );
}

function getConfidenceLevel(confidence: number): ConfidenceLevel {
  if (confidence >= 0.9) return 'VERY_HIGH';
  if (confidence >= 0.75) return 'HIGH';
  if (confidence >= 0.6) return 'MEDIUM';
  if (confidence >= 0.4) return 'LOW';
  return 'VERY_LOW';
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  closeButton: {
    padding: tokens.spacing.inline,
  },
  closeIcon: {
    fontSize: 20,
    color: colors.textSecondary,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    padding: tokens.spacing.card,
    paddingTop: 60, // Account for header
    paddingBottom: 100,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: tokens.spacing.section,
  },
  headerInfo: {
    flex: 1,
    marginLeft: tokens.spacing.element,
  },
  senderName: {
    ...typography.headingSmall,
  },
  senderEmail: {
    ...typography.labelMedium,
    marginTop: 2,
  },
  timestamp: {
    ...typography.labelSmall,
    marginTop: 4,
  },
  subject: {
    ...typography.headingLarge,
    marginBottom: tokens.spacing.section,
  },
  summaryCard: {
    marginBottom: tokens.spacing.component,
  },
  summaryHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: tokens.spacing.inline,
  },
  summaryLabel: {
    ...typography.labelSmall,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  summaryText: {
    ...typography.bodyMedium,
    lineHeight: 22,
  },
  bodyCard: {
    marginBottom: tokens.spacing.section,
  },
  bodyText: {
    ...typography.bodyMedium,
    lineHeight: 24,
  },
  actionsSection: {
    marginBottom: tokens.spacing.section,
  },
  actionsLabel: {
    ...typography.labelSmall,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: tokens.spacing.element,
  },
  primaryAction: {
    marginBottom: tokens.spacing.inline,
  },
  secondaryAction: {
    marginBottom: tokens.spacing.inline,
  },
  threadCard: {
    marginBottom: tokens.spacing.section,
  },
  threadText: {
    ...typography.bodySmall,
    textAlign: 'center',
  },
  bottomBar: {
    flexDirection: 'row',
    padding: tokens.spacing.component,
    borderTopWidth: 1,
    borderTopColor: colors.borderSubtle,
    gap: tokens.spacing.element,
  },
  bottomButton: {
    flex: 1,
  },
});

