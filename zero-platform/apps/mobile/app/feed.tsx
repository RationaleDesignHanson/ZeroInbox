/**
 * FeedScreen - Main card feed with swipe actions
 * Core email triage experience matching iOS app
 */

import React, { useState, useCallback, useRef } from 'react';
import { View, StyleSheet, Dimensions } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import type { EmailCard, SuggestedAction } from '@zero/types';

// Components
import { CardStack } from '../components/CardStack';
import { LiquidGlassBottomNav } from '../components/LiquidGlassBottomNav';
import { CelebrationView } from '../components/CelebrationView';
import { ActionSelectorSheet } from '../components/ActionSelectorSheet';
import { SnoozePickerSheet } from '../components/SnoozePickerSheet';
import { ActionToast } from '../components/ActionToast';
import { SearchModal } from '../components/SearchModal';

// Services
import { HapticService } from '../services/HapticService';
import { ActionRouter } from '../services/ActionRouter';

// Data
import { ALL_MOCK_EMAILS, MOCK_MAIL_EMAILS, MOCK_ADS_EMAILS } from '../data/mockEmails';

// Context
import { useAuth } from '../contexts/AuthContext';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

type FeedMode = 'all' | 'mail' | 'ads';
type ToastAction = {
  message: string;
  actionLabel?: string;
  onAction?: () => void;
};

export default function FeedScreen() {
  const { logout } = useAuth();
  
  // Card state
  const [cards, setCards] = useState<EmailCard[]>([...ALL_MOCK_EMAILS]);
  const [mode, setMode] = useState<FeedMode>('all');
  const [processedCount, setProcessedCount] = useState(0);
  
  // UI state
  const [showCelebration, setShowCelebration] = useState(false);
  const [showActionSheet, setShowActionSheet] = useState(false);
  const [showSnoozeSheet, setShowSnoozeSheet] = useState(false);
  const [showSearchModal, setShowSearchModal] = useState(false);
  const [toast, setToast] = useState<ToastAction | null>(null);
  
  // Current card for action sheets
  const [activeCard, setActiveCard] = useState<EmailCard | null>(null);
  
  // Undo stack
  const undoStack = useRef<{ card: EmailCard; index: number }[]>([]);

  // Get cards for current mode
  const getCardsForMode = useCallback((newMode: FeedMode): EmailCard[] => {
    switch (newMode) {
      case 'mail':
        return [...MOCK_MAIL_EMAILS];
      case 'ads':
        return [...MOCK_ADS_EMAILS];
      default:
        return [...ALL_MOCK_EMAILS];
    }
  }, []);

  // Remove a card from the stack
  const removeCard = useCallback((cardId: string, showCelebrationIfEmpty = true) => {
    setCards((prev) => {
      const index = prev.findIndex((c) => c.id === cardId);
      const card = prev.find((c) => c.id === cardId);
      
      if (card && index !== -1) {
        // Store for undo
        undoStack.current.push({ card, index });
        if (undoStack.current.length > 10) {
          undoStack.current.shift();
        }
      }
      
      const newCards = prev.filter((c) => c.id !== cardId);
      
      // Schedule celebration check for next tick to avoid nested setState
      if (showCelebrationIfEmpty && newCards.length === 0) {
        setTimeout(() => setShowCelebration(true), 0);
      }
      
      return newCards;
    });
    
    setProcessedCount((p) => p + 1);
  }, []);

  // Undo last action
  const handleUndo = useCallback(() => {
    const lastAction = undoStack.current.pop();
    if (lastAction) {
      HapticService.lightImpact();
      setCards((prev) => {
        const newCards = [...prev];
        newCards.splice(lastAction.index, 0, lastAction.card);
        return newCards;
      });
      setProcessedCount((p) => Math.max(0, p - 1));
      setToast(null);
    }
  }, []);

  // Show toast with optional undo
  const showToast = useCallback((message: string, allowUndo = true) => {
    setToast({
      message,
      actionLabel: allowUndo ? 'Undo' : undefined,
      onAction: allowUndo ? handleUndo : undefined,
    });
    
    // Auto-dismiss after 3 seconds
    setTimeout(() => setToast(null), 3000);
  }, [handleUndo]);

  // Swipe handlers
  const handleSwipeLeft = useCallback((card: EmailCard) => {
    HapticService.mediumImpact();
    removeCard(card.id);
    showToast(`Archived "${card.title.substring(0, 30)}..."`);
  }, [removeCard, showToast]);

  const handleSwipeRight = useCallback((card: EmailCard) => {
    HapticService.mediumImpact();
    
    // Execute primary action
    const primaryAction = card.suggestedActions?.find((a) => a.isPrimary);
    if (primaryAction) {
      ActionRouter.executeAction(primaryAction, card);
    }
    
    removeCard(card.id);
    showToast(`${primaryAction?.displayName || 'Action'} completed`);
  }, [removeCard, showToast]);

  const handleSwipeUp = useCallback((card: EmailCard) => {
    HapticService.lightImpact();
    setActiveCard(card);
    setShowSnoozeSheet(true);
  }, []);

  const handleSwipeDown = useCallback((card: EmailCard) => {
    HapticService.lightImpact();
    setActiveCard(card);
    setShowActionSheet(true);
  }, []);

  const handleCardPress = useCallback((card: EmailCard) => {
    HapticService.lightImpact();
    router.push(`/email/${card.id}`);
  }, []);

  // Action sheet handlers
  const handleSelectAction = useCallback((actionId: string, actionName: string) => {
    if (!activeCard) return;
    
    HapticService.mediumImpact();
    setShowActionSheet(false);
    
    const action = activeCard.suggestedActions?.find((a) => a.id === actionId);
    if (action) {
      ActionRouter.executeAction(action, activeCard);
    }
    
    removeCard(activeCard.id);
    showToast(`${actionName} completed`);
    setActiveCard(null);
  }, [activeCard, removeCard, showToast]);

  const handleSnooze = useCallback((duration: string) => {
    if (!activeCard) return;
    
    HapticService.mediumImpact();
    setShowSnoozeSheet(false);
    removeCard(activeCard.id);
    showToast(`Snoozed until ${duration}`);
    setActiveCard(null);
  }, [activeCard, removeCard, showToast]);

  // Mode change (bottom nav)
  const handleModeChange = useCallback((newMode: FeedMode) => {
    if (newMode === mode) return;
    
    HapticService.lightImpact();
    setMode(newMode);
    setCards(getCardsForMode(newMode));
    setProcessedCount(0);
  }, [mode, getCardsForMode]);

  // Celebration continue
  const handleCelebrationContinue = useCallback(() => {
    HapticService.success();
    setShowCelebration(false);
    setCards(getCardsForMode(mode));
    setProcessedCount(0);
  }, [mode, getCardsForMode]);

  // Nav actions
  const handleSettingsPress = useCallback(() => {
    HapticService.lightImpact();
    router.push('/settings-modal');
  }, []);

  const handleSearchPress = useCallback(() => {
    HapticService.lightImpact();
    setShowSearchModal(true);
  }, []);

  const handleRefreshPress = useCallback(() => {
    HapticService.mediumImpact();
    setCards(getCardsForMode(mode));
    setProcessedCount(0);
    showToast('Refreshed inbox', false);
  }, [mode, getCardsForMode, showToast]);

  // Celebration view
  if (showCelebration) {
    return (
      <CelebrationView
        emailsProcessed={processedCount}
        onContinue={handleCelebrationContinue}
      />
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      {/* Card Stack */}
      <View style={styles.cardContainer}>
        <CardStack
          cards={cards}
          onSwipeLeft={handleSwipeLeft}
          onSwipeRight={handleSwipeRight}
          onSwipeUp={handleSwipeUp}
          onSwipeDown={handleSwipeDown}
          onCardPress={handleCardPress}
        />
      </View>

      {/* Bottom Navigation */}
      <LiquidGlassBottomNav
        mode={mode}
        onModeChange={handleModeChange}
        onSettingsPress={handleSettingsPress}
        onSearchPress={handleSearchPress}
        onRefreshPress={handleRefreshPress}
        cardCount={cards.length}
        processedCount={processedCount}
      />

      {/* Action Selector Sheet */}
      <ActionSelectorSheet
        visible={showActionSheet}
        onClose={() => {
          setShowActionSheet(false);
          setActiveCard(null);
        }}
        onSelectAction={handleSelectAction}
        card={activeCard}
      />

      {/* Snooze Picker Sheet */}
      <SnoozePickerSheet
        visible={showSnoozeSheet}
        onClose={() => {
          setShowSnoozeSheet(false);
          setActiveCard(null);
        }}
        onSelectDuration={handleSnooze}
      />

      {/* Search Modal */}
      <SearchModal
        visible={showSearchModal}
        onClose={() => setShowSearchModal(false)}
        emails={ALL_MOCK_EMAILS}
        onSelectEmail={(email) => {
          setShowSearchModal(false);
          router.push(`/email/${email.id}`);
        }}
      />

      {/* Toast */}
      {toast && (
        <ActionToast
          message={toast.message}
          actionLabel={toast.actionLabel}
          onAction={toast.onAction}
          onDismiss={() => setToast(null)}
        />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0f',
  },
  cardContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
