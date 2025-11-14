import SwiftUI

struct AttachmentListView: View {
    let attachments: [EmailAttachment]
    let onAttachmentTap: (EmailAttachment) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "paperclip")
                    .foregroundColor(DesignTokens.Colors.textSubtle)
                    .font(.subheadline)

                Text("\(attachments.count) Attachment\(attachments.count == 1 ? "" : "s")")
                    .font(.subheadline.bold())
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }

            // Attachment rows
            VStack(spacing: DesignTokens.Spacing.inline) {
                ForEach(attachments) { attachment in
                    AttachmentRow(
                        attachment: attachment,
                        onTap: {
                            onAttachmentTap(attachment)
                        }
                    )
                }
            }
        }
        .padding(DesignTokens.Spacing.section)
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }
}

// MARK: - Attachment Row

struct AttachmentRow: View {
    let attachment: EmailAttachment
    let onTap: () -> Void

    @State private var isCached = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // File icon
                Image(systemName: attachment.fileIcon)
                    .font(.title2)
                    .foregroundColor(fileTypeColor)
                    .frame(width: 40, height: 40)
                    .background(fileTypeColor.opacity(0.15))
                    .cornerRadius(DesignTokens.Spacing.inline)

                // File info
                VStack(alignment: .leading, spacing: 4) {
                    Text(attachment.filename)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: DesignTokens.Spacing.inline) {
                        Text(attachment.fileSizeFormatted)
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)

                        if isCached {
                            HStack(spacing: 2) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                Text("Downloaded")
                                    .font(.caption2)
                            }
                            .foregroundColor(.green)
                        }
                    }
                }

                Spacer()

                // Action indicator
                Image(systemName: canPreview ? "eye.fill" : "square.and.arrow.down")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
            }
            .padding(DesignTokens.Spacing.component)
            .background(Color.white.opacity(0.08))
            .cornerRadius(DesignTokens.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(DesignTokens.Opacity.glassLight), lineWidth: 1)
            )
        }
        .onAppear {
            isCached = AttachmentService.shared.isCached(attachment)
        }
    }

    var canPreview: Bool {
        AttachmentService.shared.canPreview(attachment)
    }

    var fileTypeColor: Color {
        if attachment.mimeType.contains("pdf") {
            return .red
        } else if attachment.mimeType.contains("image") {
            return .blue
        } else if attachment.mimeType.contains("word") || attachment.mimeType.contains("document") {
            return .blue
        } else if attachment.mimeType.contains("excel") || attachment.mimeType.contains("spreadsheet") {
            return .green
        } else if attachment.mimeType.contains("zip") || attachment.mimeType.contains("archive") {
            return .orange
        } else {
            return .gray
        }
    }
}

// MARK: - Preview

#Preview("Attachment List") {
    AttachmentListView(
        attachments: [
            EmailAttachment(
                id: "1",
                filename: "Invoice_2024.pdf",
                mimeType: "application/pdf",
                size: 245678,
                messageId: "msg_123"
            ),
            EmailAttachment(
                id: "2",
                filename: "Photo.jpg",
                mimeType: "image/jpeg",
                size: 1245678,
                messageId: "msg_123"
            ),
            EmailAttachment(
                id: "3",
                filename: "Report.docx",
                mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                size: 45678,
                messageId: "msg_123"
            )
        ],
        onAttachmentTap: { attachment in
            print("Tapped: \(attachment.filename)")
        }
    )
    .padding()
    .background(
        LinearGradient(
            colors: [Color.purple, Color.blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
