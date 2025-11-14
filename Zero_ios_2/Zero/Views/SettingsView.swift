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
    @State private var showDebugOverlay: Bool = false
    @State private var showModeIndicators: Bool = true
    @State private var isReloadingEmails = false
    @State private var showReloadAlert = false
    @State private var enableEmailSending: Bool = false
    @State private var showEmailSendingWarning = false
    @State private var vipFilterEnabled: Bool = false
    @State private var enableThreading: Bool = false

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

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.blue)
                                    Text("OpenAI API Key")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                }

                                if !AppEnvironment.openAIKey.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text("API key configured from build settings")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                        Text("AI Draft Composer is ready to use")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                    }
                                } else {
                                    Text("Required for AI Draft Composer feature")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                }

                                // Manual override option
                                DisclosureGroup {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Override the build configuration key with a custom value:")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

                                        HStack {
                                            SecureField("sk-...", text: $openAIKey)
                                                .textFieldStyle(.plain)
                                                .foregroundColor(.white)
                                                .padding(DesignTokens.Spacing.component)
                                                .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                                .cornerRadius(DesignTokens.Radius.chip)

                                            Button(action: saveAPIKey) {
                                                Text("Save")
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, DesignTokens.Spacing.section)
                                                    .padding(.vertical, DesignTokens.Spacing.component)
                                                    .background(Color.blue)
                                                    .cornerRadius(DesignTokens.Radius.chip)
                                            }
                                        }
                                    }
                                    .padding(.top, 8)
                                } label: {
                                    Text("Manual Override (Advanced)")
                                        .font(.caption)
                                        .foregroundColor(.blue.opacity(DesignTokens.Opacity.textTertiary))
                                }
                            }
                            .padding(DesignTokens.Spacing.section)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                    .fill(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                            .strokeBorder(Color.blue.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            // Gemini API Key
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "brain")
                                        .foregroundColor(.purple)
                                    Text("Gemini API Key")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                }

                                if !AppEnvironment.geminiAPIKey.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text("API key configured from build settings")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                        Text("Smart Replies and ML Classification are ready to use")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                    }
                                } else {
                                    Text("Required for Smart Replies and ML Classification")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                }

                                // Manual override option
                                DisclosureGroup {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Override the build configuration key with a custom value:")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

                                        HStack {
                                            SecureField("AIza...", text: $geminiAPIKey)
                                                .textFieldStyle(.plain)
                                                .foregroundColor(.white)
                                                .padding(DesignTokens.Spacing.component)
                                                .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                                .cornerRadius(DesignTokens.Radius.chip)

                                            Button(action: saveGeminiAPIKey) {
                                                Text("Save")
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, DesignTokens.Spacing.section)
                                                    .padding(.vertical, 12)
                                                    .background(Color.purple)
                                                    .cornerRadius(DesignTokens.Radius.chip)
                                            }
                                        }
                                    }
                                    .padding(.top, 8)
                                } label: {
                                    Text("Manual Override (Advanced)")
                                        .font(.caption)
                                        .foregroundColor(.purple.opacity(DesignTokens.Opacity.textTertiary))
                                }
                            }
                            .padding(DesignTokens.Spacing.section)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                    .fill(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                            .strokeBorder(Color.purple.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            // ML Classification Toggle
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $useMLClassification) {
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("ML Classification")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                            Text("Use ML-based intent detection for better accuracy")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                        }
                                    }
                                }
                                .tint(.blue)
                                .onChange(of: useMLClassification) {
                                    UserDefaults.standard.set(useMLClassification, forKey: "useMLClassification")
                                    showMLAlert = useMLClassification

                                    // Haptic feedback
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()

                                    Logger.info("ML Classification: \(useMLClassification ? "enabled" : "disabled")", category: .app)
                                }
                            }
                            .padding(DesignTokens.Spacing.section)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                    .fill(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                            .strokeBorder(Color.blue.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            // Email Sending Toggle (SAFETY FEATURE)
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $enableEmailSending) {
                                    HStack {
                                        Image(systemName: enableEmailSending ? "paperplane.fill" : "paperplane")
                                            .foregroundColor(enableEmailSending ? .red : .orange)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Enable Email Sending")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                            Text(enableEmailSending ? "⚠️ Emails will be sent for real" : "Safe mode: emails won't actually send")
                                                .font(.caption)
                                                .foregroundColor(enableEmailSending ? .red.opacity(DesignTokens.Opacity.textTertiary) : .white.opacity(DesignTokens.Opacity.textDisabled))
                                        }
                                    }
                                }
                                .tint(.red)
                                .onChange(of: enableEmailSending) {
                                    if enableEmailSending {
                                        showEmailSendingWarning = true
                                    } else {
                                        UserDefaults.standard.set(false, forKey: "enableEmailSending")
                                        Logger.info("Email sending disabled", category: .app)
                                    }

                                    // Haptic feedback
                                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                                    impact.impactOccurred()
                                }

                                // Warning message when disabled
                                if !enableEmailSending {
                                    HStack(spacing: 8) {
                                        Image(systemName: "shield.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                        Text("Safe mode active: Reply and compose features will simulate sending without actually sending emails. Enable this setting carefully when you're ready to send real emails.")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(DesignTokens.Spacing.component)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.green.opacity(DesignTokens.Opacity.glassLight))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .strokeBorder(Color.green.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                            .padding(DesignTokens.Spacing.section)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                    .fill(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                            .strokeBorder(enableEmailSending ? Color.red.opacity(DesignTokens.Opacity.overlayStrong) : Color.orange.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 2)
                                    )
                            )
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

                        // Model Tuning Section (Priority)
                        Button {
                            showModelTuning = true
                        } label: {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .font(.title3)
                                    .foregroundColor(.cyan)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Model Tuning")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Train Zero's AI on categories and actions")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(DesignTokens.Spacing.card)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.cyan.opacity(0.15),
                                                Color.purple.opacity(0.15)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [
                                                        Color.cyan.opacity(DesignTokens.Opacity.overlayStrong),
                                                        Color.purple.opacity(DesignTokens.Opacity.overlayStrong)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 16)
                        .padding(.top, 20)

                        // Simplified Email Time Range Section
                        Button {
                            // Navigate to time range settings (simplified)
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Email Time Range")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Fetching last \(viewModel.emailTimeRange.days) days")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                }
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(DesignTokens.Spacing.card)
                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                            .cornerRadius(DesignTokens.Radius.card)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 16)
                        .disabled(true) // TODO: Re-enable with dedicated settings page

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
                                .padding(DesignTokens.Spacing.card)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                                .strokeBorder(Color.white.opacity(DesignTokens.Opacity.glassLight), lineWidth: 1)
                                        )
                                )
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

                            Button {
                                // Reset to onboarding
                                viewModel.currentAppState = .onboarding
                                isPresented = false
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.title3)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Reset Onboarding")
                                            .font(.headline)
                                        Text("Go through the welcome flow again")
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
                                                .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayLight), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            // Debug Overlay Toggle
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $showDebugOverlay) {
                                    HStack {
                                        Image(systemName: "ant.fill")
                                            .foregroundColor(.yellow)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Debug Overlay")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                            Text("Show card counts and archetype distribution")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                        }
                                    }
                                }
                                .tint(.yellow)
                                .onChange(of: showDebugOverlay) {
                                    // Update feature flag
                                    if showDebugOverlay {
                                        services.featureGating.enable(.debugOverlays)
                                    } else {
                                        services.featureGating.disable(.debugOverlays)
                                    }

                                    // Haptic feedback
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()

                                    Logger.info("Debug Overlay: \(showDebugOverlay ? "enabled" : "disabled")", category: .app)
                                }
                            }
                            .padding(DesignTokens.Spacing.section)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                    .fill(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                            .strokeBorder(Color.yellow.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            // Mode Indicators Toggle
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $showModeIndicators) {
                                    HStack {
                                        Image(systemName: "circle.fill")
                                            .foregroundColor(.cyan)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Mode Indicators")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                            Text("Show status dots (VIP, deadline, newsletter, etc.)")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                        }
                                    }
                                }
                                .tint(.cyan)
                                .onChange(of: showModeIndicators) {
                                    UserDefaults.standard.set(showModeIndicators, forKey: "showModeIndicators")

                                    // Haptic feedback
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()

                                    Logger.info("Mode Indicators: \(showModeIndicators ? "enabled" : "disabled")", category: .app)
                                }
                            }
                            .padding(DesignTokens.Spacing.section)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                    .fill(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                            .strokeBorder(Color.cyan.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            // VIP Filter Toggle
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $vipFilterEnabled) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("VIP Filter")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                            Text("Show only emails from VIP contacts")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                        }
                                    }
                                }
                                .tint(.yellow)
                                .onChange(of: vipFilterEnabled) {
                                    VIPManager.shared.isVIPFilterEnabled = vipFilterEnabled
                                    Logger.info("VIP filter \(vipFilterEnabled ? "enabled" : "disabled")", category: .app)

                                    // Haptic feedback
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                }

                                // VIP count display
                                if !VIPManager.shared.vipContacts.isEmpty {
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.2.fill")
                                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                        Text("\(VIPManager.shared.vipContacts.count) VIP contact\(VIPManager.shared.vipContacts.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                    }
                                }
                            }
                            .padding(DesignTokens.Spacing.section)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                    .fill(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                            .strokeBorder(Color.yellow.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, DesignTokens.Spacing.section)

                            // Threading Toggle
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $enableThreading) {
                                    HStack {
                                        Image(systemName: "bubble.left.and.bubble.right.fill")
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Conversation Threading")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                            Text("Group related emails into conversation threads")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                                        }
                                    }
                                }
                                .tint(.blue)
                                .onChange(of: enableThreading) {
                                    UserDefaults.standard.set(enableThreading, forKey: "enableThreading")
                                    Logger.info("Threading \(enableThreading ? "enabled" : "disabled")", category: .app)

                                    // Haptic feedback
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                }
                            }
                            .padding(DesignTokens.Spacing.section)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                    .fill(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                            .strokeBorder(Color.blue.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                    )
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
            showDebugOverlay = services.featureGating.isEnabled(.debugOverlays)

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
        .sheet(isPresented: $showModelTuning) {
            ModelTuningView()
        }
        .alert("Emails Reloaded", isPresented: $showReloadAlert) {
            Button("OK") { }
        } message: {
            Text("Your inbox has been refreshed with the latest emails.")
        }
        .alert("⚠️ Enable Email Sending?", isPresented: $showEmailSendingWarning) {
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
