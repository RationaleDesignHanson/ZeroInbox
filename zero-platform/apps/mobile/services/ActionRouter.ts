/**
 * ActionRouter - Routes and executes actions based on actionId and type
 * Handles both GO_TO (external URLs) and IN_APP (modal) actions
 * Matches iOS ActionRouter.swift implementation
 */

import * as Linking from 'expo-linking';
import * as WebBrowser from 'expo-web-browser';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from './HapticService';

// Action types matching iOS implementation
export type ActionType = 'GO_TO' | 'IN_APP';

// Modal types for IN_APP actions
export type ModalType =
  | 'quick_reply'
  | 'add_to_calendar'
  | 'track_package'
  | 'pay_invoice'
  | 'view_document'
  | 'sign_form'
  | 'check_in_flight'
  | 'write_review'
  | 'snooze'
  | 'save_for_later'
  | 'view_details'
  | 'confirmation'
  | 'share'
  | 'unsubscribe';

// Result of routing an action
export interface ActionRouteResult {
  type: ActionType;
  modalType?: ModalType;
  url?: string;
  context?: Record<string, string>;
}

// Action modal event handler types
export type ActionModalHandler = (
  modalType: ModalType,
  card: EmailCard,
  action: SuggestedAction,
  context?: Record<string, string>
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

// Modal component mappings for IN_APP actions
const MODAL_MAPPINGS: Record<string, ModalType> = {
  reply: 'quick_reply',
  quick_reply: 'quick_reply',
  respond: 'quick_reply',
  acknowledge: 'confirmation',
  confirm_attendance: 'confirmation',
  schedule: 'add_to_calendar',
  add_to_calendar: 'add_to_calendar',
  view_document: 'view_document',
  sign_document: 'sign_form',
  sign_form: 'sign_form',
  track_package: 'track_package',
  pay_invoice: 'pay_invoice',
  check_in_flight: 'check_in_flight',
  write_review: 'write_review',
  snooze: 'snooze',
  save_later: 'save_for_later',
  save_for_later: 'save_for_later',
  archive: 'confirmation',
  share: 'share',
  unsubscribe: 'unsubscribe',
};

// Actions that should always open externally (GO_TO)
const GO_TO_ACTIONS = new Set([
  'track_package',
  'pay_invoice',
  'view_order',
  'check_in_flight',
  'reset_password',
  'verify_account',
  'register_event',
  'view_ticket',
  'join_meeting',
  'download_receipt',
  'claim_deal',
  'view_product',
  'complete_cart',
  'manage_booking',
  'contact_support',
  'open_link',
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
   * Route an action to determine how it should be executed
   */
  routeAction(action: SuggestedAction, card: EmailCard): ActionRouteResult {
    const actionId = action.id.toLowerCase();
    const context = this.extractContext(action, card);

    // Check if this is a GO_TO action
    if (GO_TO_ACTIONS.has(actionId) || this.hasExternalUrl(actionId, context)) {
      const url = this.getUrlForAction(actionId, context);
      return {
        type: 'GO_TO',
        url,
        context,
      };
    }

    // Otherwise it's an IN_APP action
    const modalType = MODAL_MAPPINGS[actionId] || 'view_details';
    return {
      type: 'IN_APP',
      modalType,
      context,
    };
  }

  /**
   * Execute an action (either open URL or show modal)
   */
  async executeAction(
    action: SuggestedAction,
    card: EmailCard
  ): Promise<{ success: boolean; message?: string }> {
    const route = this.routeAction(action, card);

    HapticService.mediumImpact();

    if (route.type === 'GO_TO' && route.url) {
      return this.executeGoToAction(route.url);
    }

    if (route.type === 'IN_APP' && route.modalType) {
      return this.executeInAppAction(route.modalType, card, action, route.context);
    }

    return { success: false, message: 'Unknown action type' };
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
   * Execute an IN_APP action by showing a modal
   */
  private executeInAppAction(
    modalType: ModalType,
    card: EmailCard,
    action: SuggestedAction,
    context?: Record<string, string>
  ): { success: boolean; message?: string } {
    if (!this.modalHandler) {
      console.warn('ActionRouter: No modal handler registered');
      return { success: false, message: 'Modal handler not registered' };
    }

    this.modalHandler(modalType, card, action, context);
    return { success: true };
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
    }
    if (card.sender?.name) {
      context.senderName = card.sender.name;
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
}

export const ActionRouter = new ActionRouterService();

