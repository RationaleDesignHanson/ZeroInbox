import SwiftUI

/// Reusable copy button with automatic success state
/// Consolidates duplicate copy button implementations across ActionModules
struct CopyableButton: View {
    let text: String
    let label: String
    let style: ButtonStyle

    @State private var showSuccess = false

    enum ButtonStyle {
        case primary    // Blue fill
        case secondary  // Gray fill
        case iconOnly   // Just icon, no background
    }

    init(text: String, label: String = "Copy", style: ButtonStyle = .primary) {
        self.text = text
        self.label = label
        self.style = style
    }

    var body: some View {
        Button {
            copyToClipboard()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: showSuccess ? "checkmark.circle.fill" : "doc.on.doc")
                    .foregroundColor(showSuccess ? .green : iconColor)

                if style != .iconOnly {
                    Text(showSuccess ? "Copied!" : label)
                        .font(.headline)
                        .foregroundColor(textColor)
                }
            }
            .frame(maxWidth: style == .iconOnly ? nil : .infinity)
            .padding(style == .iconOnly ? 0 : 14)
            .background(backgroundColor)
            .cornerRadius(DesignTokens.Radius.button)
        }
        .disabled(showSuccess)
    }

    private func copyToClipboard() {
        ClipboardUtility.copy(text)

        withAnimation {
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSuccess = false
            }
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return showSuccess ? .green : .blue
        case .secondary:
            return showSuccess ? .green.opacity(0.2) : Color(.systemGray5)
        case .iconOnly:
            return .clear
        }
    }

    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return showSuccess ? .green : DesignTokens.Colors.textPrimary
        case .iconOnly:
            return showSuccess ? .green : DesignTokens.Colors.textSecondary
        }
    }

    private var iconColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return DesignTokens.Colors.textSecondary
        case .iconOnly:
            return DesignTokens.Colors.textSecondary
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Primary style
        CopyableButton(text: "ABC123", label: "Copy Code", style: .primary)

        // Secondary style
        CopyableButton(text: "1Z999AA10123456789", label: "Copy Tracking Number", style: .secondary)

        // Icon only
        HStack {
            Text("Order #123456")
                .font(.body)
            CopyableButton(text: "123456", style: .iconOnly)
        }
    }
    .padding()
    .background(Color(.systemBackground))
}
