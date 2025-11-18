import Foundation

/**
 * ModalConfigService - Fetches modal configurations from backend API
 *
 * Phase 3: Backend API Integration
 * Provides dynamic modal configuration delivery with caching and A/B testing support
 *
 * Features:
 * - Remote config fetching from API
 * - Local caching for offline support
 * - Version management
 * - A/B testing support
 * - Fallback to bundled configs
 */
class ModalConfigService {
    static let shared = ModalConfigService()

    // MARK: - Configuration

    private let baseURL: String
    private let cache: ModalConfigCache
    private let networkMonitor: NetworkMonitor

    // MARK: - Initialization

    init(
        baseURL: String = AppEnvironment.current.apiBaseURL,
        cache: ModalConfigCache = ModalConfigCache.shared,
        networkMonitor: NetworkMonitor = NetworkMonitor.shared
    ) {
        self.baseURL = baseURL
        self.cache = cache
        self.networkMonitor = networkMonitor
    }

    // MARK: - Public API

    /// Fetch modal configuration by ID
    /// - Parameter modalId: The modal identifier (e.g., "track_package")
    /// - Returns: ModalConfig or nil if not available
    func fetchConfig(for modalId: String) async -> ModalConfig? {
        // 1. Try memory cache first
        if let cachedConfig = cache.get(modalId) {
            Logger.info("📦 Loaded \(modalId) from cache", category: .action)
            return cachedConfig
        }

        // 2. If offline, try to load from bundle
        if !networkMonitor.isConnected {
            Logger.warning("📴 Offline - loading \(modalId) from bundle", category: .action)
            return loadFromBundle(modalId)
        }

        // 3. Fetch from API
        do {
            let config = try await fetchFromAPI(modalId)
            Logger.info("🌐 Fetched \(modalId) from API", category: .action)

            // Cache for future use
            cache.set(config, forKey: modalId)

            return config
        } catch {
            Logger.error("❌ Failed to fetch \(modalId): \(error)", category: .action)

            // 4. Fallback to bundle
            return loadFromBundle(modalId)
        }
    }

    /// Prefetch multiple modal configs (for common modals)
    func prefetch(modalIds: [String]) async {
        Logger.info("🔄 Prefetching \(modalIds.count) modal configs", category: .action)

        await withTaskGroup(of: Void.self) { group in
            for modalId in modalIds {
                group.addTask {
                    _ = await self.fetchConfig(for: modalId)
                }
            }
        }

        Logger.info("✅ Prefetch complete", category: .action)
    }

    /// Clear cached configs (useful for testing or forcing refresh)
    func clearCache() {
        cache.clear()
        Logger.info("🗑️ Cache cleared", category: .action)
    }

    // MARK: - Private Methods

    /// Fetch config from API
    private func fetchFromAPI(_ modalId: String) async throws -> ModalConfig {
        // Build request URL
        let endpoint = "\(baseURL)/api/v1/modal-configs/\(modalId)"
        guard let url = URL(string: endpoint) else {
            throw ModalConfigError.invalidURL
        }

        // Add query parameters for A/B testing and versioning
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "version", value: "1.0"),
            URLQueryItem(name: "platform", value: "ios"),
            URLQueryItem(name: "user_id", value: UserSession.current?.userId ?? "anonymous")
        ]

        guard let finalURL = components?.url else {
            throw ModalConfigError.invalidURL
        }

        // Make request
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(AppEnvironment.apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ModalConfigError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ModalConfigError.httpError(statusCode: httpResponse.statusCode)
        }

        // Decode config
        let decoder = JSONDecoder()
        let config = try decoder.decode(ModalConfig.self, from: data)

        // Validate config
        let validation = config.validate()
        guard validation.isValid else {
            if case .invalid(let errors) = validation {
                throw ModalConfigError.invalidConfig(errors: errors)
            }
            throw ModalConfigError.invalidConfig(errors: ["Unknown validation error"])
        }

        return config
    }

    /// Load config from local bundle (fallback)
    private func loadFromBundle(_ modalId: String) -> ModalConfig? {
        return ModalConfig.load(from: modalId)
    }
}

// MARK: - ModalConfig Cache

class ModalConfigCache {
    static let shared = ModalConfigCache()

    private var cache: [String: CachedConfig] = [:]
    private let cacheLifetime: TimeInterval = 3600 // 1 hour

    struct CachedConfig {
        let config: ModalConfig
        let timestamp: Date
    }

    func get(_ key: String) -> ModalConfig? {
        guard let cached = cache[key] else { return nil }

        // Check if expired
        if Date().timeIntervalSince(cached.timestamp) > cacheLifetime {
            cache.removeValue(forKey: key)
            return nil
        }

        return cached.config
    }

    func set(_ config: ModalConfig, forKey key: String) {
        cache[key] = CachedConfig(config: config, timestamp: Date())
    }

    func clear() {
        cache.removeAll()
    }
}

// MARK: - Errors

enum ModalConfigError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case invalidConfig(errors: [String])
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .invalidConfig(let errors):
            return "Invalid config: \(errors.joined(separator: ", "))"
        case .networkUnavailable:
            return "Network unavailable"
        }
    }
}

// MARK: - Helper Extensions

extension ModalConfig {
    /// Create a remote config URL for sharing/debugging
    var remoteURL: URL? {
        guard let baseURL = URL(string: AppEnvironment.current.apiBaseURL) else { return nil }
        return baseURL.appendingPathComponent("api/v1/modal-configs/\(id)")
    }
}
