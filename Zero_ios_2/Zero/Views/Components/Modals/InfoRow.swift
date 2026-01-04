import SwiftUI

/// Reusable label/value row for displaying information in modals
/// Used for tracking numbers, invoice IDs, dates, etc.
struct InfoRow: View {
    let label: String
    let value: String

    var icon: String? = nil
    var iconColor: Color = .secondary
    var valueColor: Color = .primary
    var copyable: Bool = false
    var tappable: Bool = false
    var onTap: (() -> Void)? = nil

    @State private var showCopiedToast = false

    var body: some View {
        Button(action: handleTap) {
            HStack(alignment: .top, spacing: 12) {
                // Icon (optional)
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .frame(width: 20)
                        .font(.subheadline)
                }

                // Label
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                // Value
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(valueColor)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(3)

                // Copy button (if copyable)
                if copyable {
                    Button {
                        copyToClipboard()
                    } label: {
                        Image(systemName: showCopiedToast ? "checkmark.circle.fill" : "doc.on.doc")
                            .foregroundColor(showCopiedToast ? .green : .blue)
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderless)
                }

                // Chevron (if tappable)
                if tappable && onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!tappable || onTap == nil)
    }

    private func handleTap() {
        guard tappable, let onTap = onTap else { return }
        onTap()
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = value
        showCopiedToast = true

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Reset toast after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showCopiedToast = false
        }
    }
}

// MARK: - Convenience Initializers

extension InfoRow {
    /// Simple label/value row
    init(label: String, value: String) {
        self.label = label
        self.value = value
    }

    /// Row with icon
    init(label: String, value: String, icon: String, iconColor: Color = .secondary) {
        self.label = label
        self.value = value
        self.icon = icon
        self.iconColor = iconColor
    }

    /// Copyable row
    init(label: String, value: String, copyable: Bool) {
        self.label = label
        self.value = value
        self.copyable = copyable
    }

    /// Tappable row
    init(label: String, value: String, onTap: @escaping () -> Void) {
        self.label = label
        self.value = value
        self.tappable = true
        self.onTap = onTap
    }
}

// MARK: - ModalSectionView for grouping InfoRows

/// Glass-morphism section container for grouping related info rows
struct ModalSectionView<Content: View>: View {
    let title: String?
    let subtitle: String?
    let background: BackgroundStyle
    let collapsible: Bool

    @ViewBuilder let content: () -> Content

    @State private var isExpanded: Bool = true

    enum BackgroundStyle {
        case glass
        case card
        case plain
        case none
    }

    init(
        title: String? = nil,
        subtitle: String? = nil,
        background: BackgroundStyle = .glass,
        collapsible: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.background = background
        self.collapsible = collapsible
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            if let title = title {
                Button(action: toggleExpanded) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.headline)
                                .foregroundColor(.primary)

                            if let subtitle = subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if collapsible {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!collapsible)
            }

            // Content
            if isExpanded {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
        .padding(DesignTokens.Spacing.card)
        .background(backgroundView)
        .cornerRadius(DesignTokens.Radius.card)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch background {
        case .glass:
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                        .strokeBorder(Color.white.opacity(DesignTokens.Opacity.glassLight), lineWidth: 1)
                )
        case .card:
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .fill(Color(.systemGray6))
        case .plain:
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .fill(Color(.systemBackground))
        case .none:
            EmptyView()
        }
    }

    private func toggleExpanded() {
        guard collapsible else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            isExpanded.toggle()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct InfoRow_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Basic rows
                ModalSectionView(title: "Basic Info") {
                    InfoRow(label: "Order ID", value: "ORD-123456")
                    InfoRow(label: "Status", value: "In Transit")
                    InfoRow(label: "Delivery", value: "Dec 25, 2025")
                }

                // With icons
                ModalSectionView(title: "Contact Details") {
                    InfoRow(label: "Email", value: "john@example.com", icon: "envelope.fill", iconColor: .blue)
                    InfoRow(label: "Phone", value: "+1 (555) 123-4567", icon: "phone.fill", iconColor: .green)
                    InfoRow(label: "Location", value: "San Francisco, CA", icon: "mappin.circle.fill", iconColor: .red)
                }

                // Copyable
                ModalSectionView(title: "Tracking Info") {
                    InfoRow(label: "Tracking #", value: "1Z999AA10123456784", copyable: true)
                    InfoRow(label: "Confirmation", value: "CNF-789012", copyable: true)
                }

                // Tappable
                ModalSectionView(title: "Actions") {
                    InfoRow(label: "View Invoice", value: "PDF", onTap: {})
                    InfoRow(label: "Contact Support", value: "Email", onTap: {})
                }

                // Collapsible section
                ModalSectionView(title: "Additional Details", subtitle: "Optional information", collapsible: true) {
                    InfoRow(label: "Weight", value: "2.5 lbs")
                    InfoRow(label: "Dimensions", value: "12\" × 8\" × 4\"")
                    InfoRow(label: "Insurance", value: "$100")
                }
            }
            .padding()
        }
    }
}
#endif
