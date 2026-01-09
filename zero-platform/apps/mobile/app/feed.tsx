/**
 * FeedScreen - Main card feed with swipe actions
 * Core email triage experience matching iOS app
 */

import React, { useState, useCallback, useRef, useMemo } from 'react';
import { View, StyleSheet, Text, Dimensions } from 'react-native';
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

// Action Modals
import { EmailComposerModal } from '../components/modals/EmailComposerModal';
import { CalendarModal } from '../components/modals/CalendarModal';
import { ConfirmationModal } from '../components/modals/ConfirmationModal';
import { DocumentViewerModal } from '../components/modals/DocumentViewerModal';

// Services
import { HapticService } from '../services/HapticService';
import { ActionRouter } from '../services/ActionRouter';

// Data
import { ALL_MOCK_EMAILS, MOCK_MAIL_EMAILS, MOCK_ADS_EMAILS } from '../data/mockEmails';

// Context
import { useAuth } from '../contexts/AuthContext';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

type FeedMode = 'mail' | 'ads';
type ToastAction = {
  message: string;
  actionLabel?: string;
  onAction?: () => void;
};

export default function FeedScreen() {
  const { logout } = useAuth();
  
  // Card state - separate mail and ads
  const [mailCards, setMailCards] = useState<EmailCard[]>([...MOCK_MAIL_EMAILS]);
  const [adsCards, setAdsCards] = useState<EmailCard[]>([...MOCK_ADS_EMAILS]);
  const [mode, setMode] = useState<FeedMode>('mail');
  const [currentIndex, setCurrentIndex] = useState(0);
  
  // Track initial counts for progress
  const initialMailCount = useRef(MOCK_MAIL_EMAILS.length);
  const initialAdsCount = useRef(MOCK_ADS_EMAILS.length);
  
  // UI state
  const [showCelebration, setShowCelebration] = useState(false);
  const [showActionSheet, setShowActionSheet] = useState(false);
  const [showSnoozeSheet, setShowSnoozeSheet] = useState(false);
  const [showSearchModal, setShowSearchModal] = useState(false);
  const [toast, setToast] = useState<ToastAction | null>(null);
  
  // Current card for action sheets
  const [activeCard, setActiveCard] = useState<EmailCard | null>(null);
  
  // Action modal state
  const [activeAction, setActiveAction] = useState<SuggestedAction | null>(null);
  const [showEmailComposer, setShowEmailComposer] = useState(false);
  const [showCalendarModal, setShowCalendarModal] = useState(false);
  const [showConfirmationModal, setShowConfirmationModal] = useState(false);
  const [showDocumentModal, setShowDocumentModal] = useState(false);
  
  // Undo stack
  const undoStack = useRef<{ card: EmailCard; mode: FeedMode }[]>([]);

  // Current cards based on mode
  const currentCards = mode === 'mail' ? mailCards : adsCards;
  const setCurrentCards = mode === 'mail' ? setMailCards : setAdsCards;
  const totalInitial = mode === 'mail' ? initialMailCount.current : initialAdsCount.current;

  // Remove a card from the stack
  const removeCard = useCallback((cardId: string) => {
    const cards = mode === 'mail' ? mailCards : adsCards;
    const card = cards.find((c) => c.id === cardId);
    
    if (card) {
      // Store for undo
      undoStack.current.push({ card, mode });
      if (undoStack.current.length > 10) {
        undoStack.current.shift();
      }
    }
    
    if (mode === 'mail') {
      setMailCards((prev) => {
        const newCards = prev.filter((c) => c.id !== cardId);
        if (newCards.length === 0) {
          setTimeout(() => setShowCelebration(true), 300);
        }
        return newCards;
      });
    } else {
      setAdsCards((prev) => {
        const newCards = prev.filter((c) => c.id !== cardId);
        if (newCards.length === 0) {
          setTimeout(() => setShowCelebration(true), 300);
        }
        return newCards;
      });
    }
  }, [mode, mailCards, adsCards]);

  // Undo last action
  const handleUndo = useCallback(() => {
    const lastAction = undoStack.current.pop();
    if (lastAction) {
      HapticService.lightImpact();
      if (lastAction.mode === 'mail') {
        setMailCards((prev) => [lastAction.card, ...prev]);
      } else {
        setAdsCards((prev) => [lastAction.card, ...prev]);
      }
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
    showToast(`Archived "${card.title.substring(0, 25)}..."`);
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
    setShowActionSheet(true); // Swipe UP = Actions
  }, []);

  const handleSwipeDown = useCallback((card: EmailCard) => {
    HapticService.lightImpact();
    setActiveCard(card);
    setShowSnoozeSheet(true); // Swipe DOWN = Snooze
  }, []);

  const handleCardPress = useCallback((card: EmailCard) => {
    HapticService.lightImpact();
    router.push(`/email/${card.id}`);
  }, []);

  const handleIndexChange = useCallback((index: number) => {
    setCurrentIndex(index);
  }, []);

  // Determine which modal to show for an action
  const getModalForAction = useCallback((actionId: string): 'email' | 'calendar' | 'document' | 'confirmation' | 'none' => {
    // Reply actions
    if (['reply', 'quick_reply', 'forward', 'respond'].includes(actionId)) {
      return 'email';
    }
    // Calendar actions
    if (['schedule', 'add_to_calendar', 'rsvp_yes', 'rsvp_no', 'schedule_meeting'].includes(actionId)) {
      return 'calendar';
    }
    // Document actions
    if (['view_document', 'sign_document', 'review_attachment', 'sign_form'].includes(actionId)) {
      return 'document';
    }
    // Actions that need confirmation
    if (['archive', 'delete', 'acknowledge', 'confirm_attendance', 'mark_read', 'mark_unread'].includes(actionId)) {
      return 'confirmation';
    }
    // Quick actions that don't need a modal
    return 'none';
  }, []);

  // Action sheet handlers
  const handleSelectAction = useCallback((action: { id: string; displayName: string }) => {
    if (!activeCard) return;
    
    HapticService.lightImpact();
    setShowActionSheet(false);
    
    const modalType = getModalForAction(action.id);
    
    // Create a full action object
    const fullAction: SuggestedAction = {
      id: action.id,
      displayName: action.displayName,
      type: action.id as any,
    };
    setActiveAction(fullAction);
    
    switch (modalType) {
      case 'email':
        setShowEmailComposer(true);
        break;
      case 'calendar':
        setShowCalendarModal(true);
        break;
      case 'document':
        setShowDocumentModal(true);
        break;
      case 'confirmation':
        setShowConfirmationModal(true);
        break;
      case 'none':
      default:
        // Execute immediately without modal
        ActionRouter.executeAction(fullAction, activeCard);
        removeCard(activeCard.id);
        showToast(`${action.displayName} completed`);
        setActiveCard(null);
        setActiveAction(null);
        break;
    }
  }, [activeCard, getModalForAction, removeCard, showToast]);
  
  // Modal completion handlers
  const handleEmailSend = useCallback((message: string) => {
    if (!activeCard || !activeAction) return;
    
    HapticService.success();
    setShowEmailComposer(false);
    removeCard(activeCard.id);
    showToast('Reply sent');
    setActiveCard(null);
    setActiveAction(null);
  }, [activeCard, activeAction, removeCard, showToast]);
  
  const handleCalendarAdd = useCallback(() => {
    if (!activeCard || !activeAction) return;
    
    HapticService.success();
    setShowCalendarModal(false);
    removeCard(activeCard.id);
    showToast('Added to calendar');
    setActiveCard(null);
    setActiveAction(null);
  }, [activeCard, activeAction, removeCard, showToast]);
  
  const handleConfirmAction = useCallback(() => {
    if (!activeCard || !activeAction) return;
    
    HapticService.success();
    setShowConfirmationModal(false);
    ActionRouter.executeAction(activeAction, activeCard);
    removeCard(activeCard.id);
    showToast(`${activeAction.displayName} completed`);
    setActiveCard(null);
    setActiveAction(null);
  }, [activeCard, activeAction, removeCard, showToast]);
  
  const handleDocumentAction = useCallback((actionType: string) => {
    if (!activeCard || !activeAction) return;
    
    HapticService.success();
    setShowDocumentModal(false);
    
    if (actionType === 'sign') {
      showToast('Document signed');
    } else {
      showToast('Document downloaded');
    }
    
    removeCard(activeCard.id);
    setActiveCard(null);
    setActiveAction(null);
  }, [activeCard, activeAction, removeCard, showToast]);
  
  const closeAllModals = useCallback(() => {
    setShowEmailComposer(false);
    setShowCalendarModal(false);
    setShowConfirmationModal(false);
    setShowDocumentModal(false);
    setActiveAction(null);
  }, []);

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
    setCurrentIndex(0);
  }, [mode]);

  // Celebration continue
  const handleCelebrationContinue = useCallback(() => {
    HapticService.success();
    setShowCelebration(false);
    // Reset the current mode's cards
    if (mode === 'mail') {
      setMailCards([...MOCK_MAIL_EMAILS]);
      initialMailCount.current = MOCK_MAIL_EMAILS.length;
    } else {
      setAdsCards([...MOCK_ADS_EMAILS]);
      initialAdsCount.current = MOCK_ADS_EMAILS.length;
    }
    setCurrentIndex(0);
  }, [mode]);

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
    if (mode === 'mail') {
      setMailCards([...MOCK_MAIL_EMAILS]);
      initialMailCount.current = MOCK_MAIL_EMAILS.length;
    } else {
      setAdsCards([...MOCK_ADS_EMAILS]);
      initialAdsCount.current = MOCK_ADS_EMAILS.length;
    }
    setCurrentIndex(0);
    showToast('Refreshed inbox', false);
  }, [mode, showToast]);

  // Render empty state
  const renderEmpty = useCallback(() => (
    <View style={styles.emptyState}>
      <Text style={styles.emptyEmoji}>🎉</Text>
      <Text style={styles.emptyTitle}>All caught up!</Text>
      <Text style={styles.emptySubtitle}>No more {mode === 'mail' ? 'emails' : 'promotions'} to process</Text>
    </View>
  ), [mode]);

  // Celebration view
  if (showCelebration) {
    return (
      <CelebrationView
        emailsProcessed={totalInitial - currentCards.length}
        onContinue={handleCelebrationContinue}
      />
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      {/* Card Stack */}
      <View style={styles.cardContainer}>
        <CardStack
          cards={currentCards}
          currentIndex={currentIndex}
          onSwipeLeft={handleSwipeLeft}
          onSwipeRight={handleSwipeRight}
          onSwipeUp={handleSwipeUp}
          onSwipeDown={handleSwipeDown}
          onCardPress={handleCardPress}
          onIndexChange={handleIndexChange}
          renderEmpty={renderEmpty}
        />
      </View>

      {/* Bottom Navigation */}
      <LiquidGlassBottomNav
        mode={mode}
        onModeChange={handleModeChange}
        mailCount={mailCards.length}
        adsCount={adsCards.length}
        totalInitialCards={totalInitial}
        onSettingsPress={handleSettingsPress}
        onSearchPress={handleSearchPress}
        onRefreshPress={handleRefreshPress}
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
        emails={[...mailCards, ...adsCards]}
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
      
      {/* Email Composer Modal */}
      {activeCard && activeAction && (
        <EmailComposerModal
          visible={showEmailComposer}
          onClose={() => {
            setShowEmailComposer(false);
            closeAllModals();
          }}
          onSend={handleEmailSend}
          card={activeCard}
          action={activeAction}
        />
      )}
      
      {/* Calendar Modal */}
      {activeCard && activeAction && (
        <CalendarModal
          visible={showCalendarModal}
          onClose={() => {
            setShowCalendarModal(false);
            closeAllModals();
          }}
          onAdd={handleCalendarAdd}
          card={activeCard}
          action={activeAction}
        />
      )}
      
      {/* Confirmation Modal */}
      {activeCard && activeAction && (
        <ConfirmationModal
          visible={showConfirmationModal}
          onClose={() => {
            setShowConfirmationModal(false);
            closeAllModals();
          }}
          onConfirm={handleConfirmAction}
          card={activeCard}
          action={activeAction}
        />
      )}
      
      {/* Document Viewer Modal */}
      {activeCard && activeAction && (
        <DocumentViewerModal
          visible={showDocumentModal}
          onClose={() => {
            setShowDocumentModal(false);
            closeAllModals();
          }}
          onAction={handleDocumentAction}
          card={activeCard}
          action={activeAction}
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
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: 40,
  },
  emptyEmoji: {
    fontSize: 64,
    marginBottom: 16,
  },
  emptyTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: 'white',
    marginBottom: 8,
  },
  emptySubtitle: {
    fontSize: 16,
    color: 'rgba(255,255,255,0.6)',
    textAlign: 'center',
  },
});
