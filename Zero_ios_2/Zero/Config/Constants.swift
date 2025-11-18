import Foundation
import UIKit

/// Centralized constants for the Zero app
/// Eliminates magic strings and hardcoded values throughout the codebase
enum Constants {
    
    // MARK: - User Defaults Keys
    enum UserDefaultsKeys {
        static let useMockData = "useMockData"
        static let selectedArchetypes = "selectedArchetypes"
        static let emailTimeRange = "emailTimeRange"
        static let savedDeals = "savedDeals"
        static let useMLClassification = "useMLClassification"
        static let openAIAPIKey = "openAIAPIKey"
        static let geminiAPIKey = "geminiAPIKey"
    }
    
    // MARK: - Keychain Keys
    enum Keychain {
        static let service = "EmailShortForm"
    }
    
    // MARK: - User Session
    enum UserSession {
        static let defaultUserId = "user-123" // TODO: Replace with actual authenticated user ID
    }
    
    // MARK: - API Configuration
    enum API {
        static let gatewayPort = 3001
        static let classifierPort = 8082
        static let emailServicePort = 8081
        static let summarizationServicePort = 8083
        static let shoppingAgentPort = 8085

        enum Development {
            // NOTE: Gateway MUST use production URL even in dev (OAuth callbacks are registered with Google)
            static let gatewayBaseURL = "https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api"
            static let classifierBaseURL = "http://localhost:8082/api"
            static let emailServiceBaseURL = "http://localhost:8081/api"
            static let summarizationServiceBaseURL = "http://localhost:8083/api"
            static let smartRepliesServiceBaseURL = "http://localhost:8086/api"
            static let shoppingCartBaseURL = "http://localhost:8084"
            static let scheduledPurchaseBaseURL = "http://localhost:8085/api"
            static let steelAgentBaseURL = "http://localhost:8087/api"
        }

        enum Production {
            static let gatewayBaseURL = "https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api"
            static let classifierBaseURL = "https://classifier-service-hqdlmnyzrq-uc.a.run.app/api"
            static let emailServiceBaseURL = "https://email-service-hqdlmnyzrq-uc.a.run.app/api"
            static let summarizationServiceBaseURL = "https://summarization-service-hqdlmnyzrq-uc.a.run.app/api"
            static let smartRepliesServiceBaseURL = "https://smart-replies-service-hqdlmnyzrq-uc.a.run.app/api"
            static let shoppingCartBaseURL = "https://shopping-agent-service-hqdlmnyzrq-uc.a.run.app"
            static let scheduledPurchaseBaseURL = "https://scheduled-purchase-service-hqdlmnyzrq-uc.a.run.app/api"
            static let steelAgentBaseURL = "https://steel-agent-service-hqdlmnyzrq-uc.a.run.app/api"
        }

        // MARK: - Environment Selection
        static var isProduction: Bool {
            #if DEBUG
            return false
            #else
            return true
            #endif
        }

        // Convenience accessors for current environment
        static var classifierServiceURL: String {
            isProduction ? Production.classifierBaseURL : Development.classifierBaseURL
        }

        static var emailServiceURL: String {
            isProduction ? Production.emailServiceBaseURL : Development.emailServiceBaseURL
        }
    }
    
    // MARK: - UI Constants
    enum UI {
        static let cardWidth: CGFloat = UIScreen.main.bounds.width - 48
        static let cardHeight: CGFloat = 500
        static let cardStackOffset: CGFloat = 15
        static let cardStackScale: CGFloat = 0.03
        static let swipeThreshold: CGFloat = 120
        static let swipeHapticThreshold: CGFloat = 120
        
        enum Animation {
            static let springResponse: Double = 0.35
            static let springDamping: Double = 0.8
            static let springBlend: Double = 0.15
            static let snapbackResponse: Double = 0.4
            static let snapbackDamping: Double = 0.65
            static let snapbackBlend: Double = 0.1
        }
        
        enum Toast {
            static let autoDismissDelay: Double = 3.0
            static let bottomPadding: CGFloat = 100
        }
    }
    
    // MARK: - Feature Flags
    enum FeatureFlags {
        static let enableMLClassification = true
        static let enableSmartReplies = true
        static let enableShoppingCart = true
        static let enableThreadView = true
        static let enableAdminFeedback = true
    }
    
    // MARK: - Analytics Events
    enum AnalyticsEvents {
        static let appSessionStart = "app_session_start"
        static let appSessionEnd = "app_session_end"
        static let appEnteredForeground = "app_entered_foreground"
        static let cardSwiped = "card_swiped"
        static let emailFetchSuccess = "email_fetch_success"
        static let emailFetchFailed = "email_fetch_failed"
        static let actionExecuted = "action_executed"
        static let modalOpened = "modal_opened"
        static let archetypeChanged = "archetype_changed"
    }
    
    // MARK: - Default Values
    enum Defaults {
        static let selectedArchetypes: [CardType] = [.mail, .ads]
        static let emailTimeRange: EmailTimeRange = .twoWeeks
        static let snoozeDuration = 2 // hours
        static let maxEmailResults = 100
    }
    
    // MARK: - Validation
    enum Validation {
        static let minSwipeDistance: CGFloat = 50
        static let maxVisibleCards = 3
    }
    
    // MARK: - User Defaults
    enum UserDefaults {
        /// Default user ID (replaces hardcoded "user-123")
        static let defaultUserId = "user-123"
        static let demoEmail = "demo@zero.app"
    }
    
    // MARK: - File Paths
    enum FilePaths {
        static let analyticsLog = "analytics.log"
        static let errorLog = "error.log"
        static let combinedLog = "combined.log"
    }

    // MARK: - App Information
    enum AppInfo {
        static let supportEmail = "0Inboxapp@gmail.com"
        static let privacyPolicyURL = "https://zero-legal-pages-514014482017.us-central1.run.app/privacy.html"
        static let termsOfServiceURL = "https://zero-legal-pages-514014482017.us-central1.run.app/terms.html"
        static let version = "1.0"
        static let buildType = "TestFlight Beta"
    }
}

