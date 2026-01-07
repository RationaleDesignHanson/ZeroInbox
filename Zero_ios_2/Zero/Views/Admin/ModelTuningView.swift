#if DEBUG
import SwiftUI

/// Collapsible category section for missed actions
struct CollapsibleCategorySection: View {
    let category: ActionCategory
    let email: UnifiedEmailForTuning
    @ObservedObject var viewModel: ModelTuningViewModel
    let actionChipBuilder: (String, Bool, Color, Bool) -> AnyView

    @State private var isExpanded: Bool = false

    init(category: ActionCategory, email: UnifiedEmailForTuning, viewModel: ModelTuningViewModel, actionChipBuilder: @escaping (String, Bool, Color, Bool) -> some View) {
        self.category = category
        self.email = email
        self.viewModel = viewModel
        self.actionChipBuilder = { actionId, isSelected, color, enabled in
            AnyView(actionChipBuilder(actionId, isSelected, color, enabled))
        }
    }

    var missedActionsForCategory: [String] {
        viewModel.actionsForCategory(category).filter { actionId in
            !email.suggestedActions.contains(where: { $0.actionId == actionId })
        }
    }

    var body: some View {
        if !missedActionsForCategory.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                // Category header with chevron
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text(category.rawValue)
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                            .textCase(.uppercase)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                // Action buttons (shown when expanded)
                if isExpanded {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                        ForEach(missedActionsForCategory, id: \.self) { actionId in
                            actionChipBuilder(
                                actionId,
                                viewModel.missedActions.contains(actionId),
                                .orange,
                                true
                            )
                            .onTapGesture {
                                viewModel.toggleMissedAction(actionId)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

/// Consolidated Model Tuning Tool
/// Replaces AdminFeedbackView and ActionFeedbackView with modern, unified UX
/// Trains both email categorization and action suggestions
struct ModelTuningView: View {
    @SwiftUI.Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ModelTuningViewModel()

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
            .navigationTitle(viewModel.rewardStats == nil ? "Model Tuning" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .principal) {
                    // Progress meter in navigation bar (replaces title when present)
                    if let stats = viewModel.rewardStats {
                        rewardProgressPill(stats: stats)
                    } else {
                        Text("Model Tuning")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.showDataInfoSheet = true
                        } label: {
                            Label("What's Collected?", systemImage: "info.circle")
                        }

                        Button {
                            viewModel.initiateExport()
                        } label: {
                            Label("Export Feedback (\(LocalFeedbackStore.shared.getFeedbackCount()))", systemImage: "square.and.arrow.up")
                        }
                        .disabled(LocalFeedbackStore.shared.getFeedbackCount() == 0)

                        Divider()

                        Button(role: .destructive) {
                            viewModel.showClearConfirmation = true
                        } label: {
                            Label("Clear All Feedback", systemImage: "trash")
                        }
                        .disabled(LocalFeedbackStore.shared.getFeedbackCount() == 0)

                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
            .alert("Feedback Submitted", isPresented: $viewModel.showSuccessAlert) {
                Button("Next Email") {
                    viewModel.loadNextEmail()
                }
            } message: {
                if let stats = viewModel.rewardStats {
                    Text("Testing Phase: \(stats.currentProgress) samples contributed. Progress: \(stats.currentProgress)/10 toward free month.")
                } else {
                    Text("Feedback recorded for model training. Thank you!")
                }
            }
            .alert("🎉 Free Month Earned!", isPresented: $viewModel.showRewardEarnedAlert) {
                Button("Next Email") {
                    viewModel.loadNextEmail()
                }
            } message: {
                if let stats = viewModel.rewardStats {
                    Text("Congratulations! You've earned a free month of Zero Premium by helping improve our AI models. Total earned: \(stats.earnedMonths) months!")
                } else {
                    Text("Congratulations! You've earned a free month of Zero Premium!")
                }
            }
            // Consent dialog - shown on first use
            .sheet(isPresented: $viewModel.showConsentDialog) {
                consentDialogView
            }
            // Export warning - shown before exporting
            .alert("Review Before Sharing", isPresented: $viewModel.showExportWarning) {
                Button("Cancel", role: .cancel) { }
                Button("Export") {
                    viewModel.performExport()
                }
            } message: {
                Text("This file contains \(LocalFeedbackStore.shared.getFeedbackCount()) sanitized email samples. Personal information has been redacted, but please review before sharing externally.")
            }
            // Clear confirmation
            .alert("Clear All Feedback?", isPresented: $viewModel.showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    LocalFeedbackStore.shared.clearAllFeedback()
                    viewModel.updateRewardStats()
                }
            } message: {
                Text("This will permanently delete all \(LocalFeedbackStore.shared.getFeedbackCount()) feedback samples from your device. This cannot be undone.")
            }
            // Data info sheet
            .sheet(isPresented: $viewModel.showDataInfoSheet) {
                dataInfoSheetView
            }
        }
        .task {
            viewModel.loadNextEmail()
        }
    }

    // MARK: - Consent Dialog

    var consentDialogView: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 60))
                                .foregroundColor(.cyan)

                            Text("Help Improve Zero's AI")
                                .font(.title.bold())
                                .foregroundColor(.white)

                            Text("Model Tuning collects email samples to improve classification accuracy.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                        // Privacy guarantees
                        VStack(alignment: .leading, spacing: 16) {
                            privacyFeature(icon: "lock.shield", title: "PII Automatically Redacted", description: "Email addresses, phone numbers, credit cards, and sensitive data removed")
                            privacyFeature(icon: "externaldrive", title: "Stored Locally", description: "All data stays on your device until you choose to export")
                            privacyFeature(icon: "hand.raised", title: "You Control Export", description: "Review samples before sharing externally")
                            privacyFeature(icon: "trash", title: "Delete Anytime", description: "Clear all feedback data whenever you want")
                        }
                        .padding(.vertical, 8)

                        // Important note
                        Text("Testing Phase: Review non-sensitive emails only. Contribute any amount - every sample helps!")
                            .font(.footnote)
                            .foregroundColor(.orange.opacity(0.9))
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)

                        // Buttons
                        VStack(spacing: 12) {
                            Button {
                                viewModel.giveConsent()
                            } label: {
                                Text("I Understand")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.cyan)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }

                            Button {
                                viewModel.declineConsent()
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Text("Not Now")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func privacyFeature(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.cyan)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Data Info Sheet

    var dataInfoSheetView: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("What's Collected?")
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        VStack(alignment: .leading, spacing: 16) {
                            dataItem(title: "Email Subjects", description: "Sanitized with PII removed", icon: "envelope")
                            dataItem(title: "Sender Domains", description: "Full email addresses redacted (e.g., \"gmail.com\")", icon: "at")
                            dataItem(title: "Email Snippets", description: "Preview text with PII removed", icon: "text.alignleft")
                            dataItem(title: "Your Classifications", description: "How you corrected the AI's categories", icon: "checkmark.circle")
                            dataItem(title: "Action Feedback", description: "Which actions were suggested correctly/incorrectly", icon: "bolt")
                        }

                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Storage Info")
                                .font(.headline)
                                .foregroundColor(.white)

                            HStack {
                                Text("Samples Collected:")
                                Spacer()
                                Text("\(LocalFeedbackStore.shared.getFeedbackCount())")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white.opacity(0.8))

                            if let fileSize = LocalFeedbackStore.shared.getFileSize() {
                                HStack {
                                    Text("File Size:")
                                    Spacer()
                                    Text(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white.opacity(0.8))
                            }

                            Text("Location: Documents/zero-feedback-export.jsonl")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Data Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.showDataInfoSheet = false
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }

    private func dataItem(title: String, description: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
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

    func feedbackContentView(_ email: UnifiedEmailForTuning) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Email preview card
                emailPreviewCard(email)

                // Category feedback section
                categoryFeedbackSection(email)

                // Action feedback section
                actionFeedbackSection(email)

                // General notes
                notesField

                // Action buttons
                actionButtons

                Spacer(minLength: 100)
            }
            .padding()
        }
    }

    // MARK: - Email Preview Card

    func emailPreviewCard(_ email: UnifiedEmailForTuning) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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

    // MARK: - Category Feedback Section

    func categoryFeedbackSection(_ email: UnifiedEmailForTuning) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "folder.badge.questionmark")
                    .foregroundColor(.purple)
                Text("EMAIL CATEGORY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
            }

            // Current category
            HStack {
                Text("Detected:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                Text(email.classifiedType.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(categoryColor(email.classifiedType).opacity(DesignTokens.Opacity.overlayMedium))
                    .cornerRadius(DesignTokens.Radius.chip)
            }

            // Category selection
            Text("Correct category:")
                .font(.subheadline)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach([CardType.mail, .ads], id: \.self) { category in
                    categoryButton(category, isSelected: viewModel.correctedCategory == category)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    func categoryButton(_ category: CardType, isSelected: Bool) -> some View {
        Button(action: {
            viewModel.correctedCategory = category
        }) {
            HStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.title3)
                Text(category.displayName)
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? categoryColor(category).opacity(DesignTokens.Opacity.textSubtle) : Color.white.opacity(0.15))
            .foregroundColor(.white)
            .cornerRadius(DesignTokens.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? categoryColor(category) : Color.white.opacity(0.4), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    func categoryColor(_ category: CardType) -> Color {
        switch category {
        case .mail: return .blue
        case .ads: return .green
        }
    }

    // MARK: - Action Feedback Section

    func actionFeedbackSection(_ email: UnifiedEmailForTuning) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.yellow)
                Text("SUGGESTED ACTIONS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
            }

            // Detected intent
            HStack {
                Text("Intent:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                Text(email.intent)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.purple.opacity(DesignTokens.Opacity.overlayLight))
            .cornerRadius(DesignTokens.Radius.button)

            // Current suggested actions
            VStack(alignment: .leading, spacing: 8) {
                Text("Currently Suggested:")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                    ForEach(email.suggestedActions) { action in
                        actionChip(actionId: action.actionId, isSelected: false, color: .blue, enabled: false)
                    }
                }
            }

            Divider().background(Color.white.opacity(DesignTokens.Opacity.overlayLight))

            // Missed actions selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Missed Actions (should have been suggested):")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                ForEach(ActionCategory.allCases, id: \.self) { category in
                    CollapsibleCategorySection(
                        category: category,
                        email: email,
                        viewModel: viewModel,
                        actionChipBuilder: actionChip
                    )
                }
            }

            Divider().background(Color.white.opacity(DesignTokens.Opacity.overlayLight))

            // Unnecessary actions selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Unnecessary Actions (shouldn't have been suggested):")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                FlowLayout(spacing: 8) {
                    ForEach(email.suggestedActions) { action in
                        actionChip(
                            actionId: action.actionId,
                            isSelected: viewModel.unnecessaryActions.contains(action.actionId),
                            color: .red,
                            enabled: true
                        )
                        .onTapGesture {
                            viewModel.toggleUnnecessaryAction(action.actionId)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    func actionChip(actionId: String, isSelected: Bool, color: Color, enabled: Bool) -> some View {
        Text(viewModel.getActionLabel(actionId))
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(DesignTokens.Opacity.textTertiary) : Color.white.opacity(enabled ? 0.2 : 0.1))
            .cornerRadius(DesignTokens.Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? color : Color.white.opacity(enabled ? 0.5 : 0.3), lineWidth: 2)
            )
            .contentShape(Rectangle())
    }

    // MARK: - Notes Field

    var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional Notes (optional):")
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
        .padding()
        .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
        .cornerRadius(DesignTokens.Radius.button)
    }

    // MARK: - Action Buttons

    var actionButtons: some View {
        VStack(spacing: 12) {
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

    // MARK: - Reward Progress Pill

    func rewardProgressPill(stats: RewardStatistics) -> some View {
        HStack(spacing: 8) {
            // Trophy icon with earned months badge
            ZStack(alignment: .topTrailing) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)

                if stats.earnedMonths > 0 {
                    Text("\(stats.earnedMonths)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(3)
                        .background(Circle().fill(Color.red))
                        .offset(x: 6, y: -4)
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 2) {
                Text("\(stats.currentProgress)/10")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(DesignTokens.Opacity.overlayLight))
                            .frame(height: 4)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * stats.progressPercentage, height: 4)
                    }
                }
                .frame(width: 60, height: 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(DesignTokens.Opacity.glassLight))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                )
        )
    }
}

// MARK: - View Model

// MARK: - Unified Email Model

struct UnifiedEmailForTuning {
    let id: String
    let from: String
    let subject: String
    let snippet: String
    let timeAgo: String
    let classifiedType: CardType
    let priority: Priority
    let intent: String
    let suggestedActions: [EmailAction]
    let confidence: Double
}

@MainActor
class ModelTuningViewModel: ObservableObject {
    @Published var currentEmail: UnifiedEmailForTuning?
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var correctedCategory: CardType?
    @Published var missedActions: Set<String> = []
    @Published var unnecessaryActions: Set<String> = []
    @Published var notes: String = ""
    @Published var showSuccessAlert = false
    @Published var showRewardEarnedAlert = false
    @Published var showConsentDialog = false
    @Published var showExportWarning = false
    @Published var showDataInfoSheet = false
    @Published var showClearConfirmation = false
    @Published var rewardStats: RewardStatistics?

    private let rewardsService = ModelTuningRewardsService.shared
    private let consentKey = "modelTuning_consent_given"

    var hasConsent: Bool {
        UserDefaults.standard.bool(forKey: consentKey)
    }

    var canSubmit: Bool {
        guard correctedCategory != nil else { return false }
        return true
    }

    init() {
        updateRewardStats()
        // Check consent on first launch
        if !hasConsent {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showConsentDialog = true
            }
        }
    }

    func giveConsent() {
        UserDefaults.standard.set(true, forKey: consentKey)
        showConsentDialog = false
    }

    func declineConsent() {
        showConsentDialog = false
        // Could navigate back or show alternative UI
    }

    func loadNextEmail() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                // Try to fetch from action feedback service
                let actionEmail = try await ActionFeedbackService.shared.fetchNextEmailWithActions()

                // Infer category from intent
                let inferredCategory = inferCategoryFromIntent(actionEmail.intent)
                let inferredPriority = Priority.medium

                // Create unified model
                currentEmail = UnifiedEmailForTuning(
                    id: actionEmail.id,
                    from: actionEmail.from,
                    subject: actionEmail.subject,
                    snippet: actionEmail.snippet,
                    timeAgo: actionEmail.timeAgo,
                    classifiedType: inferredCategory,
                    priority: inferredPriority,
                    intent: actionEmail.intent,
                    suggestedActions: actionEmail.suggestedActions,
                    confidence: actionEmail.confidence
                )

                resetFeedbackForm()
            } catch {
                // Auto-fallback to sample data if API is unavailable (404 error)
                Logger.warning("API unavailable, falling back to sample data: \(error.localizedDescription)", category: .app)

                do {
                    let actionEmail = try await ActionFeedbackService.shared.generateSampleEmailWithActions()

                    // Infer category from intent
                    let inferredCategory = inferCategoryFromIntent(actionEmail.intent)
                    let inferredPriority = Priority.medium

                    // Create unified model
                    currentEmail = UnifiedEmailForTuning(
                        id: actionEmail.id,
                        from: actionEmail.from,
                        subject: actionEmail.subject,
                        snippet: actionEmail.snippet,
                        timeAgo: actionEmail.timeAgo,
                        classifiedType: inferredCategory,
                        priority: inferredPriority,
                        intent: actionEmail.intent,
                        suggestedActions: actionEmail.suggestedActions,
                        confidence: actionEmail.confidence
                    )

                    resetFeedbackForm()
                    errorMessage = nil  // Clear error since we recovered with sample data
                } catch {
                    errorMessage = "Failed to load data: \(error.localizedDescription)"
                }
            }

            isLoading = false
        }
    }

    func inferCategoryFromIntent(_ intent: String) -> CardType {
        // Infer category from intent prefix
        if intent.hasPrefix("education.") || intent.hasPrefix("family.") {
            return .mail
        } else if intent.hasPrefix("e-commerce.") || intent.hasPrefix("shopping.") || intent.hasPrefix("travel.") {
            return .ads
        } else if intent.hasPrefix("billing.") || intent.hasPrefix("sales.") || intent.hasPrefix("project.") {
            return .mail
        } else if intent.hasPrefix("healthcare.") || intent.hasPrefix("restaurant.") || intent.hasPrefix("account.") {
            return .mail
        }
        return .mail // Default
    }

    func loadSampleEmail() async {
        isLoading = true
        errorMessage = nil

        do {
            let actionEmail = try await ActionFeedbackService.shared.generateSampleEmailWithActions()

            // Infer category from intent
            let inferredCategory = inferCategoryFromIntent(actionEmail.intent)
            let inferredPriority = Priority.medium

            // Create unified model
            currentEmail = UnifiedEmailForTuning(
                id: actionEmail.id,
                from: actionEmail.from,
                subject: actionEmail.subject,
                snippet: actionEmail.snippet,
                timeAgo: actionEmail.timeAgo,
                classifiedType: inferredCategory,
                priority: inferredPriority,
                intent: actionEmail.intent,
                suggestedActions: actionEmail.suggestedActions,
                confidence: actionEmail.confidence
            )

            resetFeedbackForm()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func submitFeedback() async {
        guard let email = currentEmail,
              let correctedCategory = correctedCategory else {
            return
        }

        isSubmitting = true

        // Submit category feedback
        let categoryFeedback = ClassificationFeedback(
            emailId: email.id,
            originalType: email.classifiedType,
            correctedType: correctedCategory,
            isCorrect: email.classifiedType == correctedCategory,
            confidence: email.confidence,
            notes: notes.isEmpty ? nil : notes,
            timestamp: Date()
        )

        // Submit action feedback
        let actionFeedback = ActionFeedback(
            emailId: email.id,
            intent: email.intent,
            originalActions: email.suggestedActions.map { $0.actionId },
            correctedActions: nil,
            isCorrect: missedActions.isEmpty && unnecessaryActions.isEmpty,
            missedActions: missedActions.isEmpty ? nil : Array(missedActions),
            unnecessaryActions: unnecessaryActions.isEmpty ? nil : Array(unnecessaryActions),
            confidence: email.confidence,
            notes: notes.isEmpty ? nil : notes,
            timestamp: Date()
        )

        do {
            try await AdminFeedbackService.shared.submitFeedback(categoryFeedback)
            try await ActionFeedbackService.shared.submitFeedback(actionFeedback)

            // Sanitize email content for privacy before saving locally
            let sanitizedEmail = EmailSanitizer.sanitize(
                subject: email.subject,
                from: email.from,
                snippet: email.snippet,
                body: nil // UnifiedEmailForTuning only has snippet, not full body
            )

            // Save sanitized feedback locally for export and training
            let feedbackSubmission = FeedbackSubmission(
                emailId: email.id,
                subject: sanitizedEmail.subject,
                from: sanitizedEmail.from,
                fromDomain: sanitizedEmail.fromDomain,
                body: sanitizedEmail.body,
                snippet: sanitizedEmail.snippet,
                sanitizationApplied: sanitizedEmail.sanitizationApplied,
                sanitizationVersion: sanitizedEmail.sanitizationVersion,
                classifiedCategory: email.classifiedType.rawValue,
                correctedCategory: correctedCategory.rawValue,
                classificationConfidence: email.confidence,
                suggestedActions: email.suggestedActions.map { $0.actionId },
                missedActions: missedActions.isEmpty ? nil : Array(missedActions),
                unnecessaryActions: unnecessaryActions.isEmpty ? nil : Array(unnecessaryActions),
                notes: notes.isEmpty ? nil : notes,
                intent: email.intent
            )
            LocalFeedbackStore.shared.saveFeedback(feedbackSubmission)

            // Track reward progress
            let earnedMonth = rewardsService.recordFeedback()
            updateRewardStats()

            if earnedMonth {
                // User earned a free month!
                showRewardEarnedAlert = true
            } else {
                showSuccessAlert = true
            }

        } catch {
            errorMessage = "Failed to submit feedback: \(error.localizedDescription)"
        }

        isSubmitting = false
    }

    func updateRewardStats() {
        rewardStats = rewardsService.getStatistics()
    }

    func toggleMissedAction(_ actionId: String) {
        if missedActions.contains(actionId) {
            missedActions.remove(actionId)
        } else {
            missedActions.insert(actionId)
        }
    }

    func toggleUnnecessaryAction(_ actionId: String) {
        if unnecessaryActions.contains(actionId) {
            unnecessaryActions.remove(actionId)
        } else {
            unnecessaryActions.insert(actionId)
        }
    }

    func getActionLabel(_ actionId: String) -> String {
        // Use same labels from UserPreferencesService
        let service = UserPreferencesService()
        return service.getActionLabel(for: actionId)
    }

    func actionsForCategory(_ category: ActionCategory) -> [String] {
        switch category {
        case .documents:
            return ["view_document", "view_spreadsheet", "sign_form", "sign_send", "review_attachment", "review_approve", "forward"]
        case .calendar:
            return ["schedule_meeting", "add_to_calendar", "join_meeting", "rsvp_yes", "rsvp_no", "register_event"]
        case .shopping:
            return ["view_product", "add_to_cart", "schedule_purchase", "claim_deal", "save_deal", "view_offer", "compare", "track_package", "view_order", "buy_again", "return_item", "complete_cart", "copy_promo_code", "set_reminder"]
        case .billing:
            return ["pay_invoice", "view_invoice", "download_receipt", "manage_subscription", "update_payment", "set_payment_reminder", "pay_form_fee"]
        case .travel:
            return ["check_in_flight", "view_itinerary", "add_to_wallet", "manage_booking"]
        case .account:
            return ["reset_password", "verify_account", "verify_device", "review_security", "revoke_secret"]
        case .education:
            return ["view_assignment", "check_grade"]
        case .healthcare:
            return ["check_in_appointment", "get_directions", "view_pickup_details", "view_results"]
        case .dining:
            return ["view_reservation", "modify_reservation", "track_delivery", "contact_driver"]
        case .feedback:
            return ["write_review", "rate_product", "take_survey"]
        case .project:
            return ["view_task", "view_incident", "view_ticket", "reply_to_ticket", "contact_support"]
        case .general:
            return ["open_app", "open_link", "view_details", "reply", "quick_reply", "compose", "acknowledge", "save_for_later"]
        }
    }

    /// Triggers export with warning dialog first
    func initiateExport() {
        let count = LocalFeedbackStore.shared.getFeedbackCount()
        if count == 0 {
            // No feedback to export
            return
        }
        showExportWarning = true
    }

    /// Performs actual export after user confirms warning
    func performExport() {
        exportFeedback()
    }

    private func exportFeedback() {
        // Export local feedback file via share sheet
        guard let fileURL = LocalFeedbackStore.shared.exportFeedback() else {
            Logger.warning("No feedback to export", category: .admin)
            return
        }

        let feedbackCount = LocalFeedbackStore.shared.getFeedbackCount()
        Logger.info("Exporting \(feedbackCount) feedback entries", category: .admin)

        // Present share sheet with the JSONL file
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        // Configure share sheet
        activityViewController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            if completed {
                Logger.info("Feedback export completed: \(activityType?.rawValue ?? "unknown")", category: .admin)
            } else if let error = error {
                Logger.error("Feedback export failed: \(error)", category: .admin)
            }
        }

        // Present from top view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // Find the topmost presented view controller
            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }
            topController.present(activityViewController, animated: true)
        }
    }

    private func resetFeedbackForm() {
        correctedCategory = currentEmail?.classifiedType
        missedActions = []
        unnecessaryActions = []
        notes = ""
    }
}

// MARK: - Action Categories

enum ActionCategory: String, CaseIterable {
    case documents = "Documents & Files"
    case calendar = "Calendar & Meetings"
    case shopping = "Shopping & E-commerce"
    case billing = "Billing & Payments"
    case travel = "Travel"
    case account = "Account & Security"
    case education = "Education & Family"
    case healthcare = "Healthcare"
    case dining = "Dining & Delivery"
    case feedback = "Feedback & Reviews"
    case project = "Project & Support"
    case general = "General Actions"
}

// Note: Using existing ClassificationFeedback model from EmailCard.swift

// MARK: - Flow Layout
// Note: FlowLayout is already defined in WriteReviewModal.swift and shared across the app

// MARK: - Card Type Extension

extension CardType {
    var iconName: String {
        switch self {
        case .mail: return "envelope.fill"
        case .ads: return "cart.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    ModelTuningView()
}
#endif
