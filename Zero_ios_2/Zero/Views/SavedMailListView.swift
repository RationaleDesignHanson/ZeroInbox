//
//  SavedMailListView.swift
//  Zero
//
//  Created by Claude Code on 10/25/25.
//

import SwiftUI

/**
 * SavedMailListView - Main view for browsing saved email folders
 *
 * Shows all user-created folders with email counts
 * Allows navigation to folder details
 * Supports creating new folders
 */
struct SavedMailListView: View {
    @Binding var isPresented: Bool
    @StateObject private var savedMailService = SavedMailService.shared
    @EnvironmentObject var emailViewModel: EmailViewModel
    @State private var showCreateFolder = false
    @State private var showError: String?
    @State private var editMode: EditMode = .inactive
    @State private var selectedFolder: SavedMailFolder?
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    /// Computed user ID from Keychain
    private var userId: String {
        getUserEmail() ?? "user-123"
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()

                if savedMailService.isLoading {
                    loadingView
                } else if savedMailService.folders.isEmpty {
                    emptyState
                } else {
                    folderList
                }
            }
            .navigationTitle("Saved Mail")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        isPresented = false
                    }
                    .font(.body)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if !savedMailService.folders.isEmpty {
                            EditButton()
                                .environment(\.editMode, $editMode)
                        }

                        Button {
                            showCreateFolder = true
                        } label: {
                            Image(systemName: "folder.badge.plus")
                                .font(.title3)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateFolder) {
                CreateFolderView(
                    onFolderCreated: { folder in
                        showCreateFolder = false
                        // Refresh folders list
                        loadFolders()
                    }
                )
            }
            .sheet(item: $selectedFolder) { folder in
                FolderDetailView(
                    folder: folder,
                    isPresented: Binding(
                        get: { selectedFolder != nil },
                        set: { if !$0 { selectedFolder = nil } }
                    )
                )
                .environmentObject(emailViewModel)
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

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading folders...")
                .font(.subheadline)
                .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 72))
                .foregroundColor(textColor.opacity(DesignTokens.Opacity.overlayMedium))

            VStack(spacing: 12) {
                Text("No Saved Folders")
                    .font(.title2.bold())
                    .foregroundColor(textColor)

                Text("Create folders to organize and save important emails for easy access later")
                    .font(.body)
                    .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                showCreateFolder = true
            } label: {
                Label("Create First Folder", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
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
        }
    }

    private var folderList: some View {
        List {
            // Preset Folders Section
            if !presetFolders.isEmpty {
                Section(header: Text("Preset Folders")
                    .font(.subheadline)
                    .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))) {
                    ForEach(presetFolders) { folder in
                        Button {
                            selectedFolder = folder
                        } label: {
                            FolderListRow(folder: folder)
                        }
                        .listRowBackground(rowBackgroundColor)
                    }
                }
            }

            // Custom Folders Section
            if !customFolders.isEmpty {
                Section(header: HStack {
                    Text("Custom Folders")
                        .font(.subheadline)
                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                    Spacer()
                    Text("\(customFolders.count)/10")
                        .font(.caption)
                        .foregroundColor(textColor.opacity(0.4))
                }) {
                    ForEach(customFolders) { folder in
                        Button {
                            selectedFolder = folder
                        } label: {
                            FolderListRow(folder: folder)
                        }
                        .listRowBackground(rowBackgroundColor)
                    }
                    .onDelete(perform: deleteCustomFolders)
                    .onMove(perform: moveCustomFolders)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .environment(\.editMode, $editMode)
    }

    // Computed properties for folder categories
    private var presetFolders: [SavedMailFolder] {
        savedMailService.folders.filter { $0.isPreset }
    }

    private var customFolders: [SavedMailFolder] {
        savedMailService.folders.filter { !$0.isPreset }
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

    private func deleteCustomFolders(at offsets: IndexSet) {
        // Only delete custom folders
        for index in offsets {
            let folder = customFolders[index]

            Task {
                do {
                    try await savedMailService.deleteFolder(userId: userId, folderId: folder.id)
                } catch {
                    await MainActor.run {
                        showError = error.localizedDescription
                    }
                    Logger.error("Failed to delete folder: \(error.localizedDescription)", category: .savedMail)
                }
            }
        }
    }

    private func moveCustomFolders(from source: IndexSet, to destination: Int) {
        // Only reorder custom folders - preset folders stay at top
        var custom = customFolders
        custom.move(fromOffsets: source, toOffset: destination)

        // Combine preset + reordered custom
        let allFolders = presetFolders + custom
        let folderIds = allFolders.map { $0.id }

        Task {
            do {
                _ = try await savedMailService.reorderFolders(userId: userId, folderIds: folderIds)
            } catch {
                await MainActor.run {
                    showError = error.localizedDescription
                }
                Logger.error("Failed to reorder folders: \(error.localizedDescription)", category: .savedMail)
            }
        }
    }

    /// Get user email from Keychain (same logic as ContentView)
    /// In mock mode, returns a mock user ID to allow saved mail functionality
    private func getUserEmail() -> String? {
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")
        if useMockData {
            return "mock-user"  // Return mock user ID for demo/testing
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

    // MARK: - Computed Colors

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.10) : Color(white: 0.95)
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    private var rowBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }
}

// MARK: - Folder List Row

struct FolderListRow: View {
    let folder: SavedMailFolder
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @EnvironmentObject var emailViewModel: EmailViewModel

    // Priority statistics for this folder
    private var priorityStats: [Priority: Int] {
        let folderEmails = emailViewModel.cards.filter { card in
            folder.emailIds.contains(card.id)
        }

        var stats: [Priority: Int] = [
            .critical: 0,
            .high: 0,
            .medium: 0,
            .low: 0
        ]

        for email in folderEmails {
            stats[email.priority, default: 0] += 1
        }

        return stats
    }

    var body: some View {
        HStack(spacing: 16) {
            // Folder color indicator with appropriate icon
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: folder.displayColor))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: folder.displayIcon)
                        .font(.system(size: folder.isPreset ? 24 : 22))
                        .foregroundColor(.white)
                )
                .shadow(color: Color(hex: folder.displayColor).opacity(DesignTokens.Opacity.overlayMedium), radius: 4, y: 2)

            // Folder info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(folder.name)
                        .font(.headline)
                        .foregroundColor(textColor)
                        .lineLimit(1)

                    // Preset badge
                    if folder.isPreset {
                        Text("PRESET")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(DesignTokens.Opacity.textSubtle))
                            .cornerRadius(DesignTokens.Radius.minimal)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "envelope.fill")
                        .font(.caption2)
                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.overlayStrong))

                    Text("\(folder.emailCount) \(folder.emailCount == 1 ? "email" : "emails")")
                        .font(.subheadline)
                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.textDisabled))
                }

                // Priority distribution pills
                if folder.emailCount > 0 {
                    HStack(spacing: 4) {
                        ForEach([Priority.critical, Priority.high, Priority.medium, Priority.low], id: \.self) { priority in
                            if let count = priorityStats[priority], count > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: priority.icon)
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(Color(hex: priority.color))

                                    Text("\(count)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(textColor.opacity(DesignTokens.Opacity.textSubtle))
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color(hex: priority.color).opacity(0.15))
                                .cornerRadius(DesignTokens.Radius.minimal)
                            }
                        }
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(textColor.opacity(DesignTokens.Opacity.overlayMedium))
        }
        .padding(.vertical, 4)
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
}

// MARK: - Preview

// Preview removed - requires complex EmailViewModel initialization
