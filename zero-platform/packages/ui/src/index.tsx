/**
 * @zero/ui - Shared UI components
 * Cross-platform UI components for Zero
 */

import React, { createContext, useContext } from 'react';
import { View, Text, ActivityIndicator, StyleSheet, TouchableOpacity } from 'react-native';

export const UI_VERSION = '1.0.0';

// Design tokens
export const tokens = {
  spacing: {
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    element: 12,
    component: 16,
    section: 24,
    card: 20,
    inline: 8,
    tight: 4,
  },
  borderRadius: {
    sm: 4,
    md: 8,
    lg: 16,
    xl: 24,
    full: 9999,
  },
  fontSize: {
    xs: 10,
    sm: 12,
    md: 14,
    lg: 16,
    xl: 20,
    xxl: 24,
    xxxl: 32,
  },
};

// Typography styles
export const typography = {
  displayLarge: {
    fontSize: 32,
    fontWeight: '700' as const,
    lineHeight: 40,
    letterSpacing: -0.5,
  },
  displayMedium: {
    fontSize: 28,
    fontWeight: '700' as const,
    lineHeight: 36,
    letterSpacing: -0.3,
  },
  displaySmall: {
    fontSize: 24,
    fontWeight: '600' as const,
    lineHeight: 32,
  },
  headlineMedium: {
    fontSize: 20,
    fontWeight: '600' as const,
    lineHeight: 28,
  },
  bodyLarge: {
    fontSize: 16,
    fontWeight: '400' as const,
    lineHeight: 24,
  },
  bodyMedium: {
    fontSize: 14,
    fontWeight: '400' as const,
    lineHeight: 20,
  },
  bodySmall: {
    fontSize: 12,
    fontWeight: '400' as const,
    lineHeight: 16,
  },
  labelLarge: {
    fontSize: 14,
    fontWeight: '600' as const,
    lineHeight: 20,
  },
  labelMedium: {
    fontSize: 12,
    fontWeight: '500' as const,
    lineHeight: 16,
  },
  labelSmall: {
    fontSize: 11,
    fontWeight: '500' as const,
    lineHeight: 14,
  },
};

// Color palette
export const colors = {
  // Primary colors
  primary: '#667eea',
  secondary: '#764ba2',
  success: '#22c55e',
  warning: '#eab308',
  error: '#ef4444',
  info: '#3b82f6',
  
  // Background colors
  background: '#0a0a0f',
  backgroundDark: '#050508',
  surface: '#1a1a2e',
  
  // Text colors
  text: '#ffffff',
  textSecondary: '#a0a0b0',
  textSubtle: '#6b6b7b',
  
  // Border colors
  border: '#2a2a3e',
  borderSubtle: '#1a1a2e',
  
  // Gradient colors
  mailGradientStart: '#667eea',
  mailGradientEnd: '#764ba2',
  adsGradientStart: '#f59e0b',
  adsGradientEnd: '#ef4444',
};

// Spacing export for backwards compatibility
export const spacing = tokens.spacing;

// Theme context
interface Theme {
  colors: {
    text: {
      primary: string;
      secondary: string;
      tertiary: string;
    };
    background: {
      primary: string;
      secondary: string;
      tertiary: string;
    };
    accent: {
      primary: string;
      secondary: string;
    };
  };
  mode: 'mail' | 'ads';
}

const mailTheme: Theme = {
  colors: {
    text: {
      primary: colors.text,
      secondary: colors.textSecondary,
      tertiary: colors.textSubtle,
    },
    background: {
      primary: colors.background,
      secondary: colors.surface,
      tertiary: colors.backgroundDark,
    },
    accent: {
      primary: colors.mailGradientStart,
      secondary: colors.mailGradientEnd,
    },
  },
  mode: 'mail',
};

const adsTheme: Theme = {
  colors: {
    text: {
      primary: colors.text,
      secondary: colors.textSecondary,
      tertiary: colors.textSubtle,
    },
    background: {
      primary: colors.background,
      secondary: colors.surface,
      tertiary: colors.backgroundDark,
    },
    accent: {
      primary: colors.adsGradientStart,
      secondary: colors.adsGradientEnd,
    },
  },
  mode: 'ads',
};

const ThemeContext = createContext<Theme>(mailTheme);

export function useTheme(): Theme {
  return useContext(ThemeContext);
}

// Screen wrapper component
export function Screen({ children }: { children: React.ReactNode }) {
  return (
    <View style={screenStyles.container}>
      {children}
    </View>
  );
}

const screenStyles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
});

// ThemeProvider component
export function ThemeProvider({ 
  children, 
  mode = 'mail' 
}: { 
  children: React.ReactNode;
  mode?: 'mail' | 'ads';
}) {
  const theme = mode === 'ads' ? adsTheme : mailTheme;
  return (
    <ThemeContext.Provider value={theme}>
      {children}
    </ThemeContext.Provider>
  );
}

// Card component
export function Card({ 
  children,
  variant = 'default',
  padding = 'default',
}: { 
  children: React.ReactNode;
  variant?: 'default' | 'glass' | 'elevated';
  padding?: 'none' | 'minimal' | 'default' | 'large';
}) {
  const paddingValue = {
    none: 0,
    minimal: tokens.spacing.xs,
    default: tokens.spacing.md,
    large: tokens.spacing.lg,
  }[padding];

  const variantStyle = {
    default: cardComponentStyles.default,
    glass: cardComponentStyles.glass,
    elevated: cardComponentStyles.elevated,
  }[variant];

  return (
    <View style={[cardComponentStyles.base, variantStyle, { padding: paddingValue }]}>
      {children}
    </View>
  );
}

const cardComponentStyles = StyleSheet.create({
  base: {
    borderRadius: tokens.borderRadius.lg,
    overflow: 'hidden',
  },
  default: {
    backgroundColor: colors.surface,
  },
  glass: {
    backgroundColor: 'rgba(26, 26, 46, 0.6)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  elevated: {
    backgroundColor: colors.surface,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
});

// Stack component for layout
export function Stack({ 
  children,
  direction = 'vertical',
  spacing: stackSpacing = 'md',
  align = 'stretch',
}: { 
  children: React.ReactNode;
  direction?: 'horizontal' | 'vertical';
  spacing?: keyof typeof tokens.spacing;
  align?: 'start' | 'center' | 'end' | 'stretch';
}) {
  const alignMap = {
    start: 'flex-start' as const,
    center: 'center' as const,
    end: 'flex-end' as const,
    stretch: 'stretch' as const,
  };

  return (
    <View style={{
      flexDirection: direction === 'horizontal' ? 'row' : 'column',
      gap: tokens.spacing[stackSpacing],
      alignItems: alignMap[align],
    }}>
      {children}
    </View>
  );
}

// InboxHeader component
export function InboxHeader({ 
  mode: _mode = 'mail',
  unreadCount: _unreadCount = 0,
  onModeChange: _onModeChange,
  onSearchPress: _onSearchPress,
  onSettingsPress: _onSettingsPress,
}: { 
  mode?: 'mail' | 'ads';
  unreadCount?: number;
  onModeChange?: (mode: 'mail' | 'ads') => void;
  onSearchPress?: () => void;
  onSettingsPress?: () => void;
}) {
  return (
    <View style={headerStyles.container}>
      <Text style={headerStyles.title}>Inbox</Text>
    </View>
  );
}

const headerStyles = StyleSheet.create({
  container: {
    padding: tokens.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  title: {
    fontSize: tokens.fontSize.xl,
    fontWeight: '600',
    color: colors.text,
  },
});

// EmailCard component
export function EmailCard({ 
  email,
  onPress,
  showActions: _showActions = false,
}: { 
  email: { id: string; title?: string; summary?: string };
  onPress?: () => void;
  showActions?: boolean;
}) {
  return (
    <TouchableOpacity style={cardStyles.container} onPress={onPress} activeOpacity={0.7}>
      <Text style={cardStyles.title}>
        {email.title || 'Untitled'}
      </Text>
      <Text style={cardStyles.summary}>{email.summary || ''}</Text>
    </TouchableOpacity>
  );
}

const cardStyles = StyleSheet.create({
  container: {
    padding: tokens.spacing.md,
    backgroundColor: colors.surface,
    borderRadius: tokens.borderRadius.lg,
    marginBottom: tokens.spacing.sm,
  },
  title: {
    fontSize: tokens.fontSize.lg,
    fontWeight: '600',
    color: colors.text,
    marginBottom: tokens.spacing.xs,
  },
  summary: {
    fontSize: tokens.fontSize.md,
    color: colors.textSecondary,
  },
});

// LoadingSpinner component
export function LoadingSpinner({ message }: { message?: string }) {
  return (
    <View style={spinnerStyles.container}>
      <ActivityIndicator size="large" color={colors.primary} />
      {message && <Text style={spinnerStyles.message}>{message}</Text>}
    </View>
  );
}

const spinnerStyles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.background,
  },
  message: {
    marginTop: tokens.spacing.md,
    fontSize: tokens.fontSize.md,
    color: colors.textSecondary,
  },
});

// EmptyState component
export function EmptyState({ 
  title, 
  message,
  actionLabel,
  onAction,
}: { 
  title: string;
  message?: string;
  actionLabel?: string;
  onAction?: () => void;
}) {
  return (
    <View style={emptyStyles.container}>
      <Text style={emptyStyles.title}>{title}</Text>
      {message && <Text style={emptyStyles.message}>{message}</Text>}
      {actionLabel && onAction && (
        <TouchableOpacity onPress={onAction}>
          <Text style={emptyStyles.action}>{actionLabel}</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

const emptyStyles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: tokens.spacing.xl,
    backgroundColor: colors.background,
  },
  title: {
    fontSize: tokens.fontSize.xl,
    fontWeight: '600',
    color: colors.text,
    textAlign: 'center',
    marginBottom: tokens.spacing.sm,
  },
  message: {
    fontSize: tokens.fontSize.md,
    color: colors.textSecondary,
    textAlign: 'center',
  },
  action: {
    marginTop: tokens.spacing.lg,
    fontSize: tokens.fontSize.md,
    color: colors.primary,
    fontWeight: '600',
  },
});
