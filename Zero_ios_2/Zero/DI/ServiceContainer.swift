import Foundation
import Combine

/// Dependency Injection container
/// Holds all services and provides them to views via @EnvironmentObject
/// Enables testing by allowing mock implementations
class ServiceContainer: ObservableObject {

    // MARK: - Core Services

    let emailService: EmailServiceProtocol
    let shoppingCartService: ShoppingCartServiceProtocol
    let analyticsService: Analytics  // Updated to use protocol from AnalyticsSchema
    let logger: Logging
    var settings: Settings  // Mutable to allow property updates
    let featureGating: FeatureGating  // Feature flag system (Phase 2)
    let errorReporter: ErrorReporting  // Error reporting (Phase 3)
    let lifecycleObserver: AppLifecycleObserver  // Lifecycle management (Phase 3)

    // MARK: - New Services (Phase 5)

    @Published var userPreferences: UserPreferencesService
    @Published var appState: AppStateManager
    @Published var cardManagement: CardManagementService

    // MARK: - View Models

    @Published var emailViewModel: EmailViewModel

    // MARK: - Session

    @Published var userSession: UserSession

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Initialize with real services (production)
    init(emailService: EmailServiceProtocol? = nil,
         shoppingCartService: ShoppingCartServiceProtocol? = nil,
         analyticsService: Analytics? = nil,
         logger: Logging? = nil,
         settings: Settings? = nil,
         featureGating: FeatureGating? = nil,
         errorReporter: ErrorReporting? = nil,
         lifecycleObserver: AppLifecycleObserver? = nil,
         userSession: UserSession? = nil,
         userPreferences: UserPreferencesService? = nil,
         appState: AppStateManager? = nil,
         cardManagement: CardManagementService? = nil) {

        // Use provided services or default to singletons/new instances
        self.emailService = emailService ?? EmailAPIService.shared
        self.shoppingCartService = shoppingCartService ?? ShoppingCartService.shared
        let analyticsInstance = analyticsService ?? AnalyticsService()
        self.analyticsService = analyticsInstance
        let loggerInstance = logger ?? OSLogger(category: "app")
        self.logger = loggerInstance
        self.settings = settings ?? AppSettings()
        self.featureGating = featureGating ?? LocalFeatureGating(logger: loggerInstance)
        let errorReporterInstance = errorReporter ?? ConsoleErrorReporter(logger: loggerInstance)
        self.errorReporter = errorReporterInstance
        self.lifecycleObserver = lifecycleObserver ?? AppLifecycleObserver(
            analytics: analyticsInstance,
            logger: loggerInstance,
            errorReporter: errorReporterInstance
        )
        self.userSession = userSession ?? UserSession()

        // Phase 5 services
        let prefs = userPreferences ?? UserPreferencesService()
        let state = appState ?? AppStateManager()
        let cards = cardManagement ?? CardManagementService()

        self.userPreferences = prefs
        self.appState = state
        self.cardManagement = cards

        // Create EmailViewModel with injected services
        self.emailViewModel = EmailViewModel(
            userPreferences: prefs,
            appState: state,
            cardManagement: cards
        )

        // Forward changes from all @Published services to ServiceContainer
        // This ensures ContentView (@EnvironmentObject) re-renders when nested objects change
        prefs.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)

        state.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)

        cards.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)

        self.emailViewModel.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)

        self.userSession.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)

        // Use injected logger instead of static Logger
        self.logger.info("ServiceContainer initialized with all services")
    }

    // MARK: - Factory Methods

    /// Create container with real services (production)
    /// - Parameter launchConfig: Optional launch configuration to initialize settings
    static func production(launchConfig: LaunchConfiguration? = nil) -> ServiceContainer {
        let appSettings = AppSettings()

        // Apply launch configuration if provided
        if let config = launchConfig {
            if config.isUITesting {
                if config.useMockData {
                    appSettings.useMockData = true
                }
                if config.skipOnboarding {
                    appSettings.skipOnboarding = true
                }
            }
        }

        let logger = OSLogger(category: "app")
        let analytics = AnalyticsService()
        // Note: analytics.dataMode is set explicitly in SplashView when user chooses auth method

        let errorReporter = ConsoleErrorReporter(logger: logger)

        return ServiceContainer(
            emailService: EmailAPIService.shared,
            shoppingCartService: ShoppingCartService.shared,
            analyticsService: analytics,
            logger: logger,
            settings: appSettings,
            featureGating: LocalFeatureGating(logger: logger),
            errorReporter: errorReporter,
            lifecycleObserver: AppLifecycleObserver(
                analytics: analytics,
                logger: logger,
                errorReporter: errorReporter
            ),
            userSession: UserSession(),
            userPreferences: UserPreferencesService(),
            appState: AppStateManager(),
            cardManagement: CardManagementService()
        )
    }
    
    /// Create container with mock services (testing)
    static func mock() -> ServiceContainer {
        let analytics = AnalyticsService()
        analytics.dataMode = "mock"  // Always use mock mode for testing

        let appSettings = AppSettings()
        appSettings.useMockData = true

        return ServiceContainer(
            analyticsService: analytics,
            settings: appSettings
        )
    }
}

// MARK: - Preview Helper

#if DEBUG
extension ServiceContainer {
    /// Create container for SwiftUI previews
    static func preview() -> ServiceContainer {
        return ServiceContainer()
    }
}
#endif

