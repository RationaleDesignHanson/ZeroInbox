/**
 * @zero/api - API client and hooks
 * Provides API integration for email operations
 */

export const API_VERSION = '2.0.0';

// API client configuration
interface APIConfig {
  baseUrl: string;
  timeout: number;
  authToken?: string;
}

let apiConfig: APIConfig = {
  baseUrl: 'https://api.zeroinbox.app',
  timeout: 30000,
};

// Initialize the API client
export function initializeAPIClient(config: Partial<APIConfig>) {
  apiConfig = { ...apiConfig, ...config };
}

// Get current config
export function getAPIConfig(): APIConfig {
  return { ...apiConfig };
}

// Set auth token
export function setAuthToken(token: string | undefined) {
  apiConfig.authToken = token;
}

// Generic fetch wrapper with error handling
async function apiFetch<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const url = `${apiConfig.baseUrl}${endpoint}`;
  
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  if (apiConfig.authToken) {
    headers['Authorization'] = `Bearer ${apiConfig.authToken}`;
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), apiConfig.timeout);

  try {
    const response = await fetch(url, {
      ...options,
      headers,
      signal: controller.signal,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new APIError(response.status, error.message || 'Request failed', error);
    }

    return response.json();
  } finally {
    clearTimeout(timeout);
  }
}

// Custom API Error class
export class APIError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public details?: Record<string, unknown>
  ) {
    super(message);
    this.name = 'APIError';
  }
}

// Types for API responses
export interface EmailListResponse {
  items: EmailItem[];
  nextCursor?: string;
  totalCount: number;
}

export interface EmailItem {
  id: string;
  title: string;
  summary: string;
  body?: string;
  sender: {
    name: string;
    email: string;
  };
  timeAgo: string;
  priority: 'high' | 'medium' | 'low';
  type: 'mail' | 'ads';
  intent?: string;
  suggestedActions?: SuggestedAction[];
  threadLength?: number;
  context?: Record<string, string>;
}

export interface SuggestedAction {
  id: string;
  displayName: string;
  isPrimary?: boolean;
  context?: Record<string, string>;
}

export interface UnreadCounts {
  mail: number;
  ads: number;
}

// API Functions

/**
 * Fetch emails from the inbox
 */
export async function fetchEmails(options?: {
  type?: 'mail' | 'ads';
  cursor?: string;
  limit?: number;
}): Promise<EmailListResponse> {
  const params = new URLSearchParams();
  if (options?.type) params.append('type', options.type);
  if (options?.cursor) params.append('cursor', options.cursor);
  if (options?.limit) params.append('limit', options.limit.toString());

  const query = params.toString();
  const endpoint = `/emails${query ? `?${query}` : ''}`;

  return apiFetch<EmailListResponse>(endpoint);
}

/**
 * Fetch a single email by ID
 */
export async function fetchEmail(emailId: string): Promise<EmailItem> {
  return apiFetch<EmailItem>(`/emails/${emailId}`);
}

/**
 * Execute an action on an email
 */
export async function executeAction(
  emailId: string,
  actionId: string,
  context?: Record<string, unknown>
): Promise<{ success: boolean; message?: string }> {
  return apiFetch<{ success: boolean; message?: string }>(`/emails/${emailId}/actions`, {
    method: 'POST',
    body: JSON.stringify({ actionId, context }),
  });
}

/**
 * Archive an email
 */
export async function archiveEmail(emailId: string): Promise<{ success: boolean }> {
  return apiFetch<{ success: boolean }>(`/emails/${emailId}/archive`, {
    method: 'POST',
  });
}

/**
 * Snooze an email
 */
export async function snoozeEmail(
  emailId: string,
  duration: number
): Promise<{ success: boolean }> {
  return apiFetch<{ success: boolean }>(`/emails/${emailId}/snooze`, {
    method: 'POST',
    body: JSON.stringify({ duration }),
  });
}

/**
 * Send a reply
 */
export async function sendReply(
  emailId: string,
  message: string
): Promise<{ success: boolean }> {
  return apiFetch<{ success: boolean }>(`/emails/${emailId}/reply`, {
    method: 'POST',
    body: JSON.stringify({ message }),
  });
}

/**
 * Refresh inbox (fetch new emails)
 */
export async function refreshInbox(): Promise<{ count: number }> {
  return apiFetch<{ count: number }>('/emails/refresh', {
    method: 'POST',
  });
}

/**
 * Get unread counts
 */
export async function getUnreadCounts(): Promise<UnreadCounts> {
  return apiFetch<UnreadCounts>('/emails/unread-counts');
}

// React Query-style hooks (placeholders that work without React Query)
// In a real implementation, these would use @tanstack/react-query

export function useEmails() {
  return {
    data: [] as EmailItem[],
    isLoading: false,
    error: null,
    refetch: async () => {},
  };
}

export function useInbox(_options?: { type?: string }) {
  return {
    data: {
      items: [] as EmailItem[],
      unreadCounts: { mail: 0, ads: 0 },
    },
    isLoading: false,
    isError: false,
    refetch: async () => {},
  };
}

export function useRefreshInbox() {
  return {
    mutateAsync: async () => {},
    isPending: false,
  };
}

export function usePerformAction() {
  return {
    mutate: async () => {},
    isLoading: false,
    error: null,
  };
}

export function useUserSettings() {
  return {
    data: null,
    isLoading: false,
    error: null,
  };
}

// Fetch single email by ID
export function useEmail(emailId: string) {
  const mockEmail = emailId
    ? {
        id: emailId,
        title: 'Loading...',
        summary: 'Email content loading...',
        body: 'Full email body would appear here when loaded from the server.',
        sender: {
          name: 'Loading',
          email: 'loading@example.com',
        },
        timeAgo: 'Just now',
        priority: 'medium' as const,
        type: 'mail' as const,
        suggestedActions: [],
        threadLength: 1,
      }
    : null;

  return {
    data: mockEmail,
    isLoading: false,
    isError: false,
    error: null,
    refetch: async () => {},
  };
}

// Execute an action on an email
export function useExecuteAction() {
  return {
    mutate: async (data: {
      emailId: string;
      actionId: string;
      context?: Record<string, unknown>;
    }) => {
      console.log('Executing action:', data);
      return { success: true };
    },
    mutateAsync: async (data: {
      emailId: string;
      actionId: string;
      context?: Record<string, unknown>;
    }) => {
      console.log('Executing action (async):', data);
      return { success: true };
    },
    isLoading: false,
    isPending: false,
    error: null,
  };
}
