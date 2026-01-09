/**
 * Action Modal Gallery - Developer/QA tool for testing all action modals
 * Lists all 46+ actions, filterable by mode and permission
 * Tap any action to open its modal with mock context data
 */

import React, { useState, useCallback, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Pressable,
  TextInput,
  Dimensions,
  Platform,
} from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { HapticService } from '../services/HapticService';
import {
  ACTION_CONFIGS,
  getActionsForMode,
  getAllCategories,
  getRegistryStatistics,
  sortByPriority,
  ActionConfig,
} from '../data/actionConfigs';
import {
  // Modals
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
} from '../components/modals';
import type { EmailCard, SuggestedAction } from '@zero/types';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

// Mock email card for testing
const MOCK_CARD: EmailCard = {
  id: 'test-email-001',
  title: 'Test Email Subject Line for Modal Testing',
  summary: 'This is a test summary for the email. It contains important information about the action you are testing.',
  sender: {
    name: 'Test Sender',
    email: 'test@example.com',
  },
  receivedAt: new Date().toISOString(),
  type: 'mail',
  priority: 'high',
  intent: 'action_required',
  category: 'Test',
  suggestedActions: [],
};

// Mock context data for different action types
const MOCK_CONTEXT: Record<string, Record<string, string>> = {
  track_package: {
    trackingNumber: '1Z999AA10123456784',
    carrier: 'UPS',
    url: 'https://www.ups.com/track',
    estimatedDelivery: 'January 15, 2026',
    deliveryStatus: 'In Transit',
    orderNumber: 'ORD-123456',
  },
  pay_invoice: {
    invoiceId: 'INV-2026-001',
    amount: '$149.99',
    merchant: 'Acme Corporation',
    dueDate: 'January 20, 2026',
    paymentLink: 'https://pay.stripe.com/invoice',
  },
  check_in_flight: {
    flightNumber: 'AA 1234',
    airline: 'American Airlines',
    checkInUrl: 'https://www.aa.com/checkin',
    departureTime: '10:30 AM',
    gate: 'B12',
    seat: '14A',
    confirmationCode: 'ABC123',
  },
  write_review: {
    productName: 'Wireless Bluetooth Headphones',
    orderNumber: 'ORD-789012',
    reviewLink: 'https://amazon.com/review',
  },
  rsvp_yes: {
    eventName: 'Team Offsite Meeting',
    eventDate: 'January 25, 2026',
    eventTime: '2:00 PM',
    location: '123 Conference Center',
    host: 'John Manager',
  },
  rsvp_no: {
    eventName: 'Team Offsite Meeting',
    eventDate: 'January 25, 2026',
    eventTime: '2:00 PM',
    location: '123 Conference Center',
    host: 'John Manager',
  },
  unsubscribe: {
    unsubscribeUrl: 'https://example.com/unsubscribe',
    senderName: 'Marketing Newsletter',
  },
  add_to_calendar: {
    eventTitle: 'Important Meeting',
    eventDate: 'January 25, 2026',
    eventTime: '3:00 PM',
    location: 'Conference Room A',
  },
  save_contact: {
    name: 'Jane Doe',
    email: 'jane.doe@company.com',
    phone: '+1 (555) 123-4567',
    company: 'Acme Corp',
  },
};

type FilterMode = 'all' | 'mail' | 'ads';
type FilterPermission = 'all' | 'free' | 'premium';

export default function ActionGalleryScreen() {
  const insets = useSafeAreaInsets();
  const [searchQuery, setSearchQuery] = useState('');
  const [modeFilter, setModeFilter] = useState<FilterMode>('all');
  const [permissionFilter, setPermissionFilter] = useState<FilterPermission>('all');
  const [selectedAction, setSelectedAction] = useState<ActionConfig | null>(null);
  const [showModal, setShowModal] = useState(false);

  // Get statistics
  const stats = useMemo(() => getRegistryStatistics(), []);
  const categories = useMemo(() => getAllCategories(), []);

  // Filter actions
  const filteredActions = useMemo(() => {
    let actions = [...ACTION_CONFIGS];

    // Filter by mode
    if (modeFilter !== 'all') {
      actions = actions.filter((a) => a.mode === modeFilter || a.mode === 'both');
    }

    // Filter by permission
    if (permissionFilter !== 'all') {
      actions = actions.filter((a) => a.permission === permissionFilter);
    }

    // Filter by search
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      actions = actions.filter(
        (a) =>
          a.displayName.toLowerCase().includes(query) ||
          a.actionId.toLowerCase().includes(query) ||
          a.category.toLowerCase().includes(query)
      );
    }

    return sortByPriority(actions);
  }, [modeFilter, permissionFilter, searchQuery]);

  // Group by category
  const groupedActions = useMemo(() => {
    const groups: Record<string, ActionConfig[]> = {};
    filteredActions.forEach((action) => {
      if (!groups[action.category]) {
        groups[action.category] = [];
      }
      groups[action.category].push(action);
    });
    return groups;
  }, [filteredActions]);

  const handleSelectAction = useCallback((action: ActionConfig) => {
    HapticService.lightImpact();
    setSelectedAction(action);
    setShowModal(true);
  }, []);

  const handleCloseModal = useCallback(() => {
    setShowModal(false);
    setSelectedAction(null);
  }, []);

  const handleBack = useCallback(() => {
    HapticService.lightImpact();
    router.back();
  }, []);

  // Create mock action for selected config
  const mockAction: SuggestedAction | null = selectedAction
    ? {
        id: selectedAction.actionId,
        displayName: selectedAction.displayName,
        type: selectedAction.actionId as any,
        context: MOCK_CONTEXT[selectedAction.actionId] || {},
      }
    : null;

  // Render appropriate modal
  const renderModal = () => {
    if (!selectedAction || !mockAction) return null;

    const modalName = getModalForAction(selectedAction.actionId);
    const commonProps = {
      visible: showModal,
      onClose: handleCloseModal,
      card: MOCK_CARD,
      action: mockAction,
    };

    switch (modalName) {
      case 'TrackPackageModal':
        return <TrackPackageModal {...commonProps} />;
      case 'PayInvoiceModal':
        return <PayInvoiceModal {...commonProps} />;
      case 'CheckInFlightModal':
        return <CheckInFlightModal {...commonProps} />;
      case 'RSVPModal':
        return <RSVPModal {...commonProps} />;
      case 'AddToCalendarModal':
        return <AddToCalendarModal {...commonProps} />;
      case 'SaveContactModal':
        return <SaveContactModal {...commonProps} />;
      case 'WriteReviewModal':
        return <WriteReviewModal {...commonProps} />;
      case 'UnsubscribeModal':
        return <UnsubscribeModal {...commonProps} />;
      case 'ShareModal':
        return <ShareModal {...commonProps} />;
      case 'SnoozeModal':
        return <SnoozeModal {...commonProps} />;
      case 'NewsletterSummaryModal':
        return <NewsletterSummaryModal {...commonProps} />;
      case 'ViewDetailsModal':
        return <ViewDetailsModal {...commonProps} />;
      case 'EmailComposerModal':
        return <EmailComposerModal {...commonProps} />;
      case 'ConfirmationModal':
        return (
          <ConfirmationModal
            {...commonProps}
            message={`Confirm ${selectedAction.displayName}?`}
          />
        );
      default:
        return <GenericActionModal {...commonProps} />;
    }
  };

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={['#1a1a2e', '#0a0a0f']}
        style={StyleSheet.absoluteFill}
      />

      {/* Header */}
      <SafeAreaView edges={['top']} style={styles.header}>
        <Pressable style={styles.backButton} onPress={handleBack}>
          <Ionicons name="chevron-back" size={24} color="white" />
        </Pressable>
        <View style={styles.headerContent}>
          <Text style={styles.headerTitle}>Action Modal Gallery</Text>
          <Text style={styles.headerSubtitle}>
            {stats.total} Actions • {stats.premium} Premium
          </Text>
        </View>
      </SafeAreaView>

      {/* Search */}
      <View style={styles.searchContainer}>
        <View style={styles.searchBar}>
          <Ionicons name="search" size={18} color="rgba(255,255,255,0.5)" />
          <TextInput
            style={styles.searchInput}
            placeholder="Search actions..."
            placeholderTextColor="rgba(255,255,255,0.4)"
            value={searchQuery}
            onChangeText={setSearchQuery}
          />
          {searchQuery ? (
            <Pressable onPress={() => setSearchQuery('')}>
              <Ionicons name="close-circle" size={18} color="rgba(255,255,255,0.5)" />
            </Pressable>
          ) : null}
        </View>
      </View>

      {/* Filters */}
      <View style={styles.filtersContainer}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filtersScroll}>
          {/* Mode filters */}
          {(['all', 'mail', 'ads'] as FilterMode[]).map((mode) => (
            <Pressable
              key={mode}
              style={[styles.filterChip, modeFilter === mode && styles.filterChipActive]}
              onPress={() => setModeFilter(mode)}
            >
              <Text style={[styles.filterChipText, modeFilter === mode && styles.filterChipTextActive]}>
                {mode === 'all' ? 'All Modes' : mode.charAt(0).toUpperCase() + mode.slice(1)}
              </Text>
            </Pressable>
          ))}

          <View style={styles.filterDivider} />

          {/* Permission filters */}
          {(['all', 'free', 'premium'] as FilterPermission[]).map((perm) => (
            <Pressable
              key={perm}
              style={[styles.filterChip, permissionFilter === perm && styles.filterChipActive]}
              onPress={() => setPermissionFilter(perm)}
            >
              {perm === 'premium' && <Ionicons name="sparkles" size={14} color={permissionFilter === perm ? 'white' : '#f59e0b'} />}
              <Text style={[styles.filterChipText, permissionFilter === perm && styles.filterChipTextActive]}>
                {perm === 'all' ? 'All Tiers' : perm.charAt(0).toUpperCase() + perm.slice(1)}
              </Text>
            </Pressable>
          ))}
        </ScrollView>
      </View>

      {/* Results Count */}
      <View style={styles.resultsHeader}>
        <Text style={styles.resultsCount}>
          {filteredActions.length} action{filteredActions.length !== 1 ? 's' : ''}
        </Text>
      </View>

      {/* Action List */}
      <ScrollView
        style={styles.listContainer}
        contentContainerStyle={[styles.listContent, { paddingBottom: insets.bottom + 20 }]}
        showsVerticalScrollIndicator={false}
      >
        {Object.entries(groupedActions).map(([category, actions]) => (
          <View key={category} style={styles.categorySection}>
            <Text style={styles.categoryTitle}>{category}</Text>
            {actions.map((action) => (
              <Pressable
                key={action.actionId}
                style={styles.actionCard}
                onPress={() => handleSelectAction(action)}
              >
                <View style={[styles.actionIcon, { backgroundColor: `${action.iconColor}20` }]}>
                  <Ionicons
                    name={action.icon as keyof typeof Ionicons.glyphMap}
                    size={22}
                    color={action.iconColor}
                  />
                </View>
                <View style={styles.actionInfo}>
                  <View style={styles.actionHeader}>
                    <Text style={styles.actionName}>{action.displayName}</Text>
                    {action.permission === 'premium' && (
                      <View style={styles.premiumBadge}>
                        <Ionicons name="sparkles" size={10} color="#f59e0b" />
                      </View>
                    )}
                  </View>
                  <Text style={styles.actionId}>{action.actionId}</Text>
                </View>
                <View style={styles.actionMeta}>
                  <Text style={styles.actionMode}>{action.mode}</Text>
                  <Ionicons name="chevron-forward" size={18} color="rgba(255,255,255,0.3)" />
                </View>
              </Pressable>
            ))}
          </View>
        ))}
      </ScrollView>

      {/* Modal */}
      {renderModal()}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0f',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.08)',
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255,255,255,0.1)',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  headerContent: {
    flex: 1,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: 'white',
  },
  headerSubtitle: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.5)',
    marginTop: 2,
  },
  searchContainer: {
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 12,
    paddingHorizontal: 14,
    gap: 10,
  },
  searchInput: {
    flex: 1,
    height: 44,
    fontSize: 15,
    color: 'white',
  },
  filtersContainer: {
    paddingBottom: 12,
  },
  filtersScroll: {
    paddingHorizontal: 16,
    gap: 8,
  },
  filterChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: 'rgba(255,255,255,0.08)',
  },
  filterChipActive: {
    backgroundColor: '#667eea',
  },
  filterChipText: {
    fontSize: 13,
    fontWeight: '500',
    color: 'rgba(255,255,255,0.7)',
  },
  filterChipTextActive: {
    color: 'white',
  },
  filterDivider: {
    width: 1,
    height: 20,
    backgroundColor: 'rgba(255,255,255,0.1)',
    marginHorizontal: 4,
  },
  resultsHeader: {
    paddingHorizontal: 16,
    paddingBottom: 8,
  },
  resultsCount: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.5)',
  },
  listContainer: {
    flex: 1,
  },
  listContent: {
    paddingHorizontal: 16,
  },
  categorySection: {
    marginBottom: 20,
  },
  categoryTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: 'rgba(255,255,255,0.4)',
    letterSpacing: 0.5,
    marginBottom: 10,
    textTransform: 'uppercase',
  },
  actionCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 14,
    padding: 14,
    marginBottom: 8,
  },
  actionIcon: {
    width: 44,
    height: 44,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  actionInfo: {
    flex: 1,
  },
  actionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  actionName: {
    fontSize: 15,
    fontWeight: '600',
    color: 'white',
  },
  premiumBadge: {
    backgroundColor: 'rgba(245, 158, 11, 0.2)',
    borderRadius: 6,
    padding: 3,
  },
  actionId: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.4)',
    marginTop: 2,
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
  actionMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  actionMode: {
    fontSize: 11,
    color: 'rgba(255,255,255,0.3)',
    textTransform: 'uppercase',
  },
});
