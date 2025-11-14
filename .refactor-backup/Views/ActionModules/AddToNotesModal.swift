import SwiftUI

struct AddToNotesModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool

    @State private var noteTitle = ""
    @State private var noteContent = ""
    @State private var suggestedTags: [String] = []
    @State private var suggestedFolder: String?
    @State private var showSuccess = false
    @State private var showCopySuccess = false
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Custom header bar
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

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "note.text.badge.plus")
                                .font(.title)
                                .foregroundColor(.yellow)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Save to Notes")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Text(card.sender?.name ?? "Unknown Sender")
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Note Title
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Note Title")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        TextField("", text: $noteTitle)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(DesignTokens.Radius.button)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Note Content
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Content")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        TextEditor(text: $noteContent)
                            .frame(height: 300)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(DesignTokens.Radius.button)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .colorScheme(.dark)
                            .scrollContentBackground(.hidden)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Suggested Tags
                    if !suggestedTags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Suggested Tags")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            FlowLayout(spacing: 8) {
                                ForEach(suggestedTags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Image(systemName: "tag.fill")
                                            .font(.caption)
                                        Text(tag)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.blue, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }

                    // Suggested Folder
                    if let folder = suggestedFolder {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                            Text("Suggested Folder:")
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            Text(folder)
                                .font(.subheadline.bold())
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Action Buttons
                    VStack(spacing: 12) {
                        // Save to Notes button
                        Button {
                            shareToNotes()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Save to Notes App")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(noteTitle.isEmpty ? Color.gray : Color.yellow)
                            .foregroundColor(.black)
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                        .disabled(noteTitle.isEmpty)

                        // Copy to Clipboard button
                        Button {
                            copyToClipboard()
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy to Clipboard")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .cornerRadius(DesignTokens.Radius.button)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }

                    // Copy Success message
                    if showCopySuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Copied to clipboard!")
                                .foregroundColor(.green)
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Info message
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Tap 'Save to Notes App' to open the iOS share sheet, then select Notes. Or copy to clipboard and paste manually.")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
        .onAppear {
            detectNoteDetails()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(title: noteTitle, content: noteContent)
        }
    }

    func detectNoteDetails() {
        // Use NotesIntegrationService to detect smart defaults
        if let opportunity = NotesIntegrationService.shared.detectNoteOpportunity(in: card) {
            noteTitle = opportunity.title
            noteContent = opportunity.content
            suggestedTags = opportunity.tags
            suggestedFolder = opportunity.suggestedFolder
        } else {
            // Default values
            noteTitle = card.title
            noteContent = NotesIntegrationService.shared.formatNoteContent(from: card)
            suggestedTags = []
            suggestedFolder = "Email Notes"
        }
    }

    func shareToNotes() {
        showCopySuccess = false
        showShareSheet = true
        Logger.info("Opening share sheet for Notes", category: .action)

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    func copyToClipboard() {
        NotesIntegrationService.shared.copyToClipboard(title: noteTitle, content: noteContent)
        showCopySuccess = true

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        // Hide success message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showCopySuccess = false
        }
    }
}

// MARK: - Share Sheet (UIKit Bridge)

struct ShareSheet: UIViewControllerRepresentable {
    let title: String
    let content: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return NotesIntegrationService.shared.createShareActivity(
            title: title,
            content: content
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview("Add to Notes Modal") {
    AddToNotesModal(
        card: EmailCard(
            id: "preview",
            type: .mail,
            state: .seen,
            priority: .medium,
            hpa: "save_to_notes",
            timeAgo: "2h",
            title: "Recipe: Perfect Chocolate Chip Cookies",
            summary: "Here's my famous chocolate chip cookie recipe that I've perfected over 20 years. These cookies are crispy on the edges and chewy in the middle!",
            body: "Ingredients:\n• 2 1/4 cups all-purpose flour\n• 1 tsp baking soda\n• 1 cup butter, softened\n• 3/4 cup sugar\n• 2 eggs\n• 2 cups chocolate chips\n\nInstructions:\n1. Preheat oven to 375°F\n2. Mix dry ingredients\n3. Cream butter and sugars\n4. Add eggs and vanilla\n5. Combine wet and dry ingredients\n6. Fold in chocolate chips\n7. Bake for 9-11 minutes",
            metaCTA: "View",
            suggestedActions: [
                EmailAction(
                    actionId: "add_to_notes",
                    displayName: "Save to Notes",
                    actionType: .inApp,
                    isPrimary: true,
                    context: [:]
                )
            ],
            sender: SenderInfo(
                name: "Grandma Martha",
                initial: "M",
                email: "martha@family.com"
            )
        ),
        isPresented: .constant(true)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.05, green: 0.05, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
