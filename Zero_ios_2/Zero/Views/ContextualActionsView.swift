import SwiftUI

struct ContextualActionsView: View {
    let card: EmailCard
    @State private var suggestedActions: [ContextualAction] = []

    var body: some View {
        if !suggestedActions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.caption)
                        .foregroundColor(.purple)

                    Text("Smart Actions")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))

                    Spacer()
                }

                // Action cards
                ForEach(suggestedActions) { action in
                    ContextualActionCard(action: action)
                }
            }
            .padding(DesignTokens.Spacing.component)
            .background(
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.15),
                        Color.blue.opacity(DesignTokens.Opacity.glassLight)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(DesignTokens.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.purple.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
            )
            .onAppear {
                loadSuggestedActions()
            }
        }
    }

    func loadSuggestedActions() {
        suggestedActions = ContextualActionService.shared.suggestActions(for: card)
        Logger.info("Generated \(suggestedActions.count) suggestions for email: \(card.title)", category: .app)
    }
}

struct ContextualActionCard: View {
    let action: ContextualAction
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            performAction()
        }) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(action.color.opacity(DesignTokens.Opacity.overlayLight))
                        .frame(width: 40, height: 40)

                    Image(systemName: action.icon)
                        .font(.system(size: 16))
                        .foregroundColor(action.color)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(action.title)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)

                        if action.priority == .critical {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                        } else if action.priority == .high {
                            Image(systemName: "exclamationmark.circle")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }

                    Text(action.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                        .lineLimit(2)
                }

                Spacer()

                // Arrow
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(action.color)
            }
            .padding(DesignTokens.Spacing.element)
            .background(
                Color.white.opacity(isPressed ? 0.15 : 0.05)
            )
            .cornerRadius(DesignTokens.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(action.color.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }

    func performAction() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Execute action handler
        action.handler()

        Logger.info("Executed: \(action.title) [\(action.type.rawValue)]", category: .app)
    }
}

// MARK: - Preview
// Preview removed due to complex EmailCard init requirements
