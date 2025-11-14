import SwiftUI

struct DraftComposerModal: View {
    let emailId: String
    let emailSubject: String
    let emailBody: String
    let senderName: String
    @SwiftUI.Environment(\.dismiss) var dismiss

    @State private var selectedTone: DraftTone = .professional
    @State private var isGenerating = false
    @State private var generatedDraft: EmailDraft?
    @State private var editedDraftText: String = ""
    @State private var errorMessage: String?
    @State private var isSending = false
    @FocusState private var isEditing: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let draft = generatedDraft {
                    // Generated draft view
                    draftContentView(draft)
                } else {
                    // Generation setup view
                    generationSetupView
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("AI Draft Composer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if let draft = generatedDraft {
                            logFeedback(draft: draft, action: .discarded)
                        }
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .task {
                // Auto-generate draft on open
                await generateDraft()
            }
        }
    }

    // MARK: - Generation Setup View

    var generationSetupView: some View {
        VStack(spacing: 24) {
            Spacer()

            // AI icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(DesignTokens.Opacity.overlayMedium),
                                Color.blue.opacity(DesignTokens.Opacity.overlayMedium)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .symbolEffect(.pulse, options: .repeating)
            }

            if isGenerating {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)

                    Text("Generating your draft...")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Analyzing email context and tone")
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.red)

                    Text("Failed to generate draft")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red.opacity(DesignTokens.Opacity.textTertiary))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: { Task { await generateDraft() } }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                }
            } else {
                // Tone selector
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Tone")
                        .font(.headline)
                        .foregroundColor(.white)

                    VStack(spacing: 12) {
                        ForEach(DraftTone.allCases, id: \.self) { tone in
                            ToneButton(
                                tone: tone,
                                isSelected: selectedTone == tone
                            ) {
                                selectedTone = tone
                                Task { await generateDraft() }
                            }
                        }
                    }
                }
                .padding()
            }

            Spacer()
        }
    }

    // MARK: - Draft Content View

    func draftContentView(_ draft: EmailDraft) -> some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Draft header with premium styling
                    HStack(spacing: 12) {
                        // AI Badge with gradient
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                            Text("AI Draft")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(DesignTokens.Opacity.textDisabled),
                                    Color.blue.opacity(DesignTokens.Opacity.textDisabled)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(DesignTokens.Radius.modal)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: draft.tone.icon)
                                    .font(.caption)
                                Text(draft.tone.rawValue)
                                    .font(.caption)

                                Text("•")
                                    .font(.caption)

                                Text(String(format: "%.1fs", draft.latency))
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                        }

                        Spacer()

                        // Regenerate button with glassmorphic style
                        Button(action: { Task { await regenerateDraft() } }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Regenerate")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(DesignTokens.Radius.modal)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                            )
                        }
                        .disabled(isGenerating)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayLight), lineWidth: 1)
                            )
                    )

                    // Editable draft text with glassmorphic container
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Draft Content (Tap to Edit)")
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))

                        TextEditor(text: $editedDraftText)
                            .frame(minHeight: 200)
                            .padding(DesignTokens.Spacing.element)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .foregroundColor(.white)
                            .focused($isEditing)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        isEditing ?
                                            LinearGradient(
                                                colors: [Color.blue, Color.purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ) :
                                            LinearGradient(
                                                colors: [Color.white.opacity(DesignTokens.Opacity.overlayLight), Color.white.opacity(DesignTokens.Opacity.glassLight)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                        lineWidth: isEditing ? 2 : 1
                                    )
                            )
                    )

                    // Tone selector (for regeneration)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Change Tone")
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(DraftTone.allCases, id: \.self) { tone in
                                    ToneChip(
                                        tone: tone,
                                        isSelected: selectedTone == tone
                                    ) {
                                        selectedTone = tone
                                        Task { await regenerateDraft() }
                                    }
                                }
                            }
                        }
                    }

                    // Disclaimer
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("AI-generated content • Please review before sending")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                    .padding(.horizontal)
                }
                .padding()
            }

            // Action buttons
            VStack(spacing: 12) {
                // Send button
                Button(action: sendDraft) {
                    HStack {
                        if isSending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("Send Draft")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .disabled(isSending || editedDraftText.isEmpty)

                // Discard button
                Button(action: {
                    logFeedback(draft: draft, action: .discarded)
                    dismiss()
                }) {
                    Text("Discard Draft")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .disabled(isSending)
            }
            .padding()
        }
    }

    // MARK: - Draft Generation

    func generateDraft() async {
        isGenerating = true
        errorMessage = nil

        do {
            let context = EmailDraftContext(
                emailId: emailId,
                subject: emailSubject,
                senderName: senderName,
                emailBody: emailBody,
                threadHistory: nil, // Could fetch thread history here
                userIntent: nil
            )

            let draft = try await DraftComposerService.shared.generateDraft(
                emailContext: context,
                tone: selectedTone
            )

            await MainActor.run {
                generatedDraft = draft
                editedDraftText = draft.content
                isGenerating = false

                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isGenerating = false
            }
        }
    }

    func regenerateDraft() async {
        guard let currentDraft = generatedDraft else { return }

        // Log regeneration
        logFeedback(draft: currentDraft, action: .regenerated)

        // Clear current draft
        await MainActor.run {
            generatedDraft = nil
        }

        // Generate new draft
        await generateDraft()
    }

    func sendDraft() {
        guard let draft = generatedDraft else { return }

        isSending = true

        Task {
            do {
                // Log feedback (edited if text changed, approved if unchanged)
                let wasEdited = editedDraftText != draft.content
                logFeedback(
                    draft: draft,
                    action: wasEdited ? .edited : .approved,
                    editedContent: wasEdited ? editedDraftText : nil
                )

                // Send reply via API
                _ = try await EmailAPIService.shared.generateReply(emailId: emailId)

                Logger.info("Draft sent successfully", category: .app)

                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()

                await MainActor.run {
                    isSending = false
                    dismiss()
                }
            } catch {
                Logger.info("Failed to send draft: \(error)", category: .app)
                await MainActor.run {
                    isSending = false
                    errorMessage = "Failed to send draft"
                }
            }
        }
    }

    func logFeedback(draft: EmailDraft, action: FeedbackAction, editedContent: String? = nil) {
        DraftComposerService.shared.logFeedback(
            draft: draft,
            action: action,
            editedContent: editedContent
        )
    }
}

// MARK: - Tone Button (Large)

struct ToneButton: View {
    let tone: DraftTone
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: tone.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tone.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(tone.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(DesignTokens.Opacity.overlayLight) : Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
            .cornerRadius(DesignTokens.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.blue : Color.white.opacity(DesignTokens.Opacity.glassLight), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tone Chip (Small)

struct ToneChip: View {
    let tone: DraftTone
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: tone.icon)
                    .font(.caption)
                Text(tone.rawValue)
                    .font(.subheadline.bold())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color.white.opacity(DesignTokens.Opacity.glassLight), Color.white.opacity(DesignTokens.Opacity.glassLight)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .cornerRadius(DesignTokens.Radius.modal)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isSelected ? Color.white.opacity(DesignTokens.Opacity.overlayMedium) : Color.white.opacity(DesignTokens.Opacity.glassLight),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
