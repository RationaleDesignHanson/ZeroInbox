//
//  BuildInfoView.swift
//  Zero
//
//  Created by Claude Code on 11/17/25.
//

import SwiftUI

/**
 * BuildInfoView - Displays app version, build info, and environment details
 *
 * Useful for:
 * - Debugging issues with specific builds
 * - Verifying correct backend configuration
 * - Support requests (users can provide version info)
 */
struct BuildInfoView: View {
    @Environment(\.presentationMode) var presentationMode

    // MARK: - Build Information

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }

    private var environment: String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }

    private var buildDate: String {
        // This would need to be injected at build time via build script
        // For now, we'll show a placeholder
        "Build time not available"
    }

    // MARK: - Backend URLs

    private var gatewayURL: String {
        Constants.API.Production.gatewayBaseURL
    }

    private var analyticsURL: String {
        APIConfig.analyticsURL
    }

    private var classificationURL: String {
        APIConfig.classificationURL
    }

    // MARK: - Device Info

    private var deviceModel: String {
        UIDevice.current.model
    }

    private var systemVersion: String {
        UIDevice.current.systemVersion
    }

    private var deviceName: String {
        UIDevice.current.name
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.08, blue: 0.15),
                        Color(red: 0.15, green: 0.10, blue: 0.20),
                        Color(red: 0.08, green: 0.12, blue: 0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))

                            Text("Build Information")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)

                            Text("Version \(appVersion) (\(buildNumber))")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                        }
                        .padding(.top, 40)

                        // App Info Section
                        InfoSection(title: "App Information") {
                            BuildInfoRow(label: "Version", value: appVersion)
                            BuildInfoRow(label: "Build Number", value: buildNumber)
                            BuildInfoRow(label: "Build Type", value: Constants.AppInfo.buildType)
                            BuildInfoRow(label: "Environment", value: environment)
                            BuildInfoRow(label: "Bundle ID", value: bundleIdentifier)
                            BuildInfoRow(label: "Build Date", value: buildDate)
                        }

                        // Device Info Section
                        InfoSection(title: "Device Information") {
                            BuildInfoRow(label: "Device", value: deviceModel)
                            BuildInfoRow(label: "iOS Version", value: systemVersion)
                            BuildInfoRow(label: "Device Name", value: deviceName)
                        }

                        // Backend Configuration Section
                        InfoSection(title: "Backend Configuration") {
                            BuildInfoRow(label: "Gateway API", value: gatewayURL, monospace: true)
                            BuildInfoRow(label: "Analytics API", value: analyticsURL, monospace: true)
                            BuildInfoRow(label: "Classification API", value: classificationURL, monospace: true)
                        }

                        // Support Section
                        InfoSection(title: "Support") {
                            BuildInfoRow(label: "Email", value: Constants.AppInfo.supportEmail)

                            Button {
                                // Copy all info to clipboard
                                copyAllInfoToClipboard()
                            } label: {
                                HStack {
                                    Image(systemName: "doc.on.doc.fill")
                                        .font(.title3)

                                    Text("Copy All Info")
                                        .font(.headline)

                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(DesignTokens.Spacing.card)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                                                .strokeBorder(Color.cyan.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.section)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func copyAllInfoToClipboard() {
        let info = """
        Zero Inbox - Build Information

        App Information:
        - Version: \(appVersion)
        - Build Number: \(buildNumber)
        - Build Type: \(Constants.AppInfo.buildType)
        - Environment: \(environment)
        - Bundle ID: \(bundleIdentifier)

        Device Information:
        - Device: \(deviceModel)
        - iOS Version: \(systemVersion)
        - Device Name: \(deviceName)

        Backend Configuration:
        - Gateway API: \(gatewayURL)
        - Analytics API: \(analyticsURL)
        - Classification API: \(classificationURL)

        Support: \(Constants.AppInfo.supportEmail)
        """

        UIPasteboard.general.string = info
        HapticService.shared.success()

        Logger.info("Build info copied to clipboard", category: .action)
    }
}

// MARK: - Info Section

private struct InfoSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSecondary))
                .padding(.horizontal, DesignTokens.Spacing.card)

            VStack(spacing: 0) {
                content
            }
            .glassCard(
                borderColor: .white,
                borderOpacity: DesignTokens.Opacity.glassLight,
                padding: DesignTokens.Spacing.card
            )
        }
    }
}

// MARK: - Info Row

private struct BuildInfoRow: View {
    let label: String
    let value: String
    var monospace: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))

                Spacer()
            }

            HStack {
                Text(value)
                    .font(monospace ? .system(.caption, design: .monospaced) : .body)
                    .foregroundColor(.white)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)

                Spacer()
            }

            Divider()
                .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Preview

#if DEBUG
struct BuildInfoView_Previews: PreviewProvider {
    static var previews: some View {
        BuildInfoView()
    }
}
#endif
