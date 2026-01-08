/**
 * DynamicActionModal - Placeholder for dynamic action modals
 * TODO: Implement full ActionCatalog integration
 */

import React from 'react';
import {
  View,
  Text,
  Modal,
  TouchableOpacity,
  StyleSheet,
  Platform,
} from 'react-native';
import { BlurView } from 'expo-blur';

interface DynamicActionModalProps {
  visible: boolean;
  actionId: string;
  emailId: string;
  context?: Record<string, unknown>;
  onClose: () => void;
  onSuccess?: () => void;
}

export function DynamicActionModal({
  visible,
  actionId,
  emailId,
  context = {},
  onClose,
  onSuccess,
}: DynamicActionModalProps) {
  const handleConfirm = () => {
    console.log('Action executed:', { actionId, emailId, context });
    onSuccess?.();
    onClose();
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="slide"
      onRequestClose={onClose}
    >
      <View style={styles.container}>
        {Platform.OS === 'ios' ? (
          <BlurView intensity={40} tint="dark" style={StyleSheet.absoluteFill} />
        ) : (
          <View style={[StyleSheet.absoluteFill, styles.androidBackdrop]} />
        )}
        <TouchableOpacity style={styles.backdropTouch} onPress={onClose} />

        <View style={styles.modalContainer}>
          <View style={styles.handle} />

          <View style={styles.content}>
            <Text style={styles.icon}>⚡</Text>
            <Text style={styles.title}>Execute Action</Text>
            <Text style={styles.subtitle}>
              Action: {actionId}
            </Text>
            <Text style={styles.emailId}>
              Email: {emailId}
            </Text>
          </View>

          <View style={styles.actions}>
            <TouchableOpacity style={styles.cancelButton} onPress={onClose}>
              <Text style={styles.cancelButtonText}>Cancel</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.primaryButton} onPress={handleConfirm}>
              <Text style={styles.primaryButtonText}>Confirm</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'flex-end',
  },
  androidBackdrop: {
    backgroundColor: 'rgba(0,0,0,0.7)',
  },
  backdropTouch: {
    flex: 1,
  },
  modalContainer: {
    backgroundColor: 'rgba(30, 30, 40, 0.98)',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    paddingBottom: Platform.OS === 'ios' ? 34 : 20,
  },
  handle: {
    width: 40,
    height: 4,
    backgroundColor: 'rgba(255,255,255,0.3)',
    borderRadius: 2,
    alignSelf: 'center',
    marginTop: 12,
    marginBottom: 8,
  },
  content: {
    padding: 24,
    alignItems: 'center',
  },
  icon: {
    fontSize: 48,
    marginBottom: 16,
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: 'white',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 15,
    color: 'rgba(255,255,255,0.7)',
    marginBottom: 4,
  },
  emailId: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.5)',
  },
  actions: {
    flexDirection: 'row',
    padding: 20,
    gap: 12,
  },
  cancelButton: {
    flex: 1,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 14,
    padding: 16,
    alignItems: 'center',
  },
  cancelButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },
  primaryButton: {
    flex: 2,
    backgroundColor: '#667eea',
    borderRadius: 14,
    padding: 16,
    alignItems: 'center',
  },
  primaryButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '700',
  },
});

export default DynamicActionModal;
