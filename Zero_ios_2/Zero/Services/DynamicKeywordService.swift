import Foundation

/**
 * Dynamic Keyword Service (Phase 3)
 * Fetches ML-learned keywords from corpus instead of using hardcoded arrays
 *
 * Features:
 * - API-fetched keywords with TF-IDF weights
 * - 7-day cache with automatic refresh
 * - Offline fallback to embedded keywords
 * - Category-specific keyword sets
 */

// MARK: - API Response Models

struct KeywordResponse: Codable {
    let keywords: [DynamicKeyword]
    let metadata: KeywordMetadata
}

struct DynamicKeyword: Codable {
    let keyword: String
    let weight: Double
    let frequency: Int
    let occurrences: Int
    let precision: Double
    let tfidfScore: Double

    enum CodingKeys: String, CodingKey {
        case keyword, weight, frequency, occurrences, precision
        case tfidfScore = "tfidf_score"
    }
}

struct KeywordMetadata: Codable {
    let userId: String
    let category: String
    let corpusSize: Int
    let documentCount: Int
    let lastUpdated: String
    let fromCache: Bool?
    let cacheAge: String?
}

// MARK: - Keyword Category

enum KeywordCategory: String, CaseIterable {
    case events = "events"
    case reminders = "reminders"
    case payments = "payments"
    case shopping = "shopping"
    case documents = "documents"
    case contacts = "contacts"
    case urgency = "urgency"
    case tracking = "tracking"
    case supplies = "supplies"
    case books = "books"

    var fallbackKeywords: [String] {
        switch self {
        case .events:
            return ["meeting", "appointment", "event", "conference", "webinar", "class"]
        case .reminders:
            return ["due", "deadline", "reminder", "don't forget", "remember"]
        case .payments:
            return ["invoice", "bill", "payment", "pay now", "amount due"]
        case .shopping:
            return ["sale", "discount", "order", "purchase", "buy"]
        case .documents:
            return ["attached", "attachment", "pdf", "document", "form", "sign"]
        case .contacts:
            return ["call", "phone", "contact", "reach out"]
        case .urgency:
            return ["urgent", "asap", "immediately", "time sensitive"]
        case .tracking:
            return ["tracking", "shipment", "delivery", "package"]
        case .supplies:
            return ["supplies", "materials", "bring", "purchase"]
        case .books:
            return ["book", "reading", "library", "novel"]
        }
    }
}

// MARK: - Dynamic Keyword Service

@MainActor
class DynamicKeywordService: ObservableObject {
    static let shared = DynamicKeywordService()

    @Published var isLoading = false
    @Published var error: String?

    // Cached keywords by category
    private var cachedKeywords: [KeywordCategory: [String]] = [:]
    private var cachedWeights: [KeywordCategory: [String: Double]] = [:]
    private var cacheTimestamps: [KeywordCategory: Date] = [:]

    // Cache expiration (7 days)
    private let cacheExpirationInterval: TimeInterval = 7 * 24 * 60 * 60

    // API Configuration
    private let keywordServiceBaseURL: String

    private init() {
        // Use environment variable or default
        if let urlString = ProcessInfo.processInfo.environment["KEYWORD_SERVICE_URL"] {
            self.keywordServiceBaseURL = urlString
        } else if let urlString = Bundle.main.infoDictionary?["KEYWORD_SERVICE_URL"] as? String {
            self.keywordServiceBaseURL = urlString
        } else {
            self.keywordServiceBaseURL = "http://localhost:8088"
        }
    }

    // MARK: - Public API

    /**
     * Get keywords for category (cached or API-fetched)
     */
    func getKeywords(
        for category: KeywordCategory,
        userId: String,
        forceRefresh: Bool = false
    ) async -> [String] {
        // Check cache first
        if !forceRefresh && isCacheValid(for: category) {
            if let cached = cachedKeywords[category] {
                print("📦 Using cached keywords for \(category.rawValue)")
                return cached
            }
        }

        // Fetch from API
        do {
            let keywords = try await fetchKeywordsFromAPI(
                category: category,
                userId: userId
            )

            // Cache the keywords
            cachedKeywords[category] = keywords
            cacheTimestamps[category] = Date()

            print("✅ Fetched \(keywords.count) keywords for \(category.rawValue) from API")
            return keywords

        } catch {
            print("⚠️ Failed to fetch keywords for \(category.rawValue): \(error.localizedDescription)")
            print("📱 Using fallback keywords")

            // Return fallback keywords
            return category.fallbackKeywords
        }
    }

    /**
     * Get keyword weight (for confidence scoring)
     */
    func getWeight(for keyword: String, category: KeywordCategory) -> Double {
        return cachedWeights[category]?[keyword.lowercased()] ?? 0.5
    }

    /**
     * Check if text contains any keywords from category
     */
    func containsKeyword(
        text: String,
        category: KeywordCategory,
        userId: String
    ) async -> Bool {
        let keywords = await getKeywords(for: category, userId: userId)
        let lowercasedText = text.lowercased()

        return keywords.contains { keyword in
            lowercasedText.contains(keyword.lowercased())
        }
    }

    /**
     * Get matching keywords and their weights
     */
    func getMatchingKeywords(
        text: String,
        category: KeywordCategory,
        userId: String
    ) async -> [(keyword: String, weight: Double)] {
        let keywords = await getKeywords(for: category, userId: userId)
        let lowercasedText = text.lowercased()

        var matches: [(String, Double)] = []

        for keyword in keywords {
            if lowercasedText.contains(keyword.lowercased()) {
                let weight = getWeight(for: keyword, category: category)
                matches.append((keyword, weight))
            }
        }

        // Sort by weight (highest first)
        return matches.sorted { $0.1 > $1.1 }
    }

    /**
     * Preload keywords for all categories (call on app launch)
     */
    func preloadKeywords(for userId: String) async {
        print("🔄 Preloading keywords for all categories...")

        await withTaskGroup(of: Void.self) { group in
            for category in KeywordCategory.allCases {
                group.addTask {
                    _ = await self.getKeywords(for: category, userId: userId)
                }
            }
        }

        print("✅ Keyword preloading complete")
    }

    /**
     * Invalidate cache (force refresh on next fetch)
     */
    func invalidateCache(for category: KeywordCategory? = nil) {
        if let category = category {
            cachedKeywords.removeValue(forKey: category)
            cachedWeights.removeValue(forKey: category)
            cacheTimestamps.removeValue(forKey: category)
            print("🗑️ Invalidated cache for \(category.rawValue)")
        } else {
            cachedKeywords.removeAll()
            cachedWeights.removeAll()
            cacheTimestamps.removeAll()
            print("🗑️ Invalidated all keyword caches")
        }
    }

    // MARK: - Private Methods

    /**
     * Check if cache is valid
     */
    private func isCacheValid(for category: KeywordCategory) -> Bool {
        guard let timestamp = cacheTimestamps[category] else {
            return false
        }

        let elapsed = Date().timeIntervalSince(timestamp)
        return elapsed < cacheExpirationInterval
    }

    /**
     * Fetch keywords from API
     */
    private func fetchKeywordsFromAPI(
        category: KeywordCategory,
        userId: String,
        days: Int = 90
    ) async throws -> [String] {
        var components = URLComponents(string: "\(keywordServiceBaseURL)/api/keywords/dynamic")!
        components.queryItems = [
            URLQueryItem(name: "userId", value: userId),
            URLQueryItem(name: "category", value: category.rawValue),
            URLQueryItem(name: "days", value: "\(days)"),
            URLQueryItem(name: "limit", value: "20")
        ]

        guard let url = components.url else {
            throw KeywordError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw KeywordError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw KeywordError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let keywordResponse = try decoder.decode(KeywordResponse.self, from: data)

        // Extract keywords as strings
        let keywords = keywordResponse.keywords.map { $0.keyword }

        // Cache weights for later use
        var weights: [String: Double] = [:]
        for kw in keywordResponse.keywords {
            weights[kw.keyword.lowercased()] = kw.weight
        }
        cachedWeights[category] = weights

        return keywords
    }

    /**
     * Get cache info for debugging
     */
    func getCacheInfo() -> String {
        var info = "Keyword Cache Info:\n"

        for category in KeywordCategory.allCases {
            if let timestamp = cacheTimestamps[category],
               let keywords = cachedKeywords[category] {
                let age = Date().timeIntervalSince(timestamp) / 3600  // hours
                let valid = isCacheValid(for: category)
                info += "- \(category.rawValue): \(keywords.count) keywords, age: \(String(format: "%.1f", age))h, valid: \(valid)\n"
            } else {
                info += "- \(category.rawValue): No cache\n"
            }
        }

        return info
    }
}

// MARK: - Errors

enum KeywordError: Error, LocalizedError {
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
