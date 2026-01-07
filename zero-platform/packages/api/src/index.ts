/**
 * @zero/api - API client and hooks
 * Placeholder for API integration
 */

export const API_VERSION = '1.0.0';

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
    data: { items: [] },
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
