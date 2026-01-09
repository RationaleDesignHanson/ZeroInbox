/**
 * WriteReviewModal - Product review with star rating
 */

import React, { useState } from 'react';
import { View, Text, StyleSheet, TextInput, Linking, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';
import {
  BaseActionModal,
  ModalSection,
  ActionButton,
} from './BaseActionModal';

interface WriteReviewModalProps {
  visible: boolean;
  onClose: () => void;
  card: EmailCard;
  action: SuggestedAction;
}

export function WriteReviewModal({ visible, onClose, card, action }: WriteReviewModalProps) {
  const [rating, setRating] = useState(0);
  const [reviewText, setReviewText] = useState('');

  const context = action.context || {};
  const productName = context.productName || 'Product';
  const reviewLink = context.reviewLink || context.url || '';
  const orderNumber = context.orderNumber || '';

  const handleSetRating = (stars: number) => {
    HapticService.lightImpact();
    setRating(stars);
  };

  const handleSubmitReview = async () => {
    HapticService.success();
    if (reviewLink) {
      await Linking.openURL(reviewLink);
    }
    onClose();
  };

  const handleOpenReviewLink = async () => {
    HapticService.mediumImpact();
    if (reviewLink) {
      await Linking.openURL(reviewLink);
      onClose();
    }
  };

  return (
    <BaseActionModal
      visible={visible}
      onClose={onClose}
      card={card}
      action={action}
      title="Write Review"
      icon="star-outline"
      iconColor="#f59e0b"
      gradientColors={['#f59e0b', '#d97706']}
      footer={
        <>
          {reviewLink ? (
            <ActionButton
              title="Write Review on Website"
              icon="open-outline"
              onPress={handleOpenReviewLink}
            />
          ) : (
            <ActionButton
              title="Submit Review"
              icon="checkmark-circle-outline"
              onPress={handleSubmitReview}
              disabled={rating === 0}
            />
          )}
        </>
      }
    >
      {/* Product Info */}
      <View style={styles.productCard}>
        <View style={styles.productIcon}>
          <Ionicons name="cube-outline" size={30} color="#f59e0b" />
        </View>
        <View style={styles.productInfo}>
          <Text style={styles.productName}>{productName}</Text>
          {orderNumber && (
            <Text style={styles.orderNumber}>Order #{orderNumber}</Text>
          )}
        </View>
      </View>

      {/* Star Rating */}
      <ModalSection title="YOUR RATING">
        <View style={styles.starsContainer}>
          {[1, 2, 3, 4, 5].map((star) => (
            <Pressable
              key={star}
              onPress={() => handleSetRating(star)}
              style={styles.starButton}
            >
              <Ionicons
                name={star <= rating ? 'star' : 'star-outline'}
                size={36}
                color={star <= rating ? '#f59e0b' : 'rgba(255,255,255,0.3)'}
              />
            </Pressable>
          ))}
        </View>
        <Text style={styles.ratingLabel}>
          {rating === 0 && 'Tap to rate'}
          {rating === 1 && 'Poor'}
          {rating === 2 && 'Fair'}
          {rating === 3 && 'Good'}
          {rating === 4 && 'Very Good'}
          {rating === 5 && 'Excellent!'}
        </Text>
      </ModalSection>

      {/* Review Text (only if no external link) */}
      {!reviewLink && (
        <ModalSection title="YOUR REVIEW">
          <TextInput
            style={styles.reviewInput}
            placeholder="Share your experience with this product..."
            placeholderTextColor="rgba(255,255,255,0.4)"
            multiline
            numberOfLines={4}
            value={reviewText}
            onChangeText={setReviewText}
          />
          <Text style={styles.charCount}>{reviewText.length}/500</Text>
        </ModalSection>
      )}

      {/* Quick Tips */}
      <View style={styles.tips}>
        <Text style={styles.tipsTitle}>💡 Review Tips</Text>
        <Text style={styles.tipText}>• Share what you liked most</Text>
        <Text style={styles.tipText}>• Mention product quality</Text>
        <Text style={styles.tipText}>• Would you recommend it?</Text>
      </View>
    </BaseActionModal>
  );
}

const styles = StyleSheet.create({
  productCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(245, 158, 11, 0.15)',
    borderRadius: 16,
    padding: 16,
    marginBottom: 20,
    gap: 14,
  },
  productIcon: {
    width: 56,
    height: 56,
    borderRadius: 14,
    backgroundColor: 'rgba(245, 158, 11, 0.2)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  productInfo: {
    flex: 1,
  },
  productName: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
  orderNumber: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.5)',
    marginTop: 4,
  },
  starsContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 8,
    marginBottom: 8,
  },
  starButton: {
    padding: 4,
  },
  ratingLabel: {
    textAlign: 'center',
    fontSize: 14,
    fontWeight: '600',
    color: '#f59e0b',
  },
  reviewInput: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 12,
    padding: 14,
    color: 'white',
    fontSize: 15,
    minHeight: 100,
    textAlignVertical: 'top',
  },
  charCount: {
    textAlign: 'right',
    fontSize: 12,
    color: 'rgba(255,255,255,0.4)',
    marginTop: 8,
  },
  tips: {
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 14,
    padding: 16,
    marginTop: 12,
  },
  tipsTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: 'white',
    marginBottom: 10,
  },
  tipText: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.6)',
    paddingVertical: 3,
  },
});
