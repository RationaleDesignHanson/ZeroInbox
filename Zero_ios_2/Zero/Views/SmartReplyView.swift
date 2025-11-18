import SwiftUI
import Speech
import AVFoundation

struct SmartReplyView: View {
    let email: EmailCard  // Changed from emailId to full email for Gemini context
    let onSelect: (String) -> Void

    @State private var replies: [String] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var usedFallback = false

    // Fallback suggestions when API fails
    private let fallbackSuggestions = [
        "Thanks for reaching out. I'll get back to you soon.",
        "I appreciate the update. Let me review this and follow up.",
        "Could you provide more details about this?"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
            // Header
            HStack(spacing: DesignTokens.Spacing.inline) {
                Image(systemName: usedFallback ? "exclamationmark.triangle.fill" : "sparkles")
                    .font(.caption)
                    .foregroundColor(usedFallback ? .orange : .blue)

                Text(usedFallback ? "Quick Replies" : "Smart Replies")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignTokens.Colors.textSecondary)

                Spacer()

                if isLoading {
                    LoadingSpinner(text: nil, size: .small)
                }
            }

            // Show error banner if there was an error (but still show fallback replies below)
            if let error = error, usedFallback {
                HStack(spacing: 8) {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.orange)

                    Button(action: {
                        Task {
                            await retryLoadSmartReplies()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10))
                            Text("Retry")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(6)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            if !replies.isEmpty {
                // Reply buttons
                ForEach(Array(replies.enumerated()), id: \.offset) { index, reply in
                    SmartReplyButton(
                        reply: reply,
                        index: index,
                        onTap: {
                            handleReplySelection(reply, index: index)
                        }
                    )
                }

                // Disclaimer
                Text(usedFallback ? "Generic replies • Review before sending" : "AI-generated • Review before sending")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(DesignTokens.Spacing.section)
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.15),
                    Color.purple.opacity(DesignTokens.Opacity.glassLight)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(DesignTokens.Radius.button)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                .strokeBorder(Color.blue.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
        )
        .task {
            await loadSmartReplies()
        }
    }

    func loadSmartReplies() async {
        do {
            let fetchedReplies = try await SmartReplyService.shared.generateSmartReplies(for: email)

            await MainActor.run {
                replies = fetchedReplies
                isLoading = false
                usedFallback = false
                error = nil
            }
        } catch {
            await MainActor.run {
                // Use fallback suggestions instead of showing empty state
                replies = fallbackSuggestions
                usedFallback = true
                isLoading = false

                // Set more specific error message
                if let smartReplyError = error as? SmartReplyError {
                    switch smartReplyError {
                    case .missingAPIKey:
                        self.error = "API key not configured"
                    case .apiError(let statusCode, _):
                        self.error = "API error (\(statusCode))"
                    default:
                        self.error = "Could not generate AI replies"
                    }
                } else {
                    self.error = "Could not generate AI replies"
                }

                Logger.warning("Smart reply failed, using fallback: \(error.localizedDescription)", category: .email)
            }
        }
    }

    func retryLoadSmartReplies() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        await loadSmartReplies()
    }

    func handleReplySelection(_ reply: String, index: Int) {
        // Log feedback
        Task {
            try? await EmailAPIService.shared.logSmartReplyFeedback(
                emailId: email.id,
                replyIndex: index,
                action: "selected",
                originalReply: reply,
                finalReply: reply
            )
        }

        // Trigger haptic feedback
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()

        // Pass reply to parent
        onSelect(reply)
    }
}

struct SmartReplyButton: View {
    let reply: String
    let index: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.inline) {
                // Reply icon based on type
                Image(systemName: replyIcon)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(width: 20)

                Text(reply)
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                Spacer()

                Image(systemName: "arrow.up.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .padding(DesignTokens.Spacing.component)
            .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
            .cornerRadius(DesignTokens.Spacing.inline)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Spacing.inline)
                    .strokeBorder(Color.blue.opacity(DesignTokens.Opacity.overlayLight), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    var replyIcon: String {
        switch index {
        case 0:
            return "checkmark.circle"
        case 1:
            return "text.bubble"
        case 2:
            return "hand.raised"
        default:
            return "text.bubble"
        }
    }
}

// MARK: - Compose Modal with Smart Reply

struct ComposeReplyModal: View {
    let card: EmailCard  // Changed to require full card for Smart Replies
    @SwiftUI.Environment(\.dismiss) var dismiss

    @State private var replyText: String = ""
    @State private var isSending: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    // Voice input states
    @State private var isRecording: Bool = false
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()

    // Template picker state
    @State private var showTemplatePicker = false
    // AI Composer state
    @State private var showAIComposer = false

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignTokens.Spacing.section) {
                // Smart replies at top
                SmartReplyView(email: card) { selectedReply in
                    replyText = selectedReply
                    isTextFieldFocused = true
                }

                // Compose area
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                    HStack {
                        Text("Your Reply")
                            .font(.subheadline.bold())
                            .foregroundColor(DesignTokens.Colors.textSubtle)

                        Spacer()

                        // AI Regenerate button
                        Button(action: { showAIComposer = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Regenerate")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .padding(.horizontal, DesignTokens.Spacing.component)
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
                        }
                        .disabled(isSending)

                        // Templates button
                        Button(action: { showTemplatePicker = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "text.bubble")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                            }
                        }
                        .disabled(isSending)

                        // Voice input button
                        Button(action: toggleRecording) {
                            HStack(spacing: 6) {
                                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(isRecording ? .red : .blue)

                                if isRecording {
                                    Text("Stop")
                                        .font(.caption.bold())
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .disabled(isSending)
                    }

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $replyText)
                            .frame(minHeight: 150)
                            .padding(DesignTokens.Spacing.component)
                            .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                            .cornerRadius(DesignTokens.Radius.button)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .focused($isTextFieldFocused)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .strokeBorder(isRecording ? Color.red.opacity(DesignTokens.Opacity.overlayStrong) : Color.white.opacity(DesignTokens.Opacity.glassLight), lineWidth: isRecording ? 2 : 1)
                            )

                        // Recording indicator
                        if isRecording {
                            HStack(spacing: DesignTokens.Spacing.inline) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("Listening...")
                                    .font(.caption.bold())
                                    .foregroundColor(.red)
                            }
                            .padding(DesignTokens.Spacing.inline)
                            .background(Color.black.opacity(DesignTokens.Opacity.overlayStrong))
                            .cornerRadius(DesignTokens.Spacing.inline)
                            .padding(DesignTokens.Spacing.inline)
                        }
                    }
                }

                Spacer()

                // Send button
                Button(action: sendReply) {
                    HStack {
                        if isSending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("Send Reply")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DesignTokens.Spacing.section)
                    .background(replyText.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .cornerRadius(DesignTokens.Radius.button)
                }
                .disabled(replyText.isEmpty || isSending)
            }
            .padding(DesignTokens.Spacing.section)
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
            .navigationTitle("Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                TemplatePickerView(isPresented: $showTemplatePicker) { template in
                    // Insert template content
                    if replyText.isEmpty {
                        replyText = template.content
                    } else {
                        replyText += "\n\n" + template.content
                    }
                    isTextFieldFocused = true
                }
            }
            .sheet(isPresented: $showAIComposer) {
                EmailComposerModal(
                    card: card,
                    isPresented: $showAIComposer
                )
            }
            .onDisappear {
                // CRITICAL: Clean up voice recording resources to prevent memory leaks
                if isRecording {
                    stopRecording()
                }

                // Deallocate speech recognition resources
                recognitionTask?.cancel()
                recognitionTask = nil
                recognitionRequest = nil

                // Stop audio engine if still running
                if audioEngine.isRunning {
                    audioEngine.stop()
                    if audioEngine.inputNode.numberOfInputs > 0 {
                        audioEngine.inputNode.removeTap(onBus: 0)
                    }
                }

                Logger.info("ComposeReplyModal: Voice recording resources cleaned up", category: .app)
            }
        }
    }

    func sendReply() {
        guard !replyText.isEmpty else { return }

        isSending = true

        Task {
            do {
                // Send reply via Gmail API
                _ = try await EmailAPIService.shared.generateReply(emailId: card.id)

                // Log success
                Logger.info("Reply sent successfully", category: .email)

                // Haptic feedback
                let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                impactHeavy.impactOccurred()

                await MainActor.run {
                    isSending = false
                    dismiss()
                }
            } catch {
                Logger.error("Failed to send reply: \(error)", category: .email)
                await MainActor.run {
                    isSending = false
                    // Could show error alert here
                }
            }
        }
    }

    // MARK: - Voice Input Functions

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecording() {
        // Request speech recognition authorization
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                guard authStatus == .authorized else {
                    Logger.error("Speech recognition not authorized", category: .app)
                    return
                }

                do {
                    // Cancel any existing recognition task
                    if let recognitionTask = recognitionTask {
                        recognitionTask.cancel()
                        self.recognitionTask = nil
                    }

                    // Configure audio session
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

                    // Create recognition request
                    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                    guard let recognitionRequest = recognitionRequest else {
                        Logger.error("Unable to create recognition request", category: .app)
                        return
                    }

                    recognitionRequest.shouldReportPartialResults = true

                    // Get the audio input node
                    let inputNode = audioEngine.inputNode
                    let recordingFormat = inputNode.outputFormat(forBus: 0)

                    // Install tap on the audio engine
                    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                        recognitionRequest.append(buffer)
                    }

                    // Start the audio engine
                    audioEngine.prepare()
                    try audioEngine.start()

                    // Start recognition task
                    recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                        if let result = result {
                            DispatchQueue.main.async {
                                // Append transcription to existing text
                                let transcribedText = result.bestTranscription.formattedString
                                if replyText.isEmpty {
                                    replyText = transcribedText
                                } else {
                                    replyText += " " + transcribedText
                                }
                            }
                        }

                        if error != nil || result?.isFinal == true {
                            self.stopRecording()
                        }
                    }

                    isRecording = true
                    Logger.info("Recording started", category: .app)

                    // Haptic feedback
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()

                } catch {
                    Logger.error("Failed to start recording: \(error)", category: .app)
                    stopRecording()
                }
            }
        }
    }

    func stopRecording() {
        // Stop audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        isRecording = false
        Logger.info("Recording stopped", category: .app)

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}
