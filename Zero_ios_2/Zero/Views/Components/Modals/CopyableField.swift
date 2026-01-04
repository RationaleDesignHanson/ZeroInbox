import SwiftUI

/// Specialized component for displaying copyable text (tracking numbers, codes, IDs)
/// Features prominent copy button and success feedback
struct CopyableField: View {
    let label: String?
    let value: String

    var icon: String? = nil
    var iconColor: Color = .blue
    var valueFont: Font = .body
    var style: FieldStyle = .prominent

    @State private var showCopiedFeedback = false

    enum FieldStyle {
        case prominent    // Large badge-like style
        case inline       // Compact inline style
        case card         // Full-width card style
    }

    var body: some View {
        switch style {
        case .prominent:
            prominentStyle
        case .inline:
            inlineStyle
        case .card:
            cardStyle
        }
    }

    // MARK: - Prominent Style (Badge)

    private var prominentStyle: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(iconColor)
                }

                Text(value)
                    .font(valueFont.monospaced())
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Button(action: copyToClipboard) {
                    HStack(spacing: 6) {
                        Image(systemName: showCopiedFeedback ? "checkmark.circle.fill" : "doc.on.doc.fill")
                        Text(showCopiedFeedback ? "Copied!" : "Copy")
                            .font(.caption.bold())
                    }
                    .foregroundColor(showCopiedFeedback ? .green : .blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        (showCopiedFeedback ? Color.green : Color.blue)
                            .opacity(0.15)
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(DesignTokens.Spacing.component)
            .background(Color(.systemGray6))
            .cornerRadius(DesignTokens.Radius.card)
        }
    }

    // MARK: - Inline Style (Compact)

    private var inlineStyle: some View {
        HStack(spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(iconColor)
            }

            Text(value)
                .font(valueFont.monospaced())
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            Button(action: copyToClipboard) {
                Image(systemName: showCopiedFeedback ? "checkmark.circle.fill" : "doc.on.doc")
                    .foregroundColor(showCopiedFeedback ? .green : .blue)
                    .font(.subheadline)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Card Style (Full Width)

    private var cardStyle: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(iconColor)
                }

                if let label = label {
                    Text(label)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Spacer()
            }

            // Value
            HStack {
                Text(value)
                    .font(valueFont.monospaced())
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: copyToClipboard) {
                    HStack(spacing: 6) {
                        Image(systemName: showCopiedFeedback ? "checkmark.circle.fill" : "doc.on.doc.fill")
                        Text(showCopiedFeedback ? "Copied" : "Copy")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(showCopiedFeedback ? Color.green : Color.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(DesignTokens.Spacing.component)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(DesignTokens.Spacing.card)
        .background(.ultraThinMaterial)
        .cornerRadius(DesignTokens.Radius.card)
    }

    // MARK: - Actions

    private func copyToClipboard() {
        UIPasteboard.general.string = value

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Show success feedback
        withAnimation {
            showCopiedFeedback = true
        }

        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }
}

// MARK: - Convenience Initializers

extension CopyableField {
    /// Simple copyable field with value only
    init(value: String, style: FieldStyle = .prominent) {
        self.label = nil
        self.value = value
        self.style = style
    }

    /// Copyable field with label
    init(label: String, value: String, style: FieldStyle = .prominent) {
        self.label = label
        self.value = value
        self.style = style
    }

    /// Copyable field with icon
    init(
        label: String,
        value: String,
        icon: String,
        iconColor: Color = .blue,
        style: FieldStyle = .prominent
    ) {
        self.label = label
        self.value = value
        self.icon = icon
        self.iconColor = iconColor
        self.style = style
    }
}

// MARK: - Preview

#if DEBUG
struct CopyableField_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Prominent style
                VStack(alignment: .leading, spacing: 16) {
                    Text("Prominent Style")
                        .font(.title2.bold())

                    CopyableField(
                        label: "Tracking Number",
                        value: "1Z999AA10123456784",
                        icon: "shippingbox.fill",
                        iconColor: .orange,
                        style: .prominent
                    )

                    CopyableField(
                        label: "Confirmation Code",
                        value: "ABC-XYZ-123",
                        style: .prominent
                    )
                }

                Divider()

                // Inline style
                VStack(alignment: .leading, spacing: 16) {
                    Text("Inline Style")
                        .font(.title2.bold())

                    CopyableField(
                        label: "Invoice ID",
                        value: "INV-2025-001234",
                        style: .inline
                    )

                    CopyableField(
                        label: "Order #",
                        value: "ORD-789456",
                        icon: "cart.fill",
                        style: .inline
                    )
                }

                Divider()

                // Card style
                VStack(alignment: .leading, spacing: 16) {
                    Text("Card Style")
                        .font(.title2.bold())

                    CopyableField(
                        label: "Promo Code",
                        value: "SAVE25NOW",
                        icon: "tag.fill",
                        iconColor: .green,
                        style: .card
                    )

                    CopyableField(
                        label: "Booking Reference",
                        value: "BKG-2025-ABCD1234",
                        icon: "ticket.fill",
                        iconColor: .purple,
                        style: .card
                    )
                }
            }
            .padding()
        }
    }
}
#endif
