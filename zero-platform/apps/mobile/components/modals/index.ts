/**
 * Action Modals - Export all 46+ action modals
 * Matches iOS ActionModules/ directory
 */

// Base components
export * from './BaseActionModal';

// Shipping & Delivery
export { TrackPackageModal } from './TrackPackageModal';
// ScheduleDeliveryTimeModal - uses GenericActionModal
// PickupDetailsModal - uses GenericActionModal
// ContactDriverModal - uses GenericActionModal

// Financial
export { PayInvoiceModal } from './PayInvoiceModal';
// UpdatePaymentModal - uses GenericActionModal
// CancelSubscriptionModal - uses GenericActionModal
// ScheduledPurchaseModal - uses GenericActionModal

// Travel
export { CheckInFlightModal } from './CheckInFlightModal';
// ViewItineraryModal - uses GenericActionModal
// ReservationModal - uses GenericActionModal

// Calendar & Scheduling
export { AddToCalendarModal } from './AddToCalendarModal';
export { RSVPModal } from './RSVPModal';
// ScheduleMeetingModal - uses GenericActionModal

// Documents
// DocumentViewerModal - uses existing
// DocumentPreviewModal - uses GenericActionModal
// SignFormModal - uses GenericActionModal
// SpreadsheetViewerModal - uses GenericActionModal
// AttachmentViewerModal - uses GenericActionModal

// Communication
// QuickReplyModal - uses existing EmailComposerModal
// SendMessageModal - uses GenericActionModal
export { SaveContactModal } from './SaveContactModal';

// Shopping
// BrowseShoppingModal - uses GenericActionModal
// ShoppingPurchaseModal - uses GenericActionModal
// ShoppingAutomationModal - uses GenericActionModal
export { WriteReviewModal } from './WriteReviewModal';

// Account & Security
// AccountVerificationModal - uses GenericActionModal
// ReviewSecurityModal - uses GenericActionModal
// ProvideAccessCodeModal - uses GenericActionModal

// Utilities
export { UnsubscribeModal } from './UnsubscribeModal';
// AddReminderModal - uses GenericActionModal
// AddToNotesModal - uses GenericActionModal
// AddToWalletModal - uses GenericActionModal
export { ShareModal } from './ShareModal';
export { SnoozeModal } from './SnoozeModal';

// Content & News
export { NewsletterSummaryModal } from './NewsletterSummaryModal';
// ReadCommunityPostModal - uses GenericActionModal
// ViewPostCommentsModal - uses GenericActionModal
export { ViewDetailsModal } from './ViewDetailsModal';
// ViewActivityModal - uses GenericActionModal
// ViewActivityDetailsModal - uses GenericActionModal

// Infrastructure
// PrepareForOutageModal - uses GenericActionModal
// ViewOutageDetailsModal - uses GenericActionModal
// OpenAppModal - uses GenericActionModal

// Generic fallback for any action
export { GenericActionModal } from './GenericActionModal';

// Re-export existing modals (created earlier)
export { EmailComposerModal } from './EmailComposerModal';
export { CalendarModal } from './CalendarModal';
export { DocumentViewerModal } from './DocumentViewerModal';
export { ConfirmationModal } from './ConfirmationModal';

/**
 * Modal Registry - Maps actionId to modal component
 * Used by ActionRouter to determine which modal to show
 */
export type ModalComponentName =
  | 'TrackPackageModal'
  | 'PayInvoiceModal'
  | 'CheckInFlightModal'
  | 'RSVPModal'
  | 'AddToCalendarModal'
  | 'SaveContactModal'
  | 'WriteReviewModal'
  | 'UnsubscribeModal'
  | 'ShareModal'
  | 'SnoozeModal'
  | 'NewsletterSummaryModal'
  | 'ViewDetailsModal'
  | 'GenericActionModal'
  | 'EmailComposerModal'
  | 'CalendarModal'
  | 'DocumentViewerModal'
  | 'ConfirmationModal';

/**
 * Get the appropriate modal component for an action
 */
export function getModalForAction(actionId: string): ModalComponentName {
  const modalMap: Record<string, ModalComponentName> = {
    // Shipping
    track_package: 'TrackPackageModal',
    
    // Financial
    pay_invoice: 'PayInvoiceModal',
    
    // Travel
    check_in_flight: 'CheckInFlightModal',
    
    // Calendar
    add_to_calendar: 'AddToCalendarModal',
    schedule: 'AddToCalendarModal',
    rsvp_yes: 'RSVPModal',
    rsvp_no: 'RSVPModal',
    
    // Communication
    quick_reply: 'EmailComposerModal',
    reply: 'EmailComposerModal',
    respond: 'EmailComposerModal',
    forward: 'EmailComposerModal',
    save_contact: 'SaveContactModal',
    
    // Shopping
    write_review: 'WriteReviewModal',
    
    // Utilities
    unsubscribe: 'UnsubscribeModal',
    share: 'ShareModal',
    snooze: 'SnoozeModal',
    
    // Content
    view_newsletter_summary: 'NewsletterSummaryModal',
    view_details: 'ViewDetailsModal',
    
    // Documents
    view_document: 'DocumentViewerModal',
    sign_document: 'DocumentViewerModal',
    
    // Confirmations
    archive: 'ConfirmationModal',
    delete: 'ConfirmationModal',
    acknowledge: 'ConfirmationModal',
  };

  return modalMap[actionId.toLowerCase()] || 'GenericActionModal';
}
