import SwiftUI
import QuickLook

/// Modal for previewing PDF documents in-app using Quick Look
/// Supports PDF Data or file URL with native iOS preview features (share, markup, print)
struct DocumentPreviewModal: View {
    let documentTitle: String
    let pdfData: Data?
    let pdfURL: URL?
    @Binding var isPresented: Bool

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var temporaryFileURL: URL?

    var body: some View {
        ZStack {
            if let url = temporaryFileURL ?? pdfURL {
                DocumentPreviewViewController(url: url, title: documentTitle)
                    .edgesIgnoringSafeArea(.all)
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Preparing document...")
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .onAppear {
                    preparePDF()
                }
            }

            // Close button overlay
            VStack {
                HStack {
                    Spacer()
                    Button {
                        cleanup()
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .shadow(color: .black.opacity(DesignTokens.Opacity.overlayStrong), radius: 4)
                    }
                    .padding()
                }
                Spacer()
            }

            // Error overlay
            if showError {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        Text(errorMessage)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.red.opacity(DesignTokens.Opacity.textSecondary))
                    .cornerRadius(DesignTokens.Radius.button)
                    .padding()
                    Spacer().frame(height: 100)
                }
            }
        }
        .onDisappear {
            cleanup()
        }
    }

    /// Prepare PDF for preview - write Data to temporary file if needed
    private func preparePDF() {
        if pdfURL != nil {
            // URL already provided, no need to create temporary file
            return
        }

        guard let data = pdfData else {
            errorMessage = "No PDF data available"
            showError = true
            return
        }

        // Create temporary file for Quick Look
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(documentTitle.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "_", options: .regularExpression))_\(UUID().uuidString).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            temporaryFileURL = fileURL
            Logger.info("PDF written to temporary file: \(fileURL.path)", category: .action)

            // Analytics
            AnalyticsService.shared.log("document_preview_opened", properties: [
                "document_title": documentTitle,
                "file_size": data.count
            ])
        } catch {
            Logger.error("Failed to write PDF to temporary file: \(error.localizedDescription)", category: .action)
            errorMessage = "Could not prepare PDF for preview"
            showError = true
        }
    }

    /// Clean up temporary files
    private func cleanup() {
        if let tempURL = temporaryFileURL {
            try? FileManager.default.removeItem(at: tempURL)
            Logger.info("Cleaned up temporary PDF file", category: .action)
        }
    }
}

/// UIViewControllerRepresentable wrapper for QLPreviewController
struct DocumentPreviewViewController: UIViewControllerRepresentable {
    let url: URL
    let title: String

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url, title: title)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        let title: String

        init(url: URL, title: String) {
            self.url = url
            self.title = title
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return PreviewItem(url: url, title: title)
        }
    }
}

/// QLPreviewItem implementation
class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?

    init(url: URL, title: String) {
        self.previewItemURL = url
        self.previewItemTitle = title
        super.init()
    }
}

#Preview {
    DocumentPreviewModal(
        documentTitle: "Signed Permission Form",
        pdfData: nil,
        pdfURL: nil,
        isPresented: .constant(true)
    )
}
