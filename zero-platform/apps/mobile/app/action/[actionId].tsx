/**
 * Action Modal Route - Dynamic action modal based on actionId
 * Accessed via /action/{actionId}?emailId={emailId}&context={json}
 * Routes to the appropriate modal from the 46+ action modal library
 */

import React, { useMemo, useCallback } from 'react';
import { View, StyleSheet } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { MOCK_MAIL_EMAILS, MOCK_ADS_EMAILS } from '../../data/mockEmails';

// Import all modals
import {
  TrackPackageModal,
  PayInvoiceModal,
  CheckInFlightModal,
  RSVPModal,
  AddToCalendarModal,
  SaveContactModal,
  WriteReviewModal,
  UnsubscribeModal,
  ShareModal,
  SnoozeModal,
  NewsletterSummaryModal,
  ViewDetailsModal,
  GenericActionModal,
  EmailComposerModal,
  ConfirmationModal,
  getModalForAction,
} from '../../components/modals';

// Mock card for when we can't find the email
const FALLBACK_CARD: EmailCard = {
  id: 'fallback',
  title: 'Email',
  summary: '',
  sender: { name: 'Unknown', email: 'unknown@email.com' },
  receivedAt: new Date().toISOString(),
  type: 'mail',
  priority: 'normal',
  suggestedActions: [],
};

export default function ActionModalScreen() {
  const { actionId, emailId, context: contextParam } = useLocalSearchParams<{
    actionId: string;
    emailId: string;
    context?: string;
  }>();
  const router = useRouter();

  // Parse context from URL params
  const context = useMemo(() => {
    if (!contextParam) return {};
    try {
      return JSON.parse(decodeURIComponent(contextParam));
    } catch {
      return {};
    }
  }, [contextParam]);

  // Find the email card
  const card = useMemo(() => {
    if (!emailId) return FALLBACK_CARD;
    
    const allEmails = [...MOCK_MAIL_EMAILS, ...MOCK_ADS_EMAILS];
    return allEmails.find((e) => e.id === emailId) || {
      ...FALLBACK_CARD,
      id: emailId,
      title: context.subject || 'Email',
      sender: {
        name: context.senderName || 'Unknown',
        email: context.senderEmail || 'unknown@email.com',
      },
    };
  }, [emailId, context]);

  // Create action object
  const action: SuggestedAction = useMemo(() => ({
    id: actionId || 'view_details',
    displayName: getActionDisplayName(actionId || 'view_details'),
    type: actionId as any,
    context,
  }), [actionId, context]);

  const handleClose = useCallback(() => {
    router.back();
  }, [router]);

  const handleSuccess = useCallback(() => {
    console.log('Action completed:', actionId);
    router.back();
  }, [actionId, router]);

  // If missing required params, go back
  if (!actionId) {
    router.back();
    return null;
  }

  // Determine which modal to render
  const modalName = getModalForAction(actionId);
  const commonProps = {
    visible: true,
    onClose: handleClose,
    card,
    action,
  };

  // Render the appropriate modal
  switch (modalName) {
    case 'TrackPackageModal':
      return (
        <View style={styles.container}>
          <TrackPackageModal {...commonProps} />
        </View>
      );

    case 'PayInvoiceModal':
      return (
        <View style={styles.container}>
          <PayInvoiceModal {...commonProps} />
        </View>
      );

    case 'CheckInFlightModal':
      return (
        <View style={styles.container}>
          <CheckInFlightModal {...commonProps} />
        </View>
      );

    case 'RSVPModal':
      return (
        <View style={styles.container}>
          <RSVPModal {...commonProps} />
        </View>
      );

    case 'AddToCalendarModal':
      return (
        <View style={styles.container}>
          <AddToCalendarModal {...commonProps} onAdd={handleSuccess} />
        </View>
      );

    case 'SaveContactModal':
      return (
        <View style={styles.container}>
          <SaveContactModal {...commonProps} />
        </View>
      );

    case 'WriteReviewModal':
      return (
        <View style={styles.container}>
          <WriteReviewModal {...commonProps} />
        </View>
      );

    case 'UnsubscribeModal':
      return (
        <View style={styles.container}>
          <UnsubscribeModal {...commonProps} />
        </View>
      );

    case 'ShareModal':
      return (
        <View style={styles.container}>
          <ShareModal {...commonProps} />
        </View>
      );

    case 'SnoozeModal':
      return (
        <View style={styles.container}>
          <SnoozeModal {...commonProps} onSnooze={handleSuccess} />
        </View>
      );

    case 'NewsletterSummaryModal':
      return (
        <View style={styles.container}>
          <NewsletterSummaryModal {...commonProps} />
        </View>
      );

    case 'ViewDetailsModal':
      return (
        <View style={styles.container}>
          <ViewDetailsModal {...commonProps} />
        </View>
      );

    case 'EmailComposerModal':
      return (
        <View style={styles.container}>
          <EmailComposerModal {...commonProps} onSend={handleSuccess} />
        </View>
      );

    case 'ConfirmationModal':
      return (
        <View style={styles.container}>
          <ConfirmationModal 
            {...commonProps} 
            onConfirm={handleSuccess}
            message={`Confirm ${action.displayName}?`}
          />
        </View>
      );

    case 'GenericActionModal':
    default:
      return (
        <View style={styles.container}>
          <GenericActionModal {...commonProps} onConfirm={handleSuccess} />
        </View>
      );
  }
}

// Get display name for action
function getActionDisplayName(actionId: string): string {
  const displayNames: Record<string, string> = {
    track_package: 'Track Package',
    pay_invoice: 'Pay Invoice',
    check_in_flight: 'Check In',
    rsvp_yes: 'Accept Invitation',
    rsvp_no: 'Decline Invitation',
    add_to_calendar: 'Add to Calendar',
    schedule: 'Schedule',
    save_contact: 'Save Contact',
    write_review: 'Write Review',
    unsubscribe: 'Unsubscribe',
    share: 'Share',
    snooze: 'Snooze',
    view_newsletter_summary: 'View Summary',
    view_details: 'View Details',
    quick_reply: 'Quick Reply',
    reply: 'Reply',
    forward: 'Forward',
    archive: 'Archive',
    delete: 'Delete',
    acknowledge: 'Acknowledge',
  };
  return displayNames[actionId] || actionId.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'transparent',
  },
});
