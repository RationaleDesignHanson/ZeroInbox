import SwiftUI

struct SafeModeSettingsView: View {
    @State private var currentMode: SafeModeService.SafeMode = SafeModeService.shared.currentMode
    @State private var testEmail: String = SafeModeService.shared.testEmail
    @State private var showingProductionWarning = false
    @State private var pendingMode: SafeModeService.SafeMode?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Safe Mode Settings")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("Control email sending behavior during testing")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.Spacing.card)

            Divider()
                .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

            ScrollView {
                VStack(spacing: 24) {
                    // Current Mode Display
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Mode")
                            .font(.headline)
                            .foregroundColor(.white)

                        HStack(spacing: 12) {
                            Image(systemName: currentMode.icon)
                                .font(.title2)
                                .foregroundColor(modeColor(for: currentMode))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentMode.rawValue.capitalized)
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text(currentMode.description)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                            }

                            Spacer()

                            Circle()
                                .fill(modeColor(for: currentMode))
                                .frame(width: 12, height: 12)
                        }
                        .padding()
                        .background(modeColor(for: currentMode).opacity(DesignTokens.Opacity.overlayLight))
                        .cornerRadius(DesignTokens.Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(modeColor(for: currentMode), lineWidth: 2)
                        )
                    }

                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    // Mode Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Mode")
                            .font(.headline)
                            .foregroundColor(.white)

                        // Read-Only Mode
                        ModeSelectionRow(
                            mode: .readOnly,
                            isSelected: currentMode == .readOnly,
                            onTap: { selectMode(.readOnly) }
                        )

                        // Demo Mode
                        ModeSelectionRow(
                            mode: .demo,
                            isSelected: currentMode == .demo,
                            onTap: { selectMode(.demo) }
                        )

                        // Production Mode
                        ModeSelectionRow(
                            mode: .production,
                            isSelected: currentMode == .production,
                            onTap: { selectMode(.production) }
                        )
                    }

                    // Test Email (Demo Mode Only)
                    if currentMode == .demo {
                        Divider()
                            .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Test Email Address")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("All emails will be redirected to this address in Demo Mode")
                                .font(.caption)
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))

                            TextField("", text: $testEmail)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                .cornerRadius(DesignTokens.Radius.button)
                                .foregroundColor(.white)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                )
                                .onChange(of: testEmail) { _, newValue in
                                    SafeModeService.shared.testEmail = newValue
                                }
                        }
                    }

                    // Statistics
                    Divider()
                        .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Statistics")
                            .font(.headline)
                            .foregroundColor(.white)

                        StatRow(
                            icon: "eye.slash.fill",
                            label: "Blocked Emails (Read-Only)",
                            value: "\(SafeModeService.shared.blockedEmailCount)",
                            color: .blue
                        )

                        StatRow(
                            icon: "arrow.triangle.2.circlepath",
                            label: "Redirected Emails (Demo)",
                            value: "\(SafeModeService.shared.redirectedEmailCount)",
                            color: .orange
                        )

                        Button {
                            SafeModeService.shared.resetStatistics()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Reset Statistics")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(DesignTokens.Opacity.overlayLight))
                            .cornerRadius(DesignTokens.Radius.chip)
                        }
                    }

                    // Info Box
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("How It Works")
                                .font(.headline)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SafeModeInfoRow(
                                icon: "eye.slash",
                                text: "Read-Only: No emails sent. All sends are simulated."
                            )
                            SafeModeInfoRow(
                                icon: "arrow.triangle.swap",
                                text: "Demo: Emails redirected to your test address."
                            )
                            SafeModeInfoRow(
                                icon: "checkmark.shield",
                                text: "Production: Normal operation. Real emails sent."
                            )
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(DesignTokens.Opacity.overlayLight))
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .alert("Switch to Production Mode?", isPresented: $showingProductionWarning) {
            Button("Cancel", role: .cancel) {
                pendingMode = nil
            }
            Button("Confirm", role: .destructive) {
                if let mode = pendingMode {
                    applyMode(mode)
                }
            }
        } message: {
            Text("⚠️ Production Mode will send REAL emails to REAL people. Are you sure?")
        }
    }

    func selectMode(_ mode: SafeModeService.SafeMode) {
        if SafeModeService.shared.requiresConfirmation(for: mode) {
            pendingMode = mode
            showingProductionWarning = true
        } else {
            applyMode(mode)
        }
    }

    func applyMode(_ mode: SafeModeService.SafeMode) {
        SafeModeService.shared.currentMode = mode
        currentMode = mode
        pendingMode = nil

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(mode == .production ? .warning : .success)
    }

    func modeColor(for mode: SafeModeService.SafeMode) -> Color {
        switch mode {
        case .production: return .green
        case .demo: return .orange
        case .readOnly: return .blue
        }
    }
}

struct ModeSelectionRow: View {
    let mode: SafeModeService.SafeMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: mode.icon)
                    .font(.title3)
                    .foregroundColor(modeColor)
                    .frame(width: 40, height: 40)
                    .background(modeColor.opacity(DesignTokens.Opacity.overlayLight))
                    .cornerRadius(DesignTokens.Radius.button)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue.capitalized)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(modeColor)
                }
            }
            .padding()
            .background(isSelected ? modeColor.opacity(DesignTokens.Opacity.overlayLight) : Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
            .cornerRadius(DesignTokens.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? modeColor : Color.white.opacity(DesignTokens.Opacity.glassLight), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    var modeColor: Color {
        switch mode {
        case .production: return .green
        case .demo: return .orange
        case .readOnly: return .blue
        }
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))

            Spacer()

            Text(value)
                .font(.headline.bold())
                .foregroundColor(color)
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.chip)
    }
}

struct SafeModeInfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                .font(.caption)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
        }
    }
}

#Preview {
    SafeModeSettingsView()
}
