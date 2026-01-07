/**
 * Tabs Layout
 * Bottom tab navigation for main app sections
 */

import { Tabs } from 'expo-router';
import { Platform } from 'react-native';
import { tokens, colors } from '@zero/ui';

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          backgroundColor: colors.backgroundDark,
          borderTopColor: colors.borderSubtle,
          borderTopWidth: 1,
          paddingTop: 8,
          paddingBottom: Platform.OS === 'ios' ? 24 : 8,
          height: Platform.OS === 'ios' ? 88 : 64,
        },
        tabBarActiveTintColor: colors.mailGradientStart,
        tabBarInactiveTintColor: colors.textSubtle,
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '600',
        },
      }}
    >
      <Tabs.Screen
        name="inbox"
        options={{
          title: 'Inbox',
          tabBarIcon: ({ color, size }) => (
            <TabIcon name="inbox" color={color} size={size} />
          ),
        }}
      />
      <Tabs.Screen
        name="ads"
        options={{
          title: 'Ads',
          tabBarIcon: ({ color, size }) => (
            <TabIcon name="ads" color={color} size={size} />
          ),
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: 'Settings',
          tabBarIcon: ({ color, size }) => (
            <TabIcon name="settings" color={color} size={size} />
          ),
        }}
      />
    </Tabs>
  );
}

// Simple tab icon component
function TabIcon({ name, color, size }: { name: string; color: string; size: number }) {
  const { Text } = require('react-native');
  const icons: Record<string, string> = {
    inbox: '📬',
    ads: '🏷️',
    settings: '⚙️',
  };

  return (
    <Text style={{ fontSize: size, color }}>{icons[name] || '•'}</Text>
  );
}

