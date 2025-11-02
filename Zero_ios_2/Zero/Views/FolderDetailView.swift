//
//  FolderDetailView.swift
//  Zero
//
//  Created by Claude Code on 10/25/25.
//

import SwiftUI

/**
 * FolderDetailView - Shows emails within a specific folder
 *
 * Displays all emails saved to this folder
 * Allows removing emails from folder
 * Supports folder renaming and deletion
 */
struct FolderDetailView: View {
    let folder: SavedMailFolder
    @Binding var isPresented: Bool
    @StateObject private var savedMailService = SavedMailService.shared
    @EnvironmentObject var emailViewModel: EmailViewModel
    @State private var showRenameSheet = false
    @State private var showDeleteAlert = false
    @State private var showError: String?
    @State private var selectedEmailCard: EmailCard?
    @State private var selectedPriorityFilter: Priority? = nil  // nil = show all
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    /// Computed user ID from Keychain
    private var userId: String {
        getUserEmail() ?? "user-123"
    }

    // Computed property to get email cards for this folder
    private var folderEmails: [EmailCard] {
        let allEmails = emailViewModel.cards.filter { card in
            folder.emailIds.contains(card.id)
        }

        // Apply priority filter if selected
        if let priorityFilter = selectedPriorityFilter {
            return allEmails.filter { $0.priority == priorityFilter }
        }

        return allEmails
    }

    // Priority statistics for this folder
    private var priorityStats: [Priority: Int] {
        let allEmails = emailViewModel.cards.filter { card in
            folder.emailIds.contains(card.id)
        }

        var stats: [Priority: Int] = [
            .critical: 0,
            .high: 0,
            .medium: 0,
            .low: 0
        ]

        for email in allEmails {
            stats[email.priority, default: 0] += 1
        }

        return stats
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()

                if folderEmails.isEmpty && selectedPriorityFilter != nil {
                    // Empty state for filtered view
                    emptyFilteredState
                } else if folderEmails.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        // Priority filter section
                        priorityFilterSection
                            .padding(.vertical, 12)
                            .background(backgroundColor)

                        emailList
                    }
                }
            }
            .navigationTitle(folder.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    // Only show edit menu for custom folders
                    if !folder.isPreset {
                        Menu {
                            Button {
                                showRenameSheet = true
                            } label: {
                                Label("Rename Folder", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                showDeleteAlert = true
                            } label: {
                                Label("Delete Folder", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                        }
                    }
                }
            }
            .sheet(isPresented: $showRenameSheet) {
                RenameFolderView(
                    folder: folder,
                    isPresented: $showRenameSheet
                )
            }
            .sheet(item: $selectedEmailCard) { card in
                EmailDetailView(card: card)
            }
            .alert("Delete Folder?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteFolder()
                }
            } message: {
                Text("This will permanently delete \"\(folder.name)\" and remove all \(folder.emailCount) saved emails from it. The original emails will remain in your inbox.")
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

    /// Priority filter section with chips
    private var priorityFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All" filter chip
                PriorityFilterChip(
                    label: "All",
                    count: priorityStats.values.reduce(0, +),
                    isSelected: selectedPriorityFilter == nil,
                    color: "#8E8E93",
                    icon: "tray.fill",
                    onTap: {
                        HapticService.shared.lightImpact()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPriorityFilter = nil
                        }
                    }
                )

                // Priority filter chips
                ForEach([Priority.critical, Priority.high, Priority.medium, Priority.low], id: \.self) { priority in
                    PriorityFilterChip(
                        label: priority.displayName,
                        count: priorityStats[priority] ?? 0,
                        isSelected: selectedPriorityFilter == priority,
                        color: priority.color,
                        icon: priority.icon,
                        onTap: {
                            HapticService.shared.lightImpact()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPriorityFilter = priority
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private var emptyFilteredState: some View {
        VStack(spacing: 24) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 64))
                .foregroundColor(textColor.opacity(0.3))

            VStack(spacing: 8) {
                if let priority = selectedPriorityFilter {
                    Text("No \(priority.displayName) Priority Emails")
                        .font(.title3.bold())
                        .foregroundColor(textColor)

                    Text("There are no emails with \(priority.displayName.lowercased()) priority in this folder")
                        .font(.subheadline)
                        .foregroundColor(textColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }

            Button {
                withAnimation {
                    selectedPriorityFilter = nil
                }
            } label: {
                Text("Show All Emails")
                    .font(.subheadline.bold())
                    .foregroundColor(.blue)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundColor(textColor.opacity(0.3))

            VStack(spacing: 8) {
                Text("No Emails")
                    .font(.title3.bold())
                    .foregroundColor(textColor)

                Text("Swipe down on any email and save it to this folder")
                    .font(.subheadline)
                    .foregroundColor(textColor.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    private var emailList: some View {
        List {
            ForEach(folderEmails) { card in
                Button {
                    selectedEmailCard = card
                } label: {
                    EmailListRow(card: card)
                }
                .listRowBackground(rowBackgroundColor)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        removeEmail(card)
                    } label: {
                        Label("Remove", systemImage: "folder.badge.minus")
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }

    // MARK: - Actions

    private func removeEmail(_ card: EmailCard) {
        HapticService.shared.mediumImpact()

        Task {
            do {
                _ = try await savedMailService.removeEmailFromFolder(
                    userId: userId,
                    folderId: folder.id,
                    emailId: card.id
                )

                Logger.info("✅ Removed email from folder", category: .savedMail)

            } catch {
                await MainActor.run {
                    showError = error.localizedDescription
                }
                Logger.error("Failed to remove email: \(error.localizedDescription)", category: .savedMail)
            }
        }
    }

    private func deleteFolder() {
        HapticService.shared.heavyImpact()

        Task {
            do {
                try await savedMailService.deleteFolder(userId: userId, folderId: folder.id)

                await MainActor.run {
                    isPresented = false
                }

                Logger.info("✅ Deleted folder", category: .savedMail)

            } catch {
                await MainActor.run {
                    showError = error.localizedDescription
                }
                Logger.error("Failed to delete folder: \(error.localizedDescription)", category: .savedMail)
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

// MARK: - Email List Row

struct EmailListRow: View {
    let card: EmailCard
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Category indicator
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: gradientColors(for: card.type),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 4, height: 60)

            // Email info
            VStack(alignment: .leading, spacing: 6) {
                Text(card.title)
                    .font(.headline)
                    .foregroundColor(textColor)
                    .lineLimit(2)

                Text(card.summary)
                    .font(.subheadline)
                    .foregroundColor(textColor.opacity(0.6))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(card.timeAgo)
                        .font(.caption)
                        .foregroundColor(textColor.opacity(0.5))

                    // Show priority badge for all levels
                    HStack(spacing: 4) {
                        Image(systemName: card.priority.icon)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)

                        Text(card.priority.displayName.uppercased())
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(hex: card.priority.color))
                    .cornerRadius(4)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    private func gradientColors(for type: CardType) -> [Color] {
        let modern = type
        switch modern {
        case .mail:
            return [Color(red: 0.388, green: 0.6, blue: 0.945), Color(red: 0.2, green: 0.714, blue: 0.835)]
        case .ads:
            return [Color(red: 0.953, green: 0.612, blue: 0.071), Color(red: 0.988, green: 0.765, blue: 0.333)]
        }
    }
}

// MARK: - Rename Folder View

struct RenameFolderView: View {
    let folder: SavedMailFolder
    @Binding var isPresented: Bool
    @StateObject private var savedMailService = SavedMailService.shared
    @State private var newName: String
    @State private var selectedColor: String
    @State private var showError: String?
    @State private var isUpdating = false
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    /// Computed user ID from Keychain
    private var userId: String {
        getUserEmail() ?? "user-123"
    }

    init(folder: SavedMailFolder, isPresented: Binding<Bool>) {
        self.folder = folder
        self._isPresented = isPresented
        self._newName = State(initialValue: folder.name)
        self._selectedColor = State(initialValue: folder.color ?? SavedMailFolder.colorPalette[0])
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
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Folder Name")
                                .font(.headline)
                                .foregroundColor(textColor)

                            TextField("Enter folder name", text: $newName)
                                .font(.body)
                                .padding(16)
                                .background(inputBackgroundColor)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(borderColor, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)

                        // Color picker
                        VStack(alignment: .leading, spacing: 16) {
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

                        // Update button
                        Button {
                            updateFolder()
                        } label: {
                            HStack {
                                if isUpdating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Label("Update Folder", systemImage: "checkmark.circle.fill")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: canUpdate ? [Color.blue, Color.cyan] : [Color.gray, Color.gray],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .disabled(!canUpdate || isUpdating)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Edit Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
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
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: selectedColor),
                                Color(hex: selectedColor).opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color(hex: selectedColor).opacity(0.3), radius: 20, y: 10)

                Image(systemName: "folder.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }

            Text(newName.isEmpty ? folder.name : newName)
                .font(.title2.bold())
                .foregroundColor(textColor)
                .lineLimit(1)
        }
    }

    // MARK: - Computed Properties

    private var canUpdate: Bool {
        !newName.isEmpty && newName.count <= 200 && !isUpdating &&
        (newName != folder.name || selectedColor != (folder.color ?? ""))
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
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)
    }

    // MARK: - Actions

    private func updateFolder() {
        guard !newName.isEmpty else {
            showError = "Please enter a folder name"
            return
        }

        isUpdating = true
        HapticService.shared.mediumImpact()

        Task {
            do {
                _ = try await savedMailService.updateFolder(
                    userId: userId,
                    folderId: folder.id,
                    name: newName != folder.name ? newName : nil,
                    color: selectedColor != folder.color ? selectedColor : nil
                )

                await MainActor.run {
                    isUpdating = false
                    HapticService.shared.success()
                    isPresented = false
                }

                Logger.info("✅ Updated folder: \(newName)", category: .savedMail)

            } catch {
                await MainActor.run {
                    isUpdating = false
                    showError = error.localizedDescription
                }
                Logger.error("Failed to update folder: \(error.localizedDescription)", category: .savedMail)
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

// MARK: - Priority Filter Chip

struct PriorityFilterChip: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let color: String
    let icon: String
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : Color(hex: color))

                Text(label)
                    .font(.subheadline.bold())
                    .foregroundColor(isSelected ? .white : textColor)

                // Count badge
                Text("\(count)")
                    .font(.caption.bold())
                    .foregroundColor(isSelected ? .white.opacity(0.9) : textColor.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        isSelected ?
                            Color.white.opacity(0.2) :
                            (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                    )
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ?
                    LinearGradient(
                        colors: [Color(hex: color), Color(hex: color).opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ).anyView() :
                    (colorScheme == .dark ? Color(white: 0.15) : Color.white).anyView()
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isSelected ? Color.clear : Color(hex: color).opacity(0.3),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: isSelected ? Color(hex: color).opacity(0.3) : Color.clear,
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
}

// Helper extension for type-erased views
extension View {
    func anyView() -> AnyView {
        AnyView(self)
    }
}

// MARK: - Preview

// Preview removed - requires complex EmailViewModel initialization
