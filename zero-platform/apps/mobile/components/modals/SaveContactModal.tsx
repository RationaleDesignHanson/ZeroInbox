/**
 * SaveContactModal - Save contact to iOS Contacts
 */

import React, { useState } from 'react';
import { View, Text, StyleSheet, TextInput, Alert, Linking } from 'react-native';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';
import {
  BaseActionModal,
  ModalSection,
  ActionButton,
} from './BaseActionModal';

interface SaveContactModalProps {
  visible: boolean;
  onClose: () => void;
  card: EmailCard;
  action: SuggestedAction;
}

export function SaveContactModal({ visible, onClose, card, action }: SaveContactModalProps) {
  const context = action.context || {};
  const [name, setName] = useState(context.name || card.sender?.name || '');
  const [email, setEmail] = useState(context.email || card.sender?.email || '');
  const [phone, setPhone] = useState(context.phone || '');
  const [company, setCompany] = useState(context.company || '');

  const handleSaveContact = async () => {
    HapticService.mediumImpact();
    
    // Open contacts app
    try {
      await Linking.openURL('contacts://');
      HapticService.success();
      Alert.alert(
        'Contact Info',
        `Name: ${name}\nEmail: ${email}${phone ? `\nPhone: ${phone}` : ''}`,
        [{ text: 'OK', onPress: onClose }]
      );
    } catch (error) {
      Alert.alert('Error', 'Could not open Contacts app');
    }
  };

  return (
    <BaseActionModal
      visible={visible}
      onClose={onClose}
      card={card}
      action={action}
      title="Save Contact"
      icon="person-add-outline"
      iconColor="#8b5cf6"
      gradientColors={['#8b5cf6', '#7c3aed']}
      footer={
        <ActionButton
          title="Save to Contacts"
          icon="person-add-outline"
          onPress={handleSaveContact}
        />
      }
    >
      {/* Contact Avatar */}
      <View style={styles.avatarContainer}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{name.charAt(0).toUpperCase()}</Text>
        </View>
      </View>

      {/* Contact Fields */}
      <ModalSection title="CONTACT INFORMATION">
        <View style={styles.fieldGroup}>
          <Text style={styles.fieldLabel}>Name</Text>
          <TextInput
            style={styles.input}
            value={name}
            onChangeText={setName}
            placeholder="Full name"
            placeholderTextColor="rgba(255,255,255,0.4)"
          />
        </View>

        <View style={styles.fieldGroup}>
          <Text style={styles.fieldLabel}>Email</Text>
          <TextInput
            style={styles.input}
            value={email}
            onChangeText={setEmail}
            placeholder="Email address"
            placeholderTextColor="rgba(255,255,255,0.4)"
            keyboardType="email-address"
            autoCapitalize="none"
          />
        </View>

        <View style={styles.fieldGroup}>
          <Text style={styles.fieldLabel}>Phone (optional)</Text>
          <TextInput
            style={styles.input}
            value={phone}
            onChangeText={setPhone}
            placeholder="Phone number"
            placeholderTextColor="rgba(255,255,255,0.4)"
            keyboardType="phone-pad"
          />
        </View>

        <View style={styles.fieldGroup}>
          <Text style={styles.fieldLabel}>Company (optional)</Text>
          <TextInput
            style={styles.input}
            value={company}
            onChangeText={setCompany}
            placeholder="Company name"
            placeholderTextColor="rgba(255,255,255,0.4)"
          />
        </View>
      </ModalSection>
    </BaseActionModal>
  );
}

const styles = StyleSheet.create({
  avatarContainer: {
    alignItems: 'center',
    marginBottom: 20,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: 'rgba(139, 92, 246, 0.3)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    fontSize: 32,
    fontWeight: '700',
    color: '#8b5cf6',
  },
  fieldGroup: {
    marginBottom: 16,
  },
  fieldLabel: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.5)',
    marginBottom: 6,
    marginLeft: 4,
  },
  input: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 12,
    padding: 14,
    fontSize: 16,
    color: 'white',
  },
});
