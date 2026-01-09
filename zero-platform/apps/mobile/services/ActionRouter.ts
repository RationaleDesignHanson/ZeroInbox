/**
 * ActionRouter - Routes and executes actions based on actionId and type
 * Handles both GO_TO (external URLs) and IN_APP (modal) actions
 * Matches iOS ActionRouter.swift implementation
 */

import * as Linking from 'expo-linking';
import * as WebBrowser from 'expo-web-browser';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from './HapticService';
import { ACTION_CONFIGS, getActionConfig, ActionConfig } from '../data/actionConfigs';

// Action types matching iOS implementation
export type ActionType = 'GO_TO' | 'IN_APP';

// All modal types supported by the app
export type ModalType =
  // Shipping
  | 'TrackPackageModal'
  | 'ScheduleDeliveryTimeModal'
  | 'PickupDetailsModal'
  | 'ContactDriverModal'
  // Financial
  | 'PayInvoiceModal'
  | 'UpdatePaymentModal'
  | 'CancelSubscriptionModal'
  | 'ScheduledPurchaseModal'
  // Travel
  | 'CheckInFlightModal'
  | 'ViewItineraryModal'
  | 'ReservationModal'
  // Calendar
  | 'AddToCalendarModal'
  | 'ScheduleMeetingModal'
  | 'RSVPModal'
  // Documents
  | 'DocumentViewerModal'
  | 'DocumentPreviewModal'
  | 'SignFormModal'
  | 'SpreadsheetViewerModal'
  | 'AttachmentViewerModal'
  // Communication
  | 'QuickReplyModal'
  | 'SendMessageModal'
  | 'SaveContactModal'
  // Shopping
  | 'BrowseShoppingModal'
  | 'ShoppingPurchaseModal'
  | 'ShoppingAutomationModal'
  | 'WriteReviewModal'
  // Account
  | 'AccountVerificationModal'
  | 'ReviewSecurityModal'
  | 'ProvideAccessCodeModal'
  // Utilities
  | 'UnsubscribeModal'
  | 'AddReminderModal'
  | 'AddToNotesModal'
  | 'AddToWalletModal'
  | 'ShareModal'
  | 'SnoozeModal'
  // Content
  | 'NewsletterSummaryModal'
  | 'ReadCommunityPostModal'
  | 'ViewPostCommentsModal'
  | 'ViewDetailsModal'
  | 'ViewActivityModal'
  | 'ViewActivityDetailsModal'
  // Infrastructure
  | 'PrepareForOutageModal'
  | 'ViewOutageDetailsModal'
  | 'OpenAppModal'
  // Quick actions
  | 'ConfirmationModal';

// Result of routing an action
export interface ActionRouteResult {
  type: ActionType;
  modalType: ModalType;
  actionConfig: ActionConfig | null;
  url?: string;
  context: Record<string, string>;
}

// Action modal event handler types
export type ActionModalHandler = (
  modalType: ModalType,
  card: EmailCard,
  action: SuggestedAction,
  actionConfig: ActionConfig | null,
  context: Record<string, string>
) => void;

// URL mappings for GO_TO actions
const URL_MAPPINGS: Record<string, string[]> = {
  track_package: ['trackingUrl', 'url'],
  pay_invoice: ['paymentLink', 'url'],
  view_order: ['orderUrl', 'url'],
  check_in_flight: ['checkInUrl', 'url'],
  reset_password: ['resetLink', 'verificationLink', 'url'],
  verify_account: ['verificationLink', 'resetLink', 'url'],
  register_event: ['registrationLink', 'url'],
  write_review: ['reviewLink', 'url'],
  view_ticket: ['ticketUrl', 'url'],
  join_meeting: ['meetingUrl', 'url'],
  download_receipt: ['receiptUrl', 'url'],
  claim_deal: ['dealUrl', 'productUrl', 'url'],
  view_product: ['productUrl', 'dealUrl', 'url'],
  complete_cart: ['cartUrl', 'url'],
  manage_booking: ['bookingUrl', 'url'],
  contact_support: ['supportUrl', 'url'],
  open_link: ['url'],
  unsubscribe: ['unsubscribeUrl', 'url'],
};

// Actions that can execute immediately without showing a modal
const INSTANT_ACTIONS = new Set([
  'archive',
  'delete',
  'mark_read',
  'mark_unread',
  'save_for_later',
]);

class ActionRouterService {
  private modalHandler: ActionModalHandler | null = null;

  /**
   * Register a handler for modal actions
   * This should be called by the feed screen to handle modals
   */
  setModalHandler(handler: ActionModalHandler) {
    this.modalHandler = handler;
  }

  /**
   * Clear the modal handler
   */
  clearModalHandler() {
    this.modalHandler = null;
  }

  /**
   * Get action config from registry
   */
  getConfig(actionId: string): ActionConfig | null {
    return getActionConfig(actionId) || null;
  }

  /**
   * Check if action should show a modal
   */
  shouldShowModal(actionId: string): boolean {
    const config = this.getConfig(actionId);
    if (!config) return true; // Default to showing modal for unknown actions
    
    // IN_APP actions show modals, GO_TO actions may or may not
    if (config.actionType === 'IN_APP') {
      return !INSTANT_ACTIONS.has(actionId);
    }
    
    return false;
  }

  /**
   * Get the modal type for an action
   */
  getModalType(actionId: string): ModalType {
    const config = this.getConfig(actionId);
    if (config?.modalComponent) {
      return config.modalComponent as ModalType;
    }
    
    // Fallback to view details
    return 'ViewDetailsModal';
  }

  /**
   * Route an action to determine how it should be executed
   */
  routeAction(action: SuggestedAction, card: EmailCard): ActionRouteResult {
    const actionId = action.id.toLowerCase();
    const context = this.extractContext(action, card);
    const config = this.getConfig(actionId);

    // Determine action type
    const actionType: ActionType = config?.actionType || 'IN_APP';
    
    // Get modal type
    const modalType = this.getModalType(actionId);

    // Check for external URL
    if (actionType === 'GO_TO' || this.hasExternalUrl(actionId, context)) {
      const url = this.getUrlForAction(actionId, context);
      return {
        type: 'GO_TO',
        modalType,
        actionConfig: config,
        url,
        context,
      };
    }

    return {
      type: 'IN_APP',
      modalType,
      actionConfig: config,
      context,
    };
  }

  /**
   * Execute an action - either show modal or open URL
   */
  async executeAction(
    action: SuggestedAction,
    card: EmailCard
  ): Promise<{ success: boolean; showModal: boolean; modalType?: ModalType; message?: string }> {
    const route = this.routeAction(action, card);
    const actionId = action.id.toLowerCase();

    HapticService.mediumImpact();

    // Check if this should be an instant action (no modal)
    if (INSTANT_ACTIONS.has(actionId)) {
      return { 
        success: true, 
        showModal: false,
        message: `${action.displayName} completed`
      };
    }

    // GO_TO actions open external URL
    if (route.type === 'GO_TO' && route.url) {
      const result = await this.executeGoToAction(route.url);
      return { ...result, showModal: false };
    }

    // IN_APP actions show modal
    if (route.type === 'IN_APP') {
      if (this.modalHandler) {
        this.modalHandler(route.modalType, card, action, route.actionConfig, route.context);
        return { success: true, showModal: true, modalType: route.modalType };
      }
      
      // No handler registered - return info about which modal should be shown
      return { 
        success: true, 
        showModal: true, 
        modalType: route.modalType,
        message: 'Modal handler not registered' 
      };
    }

    return { success: false, showModal: false, message: 'Unknown action type' };
  }

  /**
   * Execute a GO_TO action by opening the URL
   */
  private async executeGoToAction(url: string): Promise<{ success: boolean; message?: string }> {
    try {
      // Try to open in in-app browser first for better UX
      const result = await WebBrowser.openBrowserAsync(url, {
        presentationStyle: WebBrowser.WebBrowserPresentationStyle.PAGE_SHEET,
        controlsColor: '#667eea',
        dismissButtonStyle: 'close',
      });

      if (result.type === 'cancel') {
        return { success: true, message: 'Browser closed' };
      }

      return { success: true };
    } catch (error) {
      // Fallback to external browser
      try {
        const canOpen = await Linking.canOpenURL(url);
        if (canOpen) {
          await Linking.openURL(url);
          return { success: true };
        }
        return { success: false, message: 'Cannot open URL' };
      } catch (linkError) {
        console.error('ActionRouter: Failed to open URL:', linkError);
        return { success: false, message: 'Failed to open link' };
      }
    }
  }

  /**
   * Get the primary action from a card
   */
  getPrimaryAction(card: EmailCard): SuggestedAction | null {
    if (!card.suggestedActions || card.suggestedActions.length === 0) {
      return null;
    }

    // Find primary action or return first
    return (
      card.suggestedActions.find((a) => a.isPrimary) || card.suggestedActions[0]
    );
  }

  /**
   * Get secondary actions from a card
   */
  getSecondaryActions(card: EmailCard): SuggestedAction[] {
    if (!card.suggestedActions) {
      return [];
    }
    return card.suggestedActions.filter((a) => !a.isPrimary);
  }

  /**
   * Extract context from action and card
   */
  private extractContext(
    action: SuggestedAction,
    card: EmailCard
  ): Record<string, string> {
    const context: Record<string, string> = {};

    // Add action context if available
    if (action.context) {
      Object.assign(context, action.context);
    }

    // Add card metadata
    context.cardId = card.id;
    context.cardTitle = card.title;
    if (card.sender?.email) {
      context.senderEmail = card.sender.email;
      context.recipientEmail = card.sender.email; // For replies
    }
    if (card.sender?.name) {
      context.senderName = card.sender.name;
    }
    if (card.title) {
      context.subject = `Re: ${card.title}`;
    }

    return context;
  }

  /**
   * Check if action has an external URL in context
   */
  private hasExternalUrl(actionId: string, context: Record<string, string>): boolean {
    const urlKeys = URL_MAPPINGS[actionId] || ['url'];
    return urlKeys.some((key) => context[key] && context[key].startsWith('http'));
  }

  /**
   * Get URL for a GO_TO action
   */
  private getUrlForAction(
    actionId: string,
    context: Record<string, string>
  ): string | undefined {
    const urlKeys = URL_MAPPINGS[actionId] || ['url'];

    for (const key of urlKeys) {
      if (context[key]) {
        return context[key];
      }
    }

    // Generate tracking URL if we have tracking info
    if (actionId === 'track_package') {
      return this.generateTrackingUrl(context);
    }

    return undefined;
  }

  /**
   * Generate tracking URL based on carrier and tracking number
   */
  private generateTrackingUrl(context: Record<string, string>): string | undefined {
    const trackingNumber = context.trackingNumber;
    if (!trackingNumber) return undefined;

    const carrier = (context.carrier || '').toLowerCase();

    const carrierUrls: Record<string, string> = {
      ups: `https://www.ups.com/track?tracknum=${trackingNumber}`,
      fedex: `https://www.fedex.com/fedextrack/?tracknumbers=${trackingNumber}`,
      usps: `https://tools.usps.com/go/TrackConfirmAction?tLabels=${trackingNumber}`,
      dhl: `https://www.dhl.com/en/express/tracking.html?AWB=${trackingNumber}`,
      amazon: `https://www.amazon.com/progress-tracker/package?itemId=${trackingNumber}`,
    };

    for (const [key, urlTemplate] of Object.entries(carrierUrls)) {
      if (carrier.includes(key)) {
        return urlTemplate;
      }
    }

    // Generic tracking search
    return `https://www.google.com/search?q=track+${encodeURIComponent(trackingNumber)}`;
  }

  /**
   * Get all available actions (for gallery)
   */
  getAllActions(): ActionConfig[] {
    return ACTION_CONFIGS;
  }

  /**
   * Get actions filtered by mode
   */
  getActionsForMode(mode: 'mail' | 'ads'): ActionConfig[] {
    return ACTION_CONFIGS.filter((a) => a.mode === mode || a.mode === 'both');
  }

  /**
   * Get actions filtered by category
   */
  getActionsInCategory(category: string): ActionConfig[] {
    return ACTION_CONFIGS.filter((a) => a.category === category);
  }
}

export const ActionRouter = new ActionRouterService();
