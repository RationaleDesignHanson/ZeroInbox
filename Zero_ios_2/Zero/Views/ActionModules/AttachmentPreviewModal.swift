import SwiftUI
import PDFKit

struct AttachmentPreviewModal: View {
    let attachment: EmailAttachment
    @Binding var isPresented: Bool

    @State private var attachmentData: Data?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    if isLoading {
                        // Loading state
                        VStack(spacing: DesignTokens.Spacing.section) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)

                            Text("Loading \(attachment.filename)...")
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        }
                    } else if let errorMessage = errorMessage {
                        // Error state
                        VStack(spacing: DesignTokens.Spacing.section) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.red)

                            Text("Failed to load attachment")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button {
                                loadAttachment()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Retry")
                                }
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                        }
                    } else if let data = attachmentData {
                        // Content preview
                        ScrollView {
                            VStack(spacing: DesignTokens.Spacing.section) {
                                if attachment.mimeType.contains("image") {
                                    // Image preview
                                    if let image = UIImage(data: data) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .cornerRadius(DesignTokens.Radius.button)
                                            .padding()
                                    }
                                } else if attachment.mimeType.contains("pdf") {
                                    // PDF preview
                                    PDFPreviewView(data: data)
                                        .frame(minHeight: 500)
                                        .cornerRadius(DesignTokens.Radius.button)
                                        .padding()
                                } else {
                                    // Generic file (not previewable)
                                    VStack(spacing: DesignTokens.Spacing.section) {
                                        Image(systemName: attachment.fileIcon)
                                            .font(.system(size: 64))
                                            .foregroundColor(DesignTokens.Colors.textSubtle)

                                        Text(attachment.filename)
                                            .font(.headline)
                                            .foregroundColor(DesignTokens.Colors.textPrimary)

                                        Text(attachment.fileSizeFormatted)
                                            .font(.subheadline)
                                            .foregroundColor(DesignTokens.Colors.textSubtle)

                                        Text("Preview not available for this file type")
                                            .font(.caption)
                                            .foregroundColor(DesignTokens.Colors.textSubtle)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                    .padding(.vertical, 60)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(attachment.filename)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if attachmentData != nil {
                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let data = attachmentData {
                    AttachmentShareSheet(activityItems: [data, attachment.filename])
                }
            }
        }
        .onAppear {
            loadAttachment()
        }
    }

    var gradientColors: [Color] {
        if attachment.mimeType.contains("pdf") {
            return [Color.red, Color.orange]
        } else if attachment.mimeType.contains("image") {
            return [Color.blue, Color.purple]
        } else {
            return [Color.gray, Color.blue]
        }
    }

    func loadAttachment() {
        isLoading = true
        errorMessage = nil

        // Check cache first
        if let cachedData = AttachmentService.shared.getCachedAttachment(attachment) {
            Logger.info("📎 Using cached attachment: \(attachment.filename)", category: .app)
            attachmentData = cachedData
            isLoading = false
            return
        }

        // Download attachment
        AttachmentService.shared.downloadAttachment(attachment) { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success(let data):
                    attachmentData = data

                    // Cache for future use
                    try? AttachmentService.shared.cacheAttachment(attachment, data: data)

                    HapticService.shared.success()
                    Logger.info("✅ Attachment loaded: \(attachment.filename)", category: .app)

                case .failure(let error):
                    errorMessage = error.localizedDescription
                    HapticService.shared.error()
                    Logger.error("Failed to load attachment: \(error.localizedDescription)", category: .network)
                }
            }
        }
    }
}

// MARK: - Attachment Share Sheet

struct AttachmentShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - PDF Preview View

struct PDFPreviewView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .clear

        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

#Preview("PDF Attachment") {
    AttachmentPreviewModal(
        attachment: EmailAttachment(
            id: "1",
            filename: "Invoice_2024.pdf",
            mimeType: "application/pdf",
            size: 245678,
            messageId: "msg_123"
        ),
        isPresented: .constant(true)
    )
}

#Preview("Image Attachment") {
    AttachmentPreviewModal(
        attachment: EmailAttachment(
            id: "2",
            filename: "Photo.jpg",
            mimeType: "image/jpeg",
            size: 1245678,
            messageId: "msg_123"
        ),
        isPresented: .constant(true)
    )
}
