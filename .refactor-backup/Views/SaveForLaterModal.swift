import SwiftUI

/**
 * SaveForLaterModal - Comprehensive "Save for Later" experience
 *
 * Features:
 * 1. Quick snooze buttons (1h, 6h, Tomorrow, Custom)
 * 2. Save to folder picker with folder list
 * 3. Combines snooze + folder functionality
 * 4. Consistent with existing modal patterns
 */
struct SaveForLaterModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    @State private var selectedOption: SaveOption = .snooze
    @State private var selectedFolder: SavedMailFolder? = nil
    @State private var showCustomSnooze = false
    @State private var customSnoozeHours = 2
    @StateObject private var savedMailService = SavedMailService.shared
    @EnvironmentObject var emailViewModel: EmailViewModel

    enum SaveOption: String, CaseIterable {
        case snooze = "Snooze"
        case folder = "Save to Folder"

        var icon: String {
            switch self {
            case .snooze: return "clock.fill"
            case .folder: return "folder.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Separator
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.purple.opacity(0.3),
                            Color.blue.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Email preview
            emailPreviewCard

            // Option selector
            optionSelector

            // Content based on selected option
            if selectedOption == .snooze {
                snoozeOptionsView
            } else {
                folderPickerView
            }

            Spacer()

            // Action buttons
            actionButtons
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(modalBackground)
        .cornerRadius(28)
        .shadow(color: Color.purple.opacity(0.2), radius: 20)
        .sheet(isPresented: $showCustomSnooze) {
            customSnoozeSheet
        }
        .onAppear {
            loadFolders()
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            Button {
                isPresented = false
            } label: {
                Text("Cancel")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            VStack(spacing: 4) {
                Text("Save for Later")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text("Choose how to save this email")
                    .font(.caption)
                    .foregroundColor(.purple.opacity(0.8))
            }

            Spacer()

            // Placeholder for symmetry
            Text("")
                .frame(width: 60)
        }
        .padding(.horizontal, DesignTokens.Spacing.card)
        .padding(.vertical, 16)
        .background(
            ZStack {
                Color.black.opacity(0.3)

                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        )
    }

    private var emailPreviewCard: some View {
        HStack(spacing: 12) {
            // Email icon
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "envelope.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                )

            // Email details
            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)

                if let company = card.company?.name ?? card.sender?.name {
                    Text(company)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.section)
        .background(Color.white.opacity(0.05))
        .cornerRadius(DesignTokens.Radius.button)
        .padding(.horizontal, DesignTokens.Spacing.card)
        .padding(.top, 16)
    }

    private var optionSelector: some View {
        HStack(spacing: 12) {
            ForEach(SaveOption.allCases, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedOption = option
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: option.icon)
                            .font(.body)

                        Text(option.rawValue)
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedOption == option ?
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(DesignTokens.Radius.container)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.card)
        .padding(.top, 16)
    }

    private var snoozeOptionsView: some View {
        VStack(spacing: 12) {
            Text("Remind me in...")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

            // Quick snooze buttons
            VStack(spacing: 10) {
                snoozeButton(hours: 1, label: "1 Hour", icon: "clock")
                snoozeButton(hours: 6, label: "6 Hours", icon: "clock.arrow.circlepath")
                snoozeButton(hours: 24, label: "Tomorrow", icon: "moon.zzz.fill")

                Button {
                    showCustomSnooze = true
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                            .foregroundColor(.white)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Custom Time")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("Choose exact time")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(DesignTokens.Spacing.section)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(DesignTokens.Radius.button)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.card)
    }

    private func snoozeButton(hours: Int, label: String, icon: String) -> some View {
        Button {
            performSnooze(hours: hours)
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(snoozeTimeDescription(hours: hours))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()
            }
            .padding(DesignTokens.Spacing.section)
            .background(Color.white.opacity(0.05))
            .cornerRadius(DesignTokens.Radius.button)
        }
    }

    private var folderPickerView: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Select folder")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                if savedMailService.isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding(.vertical, 32)
                } else if savedMailService.folders.isEmpty {
                    emptyFoldersView
                } else {
                    ForEach(savedMailService.folders) { folder in
                        folderRow(folder)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.card)
        }
    }

    private var emptyFoldersView: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.3))

            Text("No folders yet")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))

            Text("Create folders in the Saved Mail section to organize your emails")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 32)
    }

    private func folderRow(_ folder: SavedMailFolder) -> some View {
        Button {
            selectedFolder = folder
        } label: {
            HStack(spacing: 12) {
                // Folder icon with color
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: folder.displayColor))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: folder.displayIcon)
                            .font(.body)
                            .foregroundColor(.white)
                    )

                // Folder name and count
                VStack(alignment: .leading, spacing: 2) {
                    Text(folder.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    Text("\(folder.emailCount) emails")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Selection indicator
                if selectedFolder?.id == folder.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
            .padding(12)
            .background(
                selectedFolder?.id == folder.id ?
                    Color.white.opacity(0.1) :
                    Color.white.opacity(0.05)
            )
            .cornerRadius(DesignTokens.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        selectedFolder?.id == folder.id ?
                            Color.green.opacity(0.5) :
                            Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                isPresented = false
            } label: {
                Text("Cancel")
                    .font(.body.bold())
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(DesignTokens.Radius.button)
            }

            Button {
                if selectedOption == .folder {
                    performSaveToFolder()
                }
            } label: {
                HStack {
                    Image(systemName: selectedOption == .snooze ? "clock.fill" : "folder.fill")
                    Text(selectedOption == .snooze ? "Snooze" : "Save to Folder")
                }
                .font(.body.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(DesignTokens.Radius.button)
            }
            .disabled(selectedOption == .folder && selectedFolder == nil)
            .opacity(selectedOption == .folder && selectedFolder == nil ? 0.5 : 1.0)
        }
        .padding(.horizontal, DesignTokens.Spacing.card)
        .padding(.bottom, 24)
    }

    private var customSnoozeSheet: some View {
        SnoozePickerModal(
            isPresented: $showCustomSnooze,
            selectedDuration: $customSnoozeHours
        ) {
            performSnooze(hours: customSnoozeHours)
        }
        .presentationDetents([.height(400)])
    }

    private var modalBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.18),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Subtle accent gradient
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.1),
                    Color.clear,
                    Color.blue.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Helper Functions

    private func snoozeTimeDescription(hours: Int) -> String {
        if hours < 24 {
            let futureTime = Date().addingTimeInterval(TimeInterval(hours * 3600))
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Until \(formatter.string(from: futureTime))"
        } else {
            let futureDate = Date().addingTimeInterval(TimeInterval(hours * 3600))
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: futureDate)
        }
    }

    private func performSnooze(hours: Int) {
        Logger.info("Snoozing email for \(hours) hours", category: .savedMail)

        // TODO: Implement snooze logic via EmailViewModel or separate service
        // For now, just log the action

        // Analytics
        AnalyticsService.shared.log("save_for_later_snooze", properties: [
            "hours": hours,
            "email_type": card.type.rawValue,
            "email_priority": card.priority.rawValue
        ])

        // Dismiss modal
        isPresented = false
    }

    private func performSaveToFolder() {
        guard let folder = selectedFolder else { return }

        Logger.info("Saving email to folder: \(folder.name)", category: .savedMail)

        // Get user ID
        let userId = getUserEmail() ?? "mock-user"

        Task {
            do {
                _ = try await savedMailService.addEmailToFolder(
                    userId: userId,
                    folderId: folder.id,
                    emailId: card.id
                )

                await MainActor.run {
                    // Analytics
                    AnalyticsService.shared.log("save_for_later_folder", properties: [
                        "folder_id": folder.id,
                        "folder_name": folder.name,
                        "email_type": card.type.rawValue,
                        "email_priority": card.priority.rawValue
                    ])

                    // Dismiss modal
                    isPresented = false
                }
            } catch {
                Logger.error("Failed to save email to folder: \(error.localizedDescription)", category: .savedMail)
            }
        }
    }

    private func loadFolders() {
        let userId = getUserEmail() ?? "mock-user"

        Task {
            do {
                _ = try await savedMailService.fetchFolders(userId: userId)
            } catch {
                Logger.error("Failed to load folders: \(error.localizedDescription)", category: .savedMail)
            }
        }
    }

    private func getUserEmail() -> String? {
        let useMockData = UserDefaults.standard.bool(forKey: "useMockData")
        if useMockData {
            return "mock-user"
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

// MARK: - Preview
// Preview removed due to complex EmailViewModel initialization requirements
