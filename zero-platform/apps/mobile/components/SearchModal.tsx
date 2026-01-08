/**
 * SearchModal - Full-screen search interface
 * Filter and search through emails
 */

import React, { useState, useMemo, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  Pressable,
  FlatList,
  Platform,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { EmailCard } from '@zero/types';
import { HapticService } from '../services/HapticService';

interface SearchModalProps {
  visible: boolean;
  onClose: () => void;
  onSelectEmail: (card: EmailCard) => void;
  emails: EmailCard[];
}

type FilterType = 'all' | 'mail' | 'ads' | 'urgent' | 'unread';

const FILTERS: { id: FilterType; label: string; icon: keyof typeof Ionicons.glyphMap }[] = [
  { id: 'all', label: 'All', icon: 'mail' },
  { id: 'mail', label: 'Mail', icon: 'mail-outline' },
  { id: 'ads', label: 'Ads', icon: 'megaphone-outline' },
  { id: 'urgent', label: 'Urgent', icon: 'alert-circle-outline' },
  { id: 'unread', label: 'Unread', icon: 'mail-unread-outline' },
];

export function SearchModal({
  visible,
  onClose,
  onSelectEmail,
  emails,
}: SearchModalProps) {
  const insets = useSafeAreaInsets();
  const [searchQuery, setSearchQuery] = useState('');
  const [activeFilter, setActiveFilter] = useState<FilterType>('all');

  // Filter and search emails
  const filteredEmails = useMemo(() => {
    let results = [...emails];

    // Apply type filter
    if (activeFilter === 'mail') {
      results = results.filter((e) => e.type === 'mail');
    } else if (activeFilter === 'ads') {
      results = results.filter((e) => e.type === 'ads');
    } else if (activeFilter === 'urgent') {
      results = results.filter((e) => e.priority === 'high');
    } else if (activeFilter === 'unread') {
      // For demo, show all since we don't track read state
      results = results.filter((e) => !e.context?.isRead);
    }

    // Apply search query
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase();
      results = results.filter(
        (e) =>
          e.title.toLowerCase().includes(query) ||
          e.summary.toLowerCase().includes(query) ||
          e.sender?.name?.toLowerCase().includes(query) ||
          e.sender?.email?.toLowerCase().includes(query)
      );
    }

    return results;
  }, [emails, activeFilter, searchQuery]);

  const handleFilterChange = (filter: FilterType) => {
    HapticService.selection();
    setActiveFilter(filter);
  };

  const handleSelectEmail = (card: EmailCard) => {
    HapticService.selection();
    onSelectEmail(card);
  };

  const renderEmailItem = useCallback(
    ({ item }: { item: EmailCard }) => (
      <Pressable style={styles.emailItem} onPress={() => handleSelectEmail(item)}>
        <View style={styles.emailContent}>
          <View style={styles.emailHeader}>
            <Text style={styles.emailSender} numberOfLines={1}>
              {item.sender?.name || item.sender?.email || 'Unknown'}
            </Text>
            <Text style={styles.emailTime}>{item.timeAgo}</Text>
          </View>
          <Text style={styles.emailTitle} numberOfLines={1}>
            {item.title}
          </Text>
          <Text style={styles.emailSummary} numberOfLines={2}>
            {item.summary}
          </Text>
        </View>
        <Ionicons name="chevron-forward" size={18} color="rgba(255,255,255,0.3)" />
      </Pressable>
    ),
    []
  );

  if (!visible) return null;

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {Platform.OS === 'ios' ? (
        <BlurView intensity={80} tint="dark" style={StyleSheet.absoluteFill} />
      ) : (
        <View style={[StyleSheet.absoluteFill, styles.androidFallback]} />
      )}

      {/* Header */}
      <View style={styles.header}>
        <View style={styles.searchBar}>
          <Ionicons name="search" size={20} color="rgba(255,255,255,0.5)" />
          <TextInput
            style={styles.searchInput}
            placeholder="Search emails..."
            placeholderTextColor="rgba(255,255,255,0.4)"
            value={searchQuery}
            onChangeText={setSearchQuery}
            autoFocus
            returnKeyType="search"
          />
          {searchQuery.length > 0 && (
            <Pressable onPress={() => setSearchQuery('')}>
              <Ionicons name="close-circle" size={18} color="rgba(255,255,255,0.5)" />
            </Pressable>
          )}
        </View>
        <Pressable onPress={onClose} style={styles.cancelButton}>
          <Text style={styles.cancelText}>Cancel</Text>
        </Pressable>
      </View>

      {/* Filters */}
      <View style={styles.filters}>
        {FILTERS.map((filter) => (
          <Pressable
            key={filter.id}
            style={[
              styles.filterChip,
              activeFilter === filter.id && styles.filterChipActive,
            ]}
            onPress={() => handleFilterChange(filter.id)}
          >
            <Ionicons
              name={filter.icon}
              size={14}
              color={activeFilter === filter.id ? '#667eea' : 'rgba(255,255,255,0.6)'}
            />
            <Text
              style={[
                styles.filterText,
                activeFilter === filter.id && styles.filterTextActive,
              ]}
            >
              {filter.label}
            </Text>
          </Pressable>
        ))}
      </View>

      {/* Results */}
      <FlatList
        data={filteredEmails}
        keyExtractor={(item) => item.id}
        renderItem={renderEmailItem}
        contentContainerStyle={styles.list}
        showsVerticalScrollIndicator={false}
        ListEmptyComponent={
          <View style={styles.emptyState}>
            <Ionicons name="search-outline" size={48} color="rgba(255,255,255,0.3)" />
            <Text style={styles.emptyText}>No emails found</Text>
            <Text style={styles.emptySubtext}>
              Try adjusting your search or filters
            </Text>
          </View>
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a1a',
  },
  androidFallback: {
    backgroundColor: '#0a0a1a',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    gap: 12,
  },
  searchBar: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 12,
    paddingHorizontal: 12,
    height: 44,
    gap: 8,
  },
  searchInput: {
    flex: 1,
    fontSize: 16,
    color: 'white',
  },
  cancelButton: {
    paddingVertical: 8,
    paddingHorizontal: 4,
  },
  cancelText: {
    fontSize: 16,
    color: '#667eea',
  },
  filters: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    paddingBottom: 12,
    gap: 8,
  },
  filterChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingVertical: 6,
    paddingHorizontal: 12,
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 20,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
  },
  filterChipActive: {
    backgroundColor: 'rgba(102, 126, 234, 0.2)',
    borderColor: 'rgba(102, 126, 234, 0.5)',
  },
  filterText: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.6)',
  },
  filterTextActive: {
    color: '#667eea',
    fontWeight: '600',
  },
  list: {
    paddingHorizontal: 16,
    paddingBottom: 100,
  },
  emailItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 14,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
  },
  emailContent: {
    flex: 1,
  },
  emailHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  emailSender: {
    fontSize: 14,
    fontWeight: '600',
    color: 'white',
    flex: 1,
    marginRight: 8,
  },
  emailTime: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.4)',
  },
  emailTitle: {
    fontSize: 15,
    fontWeight: '500',
    color: 'rgba(255,255,255,0.9)',
    marginBottom: 4,
  },
  emailSummary: {
    fontSize: 13,
    color: 'rgba(255,255,255,0.5)',
    lineHeight: 18,
  },
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
  },
  emptyText: {
    fontSize: 18,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.6)',
    marginTop: 16,
  },
  emptySubtext: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.4)',
    marginTop: 4,
  },
});

