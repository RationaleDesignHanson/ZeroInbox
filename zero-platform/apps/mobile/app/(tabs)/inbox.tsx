/**
 * Inbox Screen
 * Main email list with swipe gestures
 */

import { useState, useCallback } from 'react';
import { FlatList, RefreshControl, StyleSheet, View } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  Screen,
  InboxHeader,
  EmailCard,
  LoadingSpinner,
  EmptyState,
  tokens,
  colors,
} from '@zero/ui';
import { useInbox, useRefreshInbox } from '@zero/api';
import type { EmailCard as EmailCardType } from '@zero/types';

export default function InboxScreen() {
  const router = useRouter();
  const [mode, setMode] = useState<'mail' | 'ads'>('mail');

  const {
    data: inbox,
    isLoading,
    isError,
    refetch,
  } = useInbox({ type: mode });

  const refreshMutation = useRefreshInbox();

  const onRefresh = useCallback(async () => {
    await refreshMutation.mutateAsync();
    await refetch();
  }, [refreshMutation, refetch]);

  const handleEmailPress = useCallback((email: EmailCardType) => {
    router.push(`/email/${email.id}`);
  }, [router]);

  const handleModeChange = useCallback((newMode: 'mail' | 'ads') => {
    setMode(newMode);
    if (newMode === 'ads') {
      router.push('/(tabs)/ads');
    }
  }, [router]);

  const handleSearchPress = useCallback(() => {
    // TODO: Implement search modal
  }, []);

  const handleSettingsPress = useCallback(() => {
    router.push('/(tabs)/settings');
  }, [router]);

  const renderEmail = useCallback(
    ({ item }: { item: EmailCardType }) => (
      <View style={styles.cardContainer}>
        <EmailCard
          email={item}
          onPress={() => handleEmailPress(item)}
          showActions
        />
      </View>
    ),
    [handleEmailPress]
  );

  const keyExtractor = useCallback((item: EmailCardType) => item.id, []);

  if (isLoading) {
    return (
      <Screen>
        <LoadingSpinner message="Loading your inbox..." />
      </Screen>
    );
  }

  if (isError) {
    return (
      <Screen>
        <EmptyState
          title="Unable to load inbox"
          message="Please check your connection and try again."
          actionLabel="Retry"
          onAction={() => refetch()}
        />
      </Screen>
    );
  }

  const emails = inbox?.items || [];

  return (
    <Screen>
      <SafeAreaView style={styles.container} edges={['top']}>
        <InboxHeader
          mode={mode}
          unreadCount={inbox?.unreadCounts?.mail || 0}
          onModeChange={handleModeChange}
          onSearchPress={handleSearchPress}
          onSettingsPress={handleSettingsPress}
        />

        {emails.length === 0 ? (
          <EmptyState
            title="All caught up!"
            message="You've processed all your mail. Nice work!"
          />
        ) : (
          <FlatList
            data={emails}
            renderItem={renderEmail}
            keyExtractor={keyExtractor}
            contentContainerStyle={styles.list}
            showsVerticalScrollIndicator={false}
            refreshControl={
              <RefreshControl
                refreshing={refreshMutation.isPending}
                onRefresh={onRefresh}
                tintColor={colors.mailGradientStart}
              />
            }
          />
        )}
      </SafeAreaView>
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  list: {
    padding: tokens.spacing.component,
    gap: tokens.spacing.element,
  },
  cardContainer: {
    marginBottom: tokens.spacing.element,
  },
});

