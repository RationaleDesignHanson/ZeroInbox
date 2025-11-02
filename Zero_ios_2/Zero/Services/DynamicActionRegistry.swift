import Foundation

/**
 * Dynamic Action Registry (Phase 2)
 * Fetches personalized action registry from API based on user's corpus data
 *
 * Features:
 * - API-fetched actions with corpus-driven personalization
 * - 24-hour cache with automatic refresh
 * - Offline fallback to embedded ActionRegistry
 * - User-specific action ranking
 */

// MARK: - API Response Models

struct DynamicActionRegistryResponse: Codable {
    let actions: [DynamicAction]
    let metadata: RegistryMetadata
    let fromCache: Bool?
    let cacheHit: Bool?
}

struct DynamicAction: Codable {
    let actionId: String
    let displayName: String
    let actionType: String  // "GO_TO" or "IN_APP"
    let mode: String  // "mail", "ads", or "both"
    let modalComponent: String?
    let requiredContextKeys: [String]
    let optionalContextKeys: [String]
    let fallbackBehavior: String
    let analyticsEvent: String
    let priority: Int
    let description: String
    let requiredPermission: String
    let userStats: UserActionStats?
}

struct UserActionStats: Codable {
    let frequency: Double
    let lastUsed: String?
    let timesUsed: Int
    let timesSuggested: Int
    let executionRate: Double
    let avgTimeToAction: Int
}

struct RegistryMetadata: Codable {
    let userId: String
    let corpusSize: Int
    let days: Int
    let lastUpdated: String
    let actionsReturned: Int
    let actionsFiltered: Int
    let personalizationApplied: Bool
}

// MARK: - Dynamic Action Registry Manager

@MainActor
class DynamicActionRegistry: ObservableObject {
    static let shared = DynamicActionRegistry()

    @Published var isLoading = false
    @Published var error: String?
    @Published var lastFetched: Date?
    @Published var cacheHit: Bool = false

    // Cached dynamic actions
    private var cachedActions: [DynamicAction] = []
    private var cachedMetadata: RegistryMetadata?

    // Cache expiration (24 hours)
    private let cacheExpirationInterval: TimeInterval = 24 * 60 * 60

    // API Configuration
    private let actionRegistryBaseURL: String

    private init() {
        // Use environment variable or default to localhost
        if let urlString = ProcessInfo.processInfo.environment["ACTION_REGISTRY_URL"] {
            self.actionRegistryBaseURL = urlString
        } else if let urlString = Bundle.main.infoDictionary?["ACTION_REGISTRY_URL"] as? String {
            self.actionRegistryBaseURL = urlString
        } else {
            self.actionRegistryBaseURL = "http://localhost:8085"
        }
    }

    // MARK: - Public API

    /**
     * Fetch personalized action registry from API
     * - Uses cache if available and not expired
     * - Falls back to embedded ActionRegistry on error
     */
    func fetchRegistry(
        for userId: String,
        mode: ZeroMode? = nil,
        days: Int = 30,
        forceRefresh: Bool = false
    ) async -> [ActionConfig] {
        // Check cache first
        if !forceRefresh && isCacheValid() {
            print("📦 Using cached action registry")
            return convertDynamicActionsToConfigs(cachedActions)
        }

        // Fetch from API
        isLoading = true
        error = nil

        do {
            let response = try await fetchFromAPI(
                userId: userId,
                mode: mode,
                days: days
            )

            // Update cache
            cachedActions = response.actions
            cachedMetadata = response.metadata
            lastFetched = Date()
            cacheHit = response.cacheHit ?? false

            print("✅ Fetched \(response.actions.count) personalized actions from API")
            print("   Corpus size: \(response.metadata.corpusSize)")
            print("   Personalization: \(response.metadata.personalizationApplied ? "ON" : "OFF")")
            print("   Cache hit: \(cacheHit ? "YES" : "NO")")

            isLoading = false
            return convertDynamicActionsToConfigs(response.actions)

        } catch {
            self.error = error.localizedDescription
            isLoading = false

            print("⚠️ Failed to fetch dynamic registry: \(error.localizedDescription)")
            print("📱 Falling back to embedded ActionRegistry")

            // Fallback to embedded registry
            return ActionRegistry.shared.registry.values.map { $0 }
        }
    }

    /**
     * Get current registry (cached or embedded)
     */
    func getCurrentRegistry() -> [ActionConfig] {
        if isCacheValid() && !cachedActions.isEmpty {
            return convertDynamicActionsToConfigs(cachedActions)
        }

        // Return embedded registry
        return ActionRegistry.shared.registry.values.map { $0 }
    }

    /**
     * Invalidate cache (force refresh on next fetch)
     */
    func invalidateCache() {
        cachedActions = []
        cachedMetadata = nil
        lastFetched = nil
        cacheHit = false
        print("🗑️ Dynamic action registry cache invalidated")
    }

    /**
     * Check if cache is valid
     */
    func isCacheValid() -> Bool {
        guard let lastFetched = lastFetched else {
            return false
        }

        let elapsed = Date().timeIntervalSince(lastFetched)
        return elapsed < cacheExpirationInterval
    }

    // MARK: - Private Methods

    /**
     * Fetch from API
     */
    private func fetchFromAPI(
        userId: String,
        mode: ZeroMode?,
        days: Int
    ) async throws -> DynamicActionRegistryResponse {
        var components = URLComponents(string: "\(actionRegistryBaseURL)/api/actions/registry")!
        components.queryItems = [
            URLQueryItem(name: "userId", value: userId),
            URLQueryItem(name: "days", value: "\(days)")
        ]

        if let mode = mode {
            components.queryItems?.append(
                URLQueryItem(name: "mode", value: mode.rawValue)
            )
        }

        guard let url = components.url else {
            throw RegistryError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RegistryError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw RegistryError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let registryResponse = try decoder.decode(DynamicActionRegistryResponse.self, from: data)

        return registryResponse
    }

    /**
     * Convert DynamicActions to ActionConfigs
     */
    private func convertDynamicActionsToConfigs(_ dynamicActions: [DynamicAction]) -> [ActionConfig] {
        return dynamicActions.compactMap { dynamicAction -> ActionConfig? in
            // Check if action exists in embedded registry
            guard let embeddedAction = ActionRegistry.shared.getAction(dynamicAction.actionId) else {
                print("⚠️ Unknown action from API: \(dynamicAction.actionId)")
                return nil
            }

            // Use embedded action config, but with personalized priority from API
            return ActionConfig(
                actionId: embeddedAction.actionId,
                displayName: dynamicAction.displayName,
                actionType: embeddedAction.actionType,
                mode: embeddedAction.mode,
                modalComponent: embeddedAction.modalComponent,
                requiredContextKeys: embeddedAction.requiredContextKeys,
                optionalContextKeys: embeddedAction.optionalContextKeys,
                fallbackBehavior: embeddedAction.fallbackBehavior,
                analyticsEvent: embeddedAction.analyticsEvent,
                priority: dynamicAction.priority,  // Use personalized priority from API
                description: dynamicAction.description,
                requiredPermission: embeddedAction.requiredPermission,
                availability: embeddedAction.availability
            )
        }
    }
}

// MARK: - Errors

enum RegistryError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network error"
        }
    }
}

// MARK: - Extension for Background Refresh

extension DynamicActionRegistry {
    /**
     * Schedule background refresh every 24 hours
     * Call this on app launch
     */
    func scheduleBackgroundRefresh(for userId: String) {
        // Check if cache needs refresh
        if !isCacheValid() {
            Task {
                _ = await fetchRegistry(for: userId, forceRefresh: true)
            }
        }
    }

    /**
     * Get cache age in hours
     */
    func getCacheAge() -> Double? {
        guard let lastFetched = lastFetched else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(lastFetched)
        return elapsed / 3600  // Convert to hours
    }

    /**
     * Get cache info for debugging
     */
    func getCacheInfo() -> String {
        guard let lastFetched = lastFetched else {
            return "No cache"
        }

        let age = getCacheAge() ?? 0
        let valid = isCacheValid()

        return """
        Cache Info:
        - Actions: \(cachedActions.count)
        - Age: \(String(format: "%.1f", age)) hours
        - Valid: \(valid ? "Yes" : "No")
        - Last fetched: \(lastFetched)
        - Cache hit: \(cacheHit ? "Yes" : "No")
        """
    }
}
