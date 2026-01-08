/**
 * DocumentViewerModal - View and interact with document attachments
 * Used for view_document and sign_document actions
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  ScrollView,
  Platform,
  ActivityIndicator,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import * as WebBrowser from 'expo-web-browser';
import type { EmailCard, SuggestedAction } from '@zero/types';
import { HapticService } from '../../services/HapticService';

interface DocumentViewerModalProps {
  visible: boolean;
  onClose: () => void;
  onAction: (action: string) => void;
  card: EmailCard;
  action: SuggestedAction;
  context?: Record<string, string>;
}

export function DocumentViewerModal({
  visible,
  onClose,
  onAction,
  card,
  action,
  context,
}: DocumentViewerModalProps) {
  const insets = useSafeAreaInsets();
  const [isLoading, setIsLoading] = useState(false);

  // Extract document details
  const documentName = context?.documentName || context?.filename || 'Document';
  const documentUrl = context?.documentUrl || context?.url || '';
  const documentType = getDocumentType(documentName);
  const requiresSignature = action.id === 'sign_document' || context?.requiresSignature === 'true';

  const handleOpenDocument = async () => {
    if (!documentUrl) {
      HapticService.warning();
      return;
    }

    HapticService.mediumImpact();
    setIsLoading(true);

    try {
      await WebBrowser.openBrowserAsync(documentUrl, {
        presentationStyle: WebBrowser.WebBrowserPresentationStyle.FULL_SCREEN,
      });
    } catch (error) {
      console.error('Failed to open document:', error);
      HapticService.error();
    } finally {
      setIsLoading(false);
    }
  };

  const handleSign = () => {
    HapticService.mediumImpact();
    onAction('sign');
  };

  const handleDownload = () => {
    HapticService.mediumImpact();
    onAction('download');
  };

  if (!visible) return null;

  return (
    <View style={styles.container}>
      <View style={styles.backdrop}>
        <Pressable style={StyleSheet.absoluteFill} onPress={onClose} />
      </View>

      <View style={[styles.modal, { paddingBottom: insets.bottom + 16 }]}>
        {Platform.OS === 'ios' ? (
          <BlurView intensity={80} tint="dark" style={StyleSheet.absoluteFill} />
        ) : (
          <View style={[StyleSheet.absoluteFill, styles.androidFallback]} />
        )}

        {/* Handle */}
        <View style={styles.handle} />

        {/* Header */}
        <View style={styles.header}>
          <Ionicons name="document-text" size={28} color="#3b82f6" />
          <Text style={styles.headerTitle}>
            {requiresSignature ? 'Sign Document' : 'View Document'}
          </Text>
          <Pressable onPress={onClose} style={styles.closeButton}>
            <Ionicons name="close" size={24} color="rgba(255,255,255,0.6)" />
          </Pressable>
        </View>

        <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
          {/* Document Preview Card */}
          <View style={styles.documentCard}>
            <View style={styles.documentIconContainer}>
              <View style={[styles.documentIcon, { backgroundColor: documentType.color + '20' }]}>
                <Ionicons name={documentType.icon} size={32} color={documentType.color} />
              </View>
            </View>

            <Text style={styles.documentName}>{documentName}</Text>
            <Text style={styles.documentMeta}>
              From: {card.sender?.name || card.sender?.email || 'Unknown'}
            </Text>

            {requiresSignature && (
              <View style={styles.signatureBadge}>
                <Ionicons name="pencil" size={14} color="#f59e0b" />
                <Text style={styles.signatureBadgeText}>Signature Required</Text>
              </View>
            )}
          </View>

          {/* Document Info */}
          <View style={styles.infoSection}>
            <Text style={styles.sectionTitle}>Document Details</Text>
            
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Type</Text>
              <Text style={styles.infoValue}>{documentType.label}</Text>
            </View>
            
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Source</Text>
              <Text style={styles.infoValue}>{card.title}</Text>
            </View>

            {context?.pageCount && (
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Pages</Text>
                <Text style={styles.infoValue}>{context.pageCount}</Text>
              </View>
            )}
          </View>

          {/* Email Context */}
          <View style={styles.contextSection}>
            <Text style={styles.sectionTitle}>From Email</Text>
            <Text style={styles.contextText} numberOfLines={3}>
              {card.summary}
            </Text>
          </View>
        </ScrollView>

        {/* Actions */}
        <View style={styles.actions}>
          <Pressable style={styles.secondaryButton} onPress={handleDownload}>
            <Ionicons name="download-outline" size={20} color="white" />
            <Text style={styles.secondaryButtonText}>Download</Text>
          </Pressable>
          
          <Pressable
            style={[styles.primaryButton, isLoading && styles.buttonDisabled]}
            onPress={requiresSignature ? handleSign : handleOpenDocument}
            disabled={isLoading}
          >
            {isLoading ? (
              <ActivityIndicator size="small" color="white" />
            ) : (
              <>
                <Ionicons
                  name={requiresSignature ? 'pencil' : 'open-outline'}
                  size={20}
                  color="white"
                />
                <Text style={styles.primaryButtonText}>
                  {requiresSignature ? 'Sign Now' : 'Open'}
                </Text>
              </>
            )}
          </Pressable>
        </View>
      </View>
    </View>
  );
}

// Helper to determine document type from filename
function getDocumentType(filename: string): {
  icon: keyof typeof Ionicons.glyphMap;
  label: string;
  color: string;
} {
  const ext = filename.split('.').pop()?.toLowerCase() || '';
  
  const types: Record<string, { icon: keyof typeof Ionicons.glyphMap; label: string; color: string }> = {
    pdf: { icon: 'document-text', label: 'PDF Document', color: '#ef4444' },
    doc: { icon: 'document', label: 'Word Document', color: '#3b82f6' },
    docx: { icon: 'document', label: 'Word Document', color: '#3b82f6' },
    xls: { icon: 'grid', label: 'Excel Spreadsheet', color: '#22c55e' },
    xlsx: { icon: 'grid', label: 'Excel Spreadsheet', color: '#22c55e' },
    ppt: { icon: 'easel', label: 'PowerPoint', color: '#f97316' },
    pptx: { icon: 'easel', label: 'PowerPoint', color: '#f97316' },
    jpg: { icon: 'image', label: 'Image', color: '#8b5cf6' },
    jpeg: { icon: 'image', label: 'Image', color: '#8b5cf6' },
    png: { icon: 'image', label: 'Image', color: '#8b5cf6' },
  };

  return types[ext] || { icon: 'document', label: 'Document', color: '#6b7280' };
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'flex-end',
  },
  backdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  modal: {
    maxHeight: '80%',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
    borderBottomWidth: 0,
  },
  androidFallback: {
    backgroundColor: 'rgba(25, 25, 35, 0.98)',
  },
  handle: {
    width: 40,
    height: 4,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 2,
    alignSelf: 'center',
    marginTop: 12,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    gap: 12,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.1)',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: 'white',
    flex: 1,
  },
  closeButton: {
    padding: 4,
  },
  content: {
    flex: 1,
    padding: 20,
  },
  documentCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    borderRadius: 16,
    padding: 20,
    alignItems: 'center',
    marginBottom: 20,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  documentIconContainer: {
    marginBottom: 16,
  },
  documentIcon: {
    width: 72,
    height: 72,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  documentName: {
    fontSize: 18,
    fontWeight: '600',
    color: 'white',
    textAlign: 'center',
    marginBottom: 8,
  },
  documentMeta: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.5)',
  },
  signatureBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 12,
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: 'rgba(245, 158, 11, 0.15)',
    borderRadius: 20,
  },
  signatureBadgeText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#f59e0b',
  },
  infoSection: {
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 12,
    fontWeight: '600',
    color: 'rgba(255, 255, 255, 0.5)',
    marginBottom: 12,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.05)',
  },
  infoLabel: {
    fontSize: 15,
    color: 'rgba(255, 255, 255, 0.6)',
  },
  infoValue: {
    fontSize: 15,
    color: 'white',
    fontWeight: '500',
  },
  contextSection: {
    marginBottom: 20,
  },
  contextText: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    lineHeight: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderRadius: 12,
    padding: 14,
  },
  actions: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    gap: 12,
  },
  secondaryButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 16,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 14,
  },
  secondaryButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
  primaryButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 16,
    backgroundColor: '#3b82f6',
    borderRadius: 14,
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  primaryButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: 'white',
  },
});

