//
//  CreateFolderView.swift
//  Zero
//
//  Created by Claude Code on 10/25/25.
//

import SwiftUI

/**
 * CreateFolderView - Create a new custom folder
 *
 * Allows user to:
 * - Name the folder
 * - Pick a color
 * - Create the folder
 */
struct CreateFolderView: View {
    @Environment(\.dismiss) var dismiss: DismissAction
    @StateObject private var savedMailService = SavedMailService.shared
    @State private var folderName: String = ""
    @State private var selectedColor: String = SavedMailFolder.colorPalette[0]
    @State private var showError: String?
    @State private var isCreating: Bool = false
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var onFolderCreated: ((SavedMailFolder) -> Void)?

    /// Computed user ID from Keychain
    private var userId: String {
        getUserEmail() ?? AuthContext.getUserId()
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Folder preview
                        folderPreview
                            .padding(.top, 24)

                        // Folder name input
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                            Text("Folder Name")
                                .font(.headline)
                                .foregroundColor(textColor)

                            TextField("Enter folder name", text: $folderName)
                                .font(.body)
                                .padding(DesignTokens.Spacing.section)
                                .background(inputBackgroundColor)
                                .cornerRadius(DesignTokens.Radius.button)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                        .strokeBorder(borderColor, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)

                        // Color picker
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                            Text("Folder Color")
                                .font(.headline)
                                .foregroundColor(textColor)
                                .padding(.horizontal)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                                ForEach(SavedMailFolder.colorPalette, id: \.self) { color in
                                    ColorCircle(
                                        color: color,
                                        isSelected: color == selectedColor,
                                        onTap: {
                                            selectedColor = color
                                            HapticService.shared.lightImpact()
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Create button
                        Button {
                            createFolder()
                        } label: {
                            HStack {
                                if isCreating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Label("Create Folder", systemImage: "folder.badge.plus")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: canCreate ? [Color.blue, Color.cyan] : [Color.gray, Color.gray],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                        .disabled(!canCreate || isCreating)
                        .padding(.horizontal)
                        .padding(.top, DesignTokens.Spacing.inline)

                        Spacer()
                    }
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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
    }

    // MARK: - Subviews

    private var folderPreview: some View {
        VStack(spacing: DesignTokens.Spacing.section) {
            // Large folder icon with selected color
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: selectedColor),
                                Color(hex: selectedColor).opacity(DesignTokens.Opacity.textTertiary)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color(hex: selectedColor).opacity(DesignTokens.Opacity.overlayMedium), radius: 20, y: 10)

                Image(systemName: "folder.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }

            // Folder name preview
            Text(folderName.isEmpty ? "New Folder" : folderName)
                .font(.title2.bold())
                .foregroundColor(textColor)
                .lineLimit(1)
        }
    }

    // MARK: - Computed Properties

    private var canCreate: Bool {
        !folderName.isEmpty && folderName.count <= 200 && !isCreating
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.10) : Color(white: 0.95)
    }

    private var inputBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(DesignTokens.Opacity.glassLight) : Color.black.opacity(DesignTokens.Opacity.glassUltraLight)
    }

    // MARK: - Actions

    private func createFolder() {
        guard !folderName.isEmpty else {
            showError = "Please enter a folder name"
            return
        }

        isCreating = true
        HapticService.shared.mediumImpact()

        Task {
            do {
                let folder = try await savedMailService.createFolder(
                    userId: userId,
                    name: folderName,
                    color: selectedColor
                )

                await MainActor.run {
                    isCreating = false
                    HapticService.shared.success()
                    dismiss()
                    onFolderCreated?(folder)
                }

                Logger.info("✅ Created folder: \(folderName)", category: .savedMail)

            } catch {
                await MainActor.run {
                    isCreating = false
                    showError = error.localizedDescription
                }
                Logger.error("Failed to create folder: \(error.localizedDescription)", category: .savedMail)
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
}

// MARK: - Color Circle

struct ColorCircle: View {
    let color: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(Color(hex: color))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? Color.white : Color.clear,
                                lineWidth: 3
                            )
                    )
                    .shadow(
                        color: isSelected ? Color(hex: color).opacity(DesignTokens.Opacity.overlayStrong) : Color.clear,
                        radius: 8,
                        y: 4
                    )

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Preview

#if DEBUG
struct CreateFolderView_Previews: PreviewProvider {
    static var previews: some View {
        CreateFolderView()
    }
}
#endif
