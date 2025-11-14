import SwiftUI

/// Bottom sheet for selecting which action to perform on an email card
/// Appears when user flicks card upward
struct ActionSelectorBottomSheet: View {
    let card: EmailCard
    let currentActionId: String
    let onActionSelected: (String) -> Void
    @Binding var isPresented: Bool
    var userContext: UserContext = UserContext.defaultUser // Optional: defaults to free user

    @State private var selectedActionId: String? = nil
    @State private var showShareSheet = false
    @State private var showPaywall = false
    @State private var unavailableActionId: String? = nil

    private let registry = ActionRegistry.shared

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(DesignTokens.Opacity.overlayMedium))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Action")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text(card.title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Spacing.card)
            .padding(.bottom, 16)

            // Quick Actions - Horizontal Icon Row at TOP
            VStack(alignment: .leading, spacing: 8) {
                Text("QUICK ACTIONS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.overlayStrong))
                    .tracking(1)
                    .padding(.horizontal, DesignTokens.Spacing.card)

                HStack(spacing: 16) {
                    // Share button
                    QuickActionIconButton(
                        icon: "square.and.arrow.up",
                        label: "Share",
                        color: .blue,
                        onTap: {
                            showShareSheet = true
                        }
                    )

                    // Copy to clipboard
                    QuickActionIconButton(
                        icon: "doc.on.doc",
                        label: "Copy",
                        color: .purple,
                        onTap: {
                            copyToClipboard()
                        }
                    )

                    // Open in Safari (if has links)
                    if hasLinks {
                        QuickActionIconButton(
                            icon: "safari",
                            label: "Safari",
                            color: .cyan,
                            onTap: {
                                openInSafari()
                            }
                        )
                    } else {
                        // Placeholder to maintain spacing
                        QuickActionIconButton(
                            icon: "link.badge.plus",
                            label: "No Links",
                            color: .gray,
                            isDisabled: true,
                            onTap: {}
                        )
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.card)
            }
            .padding(.bottom, 16)

            Divider()
                .background(Color.white.opacity(DesignTokens.Opacity.overlayLight))
                .padding(.horizontal, DesignTokens.Spacing.card)

            // Action list
            ScrollView {
                VStack(spacing: 12) {
                    // Email-specific actions
                    if let actions = card.suggestedActions, !actions.isEmpty {
                        ForEach(actions) { action in
                            ActionSelectionRow(
                                action: action,
                                isSelected: action.actionId == selectedActionId,
                                isCurrent: action.actionId == currentActionId,
                                isAvailable: checkActionAvailability(action),
                                availabilityReason: getAvailabilityReason(action),
                                onTap: {
                                    handleActionTap(action)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.card)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 500)
        .background(
            AnimatedGradientBackground(
                for: card.type,
                animationSpeed: 30
            )
        )
        .glassmorphic(opacity: 0.03, cornerRadius: DesignTokens.Radius.card)
        .sheet(isPresented: $showShareSheet) {
            if let shareURL = extractFirstURL() {
                ActionSelectorShareSheet(activityItems: [shareURL, card.title])
            } else {
                ActionSelectorShareSheet(activityItems: [card.title, card.summary])
            }
        }
        // PAYWALL COMMENTED OUT - Keep premium tabs visible but don't enforce paywall
        // .fullScreenCover(isPresented: $showPaywall) {
        //     PremiumPaywallView(
        //         isPresented: $showPaywall,
        //         triggeredBy: unavailableActionId
        //     )
        // }
    }

    // MARK: - Helper Properties

    private var hasLinks: Bool {
        extractFirstURL() != nil
    }

    // MARK: - Helper Methods

    /// Check if action is available for current user
    private func checkActionAvailability(_ action: EmailAction) -> Bool {
        guard let registryAction = registry.getAction(action.actionId) else {
            // Action not in registry - allow by default (backward compatibility)
            return true
        }

        return registry.isActionAvailable(
            registryAction,
            userContext: userContext,
            emailContext: action.context
        )
    }

    /// Get user-friendly reason why action is unavailable
    private func getAvailabilityReason(_ action: EmailAction) -> String? {
        guard registry.getAction(action.actionId) != nil else {
            return nil // Not in registry - no restriction
        }

        return registry.getAvailabilityReason(
            action.actionId,
            userContext: userContext,
            emailContext: action.context
        )
    }

    /// Handle action tap with availability check
    private func handleActionTap(_ action: EmailAction) {
        // PAYWALL BYPASSED - Allow all actions for now
        // Still show premium badge in UI but don't block execution

        // Check availability (for UI display only)
        if !checkActionAvailability(action) {
            // Analytics - track premium action attempted (but not blocked)
            AnalyticsService.shared.log(.premiumActionBlocked, parameters: [
                "action_id": action.actionId,
                "action_name": action.displayName,
                "email_type": card.type.rawValue,
                "unavailability_reason": getAvailabilityReason(action) ?? "unknown",
                "paywall_bypassed": true
            ])

            Logger.info("User attempted premium action: \(action.actionId), allowing (paywall bypassed)", category: .userPreferences)
            // Continue to selection instead of showing paywall
        }

        // Proceed with action selection (premium or not)
        selectAction(action.actionId)
    }

    private func extractFirstURL() -> URL? {
        let text = "\(card.title) \(card.summary) \(card.body ?? "")"
        let pattern = "(https?://[^\\s]+)"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return nil
        }

        var urlString = String(text[range])
        // Clean up trailing punctuation
        urlString = urlString.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:)"))
        return URL(string: urlString)
    }

    private func copyToClipboard() {
        let textToCopy = "\(card.title)\n\n\(card.summary)"
        UIPasteboard.general.string = textToCopy

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        Logger.info("Copied email content to clipboard", category: .action)

        // Dismiss after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }

    private func openInSafari() {
        guard let url = extractFirstURL() else {
            Logger.warning("No URL found to open in Safari", category: .action)
            return
        }

        UIApplication.shared.open(url)
        Logger.info("Opening URL in Safari: \(url.absoluteString)", category: .action)

        // Dismiss after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }

    private func selectAction(_ actionId: String) {
        selectedActionId = actionId

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Delay to show selection, then call callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onActionSelected(actionId)
            isPresented = false
        }
    }
}

/// Individual action row in the selector
struct ActionSelectionRow: View {
    let action: EmailAction
    let isSelected: Bool
    let isCurrent: Bool
    var isAvailable: Bool = true // Default to available for backward compat
    var availabilityReason: String? = nil
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Action icon
                Image(systemName: actionIcon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        isSelected ? Color.white.opacity(DesignTokens.Opacity.overlayMedium) : Color.white.opacity(DesignTokens.Opacity.glassLight)
                    )
                    .cornerRadius(DesignTokens.Radius.container)

                // Action details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(action.displayName)
                            .font(.headline)
                            .foregroundColor(.white)

                        if isCurrent {
                            Text("CURRENT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.green)
                                .cornerRadius(DesignTokens.Radius.minimal)
                        }

                        // Permission badge
                        if !isAvailable {
                            Text("PREMIUM")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(DesignTokens.Radius.minimal)
                        }
                    }

                    Text(isAvailable ? actionTypeDescription : (availabilityReason ?? "Upgrade required"))
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                } else if action.isPrimary {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow.opacity(DesignTokens.Opacity.textSubtle))
                }
            }
            .padding(DesignTokens.Spacing.section)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .fill(isSelected ? Color.white.opacity(DesignTokens.Opacity.overlayLight) : Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .strokeBorder(
                        isCurrent ? Color.green.opacity(DesignTokens.Opacity.overlayStrong) : Color.white.opacity(DesignTokens.Opacity.glassLight),
                        lineWidth: isCurrent ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var actionIcon: String {
        switch action.actionId {
        case let id where id.contains("calendar"):
            return "calendar.badge.plus"
        case let id where id.contains("pay"):
            return "dollarsign.circle.fill"
        case let id where id.contains("sign"):
            return "signature"
        case let id where id.contains("track"):
            return "shippingbox.fill"
        case let id where id.contains("reply"):
            return "arrowshape.turn.up.left.fill"
        case let id where id.contains("review"):
            return "star.fill"
        case let id where id.contains("check_in"):
            return "airplane.departure"
        case let id where id.contains("meeting"):
            return "video.fill"
        case let id where id.contains("view"):
            return "eye.fill"
        case let id where id.contains("download"):
            return "arrow.down.circle.fill"
        default:
            return "checkmark.circle.fill"
        }
    }

    private var actionTypeDescription: String {
        action.actionType == .inApp ? "Complete in-app" : "Open link"
    }
}

// MARK: - Quick Action Icon Button
struct QuickActionIconButton: View {
    let icon: String
    let label: String
    let color: Color
    var isDisabled: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Circular icon button
                ZStack {
                    Circle()
                        .fill(
                            isDisabled ?
                            Color.white.opacity(DesignTokens.Opacity.glassUltraLight) :
                            color.opacity(DesignTokens.Opacity.overlayLight)
                        )
                        .frame(width: 60, height: 60)

                    Circle()
                        .strokeBorder(
                            isDisabled ?
                            Color.white.opacity(DesignTokens.Opacity.glassLight) :
                            color.opacity(0.4),
                            lineWidth: 1.5
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(
                            isDisabled ?
                            .white.opacity(DesignTokens.Opacity.overlayMedium) :
                            color
                        )
                }

                // Label
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(
                        isDisabled ?
                        .white.opacity(0.4) :
                        .white.opacity(DesignTokens.Opacity.textSubtle)
                    )
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}

// MARK: - Action Selector Share Sheet

struct ActionSelectorShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview
#if DEBUG
struct ActionSelectorBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()
                ActionSelectorBottomSheet(
                    card: EmailCard(
                        id: "test",
                        type: .mail,
                        state: .unseen,
                        priority: .high,
                        hpa: "Sign Form",
                        timeAgo: "2h ago",
                        title: "Permission Form - Field Trip",
                        summary: "Please sign the permission form for the upcoming field trip. Visit https://school.com/fieldtrip for more details.",
                        body: nil,
                        htmlBody: nil,
                        metaCTA: "Swipe Right: Sign Form",
                        intent: "education.permission.sign",
                        intentConfidence: 0.95,
                        suggestedActions: [
                            EmailAction(actionId: "sign_form", displayName: "Sign Form", actionType: .inApp, isPrimary: true, priority: 1),
                            EmailAction(actionId: "view_details", displayName: "View Details", actionType: .inApp, isPrimary: false, priority: 2),
                            EmailAction(actionId: "schedule_meeting", displayName: "Schedule Meeting", actionType: .inApp, isPrimary: false, priority: 3)
                        ]
                    ),
                    currentActionId: "sign_form",
                    onActionSelected: { _ in },
                    isPresented: .constant(true)
                )
                .transition(.move(edge: .bottom))
            }
        }
    }
}
#endif
