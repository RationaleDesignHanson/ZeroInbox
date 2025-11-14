import SwiftUI

struct UnsubscribeModal: View {
    let card: EmailCard
    let unsubscribeUrl: String
    @Binding var isPresented: Bool
    var onUnsubscribeComplete: (() -> Void)?

    @State private var selectedReason: UnsubscribeReason?
    @State private var customReason = ""
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showUndo = false
    @State private var undoTimeRemaining = 5

    // Computed: Is this a subscription service (Netflix, Spotify) vs newsletter?
    var isSubscriptionService: Bool {
        return card.isSubscription == true
    }

    var serviceName: String {
        return card.company?.name ?? card.sender?.name ?? "this service"
    }

    enum UnsubscribeReason: String, CaseIterable {
        case tooMany = "Too many emails"
        case notRelevant = "Content not relevant"
        case neverSubscribed = "Never subscribed"
        case foundBetter = "Found better alternative"
        case tooExpensive = "Too expensive"
        case notUsing = "Not using the service"
        case other = "Other (specify)"

        var icon: String {
            switch self {
            case .tooMany: return "envelope.badge.fill"
            case .notRelevant: return "xmark.circle.fill"
            case .neverSubscribed: return "questionmark.circle.fill"
            case .foundBetter: return "star.fill"
            case .tooExpensive: return "dollarsign.circle.fill"
            case .notUsing: return "pause.circle.fill"
            case .other: return "pencil.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .tooMany: return .orange
            case .notRelevant: return .red
            case .neverSubscribed: return .purple
            case .foundBetter: return .blue
            case .tooExpensive: return .green
            case .notUsing: return .gray
            case .other: return .gray
            }
        }

        // Newsletter-specific reasons
        static var newsletterReasons: [UnsubscribeReason] {
            [.tooMany, .notRelevant, .neverSubscribed, .foundBetter, .other]
        }

        // Subscription service reasons
        static var subscriptionReasons: [UnsubscribeReason] {
            [.tooExpensive, .notUsing, .foundBetter, .other]
        }
    }

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
            .padding(.top, 20)
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: isSubscriptionService ? "xmark.circle.fill" : "envelope.badge.fill")
                                .font(.title)
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(isSubscriptionService ? "Cancel Subscription" : "Unsubscribe")
                                    .font(.title2.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Text(serviceName)
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                        }

                        if isSubscriptionService {
                            if let amount = card.subscriptionAmount {
                                Text("You're currently paying $\(String(format: "%.2f", amount)) per \(card.subscriptionFrequency ?? "month")")
                                    .font(.subheadline.bold())
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .padding(.top, 2)
                            }

                            Text("We'll help you cancel your subscription. This helps us understand your preferences.")
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .padding(.top, 4)
                        } else {
                            Text("We'll unsubscribe you from future emails. This helps us understand what you like.")
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .padding(.top, 4)
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Reason selection
                    if !showSuccess && !showUndo {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(isSubscriptionService ? "Why are you cancelling?" : "Why are you unsubscribing?")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Text("Optional - helps improve recommendations")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textTertiary)

                            // Reason buttons - show appropriate reasons based on type
                            VStack(spacing: 12) {
                                let reasons = isSubscriptionService ?
                                    UnsubscribeReason.subscriptionReasons :
                                    UnsubscribeReason.newsletterReasons

                                ForEach(reasons, id: \.self) { reason in
                                    ReasonButton(
                                        reason: reason,
                                        isSelected: selectedReason == reason,
                                        action: {
                                            withAnimation {
                                                selectedReason = reason
                                            }
                                        }
                                    )
                                }
                            }

                            // Custom reason field (only show when "Other" selected)
                            if selectedReason == .other {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Please specify:")
                                        .font(.subheadline.bold())
                                        .foregroundColor(DesignTokens.Colors.textPrimary)

                                    TextField("Type your reason...", text: $customReason, axis: .vertical)
                                        .lineLimit(2...4)
                                        .padding()
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(DesignTokens.Radius.button)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }

                    // Success state
                    if showSuccess {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)

                            Text(isSubscriptionService ? "Cancellation Requested" : "Unsubscribed Successfully")
                                .font(.title3.bold())
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            if isSubscriptionService {
                                Text("We've opened the cancellation page for \(serviceName). Follow the steps to complete cancellation.")
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            } else {
                                Text("You won't receive emails from \(serviceName) anymore.")
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }

                    // Undo countdown
                    if showUndo {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 8)
                                    .frame(width: 80, height: 80)

                                Circle()
                                    .trim(from: 0, to: CGFloat(undoTimeRemaining) / 5.0)
                                    .stroke(Color.orange, lineWidth: 8)
                                    .frame(width: 80, height: 80)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.linear(duration: 1.0), value: undoTimeRemaining)

                                Text("\(undoTimeRemaining)")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }

                            Text((isSubscriptionService ? "Cancelling" : "Unsubscribing") + " in \(undoTimeRemaining) seconds...")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            if isSubscriptionService {
                                Text("We'll open the cancellation page for \(serviceName).")
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            } else {
                                Text("You won't receive emails from \(serviceName) anymore.")
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }

                            Button {
                                cancelUnsubscribe()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.uturn.backward")
                                    Text(isSubscriptionService ? "Undo Cancellation" : "Undo Unsubscribe")
                                        .font(.headline)
                                }
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }

                    // Error message
                    if showError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Action buttons
                    if !showSuccess && !showUndo {
                        VStack(spacing: 12) {
                            // Unsubscribe/Cancel button
                            Button {
                                initiateUnsubscribe()
                            } label: {
                                HStack {
                                    if isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: isSubscriptionService ? "xmark.circle.fill" : "envelope.badge.fill")
                                        Text(isSubscriptionService ? "Cancel Subscription" : "Unsubscribe")
                                            .font(.headline)
                                    }
                                }
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                            .disabled(isProcessing)
                            .opacity(isProcessing ? 0.6 : 1.0)

                            // Cancel button
                            Button {
                                isPresented = false
                            } label: {
                                Text(isSubscriptionService ? "Keep Subscription" : "Keep Receiving Emails")
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                .padding(DesignTokens.Spacing.card)
            }
        }
    }

    // MARK: - Actions

    func initiateUnsubscribe() {
        // Start 5-second countdown with undo option
        showUndo = true
        undoTimeRemaining = 5

        HapticService.shared.warning()

        // Start countdown
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if undoTimeRemaining > 0 {
                undoTimeRemaining -= 1
            } else {
                timer.invalidate()
                // Execute unsubscribe after countdown
                executeUnsubscribe()
            }
        }
    }

    func cancelUnsubscribe() {
        undoTimeRemaining = 0
        showUndo = false

        HapticService.shared.success()
        Logger.info("Unsubscribe cancelled by user", category: .action)
    }

    func executeUnsubscribe() {
        isProcessing = true
        showError = false

        Logger.info("Executing unsubscribe for: \(unsubscribeUrl)", category: .action)

        // Call UnsubscribeService
        UnsubscribeService.shared.unsubscribe(
            url: unsubscribeUrl,
            reason: selectedReason?.rawValue,
            customReason: customReason.isEmpty ? nil : customReason,
            senderName: card.company?.name ?? card.sender?.name
        ) { result in
            DispatchQueue.main.async {
                isProcessing = false

                switch result {
                case .success:
                    showSuccess = true
                    showUndo = false

                    HapticService.shared.success()
                    Logger.info("Unsubscribe successful", category: .action)

                    // Call completion callback
                    onUnsubscribeComplete?()

                    // Auto-dismiss after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        isPresented = false
                    }

                case .failure(let error):
                    showError = true
                    showUndo = false
                    errorMessage = error.localizedDescription

                    HapticService.shared.error()
                    Logger.error("Unsubscribe failed: \(error.localizedDescription)", category: .action)
                }
            }
        }
    }
}

// MARK: - Reason Button

struct ReasonButton: View {
    let reason: UnsubscribeModal.UnsubscribeReason
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: reason.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? reason.color : .white.opacity(0.7))
                    .frame(width: 30)

                Text(reason.rawValue)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(reason.color)
                        .font(.title3)
                }
            }
            .padding()
            .background(isSelected ? reason.color.opacity(0.2) : Color.white.opacity(0.1))
            .cornerRadius(DesignTokens.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .strokeBorder(
                        isSelected ? reason.color : Color.white.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
    }
}

// MARK: - Preview

#Preview("Unsubscribe Modal") {
    UnsubscribeModal(
        card: EmailCard(
            id: "preview",
            type: .ads,
            state: .unseen,
            priority: .medium,
            hpa: "Deals",
            timeAgo: "2h ago",
            title: "Weekly Newsletter",
            summary: "Latest updates and offers",
            metaCTA: "Unsubscribe",
            company: CompanyInfo(name: "TechCrunch", initials: "TC"),
            isNewsletter: true,
            unsubscribeUrl: "https://example.com/unsubscribe"
        ),
        unsubscribeUrl: "https://example.com/unsubscribe",
        isPresented: .constant(true)
    )
    .background(
        LinearGradient(
            colors: [Color.orange, Color.red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
