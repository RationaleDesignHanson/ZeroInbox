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
                    Button(action: { viewModel.exportFeedback() }) {
                        Image(systemName: "square.and.arrow.up")
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
                    Text("Progress: \(stats.currentProgress)/10 cards toward next free month")
                } else {
                    Text("Feedback recorded for model training")
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
    @Published var rewardStats: RewardStatistics?

    private let rewardsService = ModelTuningRewardsService.shared

    var canSubmit: Bool {
        guard correctedCategory != nil else { return false }
        return true
    }

    init() {
        updateRewardStats()
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

    func exportFeedback() {
        let message = "Feedback export is handled by backend API"
        Logger.info(message, category: .admin)
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
