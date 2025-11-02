import SwiftUI
import QuickLook

/**
 * AttachmentViewerModal - View email attachments using iOS QuickLook
 *
 * Features:
 * - Lists all attachments with file icons, names, and sizes
 * - Taps attachment to preview with QuickLook
 * - Fetches attachment data from backend on demand
 * - Supports PDFs, images, documents, spreadsheets
 * - Shows loading state while fetching
 * - Error handling for failed downloads
 */
struct AttachmentViewerModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var selectedAttachment: EmailAttachment? = nil
    @State private var attachmentData: Data? = nil
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPreview = false
    @State private var temporaryFileURL: URL? = nil

    var body: some View {
        NavigationView {
            ZStack {
                modalBackground

                VStack(spacing: 0) {
                    // Header
                    headerView

                    if let attachments = card.attachments, !attachments.isEmpty {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(attachments) { attachment in
                                    attachmentRow(attachment)
                                }
                            }
                            .padding()
                        }
                    } else {
                        emptyState
                    }
                }

                // Loading overlay
                if isLoading {
                    loadingOverlay
                }

                // Error toast
                if showError {
                    errorToast
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showPreview) {
            if let url = temporaryFileURL, let attachment = selectedAttachment {
                DocumentPreviewModal(
                    documentTitle: attachment.filename,
                    pdfData: nil,
                    pdfURL: url,
                    isPresented: $showPreview
                )
            }
        }
        .onDisappear {
            cleanup()
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(DesignTokens.Colors.textSubtle)
            }

            Spacer()

            VStack(spacing: 4) {
                Text("Attachments")
                    .font(.title3.bold())
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                if let attachments = card.attachments {
                    Text("\(attachments.count) file\(attachments.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.purple.opacity(0.8))
                }
            }

            Spacer()

            // Placeholder for symmetry
            Color.clear.frame(width: 40)
        }
        .padding(.horizontal, DesignTokens.Spacing.card)
        .padding(.vertical, DesignTokens.Spacing.section)
        .background(
            ZStack {
                Color.black.opacity(0.3)
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        )
    }

    private func attachmentRow(_ attachment: EmailAttachment) -> some View {
        Button {
            downloadAndPreview(attachment)
        } label: {
            HStack(spacing: DesignTokens.Spacing.section) {
                // File icon
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: attachment.fileIcon)
                            .font(.title3)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    )

                // File info
                VStack(alignment: .leading, spacing: 4) {
                    Text(attachment.filename)
                        .font(.subheadline.bold())
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)

                    Text(attachment.fileSizeFormatted)
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(DesignTokens.Colors.textSubtle)
            }
            .padding(DesignTokens.Spacing.section)
            .background(Color.white.opacity(0.05))
            .cornerRadius(DesignTokens.Radius.button)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.section) {
            Image(systemName: "paperclip.badge.ellipsis")
                .font(.system(size: 48))
                .foregroundColor(DesignTokens.Colors.textSubtle)

            Text("No Attachments")
                .font(.headline)
                .foregroundColor(DesignTokens.Colors.textSubtle)

            Text("This email doesn't have any attachments")
                .font(.caption)
                .foregroundColor(DesignTokens.Colors.textSubtle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.section) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Downloading...")
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            .padding(32)
            .background(Color.black.opacity(0.8))
            .cornerRadius(DesignTokens.Radius.container)
        }
    }

    private var errorToast: some View {
        VStack {
            Spacer()

            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            .padding()
            .background(Color.red.opacity(0.9))
            .cornerRadius(DesignTokens.Radius.button)
            .padding()

            Spacer().frame(height: 100)
        }
        .transition(.move(edge: .bottom))
    }

    private var modalBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.18),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

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
        .ignoresSafeArea()
    }

    // MARK: - Functions

    private func downloadAndPreview(_ attachment: EmailAttachment) {
        selectedAttachment = attachment
        isLoading = true
        showError = false

        Logger.info("Downloading attachment: \(attachment.filename)", category: .action)

        Task {
            do {
                // Fetch attachment data from backend
                let data = try await fetchAttachmentData(messageId: card.id, attachmentId: attachment.id)

                // Write to temporary file
                let tempURL = try await writeToTemporaryFile(data: data, filename: attachment.filename)

                await MainActor.run {
                    attachmentData = data
                    temporaryFileURL = tempURL
                    isLoading = false
                    showPreview = true

                    // Analytics
                    AnalyticsService.shared.log("attachment_opened", properties: [
                        "filename": attachment.filename,
                        "mimeType": attachment.mimeType,
                        "size": attachment.size
                    ])
                }
            } catch {
                Logger.error("Failed to download attachment: \(error.localizedDescription)", category: .action)

                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to download attachment"
                    showError = true

                    // Hide error after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showError = false
                    }
                }
            }
        }
    }

    private func fetchAttachmentData(messageId: String, attachmentId: String) async throws -> Data {
        #if DEBUG
        let baseURL = Constants.API.Development.gatewayBaseURL
        #else
        let baseURL = Constants.API.Production.gatewayBaseURL
        #endif
        let endpoint = "\(baseURL)/emails/\(messageId)/attachments/\(attachmentId)"

        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "AttachmentViewer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Add auth token if available
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AttachmentViewer", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch attachment"])
        }

        // Parse response to get base64 data
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let base64String = json["data"] as? String,
           let decodedData = Data(base64Encoded: base64String) {
            return decodedData
        }

        throw NSError(domain: "AttachmentViewer", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid attachment data"])
    }

    private func writeToTemporaryFile(data: Data, filename: String) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        try data.write(to: fileURL)

        Logger.info("Wrote attachment to temporary file: \(fileURL.path)", category: .action)

        return fileURL
    }

    private func cleanup() {
        if let tempURL = temporaryFileURL {
            try? FileManager.default.removeItem(at: tempURL)
            Logger.info("Cleaned up temporary attachment file", category: .action)
        }
    }

    private func getAuthToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "EmailShortForm",
            kSecAttrAccount as String: "jwtToken",
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }
}
