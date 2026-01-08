/**
 * @zero/api - API client and hooks
 * Placeholder for API integration
 */

export const API_VERSION = '1.0.0';

// API client configuration
let apiConfig = {
  baseUrl: 'https://api.zeroinbox.app',
  timeout: 30000,
};

// Initialize the API client
export function initializeAPIClient(config: { baseUrl?: string; timeout?: number }) {
  apiConfig = { ...apiConfig, ...config };
}

// Get current config
export function getAPIConfig() {
  return apiConfig;
}

// Placeholder hooks - will be implemented when backend is ready
export function useEmails() {
  return {
    data: [],
    isLoading: false,
    error: null,
    refetch: async () => {},
  };
}

export function useInbox(_options?: { type?: string }) {
  return {
    data: { 
      items: [],
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
  // In production, this would use React Query to fetch from API
  // For now, return a mock email for demo purposes
  const mockEmail = emailId ? {
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
  } : null;

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
    mutate: async (data: { emailId: string; actionId: string; context?: Record<string, unknown> }) => {
      console.log('Executing action:', data);
      // In production, this would call the API
      return { success: true };
    },
    mutateAsync: async (data: { emailId: string; actionId: string; context?: Record<string, unknown> }) => {
      console.log('Executing action (async):', data);
      // In production, this would call the API
      return { success: true };
    },
    isLoading: false,
    isPending: false,
    error: null,
  };
}
