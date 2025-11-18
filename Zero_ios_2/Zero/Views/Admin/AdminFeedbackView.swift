#if DEBUG
import SwiftUI

/// Admin tool for reviewing and providing feedback on email classifications
/// Used to collect training data for ML model improvement
struct AdminFeedbackView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AdminFeedbackViewModel()

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
            .navigationTitle("Classification Feedback")
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
                FeedbackStatsView(stats: viewModel.stats)
            }
            .alert("Feedback Submitted", isPresented: $viewModel.showSuccessAlert) {
                Button("Next Email") {
                    viewModel.loadNextEmail()
                }
            } message: {
                Text("Classification feedback recorded for training")
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
        LoadingSpinner(text: "Loading email...", size: .medium)
    }

    // MARK: - Error View

    func errorView(_ error: String) -> some View {
        GenericEmptyState(
            icon: "exclamationmark.triangle",
            title: "Error",
            message: error,
            action: ("Retry", { viewModel.loadNextEmail() })
        )
    }

    // MARK: - Empty State

    var emptyStateView: some View {
        GenericEmptyState(
            icon: "checkmark.circle.fill",
            title: "All Done!",
            message: "No more emails to review",
            action: ("Load Sample", { Task { await viewModel.loadSampleEmail() } })
        )
    }

    // MARK: - Feedback Content

    func feedbackContentView(_ email: ClassifiedEmail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Email preview card
                emailPreviewCard(email)

                // Current classification
                currentClassificationSection(email)

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

    func emailPreviewCard(_ email: ClassifiedEmail) -> some View {
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

    // MARK: - Current Classification

    func currentClassificationSection(_ email: ClassifiedEmail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CURRENT CLASSIFICATION")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

            HStack(spacing: 16) {
                // Archetype badge
                VStack(spacing: 8) {
                    Text(email.classifiedType.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue.opacity(DesignTokens.Opacity.textDisabled), .purple.opacity(DesignTokens.Opacity.textDisabled)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(DesignTokens.Radius.button)

                    Text("Predicted Type")
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                }

                Spacer()

                // Priority
                VStack(spacing: 8) {
                    Text(email.priority.rawValue.uppercased())
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(priorityColor(email.priority))
                        .cornerRadius(DesignTokens.Radius.chip)

                    Text("Priority")
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                }
            }
        }
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
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                        .frame(height: 8)

                    // Fill
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

    func feedbackControls(_ email: ClassifiedEmail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("YOUR FEEDBACK")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

            feedbackButtons

            if viewModel.feedbackType == .incorrect {
                correctedTypePicker(email: email)
            }

            notesField
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    var feedbackButtons: some View {
        HStack(spacing: 12) {
            feedbackButton(type: .correct, icon: "checkmark.circle.fill", label: "Correct", color: .green)
            feedbackButton(type: .incorrect, icon: "xmark.circle.fill", label: "Incorrect", color: .red)
        }
        .buttonStyle(PlainButtonStyle())
    }

    func feedbackButton(type: ClassificationFeedbackType, icon: String, label: String, color: Color) -> some View {
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

    func correctedTypePicker(email: ClassifiedEmail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Correct Type:")
                .font(.subheadline.bold())
                .foregroundColor(.white)

            ForEach(CardType.allCases.filter { $0 != email.classifiedType }, id: \.self) { type in
                typePickerRow(type: type)
            }
        }
        .padding(.top, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    func typePickerRow(type: CardType) -> some View {
        let isSelected = viewModel.correctedType == type
        return Button(action: {
            viewModel.correctedType = type
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.4))
                Text(type.displayName)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(DesignTokens.Opacity.overlayLight) : Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
            .cornerRadius(DesignTokens.Radius.chip)
        }
        .buttonStyle(PlainButtonStyle())
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

    func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }

    func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .yellow }
        return .orange
    }

    func confidenceLabel(_ confidence: Double) -> String {
        if confidence >= 0.8 { return "High confidence - likely correct" }
        if confidence >= 0.6 { return "Medium confidence - review recommended" }
        return "Low confidence - review carefully"
    }
}

// MARK: - View Model

@MainActor
class AdminFeedbackViewModel: ObservableObject {
    @Published var currentEmail: ClassifiedEmail?
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var feedbackType: ClassificationFeedbackType?
    @Published var correctedType: CardType?
    @Published var notes: String = ""
    @Published var stats = FeedbackStats()
    @Published var showStats = false
    @Published var showSuccessAlert = false
    @Published var showExportAlert = false
    @Published var exportMessage = ""

    private var feedbackHistory: [ClassificationFeedback] = []

    var canSubmit: Bool {
        guard feedbackType != nil else { return false }
        if feedbackType == .incorrect {
            return correctedType != nil
        }
        return true
    }

    func loadNextEmail() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                currentEmail = try await AdminFeedbackService.shared.fetchNextEmail()
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
            currentEmail = try await AdminFeedbackService.shared.generateSampleEmail()
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

        let feedback = ClassificationFeedback(
            emailId: email.id,
            originalType: email.classifiedType,
            correctedType: feedbackType == .incorrect ? correctedType : nil,
            isCorrect: feedbackType == .correct,
            confidence: email.confidence,
            notes: notes.isEmpty ? nil : notes,
            timestamp: Date()
        )

        do {
            try await AdminFeedbackService.shared.submitFeedback(feedback)

            // Update stats
            stats.totalReviewed += 1
            if feedbackType == .correct {
                stats.correctCount += 1
            } else {
                stats.incorrectCount += 1
            }

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
            let filename = "classification_feedback_\(Int(Date().timeIntervalSince1970)).json"
            let fileURL = documentsPath.appendingPathComponent(filename)

            try jsonData.write(to: fileURL)

            exportMessage = "Exported \(feedbackHistory.count) feedback entries to:\n\(fileURL.path)"
            showExportAlert = true

            Logger.info("Exported feedback to: \(fileURL.path)", category: .admin)

        } catch {
            exportMessage = "Export failed: \(error.localizedDescription)"
            showExportAlert = true
        }
    }

    private func resetFeedbackForm() {
        feedbackType = nil
        correctedType = nil
        notes = ""
    }
}

// MARK: - Feedback Stats View

struct FeedbackStatsView: View {
    let stats: FeedbackStats
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

                VStack(spacing: 24) {
                    // Total reviewed
                    statCard(
                        icon: "checkmark.circle.fill",
                        title: "Total Reviewed",
                        value: "\(stats.totalReviewed)",
                        color: .blue
                    )

                    // Correct
                    statCard(
                        icon: "hand.thumbsup.fill",
                        title: "Correct Classifications",
                        value: "\(stats.correctCount)",
                        subtitle: stats.totalReviewed > 0 ? "\(Int(Double(stats.correctCount) / Double(stats.totalReviewed) * 100))% accuracy" : "",
                        color: .green
                    )

                    // Incorrect
                    statCard(
                        icon: "hand.thumbsdown.fill",
                        title: "Incorrect Classifications",
                        value: "\(stats.incorrectCount)",
                        subtitle: stats.totalReviewed > 0 ? "\(Int(Double(stats.incorrectCount) / Double(stats.totalReviewed) * 100))% error rate" : "",
                        color: .red
                    )

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Feedback Statistics")
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
}

// MARK: - Models

enum ClassificationFeedbackType {
    case correct, incorrect
}

struct FeedbackStats {
    var totalReviewed: Int = 0
    var correctCount: Int = 0
    var incorrectCount: Int = 0
}

// MARK: - Preview

#Preview {
    AdminFeedbackView()
}
#endif
