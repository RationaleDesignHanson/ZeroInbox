/**
 * PayInvoiceModal - Premium modal for invoice payment
 * Displays invoice details and payment options
 */

import React, { useState } from 'react';
import { View, Text, StyleSheet, Linking, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';
import {
  BaseActionModal,
  ModalSection,
  InfoRow,
  CopyableField,
  ActionButton,
} from './BaseActionModal';

interface PayInvoiceModalProps {
  visible: boolean;
  onClose: () => void;
  card: EmailCard;
  action: SuggestedAction;
}

const PAYMENT_METHODS = [
  { id: 'apple_pay', name: 'Apple Pay', icon: 'logo-apple' },
  { id: 'card', name: 'Credit Card', icon: 'card-outline' },
  { id: 'bank', name: 'Bank Account', icon: 'business-outline' },
];

export function PayInvoiceModal({ visible, onClose, card, action }: PayInvoiceModalProps) {
  const [selectedMethod, setSelectedMethod] = useState('apple_pay');
  const [isProcessing, setIsProcessing] = useState(false);

  // Extract context
  const context = action.context || {};
  const invoiceId = context.invoiceId || 'N/A';
  const amount = context.amount || context.amountDue || '$0.00';
  const merchant = context.merchant || card.sender?.name || 'Merchant';
  const dueDate = context.dueDate || '';
  const lateFee = context.lateFee || '';
  const paymentLink = context.paymentLink || context.url || '';

  const handlePayNow = async () => {
    HapticService.mediumImpact();
    
    if (paymentLink) {
      // Open external payment link
      await Linking.openURL(paymentLink);
      onClose();
    } else {
      // Simulate payment processing
      setIsProcessing(true);
      
      setTimeout(() => {
        setIsProcessing(false);
        HapticService.success();
        Alert.alert(
          'Payment Initiated',
          `Your payment of ${amount} to ${merchant} has been initiated.`,
          [{ text: 'OK', onPress: onClose }]
        );
      }, 2000);
    }
  };

  const handleViewInvoice = async () => {
    HapticService.lightImpact();
    if (context.invoiceUrl) {
      await Linking.openURL(context.invoiceUrl);
    }
  };

  return (
    <BaseActionModal
      visible={visible}
      onClose={onClose}
      card={card}
      action={action}
      title="Pay Invoice"
      icon="card-outline"
      iconColor="#22c55e"
      gradientColors={['#22c55e', '#059669']}
      footer={
        <>
          <ActionButton
            title={`Pay ${amount}`}
            icon="checkmark-circle-outline"
            onPress={handlePayNow}
            loading={isProcessing}
          />
          {context.invoiceUrl && (
            <ActionButton
              title="View Invoice PDF"
              icon="document-text-outline"
              onPress={handleViewInvoice}
              variant="secondary"
            />
          )}
        </>
      }
    >
      {/* Amount Display */}
      <View style={styles.amountContainer}>
        <Text style={styles.amountLabel}>Amount Due</Text>
        <Text style={styles.amountValue}>{amount}</Text>
        <Text style={styles.merchantName}>{merchant}</Text>
      </View>

      {/* Invoice Details */}
      <ModalSection title="INVOICE DETAILS">
        <CopyableField
          label="Invoice ID"
          value={invoiceId}
          icon="document-outline"
          iconColor="#3b82f6"
        />

        {dueDate && (
          <InfoRow
            icon="calendar-outline"
            iconColor="#f59e0b"
            label="Due Date"
            value={dueDate}
          />
        )}

        {lateFee && (
          <InfoRow
            icon="warning-outline"
            iconColor="#ef4444"
            label="Late Fee"
            value={lateFee}
          />
        )}
      </ModalSection>

      {/* Payment Method */}
      <ModalSection title="PAYMENT METHOD">
        {PAYMENT_METHODS.map((method) => (
          <View
            key={method.id}
            style={[
              styles.paymentMethod,
              selectedMethod === method.id && styles.paymentMethodSelected,
            ]}
          >
            <View style={styles.methodIcon}>
              <Ionicons
                name={method.icon as keyof typeof Ionicons.glyphMap}
                size={22}
                color={selectedMethod === method.id ? '#22c55e' : 'rgba(255,255,255,0.6)'}
              />
            </View>
            <Text
              style={[
                styles.methodName,
                selectedMethod === method.id && styles.methodNameSelected,
              ]}
            >
              {method.name}
            </Text>
            {selectedMethod === method.id ? (
              <Ionicons name="checkmark-circle" size={22} color="#22c55e" />
            ) : (
              <Ionicons name="ellipse-outline" size={22} color="rgba(255,255,255,0.3)" />
            )}
          </View>
        ))}
      </ModalSection>

      {/* Security Note */}
      <View style={styles.securityNote}>
        <Ionicons name="shield-checkmark-outline" size={16} color="rgba(255,255,255,0.5)" />
        <Text style={styles.securityText}>
          Your payment info is encrypted and secure
        </Text>
      </View>
    </BaseActionModal>
  );
}

const styles = StyleSheet.create({
  amountContainer: {
    alignItems: 'center',
    backgroundColor: 'rgba(34, 197, 94, 0.1)',
    borderRadius: 16,
    padding: 24,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: 'rgba(34, 197, 94, 0.2)',
  },
  amountLabel: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.5)',
    marginBottom: 4,
  },
  amountValue: {
    fontSize: 40,
    fontWeight: '700',
    color: '#22c55e',
    marginBottom: 4,
  },
  merchantName: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.7)',
  },
  paymentMethod: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 12,
    borderRadius: 12,
    marginBottom: 8,
    backgroundColor: 'rgba(255,255,255,0.05)',
  },
  paymentMethodSelected: {
    backgroundColor: 'rgba(34, 197, 94, 0.15)',
    borderWidth: 1,
    borderColor: 'rgba(34, 197, 94, 0.3)',
  },
  methodIcon: {
    width: 36,
    height: 36,
    borderRadius: 10,
    backgroundColor: 'rgba(255,255,255,0.1)',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  methodName: {
    flex: 1,
    fontSize: 15,
    fontWeight: '500',
    color: 'rgba(255,255,255,0.8)',
  },
  methodNameSelected: {
    color: 'white',
  },
  securityNote: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    marginTop: 8,
  },
  securityText: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.5)',
  },
});
