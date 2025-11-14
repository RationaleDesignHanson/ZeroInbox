import SwiftUI

/// Admin tool for reviewing and providing feedback on suggested email actions
/// Used to collect training data for action suggestion model improvement
struct ActionFeedbackView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ActionFeedbackViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if let email = viewModel.currentEmail {
                    feedbackContentView(email)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Action Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Stats button
                        Button(action: { viewModel.showStats.toggle() }) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.white)
                        }

                        // Export button
                        Button(action: { viewModel.exportFeedback() }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showStats) {
                ActionFeedbackStatsView(summary: viewModel.summary)
            }
            .alert("Feedback Submitted", isPresented: $viewModel.showSuccessAlert) {
                Button("Next Email") {
                    viewModel.loadNextEmail()
                }
            } message: {
                Text("Action feedback recorded for training")
            }
            .alert("Export Complete", isPresented: $viewModel.showExportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.exportMessage)
            }
        }
        .task {
            viewModel.loadNextEmail()
        }
    }

    // MARK: - Loading View

    var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)

            Text("Loading email...")
                .font(.headline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
        }
    }

    // MARK: - Error View

    func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Error")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text(error)
                .font(.subheadline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                viewModel.loadNextEmail()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(DesignTokens.Radius.button)
        }
    }

    // MARK: - Empty State

    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("All Done!")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("No more emails to review")
                .font(.subheadline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))

            Button("Load Sample") {
                Task { await viewModel.loadSampleEmail() }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(DesignTokens.Radius.button)
        }
    }

    // MARK: - Feedback Content

    func feedbackContentView(_ email: ClassifiedEmailWithActions) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Email preview card
                emailPreviewCard(email)

                // Intent display
                intentSection(email)

                // Suggested actions
                suggestedActionsSection(email)

                // Confidence indicator
                confidenceIndicator(email.confidence)

                // Feedback controls
                feedbackControls(email)

                // Action buttons
                actionButtons

                Spacer(minLength: 100)
            }
            .padding()
        }
    }

    // MARK: - Email Preview Card

    func emailPreviewCard(_ email: ClassifiedEmailWithActions) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("EMAIL PREVIEW")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

                Spacer()

                Text(email.timeAgo)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
            }

            Divider()
                .background(Color.white.opacity(DesignTokens.Opacity.overlayLight))

            // From
            HStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.blue)
                Text("From:")
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                Text(email.from)
                    .foregroundColor(.white)
                    .bold()
            }
            .font(.subheadline)

            // Subject
            HStack(spacing: 8) {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.purple)
                Text("Subject:")
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                Text(email.subject)
                    .foregroundColor(.white)
                    .bold()
                    .lineLimit(2)
            }
            .font(.subheadline)

            // Snippet
            Text(email.snippet)
                .font(.caption)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
                .lineLimit(4)
                .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayLight), lineWidth: 1)
                )
        )
    }

    // MARK: - Intent Section

    func intentSection(_ email: ClassifiedEmailWithActions) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DETECTED INTENT")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

            HStack {
                Image(systemName: "target")
                    .foregroundColor(.purple)
                Text(email.intent)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(DesignTokens.Opacity.overlayLight))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.purple.opacity(0.4), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Suggested Actions Section

    func suggestedActionsSection(_ email: ClassifiedEmailWithActions) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUGGESTED ACTIONS (\(email.suggestedActions.count))")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

            ForEach(email.suggestedActions) { action in
                actionRow(action)
            }
        }
    }

    func actionRow(_ action: EmailAction) -> some View {
        HStack(spacing: 12) {
            // Action type icon
            Image(systemName: action.actionType == .goTo ? "arrow.up.forward.square" : "app.fill")
                .foregroundColor(action.isPrimary ? .yellow : .blue)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(action.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    if action.isPrimary {
                        Text("PRIMARY")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(DesignTokens.Opacity.overlayLight))
                            .cornerRadius(DesignTokens.Radius.minimal)
                    }
                }

                Text(action.actionId)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
            }

            Spacer()

            // Priority badge
            if let priority = action.priority {
                Text("#\(priority)")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    // MARK: - Confidence Indicator

    func confidenceIndicator(_ confidence: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MODEL CONFIDENCE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

                Spacer()

                Text("\(Int(confidence * 100))%")
                    .font(.headline)
                    .foregroundColor(confidenceColor(confidence))
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [confidenceColor(confidence).opacity(DesignTokens.Opacity.textTertiary), confidenceColor(confidence)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(confidence), height: 8)
                }
            }
            .frame(height: 8)

            Text(confidenceLabel(confidence))
                .font(.caption)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    // MARK: - Feedback Controls

    func feedbackControls(_ email: ClassifiedEmailWithActions) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("YOUR FEEDBACK")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

            feedbackButtons

            if viewModel.feedbackType == .incorrect {
                actionFeedbackOptions(email: email)
            }

            notesField
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    var feedbackButtons: some View {
        HStack(spacing: 12) {
            feedbackButton(type: .correct, icon: "checkmark.circle.fill", label: "All Correct", color: .green)
            feedbackButton(type: .incorrect, icon: "xmark.circle.fill", label: "Needs Changes", color: .red)
        }
        .buttonStyle(PlainButtonStyle())
    }

    func feedbackButton(type: ActionFeedbackType, icon: String, label: String, color: Color) -> some View {
        let isSelected = viewModel.feedbackType == type
        return Button(action: {
            viewModel.feedbackType = type
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? color.opacity(DesignTokens.Opacity.overlayMedium) : Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
            .foregroundColor(isSelected ? color : .white.opacity(DesignTokens.Opacity.textSubtle))
            .cornerRadius(DesignTokens.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? color : Color.white.opacity(DesignTokens.Opacity.overlayLight), lineWidth: 2)
            )
        }
    }

    func actionFeedbackOptions(email: ClassifiedEmailWithActions) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Missed actions
            VStack(alignment: .leading, spacing: 8) {
                Text("Missed Actions (should have been suggested):")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                TextField("e.g., track_package, add_to_calendar", text: $viewModel.missedActionsText)
                    .padding()
                    .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                    .foregroundColor(.white)
                    .cornerRadius(DesignTokens.Radius.chip)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayLight), lineWidth: 1)
                    )

                Text("Comma-separated action IDs")
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
            }

            // Unnecessary actions
            VStack(alignment: .leading, spacing: 8) {
                Text("Unnecessary Actions (shouldn't have been suggested):")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                TextField("e.g., contact_carrier", text: $viewModel.unnecessaryActionsText)
                    .padding()
                    .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                    .foregroundColor(.white)
                    .cornerRadius(DesignTokens.Radius.chip)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayLight), lineWidth: 1)
                    )

                Text("Comma-separated action IDs")
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
            }
        }
        .padding(.top, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (optional):")
                .font(.subheadline.bold())
                .foregroundColor(.white)

            TextEditor(text: $viewModel.notes)
                .frame(height: 80)
                .padding(DesignTokens.Spacing.inline)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                .foregroundColor(.white)
                .cornerRadius(DesignTokens.Radius.chip)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayLight), lineWidth: 1)
                )
        }
    }

    // MARK: - Action Buttons

    var actionButtons: some View {
        VStack(spacing: 12) {
            // Submit button
            Button(action: {
                Task { await viewModel.submitFeedback() }
            }) {
                HStack {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("Submit Feedback")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canSubmit ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(DesignTokens.Radius.button)
            }
            .disabled(!viewModel.canSubmit || viewModel.isSubmitting)

            // Skip button
            Button(action: {
                viewModel.loadNextEmail()
            }) {
                Text("Skip This Email")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
            }
            .disabled(viewModel.isSubmitting)
        }
    }

    // MARK: - Helper Functions

    func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .yellow }
        return .orange
    }

    func confidenceLabel(_ confidence: Double) -> String {
        if confidence >= 0.8 { return "High confidence - actions likely correct" }
        if confidence >= 0.6 { return "Medium confidence - review recommended" }
        return "Low confidence - review carefully"
    }
}

// MARK: - View Model

@MainActor
class ActionFeedbackViewModel: ObservableObject {
    @Published var currentEmail: ClassifiedEmailWithActions?
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var feedbackType: ActionFeedbackType?
    @Published var missedActionsText: String = ""
    @Published var unnecessaryActionsText: String = ""
    @Published var notes: String = ""
    @Published var summary = ActionFeedbackService.shared.generateFeedbackSummary()
    @Published var showStats = false
    @Published var showSuccessAlert = false
    @Published var showExportAlert = false
    @Published var exportMessage = ""

    private var feedbackHistory: [ActionFeedback] = []

    var canSubmit: Bool {
        guard feedbackType != nil else { return false }
        if feedbackType == .incorrect {
            return !missedActionsText.isEmpty || !unnecessaryActionsText.isEmpty
        }
        return true
    }

    func loadNextEmail() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                currentEmail = try await ActionFeedbackService.shared.fetchNextEmailWithActions()
                resetFeedbackForm()
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }

    func loadSampleEmail() async {
        isLoading = true
        errorMessage = nil

        do {
            currentEmail = try await ActionFeedbackService.shared.generateSampleEmailWithActions()
            resetFeedbackForm()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func submitFeedback() async {
        guard let email = currentEmail,
              let feedbackType = feedbackType else {
            return
        }

        isSubmitting = true

        // Parse missed and unnecessary actions
        let missedActions = missedActionsText.isEmpty ? nil : missedActionsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        let unnecessaryActions = unnecessaryActionsText.isEmpty ? nil : unnecessaryActionsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        let feedback = ActionFeedback(
            emailId: email.id,
            intent: email.intent,
            originalActions: email.suggestedActions.map { $0.actionId },
            correctedActions: nil,  // Future enhancement
            isCorrect: feedbackType == .correct,
            missedActions: missedActions,
            unnecessaryActions: unnecessaryActions,
            confidence: email.confidence,
            notes: notes.isEmpty ? nil : notes,
            timestamp: Date()
        )

        do {
            try await ActionFeedbackService.shared.submitFeedback(feedback)

            // Update stats
            summary = ActionFeedbackService.shared.generateFeedbackSummary()

            // Store in history
            feedbackHistory.append(feedback)

            showSuccessAlert = true

        } catch {
            errorMessage = "Failed to submit feedback: \(error.localizedDescription)"
        }

        isSubmitting = false
    }

    func exportFeedback() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(feedbackHistory)

            // Save to documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let filename = "action_feedback_\(Int(Date().timeIntervalSince1970)).json"
            let fileURL = documentsPath.appendingPathComponent(filename)

            try jsonData.write(to: fileURL)

            exportMessage = "Exported \(feedbackHistory.count) feedback entries to:\n\(fileURL.path)"
            showExportAlert = true

            Logger.info("Exported action feedback to: \(fileURL.path)", category: .admin)

        } catch {
            exportMessage = "Export failed: \(error.localizedDescription)"
            showExportAlert = true
        }
    }

    private func resetFeedbackForm() {
        feedbackType = nil
        missedActionsText = ""
        unnecessaryActionsText = ""
        notes = ""
    }
}

// MARK: - Feedback Stats View

struct ActionFeedbackStatsView: View {
    let summary: ActionFeedbackSummary
    @SwiftUI.Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Total reviewed
                        statCard(
                            icon: "checkmark.circle.fill",
                            title: "Total Reviewed",
                            value: "\(summary.totalReviewed)",
                            color: .blue
                        )

                        // Accuracy
                        statCard(
                            icon: "target",
                            title: "Overall Accuracy",
                            value: "\(Int(summary.overallAccuracy * 100))%",
                            color: .green
                        )

                        // Top missed actions
                        if !summary.topMissedActions.isEmpty {
                            missedActionsCard
                        }

                        // Top unnecessary actions
                        if !summary.topUnnecessaryActions.isEmpty {
                            unnecessaryActionsCard
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Action Feedback Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    func statCard(icon: String, title: String, value: String, subtitle: String = "", color: Color) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))

                    Text(value)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(color.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 2)
        )
    }

    var missedActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Missed Actions")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(summary.topMissedActions, id: \.action) { item in
                HStack {
                    Text(item.action)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
                    Spacer()
                    Text("\(item.count)x")
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.orange.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 2)
        )
    }

    var unnecessaryActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Unnecessary Actions")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(summary.topUnnecessaryActions, id: \.action) { item in
                HStack {
                    Text(item.action)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
                    Spacer()
                    Text("\(item.count)x")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.red.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 2)
        )
    }
}

// MARK: - Types

enum ActionFeedbackType {
    case correct, incorrect
}

// MARK: - Preview

#Preview {
    ActionFeedbackView()
}
