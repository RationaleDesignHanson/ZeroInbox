import SwiftUI

/// Unified button footer for all action modals
/// Provides consistent primary/secondary button layout with loading states
struct ModalButtonFooter: View {
    let primaryTitle: String
    let secondaryTitle: String?
    let onPrimary: () -> Void
    let onSecondary: (() -> Void)?

    var isLoading: Bool = false
    var primaryDisabled: Bool = false
    var primaryColor: Color = .blue
    var hapticFeedback: UIImpactFeedbackGenerator.FeedbackStyle = .medium

    var body: some View {
        VStack(spacing: 12) {
            // Primary button
            Button(action: handlePrimaryAction) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(primaryTitle)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(primaryDisabled ? Color.gray : primaryColor)
                .foregroundColor(.white)
                .cornerRadius(DesignTokens.Radius.button)
            }
            .disabled(isLoading || primaryDisabled)

            // Secondary button (if provided)
            if let secondaryTitle = secondaryTitle,
               let onSecondary = onSecondary {
                Button(action: onSecondary) {
                    Text(secondaryTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(DesignTokens.Radius.button)
                }
                .disabled(isLoading)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.section)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }

    private func handlePrimaryAction() {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: hapticFeedback)
        generator.impactOccurred()

        onPrimary()
    }
}

// MARK: - Convenience Initializers

extension ModalButtonFooter {
    /// Single primary button only
    init(
        primaryTitle: String,
        onPrimary: @escaping () -> Void,
        isLoading: Bool = false,
        primaryDisabled: Bool = false,
        primaryColor: Color = .blue
    ) {
        self.primaryTitle = primaryTitle
        self.secondaryTitle = nil
        self.onPrimary = onPrimary
        self.onSecondary = nil
        self.isLoading = isLoading
        self.primaryDisabled = primaryDisabled
        self.primaryColor = primaryColor
    }

    /// Primary + secondary buttons
    init(
        primaryTitle: String,
        secondaryTitle: String,
        onPrimary: @escaping () -> Void,
        onSecondary: @escaping () -> Void,
        isLoading: Bool = false,
        primaryDisabled: Bool = false,
        primaryColor: Color = .blue
    ) {
        self.primaryTitle = primaryTitle
        self.secondaryTitle = secondaryTitle
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
        self.isLoading = isLoading
        self.primaryDisabled = primaryDisabled
        self.primaryColor = primaryColor
    }
}

// MARK: - Preview

#if DEBUG
struct ModalButtonFooter_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Single button
            ModalButtonFooter(
                primaryTitle: "Continue",
                onPrimary: {}
            )

            // Primary + secondary
            ModalButtonFooter(
                primaryTitle: "Save Changes",
                secondaryTitle: "Cancel",
                onPrimary: {},
                onSecondary: {}
            )

            // Loading state
            ModalButtonFooter(
                primaryTitle: "Processing...",
                secondaryTitle: "Cancel",
                onPrimary: {},
                onSecondary: {},
                isLoading: true
            )

            // Disabled state
            ModalButtonFooter(
                primaryTitle: "Submit",
                secondaryTitle: "Cancel",
                onPrimary: {},
                onSecondary: {},
                primaryDisabled: true
            )

            // Custom color
            ModalButtonFooter(
                primaryTitle: "Delete",
                secondaryTitle: "Cancel",
                onPrimary: {},
                onSecondary: {},
                primaryColor: .red
            )
        }
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}
#endif
