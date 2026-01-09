/**
 * TrackPackageModal - Premium modal for package tracking
 * Displays tracking info, timeline, and carrier details
 */

import React, { useState } from 'react';
import { View, Text, StyleSheet, Linking, Share } from 'react-native';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';
import {
  BaseActionModal,
  ModalSection,
  InfoRow,
  CopyableField,
  ActionButton,
  ProgressStep,
} from './BaseActionModal';

interface TrackPackageModalProps {
  visible: boolean;
  onClose: () => void;
  card: EmailCard;
  action: SuggestedAction;
}

export function TrackPackageModal({ visible, onClose, card, action }: TrackPackageModalProps) {
  const [isLoading, setIsLoading] = useState(false);

  // Extract context
  const context = action.context || {};
  const trackingNumber = context.trackingNumber || 'N/A';
  const carrier = context.carrier || 'Carrier';
  const trackingUrl = context.url || context.trackingUrl || '';
  const estimatedDelivery = context.estimatedDelivery || context.deliveryDate || 'Pending';
  const currentStatus = context.deliveryStatus || context.status || 'In Transit';
  const orderNumber = context.orderNumber || '';

  // Carrier branding
  const getCarrierInfo = () => {
    const lowerCarrier = carrier.toLowerCase();
    if (lowerCarrier.includes('ups')) {
      return { icon: 'cube-outline', color: '#6b4226' };
    } else if (lowerCarrier.includes('fedex')) {
      return { icon: 'cube-outline', color: '#8b5cf6' };
    } else if (lowerCarrier.includes('usps')) {
      return { icon: 'mail-outline', color: '#3b82f6' };
    } else if (lowerCarrier.includes('dhl')) {
      return { icon: 'airplane-outline', color: '#f59e0b' };
    } else if (lowerCarrier.includes('amazon')) {
      return { icon: 'cart-outline', color: '#ff9900' };
    }
    return { icon: 'cube-outline', color: '#667eea' };
  };

  const carrierInfo = getCarrierInfo();

  // Determine current step
  const getCurrentStep = () => {
    const status = currentStatus.toLowerCase();
    if (status.includes('delivered')) return 4;
    if (status.includes('out for delivery')) return 3;
    if (status.includes('transit')) return 2;
    if (status.includes('shipped')) return 1;
    return 0;
  };
  const currentStep = getCurrentStep();

  // Generate tracking URL if not provided
  const getTrackingUrl = () => {
    if (trackingUrl) return trackingUrl;

    const lowerCarrier = carrier.toLowerCase();
    if (lowerCarrier.includes('ups')) {
      return `https://www.ups.com/track?tracknum=${trackingNumber}`;
    } else if (lowerCarrier.includes('fedex')) {
      return `https://www.fedex.com/fedextrack/?tracknumbers=${trackingNumber}`;
    } else if (lowerCarrier.includes('usps')) {
      return `https://tools.usps.com/go/TrackConfirmAction?tLabels=${trackingNumber}`;
    }
    return `https://www.google.com/search?q=track+${encodeURIComponent(trackingNumber)}`;
  };

  const handleTrackOnline = async () => {
    HapticService.mediumImpact();
    const url = getTrackingUrl();
    if (url) {
      await Linking.openURL(url);
      onClose();
    }
  };

  const handleShare = async () => {
    HapticService.lightImpact();
    const shareText = `📦 Package Tracking\n\nTracking #: ${trackingNumber}\nCarrier: ${carrier}\nEst. Delivery: ${estimatedDelivery}\n\nTrack: ${getTrackingUrl()}`;

    try {
      await Share.share({ message: shareText });
    } catch (error) {
      console.error('Share failed:', error);
    }
  };

  return (
    <BaseActionModal
      visible={visible}
      onClose={onClose}
      card={card}
      action={action}
      title="Track Package"
      icon={carrierInfo.icon}
      iconColor={carrierInfo.color}
      gradientColors={[carrierInfo.color, '#667eea']}
      footer={
        <>
          <ActionButton
            title="Track on Carrier Website"
            icon="open-outline"
            onPress={handleTrackOnline}
          />
          <ActionButton
            title="Share Tracking Info"
            icon="share-outline"
            onPress={handleShare}
            variant="secondary"
          />
        </>
      }
    >
      {/* Carrier Badge */}
      <View style={styles.carrierBadge}>
        <Text style={styles.carrierText}>{carrier}</Text>
      </View>

      {/* Shipment Details */}
      <ModalSection title="SHIPMENT DETAILS">
        <CopyableField
          label="Tracking Number"
          value={trackingNumber}
          icon="barcode-outline"
          iconColor={carrierInfo.color}
        />

        {orderNumber && (
          <InfoRow
            icon="bag-outline"
            iconColor="#0ea5e9"
            label="Order Number"
            value={orderNumber}
          />
        )}

        <InfoRow
          icon="calendar-outline"
          iconColor="#22c55e"
          label="Estimated Delivery"
          value={estimatedDelivery}
        />

        <InfoRow
          icon="location-outline"
          iconColor="#f59e0b"
          label="Current Status"
          value={currentStatus}
        />
      </ModalSection>

      {/* Delivery Progress */}
      <ModalSection title="DELIVERY PROGRESS">
        <ProgressStep
          icon="checkmark-circle-outline"
          title="Order Placed"
          isCompleted={currentStep >= 0}
          color="#22c55e"
        />
        <ProgressStep
          icon="cube-outline"
          title="Shipped"
          isCompleted={currentStep >= 1}
          color="#22c55e"
        />
        <ProgressStep
          icon="car-outline"
          title="In Transit"
          isCompleted={currentStep >= 2}
          isActive={currentStep === 2}
          color="#f59e0b"
        />
        <ProgressStep
          icon="navigate-outline"
          title="Out for Delivery"
          isCompleted={currentStep >= 3}
          isActive={currentStep === 3}
          color="#3b82f6"
        />
        <ProgressStep
          icon="home-outline"
          title="Delivered"
          isCompleted={currentStep >= 4}
          color="#8b5cf6"
        />
      </ModalSection>
    </BaseActionModal>
  );
}

const styles = StyleSheet.create({
  carrierBadge: {
    alignSelf: 'center',
    backgroundColor: 'rgba(255,255,255,0.1)',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    marginBottom: 20,
  },
  carrierText: {
    fontSize: 14,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.8)',
  },
});
