/**
 * DynamicActionModal - Renders action modals dynamically from ActionCatalog
 * Supports all 117 action types with form fields, validation, and execution
 */

import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  Modal,
  ScrollView,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Linking,
  Clipboard,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { getActionModal, ActionModalConfig, ModalField } from '@zero/core';
import { usePerformAction } from '@zero/api';
import { Colors, Spacing, Radius, Typography } from '@zero/ui';

interface DynamicActionModalProps {
  visible: boolean;
  actionId: string;
  emailId: string;
  context?: Record<string, any>;
  onClose: () => void;
  onSuccess?: () => void;
}

interface FormValues {
  [key: string]: string;
}

export function DynamicActionModal({
  visible,
  actionId,
  emailId,
  context = {},
  onClose,
  onSuccess,
}: DynamicActionModalProps) {
  const [formValues, setFormValues] = useState<FormValues>({});
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const performAction = usePerformAction();
  const modalConfig = getActionModal(actionId);

  const handleFieldChange = useCallback((fieldId: string, value: string) => {
    setFormValues((prev) => ({ ...prev, [fieldId]: value }));
    setErrors((prev) => ({ ...prev, [fieldId]: '' }));
  }, []);

  const validateForm = useCallback((): boolean => {
    if (!modalConfig) return false;

    const newErrors: Record<string, string> = {};
    let isValid = true;

    modalConfig.fields.forEach((field) => {
      if (field.required && !formValues[field.id]?.trim()) {
        newErrors[field.id] = `${field.label} is required`;
        isValid = false;
      }
    });

    setErrors(newErrors);
    return isValid;
  }, [modalConfig, formValues]);

  const handleSubmit = useCallback(async () => {
    if (!modalConfig || !validateForm()) return;

    setIsSubmitting(true);

    try {
      if (modalConfig.actionType === 'GO_TO') {
        // Get URL from context
        const urlKey = modalConfig.contextKeys?.find((key) => key.toLowerCase().includes('url'));
        const url = urlKey ? context[urlKey] : null;

        if (url) {
          await Linking.openURL(url);
          onSuccess?.();
          onClose();
        } else {
          Alert.alert('Error', 'No URL available for this action');
        }
      } else {
        // IN_APP action - send to backend
        await performAction.mutateAsync({
          emailId,
          action: {
            id: `action_${actionId}_${Date.now()}`,
            actionId,
            displayName: modalConfig.title,
            actionType: 'IN_APP',
            isPrimary: true,
            context: { ...context, ...formValues },
          },
        });

        // Handle special actions
        if (modalConfig.copyToClipboard && context.promoCode) {
          Clipboard.setString(context.promoCode);
          Alert.alert('Copied!', `Promo code "${context.promoCode}" copied to clipboard`);
        }

        onSuccess?.();
        onClose();
      }
    } catch (error) {
      Alert.alert('Error', 'Failed to execute action. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  }, [modalConfig, formValues, context, emailId, actionId, validateForm, performAction, onSuccess, onClose]);

  const handleQuickReply = useCallback((reply: string) => {
    setFormValues((prev) => ({ ...prev, message: reply }));
  }, []);

  if (!modalConfig) {
    return null;
  }

  return (
    <Modal
      visible={visible}
      transparent
      animationType="slide"
      onRequestClose={onClose}
    >
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.container}
      >
        <BlurView intensity={40} tint="dark" style={styles.backdrop}>
          <TouchableOpacity style={styles.backdropTouch} onPress={onClose} />
        </BlurView>

        <View style={styles.modalContainer}>
          <View style={styles.handle} />

          <ScrollView
            style={styles.content}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
          >
            {/* Header */}
            <View style={styles.header}>
              <Text style={styles.icon}>{modalConfig.icon}</Text>
              <Text style={styles.title}>{modalConfig.title}</Text>
              <Text style={styles.subtitle}>{modalConfig.subtitle}</Text>
            </View>

            {/* Warning Message */}
            {modalConfig.warningMessage && (
              <View style={styles.warningContainer}>
                <Text style={styles.warningText}>⚠️ {modalConfig.warningMessage}</Text>
              </View>
            )}

            {/* Context Info */}
            {modalConfig.contextKeys && modalConfig.contextKeys.length > 0 && (
              <View style={styles.contextContainer}>
                {modalConfig.contextKeys.map((key) => {
                  const value = context[key];
                  if (!value) return null;
                  return (
                    <View key={key} style={styles.contextItem}>
                      <Text style={styles.contextLabel}>
                        {key.replace(/([A-Z])/g, ' $1').trim()}
                      </Text>
                      <Text style={styles.contextValue}>{value}</Text>
                    </View>
                  );
                })}
              </View>
            )}

            {/* Quick Replies */}
            {modalConfig.quickReplies && (
              <View style={styles.quickRepliesContainer}>
                <Text style={styles.quickRepliesLabel}>Quick Replies</Text>
                <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                  {modalConfig.quickReplies.map((reply, index) => (
                    <TouchableOpacity
                      key={index}
                      style={styles.quickReplyChip}
                      onPress={() => handleQuickReply(reply)}
                    >
                      <Text style={styles.quickReplyText}>{reply}</Text>
                    </TouchableOpacity>
                  ))}
                </ScrollView>
              </View>
            )}

            {/* Form Fields */}
            {modalConfig.fields.map((field) => (
              <FormFieldComponent
                key={field.id}
                field={field}
                value={formValues[field.id] || ''}
                error={errors[field.id]}
                onChange={(value) => handleFieldChange(field.id, value)}
              />
            ))}
          </ScrollView>

          {/* Actions */}
          <View style={styles.actions}>
            <TouchableOpacity
              style={styles.cancelButton}
              onPress={onClose}
              disabled={isSubmitting}
            >
              <Text style={styles.cancelButtonText}>{modalConfig.cancelButton}</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[
                styles.primaryButton,
                modalConfig.urgencyLevel === 'critical' && styles.urgentButton,
                isSubmitting && styles.disabledButton,
              ]}
              onPress={handleSubmit}
              disabled={isSubmitting}
            >
              <Text style={styles.primaryButtonText}>
                {isSubmitting ? 'Processing...' : modalConfig.primaryButton}
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

interface FormFieldComponentProps {
  field: ModalField;
  value: string;
  error?: string;
  onChange: (value: string) => void;
}

function FormFieldComponent({ field, value, error, onChange }: FormFieldComponentProps) {
  const [showOptions, setShowOptions] = useState(false);

  switch (field.type) {
    case 'text':
      return (
        <View style={styles.fieldContainer}>
          <Text style={styles.fieldLabel}>
            {field.label}
            {field.required && <Text style={styles.required}> *</Text>}
          </Text>
          <TextInput
            style={[styles.textInput, error && styles.inputError]}
            value={value}
            onChangeText={onChange}
            placeholder={field.placeholder}
            placeholderTextColor="rgba(255,255,255,0.4)"
          />
          {error && <Text style={styles.errorText}>{error}</Text>}
        </View>
      );

    case 'textarea':
      return (
        <View style={styles.fieldContainer}>
          <Text style={styles.fieldLabel}>
            {field.label}
            {field.required && <Text style={styles.required}> *</Text>}
          </Text>
          <TextInput
            style={[styles.textArea, error && styles.inputError]}
            value={value}
            onChangeText={onChange}
            placeholder={field.placeholder}
            placeholderTextColor="rgba(255,255,255,0.4)"
            multiline
            numberOfLines={4}
            textAlignVertical="top"
          />
          {error && <Text style={styles.errorText}>{error}</Text>}
        </View>
      );

    case 'select':
      return (
        <View style={styles.fieldContainer}>
          <Text style={styles.fieldLabel}>
            {field.label}
            {field.required && <Text style={styles.required}> *</Text>}
          </Text>
          <TouchableOpacity
            style={[styles.selectButton, error && styles.inputError]}
            onPress={() => setShowOptions(!showOptions)}
          >
            <Text style={[styles.selectText, !value && styles.placeholderText]}>
              {value
                ? field.options?.find((o) => o.value === value)?.label || value
                : 'Select an option'}
            </Text>
            <Text style={styles.selectArrow}>{showOptions ? '▲' : '▼'}</Text>
          </TouchableOpacity>
          {showOptions && (
            <View style={styles.optionsContainer}>
              {field.options?.map((option) => (
                <TouchableOpacity
                  key={option.value}
                  style={[
                    styles.optionItem,
                    value === option.value && styles.selectedOption,
                  ]}
                  onPress={() => {
                    onChange(option.value);
                    setShowOptions(false);
                  }}
                >
                  <Text
                    style={[
                      styles.optionText,
                      value === option.value && styles.selectedOptionText,
                    ]}
                  >
                    {option.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          )}
          {error && <Text style={styles.errorText}>{error}</Text>}
        </View>
      );

    case 'multiselect':
      const selectedValues = value ? value.split(',') : [];
      return (
        <View style={styles.fieldContainer}>
          <Text style={styles.fieldLabel}>
            {field.label}
            {field.required && <Text style={styles.required}> *</Text>}
          </Text>
          <View style={styles.multiSelectContainer}>
            {field.options?.map((option) => {
              const isSelected = selectedValues.includes(option.value);
              return (
                <TouchableOpacity
                  key={option.value}
                  style={[styles.multiSelectChip, isSelected && styles.selectedChip]}
                  onPress={() => {
                    const newValues = isSelected
                      ? selectedValues.filter((v) => v !== option.value)
                      : [...selectedValues, option.value];
                    onChange(newValues.join(','));
                  }}
                >
                  <Text
                    style={[
                      styles.multiSelectText,
                      isSelected && styles.selectedChipText,
                    ]}
                  >
                    {option.label}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
          {error && <Text style={styles.errorText}>{error}</Text>}
        </View>
      );

    default:
      return null;
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'flex-end',
  },
  backdrop: {
    ...StyleSheet.absoluteFillObject,
  },
  backdropTouch: {
    flex: 1,
  },
  modalContainer: {
    backgroundColor: 'rgba(30, 30, 40, 0.98)',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    maxHeight: '85%',
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
    padding: 20,
  },
  header: {
    alignItems: 'center',
    marginBottom: 24,
  },
  icon: {
    fontSize: 48,
    marginBottom: 12,
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: 'white',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 15,
    color: 'rgba(255,255,255,0.7)',
  },
  warningContainer: {
    backgroundColor: 'rgba(255, 165, 0, 0.15)',
    borderWidth: 1,
    borderColor: 'rgba(255, 165, 0, 0.5)',
    borderRadius: 12,
    padding: 12,
    marginBottom: 20,
  },
  warningText: {
    color: 'rgba(255, 200, 100, 1)',
    fontSize: 14,
    textAlign: 'center',
  },
  contextContainer: {
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
  },
  contextItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  contextLabel: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.6)',
    textTransform: 'capitalize',
  },
  contextValue: {
    fontSize: 13,
    color: 'white',
    fontWeight: '600',
    maxWidth: '60%',
    textAlign: 'right',
  },
  quickRepliesContainer: {
    marginBottom: 20,
  },
  quickRepliesLabel: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.6)',
    marginBottom: 8,
  },
  quickReplyChip: {
    backgroundColor: 'rgba(102, 126, 234, 0.3)',
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 16,
    marginRight: 8,
  },
  quickReplyText: {
    color: 'white',
    fontSize: 14,
  },
  fieldContainer: {
    marginBottom: 20,
  },
  fieldLabel: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.9)',
    marginBottom: 8,
    fontWeight: '500',
  },
  required: {
    color: '#ff6b6b',
  },
  textInput: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 12,
    padding: 14,
    color: 'white',
    fontSize: 16,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
  },
  textArea: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 12,
    padding: 14,
    color: 'white',
    fontSize: 16,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
    minHeight: 100,
  },
  inputError: {
    borderColor: '#ff6b6b',
  },
  errorText: {
    color: '#ff6b6b',
    fontSize: 12,
    marginTop: 4,
  },
  selectButton: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 12,
    padding: 14,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
  },
  selectText: {
    color: 'white',
    fontSize: 16,
  },
  placeholderText: {
    color: 'rgba(255,255,255,0.4)',
  },
  selectArrow: {
    color: 'rgba(255,255,255,0.6)',
    fontSize: 12,
  },
  optionsContainer: {
    backgroundColor: 'rgba(50, 50, 60, 0.98)',
    borderRadius: 12,
    marginTop: 8,
    overflow: 'hidden',
  },
  optionItem: {
    padding: 14,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.05)',
  },
  selectedOption: {
    backgroundColor: 'rgba(102, 126, 234, 0.3)',
  },
  optionText: {
    color: 'white',
    fontSize: 15,
  },
  selectedOptionText: {
    fontWeight: '600',
  },
  multiSelectContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  multiSelectChip: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
  },
  selectedChip: {
    backgroundColor: 'rgba(102, 126, 234, 0.4)',
    borderColor: 'rgba(102, 126, 234, 0.8)',
  },
  multiSelectText: {
    color: 'rgba(255,255,255,0.8)',
    fontSize: 14,
  },
  selectedChipText: {
    color: 'white',
    fontWeight: '600',
  },
  actions: {
    flexDirection: 'row',
    padding: 20,
    paddingTop: 0,
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
  urgentButton: {
    backgroundColor: '#e74c3c',
  },
  disabledButton: {
    opacity: 0.6,
  },
  primaryButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '700',
  },
});

export default DynamicActionModal;

