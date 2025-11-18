
//
//  ZeroApp.swift
//  Zero
//
//  Created by Matt Hanson on 10/18/25.
//


import SwiftUI

@main
struct ZeroApp: App {

    // MARK: - Dependency Injection

    /// Centralized launch configuration
    private let launchConfig = LaunchConfiguration()

    /// Service container holds all services and user session
    /// Injected via @EnvironmentObject throughout the app
    @StateObject private var services: ServiceContainer

    /// Scene phase for lifecycle tracking
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Initialize services with launch configuration
        let launchConfig = LaunchConfiguration()
        let container = ServiceContainer.production(launchConfig: launchConfig)
        _services = StateObject(wrappedValue: container)

        // Log UI testing configuration
        if launchConfig.isUITesting {
            container.logger.info("🧪 UI Testing mode detected")

            if launchConfig.useMockData {
                container.logger.info("✅ Mock data enabled for UI tests")
            }

            if launchConfig.skipOnboarding {
                container.logger.info("⏩ Onboarding skip requested for UI tests")
            }
        }

        // Log app launch
        container.logger.info("Zero v1.11.1 launched")

        // Initialize lifecycle observer (replaces manual analytics tracking)
        container.lifecycleObserver.didLaunch()

        // Set user properties with typed enums
        container.analyticsService.setUserProperty(
            container.settings.useMockData ? "mock" : "real",
            forName: .dataMode
        )

        // Track selected archetypes
        let archetypes = container.settings.selectedArchetypes
        if !archetypes.isEmpty {
            container.analyticsService.setUserProperty(
                archetypes.joined(separator: ","),
                forName: .selectedArchetypes
            )
        }

        // Fetch remote config on launch (async, non-blocking)
        Task {
            await RemoteConfigService.shared.fetchConfig()
        }

        // Start network monitoring
        Task { @MainActor in
            NetworkMonitor.shared.startMonitoring()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(services)
                .environmentObject(services.userSession)
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
                .onOpenURL { url in
                    handleOAuthCallback(url)
                }
        }
    }

    // MARK: - Lifecycle Handling

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        // Delegate all lifecycle handling to AppLifecycleObserver
        services.lifecycleObserver.handleScenePhase(phase)
    }

    // MARK: - OAuth Callback Handling

    private func handleOAuthCallback(_ url: URL) {
        services.logger.info("📱 OAuth callback received: \(url.absoluteString)")

        // Extract JWT token and email from callback URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let token = queryItems.first(where: { $0.name == "token" })?.value,
              let email = queryItems.first(where: { $0.name == "email" })?.value,
              let provider = queryItems.first(where: { $0.name == "provider" })?.value else {
            services.logger.error("❌ Missing token, email, or provider in OAuth callback")
            return
        }

        services.logger.info("✅ JWT token received from backend")

        // Store the JWT token and authenticate user
        Task { @MainActor in
            // Map provider string to enum
            let providerEnum: UserSession.AuthProvider
            switch provider.lowercased() {
            case "gmail":
                providerEnum = .gmail
            case "outlook":
                providerEnum = .outlook
            default:
                providerEnum = .gmail
            }

            // Update user session with authenticated email
            services.userSession.authenticate(
                userId: email,
                email: email,
                provider: providerEnum
            )

            // Store JWT token securely in Keychain
            if let emailAPIService = services.emailService as? EmailAPIService {
                do {
                    try emailAPIService.storeTokenInKeychain(token: token, email: email)
                    services.logger.info("✅ JWT token stored securely in Keychain")
                } catch {
                    services.logger.error("❌ Failed to store token in Keychain: \(error)")
                }
            } else {
                services.logger.warning("⚠️ Could not cast emailService to EmailAPIService for Keychain storage")
            }

            // Turn off mock data mode
            services.settings.useMockData = false

            services.logger.info("✅ OAuth flow completed successfully for \(email)")
        }
    }
}


