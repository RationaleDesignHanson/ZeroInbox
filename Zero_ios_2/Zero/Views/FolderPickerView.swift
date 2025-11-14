//
//  FolderPickerView.swift
//  Zero
//
//  Created by Claude Code on 10/25/25.
//

import SwiftUI

/**
 * FolderPickerView - Select folder to save email
 *
 * Shows list of existing folders + option to create new folder
 * User can tap a folder to save the email there
 */
struct FolderPickerView: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    @StateObject private var savedMailService = SavedMailService.shared
    @State private var showCreateFolder = false
    @State private var showError: String?
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    /// Computed user ID from Keychain
    private var userId: String {
        getUserEmail() ?? "user-123"
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Email preview header
                    emailPreviewHeader
                        .padding()
                        .background(headerBackgroundColor)

                    if savedMailService.isLoading {
                        // Loading state
                        VStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading folders...")
                                .font(.caption)
                                .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                                .padding(.top, 16)
                            Spacer()
                        }
                    } else if savedMailService.folders.isEmpty {
                        // Empty state
                        emptyState
                    } else {
                        // Folder list
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(savedMailService.folders) { folder in
                                    FolderRow(folder: folder)
                                        .onTapGesture {
                                            saveToFolder(folder)
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Save to Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateFolder = true
                    } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateFolder) {
                CreateFolderView(
                    onFolderCreated: { folder in
                        showCreateFolder = false
                        // Automatically save email to the newly created folder
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            saveToFolder(folder)
                        }
                    }
                )
            }
            .alert("Error", isPresented: .constant(showError != nil)) {
                Button("OK") {
                    showError = nil
                }
            } message: {
                if let error = showError {
                    Text(error)
                }
            }
        }
        .onAppear {
            loadFolders()
        }
    }

    // MARK: - Subviews

    private var emailPreviewHeader: some View {
        HStack(spacing: 12) {
            // Email icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: gradientColors(for: card.type),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "envelope.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }

            // Email info
            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(.headline)
                    .foregroundColor(textColor)
                    .lineLimit(1)

                Text(card.summary)
                    .font(.caption)
                    .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "folder.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(textColor.opacity(DesignTokens.Opacity.overlayMedium))

            VStack(spacing: 8) {
                Text("No Folders Yet")
                    .font(.title2.bold())
                    .foregroundColor(textColor)

                Text("Create a folder to organize your important emails")
                    .font(.subheadline)
                    .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                showCreateFolder = true
            } label: {
                Label("Create First Folder", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(DesignTokens.Radius.button)
            }
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Actions

    private func loadFolders() {
        Task {
            do {
                _ = try await savedMailService.fetchFolders(userId: userId)
            } catch {
                await MainActor.run {
                    showError = error.localizedDescription
                }
                Logger.error("Failed to load folders: \(error.localizedDescription)", category: .savedMail)
            }
        }
    }

    private func saveToFolder(_ folder: SavedMailFolder) {
        HapticService.shared.success()

        Task {
            do {
                _ = try await savedMailService.addEmailToFolder(
                    userId: userId,
                    folderId: folder.id,
                    emailId: card.id
                )

                // Success - dismiss sheet
                await MainActor.run {
                    isPresented = false
                }

                Logger.info("✅ Saved email to folder: \(folder.name)", category: .savedMail)

            } catch {
                await MainActor.run {
                    showError = error.localizedDescription
                }
                Logger.error("Failed to save email to folder: \(error.localizedDescription)", category: .savedMail)
            }
        }
    }

    /// Get user email from Keychain (same logic as ContentView)
    private func getUserEmail() -> String? {
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")
        if useMockData {
            return nil
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "EmailShortForm",
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let attributes = result as? [String: Any],
           let emailData = attributes[kSecAttrAccount as String] as? String {
            return emailData
        }

        return nil
    }

    // MARK: - Helper Methods

    private func gradientColors(for type: CardType) -> [Color] {
        let modern = type
        switch modern {
        case .mail:
            return [Color(red: 0.388, green: 0.6, blue: 0.945), Color(red: 0.2, green: 0.714, blue: 0.835)]
        case .ads:
            return [Color(red: 0.953, green: 0.612, blue: 0.071), Color(red: 0.988, green: 0.765, blue: 0.333)]
        }
    }

    // MARK: - Computed Colors

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.10) : Color(white: 0.95)
    }

    private var headerBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
}

// MARK: - Folder Row

struct FolderRow: View {
    let folder: SavedMailFolder
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 16) {
            // Folder color indicator with appropriate icon
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: folder.displayColor))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: folder.displayIcon)
                        .font(.system(size: folder.isPreset ? 20 : 18))
                        .foregroundColor(.white)
                )

            // Folder info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(folder.name)
                        .font(.headline)
                        .foregroundColor(textColor)

                    // Preset badge (smaller in picker)
                    if folder.isPreset {
                        Text("PRESET")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(DesignTokens.Opacity.textSubtle))
                            .cornerRadius(3)
                    }
                }

                Text("\(folder.emailCount) \(folder.emailCount == 1 ? "email" : "emails")")
                    .font(.caption)
                    .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(textColor.opacity(DesignTokens.Opacity.overlayMedium))
        }
        .padding(DesignTokens.Spacing.section)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                .fill(rowBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
        )
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    private var rowBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(DesignTokens.Opacity.glassLight) : Color.black.opacity(DesignTokens.Opacity.glassUltraLight)
    }
}

// MARK: - Preview

// Preview removed - requires complex EmailCard initialization
