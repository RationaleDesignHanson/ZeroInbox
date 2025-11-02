import Foundation
import Combine
import UIKit

/// Manages multiple email accounts and account switching
@MainActor
class AccountManager: ObservableObject {
    @Published var accounts: [EmailAccount] = []
    @Published var activeAccount: EmailAccount?
    @Published var showAllAccounts: Bool = true // Unified inbox mode
    @Published var isLoadingAccounts: Bool = false
    @Published var errorMessage: String?

    private let baseURL: String
    private var cancellables = Set<AnyCancellable>()

    init(baseURL: String = AppEnvironment.current.gatewayBaseURL) {
        self.baseURL = baseURL
        loadAccountsFromStorage()
    }

    // MARK: - Account Management

    /// Load accounts from UserDefaults (cached)
    func loadAccountsFromStorage() {
        if let data = UserDefaults.standard.data(forKey: "cachedAccounts"),
           let decoded = try? JSONDecoder().decode([EmailAccount].self, from: data) {
            accounts = decoded
            activeAccount = accounts.first(where: { $0.isPrimary }) ?? accounts.first
            Logger.info("Loaded \(accounts.count) accounts from cache", category: .app)
        }
    }

    /// Save accounts to UserDefaults (cache)
    func saveAccountsToStorage() {
        if let encoded = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(encoded, forKey: "cachedAccounts")
            Logger.info("Saved \(accounts.count) accounts to cache", category: .app)
        }
    }

    /// Fetch accounts from backend
    func fetchAccounts(userId: String) async {
        isLoadingAccounts = true
        errorMessage = nil

        do {
            let url = URL(string: "\(baseURL)/api/auth/accounts?userId=\(userId)")!
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch accounts"])
            }

            let json = try JSONDecoder().decode(AccountsResponse.self, from: data)
            accounts = json.accounts
            activeAccount = accounts.first(where: { $0.isPrimary }) ?? accounts.first

            saveAccountsToStorage()
            Logger.info("Fetched \(accounts.count) accounts from backend", category: .app)

        } catch {
            errorMessage = "Failed to load accounts: \(error.localizedDescription)"
            Logger.error("Failed to fetch accounts", category: .app, error: error)
        }

        isLoadingAccounts = false
    }

    /// Add a new account (trigger OAuth flow)
    func addAccount(userId: String) async {
        // Open OAuth URL for adding account
        let urlString = "\(baseURL)/api/auth/gmail/add?userId=\(userId)&isAdditional=true"
        if let url = URL(string: urlString) {
            await openURL(url)
        }
    }

    /// Remove an account
    func removeAccount(_ account: EmailAccount, userId: String) async {
        errorMessage = nil

        do {
            var request = URLRequest(url: URL(string: "\(baseURL)/api/auth/accounts/\(account.id)?userId=\(userId)")!)
            request.httpMethod = "DELETE"

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to remove account"])
            }

            // Remove from local list
            accounts.removeAll(where: { $0.id == account.id })

            // If removed account was active, switch to another
            if activeAccount?.id == account.id {
                activeAccount = accounts.first(where: { $0.isPrimary }) ?? accounts.first
            }

            saveAccountsToStorage()
            Logger.info("Removed account: \(account.email)", category: .app)

        } catch {
            errorMessage = "Failed to remove account: \(error.localizedDescription)"
            Logger.error("Failed to remove account", category: .app, error: error)
        }
    }

    /// Switch to a specific account
    func switchToAccount(_ account: EmailAccount) {
        activeAccount = account
        showAllAccounts = false
        Logger.info("Switched to account: \(account.email)", category: .app)
    }

    /// Toggle unified inbox mode
    func toggleUnifiedInbox() {
        showAllAccounts.toggle()
        if showAllAccounts {
            activeAccount = nil
            Logger.info("Unified inbox enabled", category: .app)
        } else {
            activeAccount = accounts.first(where: { $0.isPrimary }) ?? accounts.first
            Logger.info("Single account mode: \(activeAccount?.email ?? "none")", category: .app)
        }
    }

    /// Set an account as primary
    func setPrimaryAccount(_ account: EmailAccount, userId: String) async {
        errorMessage = nil

        do {
            var request = URLRequest(url: URL(string: "\(baseURL)/api/auth/accounts/\(account.id)/set-primary?userId=\(userId)")!)
            request.httpMethod = "PATCH"

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to set primary account"])
            }

            // Update local accounts
            accounts = accounts.map { a in
                var updated = a
                updated.isPrimary = (a.id == account.id)
                return updated
            }

            activeAccount = account
            saveAccountsToStorage()
            Logger.info("Set primary account: \(account.email)", category: .app)

        } catch {
            errorMessage = "Failed to set primary account: \(error.localizedDescription)"
            Logger.error("Failed to set primary account", category: .app, error: error)
        }
    }

    /// Enable or disable an account
    func toggleAccountEnabled(_ account: EmailAccount, userId: String) async {
        errorMessage = nil
        let newEnabledState = !account.enabled

        do {
            var request = URLRequest(url: URL(string: "\(baseURL)/api/auth/accounts/\(account.id)?userId=\(userId)")!)
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = ["enabled": newEnabledState]
            request.httpBody = try JSONEncoder().encode(body)

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to toggle account"])
            }

            // Update local account
            if let index = accounts.firstIndex(where: { $0.id == account.id }) {
                accounts[index].enabled = newEnabledState
            }

            saveAccountsToStorage()
            Logger.info("Toggled account \(account.email): \(newEnabledState ? "enabled" : "disabled")", category: .app)

        } catch {
            errorMessage = "Failed to toggle account: \(error.localizedDescription)"
            Logger.error("Failed to toggle account", category: .app, error: error)
        }
    }

    /// Sync a specific account
    func syncAccount(_ account: EmailAccount, userId: String) async {
        errorMessage = nil

        do {
            var request = URLRequest(url: URL(string: "\(baseURL)/api/auth/accounts/\(account.id)/sync?userId=\(userId)")!)
            request.httpMethod = "POST"

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to sync account"])
            }

            // Update last synced timestamp
            if let index = accounts.firstIndex(where: { $0.id == account.id }) {
                accounts[index].lastSynced = Date()
            }

            saveAccountsToStorage()
            Logger.info("Synced account: \(account.email)", category: .app)

        } catch {
            errorMessage = "Failed to sync account: \(error.localizedDescription)"
            Logger.error("Failed to sync account", category: .app, error: error)
        }
    }

    // MARK: - Utilities

    /// Get total unread count across all enabled accounts
    var totalUnreadCount: Int {
        accounts.filter { $0.enabled }.compactMap { $0.unreadCount }.reduce(0, +)
    }

    /// Check if user has multiple accounts
    var hasMultipleAccounts: Bool {
        accounts.count > 1
    }

    /// Get enabled accounts
    var enabledAccounts: [EmailAccount] {
        accounts.filter { $0.enabled }
    }

    /// Open URL (for OAuth)
    private func openURL(_ url: URL) async {
        #if canImport(UIKit)
        await UIApplication.shared.open(url)
        #endif
    }
}

// MARK: - Response Models

struct AccountsResponse: Codable {
    let accounts: [EmailAccount]
}
