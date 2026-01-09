/**
 * Action Configurations - Single source of truth for all actions
 * Mirrors iOS ActionRegistry.swift
 */

export type ActionType = 'GO_TO' | 'IN_APP';
export type ActionMode = 'mail' | 'ads' | 'both';
export type ActionPriority = 'critical' | 'veryHigh' | 'high' | 'mediumHigh' | 'medium' | 'mediumLow' | 'low' | 'veryLow';
export type ActionPermission = 'free' | 'premium' | 'beta' | 'admin';

export interface ActionConfig {
  actionId: string;
  displayName: string;
  actionType: ActionType;
  mode: ActionMode;
  modalComponent: string;
  icon: string;
  iconColor: string;
  requiredContextKeys: string[];
  optionalContextKeys: string[];
  priority: ActionPriority;
  permission: ActionPermission;
  description: string;
  category: string;
}

// Priority values for sorting
export const PRIORITY_VALUES: Record<ActionPriority, number> = {
  critical: 95,
  veryHigh: 90,
  high: 85,
  mediumHigh: 80,
  medium: 75,
  mediumLow: 70,
  low: 65,
  veryLow: 60,
};

/**
 * All 46+ Action Configurations
 * Organized by category matching iOS ActionModules/
 */
export const ACTION_CONFIGS: ActionConfig[] = [
  // ============================================
  // SHIPPING & DELIVERY
  // ============================================
  {
    actionId: 'track_package',
    displayName: 'Track Package',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'TrackPackageModal',
    icon: 'cube-outline',
    iconColor: '#3b82f6',
    requiredContextKeys: ['trackingNumber', 'carrier'],
    optionalContextKeys: ['url', 'expectedDelivery', 'currentStatus'],
    priority: 'veryHigh',
    permission: 'premium',
    description: 'Track package delivery status with carrier details',
    category: 'Shipping',
  },
  {
    actionId: 'schedule_delivery_time',
    displayName: 'Schedule Delivery',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'ScheduleDeliveryTimeModal',
    icon: 'time-outline',
    iconColor: '#22c55e',
    requiredContextKeys: [],
    optionalContextKeys: ['trackingNumber', 'carrier', 'availableSlots'],
    priority: 'high',
    permission: 'free',
    description: 'Choose preferred delivery time window',
    category: 'Shipping',
  },
  {
    actionId: 'view_pickup_details',
    displayName: 'View Pickup Details',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'PickupDetailsModal',
    icon: 'location-outline',
    iconColor: '#8b5cf6',
    requiredContextKeys: ['pharmacy'],
    optionalContextKeys: ['rxNumber', 'address', 'phone', 'hours'],
    priority: 'mediumHigh',
    permission: 'free',
    description: 'View prescription or package pickup details',
    category: 'Shipping',
  },
  {
    actionId: 'contact_driver',
    displayName: 'Contact Driver',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'ContactDriverModal',
    icon: 'car-outline',
    iconColor: '#f59e0b',
    requiredContextKeys: [],
    optionalContextKeys: ['driverName', 'driverPhone', 'vehicleInfo', 'eta'],
    priority: 'high',
    permission: 'free',
    description: 'Contact delivery driver',
    category: 'Shipping',
  },

  // ============================================
  // FINANCIAL
  // ============================================
  {
    actionId: 'pay_invoice',
    displayName: 'Pay Invoice',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'PayInvoiceModal',
    icon: 'card-outline',
    iconColor: '#22c55e',
    requiredContextKeys: ['invoiceId', 'amount', 'merchant'],
    optionalContextKeys: ['paymentLink', 'dueDate', 'description'],
    priority: 'critical',
    permission: 'premium',
    description: 'Pay invoice with amount and merchant details',
    category: 'Financial',
  },
  {
    actionId: 'update_payment',
    displayName: 'Update Payment',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'UpdatePaymentModal',
    icon: 'card-outline',
    iconColor: '#ef4444',
    requiredContextKeys: [],
    optionalContextKeys: ['paymentUrl', 'lastFour', 'expiration'],
    priority: 'high',
    permission: 'free',
    description: 'Update payment method on file',
    category: 'Financial',
  },
  {
    actionId: 'cancel_subscription',
    displayName: 'Cancel Subscription',
    actionType: 'IN_APP',
    mode: 'ads',
    modalComponent: 'CancelSubscriptionModal',
    icon: 'close-circle-outline',
    iconColor: '#ef4444',
    requiredContextKeys: [],
    optionalContextKeys: ['serviceName', 'cancellationUrl', 'renewalDate'],
    priority: 'high',
    permission: 'free',
    description: 'Cancel subscription service',
    category: 'Financial',
  },
  {
    actionId: 'schedule_purchase',
    displayName: 'Schedule Purchase',
    actionType: 'IN_APP',
    mode: 'ads',
    modalComponent: 'ScheduledPurchaseModal',
    icon: 'calendar-outline',
    iconColor: '#8b5cf6',
    requiredContextKeys: [],
    optionalContextKeys: ['productName', 'price', 'purchaseDate'],
    priority: 'mediumHigh',
    permission: 'premium',
    description: 'Schedule future purchase with reminder',
    category: 'Financial',
  },

  // ============================================
  // TRAVEL
  // ============================================
  {
    actionId: 'check_in_flight',
    displayName: 'Check In',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'CheckInFlightModal',
    icon: 'airplane-outline',
    iconColor: '#3b82f6',
    requiredContextKeys: ['flightNumber', 'airline'],
    optionalContextKeys: ['checkInUrl', 'departureTime', 'gate', 'seat'],
    priority: 'critical',
    permission: 'premium',
    description: 'Check in for flight with airline details',
    category: 'Travel',
  },
  {
    actionId: 'view_itinerary',
    displayName: 'View Itinerary',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'ViewItineraryModal',
    icon: 'map-outline',
    iconColor: '#0ea5e9',
    requiredContextKeys: [],
    optionalContextKeys: ['itineraryUrl', 'destination', 'dates'],
    priority: 'mediumHigh',
    permission: 'free',
    description: 'View travel itinerary details',
    category: 'Travel',
  },
  {
    actionId: 'view_reservation',
    displayName: 'View Reservation',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'ReservationModal',
    icon: 'restaurant-outline',
    iconColor: '#f59e0b',
    requiredContextKeys: [],
    optionalContextKeys: ['reservationNumber', 'venue', 'date', 'time', 'partySize'],
    priority: 'medium',
    permission: 'free',
    description: 'View reservation details',
    category: 'Travel',
  },

  // ============================================
  // CALENDAR & SCHEDULING
  // ============================================
  {
    actionId: 'add_to_calendar',
    displayName: 'Add to Calendar',
    actionType: 'IN_APP',
    mode: 'mail',
    modalComponent: 'AddToCalendarModal',
    icon: 'calendar-outline',
    iconColor: '#3b82f6',
    requiredContextKeys: [],
    optionalContextKeys: ['eventTitle', 'eventDate', 'eventTime', 'location'],
    priority: 'mediumHigh',
    permission: 'free',
    description: 'Add event to iOS Calendar',
    category: 'Calendar',
  },
  {
    actionId: 'schedule_meeting',
    displayName: 'Schedule Meeting',
    actionType: 'IN_APP',
    mode: 'mail',
    modalComponent: 'ScheduleMeetingModal',
    icon: 'people-outline',
    iconColor: '#8b5cf6',
    requiredContextKeys: [],
    optionalContextKeys: ['meetingTitle', 'attendees', 'duration'],
    priority: 'medium',
    permission: 'free',
    description: 'Schedule meeting with attendees',
    category: 'Calendar',
  },
  {
    actionId: 'rsvp_yes',
    displayName: 'Accept Invitation',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'RSVPModal',
    icon: 'checkmark-circle-outline',
    iconColor: '#22c55e',
    requiredContextKeys: [],
    optionalContextKeys: ['eventTitle', 'eventDate', 'host'],
    priority: 'veryHigh',
    permission: 'free',
    description: 'Accept event invitation',
    category: 'Calendar',
  },
  {
    actionId: 'rsvp_no',
    displayName: 'Decline Invitation',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'RSVPModal',
    icon: 'close-circle-outline',
    iconColor: '#ef4444',
    requiredContextKeys: [],
    optionalContextKeys: ['eventTitle', 'eventDate', 'host'],
    priority: 'medium',
    permission: 'free',
    description: 'Decline event invitation',
    category: 'Calendar',
  },

  // ============================================
  // DOCUMENTS
  // ============================================
  {
    actionId: 'view_document',
    displayName: 'View Document',
    actionType: 'IN_APP',
    mode: 'mail',
    modalComponent: 'DocumentViewerModal',
    icon: 'document-outline',
    iconColor: '#64748b',
    requiredContextKeys: [],
    optionalContextKeys: ['documentUrl', 'documentName', 'documentType'],
    priority: 'medium',
    permission: 'free',
    description: 'View attached document',
    category: 'Documents',
  },
  {
    actionId: 'document_preview',
    displayName: 'Preview Document',
    actionType: 'IN_APP',
    mode: 'mail',
    modalComponent: 'DocumentPreviewModal',
    icon: 'eye-outline',
    iconColor: '#6366f1',
    requiredContextKeys: [],
    optionalContextKeys: ['documentUrl', 'documentName'],
    priority: 'mediumLow',
    permission: 'free',
    description: 'Quick preview of document',
    category: 'Documents',
  },
  {
    actionId: 'sign_form',
    displayName: 'Sign Form',
    actionType: 'IN_APP',
    mode: 'mail',
    modalComponent: 'SignFormModal',
    icon: 'create-outline',
    iconColor: '#22c55e',
    requiredContextKeys: [],
    optionalContextKeys: ['formUrl', 'documentName', 'deadline'],
    priority: 'critical',
    permission: 'premium',
    description: 'Digitally sign form or document',
    category: 'Documents',
  },
  {
    actionId: 'view_spreadsheet',
    displayName: 'View Spreadsheet',
    actionType: 'IN_APP',
    mode: 'mail',
    modalComponent: 'SpreadsheetViewerModal',
    icon: 'grid-outline',
    iconColor: '#22c55e',
    requiredContextKeys: [],
    optionalContextKeys: ['spreadsheetUrl', 'sheetName'],
    priority: 'mediumLow',
    permission: 'free',
    description: 'View spreadsheet or budget document',
    category: 'Documents',
  },
  {
    actionId: 'view_attachment',
    displayName: 'View Attachment',
    actionType: 'IN_APP',
    mode: 'mail',
    modalComponent: 'AttachmentViewerModal',
    icon: 'attach-outline',
    iconColor: '#64748b',
    requiredContextKeys: [],
    optionalContextKeys: ['attachmentUrl', 'fileName', 'fileType'],
    priority: 'medium',
    permission: 'free',
    description: 'View email attachment',
    category: 'Documents',
  },

  // ============================================
  // COMMUNICATION
  // ============================================
  {
    actionId: 'quick_reply',
    displayName: 'Quick Reply',
    actionType: 'IN_APP',
    mode: 'mail',
    modalComponent: 'QuickReplyModal',
    icon: 'chatbubble-outline',
    iconColor: '#3b82f6',
    requiredContextKeys: ['recipientEmail', 'subject'],
    optionalContextKeys: ['body', 'template'],
    priority: 'high',
    permission: 'free',
    description: 'Send quick reply to email',
    category: 'Communication',
  },
  {
    actionId: 'reply',
    displayName: 'Reply',
    actionType: 'IN_APP',
    mode: 'mail',
    modalComponent: 'QuickReplyModal',
    icon: 'return-down-back-outline',
    iconColor: '#3b82f6',
    requiredContextKeys: ['recipientEmail', 'subject'],
    optionalContextKeys: ['body'],
    priority: 'mediumHigh',
    permission: 'free',
    description: 'Reply to email',
    category: 'Communication',
  },
  {
    actionId: 'send_message',
    displayName: 'Send Message',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'SendMessageModal',
    icon: 'chatbubble-ellipses-outline',
    iconColor: '#22c55e',
    requiredContextKeys: [],
    optionalContextKeys: ['phoneNumber', 'message'],
    priority: 'medium',
    permission: 'free',
    description: 'Send SMS/iMessage',
    category: 'Communication',
  },
  {
    actionId: 'save_contact',
    displayName: 'Save Contact',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'SaveContactModal',
    icon: 'person-add-outline',
    iconColor: '#8b5cf6',
    requiredContextKeys: [],
    optionalContextKeys: ['name', 'email', 'phone', 'company'],
    priority: 'mediumLow',
    permission: 'free',
    description: 'Save contact to iOS Contacts',
    category: 'Communication',
  },

  // ============================================
  // SHOPPING
  // ============================================
  {
    actionId: 'browse_shopping',
    displayName: 'Browse Shopping',
    actionType: 'IN_APP',
    mode: 'ads',
    modalComponent: 'BrowseShoppingModal',
    icon: 'cart-outline',
    iconColor: '#f59e0b',
    requiredContextKeys: [],
    optionalContextKeys: ['productUrl', 'category', 'query'],
    priority: 'medium',
    permission: 'free',
    description: 'Browse shopping products',
    category: 'Shopping',
  },
  {
    actionId: 'shopping_purchase',
    displayName: 'Purchase',
    actionType: 'IN_APP',
    mode: 'ads',
    modalComponent: 'ShoppingPurchaseModal',
    icon: 'bag-check-outline',
    iconColor: '#22c55e',
    requiredContextKeys: ['productUrl'],
    optionalContextKeys: ['productName', 'price', 'promoCode'],
    priority: 'high',
    permission: 'free',
    description: 'Complete purchase',
    category: 'Shopping',
  },
  {
    actionId: 'claim_deal',
    displayName: 'Claim Deal',
    actionType: 'IN_APP',
    mode: 'ads',
    modalComponent: 'ShoppingAutomationModal',
    icon: 'pricetag-outline',
    iconColor: '#ef4444',
    requiredContextKeys: ['productUrl'],
    optionalContextKeys: ['productName', 'dealUrl', 'promoCode'],
    priority: 'mediumHigh',
    permission: 'premium',
    description: 'AI agent adds product to cart automatically',
    category: 'Shopping',
  },
  {
    actionId: 'write_review',
    displayName: 'Write Review',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'WriteReviewModal',
    icon: 'star-outline',
    iconColor: '#f59e0b',
    requiredContextKeys: ['productName'],
    optionalContextKeys: ['reviewLink', 'orderNumber', 'productImage'],
    priority: 'mediumLow',
    permission: 'free',
    description: 'Write product review',
    category: 'Shopping',
  },

  // ============================================
  // ACCOUNT & SECURITY
  // ============================================
  {
    actionId: 'verify_account',
    displayName: 'Verify Account',
    actionType: 'IN_APP',
    mode: 'mail',
    modalComponent: 'AccountVerificationModal',
    icon: 'shield-checkmark-outline',
    iconColor: '#22c55e',
    requiredContextKeys: [],
    optionalContextKeys: ['verificationLink', 'accountType'],
    priority: 'veryHigh',
    permission: 'free',
    description: 'Verify email or account',
    category: 'Account',
  },
  {
    actionId: 'review_security',
    displayName: 'Review Security',
    actionType: 'IN_APP',
    mode: 'mail',
    modalComponent: 'ReviewSecurityModal',
    icon: 'shield-outline',
    iconColor: '#ef4444',
    requiredContextKeys: [],
    optionalContextKeys: ['securityUrl', 'alertType', 'device'],
    priority: 'veryHigh',
    permission: 'free',
    description: 'Review security settings or alert',
    category: 'Account',
  },
  {
    actionId: 'provide_access_code',
    displayName: 'Provide Access Code',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'ProvideAccessCodeModal',
    icon: 'key-outline',
    iconColor: '#8b5cf6',
    requiredContextKeys: ['trackingNumber'],
    optionalContextKeys: ['deliveryDate', 'instructions'],
    priority: 'medium',
    permission: 'free',
    description: 'Provide building or gate access code for delivery',
    category: 'Account',
  },

  // ============================================
  // UTILITIES
  // ============================================
  {
    actionId: 'unsubscribe',
    displayName: 'Unsubscribe',
    actionType: 'IN_APP',
    mode: 'ads',
    modalComponent: 'UnsubscribeModal',
    icon: 'mail-unread-outline',
    iconColor: '#ef4444',
    requiredContextKeys: [],
    optionalContextKeys: ['unsubscribeUrl', 'senderName'],
    priority: 'high',
    permission: 'premium',
    description: 'Unsubscribe from mailing list',
    category: 'Utilities',
  },
  {
    actionId: 'add_reminder',
    displayName: 'Add Reminder',
    actionType: 'IN_APP',
    mode: 'mail',
    modalComponent: 'AddReminderModal',
    icon: 'alarm-outline',
    iconColor: '#f59e0b',
    requiredContextKeys: [],
    optionalContextKeys: ['reminderTitle', 'dueDate', 'notes'],
    priority: 'mediumLow',
    permission: 'free',
    description: 'Add reminder to iOS Reminders',
    category: 'Utilities',
  },
  {
    actionId: 'add_to_notes',
    displayName: 'Add to Notes',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'AddToNotesModal',
    icon: 'document-text-outline',
    iconColor: '#f59e0b',
    requiredContextKeys: [],
    optionalContextKeys: ['noteContent', 'folder'],
    priority: 'veryHigh',
    permission: 'free',
    description: 'Save email content to iOS Notes app',
    category: 'Utilities',
  },
  {
    actionId: 'add_to_wallet',
    displayName: 'Add to Wallet',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'AddToWalletModal',
    icon: 'wallet-outline',
    iconColor: '#000000',
    requiredContextKeys: [],
    optionalContextKeys: ['passUrl', 'passType'],
    priority: 'high',
    permission: 'free',
    description: 'Add pass to Apple Wallet',
    category: 'Utilities',
  },
  {
    actionId: 'share',
    displayName: 'Share',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'ShareModal',
    icon: 'share-outline',
    iconColor: '#3b82f6',
    requiredContextKeys: ['content'],
    optionalContextKeys: [],
    priority: 'low',
    permission: 'free',
    description: 'Share via iOS share sheet',
    category: 'Utilities',
  },
  {
    actionId: 'snooze',
    displayName: 'Snooze',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'SnoozeModal',
    icon: 'time-outline',
    iconColor: '#f59e0b',
    requiredContextKeys: [],
    optionalContextKeys: ['snoozeUntil'],
    priority: 'medium',
    permission: 'free',
    description: 'Snooze email for later',
    category: 'Utilities',
  },

  // ============================================
  // CONTENT & NEWS
  // ============================================
  {
    actionId: 'view_newsletter_summary',
    displayName: 'View Summary',
    actionType: 'IN_APP',
    mode: 'ads',
    modalComponent: 'NewsletterSummaryModal',
    icon: 'newspaper-outline',
    iconColor: '#8b5cf6',
    requiredContextKeys: [],
    optionalContextKeys: ['summaryText', 'topLinks'],
    priority: 'mediumLow',
    permission: 'premium',
    description: 'View AI-generated newsletter summary',
    category: 'Content',
  },
  {
    actionId: 'read_community_post',
    displayName: 'Read Post',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'ReadCommunityPostModal',
    icon: 'chatbubbles-outline',
    iconColor: '#3b82f6',
    requiredContextKeys: [],
    optionalContextKeys: ['postUrl', 'postTitle'],
    priority: 'veryHigh',
    permission: 'free',
    description: 'Read community post',
    category: 'Content',
  },
  {
    actionId: 'view_post_comments',
    displayName: 'View Comments',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'ViewPostCommentsModal',
    icon: 'chatbubble-outline',
    iconColor: '#6366f1',
    requiredContextKeys: [],
    optionalContextKeys: ['postUrl', 'commentCount'],
    priority: 'high',
    permission: 'free',
    description: 'Read post comments and discussion',
    category: 'Content',
  },
  {
    actionId: 'view_details',
    displayName: 'View Details',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'ViewDetailsModal',
    icon: 'information-circle-outline',
    iconColor: '#64748b',
    requiredContextKeys: [],
    optionalContextKeys: [],
    priority: 'veryLow',
    permission: 'free',
    description: 'View email details (fallback)',
    category: 'Content',
  },
  {
    actionId: 'view_activity',
    displayName: 'View Activity',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'ViewActivityModal',
    icon: 'pulse-outline',
    iconColor: '#22c55e',
    requiredContextKeys: [],
    optionalContextKeys: ['activityUrl', 'activityType'],
    priority: 'low',
    permission: 'free',
    description: 'View fitness or social activity',
    category: 'Content',
  },
  {
    actionId: 'view_activity_details',
    displayName: 'Activity Details',
    actionType: 'IN_APP',
    mode: 'mail',
    modalComponent: 'ViewActivityDetailsModal',
    icon: 'list-outline',
    iconColor: '#3b82f6',
    requiredContextKeys: [],
    optionalContextKeys: ['activityUrl', 'date', 'duration'],
    priority: 'veryHigh',
    permission: 'free',
    description: 'View detailed activity information',
    category: 'Content',
  },

  // ============================================
  // INFRASTRUCTURE
  // ============================================
  {
    actionId: 'prepare_for_outage',
    displayName: 'View Preparation Tips',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'PrepareForOutageModal',
    icon: 'flash-off-outline',
    iconColor: '#f59e0b',
    requiredContextKeys: [],
    optionalContextKeys: ['outageStart', 'outageEnd', 'affectedArea'],
    priority: 'high',
    permission: 'free',
    description: 'View tips to prepare for power outage',
    category: 'Infrastructure',
  },
  {
    actionId: 'view_outage_details',
    displayName: 'View Outage Info',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'ViewOutageDetailsModal',
    icon: 'warning-outline',
    iconColor: '#ef4444',
    requiredContextKeys: [],
    optionalContextKeys: ['outageStart', 'outageEnd', 'reason'],
    priority: 'veryHigh',
    permission: 'free',
    description: 'View power outage details and affected areas',
    category: 'Infrastructure',
  },
  {
    actionId: 'open_app',
    displayName: 'Open App',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'OpenAppModal',
    icon: 'apps-outline',
    iconColor: '#64748b',
    requiredContextKeys: [],
    optionalContextKeys: ['appUrl', 'appName'],
    priority: 'mediumLow',
    permission: 'free',
    description: 'Open external app',
    category: 'Infrastructure',
  },

  // ============================================
  // QUICK ACTIONS (no modal needed)
  // ============================================
  {
    actionId: 'archive',
    displayName: 'Archive',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'ConfirmationModal',
    icon: 'archive-outline',
    iconColor: '#667eea',
    requiredContextKeys: [],
    optionalContextKeys: [],
    priority: 'medium',
    permission: 'free',
    description: 'Archive email',
    category: 'Quick',
  },
  {
    actionId: 'delete',
    displayName: 'Delete',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'ConfirmationModal',
    icon: 'trash-outline',
    iconColor: '#ef4444',
    requiredContextKeys: [],
    optionalContextKeys: [],
    priority: 'medium',
    permission: 'free',
    description: 'Delete email',
    category: 'Quick',
  },
  {
    actionId: 'acknowledge',
    displayName: 'Acknowledge',
    actionType: 'IN_APP',
    mode: 'mail',
    modalComponent: 'ConfirmationModal',
    icon: 'checkmark-outline',
    iconColor: '#22c55e',
    requiredContextKeys: ['recipientEmail', 'subject'],
    optionalContextKeys: [],
    priority: 'low',
    permission: 'free',
    description: 'Send acknowledgment reply',
    category: 'Quick',
  },
  {
    actionId: 'save_for_later',
    displayName: 'Save for Later',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'ConfirmationModal',
    icon: 'bookmark-outline',
    iconColor: '#22c55e',
    requiredContextKeys: [],
    optionalContextKeys: ['folderId', 'reminderTime'],
    priority: 'mediumLow',
    permission: 'free',
    description: 'Save email to folder or set reminder',
    category: 'Quick',
  },
  {
    actionId: 'mark_unread',
    displayName: 'Mark Unread',
    actionType: 'IN_APP',
    mode: 'both',
    modalComponent: 'ConfirmationModal',
    icon: 'mail-unread-outline',
    iconColor: '#3b82f6',
    requiredContextKeys: [],
    optionalContextKeys: [],
    priority: 'low',
    permission: 'free',
    description: 'Mark email as unread',
    category: 'Quick',
  },
];

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Get action config by ID
 */
export function getActionConfig(actionId: string): ActionConfig | undefined {
  return ACTION_CONFIGS.find((a) => a.actionId === actionId);
}

/**
 * Get all actions for a mode
 */
export function getActionsForMode(mode: 'mail' | 'ads'): ActionConfig[] {
  return ACTION_CONFIGS.filter((a) => a.mode === mode || a.mode === 'both');
}

/**
 * Get all actions in a category
 */
export function getActionsInCategory(category: string): ActionConfig[] {
  return ACTION_CONFIGS.filter((a) => a.category === category);
}

/**
 * Get all unique categories
 */
export function getAllCategories(): string[] {
  return [...new Set(ACTION_CONFIGS.map((a) => a.category))];
}

/**
 * Get action count by category
 */
export function getActionCountByCategory(): Record<string, number> {
  const counts: Record<string, number> = {};
  ACTION_CONFIGS.forEach((a) => {
    counts[a.category] = (counts[a.category] || 0) + 1;
  });
  return counts;
}

/**
 * Get premium actions only
 */
export function getPremiumActions(): ActionConfig[] {
  return ACTION_CONFIGS.filter((a) => a.permission === 'premium');
}

/**
 * Sort actions by priority
 */
export function sortByPriority(actions: ActionConfig[]): ActionConfig[] {
  return [...actions].sort(
    (a, b) => PRIORITY_VALUES[b.priority] - PRIORITY_VALUES[a.priority]
  );
}

/**
 * Get registry statistics
 */
export function getRegistryStatistics() {
  const total = ACTION_CONFIGS.length;
  const goTo = ACTION_CONFIGS.filter((a) => a.actionType === 'GO_TO').length;
  const inApp = ACTION_CONFIGS.filter((a) => a.actionType === 'IN_APP').length;
  const mail = ACTION_CONFIGS.filter((a) => a.mode === 'mail').length;
  const ads = ACTION_CONFIGS.filter((a) => a.mode === 'ads').length;
  const both = ACTION_CONFIGS.filter((a) => a.mode === 'both').length;
  const premium = ACTION_CONFIGS.filter((a) => a.permission === 'premium').length;

  return {
    total,
    goTo,
    inApp,
    mail,
    ads,
    both,
    premium,
    categories: getAllCategories().length,
  };
}
