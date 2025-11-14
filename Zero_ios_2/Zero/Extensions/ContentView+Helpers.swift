import SwiftUI

/**
 * ContentView+Helpers
 * Helper methods extracted from ContentView to reduce complexity
 *
 * Phase 2 (Option 2): CLI-safe helper extraction
 */
extension ContentView {

    // MARK: - User Authentication

    /// Get current authenticated user email
    func getUserEmail() -> String? {
        // Check if using mock data
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")
        if useMockData {
            return nil // Mock mode, don't show email
        }

        // Try to get email from Keychain (from authenticated session)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "EmailShortForm",
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let attributes = result as? [String: Any],
           let emailData = attributes[kSecAttrAccount as String] as? String {
            return emailData
        }

        return nil
    }

    // MARK: - Shopping Cart

    /// Load shopping cart item count from persistent storage
    func loadCartItemCount() async {
        // Simulate async cart count fetch
        // In production, this would query the shopping cart service
        await MainActor.run {
            // Default to 0 for now - will be populated from real cart service
            viewState.cartItemCount = 0
        }
    }

    // MARK: - Swipe Gestures

    /// Determine swipe direction from drag offset
    func getSwipeDirection(isHorizontal: Bool, dragOffset: CGSize) -> SwipeDirection {
        if isHorizontal {
            return dragOffset.width > 0 ? .right : .left
        } else {
            return .down
        }
    }

    // MARK: - Archetype Checking

    /// Check if all selected archetypes have been cleared (no unseen cards)
    func checkAllArchetypesCleared() -> Bool {
        // Check if ALL selected archetypes have zero unseen cards
        return viewModel.selectedArchetypes.allSatisfy { archetype in
            let archetypeCards = viewModel.cards.filter { $0.type == archetype && $0.state == .unseen }
            return archetypeCards.isEmpty
        }
    }
}
