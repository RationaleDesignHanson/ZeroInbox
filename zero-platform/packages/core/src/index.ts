/**
 * @zero/core - Core business logic
 * Placeholder for shared platform-agnostic business logic
 */

export const VERSION = '1.0.0';

// Intent classification utilities
export const intentCategories = {
  'e-commerce': ['shipping', 'order', 'return', 'refund'],
  'billing': ['invoice', 'payment', 'receipt', 'subscription'],
  'security': ['two_factor', 'password_reset', 'fraud_alert', 'login_alert'],
  'marketing': ['promotion', 'newsletter', 'announcement'],
  'social': ['mention', 'message', 'follow', 'comment'],
} as const;

// Priority calculation helpers
export function calculatePriority(
  intent?: string,
  isVIP?: boolean,
  hasSecurityFlag?: boolean
): 'critical' | 'high' | 'medium' | 'low' {
  if (hasSecurityFlag || intent?.startsWith('security')) return 'critical';
  if (isVIP) return 'high';
  if (intent?.includes('billing') || intent?.includes('order')) return 'medium';
  return 'low';
}

