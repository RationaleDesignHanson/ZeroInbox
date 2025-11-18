import SwiftUI

/// Reusable API key setting card component
/// Eliminates ~65 lines of duplicate code per API key setting
struct SettingAPIKeyCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let environmentKey: String
    let storageKey: String
    let configuredMessage: String
    let readyMessage: String
    let placeholder: String

    @State private var manualKey: String = ""
    @State private var showManualOverride = false
    @State private var savedConfirmation = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.headline)
                    .foregroundColor(textColor)
            }

            // Status or description
            if !environmentKey.isEmpty {
                // API key configured via environment
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(configuredMessage)
                        .font(.caption)
                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.textSubtle))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.green.opacity(DesignTokens.Opacity.glassUltraLight))
                .cornerRadius(DesignTokens.Radius.chip)

                if !manualKey.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Manual override active")
                            .font(.caption)
                            .foregroundColor(textColor.opacity(DesignTokens.Opacity.textSubtle))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.blue.opacity(DesignTokens.Opacity.glassUltraLight))
                    .cornerRadius(DesignTokens.Radius.chip)
                }
            } else if !manualKey.isEmpty {
                // Manual key configured
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(readyMessage)
                        .font(.caption)
                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.textSubtle))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.green.opacity(DesignTokens.Opacity.glassUltraLight))
                .cornerRadius(DesignTokens.Radius.chip)
            } else {
                // No key configured
                Text(description)
                    .font(.caption)
                    .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
            }

            // Manual override disclosure
            DisclosureGroup(isExpanded: $showManualOverride) {
                VStack(alignment: .leading, spacing: 12) {
                    SecureField(placeholder, text: $manualKey)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    HStack {
                        Button("Save") {
                            saveManualKey()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(color)
                        .disabled(manualKey.isEmpty)

                        if !manualKey.isEmpty {
                            Button("Clear") {
                                clearManualKey()
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }

                        Spacer()

                        if savedConfirmation {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                                Text("Saved")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            } label: {
                HStack {
                    Text("Manual Override")
                        .font(.subheadline)
                        .foregroundColor(color)
                    Spacer()
                }
            }
            .tint(color)
        }
        .glassCard(borderColor: color)
        .padding(.horizontal, DesignTokens.Spacing.section)
        .onAppear {
            loadManualKey()
        }
    }

    private var textColor: Color {
        // Settings screen always has dark background, so always use white text
        .white
    }

    private func loadManualKey() {
        if let savedKey = UserDefaults.standard.string(forKey: storageKey) {
            manualKey = savedKey
        }
    }

    private func saveManualKey() {
        UserDefaults.standard.set(manualKey, forKey: storageKey)
        Logger.info("Manual \(title) saved to UserDefaults", category: .userPreferences)

        // Show confirmation
        savedConfirmation = true
        HapticService.shared.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                savedConfirmation = false
            }
        }
    }

    private func clearManualKey() {
        manualKey = ""
        UserDefaults.standard.removeObject(forKey: storageKey)
        Logger.info("Manual \(title) cleared from UserDefaults", category: .userPreferences)
        HapticService.shared.lightImpact()
    }
}
