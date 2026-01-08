/**
 * FeedScreen - Main card feed view
 * Single screen with CardStack, LiquidGlassBottomNav, and CelebrationView
 * Matches iOS app architecture
 */

import React, { useState, useCallback, useMemo, useRef } from 'react';
import { View, StyleSheet, Modal, StatusBar } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import type { EmailCard } from '@zero/types';
import { CardStack } from '../components/CardStack';
import { LiquidGlassBottomNav } from '../components/LiquidGlassBottomNav';
import { CelebrationView } from '../components/CelebrationView';
import { NebulaBackground } from '../components/NebulaBackground';
import { ActionSelectorSheet } from '../components/ActionSelectorSheet';
import { SnoozePickerSheet } from '../components/SnoozePickerSheet';
import { SwipeHintOverlay } from '../components/SwipeHintOverlay';
import { ActionToast } from '../components/ActionToast';
import { HapticService } from '../services/HapticService';
import { MOCK_MAIL_EMAILS, MOCK_ADS_EMAILS } from '../data/mockEmails';
import SettingsModal from './settings-modal';

type Mode = 'mail' | 'ads';

interface UndoState {
  visible: boolean;
  message: string;
  card: EmailCard | null;
  action: string;
}

interface ToastState {
  visible: boolean;
  message: string;
  type: 'success' | 'info';
}

export default function FeedScreen() {
  const router = useRouter();
  
  // Mode state
  const [mode, setMode] = useState<Mode>('mail');
  
  // Card state - separate arrays for mail and ads
  const [mailCards, setMailCards] = useState<EmailCard[]>(MOCK_MAIL_EMAILS);
  const [adsCards, setAdsCards] = useState<EmailCard[]>(MOCK_ADS_EMAILS);
  
  // UI state
  const [showSettings, setShowSettings] = useState(false);
  const [showActionSheet, setShowActionSheet] = useState(false);
  const [showSnoozeSheet, setShowSnoozeSheet] = useState(false);
  const [showSwipeHint, setShowSwipeHint] = useState(false);
  const [selectedCard, setSelectedCard] = useState<EmailCard | null>(null);
  const [celebration, setCelebration] = useState<{ show: boolean; type: Mode; allCleared: boolean }>({
    show: false,
    type: 'mail',
    allCleared: false,
  });
  
  // Toast state for undo and feedback
  const [toast, setToast] = useState<ToastState>({
    visible: false,
    message: '',
    type: 'success',
  });
  
  // Last removed card for undo
  const [lastRemovedCard, setLastRemovedCard] = useState<EmailCard | null>(null);
  
  // Track initial counts for progress bar
  const initialMailCount = useRef(MOCK_MAIL_EMAILS.length);
  const initialAdsCount = useRef(MOCK_ADS_EMAILS.length);
  const totalInitialCards = initialMailCount.current + initialAdsCount.current;
  
  // Current cards based on mode
  const currentCards = mode === 'mail' ? mailCards : adsCards;
  const currentIndex = 0; // Always show from top since we remove cards
  
  // Remove card from appropriate list
  const removeCard = useCallback((card: EmailCard, action: string) => {
    const isMailCard = card.type === 'mail';
    setLastRemovedCard(card);
    
    if (isMailCard) {
      setMailCards(prev => {
        const newCards = prev.filter(c => c.id !== card.id);
        // Schedule celebration check after state update
        if (newCards.length === 0) {
          setTimeout(() => {
            setCelebration({ show: true, type: 'mail', allCleared: adsCards.length === 0 });
          }, 0);
        }
        return newCards;
      });
    } else {
      setAdsCards(prev => {
        const newCards = prev.filter(c => c.id !== card.id);
        // Schedule celebration check after state update
        if (newCards.length === 0) {
          setTimeout(() => {
            setCelebration({ show: true, type: 'ads', allCleared: mailCards.length === 0 });
          }, 0);
        }
        return newCards;
      });
    }
    
    // Show toast
    setToast({
      visible: true,
      message: action,
      type: 'success',
    });
    
    // Auto-hide toast after 3 seconds
    setTimeout(() => {
      setToast(prev => ({ ...prev, visible: false }));
    }, 3000);
  }, [adsCards.length, mailCards.length]);
  
  // Undo action
  const handleUndo = useCallback(() => {
    if (!lastRemovedCard) return;
    
    const card = lastRemovedCard;
    if (card.type === 'mail') {
      setMailCards(prev => [card, ...prev]);
    } else {
      setAdsCards(prev => [card, ...prev]);
    }
    
    setCelebration({ show: false, type: 'mail', allCleared: false });
    setToast({ visible: false, message: '', type: 'success' });
    setLastRemovedCard(null);
    HapticService.selection();
  }, [lastRemovedCard]);
  
  // Swipe handlers
  const handleSwipeLeft = useCallback((card: EmailCard) => {
    removeCard(card, 'Archived');
  }, [removeCard]);
  
  const handleSwipeRight = useCallback((card: EmailCard) => {
    setSelectedCard(card);
    setShowActionSheet(true);
  }, []);
  
  const handleSwipeUp = useCallback((card: EmailCard) => {
    // Show more options / action sheet
    setSelectedCard(card);
    setShowActionSheet(true);
  }, []);
  
  const handleSwipeDown = useCallback((card: EmailCard) => {
    setSelectedCard(card);
    setShowSnoozeSheet(true);
  }, []);
  
  const handleCardPress = useCallback((card: EmailCard) => {
    // Navigate to email detail
    router.push(`/email/${card.id}`);
  }, [router]);
  
  // Action sheet handlers
  const handleSelectAction = useCallback((action: { id: string; displayName: string }) => {
    if (selectedCard) {
      removeCard(selectedCard, action.displayName);
    }
    setShowActionSheet(false);
    setSelectedCard(null);
  }, [selectedCard, removeCard]);
  
  // Snooze handlers
  const handleSnooze = useCallback((duration: string) => {
    if (selectedCard) {
      removeCard(selectedCard, `Snoozed (${duration})`);
    }
    setShowSnoozeSheet(false);
    setSelectedCard(null);
  }, [selectedCard, removeCard]);
  
  // Mode change
  const handleModeChange = useCallback((newMode: Mode) => {
    if (newMode !== mode) {
      setMode(newMode);
      HapticService.selection();
    }
  }, [mode]);
  
  // Celebration continue
  const handleCelebrationContinue = useCallback(() => {
    setCelebration({ show: false, type: 'mail', allCleared: false });
    
    // If we cleared one mode, switch to the other if it has cards
    if (celebration.type === 'mail' && adsCards.length > 0) {
      setMode('ads');
    } else if (celebration.type === 'ads' && mailCards.length > 0) {
      setMode('mail');
    }
  }, [celebration.type, adsCards.length, mailCards.length]);
  
  // Nav handlers
  const handleSettingsPress = useCallback(() => {
    setShowSettings(true);
    HapticService.selection();
  }, []);
  
  const handleSearchPress = useCallback(() => {
    // TODO: Implement search modal
    HapticService.selection();
  }, []);
  
  const handleRefreshPress = useCallback(() => {
    // Reset cards for demo
    setMailCards(MOCK_MAIL_EMAILS);
    setAdsCards(MOCK_ADS_EMAILS);
    HapticService.success();
  }, []);
  
  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" />
      
      {/* Background */}
      <NebulaBackground mode={mode} />
      
      <SafeAreaView style={styles.content} edges={['top']}>
        {/* Card Stack */}
        <CardStack
          cards={currentCards}
          currentIndex={currentIndex}
          onSwipeLeft={handleSwipeLeft}
          onSwipeRight={handleSwipeRight}
          onSwipeUp={handleSwipeUp}
          onSwipeDown={handleSwipeDown}
          onCardPress={handleCardPress}
          onIndexChange={() => {}}
          renderEmpty={() => (
            <View style={styles.emptyState}>
              {/* Empty state handled by CelebrationView */}
            </View>
          )}
        />
      </SafeAreaView>
      
      {/* Bottom Navigation */}
      <LiquidGlassBottomNav
        mode={mode}
        onModeChange={handleModeChange}
        mailCount={mailCards.length}
        adsCount={adsCards.length}
        totalInitialCards={totalInitialCards}
        onSettingsPress={handleSettingsPress}
        onSearchPress={handleSearchPress}
        onRefreshPress={handleRefreshPress}
      />
      
      {/* Celebration View */}
      {celebration.show && (
        <CelebrationView
          archetype={celebration.type}
          allArchetypesCleared={celebration.allCleared}
          onContinue={handleCelebrationContinue}
        />
      )}
      
      {/* Action Sheet */}
      <ActionSelectorSheet
        visible={showActionSheet}
        onClose={() => {
          setShowActionSheet(false);
          setSelectedCard(null);
        }}
        onSelectAction={handleSelectAction}
        card={selectedCard}
      />
      
      {/* Snooze Sheet */}
      <SnoozePickerSheet
        visible={showSnoozeSheet}
        onClose={() => {
          setShowSnoozeSheet(false);
          setSelectedCard(null);
        }}
        onSelect={(option) => handleSnooze(option.label)}
        emailTitle={selectedCard?.title}
      />
      
      {/* Toast for feedback */}
      {toast.visible && (
        <ActionToast
          message={toast.message}
          onUndo={lastRemovedCard ? handleUndo : undefined}
          onDismiss={() => setToast(prev => ({ ...prev, visible: false }))}
        />
      )}
      
      {/* Swipe Hint */}
      <SwipeHintOverlay
        visible={showSwipeHint}
        onDismiss={() => setShowSwipeHint(false)}
      />
      
      {/* Settings Modal */}
      <Modal
        visible={showSettings}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() => setShowSettings(false)}
      >
        <SettingsModal onClose={() => setShowSettings(false)} />
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0f',
  },
  content: {
    flex: 1,
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

