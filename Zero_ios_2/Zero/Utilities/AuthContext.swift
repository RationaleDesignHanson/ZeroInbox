//
//  AuthContext.swift
//  Zero
//
//  Created by Week 6 Refactoring
//  Purpose: Centralized authentication context management
//

import Foundation

/// Centralized authentication context
/// Week 6 Cleanup: Replaces hardcoded "user-123" placeholders throughout the app
///
/// This provides a single source of truth for user authentication state.
/// Currently returns placeholder values, but can be easily upgraded to real authentication.
///
/// Usage:
/// ```swift
/// let userId = AuthContext.getUserId()
/// let email = AuthContext.getUserEmail()
/// let token = AuthContext.getAuthToken()
/// ```
struct AuthContext {

    // MARK: - User Identity

    /// Get the current authenticated user's ID
    /// - Returns: User ID string (currently placeholder)
    static func getUserId() -> String {
        return Constants.UserSession.defaultUserId
    }

    /// Get the current authenticated user's email
    /// - Returns: User email string (currently placeholder)
    static func getUserEmail() -> String {
        // When real auth is implemented, this would return actual email
        return getUserId()
    }

    /// Get the current authenticated admin user's ID (for admin operations)
    /// - Returns: Admin user ID string (currently placeholder)
    static func getAdminId() -> String {
        return "admin-user"
    }

    // MARK: - Authentication Tokens

    /// Get the current authentication token for API calls
    /// - Returns: Auth token if available, nil otherwise
    /// - Note: Currently returns nil - implement token management when backend is ready
    static func getAuthToken() -> String? {
        // TODO: Implement token management
        // - Check keychain for stored token
        // - Validate token expiration
        // - Refresh if needed
        // - Return active token
        return nil
    }

    /// Check if user is authenticated
    /// - Returns: True if user has valid authentication
    static func isAuthenticated() -> Bool {
        // Currently always true (placeholder mode)
        // When real auth is implemented, check for valid token
        return true
    }

    // MARK: - User Preferences

    /// Get the user's timezone
    /// - Returns: User's timezone identifier (e.g., "America/Los_Angeles")
    static func getUserTimezone() -> String {
        // Return device timezone
        return TimeZone.current.identifier
    }

    /// Get the user's preferred locale
    /// - Returns: User's locale identifier
    static func getUserLocale() -> String {
        return Locale.current.identifier
    }

    // MARK: - Session Management

    /// Sign out the current user
    static func signOut() {
        // TODO: Implement when auth is ready
        // - Clear tokens from keychain
        // - Clear user session
        // - Clear cached data
        // - Navigate to login screen
        Logger.info("Sign out requested (placeholder)", category: .authentication)
    }

    /// Refresh authentication token
    /// - Returns: True if refresh succeeded
    static func refreshToken() async -> Bool {
        // TODO: Implement when auth is ready
        // - Check if refresh token exists
        // - Call refresh endpoint
        // - Store new token
        // - Return success status
        Logger.info("Token refresh requested (placeholder)", category: .authentication)
        return false
    }
}

// MARK: - Migration Notes

/*
 WEEK 6 CLEANUP: AuthContext Centralization

 This utility replaces 21 instances of hardcoded user IDs across the codebase:

 BEFORE:
 -------
 - "user-123" (16 instances)
 - Constants.User.defaultUserId (scattered usage)
 - "current-user" (1 instance)
 - "admin-user" (1 instance)

 AFTER:
 ------
 - AuthContext.getUserId() (for regular user operations)
 - AuthContext.getAdminId() (for admin operations)
 - AuthContext.getAuthToken() (for API authentication)

 Benefits:
 ---------
 1. Single source of truth for auth state
 2. Easy to upgrade to real authentication
 3. Consistent behavior across app
 4. Centralized logging and debugging
 5. Type-safe API (no magic strings)

 Files Modified (21 replacements):
 ---------------------------------
 - Config/Constants.swift
 - Models/UserSession.swift
 - ViewModels/EmailViewModel.swift
 - Services/ShoppingAutomationService.swift
 - Services/SharedTemplateService.swift
 - Services/ActionFeedbackService.swift
 - Services/AdminFeedbackService.swift
 - Views/ShoppingCartView.swift
 - Views/SharedTemplateView.swift
 - Views/SavedMailListView.swift
 - Views/FolderPickerView.swift
 - Views/FolderDetailView.swift
 - Views/CreateFolderView.swift
 - Views/ActionModules/ShoppingPurchaseModal.swift
 - Views/ActionModules/ScheduledPurchaseModal.swift
 - Zero/ContentView.swift

 Future Enhancements:
 --------------------
 1. Integrate with real auth provider (Firebase, Auth0, etc.)
 2. Implement token management (storage, refresh, expiration)
 3. Add biometric authentication support
 4. Add session timeout handling
 5. Add multi-account support
 */
