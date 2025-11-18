import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var services: ServiceContainer
    @ObservedObject var viewModel: EmailViewModel
    @Binding var isPresented: Bool
    @StateObject private var accountManager = AccountManager()
    @State private var openAIKey: String = ""
    @State private var geminiAPIKey: String = ""
    @State private var useMLClassification: Bool = false
    @State private var showKeyAlert = false
    @State private var showMLAlert = false
    @State private var showModelTuning = false
    #if DEBUG
    // @State private var showActionTester = false // Disabled - ActionTester needs fixes
    #endif
    @State private var showDebugOverlay: Bool = false
    @State private var showModeIndicators: Bool = true
    @State private var isReloadingEmails = false
    @State private var showReloadAlert = false
    @State private var enableEmailSending: Bool = false
    @State private var showEmailSendingWarning = false
    @State private var showSendingConfirmation = false
    @State private var showResetConfirmation = false
    @State private var vipFilterEnabled: Bool = false
    @State private var enableThreading: Bool = false
    @State private var debugOverlay: Bool = false
    @State private var showBuildInfo = false

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.1, blue: 0.3),
                Color(red: 0.2, green: 0.1, blue: 0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }


    @ViewBuilder
    private var aiSettingsSection: some View {
                        // AI Settings Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("AI Features")
                                .font(.headline)
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                                .padding(.horizontal, DesignTokens.Spacing.card)
                                .padding(.top, DesignTokens.Spacing.card)

                            SettingAPIKeyCard(
                                title: "OpenAI API Key",
                                description: "Used for smart replies and AI features. Get yours at platform.openai.com/api-keys",
                                icon: "key.fill",
                                color: .blue,
                                environmentKey: AppEnvironment.openAIKey,
                                storageKey: "manualOpenAIKey",
                                configuredMessage: "API key configured via environment",
                                readyMessage: "API key ready to use",
                                placeholder: "sk-proj-..."
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            SettingAPIKeyCard(
                                title: "Gemini API Key",
                                description: "Optional: Use Google's Gemini model for classification. Get yours at ai.google.dev",
                                icon: "sparkles",
                                color: .purple,
                                environmentKey: AppEnvironment.geminiAPIKey,
                                storageKey: "manualGeminiKey",
                                configuredMessage: "API key configured via environment",
                                readyMessage: "API key ready to use",
                                placeholder: "Enter Gemini API key..."
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            SettingToggleRow(
                                title: "ML Classification",
                                description: "Use ML-based intent detection for better accuracy",
                                icon: "wand.and.stars",
                                color: .blue,
                                isOn: $useMLClassification,
                                onChange: { _ in
                                    Logger.info("ML Classification toggled: \(useMLClassification)", category: .userPreferences)
                                }
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            SettingToggleRowWithExtra(
                                title: "Enable Email Sending",
                                description: enableEmailSending ? "⚠️ Emails will be sent for real" : "Safe mode: emails won't actually send",
                                icon: enableEmailSending ? "paperplane.fill" : "paperplane",
                                color: enableEmailSending ? .red : .orange,
                                isOn: $enableEmailSending,
                                onChange: { newValue in
                                    if newValue {
                                        showSendingConfirmation = true
                                    } else {
                                        Logger.info("Email sending disabled - safe mode", category: .userPreferences)
                                    }
                                }
                            ) {
                                if !enableEmailSending {
                                    HStack(spacing: 8) {
                                        Image(systemName: "shield.fill")
                                            .foregroundColor(.green)
                                        Text("Safe mode active: Reply and compose features will simulate sending without actually delivering emails")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            .padding(.horizontal, DesignTokens.Spacing.section)
                        }

    }

    @ViewBuilder
    private var settingsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "gear")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))

                            Text("Settings")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)

                        // Model Tuning - Feature flagged
                        if services.featureGating.isEnabled(.modelTuning) {
                            SettingNavigationButton(
                                title: "Model Tuning",
                                description: "Train Zero's AI on categories and actions",
                                icon: "brain.head.profile",
                                color: .cyan,
                                style: .gradient(colors: [.cyan, .purple]),
                                action: { showModelTuning = true }
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                        }

                        #if DEBUG
                        // ActionTester button disabled - needs fixes
                        // SettingNavigationButton(
                        //     title: "Action Tester",
                        //     description: "Test all 45+ actions with mock data",
                        //     icon: "play.circle.fill",
                        //     color: .green,
                        //     style: .gradient(colors: [.green, .blue]),
                        //     action: { showActionTester = true }
                        // )
                        // .padding(.horizontal, 16)
                        #endif

                        SettingNavigationButton(
                            title: "Email Time Range",
                            description: "Filter by date range (coming soon)",
                            icon: "calendar",
                            color: .orange,
                            disabled: true,
                            action: {}
                        )
                        .padding(.horizontal, 16)

                        aiSettingsSection

                        // Email Accounts Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Email Accounts")
                                .font(.headline)
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                                .padding(.horizontal, DesignTokens.Spacing.card)
                                .padding(.top, DesignTokens.Spacing.card)

                            // Account list
                            if accountManager.accounts.isEmpty {
                                Text("No accounts connected")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                                    .padding(.horizontal, 20)
                            } else {
                                ForEach(accountManager.accounts) { account in
                                    AccountRow(
                                        account: account,
                                        accountManager: accountManager,
                                        onRemove: {
                                            Task {
                                                await accountManager.removeAccount(account, userId: viewModel.userId)
                                            }
                                        }
                                    )
                                    .padding(.horizontal, DesignTokens.Spacing.section)
                                }
                            }

                            // Add account button (disabled - multi-account not implemented yet)
                            Button {
                                // Disabled - multi-account feature not implemented
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Add Email Account")
                                            .font(.headline)
                                        Text("Coming soon - multiple account support")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                    }

                                    Spacer()
                                }
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                                .glassCard(borderColor: .white, borderOpacity: DesignTokens.Opacity.glassLight, padding: DesignTokens.Spacing.card)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(true)
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            // Reload emails button
                            Button {
                                reloadEmails()
                            } label: {
                                HStack {
                                    if isReloadingEmails {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .frame(width: 24, height: 24)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.title3)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Reload Emails")
                                            .font(.headline)
                                        Text("Fetch latest emails and start fresh")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                    }

                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(DesignTokens.Spacing.card)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                                .strokeBorder(Color.green.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, DesignTokens.Spacing.section)
                            .disabled(isReloadingEmails)
                        }

                        // Reset Onboarding Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("App Settings")
                                .font(.headline)
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                                .padding(.horizontal, DesignTokens.Spacing.card)
                                .padding(.top, DesignTokens.Spacing.card)

                            SettingNavigationButton(
                                title: "Reset Onboarding",
                                description: "Go through the welcome flow again",
                                icon: "arrow.counterclockwise",
                                color: .white,
                                action: { showResetConfirmation = true }
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            SettingToggleRow(
                                title: "Debug Overlay",
                                description: "Show card counts and archetype distribution",
                                icon: "ant.fill",
                                color: .yellow,
                                isOn: $debugOverlay,
                                onChange: { _ in
                                    Logger.info("Debug overlay toggled: \(debugOverlay)", category: .userPreferences)
                                }
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            SettingToggleRow(
                                title: "Mode Indicators",
                                description: "Show status dots (VIP, deadline, newsletter, etc.)",
                                icon: "circle.fill",
                                color: .cyan,
                                isOn: $showModeIndicators,
                                onChange: { _ in
                                    Logger.info("Mode indicators toggled: \(showModeIndicators)", category: .userPreferences)
                                }
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            SettingToggleRowWithExtra(
                                title: "VIP Filter",
                                description: "Show only emails from VIP contacts",
                                icon: "star.fill",
                                color: .yellow,
                                isOn: Binding(
                                    get: { VIPManager.shared.isVIPFilterEnabled },
                                    set: { newValue in
                                        VIPManager.shared.isVIPFilterEnabled = newValue
                                    }
                                ),
                                onChange: { _ in
                                    HapticService.shared.mediumImpact()
                                    Logger.info("VIP filter toggled: \(VIPManager.shared.isVIPFilterEnabled)", category: .userPreferences)
                                }
                            ) {
                                if VIPManager.shared.vipContacts.count > 0 {
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.2.fill")
                                            .foregroundColor(.yellow)
                                        Text("\(VIPManager.shared.vipContacts.count) VIP contact\(VIPManager.shared.vipContacts.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            SettingToggleRow(
                                title: "Conversation Threading",
                                description: "Group related emails into conversation threads",
                                icon: "bubble.left.and.bubble.right.fill",
                                color: .blue,
                                isOn: $enableThreading,
                                onChange: { _ in
                                    Logger.info("Threading toggled: \(enableThreading)", category: .userPreferences)
                                }
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)
                        }

                        // Legal Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Legal")
                                .font(.headline)
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                                .padding(.horizontal, DesignTokens.Spacing.card)
                                .padding(.top, DesignTokens.Spacing.card)

                            SettingNavigationButton(
                                title: "Privacy Policy",
                                description: "How we protect and handle your data",
                                icon: "hand.raised.fill",
                                color: .blue,
                                action: {
                                    if let url = URL(string: Constants.AppInfo.privacyPolicyURL) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            SettingNavigationButton(
                                title: "Terms of Service",
                                description: "Beta testing agreement and usage terms",
                                icon: "doc.text.fill",
                                color: .purple,
                                action: {
                                    if let url = URL(string: Constants.AppInfo.termsOfServiceURL) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            SettingNavigationButton(
                                title: "Contact Support",
                                description: "Get help or report issues",
                                icon: "envelope.fill",
                                color: .green,
                                action: {
                                    if let url = URL(string: "mailto:\(Constants.AppInfo.supportEmail)") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            SettingNavigationButton(
                                title: "Build Info",
                                description: "Version \(Constants.AppInfo.version) - \(Constants.AppInfo.buildType)",
                                icon: "info.circle.fill",
                                color: .gray,
                                action: { showBuildInfo = true }
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)
                        }

                        Spacer()
                    }
                }
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                settingsContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }
                }
            }
        }
        .onAppear {
            // Load existing API keys and settings
            openAIKey = UserDefaults.standard.string(forKey: "openAIAPIKey") ?? ""
            geminiAPIKey = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? ""

            // Enable ML classification by default (only if never set before)
            if UserDefaults.standard.object(forKey: "useMLClassification") == nil {
                UserDefaults.standard.set(true, forKey: "useMLClassification")
                useMLClassification = true
                Logger.info("ML Classification auto-enabled on first launch", category: .app)
            } else {
                useMLClassification = UserDefaults.standard.bool(forKey: "useMLClassification")
            }

            // Load debug overlay setting from feature flags
            debugOverlay = services.featureGating.isEnabled(.debugOverlays)

            // Load mode indicators setting (enabled by default)
            if UserDefaults.standard.object(forKey: "showModeIndicators") == nil {
                UserDefaults.standard.set(true, forKey: "showModeIndicators")
                showModeIndicators = true
            } else {
                showModeIndicators = UserDefaults.standard.bool(forKey: "showModeIndicators")
            }

            // Load email sending setting (default: DISABLED for safety)
            enableEmailSending = UserDefaults.standard.bool(forKey: "enableEmailSending")
            if !enableEmailSending {
                Logger.info("🛡️ Email sending is DISABLED (safe mode)", category: .app)
            } else {
                Logger.warning("⚠️ Email sending is ENABLED", category: .app)
            }

            // Load VIP filter setting
            vipFilterEnabled = VIPManager.shared.isVIPFilterEnabled

            // Load threading setting (default: DISABLED for now)
            enableThreading = UserDefaults.standard.bool(forKey: "enableThreading")

            // Load accounts
            Task {
                await accountManager.fetchAccounts(userId: viewModel.userId)
            }
        }
        .alert("API Key Saved", isPresented: $showKeyAlert) {
            Button("OK") { }
        } message: {
            Text("Your OpenAI API key has been saved securely.")
        }
        .alert("ML Classification Enabled", isPresented: $showMLAlert) {
            Button("OK") { }
        } message: {
            Text("ML-based classification will be used for new emails. Reload your inbox to see the changes.")
        }
        #if DEBUG
        .sheet(isPresented: $showModelTuning) {
            ModelTuningView()
        }
        // ActionTester sheet disabled - needs fixes
        // .sheet(isPresented: $showActionTester) {
        //     ActionTester()
        // }
        #endif
        .alert("Emails Reloaded", isPresented: $showReloadAlert) {
            Button("OK") { }
        } message: {
            Text("Your inbox has been refreshed with the latest emails.")
        }
        .alert("⚠️ Enable Email Sending?", isPresented: $showSendingConfirmation) {
            Button("Cancel", role: .cancel) {
                enableEmailSending = false
            }
            Button("Enable", role: .destructive) {
                UserDefaults.standard.set(true, forKey: "enableEmailSending")
                Logger.info("⚠️ Email sending ENABLED - emails will be sent for real", category: .app)
            }
        } message: {
            Text("This will allow the app to send real emails when you use Reply or Compose features. Make sure you're ready to send actual emails before enabling this.")
        }
        .alert("Reset Onboarding?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.currentAppState = .onboarding
                isPresented = false
            }
        } message: {
            Text("You will be taken through the welcome flow again. This won't delete any of your settings or data.")
        }
        .sheet(isPresented: $showBuildInfo) {
            BuildInfoView()
        }
    }

    func reloadEmails() {
        isReloadingEmails = true

        Task {
            await viewModel.loadRealEmails()

            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            isReloadingEmails = false
            showReloadAlert = true
            Logger.info("Emails reloaded from settings", category: .app)
        }
    }

    func saveAPIKey() {
        guard !openAIKey.isEmpty else { return }

        UserDefaults.standard.set(openAIKey, forKey: "openAIAPIKey")
        showKeyAlert = true

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Logger.info("OpenAI API key saved", category: .app)
    }

    func saveGeminiAPIKey() {
        guard !geminiAPIKey.isEmpty else { return }

        UserDefaults.standard.set(geminiAPIKey, forKey: "geminiAPIKey")
        showKeyAlert = true

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Logger.info("Gemini API key saved", category: .app)
    }
}

// MARK: - Account Row Component
struct AccountRow: View {
    let account: EmailAccount
    @ObservedObject var accountManager: AccountManager
    let onRemove: () -> Void
    @State private var showRemoveConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // Account avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: account.provider.color.red,
                                    green: account.provider.color.green,
                                    blue: account.provider.color.blue
                                ),
                                Color(
                                    red: account.provider.color.red * 0.7,
                                    green: account.provider.color.green * 0.7,
                                    blue: account.provider.color.blue * 0.7
                                )
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text(account.initial)
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }

            // Account info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(account.email)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    if account.isPrimary {
                        Text("PRIMARY")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(DesignTokens.Radius.minimal)
                    }

                    if !account.enabled {
                        Text("DISABLED")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(DesignTokens.Opacity.textSubtle))
                            .cornerRadius(DesignTokens.Radius.minimal)
                    }
                }

                Text(account.provider.displayName + " • " + account.lastSyncedText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
            }

            Spacer()

            // Remove button
            Button {
                showRemoveConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(DesignTokens.Opacity.textTertiary))
                    .font(.subheadline)
                    .padding(DesignTokens.Spacing.inline)
                    .background(Color.red.opacity(DesignTokens.Opacity.overlayLight))
                    .cornerRadius(DesignTokens.Radius.chip)
            }
            .buttonStyle(PlainButtonStyle())
            .confirmationDialog(
                "Remove \(account.email)?",
                isPresented: $showRemoveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove Account", role: .destructive) {
                    onRemove()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will disconnect your account and remove all associated emails from the app.")
            }
        }
        .padding(DesignTokens.Spacing.component)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            account.isPrimary ? Color.green.opacity(DesignTokens.Opacity.overlayMedium) : Color.white.opacity(DesignTokens.Opacity.overlayLight),
                            lineWidth: 1
                        )
                )
        )
    }
}
