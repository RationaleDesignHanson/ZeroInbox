import SwiftUI

struct ViewDetailsModal: View {
    let card: EmailCard
    let context: [String: Any]
    @Binding var isPresented: Bool

    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showAttachmentPreview = false
    @State private var selectedAttachmentURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            // Custom header
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .font(.title2)
                }
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header with email icon
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                        HStack {
                            Image(systemName: "envelope.open.fill")
                                .font(.largeTitle)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email Details")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                if let sender = card.company?.name {
                                    Text(sender)
                                        .font(.subheadline)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Email metadata
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                        Text("Message Information")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        DetailRow(
                            icon: "person.circle.fill",
                            label: "From",
                            value: card.company?.name ?? "Unknown",
                            color: .blue
                        )

                        DetailRow(
                            icon: "text.alignleft",
                            label: "Subject",
                            value: card.title,
                            color: .purple
                        )

                        DetailRow(
                            icon: "calendar.circle.fill",
                            label: "Date",
                            value: card.timeAgo,
                            color: .green
                        )

                        DetailRow(
                            icon: "tag.circle.fill",
                            label: "Category",
                            value: card.type.displayName,
                            color: .orange
                        )
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Email body/summary
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                        Text("Message Preview")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        VStack(alignment: .leading, spacing: 0) {
                            StructuredSummaryView(card: card)
                        }
                        .padding(DesignTokens.Spacing.section)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Attachments (if available)
                    if let attachmentCount = context["attachmentCount"] as? Int, attachmentCount > 0 {
                        Divider()
                            .background(Color.white.opacity(0.3))

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                            Text("Attachments")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Button {
                                previewAttachment()
                            } label: {
                                HStack {
                                    Image(systemName: "paperclip")
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                    Text("\(attachmentCount) attachment(s)")
                                        .font(.subheadline)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                        .font(.caption)
                                }
                                .padding(DesignTokens.Spacing.component)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(DesignTokens.Spacing.inline)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Action buttons
                    VStack(spacing: 12) {
                        // Action buttons row
                        HStack(spacing: 12) {
                            // Archive button
                            Button {
                                archiveEmail()
                            } label: {
                                HStack {
                                    Image(systemName: "archivebox")
                                    Text("Archive")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .cornerRadius(DesignTokens.Radius.button)
                            }

                            // Forward button
                            Button {
                                forwardEmail()
                            } label: {
                                HStack {
                                    Image(systemName: "arrowshape.turn.up.right")
                                    Text("Forward")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple.opacity(0.3))
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                        }

                        // Mark as unread button
                        Button {
                            markAsUnread()
                        } label: {
                            HStack {
                                Image(systemName: "envelope.badge")
                                Text("Mark as Unread")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.3))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .cornerRadius(DesignTokens.Radius.button)
                        }

                        if showSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Action completed!")
                                    .foregroundColor(.green)
                                    .font(.headline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(DesignTokens.Radius.button)
                        }

                        if showError, let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.top, DesignTokens.Spacing.card)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .sheet(isPresented: $showAttachmentPreview) {
            if let attachmentURL = selectedAttachmentURL {
                DocumentPreviewModal(
                    documentTitle: "Email Attachment",
                    pdfData: nil,
                    pdfURL: attachmentURL,
                    isPresented: $showAttachmentPreview
                )
            } else {
                // Fallback: show message about attachments not being available yet
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 60))
                        .foregroundColor(DesignTokens.Colors.textSubtle)

                    Text("Attachment Preview")
                        .font(.title2.bold())
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    Text("Attachment preview will be available once we fetch the attachment data from your email provider.")
                        .font(.subheadline)
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button {
                        showAttachmentPreview = false
                    } label: {
                        Text("Got It")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(DesignTokens.Radius.button)
                    }
                    .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
        }
    }

    func previewAttachment() {
        Logger.info("Attachment preview requested", category: .action)

        // Check if attachment URL is available in context
        if let attachmentURLString = context["attachmentUrl"] as? String,
           let url = URL(string: attachmentURLString) {
            selectedAttachmentURL = url
            showAttachmentPreview = true

            // Analytics
            AnalyticsService.shared.log("attachment_preview_opened", properties: [
                "email_id": card.id,
                "sender": card.company?.name ?? "Unknown"
            ])
        } else {
            // No attachment URL - show placeholder modal
            selectedAttachmentURL = nil
            showAttachmentPreview = true

            Logger.info("No attachment URL available, showing placeholder", category: .action)
        }
    }

    func archiveEmail() {
        showSuccess = true

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        Logger.info("Email archived", category: .action)

        AnalyticsService.shared.log("email_archived", properties: [
            "email_id": card.id,
            "sender": card.company?.name ?? "Unknown"
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showSuccess = false
            isPresented = false
        }
    }

    func forwardEmail() {
        showSuccess = true

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Logger.info("Email forwarded", category: .action)

        AnalyticsService.shared.log("email_forwarded", properties: [
            "email_id": card.id,
            "sender": card.company?.name ?? "Unknown"
        ])

        // Reset success after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showSuccess = false
        }
    }

    func markAsUnread() {
        showSuccess = true

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        Logger.info("Email marked as unread", category: .action)

        AnalyticsService.shared.log("email_marked_unread", properties: [
            "email_id": card.id,
            "sender": card.company?.name ?? "Unknown"
        ])

        // Reset success after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showSuccess = false
        }
    }
}
