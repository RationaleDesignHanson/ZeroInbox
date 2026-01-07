/**
 * Ads Screen
 * Shopping and promotional emails
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
  ThemeProvider,
  tokens,
  colors,
} from '@zero/ui';
import { useInbox, useRefreshInbox } from '@zero/api';
import type { EmailCard as EmailCardType } from '@zero/types';

export default function AdsScreen() {
  const router = useRouter();
  const [mode, setMode] = useState<'mail' | 'ads'>('ads');

  const {
    data: inbox,
    isLoading,
    isError,
    refetch,
  } = useInbox({ type: 'ads' });

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
    if (newMode === 'mail') {
      router.push('/(tabs)/inbox');
    }
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
      <ThemeProvider mode="ads">
        <Screen>
          <LoadingSpinner message="Loading deals..." />
        </Screen>
      </ThemeProvider>
    );
  }

  if (isError) {
    return (
      <ThemeProvider mode="ads">
        <Screen>
          <EmptyState
            title="Unable to load ads"
            message="Please check your connection and try again."
            actionLabel="Retry"
            onAction={() => refetch()}
          />
        </Screen>
      </ThemeProvider>
    );
  }

  const emails = inbox?.items || [];

  return (
    <ThemeProvider mode="ads">
      <Screen>
        <SafeAreaView style={styles.container} edges={['top']}>
          <InboxHeader
            mode={mode}
            onModeChange={handleModeChange}
          />

          {emails.length === 0 ? (
            <EmptyState
              title="No deals today"
              message="Check back later for new promotions and offers."
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
                  tintColor={colors.adsGradientStart}
                />
              }
            />
          )}
        </SafeAreaView>
      </Screen>
    </ThemeProvider>
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

