import Foundation

/// Environment configuration for switching between Development and Production
enum AppEnvironment {
    case development
    case production

    /// Current environment based on build configuration
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    /// Base URL for the API Gateway
    /// NOTE: Gateway must ALWAYS use Cloud Run (even in dev) because OAuth callbacks
    /// are registered with Google and cannot redirect to localhost
    /// For development, use MOCK DATA mode instead of real email OAuth
    var apiBaseURL: String {
        // Always use production for OAuth endpoints
        return "https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api"
    }

    /// Base URL without /api suffix (for OAuth URLs like /auth/gmail)
    var gatewayBaseURL: String {
        return "https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app"
    }

    /// Base URL for the Classifier Service (ML-based classification)
    var classifierBaseURL: String {
        switch self {
        case .development:
            return "http://localhost:8082/api"
        case .production:
            return "https://classifier-service-hqdlmnyzrq-uc.a.run.app/api"
        }
    }

    /// Display name for the environment
    var displayName: String {
        switch self {
        case .development:
            return "Development (Local)"
        case .production:
            return "Production (Cloud Run)"
        }
    }

    /// OpenAI API Key (from UserDefaults, build config, or fallback)
    static var openAIKey: String {
        // Try to get from UserDefaults first (user can set in Settings)
        if let key = UserDefaults.standard.string(forKey: "openAIAPIKey"), !key.isEmpty {
            return key
        }

        // Try to get from build configuration (Info.plist)
        if let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String, !key.isEmpty {
            return key
        }

        // Fallback to empty string - will fail gracefully with error
        return ""
    }

    /// Gemini API Key (from UserDefaults, build config, or fallback)
    static var geminiAPIKey: String {
        // Try to get from UserDefaults first (user can set in Settings)
        if let key = UserDefaults.standard.string(forKey: "geminiAPIKey"), !key.isEmpty {
            return key
        }

        // Try to get from build configuration (Info.plist)
        if let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String, !key.isEmpty {
            return key
        }

        // Fallback to empty string - will fail gracefully with error
        return ""
    }

    /// API Key for modal config service (authenticated endpoint)
    static var apiKey: String {
        // Try to get from UserDefaults first
        if let key = UserDefaults.standard.string(forKey: "modalConfigAPIKey"), !key.isEmpty {
            return key
        }

        // Try to get from build configuration
        if let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String, !key.isEmpty {
            return key
        }

        // Fallback to demo key for testing
        return "demo_key_" + UUID().uuidString
    }
}
